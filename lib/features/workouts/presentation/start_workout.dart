import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/widgets/run_dialogs.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Starts [template] and opens the live log. Every Start button uses this.
///
/// A running workout opens the GPS run recorder instead (see [_startRun]).
///
/// Today's planned gym session starts with the check-in's exercise swaps.
/// When another workout is running it asks first; the same plan running
/// already just opens.
Future<void> startWorkout(
    BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
  if (template.sport == Sport.running) return _startRun(context, ref, template);
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

/// Starts recording [template] and opens `/run/live`.
///
/// A run that exists already (recording, paused, or restored after the app
/// was killed) is never replaced silently: the same plan just reopens it,
/// another plan asks whether to resume it or discard it and start this one.
/// Without location access it says so and goes nowhere.
Future<void> _startRun(
    BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
  final recorder = ref.read(runRecorderProvider.notifier);
  final router = GoRouter.of(context);
  final existing = ref.read(runRecorderProvider);
  if (existing != null) {
    if (existing.templateId != template.id) {
      final resume = await askUnfinishedRun(context, template.name);
      if (resume == null || !context.mounted) return;
      if (!resume) {
        if (!await confirmDiscardRun(context) || !context.mounted) return;
        await recorder.discard();
        if (!context.mounted) return;
        return _beginRun(context, router, recorder, template);
      }
    }
    router.push(AppRouter.liveRun);
    return;
  }
  return _beginRun(context, router, recorder, template);
}

Future<void> _beginRun(BuildContext context, GoRouter router,
    RunRecorder recorder, WorkoutTemplate template) async {
  final l10n = AppLocalizations.of(context);
  final access = await recorder.start(template: template);
  if (!context.mounted) return;
  if (access == LocationAccess.granted) {
    router.push(AppRouter.liveRun);
    return;
  }
  final serviceOff = access == LocationAccess.serviceOff;
  showAppSnack(
    context,
    serviceOff ? l10n.runLocationServiceOff : l10n.runLocationOff,
    action: SnackBarAction(
      label: l10n.runOpenSettings,
      onPressed: () => serviceOff
          ? Geolocator.openLocationSettings()
          : Geolocator.openAppSettings(),
    ),
  );
}
