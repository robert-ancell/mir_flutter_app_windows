#ifndef RUNNER_FLUTTER_WINDOW_MANAGER_H_
#define RUNNER_FLUTTER_WINDOW_MANAGER_H_

#include <flutter/method_channel.h>

#include "flutter_window.h"
#include "mir_windowing_types.h"

#include <expected>

class FlutterWindowManager {
public:
  enum class Error {
    Win32Error,
    CannotBeFirstWindow,
  };
  using WindowMap = std::unordered_map<flutter::FlutterViewId,
                                       std::unique_ptr<FlutterWindow>>;

  static auto
  createRegularWindow(std::shared_ptr<flutter::FlutterEngine> const &engine,
                      std::wstring const &title,
                      Win32Window::Point const &origin,
                      Win32Window::Size const &size)
      -> std::expected<flutter::FlutterViewId, Error>;
  static auto createPopupWindow(
      std::shared_ptr<flutter::FlutterEngine> const &engine,
      std::wstring const &title, Win32Window::Point const &origin,
      Win32Window::Size const &size,
      std::optional<flutter::FlutterViewId> parent_view_id = std::nullopt)
      -> std::expected<flutter::FlutterViewId, Error>;
  static auto destroyWindow(flutter::FlutterViewId view_id,
                            bool destroy_native_window) -> bool;
  static auto windows() -> WindowMap const &;
  static auto channel() -> std::unique_ptr<flutter::MethodChannel<>> const&;

private:
  friend class FlutterWindow;

  static void
  initializeChannel(std::shared_ptr<flutter::FlutterEngine> const &engine);
  static void sendOnWindowCreated(mir::Archetype archetype,
                                  flutter::FlutterViewId view_id,
                                  flutter::FlutterViewId parent_view_id);
  static void sendOnWindowDestroyed(flutter::FlutterViewId view_id);
  static void sendOnWindowResized(flutter::FlutterViewId view_id);
  static void cleanupClosedWindows();

  static inline std::unique_ptr<flutter::MethodChannel<>> channel_;
  static inline WindowMap windows_;
};

#endif // RUNNER_FLUTTER_WINDOW_MANAGER_H_
