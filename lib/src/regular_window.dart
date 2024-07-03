// import 'package:flutter/material.dart';

// import 'view_data.dart';
// import 'inherited_views.dart';
// import 'windowing_api.dart';

// class RegularWindow extends StatelessWidget {
//   const RegularWindow({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final views = ViewsInheritedWidget.of(context)!.views;
//     final ViewData viewData = views[View.of(context).viewId]!;

//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text('${viewData.archetype}')),
//         body: Column(
//           children: [
//             Center(
//               child: ElevatedButton(
//                 onPressed: () async {
//                   await createRegularWindow(const Size(500, 400));
//                 },
//                 child: const Text('Create Regular Window'),
//               ),
//             ),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () async {
//                   await createPopupWindow(viewData.view, const Size(200, 200));
//                 },
//                 child: const Text('Create Popup Window'),
//               ),
//             ),
//             Center(
//               child: Text('View #${viewData.view.viewId}\n'
//                   'Parent View: ${viewData.parentView?.viewId}\n'
//                   'Logical ${MediaQuery.of(context).size}\n'
//                   'DPR: ${MediaQuery.of(context).devicePixelRatio}'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'view_data.dart';
import 'inherited_views.dart';
import 'api/windowing_api.dart';

class RegularWindow extends StatelessWidget {
  const RegularWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final views = ViewsInheritedWidget.of(context)!.views;
    final ViewData viewData = views[View.of(context).viewId]!;

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
                  await createPopupWindow(viewData.view, const Size(200, 200));
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
