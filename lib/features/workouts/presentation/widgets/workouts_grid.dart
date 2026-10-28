import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/felix_plan_badge.dart';
import 'package:fitrix/core/widgets/workout_card.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/workouts/data/felix_templates_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/edit_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The plans of one [sport] as a grid of cards, with the day the week plan
/// has them on, swipe to delete (with undo), edit, and a card to add one.
/// The card's button says [actionLabel] and runs [onAction].
class WorkoutsGrid extends ConsumerWidget {
  const WorkoutsGrid({
    super.key,
    required this.sport,
    required this.actionLabel,
    required this.onAction,
  });

  final Sport sport;
  final String actionLabel;
  final void Function(WorkoutTemplate) onAction;

  Future<void> _addWorkout(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewWorkoutDialog(),
    );
    if (name != null && name.trim().isNotEmpty) {
      ref.read(workoutTemplatesProvider.notifier).add(sport, name.trim());
    }
  }

  /// Swiped away: deleted at once, with a few seconds to undo.
  void _delete(BuildContext context, WidgetRef ref, WorkoutTemplate template) {
    final notifier = ref.read(workoutTemplatesProvider.notifier);
    final felix = ref.read(felixTemplateIdsProvider.notifier);
    final wasFelix = ref.read(felixTemplateIdsProvider).contains(template.id);
    final index = ref
        .read(workoutTemplatesProvider)
        .indexWhere((w) => w.id == template.id);
    notifier.remove(template.id);
    felix.remove([template.id]);

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.workoutDeleted(template.name)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            notifier.restore(template, index);
            if (wasFelix) felix.add([template.id]);
          },
        ),
      ));
  }

  void _edit(BuildContext context, WorkoutTemplate template) {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditWorkoutSheet(template: template),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workouts = ref.watch(workoutsForSportProvider(sport));
    final history = ref
        .watch(workoutHistoryProvider)
        .where((w) => w.sport == sport)
        .toList();
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider);
    final allHistory = ref.watch(workoutHistoryProvider);
    final felixIds = ref.watch(felixTemplateIdsProvider);
    final hasFelix = workouts.any((w) => felixIds.contains(w.id));
    // Room for a 2-line title at the user's text size.
    final cellHeight = 128 +
        MediaQuery.textScalerOf(context).scale(16) * 2 -
        32 +
        (hasFelix ? MediaQuery.textScalerOf(context).scale(12) + 14 : 0);

    // Today only for a plan with an open session today; other planned plans
    // show their next day; the rest no day at all.
    bool openToday(WorkoutTemplate t) => plan.any((s) =>
        s.templateId == t.id &&
        s.day == today &&
        statusOf(s, allHistory, today, plan: plan) != SessionStatus.done);
    String? dayLabel(WorkoutTemplate t) {
      if (openToday(t)) return l10n.gymToday;
      final next =
          nextSessionAfter(plan, today, where: (s) => s.templateId == t.id);
      return next == null ? null : upcomingDayLabel(context, today, next.day);
    }

    bool doneToday(WorkoutTemplate t) => history
        .any((w) => w.templateId == t.id && sameDay(w.finishedAt, today));

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: cellHeight,
      ),
      children: [
        for (var i = 0; i < workouts.length; i++)
          _SwipeToDelete(
            key: ValueKey('swipe-${workouts[i].id}'),
            onDelete: () => _delete(context, ref, workouts[i]),
            child: GestureDetector(
              onLongPress: () => _edit(context, workouts[i]),
              child: SizedBox.expand(
                  child: WorkoutCard(
                title: workouts[i].name,
                dayLabel: dayLabel(workouts[i]),
                badge: felixIds.contains(workouts[i].id)
                    ? const FelixPlanBadge()
                    : null,
                today: openToday(workouts[i]),
                done: doneToday(workouts[i]),
                startLabel: actionLabel,
                doneLabel: l10n.gymDone,
                onStart: () => onAction(workouts[i]),
                onEdit: () => _edit(context, workouts[i]),
                editLabel: '${l10n.workoutEditLabel}, ${workouts[i].name}',
              )),
            ),
          ),
        AddWorkoutCard(onTap: () => _addWorkout(context, ref)),
      ],
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
