import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/felix_templates_store.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Bottom sheet for renaming a workout and adding / removing exercises.
class EditWorkoutSheet extends ConsumerStatefulWidget {
  final WorkoutTemplate template;

  const EditWorkoutSheet({super.key, required this.template});

  @override
  ConsumerState<EditWorkoutSheet> createState() => _EditWorkoutSheetState();
}

class _EditWorkoutSheetState extends ConsumerState<EditWorkoutSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.template.name);
  final TextEditingController _exerciseController = TextEditingController();
  late List<Exercise> _exercises = [...widget.template.exercises];

  @override
  void dispose() {
    _nameController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final name = _exerciseController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _exercises = [
        ..._exercises,
        Exercise(
          name: name,
          sets: List.generate(
            3,
            (_) => const WorkoutSet(
              previousKg: 0,
              previousReps: 10,
              kg: 0,
              reps: 10,
            ),
          ),
        ),
      ];
      _exerciseController.clear();
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    ref.read(workoutTemplatesProvider.notifier).update(
          widget.template.copyWith(
            name: name.isEmpty ? widget.template.name : name,
            exercises: _exercises,
          ),
        );
    Navigator.of(context).pop();
  }

  void _delete() {
    ref.read(workoutTemplatesProvider.notifier).remove(widget.template.id);
    ref.read(felixTemplateIdsProvider.notifier).remove([widget.template.id]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.gymEditNameHint,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.gymEditDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: palette.textSecondary,
                    onPressed: _delete,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return ListTile(
                    key: ValueKey('${exercise.name}-$index'),
                    title: Text(
                      exercise.name,
                      style: TextStyle(color: palette.textPrimary),
                    ),
                    subtitle: Text(
                      '${exercise.sets.length} sets',
                      style: TextStyle(color: palette.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      color: palette.textSecondary,
                      onPressed: () =>
                          setState(() => _exercises.removeAt(index)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _exerciseController,
                      decoration: InputDecoration(
                        hintText: l10n.gymEditAddExerciseHint,
                      ),
                      onSubmitted: (_) => _addExercise(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(l10n.gymEditSave),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
