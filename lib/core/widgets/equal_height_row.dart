import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Children side by side in columns of relative width [flex] (equal when
/// null), all as tall as the tallest one: a button whose label wraps to two
/// lines makes its neighbour match. Unlike IntrinsicHeight it works with
/// children that use LayoutBuilder (it lays each child out twice instead of
/// asking for intrinsic sizes).
class EqualHeightRow extends MultiChildRenderObjectWidget {
  final double spacing;
  final List<double>? flex;

  const EqualHeightRow({
    super.key,
    required super.children,
    required this.spacing,
    this.flex,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualHeightRow(spacing: spacing, flex: flex);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderEqualHeightRow)
      ..spacing = spacing
      ..flex = flex;
  }
}

class _RowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowParentData> {
  _RenderEqualHeightRow({required double spacing, List<double>? flex})
      : _spacing = spacing,
        _flex = flex;

  double _spacing;
  set spacing(double v) {
    if (v == _spacing) return;
    _spacing = v;
    markNeedsLayout();
  }

  List<double>? _flex;
  set flex(List<double>? v) {
    _flex = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowParentData) {
      child.parentData = _RowParentData();
    }
  }

  List<double> _widths(double total) {
    final n = childCount;
    final f = [for (var i = 0; i < n; i++) _flex?[i] ?? 1.0];
    final sum = f.fold<double>(0, (a, b) => a + b);
    final free = math.max(0.0, total - _spacing * (n - 1));
    return [for (final x in f) free * x / sum];
  }

  @override
  void performLayout() {
    final widths = _widths(constraints.maxWidth);
    var tallest = 0.0;
    var child = firstChild;
    var i = 0;
    while (child != null) {
      child.layout(BoxConstraints(minWidth: widths[i], maxWidth: widths[i]),
          parentUsesSize: true);
      tallest = math.max(tallest, child.size.height);
      child = childAfter(child);
      i++;
    }
    tallest = constraints.constrainHeight(tallest);
    var x = 0.0;
    child = firstChild;
    i = 0;
    while (child != null) {
      child.layout(BoxConstraints.tightFor(width: widths[i], height: tallest));
      (child.parentData! as _RowParentData).offset = Offset(x, 0);
      x += widths[i] + _spacing;
      child = childAfter(child);
      i++;
    }
    size = constraints.constrain(Size(constraints.maxWidth, tallest));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
