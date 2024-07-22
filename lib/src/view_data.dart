import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';
import 'api/windowing_api.dart';

class ViewData {
  final FlutterView view;
  final Widget widget;
  FlutterViewArchetype? archetype;
  FlutterView? parentView;
  Size? size;

  ViewData(this.view, this.widget,
      [this.archetype, this.parentView, this.size]);
}
