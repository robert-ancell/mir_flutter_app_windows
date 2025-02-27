// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/flutter_view_controller.h>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
public:
  // Creates a new FlutterWindow hosting a Flutter view running |engine|.
  explicit FlutterWindow(std::shared_ptr<flutter::FlutterEngine> engine);
  virtual ~FlutterWindow() = default;

  auto flutter_controller() -> std::unique_ptr<flutter::FlutterViewController> const&;

protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) override;

private:
  // The engine this window is attached to.
  std::shared_ptr<flutter::FlutterEngine> engine_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif // RUNNER_FLUTTER_WINDOW_H_
