import 'dart:collection';

import 'package:flutter/material.dart';

import 'api/flutter_view_positioner.dart';

class AppModel extends ChangeNotifier {
  int _selectedRowIndex = -1;
  int _positionerIndex = 0;

  Map<String, dynamic> _windowSettings = {
    'regularSize': const Size(400, 300),
    'floatingRegularSize': const Size(300, 300),
    'dialogSize': const Size(200, 200),
    'satelliteSize': const Size(150, 300),
    'popupSize': const Size(200, 200),
    'tipSize': const Size(140, 140),
    'anchorRect': const Rect.fromLTWH(0, 0, 1000, 1000),
  };

  final List<Map<String, dynamic>> _positionerSettings = [
    // Left
    const <String, dynamic>{
      'name': 'Left',
      'parentAnchor': FlutterViewPositionerAnchor.left,
      'childAnchor': FlutterViewPositionerAnchor.right,
      'offset': Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Right
    const <String, dynamic>{
      'name': 'Right',
      'parentAnchor': FlutterViewPositionerAnchor.right,
      'childAnchor': FlutterViewPositionerAnchor.left,
      'offset': Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Bottom Left
    const <String, dynamic>{
      'name': 'Bottom Left',
      'parentAnchor': FlutterViewPositionerAnchor.bottomLeft,
      'childAnchor': FlutterViewPositionerAnchor.topRight,
      'offset': Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Bottom
    const <String, dynamic>{
      'name': 'Bottom',
      'parentAnchor': FlutterViewPositionerAnchor.bottom,
      'childAnchor': FlutterViewPositionerAnchor.top,
      'offset': Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Bottom Right
    const <String, dynamic>{
      'name': 'Bottom Right',
      'parentAnchor': FlutterViewPositionerAnchor.bottomRight,
      'childAnchor': FlutterViewPositionerAnchor.topLeft,
      'offset': Offset(0, 0),
      'constraintAdjustments': <FlutterViewPositionerConstraintAdjustment>{
        FlutterViewPositionerConstraintAdjustment.slideX,
        FlutterViewPositionerConstraintAdjustment.slideY,
      }
    },
    // Center
    const <String, dynamic>{
      'name': 'Center',
      'parentAnchor': FlutterViewPositionerAnchor.center,
      'childAnchor': FlutterViewPositionerAnchor.center,
      'offset': Offset(0, 0),
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

  int get selectedRowIndex => _selectedRowIndex;
  int get positionerIndex => _positionerIndex;
  UnmodifiableMapView<String, dynamic> get windowSettings =>
      UnmodifiableMapView(_windowSettings);
  UnmodifiableListView<Map<String, dynamic>> get positionerSettings =>
      UnmodifiableListView(_positionerSettings);

  void setSelectedRowIndex(int index) {
    _selectedRowIndex = index;
    notifyListeners();
  }

  void setPositionerIndex(int index) {
    _positionerIndex = index;
    notifyListeners();
  }

  void setWindowSettings(Map<String, dynamic> settings) {
    _windowSettings = settings;
    notifyListeners();
  }

  void setCustomPositionerSettings(Map<String, dynamic> settings) {
    _positionerSettings.last = settings;
    notifyListeners();
  }
}
