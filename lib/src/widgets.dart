// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'inherited_views.dart';
import 'view_data.dart';

/// Calls [viewBuilder] for every view added to the app to obtain the widget to
/// render into that view. The current view can be looked up with [View.of].
class MultiViewApp extends StatefulWidget {
  const MultiViewApp({super.key, required this.viewBuilder});

  final WidgetBuilder viewBuilder;

  @override
  State<MultiViewApp> createState() => _MultiViewAppState();
}

class _MultiViewAppState extends State<MultiViewApp>
    with WidgetsBindingObserver {
  static const channel = MethodChannel('io.mir-server/window');

  Map<int, ViewData> _views = <int, ViewData>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    log('setMethodCallHandler');
    channel.setMethodCallHandler(_methodCallHandler);
    _updateViews();
  }

  @override
  void didUpdateWidget(MultiViewApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Need to re-evaluate the viewBuilder callback for all views.
    _views.clear();
    _updateViews();
  }

  @override
  void didChangeMetrics() {
    _updateViews();
  }

  bool _allViewsHaveArchetype() {
    return _views.values.every((viewData) => viewData.archetype != null);
  }

  void _updateViews() {
    log('updateViews - # of views: ${WidgetsBinding.instance.platformDispatcher.views.length}');
    final Map<int, ViewData> newViews = <int, ViewData>{};
    for (final FlutterView view
        in WidgetsBinding.instance.platformDispatcher.views) {
      final ViewData viewData = _views[view.viewId] ??
          ViewData(view, Builder(builder: widget.viewBuilder));
      newViews[view.viewId] = viewData;
    }
    setState(() {
      _views = newViews;
    });
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onWindowCreated':
        final int viewId = call.arguments['viewId'];
        final int? parentViewId = call.arguments['parentViewId'];
        final FlutterViewArchetype archetype =
            FlutterViewArchetype.values[call.arguments['archetype']];
        log('onWindowCreated - [id: $viewId] - [$archetype] - [parent: $parentViewId]');

        ViewData? viewData = _views[viewId];
        if (viewData != null) {
          viewData.archetype = archetype;
          if (parentViewId != null && _views[parentViewId] != null) {
            viewData.parentView = _views[parentViewId]?.view;
          }
          if (_allViewsHaveArchetype()) {
            setState(() {});
          }
        }
        break;
      case 'onWindowDestroyed':
        final int viewId = call.arguments['viewId'];
        log('onWindowDestroyed - [id: $viewId] - [${_views[viewId]?.archetype}] - [parent: ${_views[viewId]?.parentView}]');
        break;
      case 'onWindowResized':
        final int viewId = call.arguments['viewId'];
        final int width = call.arguments['width'];
        final int height = call.arguments['height'];
        final Size size = Size(width.toDouble(), height.toDouble());
        log('onWindowResized - [id: $viewId] - [size: (${size.width}, ${size.height})]');

        ViewData? viewData = _views[viewId];
        if (viewData != null) {
          viewData.size = size;
          if (_allViewsHaveArchetype()) {
            setState(() {});
          }
        }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget? _buildTree(FlutterView? parentView) {
    final List<ViewData> children = _views.values
        .where((viewData) => viewData.parentView == parentView)
        .toList();
    if (children.isEmpty) {
      return null;
    } else {
      if (parentView == null) {
        if (children.length == 1) {
          return View(
            view: children.first.view,
            child: _buildTree(children.first.view) ?? children.first.widget,
          );
        } else {
          final List<Widget> widgets = [];
          for (ViewData viewData in children) {
            Widget widget = View(
              view: viewData.view,
              child: _buildTree(viewData.view) ?? viewData.widget,
            );
            widgets.add(widget);
          }
          return ViewCollection(views: widgets);
        }
      } else {
        if (children.length == 1) {
          return ViewAnchor(
            view: View(
              view: children.first.view,
              child: _buildTree(children.first.view) ?? children.first.widget,
            ),
            child: _views.values
                .where((viewData) => viewData.view == parentView)
                .single
                .widget,
          );
        } else {
          final List<Widget> widgets = [];
          for (ViewData viewData in children) {
            Widget widget = View(
                view: viewData.view,
                child: _buildTree(viewData.view) ?? viewData.widget);
            widgets.add(widget);
          }
          return ViewAnchor(
            view: ViewCollection(views: widgets),
            child: _views.values
                .where((viewData) => viewData.view == parentView)
                .single
                .widget,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allViewsHaveArchetype()) {
      log("build (final tree)");
      return ViewsInheritedWidget(
        views: _views,
        child: _buildTree(null)!,
      );
    } else {
      log("build (placeholder tree)");
      return View(
        view: _views.values.first.view,
        child: const SizedBox.shrink(),
      );
    }
  }
}
