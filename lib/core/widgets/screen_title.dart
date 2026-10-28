import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/word_fit_text.dart';

/// Large left-aligned page title ("My workouts", "Gym", "My progress").
/// Shows a back button when the current route can be popped.
class ScreenTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const ScreenTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? AppSpacing.xxs : AppSpacing.md,
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      // Top-aligned: a title that wraps keeps the back button and the
      // trailing action level with its first line.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: palette.textPrimary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: Padding(
              // Centres the first line (40) on the 48 pt back button.
              padding: EdgeInsets.only(top: canPop ? AppSpacing.xxs : 0),
              child: WordFitText(
                title,
                maxLines: 2,
                style: AppText.headingXL.copyWith(color: palette.textPrimary),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
