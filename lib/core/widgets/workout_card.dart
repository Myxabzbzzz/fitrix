import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/day_badge.dart';

class WorkoutCard extends StatelessWidget {
  final String title;

  /// The day badge; none when null.
  final String? dayLabel;
  final bool today;
  final bool done;
  final String startLabel;
  final String doneLabel;
  final VoidCallback? onStart;

  /// Shows an edit icon in the top-right corner when set.
  final VoidCallback? onEdit;

  /// Semantics label of the edit icon (no tooltip).
  final String editLabel;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.dayLabel,
    this.today = false,
    this.done = false,
    this.startLabel = 'Start',
    this.doneLabel = 'Done',
    this.onStart,
    this.onEdit,
    this.editLabel = 'Edit workout',
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Opacity(
      opacity: done ? 0.55 : 1,
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
                color: palette.tile, borderRadius: AppRadius.smAll),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dayLabel != null) ...[
                      DayBadge(label: dayLabel!, today: today),
                      const SizedBox(height: AppSpacing.xxs),
                    ],
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headingS.copyWith(
                            height: 1.25, color: palette.textPrimary)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (done)
                  Semantics(
                    label: doneLabel,
                    container: true,
                    excludeSemantics: true,
                    child: Container(
                      height: 24,
                      alignment: Alignment.center,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                          color: palette.buttonMuted,
                          borderRadius: AppRadius.smAll),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check,
                              size: AppText.captionStrong.fontSize,
                              color: palette.textPrimary),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(doneLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.captionStrong
                                    .copyWith(color: palette.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  AppButton(
                    label: startLabel,
                    style: today
                        ? AppButtonStyle.primary
                        : AppButtonStyle.secondary,
                    size: AppButtonSize.small,
                    expand: true,
                    onPressed: onStart,
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            // Icon is 16 px, aligned with the day badge; the hit area is 44.
            Positioned(
              top: 0,
              right: 0,
              child: Semantics(
                button: true,
                label: editLabel,
                excludeSemantics: true,
                child: GestureDetector(
                  key: const ValueKey('workoutCardEdit'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onEdit,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Align(
                      alignment: const Alignment(0.45, -0.45),
                      child: Icon(Icons.edit_outlined,
                          size: 16, color: palette.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddWorkoutCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddWorkoutCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.tile,
      borderRadius: AppRadius.smAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          alignment: Alignment.center,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: palette.buttonMuted, shape: BoxShape.circle),
            child: Icon(Icons.add, color: palette.textPrimary),
          ),
        ),
      ),
    );
  }
}
