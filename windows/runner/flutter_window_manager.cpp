#include "flutter_window_manager.h"

#include <flutter/encodable_value.h>
#include <flutter/standard_method_codec.h>

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

void handleCreateRegularWindow(
    std::shared_ptr<flutter::FlutterEngine> const &engine,
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
          auto const &windows{FlutterWindowManager::windows()};
          return windows.contains(0)
                     ? calculateCenteredOrigin(size, windows.at(0)->GetHandle())
                     : Win32Window::Point{0, 0};
        }()};

        if (auto const view_id{FlutterWindowManager::createRegularWindow(
                engine, L"regular", origin, size)}) {
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

void handleCreatePopupWindow(
    std::shared_ptr<flutter::FlutterEngine> const &engine,
    flutter::MethodCall<> const &call,
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
      auto const *const parent{std::get_if<int>(&parent_it->second)};
      if (!parent) {
        result->Error("INVALID_VALUE",
                      "Value for 'parent' must be of type int.");
        return;
      }

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

      auto const *const positioner_parent_anchor{
          std::get_if<int>(&positioner_parent_anchor_it->second)};
      if (!positioner_parent_anchor) {
        result->Error(
            "INVALID_VALUE",
            "Value for 'positionerParentAnchor' must be of type int.");
        return;
      }

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

      // TODO: Set origin according to positioner

      // Set the origin to the mouse position
      auto const origin{[]() -> Win32Window::Point {
        POINT point;
        GetCursorPos(&point);
        auto *const monitor{MonitorFromPoint(point, MONITOR_DEFAULTTONEAREST)};
        auto const dpr{FlutterDesktopGetDpiForMonitor(monitor) / base_dpi};
        return {static_cast<unsigned int>(point.x / dpr),
                static_cast<unsigned int>(point.y / dpr)};
      }()};

      if (auto const view_id{FlutterWindowManager::createPopupWindow(
              engine, L"popup", origin, size, *parent)}) {
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
    if (FlutterWindowManager::destroyWindow(view_id, true)) {
      result->Success();
    } else {
      result->Error("UNAVAILABLE", "Can't destroy window.");
    }
  }
}

} // namespace

void FlutterWindowManager::initializeChannel(
    std::shared_ptr<flutter::FlutterEngine> const &engine) {
  if (!channel_) {
    channel_ = std::make_unique<flutter::MethodChannel<>>(
        engine->messenger(), CHANNEL,
        &flutter::StandardMethodCodec::GetInstance());
    channel_->SetMethodCallHandler(
        [engine](flutter::MethodCall<> const &call,
                 std::unique_ptr<flutter::MethodResult<>> result) {
          if (call.method_name() == "createRegularWindow") {
            handleCreateRegularWindow(engine, call, result);
          } else if (call.method_name() == "createPopupWindow") {
            handleCreatePopupWindow(engine, call, result);
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
    channel_->Resize(16);
  }
}

auto FlutterWindowManager::createRegularWindow(
    std::shared_ptr<flutter::FlutterEngine> const &engine,
    std::wstring const &title, Win32Window::Point const &origin,
    Win32Window::Size const &size)
    -> std::expected<flutter::FlutterViewId, Error> {
  auto window{std::make_unique<FlutterWindow>(engine)};
  if (!window->Create(title, origin, size, mir::Archetype::regular, nullptr)) {
    return std::unexpected(Error::Win32Error);
  }

  // Assume first window is the main window
  if (windows_.empty()) {
    window->SetQuitOnClose(true);
  }

  auto const view_id{window->flutter_controller()->view_id()};
  windows_[view_id] = std::move(window);

  initializeChannel(engine);
  cleanupClosedWindows();
  sendOnWindowCreated(mir::Archetype::regular, view_id, -1);

  return view_id;
}

auto FlutterWindowManager::createPopupWindow(
    std::shared_ptr<flutter::FlutterEngine> const &engine,
    std::wstring const &title, Win32Window::Point const &origin,
    Win32Window::Size const &size,
    std::optional<flutter::FlutterViewId> parent_view_id)
    -> std::expected<flutter::FlutterViewId, Error> {
  if (windows_.empty()) {
    return std::unexpected(Error::CannotBeFirstWindow);
  }

  auto *const parent_hwnd{parent_view_id && windows_.contains(*parent_view_id)
                              ? windows_[*parent_view_id].get()->GetHandle()
                              : nullptr};
  auto window{std::make_unique<FlutterWindow>(engine)};
  if (!window->Create(title, origin, size, mir::Archetype::popup,
                      parent_hwnd)) {
    return std::unexpected(Error::Win32Error);
  }

  auto const view_id{window->flutter_controller()->view_id()};
  windows_[view_id] = std::move(window);

  initializeChannel(engine);
  cleanupClosedWindows();
  sendOnWindowCreated(mir::Archetype::popup, view_id,
                      parent_view_id ? *parent_view_id : -1);

  return view_id;
}

auto FlutterWindowManager::destroyWindow(flutter::FlutterViewId view_id,
                                         bool destroy_native_window) -> bool {
  if (windows_.contains(view_id)) {
    if (windows_[view_id]->GetQuitOnClose()) {
      for (auto &[id, window] : windows_) {
        if (id != view_id && window->flutter_controller()) {
          window->Destroy();
        }
      }
    }
    if (destroy_native_window) {
      windows_[view_id]->Destroy();
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

auto FlutterWindowManager::windows() -> WindowMap const & { return windows_; }

auto FlutterWindowManager::channel()
    -> std::unique_ptr<flutter::MethodChannel<>> const & {
  return channel_;
};

void FlutterWindowManager::sendOnWindowCreated(
    mir::Archetype archetype, flutter::FlutterViewId view_id,
    flutter::FlutterViewId parent_view_id) {
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
  sendOnWindowResized(view_id);
}

void FlutterWindowManager::sendOnWindowDestroyed(
    flutter::FlutterViewId view_id) {
  if (channel_) {
    channel_->InvokeMethod(
        "onWindowDestroyed",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
            {flutter::EncodableValue("viewId"),
             flutter::EncodableValue(view_id)},
        }));
  }
}

void FlutterWindowManager::sendOnWindowResized(flutter::FlutterViewId view_id) {
  if (channel_) {
    auto const rect{windows_[view_id]->GetClientArea()};
    auto const width{rect.right - rect.left};
    auto const height{rect.bottom - rect.top};
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