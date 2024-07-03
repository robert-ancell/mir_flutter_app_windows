import 'dart:ui';

import 'package:flutter/widgets.dart';

enum Archetype {
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
  Archetype? archetype;
  FlutterView? parentView;

  ViewData(this.view, this.widget, [this.archetype, this.parentView]);
}
