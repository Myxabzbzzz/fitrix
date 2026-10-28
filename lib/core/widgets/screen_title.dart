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

    // The first line's box: the title's line, or the 48 pt back button if
    // taller. Controls are centred on it, so a title that wraps keeps them
    // level with its first line, and a one-line title stays centred on
    // its trailing action (as it was with a plain centred Row).
    const style = AppText.headingXL;
    final line =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    final box =
        line > kMinInteractiveDimension ? line : kMinInteractiveDimension;
    Widget onFirstLine(Widget child) =>
        SizedBox(height: box, child: Center(widthFactor: 1, child: child));

    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? AppSpacing.xxs : AppSpacing.md,
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop)
            onFirstLine(IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: palette.textPrimary,
              onPressed: () => Navigator.of(context).maybePop(),
            )),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: (box - line) / 2),
              child: WordFitText(
                title,
                maxLines: 2,
                style: style.copyWith(color: palette.textPrimary),
              ),
            ),
          ),
          if (trailing != null) onFirstLine(trailing!),
        ],
      ),
    );
  }
}
