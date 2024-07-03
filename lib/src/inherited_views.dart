import 'package:flutter/material.dart';

import 'view_data.dart';

class ViewsInheritedWidget extends InheritedWidget {
  const ViewsInheritedWidget({
    super.key,
    required this.views,
    required super.child,
  });

  final Map<int, ViewData> views;

  static ViewsInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ViewsInheritedWidget>();
  }

  @override
  bool updateShouldNotify(ViewsInheritedWidget oldWidget) {
    return views != oldWidget.views;
  }
}
