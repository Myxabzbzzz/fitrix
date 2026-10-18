import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

extension ExerciseL10n on AppLocalizations {
  String muscleGroupName(MuscleGroup g) => switch (g) {
        MuscleGroup.chest => muscleChest,
        MuscleGroup.back => muscleBack,
        MuscleGroup.shoulders => muscleShoulders,
        MuscleGroup.arms => muscleArms,
        MuscleGroup.legs => muscleLegs,
        MuscleGroup.glutes => muscleGlutes,
        MuscleGroup.core => muscleCore,
      };

  String equipmentName(Equipment e) => switch (e) {
        Equipment.barbell => equipBarbell,
        Equipment.dumbbell => equipDumbbell,
        Equipment.cable => equipCable,
        Equipment.machine => equipMachine,
        Equipment.bodyweight => equipBodyweight,
        Equipment.kettlebell => equipKettlebell,
      };

  String levelName(String level) => switch (level) {
        'beginner' => levelBeginner,
        'intermediate' => levelIntermediate,
        'advanced' => levelAdvanced,
        _ => level,
      };
}

/// Search box shared by the library and the add screen.
class ExerciseSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const ExerciseSearchField(
      {super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return TextField(
      onChanged: onChanged,
      style: AppText.bodyRegular.copyWith(color: palette.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.bodyRegular.copyWith(color: palette.textSecondary),
        prefixIcon: Icon(Icons.search, color: palette.textSecondary),
        filled: true,
        fillColor: palette.tile,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Rounded card that holds a list of rows, like the prototype's lists.
class ExerciseListCard extends StatelessWidget {
  final List<Widget> children;
  const ExerciseListCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: palette.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One exercise row: icon tile, name, subtitle and a trailing widget.
class ExerciseRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const ExerciseRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: palette.tableCell, borderRadius: AppRadius.smAll),
                child: Icon(Icons.fitness_center,
                    size: 18, color: palette.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                    Text(subtitle,
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
