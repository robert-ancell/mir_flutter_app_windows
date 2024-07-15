#include "flutter_window_manager.h"

#include <flutter/encodable_value.h>
#include <flutter/standard_method_codec.h>

#include <dwmapi.h>

#include <algorithm>

namespace {
auto *const CHANNEL{"io.mir-server/window"};
auto const base_dpi{96.0};

// Returns the origin point that will center a window of size 'size' within the
// client area of the window identified by 'handle'.
auto calculateCenteredOrigin(Win32Window::Size size,
                             HWND handle) -> Win32Window::Point {
  if (RECT frame; handle && GetWindowRect(handle, &frame)) {
    POINT const target_point{frame.left, frame.top};
    auto *const monitor{
        MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST)};
    auto const dpr{FlutterDesktopGetDpiForMonitor(monitor) / base_dpi};
    auto const centered_x{(frame.left + frame.right - size.width * dpr) / 2.0};
    auto const centered_y{(frame.top + frame.bottom - size.height * dpr) / 2.0};
    return {static_cast<unsigned int>(centered_x / dpr),
            static_cast<unsigned int>(centered_y / dpr)};
  }
  return {0, 0};
}

std::tuple<Win32Window::Point, Win32Window::Size>
applyPositioner(mir::Positioner const &positioner,
                Win32Window::Size const &size,
                flutter::FlutterViewId parent_view_id) {
  auto const &windows{FlutterWindowManager::instance().windows()};
  auto const &parent_window{windows.at(parent_view_id)};
  auto const &parent_hwnd{parent_window->GetHandle()};
  auto const dpr{FlutterDesktopGetDpiForHWND(parent_hwnd) / base_dpi};
  auto const monitor_rect{[](HWND hwnd) -> RECT {
    auto *monitor{MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)};
    MONITORINFO mi;
    mi.cbSize = sizeof(MONITORINFO);
    return GetMonitorInfo(monitor, &mi) ? mi.rcMonitor : RECT{0, 0, 0, 0};
  }(parent_hwnd)};

  RECT frame;
  if (FAILED(DwmGetWindowAttribute(parent_hwnd, DWMWA_EXTENDED_FRAME_BOUNDS,
                                   &frame, sizeof(frame)))) {
    GetWindowRect(parent_hwnd, &frame);
  }

  struct RectF {
    double left;
    double top;
    double right;
    double bottom;
  };

  struct PointF {
    double x;
    double y;
  };
  RectF const cropped_frame{
      .left = frame.left + positioner.anchor_rect.x * dpr,
      .top = frame.top + positioner.anchor_rect.y * dpr,
      .right = frame.left +
               (positioner.anchor_rect.x + positioner.anchor_rect.width) * dpr,
      .bottom =
          frame.top +
          (positioner.anchor_rect.y + positioner.anchor_rect.height) * dpr};
  PointF const center{.x = (cropped_frame.left + cropped_frame.right) / 2.0,
                      .y = (cropped_frame.top + cropped_frame.bottom) / 2.0};
  PointF child_size{size.width * dpr, size.height * dpr};
  PointF const child_center{child_size.x / 2.0, child_size.y / 2.0};

  auto const get_parent_anchor_point{
      [&](mir::Positioner::Anchor anchor) -> PointF {
        switch (anchor) {
        case mir::Positioner::Anchor::top:
          return {center.x, cropped_frame.top};
        case mir::Positioner::Anchor::bottom:
          return {center.x, cropped_frame.bottom};
        case mir::Positioner::Anchor::left:
          return {cropped_frame.left, center.y};
        case mir::Positioner::Anchor::right:
          return {cropped_frame.right, center.y};
        case mir::Positioner::Anchor::top_left:
          return {cropped_frame.left, cropped_frame.top};
        case mir::Positioner::Anchor::bottom_left:
          return {cropped_frame.left, cropped_frame.bottom};
        case mir::Positioner::Anchor::top_right:
          return {cropped_frame.right, cropped_frame.top};
        case mir::Positioner::Anchor::bottom_right:
          return {cropped_frame.right, cropped_frame.bottom};
        default:
          return center;
        }
      }};

  auto const get_child_anchor_point{
      [&](mir::Positioner::Gravity gravity) -> PointF {
        switch (gravity) {
        case mir::Positioner::Gravity::top:
          return {-child_center.x, -child_size.x};
        case mir::Positioner::Gravity::bottom:
          return {-child_center.x, 0};
        case mir::Positioner::Gravity::left:
          return {-child_size.x, -child_center.y};
        case mir::Positioner::Gravity::right:
          return {0, -child_center.y};
        case mir::Positioner::Gravity::top_left:
          return {-child_size.x, -child_size.y};
        case mir::Positioner::Gravity::bottom_left:
          return {-child_size.x, 0};
        case mir::Positioner::Gravity::top_right:
          return {0, -child_size.y};
        case mir::Positioner::Gravity::bottom_right:
          return {0, 0};
        default:
          return {-child_center.x, -child_center.y};
        }
      }};

  auto const calculate_origin{[](PointF const &parent_anchor,
                                 PointF const &child_anchor,
                                 PointF const &offset) -> PointF {
    return {.x = parent_anchor.x + child_anchor.x + offset.x,
            .y = parent_anchor.y + child_anchor.y + offset.y};
  }};

  auto anchor{positioner.anchor};
  auto gravity{positioner.gravity};
  PointF offset{static_cast<double>(positioner.offset.dx),
                static_cast<double>(positioner.offset.dy)};

  auto parent_anchor_point{get_parent_anchor_point(anchor)};
  auto child_anchor_point{get_child_anchor_point(gravity)};
  PointF origin_dc{
      calculate_origin(parent_anchor_point, child_anchor_point, offset)};

  // Constraint adjustments

  auto const is_constrained_along_x{[&]() {
    return origin_dc.x < 0 || origin_dc.x + child_size.x > monitor_rect.right;
  }};
  auto const is_constrained_along_y{[&]() {
    return origin_dc.y < 0 || origin_dc.y + child_size.y > monitor_rect.bottom;
  }};

  // X axis
  if (is_constrained_along_x()) {
    auto const reverse_anchor_along_x{[](mir::Positioner::Anchor anchor) {
      switch (anchor) {
      case mir::Positioner::Anchor::left:
        return mir::Positioner::Anchor::right;
      case mir::Positioner::Anchor::right:
        return mir::Positioner::Anchor::left;
      case mir::Positioner::Anchor::top_left:
        return mir::Positioner::Anchor::top_right;
      case mir::Positioner::Anchor::bottom_left:
        return mir::Positioner::Anchor::bottom_right;
      case mir::Positioner::Anchor::top_right:
        return mir::Positioner::Anchor::top_left;
      case mir::Positioner::Anchor::bottom_right:
        return mir::Positioner::Anchor::bottom_left;
      default:
        return anchor;
      }
    }};

    auto const reverse_gravity_along_x{[](mir::Positioner::Gravity gravity) {
      switch (gravity) {
      case mir::Positioner::Gravity::left:
        return mir::Positioner::Gravity::right;
      case mir::Positioner::Gravity::right:
        return mir::Positioner::Gravity::left;
      case mir::Positioner::Gravity::top_left:
        return mir::Positioner::Gravity::top_right;
      case mir::Positioner::Gravity::bottom_left:
        return mir::Positioner::Gravity::bottom_right;
      case mir::Positioner::Gravity::top_right:
        return mir::Positioner::Gravity::top_left;
      case mir::Positioner::Gravity::bottom_right:
        return mir::Positioner::Gravity::bottom_left;
      default:
        return gravity;
      }
    }};

    if (positioner.constraint_adjustment &
        static_cast<uint32_t>(mir::Positioner::ConstraintAdjustment::flip_x)) {
      anchor = reverse_anchor_along_x(anchor);
      gravity = reverse_gravity_along_x(gravity);
      parent_anchor_point = get_parent_anchor_point(anchor);
      child_anchor_point = get_child_anchor_point(gravity);
      auto const saved_origin_dc{std::exchange(
          origin_dc,
          calculate_origin(parent_anchor_point, child_anchor_point, offset))};
      if (is_constrained_along_x()) {
        origin_dc = saved_origin_dc;
      }
    } else if (positioner.constraint_adjustment &
               static_cast<uint32_t>(
                   mir::Positioner::ConstraintAdjustment::slide_x)) {
      // TODO: Slide towards the direction of the gravity first
      if (origin_dc.x < 0) {
        auto const diff{abs(origin_dc.x)};
        offset = {offset.x + diff, offset.y};
        origin_dc =
            calculate_origin(parent_anchor_point, child_anchor_point, offset);
      }
      if (origin_dc.x + child_size.x > monitor_rect.right) {
        auto const diff{(origin_dc.x + child_size.x) - monitor_rect.right};
        offset = {offset.x - diff, offset.y};
        origin_dc =
            calculate_origin(parent_anchor_point, child_anchor_point, offset);
      }
    } else if (positioner.constraint_adjustment &
               static_cast<uint32_t>(
                   mir::Positioner::ConstraintAdjustment::resize_x)) {
      if (origin_dc.x < 0) {
        auto const diff{std::clamp(abs(origin_dc.x), 1.0, child_size.x - 1)};
        origin_dc.x += diff;
        child_size.x -= diff;
      }
      if (origin_dc.x + child_size.x > monitor_rect.right) {
        auto const diff{
            std::clamp((origin_dc.x + child_size.x) - monitor_rect.right, 1.0,
                       child_size.x - 1)};
        child_size.x -= diff;
      }
    }
  }

  // Y axis
  if (is_constrained_along_y()) {
    auto const reverse_anchor_along_y{[](mir::Positioner::Anchor anchor) {
      switch (anchor) {
      case mir::Positioner::Anchor::top:
        return mir::Positioner::Anchor::bottom;
      case mir::Positioner::Anchor::bottom:
        return mir::Positioner::Anchor::top;
      case mir::Positioner::Anchor::top_left:
        return mir::Positioner::Anchor::bottom_left;
      case mir::Positioner::Anchor::bottom_left:
        return mir::Positioner::Anchor::top_left;
      case mir::Positioner::Anchor::top_right:
        return mir::Positioner::Anchor::bottom_right;
      case mir::Positioner::Anchor::bottom_right:
        return mir::Positioner::Anchor::top_right;
      default:
        return anchor;
      }
    }};

    auto const reverse_gravity_along_y{[](mir::Positioner::Gravity gravity) {
      switch (gravity) {
      case mir::Positioner::Gravity::top:
        return mir::Positioner::Gravity::bottom;
      case mir::Positioner::Gravity::bottom:
        return mir::Positioner::Gravity::top;
      case mir::Positioner::Gravity::top_left:
        return mir::Positioner::Gravity::bottom_left;
      case mir::Positioner::Gravity::bottom_left:
        return mir::Positioner::Gravity::top_left;
      case mir::Positioner::Gravity::top_right:
        return mir::Positioner::Gravity::bottom_right;
      case mir::Positioner::Gravity::bottom_right:
        return mir::Positioner::Gravity::top_right;
      default:
        return gravity;
      }
    }};

    if (positioner.constraint_adjustment &
        static_cast<uint32_t>(mir::Positioner::ConstraintAdjustment::flip_y)) {
      anchor = reverse_anchor_along_y(anchor);
      gravity = reverse_gravity_along_y(gravity);
      parent_anchor_point = get_parent_anchor_point(anchor);
      child_anchor_point = get_child_anchor_point(gravity);
      auto const saved_origin_dc{std::exchange(
          origin_dc,
          calculate_origin(parent_anchor_point, child_anchor_point, offset))};
      if (is_constrained_along_y()) {
        origin_dc = saved_origin_dc;
      }
    } else if (positioner.constraint_adjustment &
               static_cast<uint32_t>(
                   mir::Positioner::ConstraintAdjustment::slide_y)) {
      // TODO: Slide towards the direction of the gravity first
      if (origin_dc.y < 0) {
        auto const diff{abs(origin_dc.y)};
        offset = {offset.x, offset.y + diff};
        origin_dc =
            calculate_origin(parent_anchor_point, child_anchor_point, offset);
      }
      if (origin_dc.y + child_size.y > monitor_rect.bottom) {
        auto const diff{(origin_dc.y + child_size.y) - monitor_rect.bottom};
        offset = {offset.x, offset.y - diff};
        origin_dc =
            calculate_origin(parent_anchor_point, child_anchor_point, offset);
      }
    } else if (positioner.constraint_adjustment &
               static_cast<uint32_t>(
                   mir::Positioner::ConstraintAdjustment::resize_y)) {
      if (origin_dc.y < 0) {
        auto const diff{std::clamp(abs(origin_dc.y), 1.0, child_size.y - 1)};
        origin_dc.y += diff;
        child_size.y -= diff;
      }
      if (origin_dc.y + child_size.y > monitor_rect.bottom) {
        auto const diff{
            std::clamp((origin_dc.y + child_size.y) - monitor_rect.bottom, 1.0,
                       child_size.y - 1)};
        child_size.y -= diff;
      }
    }
  }

  Win32Window::Point const origin_lc{
      static_cast<unsigned int>(origin_dc.x / dpr),
      static_cast<unsigned int>(origin_dc.y / dpr)};
  Win32Window::Size const new_size{
      static_cast<unsigned int>(child_size.x / dpr),
      static_cast<unsigned int>(child_size.y / dpr)};
  return {origin_lc, new_size};
}

void handleCreateRegularWindow(
    flutter::MethodCall<> const &call,
    std::unique_ptr<flutter::MethodResult<>> &result) {
  auto const *const arguments{call.arguments()};
  if (auto const *const map{std::get_if<flutter::EncodableMap>(arguments)}) {
    auto const width_it{map->find(flutter::EncodableValue("width"))};
    auto const height_it{map->find(flutter::EncodableValue("height"))};
    if (width_it != map->end() && height_it != map->end()) {
      auto const *const width{std::get_if<int>(&width_it->second)};
      auto const *const height{std::get_if<int>(&height_it->second)};
      if (width && height) {
        Win32Window::Size const size{static_cast<unsigned int>(*width),
                                     static_cast<unsigned int>(*height)};

        // Window will be centered within the 'main window'
        auto const origin{[size]() -> Win32Window::Point {
          auto const &windows{FlutterWindowManager::instance().windows()};
          return windows.contains(0)
                     ? calculateCenteredOrigin(size, windows.at(0)->GetHandle())
                     : Win32Window::Point{0, 0};
        }()};

        if (auto const view_id{
                FlutterWindowManager::instance().createRegularWindow(
                    L"regular", origin, size)}) {
          result->Success(flutter::EncodableValue(*view_id));
        } else {
          result->Error("UNAVAILABLE", "Can't create window.");
        }
      } else {
        result->Error("INVALID_VALUE",
                      "Values for {'width', 'height'} must be of type int.");
      }
    } else {
      result->Error(
          "INVALID_VALUE",
          "Map does not contain all required keys: {'width', 'height'}.");
    }
  } else {
    result->Error("INVALID_VALUE", "Value argument is not a map.");
  }
}

void handleCreatePopupWindow(flutter::MethodCall<> const &call,
                             std::unique_ptr<flutter::MethodResult<>> &result) {
  auto const *const arguments{call.arguments()};
  if (auto const *const map{std::get_if<flutter::EncodableMap>(arguments)}) {
    auto const parent_it{map->find(flutter::EncodableValue("parent"))};
    auto const size_it{map->find(flutter::EncodableValue("size"))};
    auto const anchor_rect_it{map->find(flutter::EncodableValue("anchorRect"))};
    auto const positioner_parent_anchor_it{
        map->find(flutter::EncodableValue("positionerParentAnchor"))};
    auto const positioner_child_anchor_it{
        map->find(flutter::EncodableValue("positionerChildAnchor"))};
    auto const positioner_offset_it{
        map->find(flutter::EncodableValue("positionerOffset"))};
    auto const positioner_constraint_adjustment_it{
        map->find(flutter::EncodableValue("positionerConstraintAdjustment"))};

    if (parent_it != map->end() && size_it != map->end() &&
        anchor_rect_it != map->end() &&
        positioner_parent_anchor_it != map->end() &&
        positioner_child_anchor_it != map->end() &&
        positioner_offset_it != map->end() &&
        positioner_constraint_adjustment_it != map->end()) {
      // parent
      auto const *const parent{std::get_if<int>(&parent_it->second)};
      if (!parent) {
        result->Error("INVALID_VALUE",
                      "Value for 'parent' must be of type int.");
        return;
      }

      // size
      auto const *const size_list{
          std::get_if<std::vector<flutter::EncodableValue>>(&size_it->second)};
      if (size_list->size() != 2 ||
          !std::holds_alternative<int>(size_list->at(0)) ||
          !std::holds_alternative<int>(size_list->at(1))) {
        result->Error("INVALID_VALUE",
                      "Values for 'size' must be of type int.");
        return;
      }
      auto const width{std::get<int>(size_list->at(0))};
      auto const height{std::get<int>(size_list->at(1))};
      Win32Window::Size const size{static_cast<unsigned int>(width),
                                   static_cast<unsigned int>(height)};

      // anchorRect
      auto const *const anchor_rect_list{
          std::get_if<std::vector<flutter::EncodableValue>>(
              &anchor_rect_it->second)};
      if (anchor_rect_list->size() != 4 ||
          !std::holds_alternative<int>(anchor_rect_list->at(0)) ||
          !std::holds_alternative<int>(anchor_rect_list->at(1)) ||
          !std::holds_alternative<int>(anchor_rect_list->at(2)) ||
          !std::holds_alternative<int>(anchor_rect_list->at(3))) {
        result->Error("INVALID_VALUE",
                      "Values for 'anchorRect' must be of type int.");
        return;
      }
      auto const anchor_rect_x{std::get<int>(anchor_rect_list->at(0))};
      auto const anchor_rect_y{std::get<int>(anchor_rect_list->at(1))};
      auto const anchor_rect_width{std::get<int>(anchor_rect_list->at(2))};
      auto const anchor_rect_height{std::get<int>(anchor_rect_list->at(3))};

      // positionerParentAnchor
      auto const *const positioner_parent_anchor{
          std::get_if<int>(&positioner_parent_anchor_it->second)};
      if (!positioner_parent_anchor) {
        result->Error(
            "INVALID_VALUE",
            "Value for 'positionerParentAnchor' must be of type int.");
        return;
      }

      // positionerChildAnchor
      auto const *const positioner_child_anchor{
          std::get_if<int>(&positioner_child_anchor_it->second)};
      if (!positioner_child_anchor) {
        result->Error("INVALID_VALUE",
                      "Value for 'positionerChildAnchor' must be of type int.");
        return;
      }
      // Convert from anchor (originally a FlutterViewPositionerAnchor) to
      // mir::Positioner::Gravity
      auto const gravity{
          [](mir::Positioner::Anchor anchor) -> mir::Positioner::Gravity {
            switch (anchor) {
            case mir::Positioner::Anchor::none:
              return mir::Positioner::Gravity::none;
            case mir::Positioner::Anchor::top:
              return mir::Positioner::Gravity::bottom;
            case mir::Positioner::Anchor::bottom:
              return mir::Positioner::Gravity::top;
            case mir::Positioner::Anchor::left:
              return mir::Positioner::Gravity::right;
            case mir::Positioner::Anchor::right:
              return mir::Positioner::Gravity::left;
            case mir::Positioner::Anchor::top_left:
              return mir::Positioner::Gravity::bottom_right;
            case mir::Positioner::Anchor::bottom_left:
              return mir::Positioner::Gravity::top_right;
            case mir::Positioner::Anchor::top_right:
              return mir::Positioner::Gravity::bottom_left;
            case mir::Positioner::Anchor::bottom_right:
              return mir::Positioner::Gravity::top_left;
            default:
              return mir::Positioner::Gravity::none;
            }
          }(static_cast<mir::Positioner::Anchor>(*positioner_child_anchor))};

      // positionerOffset
      auto const *const positioner_offset_list{
          std::get_if<std::vector<flutter::EncodableValue>>(
              &positioner_offset_it->second)};
      if (positioner_offset_list->size() != 2 ||
          !std::holds_alternative<int>(size_list->at(0)) ||
          !std::holds_alternative<int>(size_list->at(1))) {
        result->Error("INVALID_VALUE",
                      "Values for 'positionerOffset' must be of type int.");
        return;
      }
      auto const dx{std::get<int>(positioner_offset_list->at(0))};
      auto const dy{std::get<int>(positioner_offset_list->at(1))};

      // positionerConstraintAdjustment
      auto const *const positioner_constraint_adjustment{
          std::get_if<int>(&positioner_constraint_adjustment_it->second)};
      if (!positioner_constraint_adjustment) {
        result->Error(
            "INVALID_VALUE",
            "Value for 'positionerConstraintAdjustment' must be of type int.");
        return;
      }

      mir::Positioner const positioner{
          .anchor_rect = {.x = anchor_rect_x,
                          .y = anchor_rect_y,
                          .width = anchor_rect_width,
                          .height = anchor_rect_height},
          .anchor =
              static_cast<mir::Positioner::Anchor>(*positioner_parent_anchor),
          .gravity = gravity,
          .offset = {.dx = dx, .dy = dy},
          .constraint_adjustment =
              static_cast<uint32_t>(*positioner_constraint_adjustment)};

      auto const &[origin,
                   new_size]{applyPositioner(positioner, size, *parent)};

      if (auto const view_id{FlutterWindowManager::instance().createPopupWindow(
              L"popup", origin, new_size, *parent)}) {
        result->Success(flutter::EncodableValue(*view_id));
      } else {
        result->Error("UNAVAILABLE", "Can't create window.");
      }
    } else {
      result->Error("INVALID_VALUE",
                    "Map does not contain all required keys: "
                    "{'parent', 'size', 'anchorRect', "
                    "'positionerParentAnchor', 'positionerChildAnchor', "
                    "'positionerOffset', 'positionerConstraintAdjustment'}.");
    }
  } else {
    result->Error("INVALID_VALUE", "Value argument is not a map.");
  }
}

void handleDestroyWindow(flutter::MethodCall<> const &call,
                         std::unique_ptr<flutter::MethodResult<>> &result) {
  auto const arguments{
      std::get<std::vector<flutter::EncodableValue>>(*call.arguments())};
  if (arguments.size() != 1 || !std::holds_alternative<int>(arguments[0])) {
    result->Error("INVALID_VALUE", "Value argument is not valid.");
  } else {
    auto const view_id{std::get<int>(arguments[0])};
    if (FlutterWindowManager::instance().destroyWindow(view_id, true)) {
      result->Success();
    } else {
      result->Error("UNAVAILABLE", "Can't destroy window.");
    }
  }
}

} // namespace

void FlutterWindowManager::initializeChannel() {
  if (!channel_) {
    channel_ = std::make_unique<flutter::MethodChannel<>>(
        engine_->messenger(), CHANNEL,
        &flutter::StandardMethodCodec::GetInstance());
    channel_->SetMethodCallHandler(
        [this](flutter::MethodCall<> const &call,
               std::unique_ptr<flutter::MethodResult<>> result) {
          if (call.method_name() == "createRegularWindow") {
            handleCreateRegularWindow(call, result);
          } else if (call.method_name() == "createPopupWindow") {
            handleCreatePopupWindow(call, result);
          } else if (call.method_name() == "destroyWindow") {
            handleDestroyWindow(call, result);
          } else {
            result->NotImplemented();
          }
        });

    // To avoid an overflow of onWindowCreated messages, the number of messages
    // that get buffered must be at least equal to the number of FlutterWindows
    // created in the entrypoint of the runner code. This is required because
    // the channel's message handler is set up on the Dart side only after the
    // first call to State::didUpdateWidget.
    auto const max_windows_on_startup{16};
    channel_->Resize(max_windows_on_startup);
  }
}

void FlutterWindowManager::setEngine(
    std::shared_ptr<flutter::FlutterEngine> engine) {
  std::lock_guard<std::mutex> const lock(mutex_);
  engine_ = std::move(engine);
}

auto FlutterWindowManager::createRegularWindow(std::wstring const &title,
                                               Win32Window::Point const &origin,
                                               Win32Window::Size const &size)
    -> std::expected<flutter::FlutterViewId, Error> {
  std::unique_lock lock(mutex_);
  if (!engine_) {
    return std::unexpected<Error>(Error::EngineNotSet);
  }
  auto window{std::make_unique<FlutterWindow>(engine_)};

  lock.unlock();
  if (!window->Create(title, origin, size, mir::Archetype::regular, nullptr)) {
    return std::unexpected(Error::Win32Error);
  }
  lock.lock();

  // Assume first window is the main window
  if (windows_.empty()) {
    window->SetQuitOnClose(true);
  }

  auto const view_id{window->flutter_controller()->view_id()};
  windows_[view_id] = std::move(window);

  initializeChannel();
  cleanupClosedWindows();
  sendOnWindowCreated(mir::Archetype::regular, view_id, -1);

  lock.unlock();
  sendOnWindowResized(view_id);

  return view_id;
}

auto FlutterWindowManager::createPopupWindow(
    std::wstring const &title, Win32Window::Point const &origin,
    Win32Window::Size const &size,
    std::optional<flutter::FlutterViewId> parent_view_id)
    -> std::expected<flutter::FlutterViewId, Error> {
  std::unique_lock lock(mutex_);
  if (!engine_) {
    return std::unexpected<Error>(Error::EngineNotSet);
  }
  if (windows_.empty()) {
    return std::unexpected(Error::CannotBeFirstWindow);
  }

  auto *const parent_hwnd{parent_view_id && windows_.contains(*parent_view_id)
                              ? windows_[*parent_view_id].get()->GetHandle()
                              : nullptr};
  auto window{std::make_unique<FlutterWindow>(engine_)};

  lock.unlock();
  if (!window->Create(title, origin, size, mir::Archetype::popup,
                      parent_hwnd)) {
    return std::unexpected(Error::Win32Error);
  }
  lock.lock();

  auto const view_id{window->flutter_controller()->view_id()};
  windows_[view_id] = std::move(window);

  initializeChannel();
  cleanupClosedWindows();
  sendOnWindowCreated(mir::Archetype::popup, view_id,
                      parent_view_id ? *parent_view_id : -1);

  lock.unlock();
  sendOnWindowResized(view_id);

  return view_id;
}

auto FlutterWindowManager::destroyWindow(flutter::FlutterViewId view_id,
                                         bool destroy_native_window) -> bool {
  std::unique_lock lock(mutex_);
  if (windows_.contains(view_id)) {
    if (windows_[view_id]->GetQuitOnClose()) {
      for (auto &[id, window] : windows_) {
        if (id != view_id && window->flutter_controller()) {
          lock.unlock();
          window->Destroy();
          lock.lock();
        }
      }
    }
    if (destroy_native_window) {
      auto const &window{windows_[view_id]};
      lock.unlock();
      window->Destroy();
      lock.lock();
    }
    sendOnWindowDestroyed(view_id);
    return true;
  }
  return false;
}

void FlutterWindowManager::cleanupClosedWindows() {
  std::erase_if(windows_, [](auto const &window) {
    return !window.second->flutter_controller();
  });
}

auto FlutterWindowManager::windows() const -> WindowMap const & {
  std::lock_guard const lock(mutex_);
  return windows_;
}

auto FlutterWindowManager::channel() const
    -> std::unique_ptr<flutter::MethodChannel<>> const & {
  std::lock_guard const lock(mutex_);
  return channel_;
};

void FlutterWindowManager::sendOnWindowCreated(
    mir::Archetype archetype, flutter::FlutterViewId view_id,
    flutter::FlutterViewId parent_view_id) const {
  if (channel_) {
    channel_->InvokeMethod(
        "onWindowCreated",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
            {flutter::EncodableValue("viewId"),
             flutter::EncodableValue(view_id)},
            {flutter::EncodableValue("parentViewId"),
             flutter::EncodableValue(parent_view_id)},
            {flutter::EncodableValue("archetype"),
             flutter::EncodableValue(static_cast<int>(archetype))}}));
  }
}

void FlutterWindowManager::sendOnWindowDestroyed(
    flutter::FlutterViewId view_id) const {
  if (channel_) {
    channel_->InvokeMethod(
        "onWindowDestroyed",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
            {flutter::EncodableValue("viewId"),
             flutter::EncodableValue(view_id)},
        }));
  }
}

void FlutterWindowManager::sendOnWindowResized(
    flutter::FlutterViewId view_id) const {
  std::lock_guard const lock(mutex_);
  if (channel_) {
    auto *const hwnd{windows_.at(view_id)->GetHandle()};
    RECT frame;
    if (FAILED(DwmGetWindowAttribute(hwnd, DWMWA_EXTENDED_FRAME_BOUNDS, &frame,
                                     sizeof(frame)))) {
      GetWindowRect(hwnd, &frame);
    }

    // Convert to logical coordinates
    auto const dpr{FlutterDesktopGetDpiForHWND(hwnd) / base_dpi};
    frame.left = static_cast<LONG>(frame.left / dpr);
    frame.top = static_cast<LONG>(frame.top / dpr);
    frame.right = static_cast<LONG>(frame.right / dpr);
    frame.bottom = static_cast<LONG>(frame.bottom / dpr);

    auto const width{frame.right - frame.left};
    auto const height{frame.bottom - frame.top};
    channel_->InvokeMethod(
        "onWindowResized",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
            {flutter::EncodableValue("viewId"),
             flutter::EncodableValue(view_id)},
            {flutter::EncodableValue("width"),
             flutter::EncodableValue(static_cast<int>(width))},
            {flutter::EncodableValue("height"),
             flutter::EncodableValue(static_cast<int>(height))}}));
  }
}