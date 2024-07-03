# mir_flutter_app_windows

Reference application demonstrating multi-window support for Flutter on Windows using the Mir windowing language.

## How To Build

Follow the guide from the ["MVP - The Multi View Playground"](https://github.com/goderbauer/mvp) repo to set up the development environment and build a custom engine. The guide shows how to patch the engine to add support for the multi-view runner APIs on Windows.

In addition to the patch from the MVP repo, apply [`146251.patch`](146251.patch) as a quick-and-dirty workaround for issue [#146251](https://github.com/flutter/flutter/issues/146251). This will prevent the engine from crashing when moving the pointer back and forth between overlapped windows.

After building the custom engine, run the application with:

```
flutter run --debug --local-engine-src-path <custom-engine-path> --local-engine host_debug_unopt --local-engine-host host_debug_unopt lib\main.dart
```
where `<custom-engine-path>` is the path to the source code of the custom engine (e.g., `C:/engine/src`).