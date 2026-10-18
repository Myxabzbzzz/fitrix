import 'package:fitrix/core/time/day_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/doc_deletions.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/programs/data/program_store.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

final programStoreProvider = Provider<ProgramStore>(
    (ref) => ProgramStore(ref.watch(sharedPreferencesProvider)));

class ActiveProgramNotifier extends StateNotifier<ActiveProgram?> {
  final ProgramStore _store;
  final void Function()? _onChanged;
  final void Function()? _onCleared;

  ActiveProgramNotifier(this._store,
      {void Function()? onChanged, void Function()? onCleared})
      : _onChanged = onChanged,
        _onCleared = onCleared,
        super(_store.load());

  Future<void> set(ActiveProgram p) {
    state = p;
    _onChanged?.call();
    return _store.save(p);
  }

  Future<void> clear() {
    final had = state != null;
    state = null;
    if (had) _onCleared?.call();
    return _store.clear();
  }

  /// The program pulled from the cloud was stored (or removed); show it.
  void refresh() => state = _store.load();
}

final activeProgramProvider =
    StateNotifierProvider<ActiveProgramNotifier, ActiveProgram?>(
  (ref) => ActiveProgramNotifier(
    ref.watch(programStoreProvider),
    onChanged: ref.read(localChangesProvider).notify,
    onCleared: () => recordDocDeleted(ref, 'program', 'active'),
  ),
);

/// The program being followed, resolved in the catalog. Null when none or
/// when the saved id is no longer in the catalog.
final activeProgramInfoProvider =
    Provider<({ActiveProgram active, TrainingProgram program})?>((ref) {
  final a = ref.watch(activeProgramProvider);
  final c = ref.watch(programCatalogProvider).valueOrNull;
  final p = a == null ? null : c?.byId(a.programId);
  return a == null || p == null ? null : (active: a, program: p);
});

/// Starts and ends programs: creates the workout templates, schedules the
/// sessions on the week plan and keeps the [ActiveProgram].
class ProgramStarter {
  final Ref _ref;
  ProgramStarter(this._ref);

  Future<ExerciseCatalog?> _exercises() async {
    try {
      return await _ref.read(exerciseCatalogProvider.future);
    } catch (_) {
      return null;
    }
  }

  bool _isDone(PlannedSession s) =>
      statusOf(
          s, _ref.read(workoutHistoryProvider), _ref.read(clockProvider)()) ==
      SessionStatus.done;

  /// One template per program session (sets prefilled with the start weight
  /// from history, 0 without), then the schedule from [start] on the first
  /// [weekdays]. With [replacePlan] today's and later gym sessions that are
  /// not done are replaced; other sports stay.
  Future<ActiveProgram> start({
    required TrainingProgram program,
    required DateTime start,
    required List<int> weekdays,
    required bool replacePlan,
  }) async {
    final exercises = await _exercises();
    final history = _ref.read(workoutHistoryProvider);
    final plans = [
      for (final s in program.sessions)
        (
          name: '${program.name} · ${s.name}',
          exercises: [
            for (final e in s.exercises)
              Exercise(name: e.exercise, sets: [
                for (var i = 0; i < e.sets; i++)
                  WorkoutSet(
                    previousKg: 0,
                    previousReps: 0,
                    kg: startKg(e.exercise, history, e.repsHigh,
                            catalog: exercises) ??
                        0,
                    reps: e.repsHigh,
                  ),
              ]),
          ],
          minutes: s.minutes,
          focus: s.name,
        ),
    ];
    final notifier = _ref.read(workoutTemplatesProvider.notifier);
    final ids = notifier.addPlans(Sport.gym, plans);
    final templateIds = {
      for (var i = 0; i < ids.length; i++) program.sessions[i].name: ids[i],
    };
    final templates = _ref.read(workoutTemplatesProvider);
    final sessions = scheduleProgram(program, start, weekdays, templateIds,
        intensityOf: (s) => intensityOfTemplate(
            templates.firstWhere((t) => t.id == templateIds[s.name])));

    await _removeOldProgramSessions();
    final plan = _ref.read(weekPlanProvider.notifier);
    if (replacePlan) {
      await plan.replaceFutureGym(sessions, isDone: _isDone);
    } else {
      await plan.addAll(sessions);
    }
    final active = ActiveProgram(
        programId: program.id,
        start: start,
        weekdays: weekdays,
        sessionTemplateIds: templateIds);
    await _ref.read(activeProgramProvider.notifier).set(active);
    return active;
  }

  /// Drops the not yet done sessions from today on of the running program.
  Future<void> _removeOldProgramSessions() async {
    final old = _ref.read(activeProgramProvider);
    if (old == null) return;
    final prefix = programSessionPrefix(old.programId);
    final today = dayOf(_ref.read(clockProvider)());
    await _ref.read(weekPlanProvider.notifier).removeWhere((s) =>
        s.id.startsWith(prefix) && !s.day.isBefore(today) && !_isDone(s));
  }

  /// Ends the program: its later sessions leave the plan, workouts stay.
  Future<void> end() async {
    await _removeOldProgramSessions();
    await _ref.read(activeProgramProvider.notifier).clear();
  }
}

final programStarterProvider = Provider<ProgramStarter>(ProgramStarter.new);
