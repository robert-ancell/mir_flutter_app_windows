import 'package:flutter/material.dart';

import 'custom_positioner_dialog.dart';
import 'window_settings_dialog.dart';

import 'view_data.dart';
import 'inherited_views.dart';
import 'api/windowing_api.dart';
import 'api/flutter_view_positioner.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainPageState();
}

class _MainPageState extends State<MainWindow> {
  Map<String, dynamic> windowSettings = {
    'regularSize': const Size(400, 300),
    'floatingRegularSize': const Size(300, 300),
    'dialogSize': const Size(200, 200),
    'satelliteSize': const Size(150, 300),
    'popupSize': const Size(200, 200),
    'tipSize': const Size(140, 140),
    'anchorRect': const Rect.fromLTWH(0, 0, 1000, 1000),
  };

  int positionerIndex = 0;
  List<Map<String, dynamic>> positionerSettings = [
    // Left
    <String, dynamic>{
      'name': 'Left',
      'parentAnchor': FlutterViewPositionerAnchor.left,
      'childAnchor': FlutterViewPositionerAnchor.right,
      'offset': const Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Right
    <String, dynamic>{
      'name': 'Right',
      'parentAnchor': FlutterViewPositionerAnchor.right,
      'childAnchor': FlutterViewPositionerAnchor.left,
      'offset': const Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Bottom Left
    <String, dynamic>{
      'name': 'Bottom Left',
      'parentAnchor': FlutterViewPositionerAnchor.bottomLeft,
      'childAnchor': FlutterViewPositionerAnchor.topRight,
      'offset': const Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Bottom
    <String, dynamic>{
      'name': 'Bottom',
      'parentAnchor': FlutterViewPositionerAnchor.bottom,
      'childAnchor': FlutterViewPositionerAnchor.top,
      'offset': const Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Bottom Right
    <String, dynamic>{
      'name': 'Bottom Right',
      'parentAnchor': FlutterViewPositionerAnchor.bottomRight,
      'childAnchor': FlutterViewPositionerAnchor.topLeft,
      'offset': const Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Center
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
    // Custom
    <String, dynamic>{
      'name': 'Custom',
      'parentAnchor': FlutterViewPositionerAnchor.left,
      'childAnchor': FlutterViewPositionerAnchor.right,
      'offset': const Offset(0, 50),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    }
  ];

  int selectedRowIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final viewDataMap = ViewsInheritedWidget.of(context)!.views;

    return Scaffold(
      appBar: AppBar(title: Text('Mir Window Test $positionerIndex')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 400,
                            height: 500,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                showBottomBorder: true,
                                onSelectAll: (selected) {
                                  setState(() {
                                    selectedRowIndex = -1;
                                  });
                                },
                                columns: const [
                                  DataColumn(
                                    label: SizedBox(
                                      width: 20,
                                      child: Text(
                                        'ID',
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Type',
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                      label: SizedBox(
                                        width: 20,
                                        child: Text(''),
                                      ),
                                      numeric: true),
                                ],
                                rows: viewDataMap.entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map<DataRow>((indexedEntry) {
                                  final index = indexedEntry.key;
                                  final MapEntry<int, ViewData> entry =
                                      indexedEntry.value;
                                  final viewData = entry.value;
                                  final viewId = viewData.view.viewId;
                                  final archetype = viewData.archetype ??
                                      FlutterViewArchetype.regular;
                                  final isSelected = selectedRowIndex == index;

                                  return DataRow(
                                    color:
                                        WidgetStateColor.resolveWith((states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.08);
                                      }
                                      return Colors.transparent;
                                    }),
                                    selected: isSelected,
                                    onSelectChanged: (selected) {
                                      setState(() {
                                        if (selected != null) {
                                          selectedRowIndex =
                                              selected ? index : -1;
                                        }
                                      });
                                    },
                                    cells: [
                                      DataCell(
                                        Text('$viewId'),
                                      ),
                                      DataCell(
                                        Text(archetype.toString().replaceFirst(
                                            'FlutterViewArchetype.', '')),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon:
                                              const Icon(Icons.delete_outlined),
                                          onPressed: () {
                                            destroyWindow(viewId);
                                            setState(() {});
                                            // resetWindowId(viewId);
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card.outlined(
                            margin: const EdgeInsets.symmetric(horizontal: 25),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 25, 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(top: 10, bottom: 10),
                                    child: Text(
                                      'New Window',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () async {
                                          await createRegularWindow(
                                              windowSettings['regularSize']);
                                        },
                                        child: const Text('Regular'),
                                      ),
                                      const SizedBox(height: 8),
                                      // OutlinedButton(
                                      //   onPressed: () async {
                                      //     final windowId =
                                      //         await createFloatingRegularWindow(
                                      //             windowSettings[
                                      //                 'floatingRegularSize']);
                                      //     await setWindowId(windowId);
                                      //     setState(() {
                                      //       selectedRowIndex =
                                      //           windows.indexWhere((window) =>
                                      //               window['id'] == windowId);
                                      //     });
                                      //   },
                                      //   child: const Text('Floating Regular'),
                                      // ),
                                      // const SizedBox(height: 8),
                                      // OutlinedButton(
                                      //   onPressed: () async {
                                      //     final windowId =
                                      //         await createDialogWindow(
                                      //             windowSettings['dialogSize'],
                                      //             selectedRowIndex >= 0 &&
                                      //                     isMirShellWindow(
                                      //                         selectedRowIndex)
                                      //                 ? windows[
                                      //                         selectedRowIndex]
                                      //                     ['id']
                                      //                 : null);
                                      //     await setWindowId(windowId);
                                      //   },
                                      //   child: Text(selectedRowIndex >= 0 &&
                                      //           isMirShellWindow(
                                      //               selectedRowIndex)
                                      //       ? 'Dialog of ID ${windows[selectedRowIndex]['id']}'
                                      //       : 'Dialog'),
                                      // ),
                                      // const SizedBox(height: 8),
                                      // OutlinedButton(
                                      //   onPressed: selectedRowIndex >= 0 &&
                                      //           isMirShellWindow(
                                      //               selectedRowIndex)
                                      //       ? () async {
                                      //           final windowId =
                                      //               await createSatelliteWindow(
                                      //             windows[selectedRowIndex]
                                      //                 ['id'],
                                      //             windowSettings[
                                      //                 'satelliteSize'],
                                      //             clampAnchorRectToSize(
                                      //                 await getWindowSize(windows[
                                      //                         selectedRowIndex]
                                      //                     ['id'])),
                                      //             FlutterViewPositioner(
                                      //               parentAnchor:
                                      //                   positionerSettings[
                                      //                           positionerIndex]
                                      //                       ['parentAnchor'],
                                      //               childAnchor:
                                      //                   positionerSettings[
                                      //                           positionerIndex]
                                      //                       ['childAnchor'],
                                      //               offset: positionerSettings[
                                      //                       positionerIndex]
                                      //                   ['offset'],
                                      //               constraintAdjustment:
                                      //                   positionerSettings[
                                      //                           positionerIndex]
                                      //                       [
                                      //                       'constraintAdjustments'],
                                      //             ),
                                      //           );
                                      //           await setWindowId(windowId);
                                      //           setState(() {
                                      //             // Cycle through presets when the last one (Custom preset) is not selected
                                      //             if (positionerIndex !=
                                      //                 positionerSettings
                                      //                         .length -
                                      //                     1) {
                                      //               positionerIndex =
                                      //                   (positionerIndex + 1) %
                                      //                       (positionerSettings
                                      //                               .length -
                                      //                           1);
                                      //             }
                                      //           });
                                      //         }
                                      //       : null,
                                      //   child: Text(selectedRowIndex >= 0
                                      //       ? 'Satellite of ID ${windows[selectedRowIndex]['id']}'
                                      //       : 'Satellite'),
                                      // ),
                                      // const SizedBox(height: 8),
                                      OutlinedButton(
                                        onPressed: selectedRowIndex >= 0 &&
                                                selectedRowIndex <
                                                    viewDataMap.length
                                            ? () async {
                                                final selectedData = viewDataMap
                                                    .entries
                                                    .toList()[selectedRowIndex]
                                                    .value;
                                                await createPopupWindow(
                                                  selectedData.view,
                                                  windowSettings['popupSize'],
                                                  clampAnchorRectToSize(
                                                      selectedData.size),
                                                  FlutterViewPositioner(
                                                    parentAnchor:
                                                        positionerSettings[
                                                                positionerIndex]
                                                            ['parentAnchor'],
                                                    childAnchor:
                                                        positionerSettings[
                                                                positionerIndex]
                                                            ['childAnchor'],
                                                    offset: positionerSettings[
                                                            positionerIndex]
                                                        ['offset'],
                                                    constraintAdjustment:
                                                        positionerSettings[
                                                                positionerIndex]
                                                            [
                                                            'constraintAdjustments'],
                                                  ),
                                                );
                                              }
                                            : null,
                                        child: Text(selectedRowIndex >= 0 &&
                                                selectedRowIndex <
                                                    viewDataMap.length
                                            ? 'Popup of ID ${viewDataMap.entries.toList()[selectedRowIndex].key}'
                                            : 'Popup'),
                                      ),
                                      // const SizedBox(height: 8),
                                      // OutlinedButton(
                                      //   onPressed: selectedRowIndex >= 0
                                      //       ? () async {
                                      //           final windowId =
                                      //               await createTipWindow(
                                      //             windows[selectedRowIndex]
                                      //                 ['id'],
                                      //             windowSettings['tipSize'],
                                      //             clampAnchorRectToSize(
                                      //                 await getWindowSize(windows[
                                      //                         selectedRowIndex]
                                      //                     ['id'])),
                                      //             FlutterViewPositioner(
                                      //               parentAnchor:
                                      //                   positionerSettings[
                                      //                           positionerIndex]
                                      //                       ['parentAnchor'],
                                      //               childAnchor:
                                      //                   positionerSettings[
                                      //                           positionerIndex]
                                      //                       ['childAnchor'],
                                      //               offset: positionerSettings[
                                      //                       positionerIndex]
                                      //                   ['offset'],
                                      //               constraintAdjustment:
                                      //                   positionerSettings[
                                      //                           positionerIndex]
                                      //                       [
                                      //                       'constraintAdjustments'],
                                      //             ),
                                      //           );
                                      //           await setWindowId(windowId);
                                      //           setState(() {
                                      //             // Cycle through presets when the last one (Custom preset) is not selected
                                      //             if (positionerIndex !=
                                      //                 positionerSettings
                                      //                         .length -
                                      //                     1) {
                                      //               positionerIndex =
                                      //                   (positionerIndex + 1) %
                                      //                       (positionerSettings
                                      //                               .length -
                                      //                           1);
                                      //             }
                                      //           });
                                      //         }
                                      //       : null,
                                      //   child: Text(selectedRowIndex >= 0
                                      //       ? 'Tip of ID ${windows[selectedRowIndex]['id']}'
                                      //       : 'Tip'),
                                      // ),
                                      const SizedBox(height: 8),
                                      Container(
                                        alignment: Alignment.bottomRight,
                                        child: TextButton(
                                          child: const Text('SETTINGS'),
                                          onPressed: () {
                                            windowSettingsDialog(
                                                    context, windowSettings)
                                                .then(
                                              (Map<String, dynamic>? settings) {
                                                setState(() {
                                                  if (settings != null) {
                                                    windowSettings = settings;
                                                  }
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card.outlined(
                            margin: const EdgeInsets.symmetric(horizontal: 25),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 15, 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      'Positioner',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    title: const Text('Preset'),
                                    subtitle: DropdownButton(
                                      items: positionerSettings
                                          .map((map) => map['name'] as String)
                                          .toList()
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      value: positionerSettings
                                          .map((map) => map['name'] as String)
                                          .toList()[positionerIndex],
                                      isExpanded: true,
                                      focusColor: Colors.transparent,
                                      onChanged: (String? value) {
                                        setState(() {
                                          positionerIndex = positionerSettings
                                              .map((map) =>
                                                  map['name'] as String)
                                              .toList()
                                              .indexOf(value!);
                                        });
                                      },
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: TextButton(
                                        child: const Text('CUSTOM PRESET'),
                                        onPressed: () {
                                          customPositionerDialog(
                                                  context,
                                                  positionerSettings[
                                                      positionerSettings
                                                              .length -
                                                          1])
                                              .then(
                                            (Map<String, dynamic>? settings) {
                                              setState(() {
                                                if (settings != null) {
                                                  positionerSettings[
                                                      positionerSettings
                                                              .length -
                                                          1] = settings;
                                                  positionerIndex =
                                                      positionerSettings
                                                              .length -
                                                          1;
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void destroyWindow(int windowId) {
    channel.invokeMethod('destroyWindow', [windowId]);
  }

  Rect clampAnchorRectToSize(Size? size) {
    double left = windowSettings['anchorRect'].left.clamp(0, size?.width);
    double top = windowSettings['anchorRect'].top.clamp(0, size?.height);
    double right = windowSettings['anchorRect'].right.clamp(0, size?.width);
    double bottom = windowSettings['anchorRect'].bottom.clamp(0, size?.height);
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
