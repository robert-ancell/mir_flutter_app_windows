import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'custom_positioner_dialog.dart';
import 'window_settings_dialog.dart';

import 'app_model.dart';
import 'view_data.dart';
import 'inherited_views.dart';
import 'api/windowing_api.dart';
import 'api/flutter_view_positioner.dart';

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final viewDataMap = ViewsInheritedWidget.of(context)!.views;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppModel>(
          builder: (context, dataProvider, child) {
            return Text('Mir Window Test ${dataProvider.selectedRowIndex}');
          },
        ),
      ),
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
                              child: Consumer<AppModel>(
                                builder: (context, dataProvider, child) {
                                  return DataTable(
                                    showBottomBorder: true,
                                    onSelectAll: (selected) {
                                      context
                                          .read<AppModel>()
                                          .setSelectedRowIndex(-1);
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
                                      final isSelected =
                                          dataProvider.selectedRowIndex ==
                                              index;

                                      return DataRow(
                                        color: WidgetStateColor.resolveWith(
                                            (states) {
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
                                          // setState(() {
                                          if (selected != null) {
                                            context
                                                .read<AppModel>()
                                                .setSelectedRowIndex(
                                                    selected ? index : -1);
                                          }
                                          // });
                                        },
                                        cells: [
                                          DataCell(
                                            Text('$viewId'),
                                          ),
                                          DataCell(
                                            Text(archetype
                                                .toString()
                                                .replaceFirst(
                                                    'FlutterViewArchetype.',
                                                    '')),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outlined),
                                              onPressed: () {
                                                destroyWindow(viewId);
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  );
                                },
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
                                      Consumer<AppModel>(
                                        builder:
                                            (context, dataProvider, child) {
                                          return OutlinedButton(
                                            onPressed: () async {
                                              await createRegularWindow(
                                                  dataProvider.windowSettings[
                                                      'regularSize']);
                                            },
                                            child: const Text('Regular'),
                                          );
                                        },
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
                                      Consumer<AppModel>(
                                        builder:
                                            (context, dataProvider, child) {
                                          final selectedRowIndex =
                                              dataProvider.selectedRowIndex;
                                          final selectedPositionerSettings =
                                              dataProvider.positionerSettings[
                                                  dataProvider.positionerIndex];
                                          return OutlinedButton(
                                            onPressed: selectedRowIndex >= 0 &&
                                                    selectedRowIndex <
                                                        viewDataMap.length
                                                ? () async {
                                                    final selectedData =
                                                        viewDataMap
                                                            .entries
                                                            .toList()[
                                                                selectedRowIndex]
                                                            .value;
                                                    await createPopupWindow(
                                                      selectedData.view,
                                                      dataProvider
                                                              .windowSettings[
                                                          'popupSize'],
                                                      clampRectToSize(
                                                          dataProvider
                                                                  .windowSettings[
                                                              'anchorRect'],
                                                          selectedData.size),
                                                      FlutterViewPositioner(
                                                        parentAnchor:
                                                            selectedPositionerSettings[
                                                                'parentAnchor'],
                                                        childAnchor:
                                                            selectedPositionerSettings[
                                                                'childAnchor'],
                                                        offset:
                                                            selectedPositionerSettings[
                                                                'offset'],
                                                        constraintAdjustment:
                                                            selectedPositionerSettings[
                                                                'constraintAdjustments'],
                                                      ),
                                                    );
                                                  }
                                                : null,
                                            child: Text(dataProvider
                                                            .selectedRowIndex >=
                                                        0 &&
                                                    dataProvider
                                                            .selectedRowIndex <
                                                        viewDataMap.length
                                                ? 'Popup of ID ${viewDataMap.entries.toList()[dataProvider.selectedRowIndex].key}'
                                                : 'Popup'),
                                          );
                                        },
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
                                        child: Consumer<AppModel>(
                                          builder:
                                              (context, dataProvider, child) {
                                            return TextButton(
                                              child: const Text('SETTINGS'),
                                              onPressed: () {
                                                windowSettingsDialog(
                                                        context,
                                                        dataProvider
                                                            .windowSettings)
                                                    .then(
                                                  (Map<String, dynamic>?
                                                      settings) {
                                                    if (context.mounted &&
                                                        settings != null) {
                                                      context
                                                          .read<AppModel>()
                                                          .setWindowSettings(
                                                              settings);
                                                    }
                                                  },
                                                );
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
                                    subtitle: Consumer<AppModel>(
                                      builder: (context, dataProvider, child) {
                                        List<Map<String, dynamic>>
                                            positionerSettings =
                                            dataProvider.positionerSettings;
                                        return DropdownButton(
                                          items: positionerSettings
                                              .map((map) =>
                                                  map['name'] as String)
                                              .toList()
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          value: positionerSettings
                                                  .map((map) =>
                                                      map['name'] as String)
                                                  .toList()[
                                              dataProvider.positionerIndex],
                                          isExpanded: true,
                                          focusColor: Colors.transparent,
                                          onChanged: (String? value) {
                                            // setState(() {
                                            context
                                                .read<AppModel>()
                                                .setPositionerIndex(
                                                    positionerSettings
                                                        .map((map) =>
                                                            map['name']
                                                                as String)
                                                        .toList()
                                                        .indexOf(value!));
                                            // });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Consumer<AppModel>(
                                        builder:
                                            (context, dataProvider, child) {
                                          return TextButton(
                                            child: const Text('CUSTOM PRESET'),
                                            onPressed: () {
                                              customPositionerDialog(
                                                      context,
                                                      dataProvider
                                                          .positionerSettings
                                                          .last)
                                                  .then(
                                                (Map<String, dynamic>?
                                                    settings) {
                                                  if (settings != null) {
                                                    if (context.mounted) {
                                                      context
                                                          .read<AppModel>()
                                                          .setPositionerIndex(
                                                              dataProvider
                                                                      .positionerSettings
                                                                      .length -
                                                                  1);
                                                      context
                                                          .read<AppModel>()
                                                          .setCustomPositionerSettings(
                                                              settings);
                                                    }
                                                  }
                                                },
                                              );
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

  Rect clampRectToSize(Rect anchorRect, Size? size) {
    double left = anchorRect.left.clamp(0, size?.width as double);
    double top = anchorRect.top.clamp(0, size?.height as double);
    double right = anchorRect.right.clamp(0, size?.width as double);
    double bottom = anchorRect.bottom.clamp(0, size?.height as double);
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
