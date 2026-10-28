import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// A title with a caption or value hugging the right edge.
///
/// The trailing widget keeps its natural width (up to [maxTrailingFraction]
/// of the row) and the title takes the rest, unlike Expanded + Flexible,
/// which split the row in half and wrap the title for no reason. A custom
/// layout (no LayoutBuilder), so it also works inside IntrinsicHeight.
class TitleRow extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  final double maxTrailingFraction;
  final CrossAxisAlignment crossAxisAlignment;

  const TitleRow({
    super.key,
    required this.title,
    this.trailing,
    this.maxTrailingFraction = 0.5,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    if (trailing == null) return title;
    return _TitleRowLayout(
      fraction: maxTrailingFraction,
      top: crossAxisAlignment == CrossAxisAlignment.start,
      children: [title, trailing],
    );
  }
}

class _TitleRowLayout extends MultiChildRenderObjectWidget {
  final double fraction;
  final bool top;

  const _TitleRowLayout(
      {required this.fraction, required this.top, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTitleRow(fraction, top);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderTitleRow)
      ..fraction = fraction
      ..top = top;
  }
}

class _TitleRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTitleRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TitleRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TitleRowParentData> {
  _RenderTitleRow(this._fraction, this._top);

  static const double _gap = AppSpacing.xs;

  double _fraction;
  set fraction(double v) {
    if (v == _fraction) return;
    _fraction = v;
    markNeedsLayout();
  }

  bool _top;
  set top(bool v) {
    if (v == _top) return;
    _top = v;
    markNeedsLayout();
  }

  RenderBox get _title => firstChild!;
  RenderBox get _trailing => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TitleRowParentData) {
      child.parentData = _TitleRowParentData();
    }
  }

  double _trailingWidth(double width) => math.min(
      _trailing.getMaxIntrinsicWidth(double.infinity), width * _fraction);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _title.getMinIntrinsicWidth(height) +
      _gap +
      _trailing.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _title.getMaxIntrinsicWidth(height) +
      _gap +
      _trailing.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) {
    final tw = _trailingWidth(width);
    return math.max(_title.getMinIntrinsicHeight(width - tw - _gap),
        _trailing.getMinIntrinsicHeight(tw));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final tw = _trailingWidth(width);
    return math.max(_title.getMaxIntrinsicHeight(width - tw - _gap),
        _trailing.getMaxIntrinsicHeight(tw));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    _trailing.layout(BoxConstraints(maxWidth: width * _fraction),
        parentUsesSize: true);
    final titleWidth = math.max(0.0, width - _trailing.size.width - _gap);
    _title.layout(BoxConstraints.tightFor(width: titleWidth),
        parentUsesSize: true);
    final height = math.max(_title.size.height, _trailing.size.height);
    double y(RenderBox c) => _top ? 0 : (height - c.size.height) / 2;
    (_title.parentData! as _TitleRowParentData).offset = Offset(0, y(_title));
    (_trailing.parentData! as _TitleRowParentData).offset =
        Offset(width - _trailing.size.width, y(_trailing));
    size = constraints.constrain(Size(width, height));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
