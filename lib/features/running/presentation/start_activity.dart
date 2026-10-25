import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Start button of a free ride or ski day: a recording that exists is
/// reopened, never replaced by a second one; otherwise it starts and opens
/// the live screen, or says why it can not.
Future<void> startFreeActivity(
    BuildContext context, WidgetRef ref, ActivityKind kind) async {
  final router = GoRouter.of(context);
  if (ref.read(runRecorderProvider) != null) {
    openLiveRun(router);
    return;
  }
  return beginActivity(
      context, router, ref.read(runRecorderProvider.notifier), kind);
}

/// Starts recording [kind] (under [template] when given) and opens the live
/// screen. Without location access it shows the kind's own snack and goes
/// nowhere.
Future<void> beginActivity(BuildContext context, GoRouter router,
    RunRecorder recorder, ActivityKind kind,
    [WorkoutTemplate? template]) async {
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
    switch (kind) {
      ActivityKind.run =>
        serviceOff ? l10n.runLocationServiceOff : l10n.runLocationOff,
      ActivityKind.ride =>
        serviceOff ? l10n.rideLocationServiceOff : l10n.rideLocationOff,
      ActivityKind.ski =>
        serviceOff ? l10n.skiLocationServiceOff : l10n.skiLocationOff,
    },
    action: SnackBarAction(
      label: l10n.runOpenSettings,
      onPressed: () => serviceOff
          ? Geolocator.openLocationSettings()
          : Geolocator.openAppSettings(),
    ),
  );
}
