import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/title_row.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/micronutrients.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/widgets/nutrition_cards.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

enum _Period { today, week, month }

/// Micronutrients: intake against NASEM targets for today, the last 7 days
/// or the last 30 days (averages over the days that have food logged).
class MicrosScreen extends ConsumerStatefulWidget {
  const MicrosScreen({super.key});

  @override
  ConsumerState<MicrosScreen> createState() => _MicrosScreenState();
}

class _MicrosScreenState extends ConsumerState<MicrosScreen> {
  _Period _period = _Period.today;
  MicroFilter _filter = MicroFilter.athlete;

  Map<DateTime, Map<String, double>> _perDay(DateTime today, int days) {
    final store = ref.read(foodLogStoreProvider);
    final from = DateTime(today.year, today.month, today.day - (days - 1));
    final out = <DateTime, Map<String, double>>{};
    for (final e in store.between(from, today)) {
      final d = DateTime(e.at.year, e.at.month, e.at.day);
      final m = out.putIfAbsent(d, () => {});
      for (final k in microKeys) {
        m[k] = (m[k] ?? 0) + (e.micros[k] ?? 0);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    ref.watch(foodLogProvider);
    final today = ref.watch(todayProvider);
    final sex = ref.watch(performanceProfileProvider).sex;
    final age = ref.watch(bodyStatsProvider).age;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.micrTitle),
            Expanded(
              child: sex == null || age == null
                  ? ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        InkWell(
                          key: const ValueKey('micros-complete-profile'),
                          borderRadius: AppRadius.smAll,
                          onTap: () => context.push(AppRouter.editProfile),
                          child: NutritionTile(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.nutritionCompleteTitle,
                                          style: AppText.headingS.copyWith(
                                              color: palette.textPrimary)),
                                      Text(l10n.nutritionCompleteBody,
                                          style: AppText.caption.copyWith(
                                              color: palette.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: palette.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _body(context, today, sex, age, locale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
      BuildContext context, DateTime today, Sex sex, int age, String locale) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final targets = microTargets(sex, age);
    final days = switch (_period) {
      _Period.today => 1,
      _Period.week => 7,
      _Period.month => 30,
    };
    final stats = averageMicros(_perDay(today, days));
    final keys = microKeysFor(_filter);

    // Vitamin D low on every one of the last (up to) 7 logged days.
    final logged = _perDay(today, 30);
    final recentDays = (logged.keys.toList()..sort()).reversed.take(7).toList();
    final vitDLow = recentDays.length >= 3 &&
        recentDays.every((d) =>
            microStatus('vitD_mcg', logged[d]!['vitD_mcg'] ?? 0,
                targets['vitD_mcg']!) ==
            MicroStatus.low);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      children: [
        Text(
          l10n.micrTargetsFor(
              sex == Sex.male ? l10n.micrMen : l10n.micrWomen, '$age'),
          style: AppText.caption.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        PillSelector<_Period>(
          items: _Period.values,
          selected: _period,
          labelOf: (p) => switch (p) {
            _Period.today => l10n.micrToday,
            _Period.week => l10n.micr7Days,
            _Period.month => l10n.micr30Days,
          },
          onSelected: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: AppSpacing.xs),
        PillSelector<MicroFilter>(
          items: MicroFilter.values,
          selected: _filter,
          labelOf: (f) => switch (f) {
            MicroFilter.athlete => l10n.micrAthlete,
            MicroFilter.vitamins => l10n.micrVitamins,
            MicroFilter.minerals => l10n.micrMinerals,
            MicroFilter.all => l10n.micrAll('${microKeys.length}'),
          },
          onSelected: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (stats.days == 0)
          NutritionTile(
            child: Text(l10n.micrEmpty,
                style: AppText.body14.copyWith(color: palette.textSecondary)),
          )
        else ...[
          if (_period != _Period.today)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(l10n.micrAverage('${stats.days}'),
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
            ),
          NutritionTile(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final k in keys)
                  _MicroRow(
                    microKey: k,
                    intake: stats.avg[k] ?? 0,
                    target: targets[k]!,
                    locale: locale,
                  ),
              ],
            ),
          ),
        ],
        if (vitDLow) ...[
          const SizedBox(height: AppSpacing.md),
          NutritionTile(
            key: const ValueKey('vitd-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.micrVitDTitle.toUpperCase(),
                    style:
                        AppText.captionStrong.copyWith(color: palette.accent)),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.micrVitDBody,
                    style:
                        AppText.caption.copyWith(color: palette.textPrimary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _InSeason(today: today, locale: locale),
      ],
    );
  }
}

class _MicroRow extends StatelessWidget {
  final String microKey;
  final double intake;
  final double target;
  final String locale;
  const _MicroRow({
    required this.microKey,
    required this.intake,
    required this.target,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final status = microStatus(microKey, intake, target);
    final color = switch (status) {
      MicroStatus.low => palette.warning,
      MicroStatus.ok => palette.success,
      MicroStatus.high => palette.danger,
    };
    final chip = switch (status) {
      MicroStatus.low => l10n.micrLow,
      MicroStatus.ok => l10n.micrOk,
      MicroStatus.high => l10n.micrHigh,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Name and chip on the left, the amount flush right on
              // every row.
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(microName(l10n, microKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong
                              .copyWith(color: palette.textPrimary)),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(chip,
                        style: AppText.captionStrong.copyWith(color: color)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${microAmount(microKey, intake, locale)} / '
                '${microAmount(microKey, target, locale)} '
                '${microUnitLabel(microKey)}',
                style: AppText.caption.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: 0,
                  end: target <= 0 ? 0 : (intake / target).clamp(0.0, 1.0)),
              duration: Motion.of(context, Motion.slow),
              curve: Motion.curve,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                color: color,
                backgroundColor: palette.buttonMuted,
              ),
            ),
          ),
          if (status != MicroStatus.ok)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(microHint(l10n, microKey),
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
            ),
        ],
      ),
    );
  }
}

/// Foods in season this month in Uzbekistan, with the micronutrient each is
/// richest in.
class _InSeason extends ConsumerWidget {
  final DateTime today;
  final String locale;
  const _InSeason({required this.today, required this.locale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(foodCatalogProvider).valueOrNull;
    final ids = seasonalFoodIds[today.month] ?? const <String>[];
    final foods = [
      if (catalog != null)
        for (final id in ids)
          if (catalog.byId(id) != null) catalog.byId(id)!,
    ];
    // Ranking only: which nutrient the food is richest in for an adult.
    final reference = microTargets(Sex.male, 30);
    String local(Food f) {
      final parts = (f.localName ?? f.name).split(' · ');
      return locale.startsWith('ru') && parts.length > 1 ? parts[1] : parts[0];
    }

    String richest(Food f) {
      String? best;
      var bestPct = 0.0;
      for (final k in microKeys) {
        if (k == 'sodium_mg') continue;
        final pct = (f.micros[k] ?? 0) / reference[k]!;
        if (pct > bestPct) {
          bestPct = pct;
          best = k;
        }
      }
      return best == null ? '' : microName(l10n, best);
    }

    if (foods.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(
          title: Text(l10n.micrInSeason,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          trailing: Text(
            l10n.micrUzbekistanMonth(DateFormat.MMMM(locale).format(today)),
            textAlign: TextAlign.end,
            style: AppText.caption.copyWith(color: palette.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height:
              96 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: foods.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, i) {
              final f = foods[i];
              return Container(
                width: 148,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                    color: palette.tile, borderRadius: AppRadius.smAll),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong
                            .copyWith(color: palette.textPrimary)),
                    Text('${local(f)} · ${richest(f)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
