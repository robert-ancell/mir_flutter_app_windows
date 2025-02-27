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
import 'api/windowing_api.dart';

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
  static const channel = MethodChannel('flw/window');

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

        setState(() {
          ViewData? viewData = _views[viewId];
          if (viewData != null) {
            viewData.archetype = archetype;
            if (parentViewId != null && _views[parentViewId] != null) {
              viewData.parentView = _views[parentViewId]?.view;
            }
          }
        });
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

        setState(() {
          ViewData? viewData = _views[viewId];
          if (viewData != null) {
            viewData.size = size;
          }
        });
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
      getChild(ViewData viewData) =>
          _buildTree(viewData.view) ?? viewData.widget;
      if (parentView == null) {
        if (children.length == 1) {
          return children.first.archetype != null
              ? View(
                  view: children.first.view,
                  child: getChild(children.first),
                )
              : null;
        } else {
          final List<Widget> widgets = [];
          for (ViewData viewData
              in children.where((viewData) => viewData.archetype != null)) {
            final Widget widget = View(
              view: viewData.view,
              child: getChild(viewData),
            );
            widgets.add(widget);
          }
          return widgets.isNotEmpty ? ViewCollection(views: widgets) : null;
        }
      } else {
        if (children.length == 1) {
          return children.first.archetype != null
              ? ViewAnchor(
                  view: View(
                    view: children.first.view,
                    child: getChild(children.first),
                  ),
                  child: _views.values
                      .where((viewData) => viewData.view == parentView)
                      .single
                      .widget,
                )
              : null;
        } else {
          final List<Widget> widgets = [];
          for (ViewData viewData
              in children.where((viewData) => viewData.archetype != null)) {
            final Widget widget =
                View(view: viewData.view, child: getChild(viewData));
            widgets.add(widget);
          }
          return widgets.isNotEmpty
              ? ViewAnchor(
                  view: ViewCollection(views: widgets),
                  child: _views.values
                      .where((viewData) => viewData.view == parentView)
                      .single
                      .widget,
                )
              : null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    log("build tree");
    return ViewsInheritedWidget(
      views: _views,
      child: _buildTree(null) ??
          View(
              view: _views.entries.first.value.view,
              child: const SizedBox.shrink()),
    );
  }
}
