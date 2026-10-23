import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_text.dart';
import 'package:fitrix/features/checkin/presentation/widgets/readiness_ring.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/health/data/health_daily_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Opens the morning check-in. Completes with true when it was saved.
Future<bool> showCheckInSheet(BuildContext context) async {
  final palette = AppPalette.of(context);
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _CheckInSheet(),
  );
  return saved ?? false;
}

class _CheckInSheet extends ConsumerStatefulWidget {
  const _CheckInSheet();

  @override
  ConsumerState<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<_CheckInSheet> {
  static const _minSleep = 3 * 60;
  static const _maxSleep = 12 * 60;

  int _sleepMinutes = 7 * 60 + 30;
  // Where the pre-filled sleep came from; dropped once the user moves it.
  String? _sleepSource;
  bool _sleepTouched = false;
  SleepQuality _quality = SleepQuality.ok;
  Soreness _soreness = Soreness.none;
  Set<BodyArea> _sore = {};
  Level3 _energy = Level3.ok;
  Level3 _stress = Level3.ok;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(todayCheckInProvider);
    if (saved != null) {
      _sleepMinutes = saved.sleep.inMinutes.clamp(_minSleep, _maxSleep);
    } else {
      _prefillSleep(ref.read(healthTodayDayProvider));
    }
    // Fire and forget: the sheet follows the cache when the read lands.
    unawaited(ref.read(healthSyncProvider).refresh().catchError((Object _) {}));
  }

  /// Health's last night, rounded to the slider's 15-minute step.
  void _prefillSleep(HealthDay? day) {
    final sleep = day?.sleep;
    if (sleep == null || _sleepTouched) return;
    _sleepMinutes =
        ((sleep.inMinutes / 15).round() * 15).clamp(_minSleep, _maxSleep);
    _sleepSource = day!.sleepSource ??
        (ref.read(healthSourceProvider).platform == HealthPlatform.healthConnect
            ? 'Health Connect'
            : 'Apple Health');
  }

  CheckIn _current() => CheckIn(
        at: ref.read(clockProvider)(),
        sleep: Duration(minutes: _sleepMinutes),
        quality: _quality,
        soreness: _soreness,
        sore: _soreness == Soreness.none ? const {} : _sore,
        energy: _energy,
        stress: _stress,
      );

  void _step(int minutes) => setState(() {
        _sleepTouched = true;
        _sleepSource = null;
        _sleepMinutes = (_sleepMinutes + minutes).clamp(_minSleep, _maxSleep);
      });

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final checkIn = _current();
    final navigator = Navigator.of(context);
    await ref.read(todayCheckInProvider.notifier).save(checkIn);
    // Swap sore-area exercises in today's session; the user can undo.
    final template = ref.read(todaysGymTemplateProvider);
    if (template != null && checkIn.sore.isNotEmpty) {
      final catalog = await ref.read(exerciseCatalogProvider.future);
      await ref
          .read(appliedSwapsProvider.notifier)
          .apply(sparingSwaps(template, checkIn.sore, catalog));
    }
    if (navigator.mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    ref.listen(healthTodayDayProvider, (_, day) {
      if (ref.read(todayCheckInProvider) != null) return;
      setState(() => _prefillSleep(day));
    });
    final checkIn = _current();
    final r = readiness(checkIn,
        hardDaysLast7: ref.watch(hardDaysProvider),
        health: ref.watch(healthTodayProvider));
    final now = checkIn.at;

    Widget label(String text) => Padding(
          padding:
              const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
          child: Text(text,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: AppSpacing.xxs,
                    decoration: BoxDecoration(
                        color: palette.buttonMuted,
                        borderRadius: AppRadius.fullAll),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.checkinTitle,
                              style: AppText.headingL
                                  .copyWith(color: palette.textPrimary)),
                          Text(
                            DateFormat('EEE d MMM · HH:mm', locale).format(now),
                            style: AppText.bodyRegular
                                .copyWith(color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: palette.accent,
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: label(l10n.checkinSleep)),
                    Text(l10n.sleepText(Duration(minutes: _sleepMinutes)),
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: palette.textPrimary,
                      tooltip: l10n.checkinSleepLess,
                      onPressed:
                          _sleepMinutes > _minSleep ? () => _step(-15) : null,
                    ),
                    Expanded(
                      child: Slider(
                        value: _sleepMinutes.toDouble(),
                        min: _minSleep.toDouble(),
                        max: _maxSleep.toDouble(),
                        divisions: (_maxSleep - _minSleep) ~/ 15,
                        activeColor: palette.accent,
                        inactiveColor: palette.buttonMuted,
                        onChanged: (v) => setState(() {
                          _sleepTouched = true;
                          _sleepSource = null;
                          _sleepMinutes = v.round();
                        }),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: palette.textPrimary,
                      tooltip: l10n.checkinSleepMore,
                      onPressed:
                          _sleepMinutes < _maxSleep ? () => _step(15) : null,
                    ),
                  ],
                ),
                if (_sleepSource != null)
                  Text(l10n.healthFromSource(_sleepSource!),
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                _Segmented<SleepQuality>(
                  values: SleepQuality.values,
                  selected: _quality,
                  labelOf: l10n.qualityName,
                  onSelected: (v) => setState(() => _quality = v),
                ),
                label(l10n.checkinSoreness),
                _Segmented<Soreness>(
                  values: Soreness.values,
                  selected: _soreness,
                  labelOf: l10n.sorenessName,
                  onSelected: (v) => setState(() => _soreness = v),
                ),
                if (_soreness != Soreness.none) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final a in BodyArea.values)
                        _AreaChip(
                          label: l10n.areaName(a),
                          selected: _sore.contains(a),
                          onTap: () => setState(() => _sore = _sore.contains(a)
                              ? ({..._sore}..remove(a))
                              : {..._sore, a}),
                        ),
                    ],
                  ),
                ],
                label(l10n.checkinEnergy),
                _Segmented<Level3>(
                  values: Level3.values,
                  selected: _energy,
                  labelOf: l10n.energyName,
                  onSelected: (v) => setState(() => _energy = v),
                ),
                label(l10n.checkinStress),
                _Segmented<Level3>(
                  values: Level3.values,
                  selected: _stress,
                  labelOf: l10n.stressName,
                  onSelected: (v) => setState(() => _stress = v),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                      color: palette.accentSoft, borderRadius: AppRadius.mdAll),
                  child: Row(
                    children: [
                      ReadinessRing(
                        score: r.score,
                        size: 64,
                        strokeWidth: 6,
                        child: Text('${r.score}%',
                            style: AppText.bodyStrong
                                .copyWith(color: palette.textPrimary)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.readinessLabel(r.label),
                                style: AppText.headingS
                                    .copyWith(color: palette.textPrimary)),
                            Text(l10n.checkinHint(r, checkIn),
                                style: AppText.bodyRegular
                                    .copyWith(color: palette.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.viewPaddingOf(context).bottom),
          child: AppButton(
            label: l10n.checkinSave,
            size: AppButtonSize.large,
            expand: true,
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const _Segmented({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Semantics(
              button: true,
              selected: values[i] == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(values[i]),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: values[i] == selected
                        ? palette.pillSelected
                        : palette.tile,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labelOf(values[i]),
                      maxLines: 1,
                      style: AppText.bodyStrong.copyWith(
                        color: values[i] == selected
                            ? palette.onPillSelected
                            : palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AreaChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.fullAll,
            border: Border.all(
                color: selected ? palette.textPrimary : palette.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 16, color: palette.textPrimary),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(label,
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
