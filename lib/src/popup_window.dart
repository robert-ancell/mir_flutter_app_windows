import 'package:flutter/material.dart';

import 'view_data.dart';
import 'inherited_views.dart';
import 'api/windowing_api.dart';

class PopupWindow extends StatelessWidget {
  const PopupWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final views = ViewsInheritedWidget.of(context)!.views;
    final ViewData viewData = views[View.of(context).viewId]!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Popup',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    await createPopupWindow(
                        viewData.view, const Size(200, 200));
                  },
                  child: const Text('Another popup'),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'View #${viewData.view.viewId}\n'
                  'Parent View: ${viewData.parentView?.viewId}\n'
                  'Logical ${MediaQuery.of(context).size}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
