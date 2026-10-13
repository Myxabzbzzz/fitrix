import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/workout_card.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/workouts/domain/coach_message.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/edit_workout_sheet.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';

/// Workouts of one sport ("Gym"): today's workout card plus the other plans.
class SportWorkoutsScreen extends ConsumerStatefulWidget {
  final Sport sport;

  /// Clock, injectable for tests.
  final DateTime Function() now;

  const SportWorkoutsScreen({
    super.key,
    required this.sport,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<SportWorkoutsScreen> createState() =>
      _SportWorkoutsScreenState();
}

class _SportWorkoutsScreenState extends ConsumerState<SportWorkoutsScreen> {
  late Sport _sport = widget.sport;

  Future<void> _start(WorkoutTemplate template) async {
    final active = ref.read(activeWorkoutProvider);
    if (active != null && active.template.id != template.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.gymFinishCurrentTitle),
            content: Text(
              l10n.gymFinishCurrentBody(active.template.name, template.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.gymStart),
              ),
            ],
          );
        },
      );
      if (replace != true || !mounted) return;
    }
    if (active == null || active.template.id != template.id) {
      ref.read(activeWorkoutProvider.notifier).start(template);
    }
    ref.read(activeWorkoutExpandedProvider.notifier).state = true;
  }

  Future<void> _addWorkout() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewWorkoutDialog(),
    );
    if (name != null && name.trim().isNotEmpty) {
      ref.read(workoutTemplatesProvider.notifier).add(_sport, name.trim());
    }
  }

  /// Swiped away: deleted at once, with a few seconds to undo.
  void _delete(WorkoutTemplate template) {
    final notifier = ref.read(workoutTemplatesProvider.notifier);
    final index = ref
        .read(workoutTemplatesProvider)
        .indexWhere((w) => w.id == template.id);
    notifier.remove(template.id);

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.workoutDeleted(template.name)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => notifier.restore(template, index),
        ),
      ));
  }

  void _edit(WorkoutTemplate template) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditWorkoutSheet(template: template),
    );
  }

  /// Opens this sport's Felix trainer chat (the Felix tab).
  void _askFelix() {
    ref.read(selectedAssistantTopicProvider.notifier).state =
        AssistantTopic.all.firstWhere((t) => t.sport == _sport);
    context.go(AppRouter.felix);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final workouts = ref.watch(workoutsForSportProvider(_sport));
    final history = ref
        .watch(workoutHistoryProvider)
        .where((w) => w.sport == _sport)
        .toList();
    final now = widget.now();
    final localeName = Localizations.localeOf(context).toString();
    // Room for a 2-line title at the user's text size.
    final cellHeight = 128 + MediaQuery.textScalerOf(context).scale(16) * 2 - 32;
    final coach = coachMessage(history, now,
        todayWorkout: workouts.isEmpty ? null : workouts.first.name,
        localeName: localeName);

    bool doneToday(WorkoutTemplate t) => history.any((w) =>
        w.templateId == t.id &&
        w.finishedAt.year == now.year &&
        w.finishedAt.month == now.month &&
        w.finishedAt.day == now.day);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(_sport.localizedLabel(l10n)),
            PillSelector<Sport>(
              items: Sport.values,
              selected: _sport,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) => setState(() => _sport = s),
            ),
            Expanded(
              child: SyncRefresh(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisExtent: cellHeight,
                      ),
                      children: [
                        for (var i = 0; i < workouts.length; i++)
                          _SwipeToDelete(
                            key: ValueKey('swipe-${workouts[i].id}'),
                            onDelete: () => _delete(workouts[i]),
                            child: GestureDetector(
                              onLongPress: () => _edit(workouts[i]),
                              child: WorkoutCard(
                                title: workouts[i].name,
                                dayLabel: i == 0
                                    ? l10n.gymToday
                                    : DateFormat('EEEE', localeName)
                                        .format(now.add(Duration(days: i))),
                                today: i == 0,
                                done: doneToday(workouts[i]),
                                startLabel: l10n.gymStart,
                                doneLabel: l10n.gymDone,
                                onStart: () => _start(workouts[i]),
                                onEdit: () => _edit(workouts[i]),
                                editLabel: '${l10n.workoutEditLabel}, ${workouts[i].name}',
                              ),
                            ),
                          ),
                        AddWorkoutCard(onTap: _addWorkout),
                      ],
                    ),
                    if (coach != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      CoachCard(
                        eyebrow: l10n.gymCoachEyebrow(_sport.localizedLabel(l10n)),
                        title: switch (coach.kind) {
                          CoachMessageKind.firstWorkout =>
                            l10n.gymCoachFirstTitle,
                          CoachMessageKind.welcomeBack =>
                            l10n.gymCoachBackTitle,
                        },
                        message: switch (coach.kind) {
                          CoachMessageKind.firstWorkout =>
                            l10n.gymCoachFirstMessage(coach.today),
                          CoachMessageKind.welcomeBack =>
                            l10n.gymCoachBackMessage(coach.days),
                        },
                        imageAsset: 'assets/images/felix_avatar.png',
                        primaryLabel:
                            workouts.isEmpty ? null : l10n.gymStart,
                        onPrimary: workouts.isEmpty
                            ? null
                            : () => _start(workouts.first),
                        secondaryLabel: l10n.gymAskFelix,
                        onSecondary: _askFelix,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for a new workout's name. Owns its text controller so it is only
/// disposed after the dialog's closing animation has finished.
class _NewWorkoutDialog extends StatefulWidget {
  const _NewWorkoutDialog();

  @override
  State<_NewWorkoutDialog> createState() => _NewWorkoutDialogState();
}

class _NewWorkoutDialogState extends State<_NewWorkoutDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.gymNewWorkout),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.gymNewWorkoutHint),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.gymAdd),
        ),
      ],
    );
  }
}

/// Swipe left to delete: a red strip with a bin follows the finger, with a
/// tap of haptics once the swipe is far enough to delete.
class _SwipeToDelete extends StatelessWidget {
  final VoidCallback onDelete;
  final Widget child;

  const _SwipeToDelete({
    required super.key,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      onUpdate: (details) {
        if (details.reached != details.previousReached) {
          HapticFeedback.mediumImpact();
        }
      },
      onDismissed: (_) => onDelete(),
      background: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalette.of(context).danger,
          borderRadius: AppRadius.smAll,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Icon(Icons.delete_outline,
                color: AppPalette.of(context).onAccent),
          ),
        ),
      ),
      child: child,
    );
  }
}
