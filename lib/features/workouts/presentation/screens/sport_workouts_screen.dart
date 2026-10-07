import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/edit_workout_sheet.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Workouts of one sport ("Gym"): today's workout card plus the other plans.
class SportWorkoutsScreen extends ConsumerStatefulWidget {
  final Sport sport;

  const SportWorkoutsScreen({super.key, required this.sport});

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
        builder: (context) => AlertDialog(
          title: const Text('Finish current workout?'),
          content: Text(
            '"${active.template.name}" is still in progress. '
            'Start "${template.name}" instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start'),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final workouts = ref.watch(workoutsForSportProvider(_sport));

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(_sport.label),
            PillSelector<Sport>(
              items: Sport.values,
              selected: _sport,
              labelOf: (s) => s.label,
              onSelected: (s) => setState(() => _sport = s),
            ),
            Expanded(
              child: SyncRefresh(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(31, 24, 31, 24),
                  children: [
                    if (workouts.isNotEmpty)
                      _SwipeToDelete(
                        key: ValueKey('swipe-${workouts.first.id}'),
                        onDelete: () => _delete(workouts.first),
                        child: _TodayWorkoutCard(
                          workout: workouts.first,
                          onStart: () => _start(workouts.first),
                          onEdit: () => _edit(workouts.first),
                        ),
                      ),
                    const SizedBox(height: 17),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 17,
                      crossAxisSpacing: 17,
                      childAspectRatio: 148 / 96,
                      children: [
                        for (final workout in workouts.skip(1))
                          _SwipeToDelete(
                            key: ValueKey('swipe-${workout.id}'),
                            onDelete: () => _delete(workout),
                            child: _WorkoutTile(
                              workout: workout,
                              onStart: () => _start(workout),
                              onEdit: () => _edit(workout),
                            ),
                          ),
                        _AddWorkoutTile(onTap: _addWorkout),
                      ],
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
    return AlertDialog(
      title: const Text('New workout'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Shoulders'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  final WorkoutTemplate workout;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  const _TodayWorkoutCard({
    required this.workout,
    required this.onStart,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final meta = [
      formatDuration(workout.estimatedDuration, withSeconds: false),
      '${workout.exercises.length} exercises',
      workout.focus,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: palette.buttonMuted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: 12, color: palette.textPrimary),
                const SizedBox(width: 2),
                Text(
                  'TODAY’S WORKOUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            workout.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 131,
                child: _SmallButton(
                  label: 'Start',
                  primary: true,
                  height: 32,
                  fontSize: 16,
                  onTap: onStart,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: 57,
                child: _SmallButton(
                  label: 'Edit',
                  height: 32,
                  fontSize: 16,
                  onTap: onEdit,
                ),
              ),
              const Spacer(flex: 70),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutTemplate workout;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  const _WorkoutTile({
    required this.workout,
    required this.onStart,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: palette.tile,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  workout.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 92,
                  child: _SmallButton(
                    label: 'Start',
                    height: 23,
                    fontSize: 12,
                    onTap: onStart,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline, color: Colors.white),
          ),
        ),
      ),
      child: child,
    );
  }
}

class _AddWorkoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddWorkoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: palette.tile,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.buttonMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: palette.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final bool primary;
  final double height;
  final double fontSize;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: primary ? palette.accent : palette.buttonMuted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: primary ? Colors.white : palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
