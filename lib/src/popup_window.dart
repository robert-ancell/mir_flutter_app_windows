import 'package:flutter/material.dart';

import 'inherited_views.dart';
import 'api/windowing_api.dart';
import 'api/flutter_view_positioner.dart';

class PopupWindow extends StatelessWidget {
  const PopupWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final viewDataMap = ViewsInheritedWidget.of(context)!.views;
    final viewData = viewDataMap[View.of(context).viewId]!;

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
                      viewData.view,
                      const Size(200, 200),
                      Rect.fromLTWH(
                          0, 0, viewData.size!.width, viewData.size!.height),
                      const FlutterViewPositioner(
                        parentAnchor: FlutterViewPositionerAnchor.center,
                        childAnchor: FlutterViewPositionerAnchor.center,
                        offset: Offset(0, 0),
                        constraintAdjustment: <FlutterViewPositionerConstraintAdjustment>{
                          FlutterViewPositionerConstraintAdjustment.slideX,
                          FlutterViewPositionerConstraintAdjustment.slideY,
                        },
                      ),
                    );
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


/*
    <String, dynamic>{
      'name': 'Center',
      'parentAnchor': FlutterViewPositionerAnchor.center,
      'childAnchor': FlutterViewPositionerAnchor.center,
      'offset': const Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
*/