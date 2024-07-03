#ifndef RUNNER_FLUTTER_WINDOW_MANAGER_H_
#define RUNNER_FLUTTER_WINDOW_MANAGER_H_

#include <flutter/method_channel.h>

#include "flutter_window.h"

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
  static void cleanupClosedWindows();
  static auto windows() -> WindowMap const &;

private:
  static void
  initializeChannel(std::shared_ptr<flutter::FlutterEngine> const &engine);
  static void sendOnWindowCreated(Win32Window::Archetype archetype,
                                  flutter::FlutterViewId view_id,
                                  flutter::FlutterViewId parent_view_id);

  static inline std::unique_ptr<flutter::MethodChannel<>> channel_;
  static inline WindowMap windows_;
};

#endif // RUNNER_FLUTTER_WINDOW_MANAGER_H_
