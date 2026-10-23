import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/widgets/run_dialogs.dart';
import 'package:fitrix/features/running/presentation/widgets/run_map.dart';
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

  void _close() {
    final router = GoRouter.of(context);
    router.canPop() ? router.pop() : router.go(AppRouter.home);
  }

  /// Rates the workout and its run document, once.
  void _save(RunDetails details) {
    if (_done) return;
    _done = true;
    final rpe = _rpe;
    if (rpe != null) {
      ref.read(workoutHistoryProvider.notifier).setRpe(widget.id, rpe);
      ref.read(runsProvider.notifier).put(
            widget.id,
            RunDetails(
              startedAt: details.startedAt,
              moving: details.moving,
              elapsed: details.elapsed,
              pauses: details.pauses,
              meters: details.meters,
              elevationGain: details.elevationGain,
              splits: details.splits,
              route: details.route,
              rpe: rpe,
              templateId: details.templateId,
            ),
          );
    }
    _close();
  }

  Future<void> _delete() async {
    if (_done || !await confirmDeleteRun(context) || !mounted || _done) return;
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
                child: Text(l10n.runNotFound,
                    style:
                        AppText.body14.copyWith(color: palette.textSecondary))),
      );
    }

    final locale = l10n.localeName;
    final imported = ref.watch(healthImportsProvider)[widget.id];
    final avg = paceSecPerKm(details.meters, details.moving);
    final rated =
        widget.justFinished ? _rpe : workout.sessionRpe ?? details.rpe;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('run-close'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: _close,
                  icon: Icon(Icons.arrow_back, color: palette.textPrimary),
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
              padding: const EdgeInsets.only(
                  left: 48 + AppSpacing.xs, bottom: AppSpacing.sm),
              child: Text(
                [
                  DateFormat.yMMMMEEEEd(locale)
                      .add_Hm()
                      .format(details.startedAt.toLocal()),
                  if (imported != null) imported.source,
                ].join(' · '),
                style: AppText.body14.copyWith(color: palette.textSecondary),
              ),
            ),
            // A run imported from Health has no route: no map at all.
            if (details.route.isNotEmpty) ...[
              RunMap(route: details.route),
              const SizedBox(height: AppSpacing.md),
            ],
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _Figure(
                    label: '${l10n.runDistance}, ${l10n.runUnitKm}',
                    value: imported != null && imported.meters == null
                        ? noValue
                        : formatKm(details.meters, locale)),
                _Figure(
                    label: l10n.runMovingTime,
                    value: formatClock(details.moving)),
                _Figure(
                    label: '${l10n.runAvgPace}, ${l10n.runUnitPerKm}',
                    value: formatPace(avg)),
                if (details.elevationGain != null)
                  _Figure(
                      label: l10n.runElevation,
                      value: l10n.runElevationValue(
                          formatMeters(details.elevationGain!, locale))),
                if (rated != null && !widget.justFinished)
                  _Figure(label: l10n.runRpeTitle, value: '$rated / 10'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (imported == null)
              Text(
                l10n.runElapsedLine(formatClock(details.elapsed),
                    l10n.runPausesCount(details.pauses)),
                style: AppText.body14.copyWith(color: palette.textSecondary),
              ),
            if (details.splits.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.runSplits,
                  style: AppText.headingS.copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              for (final s in details.splits)
                _SplitRow(split: s, locale: locale),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (widget.justFinished) ...[
              Text(l10n.runRpeTitle,
                  style: AppText.headingS.copyWith(color: palette.textPrimary)),
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
            if (imported != null && !widget.justFinished) ...[
              Text(l10n.runRpeTitle,
                  style: AppText.headingS.copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              RpeScale(
                keyPrefix: 'importedRpe',
                selected: workout.sessionRpe ?? imported.rpe,
                onPick: (n) {
                  ref
                      .read(workoutHistoryProvider.notifier)
                      .setRpe(widget.id, n);
                  ref.read(healthImportsProvider.notifier).setRpe(widget.id, n);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Center(
              child: TextButton(
                key: const ValueKey('run-delete'),
                onPressed: _delete,
                child: Text(
                  widget.justFinished ? l10n.runDiscardRun : l10n.runDeleteRun,
                  textAlign: TextAlign.center,
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          Text(value,
              style: AppText.headingM.copyWith(
                  color: palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
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
