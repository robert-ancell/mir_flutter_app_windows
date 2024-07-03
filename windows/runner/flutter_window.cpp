// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter_window.h"

#include <windows.h>

#include "flutter_window_manager.h"

FlutterWindow::FlutterWindow(std::shared_ptr<flutter::FlutterEngine> engine)
    : engine_(std::move(engine)) {}

auto FlutterWindow::flutter_controller()
    -> std::unique_ptr<flutter::FlutterViewController> const & {
  return flutter_controller_;
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT const frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, engine_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->view()) {
    return false;
  }

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // TODO(loicsharma): Hide the window until the first frame is rendered.
  // Single window apps use the engine's next frame callback to show the window.
  // This doesn't work for multi window apps as the engine cannot have multiple
  // next frame callbacks. If multiple windows are created, only the last one
  // will be shown.
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    FlutterWindowManager::destroyWindow(flutter_controller_->view_id(), false);
    if (flutter_controller_) {
      flutter_controller_ = nullptr;
    }
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  if (message == WM_FONTCHANGE) {
    engine_->ReloadSystemFonts();
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
