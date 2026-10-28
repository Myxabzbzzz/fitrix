import 'package:flutter/widgets.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// A title with a caption or value hugging the right edge.
///
/// The trailing widget keeps its natural width (up to [maxTrailingFraction]
/// of the row) and the title takes the rest, unlike Expanded + Flexible,
/// which split the row in half and wrap the title for no reason.
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
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Expanded(child: title),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * maxTrailingFraction),
            child: trailing,
          ),
        ],
      ),
    );
  }
}
