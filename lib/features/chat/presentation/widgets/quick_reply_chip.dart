import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// Horizontal row of quick replies, placed directly above the chat input.
/// Collapses to nothing while Felix is replying or when there are no
/// options. Chips fade up with a 50 ms stagger.
class QuickReplyBar extends StatelessWidget {
  final List<String> replies;
  final bool hidden;
  final ValueChanged<String> onTap;

  const QuickReplyBar({
    super.key,
    required this.replies,
    required this.onTap,
    this.hidden = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hidden || replies.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      key: ValueKey(replies.join('|')),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          for (var i = 0; i < replies.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            FadeSlideIn(
              delay: Duration(milliseconds: 50 * i.clamp(0, 6)),
              duration: Motion.fast,
              offset: const Offset(0, 10),
              child: QuickReplyChip(
                label: replies[i],
                onTap: () => onTap(replies[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const QuickReplyChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: AppRadius.fullAll,
            border: Border.all(color: palette.border),
          ),
          child: Text(
            label,
            style: AppText.body14.copyWith(color: palette.textPrimary),
          ),
        ),
      ),
    );
  }
}
