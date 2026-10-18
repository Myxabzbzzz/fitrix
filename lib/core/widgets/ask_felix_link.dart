import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// A compact "Ask Felix" link for Felix cards. [onTap] usually calls
/// `askFelix` with a draft about what the card shows.
class AskFelixLink extends StatelessWidget {
  final VoidCallback onTap;

  const AskFelixLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          // A comfortable tap target even though the link looks small.
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: palette.accent),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  AppLocalizations.of(context).coachAskFelix,
                  style: AppText.captionStrong.copyWith(color: palette.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
