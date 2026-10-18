import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Starts [template] and opens the live log. Every Start button uses this.
///
/// Today's planned gym session starts with the check-in's exercise swaps.
/// When another workout is running it asks first; the same plan running
/// already just opens.
Future<void> startWorkout(
    BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
  final active = ref.read(activeWorkoutProvider);
  final running = active != null && active.template.id == template.id;
  if (active != null && !running) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.gymFinishCurrentTitle),
          content: Text(
            l10n.gymFinishCurrentBody(active.template.name, template.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.gymDiscardAndStart),
            ),
          ],
        );
      },
    );
    if (replace != true || !context.mounted) return;
  }
  if (!running) {
    final today = ref.read(todaysGymTemplateProvider);
    ref.read(activeWorkoutProvider.notifier).start(today?.id == template.id
        ? applySwaps(template, ref.read(appliedSwapsProvider))
        : template);
  }
  ref.read(activeWorkoutExpandedProvider.notifier).state = true;
}
