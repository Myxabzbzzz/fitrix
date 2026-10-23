import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// A saved run in the history: its id and what was recorded.
typedef RunEntry = ({String id, RunDetails details});

/// Saved runs as rows (date, then distance · moving time · average pace);
/// a tap opens the run's summary. Shows [empty] text when there are none.
class RunHistoryList extends StatelessWidget {
  const RunHistoryList({super.key, required this.runs});

  /// Newest first.
  final List<RunEntry> runs;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    if (runs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(l10n.runHistoryEmpty,
            style: AppText.body14.copyWith(color: palette.textSecondary)),
      );
    }
    final locale = l10n.localeName;
    return Column(
      children: [
        for (final run in runs)
          _RunRow(
            key: ValueKey('run-row-${run.id}'),
            run: run,
            locale: locale,
          ),
      ],
    );
  }
}

class _RunRow extends ConsumerWidget {
  const _RunRow({super.key, required this.run, required this.locale});

  final RunEntry run;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final imp = ref.watch(healthImportsProvider.select((m) => m[run.id]));
    final source = imp?.source;
    final noDistance = imp != null && imp.meters == null;
    final d = run.details;
    final pace = formatPace(paceSecPerKm(d.meters, d.moving));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: palette.tile,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: () => context.push(AppRouter.runSummary(run.id)),
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
                      DateFormat.MMMEd(locale)
                          .add_Hm()
                          .format(d.startedAt.toLocal()),
                      if (source != null) source,
                    ].join(' · '),
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary),
                  ),
                  Text(
                    '${noDistance ? noValue : formatKm(d.meters, locale)} ${l10n.runUnitKm}'
                    ' · ${formatClock(d.moving)}'
                    ' · $pace ${l10n.runUnitPerKm}',
                    style: AppText.bodyStrong.copyWith(
                      color: palette.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
