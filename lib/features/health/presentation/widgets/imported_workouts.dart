import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_rpe_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// A workout that came from Health, with what came with it.
typedef ImportedEntry = ({CompletedWorkout workout, HealthImport info});

/// Imported workouts of [sport] still in history, newest first.
final importedWorkoutsProvider =
    Provider.family<List<ImportedEntry>, Sport>((ref, sport) {
  final imports = ref.watch(healthImportsProvider);
  return [
    for (final w in ref.watch(workoutHistoryProvider))
      if (w.sport == sport && imports[w.id] != null)
        (workout: w, info: imports[w.id]!),
  ]..sort((a, b) => b.workout.finishedAt.compareTo(a.workout.finishedAt));
});

String _details(AppLocalizations l10n, ImportedEntry e) {
  final locale = l10n.localeName;
  final meters = e.info.meters;
  return [
    e.workout.sport.localizedLabel(l10n),
    '${e.workout.duration.inMinutes} ${l10n.footballMinShort}',
    if (meters != null) '${formatKm(meters, locale)} ${l10n.runUnitKm}',
    if (e.info.avgHr != null) l10n.importedAvgHr(e.info.avgHr!),
  ].join(' · ');
}

/// One imported workout: date and source on top, then sport, length and what
/// is known (distance, average heart rate). A tap opens the sheet.
class ImportedWorkoutRow extends ConsumerWidget {
  const ImportedWorkoutRow({super.key, required this.entry});

  final ImportedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final w = entry.workout;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: palette.tile,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          key: ValueKey('imported-row-${w.id}'),
          borderRadius: AppRadius.smAll,
          onTap: () => showImportedWorkoutSheet(context, w.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      DateFormat.MMMEd(l10n.localeName)
                          .add_Hm()
                          .format(w.startedAt.toLocal()),
                      entry.info.source,
                    ].join(' · '),
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary),
                  ),
                  Text(_details(l10n, entry),
                      style: AppText.bodyStrong
                          .copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "From Apple Health": the imported workouts of [sport]; nothing when there
/// are none.
class ImportedWorkoutsSection extends ConsumerWidget {
  const ImportedWorkoutsSection({super.key, required this.sport});

  final Sport sport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(importedWorkoutsProvider(sport));
    if (entries.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(l10n.importedFromHealth(healthName(ref))),
        const SizedBox(height: AppSpacing.xs),
        for (final e in entries) ImportedWorkoutRow(entry: e),
      ],
    );
  }
}

/// The brand name of this phone's health store (not translated).
String healthName(WidgetRef ref) =>
    ref.read(healthSourceProvider).platform == HealthPlatform.healthConnect
        ? 'Health Connect'
        : 'Apple Health';

Future<void> showImportedWorkoutSheet(BuildContext context, String id) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _ImportedSheet(id: id),
  );
}

class _ImportedSheet extends ConsumerWidget {
  const _ImportedSheet({required this.id});

  final String id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importedDeleteTitle),
        content: Text(l10n.runDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('imported-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.runDeleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(workoutHistoryProvider.notifier).remove(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final w =
        ref.watch(workoutHistoryProvider).where((w) => w.id == id).firstOrNull;
    final info = ref.watch(healthImportsProvider)[id];
    if (w == null || info == null) return const SizedBox.shrink();
    final entry = (workout: w, info: info);
    final rpe = w.sessionRpe ?? info.rpe;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                DateFormat.yMMMMEEEEd(l10n.localeName)
                    .add_Hm()
                    .format(w.startedAt.toLocal()),
                info.source,
              ].join(' · '),
              style: AppText.body14.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(_details(l10n, entry),
                style: AppText.headingS.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.runRpeTitle,
                style: AppText.headingS.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            RpeScale(
              keyPrefix: 'importedRpe',
              selected: rpe,
              onPick: (n) {
                ref.read(workoutHistoryProvider.notifier).setRpe(id, n);
                ref.read(healthImportsProvider.notifier).setRpe(id, n);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                key: const ValueKey('imported-delete'),
                onPressed: () => _delete(context, ref),
                child: Text(
                  l10n.importedDelete,
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
