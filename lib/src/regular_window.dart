import 'package:flutter/material.dart';

import 'inherited_views.dart';
import 'api/windowing_api.dart';
import 'api/flutter_view_positioner.dart';

class RegularWindow extends StatelessWidget {
  const RegularWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final viewDataMap = ViewsInheritedWidget.of(context)!.views;
    final viewData = viewDataMap[View.of(context).viewId]!;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('${viewData.archetype}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await createRegularWindow(const Size(400, 300));
                },
                child: const Text('Create Regular Window'),
              ),
              const SizedBox(height: 10),
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
                child: const Text('Create Popup Window'),
              ),
              const SizedBox(height: 20),
              Text(
                'View #${viewData.view.viewId}\n'
                'Parent View: ${viewData.parentView?.viewId}\n'
                'Logical ${MediaQuery.of(context).size}\n'
                'DPR: ${MediaQuery.of(context).devicePixelRatio}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
