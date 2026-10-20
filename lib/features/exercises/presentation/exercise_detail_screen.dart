import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/exercises/domain/exercise_stats.dart';
import 'package:fitrix/features/exercises/presentation/exercise_widgets.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_format.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String id;
  const ExerciseDetailScreen({super.key, required this.id});

  void _addToWorkout(BuildContext context, WidgetRef ref, ExerciseInfo info) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    if (ref.read(activeWorkoutProvider) == null) {
      notifier.start(WorkoutTemplate(
        id: 'quick-workout',
        sport: Sport.gym,
        name: l10n.exerciseQuickWorkout,
        focus: Sport.gym.label,
        estimatedDuration: const Duration(minutes: 45),
        exercises: const [],
      ));
    }
    notifier.addExercises([info.name]);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.exerciseAdded)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final info = catalog?.byId(id);
    final history = ref.watch(workoutHistoryProvider);

    Widget bar() => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxs, AppSpacing.xs, AppSpacing.md, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: palette.textPrimary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(l10n.exerciseDetailTitle,
                    textAlign: TextAlign.center,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        );

    if (catalog == null || info == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(child: Column(children: [bar()])),
      );
    }

    final sessions = sessionsOf(info, catalog, history);
    final similar = catalog.similarTo(info);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            bar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                children: [
                  Text(info.name,
                      style: AppText.headingXL
                          .copyWith(color: palette.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _Tag(l10n.equipmentName(info.equipment)),
                        _Tag(info.pattern),
                        if (info.compound) _Tag(l10n.exerciseCompound),
                        _Tag(l10n.levelName(info.level)),
                      ]),
                  const SizedBox(height: AppSpacing.md),
                  _Muscles(
                      label: l10n.exercisePrimary,
                      muscles: info.primary,
                      strong: true),
                  if (info.secondary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _Muscles(
                        label: l10n.exerciseSecondary,
                        muscles: info.secondary,
                        strong: false),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _title(context, l10n.exerciseYourNumbers),
                  const SizedBox(height: AppSpacing.xs),
                  sessions.isEmpty
                      ? Text(l10n.exerciseNoHistory,
                          style: AppText.bodyRegular
                              .copyWith(color: palette.textSecondary))
                      : _Numbers(sessions: sessions),
                  if (info.steps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _title(context, l10n.exerciseHowTo),
                    const SizedBox(height: AppSpacing.xs),
                    for (var i = 0; i < info.steps.length; i++)
                      _Step(number: i + 1, text: info.steps[i]),
                  ],
                  if (info.mistakes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _title(context, l10n.exerciseMistakes),
                    const SizedBox(height: AppSpacing.xs),
                    for (final m in info.mistakes) _Mistake(m),
                  ],
                  if (similar.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _title(context, l10n.exerciseSimilar),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final s in similar)
                          GestureDetector(
                            key: ValueKey('similar-${s.id}'),
                            onTap: () => context.push(AppRouter.exercise(s.id)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.fullAll,
                                border: Border.all(color: palette.border),
                              ),
                              child: Text(s.name,
                                  style: AppText.body14
                                      .copyWith(color: palette.textPrimary)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: palette.background,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l10n.exerciseAskFelix,
                        style: AppButtonStyle.secondary,
                        size: AppButtonSize.large,
                        icon: Icons.chat_bubble_outline,
                        expand: true,
                        onPressed: () => askFelix(context, ref,
                            topic: AssistantTopic.forSport(Sport.gym),
                            draft: l10n.exerciseAskFelixDraft(info.name)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: l10n.exerciseAddToWorkout,
                        size: AppButtonSize.large,
                        icon: Icons.add,
                        expand: true,
                        onPressed: () => _addToWorkout(context, ref, info),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text) => Text(text,
      style:
          AppText.headingM.copyWith(color: AppPalette.of(context).textPrimary));
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.fullAll),
      child: Text(text.toUpperCase(),
          style: AppText.microStrong.copyWith(color: palette.textPrimary)),
    );
  }
}

class _Muscles extends StatelessWidget {
  final String label;
  final List<String> muscles;
  final bool strong;
  const _Muscles(
      {required this.label, required this.muscles, required this.strong});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label,
            style: AppText.caption.copyWith(color: palette.textSecondary)),
        for (final m in muscles)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: strong ? palette.accent : palette.accentSoft,
              borderRadius: AppRadius.fullAll,
            ),
            child: Text(m,
                style: AppText.body14.copyWith(
                    color: strong ? palette.onAccent : palette.textPrimary)),
          ),
      ],
    );
  }
}

class _Numbers extends StatelessWidget {
  final List<ExerciseSession> sessions;
  const _Numbers({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final best = bestOf(sessions)!;
    final points = [for (final s in sessions) s.bestE1rm];
    final first = points.first, last = points.last;
    final change =
        sessions.length >= 2 && first > 0 ? (last - first) / first * 100 : null;
    final decimal = NumberFormat('#,##0.0', locale);

    Widget stat(String label, String value, {Key? key}) => Expanded(
          child: Column(
            key: key,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
              Text(value,
                  style: AppText.headingM.copyWith(color: palette.textPrimary)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (change != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                l10n.exerciseChangeSince(
                  '${change >= 0 ? '+' : ''}${decimal.format(round1(change))}%',
                  DateFormat.MMM(locale).format(sessions.first.date),
                ),
                style: AppText.captionStrong.copyWith(color: palette.accent),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat(l10n.exerciseBestSet, formatSetLoad(context, best)),
              if (best.kg > 0)
                stat(l10n.exerciseE1rm,
                    '${decimal.format(round1(e1rm(best.kg, best.reps)))} ${l10n.unitKg}',
                    key: const ValueKey('e1rm-stat')),
              stat(l10n.exerciseSessions, '${sessions.length}'),
            ],
          ),
          if (points.length >= 2 && points.any((p) => p > 0)) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 72,
              width: double.infinity,
              child: CustomPaint(
                painter:
                    _LinePainter(points, palette.accent, palette.accentSoft),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat.MMM(locale).format(sessions.first.date),
                    style: AppText.caption.copyWith(color: palette.chartLabel)),
                Text(DateFormat.MMM(locale).format(sessions.last.date),
                    style: AppText.caption.copyWith(color: palette.chartLabel)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> points;
  final Color line;
  final Color fill;
  _LinePainter(this.points, this.line, this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    var lo = points.reduce((a, b) => a < b ? a : b);
    var hi = points.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    Offset at(int i) => Offset(
          size.width * i / (points.length - 1),
          size.height - (points[i] - lo) / (hi - lo) * (size.height - 8) - 4,
        );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill.withValues(alpha: 0.6));
    canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(at(points.length - 1), 4, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.line != line || old.fill != fill;
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: palette.pillSelected, shape: BoxShape.circle),
            child: Text('$number',
                style: AppText.captionStrong
                    .copyWith(color: palette.onPillSelected)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style:
                    AppText.bodyRegular.copyWith(color: palette.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _Mistake extends StatelessWidget {
  final String text;
  const _Mistake(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: palette.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: Icon(Icons.close, size: 16, color: palette.danger),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style:
                    AppText.bodyRegular.copyWith(color: palette.textPrimary)),
          ),
        ],
      ),
    );
  }
}
