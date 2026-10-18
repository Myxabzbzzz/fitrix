import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/presentation/screens/week_plan_screen.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/programs/domain/program_progress.dart';
import 'package:fitrix/features/programs/presentation/providers/programs_provider.dart';
import 'package:fitrix/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The running program: week, sessions done, this week's sessions, main
/// lifts and the next weight increase.
class ProgramProgressScreen extends ConsumerWidget {
  const ProgramProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(activeProgramInfoProvider);
    final loading = ref.watch(programCatalogProvider).isLoading;

    if (info == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(l10n.programsTitle),
              if (!loading)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.programNoActive,
                          style: AppText.headingM
                              .copyWith(color: palette.textPrimary)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(l10n.programNoActiveBody,
                          style: AppText.bodyRegular
                              .copyWith(color: palette.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l10n.programBrowse,
                        onPressed: () => context.go(AppRouter.programs),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final active = info.active;
    final p = info.program;
    final today = ref.watch(todayProvider);
    final history = ref.watch(workoutHistoryProvider);
    final templates = ref.watch(workoutTemplatesProvider);
    final exercises = ref.watch(exerciseCatalogProvider).valueOrNull;
    final slots = programSlots(p, active, history);
    final stats = programStats(slots, today, history, active.start);
    final week = programWeek(active, p, today);
    final thisWeek = slotsThisWeek(slots, today);
    final lifts = liftProgress(p, active, history, exercises);
    final inc = nextIncrease(p, active, history, exercises);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(
              p.name,
              trailing: IconButton(
                key: const Key('program-open-detail'),
                tooltip: l10n.programDetailsTooltip,
                icon: Icon(Icons.tune, color: palette.textPrimary),
                onPressed: () => context.push(AppRouter.program(p.id)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                children: [
                  Text(
                      l10n.programProgressSub(
                          week, p.weeks, dayAndMonth(context, active.start)),
                      key: const Key('program-week-title'),
                      style: AppText.body14
                          .copyWith(color: palette.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  WeekDots(
                    weeks: p.weeks,
                    current: week,
                    deloadWeek: p.deloadWeek,
                    doneColor: palette.pillSelected,
                    doneText: palette.onPillSelected,
                    upcomingColor: palette.tile,
                    upcomingText: palette.textSecondary,
                  ),
                  if (p.deloadWeek != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.programDeloadNote(p.deloadWeek!),
                        style: AppText.body14
                            .copyWith(color: palette.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _Tile(l10n.programTileSessions,
                          '${stats.done}/${stats.planned}'),
                      const SizedBox(width: AppSpacing.xs),
                      _Tile(
                          l10n.programTileOnTime,
                          stats.onTimePercent == null
                              ? '—'
                              : '${stats.onTimePercent}%'),
                      const SizedBox(width: AppSpacing.xs),
                      _Tile(l10n.programTileRecords, '${stats.records}',
                          accent: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.programThisWeek,
                            style: AppText.headingM
                                .copyWith(color: palette.textPrimary)),
                      ),
                      if (thisWeek.isNotEmpty)
                        Text(
                            l10n.programWeekDone(
                                thisWeek.where((s) => s.isDone).length,
                                thisWeek.length),
                            style: AppText.body14
                                .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (thisWeek.isEmpty)
                    Text(l10n.programNoSessionsWeek,
                        style: AppText.bodyRegular
                            .copyWith(color: palette.textSecondary))
                  else
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                          color: palette.tile, borderRadius: AppRadius.mdAll),
                      child: Column(
                        children: [
                          for (var i = 0; i < thisWeek.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, color: palette.border),
                            _SlotRow(
                                slot: thisWeek[i],
                                today: today,
                                onStart: () {
                                  final id = thisWeek[i].session.templateId;
                                  for (final t in templates) {
                                    if (t.id == id) {
                                      WeekPlanScreen.startTemplate(
                                          context, ref, t);
                                      return;
                                    }
                                  }
                                },
                                canStart: templates.any((t) =>
                                    t.id == thisWeek[i].session.templateId)),
                          ],
                        ],
                      ),
                    ),
                  if (lifts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.programMainLifts,
                              style: AppText.headingM
                                  .copyWith(color: palette.textPrimary)),
                        ),
                        Text(l10n.programTopSetKg,
                            style: AppText.body14
                                .copyWith(color: palette.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _LiftsTable(lifts: lifts),
                  ],
                  if (inc != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    KeyedSubtree(
                      key: const Key('program-next-increase'),
                      child: CoachCard(
                        eyebrow: l10n.programNextIncrease,
                        title: '',
                        message: l10n.programNextIncreaseText(inc.sets,
                            inc.reps, inc.exercise, kgText(inc.nextKg)),
                        imageAsset: 'assets/images/felix_robot.png',
                        imageWidth: 56,
                        imageHeight: 80,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: const Key('program-end'),
                    label: l10n.programEnd,
                    style: AppButtonStyle.secondary,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () => _confirmEnd(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.programEndTitle),
        content: Text(l10n.programEndBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('program-end-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.programEnd),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(programStarterProvider).end();
    if (context.mounted) context.go(AppRouter.programs);
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _Tile(this.label, this.value, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration:
            BoxDecoration(color: palette.tile, borderRadius: AppRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(color: palette.textSecondary)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: AppText.headingL.copyWith(
                      color: accent ? palette.accent : palette.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final ProgramSlot slot;
  final DateTime today;
  final bool canStart;
  final VoidCallback onStart;
  const _SlotRow(
      {required this.slot,
      required this.today,
      required this.canStart,
      required this.onStart});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final due = !slot.session.day.isAfter(today);
    final Widget trailing;
    if (slot.isDone) {
      trailing = Container(
        width: 32,
        height: 32,
        decoration:
            BoxDecoration(color: palette.pillSelected, shape: BoxShape.circle),
        child: Icon(Icons.check, size: 18, color: palette.onPillSelected),
      );
    } else if (due && canStart) {
      trailing = AppButton(
        key: Key('program-slot-start-${slot.session.id}'),
        label: l10n.gymStart,
        size: AppButtonSize.small,
        onPressed: onStart,
      );
    } else {
      trailing = Text(l10n.programPlanned,
          style: AppText.body14.copyWith(color: palette.textSecondary));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: due && !slot.isDone
                  ? palette.accentSoft
                  : palette.buttonMuted,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(Icons.fitness_center,
                size: 20,
                color: due && !slot.isDone
                    ? palette.accent
                    : palette.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.session.title,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                Text(weekdayName(context, slot.session.day.weekday),
                    style:
                        AppText.body14.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          trailing,
        ],
      ),
    );
  }
}

class _LiftsTable extends StatelessWidget {
  final List<LiftProgress> lifts;
  const _LiftsTable({required this.lifts});

  static const double _col = 52;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    String n(double? v) => v == null ? '—' : kgText(v);
    Widget cell(String text, TextStyle style) => SizedBox(
        width: _col,
        child: Text(text,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style));
    final head = AppText.microStrong.copyWith(color: palette.textSecondary);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.mdAll),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(l10n.programColLift.toUpperCase(), style: head)),
              cell(l10n.programColStart.toUpperCase(), head),
              cell(l10n.programColNow.toUpperCase(), head),
              cell(l10n.programColGoal.toUpperCase(), head),
            ],
          ),
          for (final l in lifts) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(l.exercise,
                      style: AppText.headingS
                          .copyWith(color: palette.textPrimary)),
                ),
                cell(n(l.start),
                    AppText.body14.copyWith(color: palette.textSecondary)),
                cell(n(l.now),
                    AppText.headingS.copyWith(color: palette.textPrimary)),
                cell(n(l.goal), AppText.body14.copyWith(color: palette.accent)),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: LinearProgressIndicator(
                value: l.fraction,
                minHeight: 4,
                color: palette.accent,
                backgroundColor: palette.buttonMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
