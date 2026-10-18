import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Small "Felix plan" chip: Felix's avatar and the label. Marks a workout
/// that Felix made.
class FelixPlanBadge extends StatelessWidget {
  /// For use on a dark (selected) surface.
  final bool onDark;

  const FelixPlanBadge({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const ValueKey('felix-plan-badge'),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxs, AppSpacing.xxs, AppSpacing.xs, AppSpacing.xxs),
      decoration: BoxDecoration(
        color: onDark
            ? palette.onPillSelected.withValues(alpha: 0.12)
            : palette.buttonMuted,
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset('assets/images/felix_avatar.png',
                width: 16, height: 16, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(l10n.felixPlanBadge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.microStrong.copyWith(
                    color:
                        onDark ? palette.onPillSelected : palette.textPrimary)),
          ),
        ],
      ),
    );
  }
}
