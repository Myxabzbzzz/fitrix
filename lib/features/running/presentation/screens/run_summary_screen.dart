import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/widgets/run_dialogs.dart';
import 'package:fitrix/features/running/presentation/widgets/ride_summary_body.dart';
import 'package:fitrix/features/running/presentation/widgets/run_figure.dart';
import 'package:fitrix/features/running/presentation/widgets/run_map.dart';
import 'package:fitrix/features/running/presentation/widgets/ski_summary_body.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_rpe_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// A finished run. The run is already saved when this opens, so leaving
/// without Save loses nothing.
///
/// [justFinished]: the run was just recorded; rate it and Save, or discard
/// it. Otherwise (opened from history): the rating is shown and the run can
/// be deleted.
class RunSummaryScreen extends ConsumerStatefulWidget {
  const RunSummaryScreen(
      {super.key, required this.id, this.justFinished = false});

  final String id;
  final bool justFinished;

  @override
  ConsumerState<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends ConsumerState<RunSummaryScreen> {
  int? _rpe;
  bool _done = false;

  /// Save was tapped: the page now shows the saved activity, and leaving it
  /// goes to its sport's screen, where it heads the history (the same for a
  /// run, a ride and a ski day, wherever the recording was opened from).
  ActivityKind? _savedKind;

  /// Just recorded and not saved yet: rating and Save show.
  bool get _fresh => widget.justFinished && _savedKind == null;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static String _sportScreen(ActivityKind kind) =>
      AppRouter.sportWorkouts(switch (kind) {
        ActivityKind.run => Sport.running,
        ActivityKind.ride => Sport.cycling,
        ActivityKind.ski => Sport.winterSports,
      });

  void _close() {
    final router = GoRouter.of(context);
    final saved = _savedKind;
    if (saved != null) {
      router.go(_sportScreen(saved));
      return;
    }
    router.canPop() ? router.pop() : router.go(AppRouter.home);
  }

  /// Rates the workout and its run document, once, and shows it saved.
  void _save(RunDetails details) {
    if (_done || _savedKind != null) return;
    final rpe = _rpe;
    if (rpe != null) {
      ref.read(workoutHistoryProvider.notifier).setRpe(widget.id, rpe);
      ref.read(runsProvider.notifier).put(
            widget.id,
            details.withRpe(rpe),
          );
    }
    setState(() => _savedKind = details.kind);
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: Motion.of(context, Motion.medium), curve: Motion.curve);
    }
  }

  Future<void> _delete() async {
    final kind = ref.read(runsProvider)[widget.id]?.kind ?? ActivityKind.run;
    if (_done || !await confirmDeleteRun(context, kind) || !mounted || _done) {
      return;
    }
    _done = true;
    ref.read(workoutHistoryProvider.notifier).remove(widget.id);
    ref.read(runsProvider.notifier).remove(widget.id);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final details = ref.watch(runsProvider)[widget.id];
    final workout = ref
        .watch(workoutHistoryProvider)
        .where((w) => w.id == widget.id)
        .firstOrNull;

    if (details == null || workout == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.background,
          elevation: 0,
          leading: BackButton(onPressed: _close),
        ),
        body: _done
            ? const SizedBox.shrink()
            : Center(
                child: Text(
                    switch (details?.kind ??
                        switch (workout?.sport) {
                          Sport.cycling => ActivityKind.ride,
                          Sport.winterSports => ActivityKind.ski,
                          _ => ActivityKind.run,
                        }) {
                      ActivityKind.run => l10n.runNotFound,
                      ActivityKind.ride => l10n.rideNotFound,
                      ActivityKind.ski => l10n.skiNotFound,
                    },
                    style:
                        AppText.body14.copyWith(color: palette.textSecondary))),
      );
    }

    final locale = l10n.localeName;
    final imported = ref.watch(healthImportsProvider)[widget.id];
    final avg = paceSecPerKm(details.meters, details.moving);
    final rated = _fresh ? _rpe : workout.sessionRpe ?? details.rpe;

    return PopScope(
      // Always poppable, so the iOS back-swipe works (a blocked PopScope
      // disables it). Once saved, the pop is followed by a jump to the
      // sport's screen (see _close).
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (_savedKind == null) return;
        final router = GoRouter.of(context);
        final saved = _savedKind!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go(_sportScreen(saved));
        });
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('run-close'),
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: _close,
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: palette.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      workout.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppText.headingM.copyWith(color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
              Padding(
                // Under the title text, which starts after the 48 pt button.
                padding: const EdgeInsets.only(left: 48, bottom: AppSpacing.sm),
                child: Text(
                  [
                    DateFormat.yMMMEd(locale)
                        .add_Hm()
                        .format(details.startedAt.toLocal()),
                    if (imported != null) imported.source,
                  ].join(' · '),
                  style: AppText.body14.copyWith(color: palette.textSecondary),
                ),
              ),
              if (details.kind == ActivityKind.ride)
                RideSummaryBody(details: details)
              else if (details.kind == ActivityKind.ski)
                SkiSummaryBody(details: details)
              else ...[
                // A run imported from Health has no route: no map at all.
                if (details.route.isNotEmpty) ...[
                  RunMap(route: details.route),
                  const SizedBox(height: AppSpacing.md),
                ],
                RunFigureGrid(
                  children: [
                    RunFigure(
                        label: '${l10n.runDistance}, ${l10n.runUnitKm}',
                        value: imported != null && imported.meters == null
                            ? noValue
                            : formatKm(details.meters, locale)),
                    RunFigure(
                        label: l10n.runMovingTime,
                        value: formatClock(details.moving)),
                    RunFigure(
                        label: '${l10n.runAvgPace}, ${l10n.runUnitPerKm}',
                        value: formatPace(avg)),
                    if (details.elevationGain != null)
                      RunFigure(
                          label: l10n.runElevation,
                          value: l10n.runElevationValue(
                              formatMeters(details.elevationGain!, locale))),
                    // An imported run shows its rating on the scale below.
                    if (rated != null && !_fresh && imported == null)
                      RunFigure(label: l10n.runRpeTitle, value: '$rated / 10'),
                  ],
                ),
              ],
              if (details.kind != ActivityKind.run &&
                  rated != null &&
                  !_fresh) ...[
                const SizedBox(height: AppSpacing.sm),
                RunFigure(label: l10n.runRpeTitle, value: '$rated / 10'),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (imported == null && !details.indoor)
                Text(
                  l10n.runElapsedLine(formatClock(details.elapsed),
                      l10n.runPausesCount(details.pauses)),
                  style: AppText.body14.copyWith(color: palette.textSecondary),
                ),
              if (details.kind == ActivityKind.run &&
                  details.splits.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.runSplits,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                for (final s in details.splits)
                  _SplitRow(split: s, locale: locale),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (_fresh) ...[
                Text(l10n.runRpeTitle,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                RpeScale(
                  keyPrefix: 'runRpe',
                  selected: _rpe,
                  onPick: (n) => setState(() => _rpe = n),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  key: const ValueKey('run-save'),
                  label: l10n.runSave,
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: () => _save(details),
                ),
              ],
              if (imported != null && !_fresh) ...[
                Text(l10n.runRpeTitle,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                RpeScale(
                  keyPrefix: 'importedRpe',
                  selected: workout.sessionRpe ?? imported.rpe,
                  onPick: (n) {
                    ref
                        .read(workoutHistoryProvider.notifier)
                        .setRpe(widget.id, n);
                    ref
                        .read(healthImportsProvider.notifier)
                        .setRpe(widget.id, n);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Center(
                child: TextButton(
                  key: const ValueKey('run-delete'),
                  onPressed: _delete,
                  child: Text(
                    switch (details.kind) {
                      ActivityKind.run =>
                        _fresh ? l10n.runDiscardRun : l10n.runDeleteRun,
                      ActivityKind.ride =>
                        _fresh ? l10n.rideDiscardRun : l10n.rideDeleteRun,
                      ActivityKind.ski =>
                        _fresh ? l10n.skiDiscardRun : l10n.skiDeleteRun,
                    },
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong
                        .copyWith(color: palette.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({required this.split, required this.locale});

  final RunSplit split;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final full = split.meters >= 1000;
    final style = AppText.body14.copyWith(
        color: palette.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              full
                  ? '${split.km}'
                  : '${formatKm(split.meters, locale)} ${l10n.runUnitKm}',
              style: style,
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(formatClock(split.time),
                  textAlign: TextAlign.end, style: style)),
          Expanded(
            flex: 3,
            child: Text(
              '${formatPace(paceSecPerKm(split.meters, split.time))} ${l10n.runUnitPerKm}',
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
