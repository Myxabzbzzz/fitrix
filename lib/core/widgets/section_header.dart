import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(title,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
        ),
        if (actionLabel != null)
          Semantics(
            button: true,
            enabled: onAction != null,
            container: true,
            label: actionLabel,
            excludeSemantics: true,
            onTap: onAction,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Align(
                    widthFactor: 1,
                    child: Text(actionLabel!,
                        style: AppText.body14.copyWith(color: palette.accent)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
