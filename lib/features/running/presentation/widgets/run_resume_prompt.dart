import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/widgets/run_dialogs.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';

/// Whether the unfinished-run prompt has been shown since the app started.
final runResumePromptShownProvider = StateProvider<bool>((ref) => false);

enum _Choice { resume, save, discard }

/// Asks once per launch what to do with a run found unfinished after the
/// app was killed. Wraps the shell's content and shows nothing itself.
///
/// The prompt names only the distance, so it needs nothing that loads
/// later (the plan's name is looked up when the run is saved).
class RunResumePrompt extends ConsumerStatefulWidget {
  const RunResumePrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RunResumePrompt> createState() => _RunResumePromptState();
}

class _RunResumePromptState extends ConsumerState<RunResumePrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  Future<void> _maybeAsk() async {
    if (!mounted || ref.read(runResumePromptShownProvider)) return;
    if (ref.read(pendingRunProvider) == null) return;
    ref.read(runResumePromptShownProvider.notifier).state = true;

    final router = GoRouter.of(context);
    final recorder = ref.read(runRecorderProvider.notifier);
    while (true) {
      final session = ref.read(pendingRunProvider);
      if (session == null || !mounted) return;
      final choice = await showDialog<_Choice>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(() {
              // A ski day names what was skied down, as its summary does.
              final km = formatKm(
                  session.kind == ActivityKind.ski
                      ? recorder.skiMeters
                      : session.track.meters,
                  l10n.localeName);
              return switch (session.kind) {
                ActivityKind.run => l10n.runUnfinishedLaunchTitle(km),
                ActivityKind.ride => l10n.rideUnfinishedLaunchTitle(km),
                ActivityKind.ski => l10n.skiUnfinishedLaunchTitle(km),
              };
            }()),
            content: Text(session.kind == ActivityKind.ski
                ? l10n.skiUnfinishedLaunchBody
                : l10n.runUnfinishedLaunchBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, _Choice.discard),
                child: Text(l10n.runDiscardAction),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _Choice.save),
                child: Text(l10n.runSave),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _Choice.resume),
                child: Text(l10n.runResume),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      switch (choice) {
        case _Choice.resume || null:
          openLiveRun(router);
          return;
        case _Choice.save:
          final workout = await recorder.finish();
          router.push(AppRouter.runSummary(workout.id, justFinished: true));
          return;
        case _Choice.discard:
          // Cancelling the confirmation goes back to the choice.
          final confirmed = await confirmDiscardRun(context, session.kind);
          if (confirmed) {
            await recorder.discard();
            return;
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
