import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/cycling/presentation/indoor_ride_sheet.dart';
import 'package:fitrix/features/football/presentation/match_log_sheet.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/widgets/run_dialogs.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';

/// Starts [template] and opens the live log. Every Start button uses this.
///
/// A running workout opens the GPS run recorder instead (see [_startRun]),
/// a cycling one asks Outdoor (the GPS recorder) or Indoor (the ride log),
/// a football one the log sheet: the game is logged after it is played.
///
/// Today's planned gym session starts with the check-in's exercise swaps.
/// When another workout is running it asks first; the same plan running
/// already just opens.
Future<void> startWorkout(
    BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
  if (template.sport == Sport.running) return _startRun(context, ref, template);
  if (template.sport == Sport.cycling) {
    return _startRide(context, ref, template);
  }
  if (template.sport == Sport.football) {
    return showMatchLogSheet(context, ref, template: template);
  }
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

/// A planned ride: Outdoor records it with GPS, Indoor opens the log. Both
/// save under the template, so the plan marks the session done.
Future<void> _startRide(
    BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
  // A ride that is already recording just reopens, as for a run.
  final existing = ref.read(runRecorderProvider);
  if (existing != null && existing.templateId == template.id) {
    return _startRun(context, ref, template, ActivityKind.ride);
  }
  final outdoor = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppPalette.of(context).background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.cyclingChoiceTitle,
                style: AppText.headingM
                    .copyWith(color: AppPalette.of(context).textPrimary)),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const ValueKey('ride-choice-outdoor'),
              label: l10n.cyclingOutdoor,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: const ValueKey('ride-choice-indoor'),
              label: l10n.cyclingIndoor,
              style: AppButtonStyle.secondary,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      );
    },
  );
  if (outdoor == null || !context.mounted) return;
  if (outdoor) return _startRun(context, ref, template, ActivityKind.ride);
  return showIndoorRideSheet(context, ref, template: template);
}

/// Starts recording [template] and opens `/run/live`.
///
/// A run that exists already (recording, paused, or restored after the app
/// was killed) is never replaced silently: the same plan just reopens it,
/// another plan asks whether to resume it or discard it and start this one.
/// Without location access it says so and goes nowhere.
Future<void> _startRun(
    BuildContext context, WidgetRef ref, WorkoutTemplate template,
    [ActivityKind kind = ActivityKind.run]) async {
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
        return _beginRun(context, router, recorder, template, kind);
      }
    }
    openLiveRun(router);
    return;
  }
  return _beginRun(context, router, recorder, template, kind);
}

Future<void> _beginRun(BuildContext context, GoRouter router,
    RunRecorder recorder, WorkoutTemplate template, ActivityKind kind) async {
  final l10n = AppLocalizations.of(context);
  final access = await recorder.start(kind: kind, template: template);
  if (!context.mounted) return;
  if (access == LocationAccess.granted) {
    openLiveRun(router);
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
