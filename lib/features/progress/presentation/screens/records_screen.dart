import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/title_row.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_widgets.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Every personal record, newest month first.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  Sport? _sport;

  String _when(
      AppLocalizations l10n, String locale, DateTime date, DateTime today) {
    final ago = daysBetween(date, today);
    if (ago <= 0) return l10n.recordsToday;
    if (ago == 1) return l10n.recordsYesterday;
    if (ago < 7) return l10n.recordsDaysAgo(ago);
    return DateFormat('d MMM', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.decimalPattern(locale);
    final today = ref.watch(todayProvider);
    final all = recordEntries(ref.watch(workoutHistoryProvider));
    final present = [
      for (final s in Sport.values)
        if (all.any((r) => r.sport == s)) s,
    ];
    final sport = present.contains(_sport) ? _sport : null;
    final shown = [
      for (final r in all.reversed)
        if (sport == null || r.sport == sport) r,
    ];
    final thisMonth = shown
        .where((r) =>
            r.record.date.year == today.year &&
            r.record.date.month == today.month)
        .length;
    final streak = bestRecordStreak(shown);

    String value(double v) => NumberFormat('0.#', locale).format(v);

    final rows = <Widget>[];
    String? month;
    for (var i = 0; i < shown.length; i++) {
      final r = shown[i].record;
      final key = '${r.date.year}-${r.date.month}';
      if (key != month) {
        month = key;
        final count = shown
            .where((e) =>
                e.record.date.year == r.date.year &&
                e.record.date.month == r.date.month)
            .length;
        final name = DateFormat('LLLL', locale).format(r.date);
        rows.add(Padding(
          padding:
              const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
          child: TitleRow(
            title: Text(
                name.isEmpty ? name : name[0].toUpperCase() + name.substring(1),
                style: AppText.headingS.copyWith(color: p.textPrimary)),
            trailing: Text(l10n.recordsMonthCount(count),
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(color: p.textSecondary)),
          ),
        ));
      }
      final isE1rm = r.kind == RecordKind.e1rm;
      final title = isE1rm
          ? l10n.recordsE1rm(r.exercise, '${value(r.value)} ${l10n.unitKg}')
          : l10n.recordsRepsLine(r.value.round(), r.exercise);
      final gain = isE1rm
          ? '+${value(r.value - r.previous)} ${l10n.unitKg}'
          : l10n.recordsGainReps((r.value - r.previous).round());
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: ProgressCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            AppText.bodyStrong.copyWith(color: p.textPrimary)),
                    Text(
                        l10n.recordsGainWhen(
                            gain, _when(l10n, locale, r.date, today)),
                        style:
                            AppText.caption.copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                    color: p.accentSoft, borderRadius: AppRadius.fullAll),
                child: Text(l10n.recordsPr,
                    style: AppText.microStrong.copyWith(color: p.accent)),
              ),
            ],
          ),
        ),
      ));
    }

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.recordsTitle),
            if (all.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                child: Text(l10n.recordsSummary(all.length, present.length),
                    style: AppText.caption.copyWith(color: p.textSecondary)),
              ),
              PillSelector<Sport?>(
                items: [null, ...present],
                selected: sport,
                labelOf: (s) =>
                    s == null ? l10n.recordsAll : s.localizedLabel(l10n),
                onSelected: (s) => setState(() => _sport = s),
              ),
            ],
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                children: [
                  if (all.isEmpty)
                    Text(l10n.recordsEmpty,
                        style:
                            AppText.headingS.copyWith(color: p.textSecondary))
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StatTile(
                            label: l10n.recordsThisMonth,
                            value: fmt.format(thisMonth),
                            valueColor: p.accent,
                            note: '',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatTile(
                            label: l10n.recordsBestStreak,
                            value: l10n.recordsWeeks(streak),
                            note: '',
                          ),
                        ),
                      ],
                    ),
                    ...rows,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
