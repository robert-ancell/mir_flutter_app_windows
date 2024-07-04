import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';

enum FlutterViewArchetype {
  regular,
  floatingRegular,
  dialog,
  satellite,
  popup,
  tip,
}

class ViewData {
  final FlutterView view;
  final Widget widget;
  FlutterViewArchetype? archetype;
  FlutterView? parentView;

  ViewData(this.view, this.widget, [this.archetype, this.parentView]);
}
