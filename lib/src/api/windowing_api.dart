import 'dart:ui' show FlutterView;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'flutter_view_positioner.dart';

const channel = MethodChannel('flw/window');

enum FlutterViewArchetype {
  regular,
  floatingRegular,
  dialog,
  satellite,
  popup,
  tip,
}

Future<FlutterView> createRegularWindow(Size size) async {
  int clampToZeroInt(double value) => value < 0 ? 0 : value.toInt();
  final int width = clampToZeroInt(size.width);
  final int height = clampToZeroInt(size.height);
  final viewId = await channel
      .invokeMethod('createRegularWindow', {'width': width, 'height': height});
  return WidgetsBinding.instance.platformDispatcher.views.firstWhere(
    (view) => view.viewId == viewId,
    orElse: () {
      throw Exception('No matching view found for viewId: $viewId');
    },
  );
}

Future<FlutterView> createPopupWindow(FlutterView parent, Size size,
    Rect anchorRect, FlutterViewPositioner positioner) async {
  int clampToZeroInt(double value) => value < 0 ? 0 : value.toInt();
  int constraintAdjustmentBitmask = 0;
  for (var adjustment in positioner.constraintAdjustment) {
    constraintAdjustmentBitmask |= 1 << adjustment.index;
  }

  final viewId = await channel.invokeMethod('createPopupWindow', {
    'parent': parent.viewId,
    'size': [clampToZeroInt(size.width), clampToZeroInt(size.height)],
    'anchorRect': [
      anchorRect.left.toInt(),
      anchorRect.top.toInt(),
      anchorRect.width.toInt(),
      anchorRect.height.toInt()
    ],
    'positionerParentAnchor': positioner.parentAnchor.index,
    'positionerChildAnchor': positioner.childAnchor.index,
    'positionerOffset': [
      positioner.offset.dx.toInt(),
      positioner.offset.dy.toInt()
    ],
    'positionerConstraintAdjustment': constraintAdjustmentBitmask
  });
  return WidgetsBinding.instance.platformDispatcher.views.firstWhere(
    (view) => view.viewId == viewId,
    orElse: () {
      throw Exception('No matching view found for viewId: $viewId');
    },
  );
}

void destroyWindow(FlutterView window) {
  channel.invokeMethod('destroyWindow', [window.viewId]);
}
