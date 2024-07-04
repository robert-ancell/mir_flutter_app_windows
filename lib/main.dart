import 'package:flutter/material.dart';

import 'src/view_data.dart';
import 'src/widgets.dart';
import 'src/inherited_views.dart';

import 'src/main_window.dart';
import 'src/regular_window.dart';
import 'src/popup_window.dart';

void main() {
  runWidget(MultiViewApp(
    viewBuilder: (BuildContext context) => const App(),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final views = ViewsInheritedWidget.of(context)!.views;
    final ViewData viewData = views[View.of(context).viewId]!;

    if (viewData.view.viewId == 0) {
      return const MaterialApp(
        home: MainWindow(),
      );
    } else {
      switch (viewData.archetype) {
        case FlutterViewArchetype.popup:
          return const PopupWindow();
        case FlutterViewArchetype.regular:
          return const RegularWindow();
        default:
          return const RegularWindow();
      }
    }
  }
}
