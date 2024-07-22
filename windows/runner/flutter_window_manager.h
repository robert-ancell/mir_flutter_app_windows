#ifndef RUNNER_FLUTTER_WINDOW_MANAGER_H_
#define RUNNER_FLUTTER_WINDOW_MANAGER_H_

#include <flutter/method_channel.h>

#include "flutter_window.h"
#include "mir_windowing_types.h"

#include <expected>
#include <mutex>

class FlutterWindowManager {
public:
  FlutterWindowManager(FlutterWindowManager const &) = delete;
  FlutterWindowManager(FlutterWindowManager &&) = delete;
  FlutterWindowManager &operator=(FlutterWindowManager const &) = delete;
  FlutterWindowManager &operator=(FlutterWindowManager &&) = delete;
  ~FlutterWindowManager() = default;

  enum class Error {
    Win32Error,
    CannotBeFirstWindow,
    EngineNotSet,
  };
  using WindowMap = std::unordered_map<flutter::FlutterViewId,
                                       std::unique_ptr<FlutterWindow>>;

  static FlutterWindowManager &instance() {
    static FlutterWindowManager instance;
    return instance;
  }

  void setEngine(std::shared_ptr<flutter::FlutterEngine> engine);
  auto createRegularWindow(std::wstring const &title,
                           Win32Window::Point const &origin,
                           Win32Window::Size const &size)
      -> std::expected<flutter::FlutterViewId, Error>;
  auto createPopupWindow(
      std::wstring const &title, Win32Window::Point const &origin,
      Win32Window::Size const &size,
      std::optional<flutter::FlutterViewId> parent_view_id = std::nullopt)
      -> std::expected<flutter::FlutterViewId, Error>;
  auto destroyWindow(flutter::FlutterViewId view_id,
                     bool destroy_native_window) -> bool;
  auto windows() const -> WindowMap const &;
  auto channel() const -> std::unique_ptr<flutter::MethodChannel<>> const &;

private:
  friend class FlutterWindow;

  FlutterWindowManager() = default;

  void initializeChannel();
  void sendOnWindowCreated(mir::Archetype archetype,
                           flutter::FlutterViewId view_id,
                           std::optional<flutter::FlutterViewId> parent_view_id) const;
  void sendOnWindowDestroyed(flutter::FlutterViewId view_id) const;
  void sendOnWindowResized(flutter::FlutterViewId view_id) const;
  void cleanupClosedWindows();

  mutable std::mutex mutex_;
  std::unique_ptr<flutter::MethodChannel<>> channel_;
  std::shared_ptr<flutter::FlutterEngine> engine_;
  WindowMap windows_;
};

#endif // RUNNER_FLUTTER_WINDOW_MANAGER_H_
