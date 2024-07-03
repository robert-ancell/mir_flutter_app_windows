import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

const channel = MethodChannel('io.mir-server/window');

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

Future<FlutterView> createPopupWindow(FlutterView parent, Size size) async {
  int clampToZeroInt(double value) => value < 0 ? 0 : value.toInt();
  final int width = clampToZeroInt(size.width);
  final int height = clampToZeroInt(size.height);
  final viewId = await channel.invokeMethod('createPopupWindow',
      {'parent': parent.viewId, 'width': width, 'height': height});
  return WidgetsBinding.instance.platformDispatcher.views.firstWhere(
    (view) => view.viewId == viewId,
    orElse: () {
      throw Exception('No matching view found for viewId: $viewId');
    },
  );
}
