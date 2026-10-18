import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Ids of the workout plans Felix made, kept on this device only (the
/// server has no field for it). They get the "Felix plan" badge.
class FelixTemplateIdsNotifier extends StateNotifier<Set<String>> {
  static const key = 'felix_template_ids_v1';
  static const batchesKey = 'felix_plan_batches_v1';

  final SharedPreferences _prefs;

  FelixTemplateIdsNotifier(this._prefs)
      : super({...?_prefs.getStringList(key)});

  void add(Iterable<String> ids) {
    state = {...state, ...ids};
    _prefs.setStringList(key, state.toList());
  }

  void remove(Iterable<String> ids) {
    final gone = ids.toSet();
    state = {
      for (final id in state)
        if (!gone.contains(id)) id
    };
    _prefs.setStringList(key, state.toList());
  }

  Map<String, dynamic> _batches() {
    try {
      final v = jsonDecode(_prefs.getString(batchesKey) ?? '{}');
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return {};
  }

  /// Remembers which templates one applied Felix card created, so its Undo
  /// can take exactly those back.
  void recordBatch(int at, List<String> templateIds) {
    final all = _batches()..['$at'] = templateIds;
    // Only the latest few matter: cards can only be undone while shown.
    while (all.length > 30) {
      all.remove(all.keys.first);
    }
    _prefs.setString(batchesKey, jsonEncode(all));
  }

  List<String> batch(int at) {
    final v = _batches()['$at'];
    return v is List ? [for (final e in v) '$e'] : const [];
  }
}

final felixTemplateIdsProvider =
    StateNotifierProvider<FelixTemplateIdsNotifier, Set<String>>((ref) =>
        FelixTemplateIdsNotifier(ref.watch(sharedPreferencesProvider)));

/// The id of the planned session [scheduleFelixPlan] makes for a template.
String felixSessionId(String templateId) => 'felix-$templateId';

/// The date a Felix day name (`today`, `mon`..`sun`) means: the weekday in
/// this week when that is today or later, else in the next week. Null for
/// anything else.
DateTime? felixDayOf(String? name, DateTime today) {
  final start = dateOnly(today);
  if (name == 'today') return start;
  final idx = _weekdayNames.indexOf(name ?? '');
  if (idx < 0) return null;
  final d = addDays(weekStartOf(start), idx);
  return d.isBefore(start) ? addDays(d, 7) : d;
}

const _weekdayNames = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// The week-plan sessions for plans Felix [created]. Returns only the new
/// sessions; [existing] is the current plan, which they are fitted around.
///  - `today`: today.
///  - `week` with [days]: each plan on its weekday this week when that is
///    today or later, else the same weekday next week. Plans without a
///    usable day are spread like the case below.
///  - `week` without days: spread over the next 7 days from [today], leaving
///    out days with a hard session and the days next to a hard non-gym one.
///  - null: nothing is planned.
List<PlannedSession> scheduleFelixPlan({
  required List<WorkoutTemplate> created,
  required String? when,
  required List<String?>? days,
  required DateTime today,
  required List<PlannedSession> existing,
}) {
  if (when == null || created.isEmpty) return const [];
  final start = dateOnly(today);
  PlannedSession session(WorkoutTemplate t, DateTime day) => PlannedSession(
        id: felixSessionId(t.id),
        day: day,
        sport: t.sport,
        title: t.name,
        templateId: t.id,
        minutes: t.estimatedDuration.inMinutes,
        intensity: intensityOfTemplate(t),
      );
  if (when == 'today') {
    return [for (final t in created) session(t, start)];
  }

  final dayFor = <int, DateTime>{};
  for (var i = 0; i < created.length; i++) {
    final name = days != null && i < days.length ? days[i] : null;
    final d = felixDayOf(name, start);
    if (d != null) dayFor[i] = d;
  }

  final open = [
    for (var i = 0; i < created.length; i++)
      if (!dayFor.containsKey(i)) i
  ];
  if (open.isNotEmpty) {
    final window = [for (var n = 0; n < 7; n++) addDays(start, n)];
    final taken = {...dayFor.values};
    final hardWeekdays = hardNonGymWeekdays(existing);
    bool hardOn(DateTime d) =>
        existing.any((s) => s.intensity == Intensity.hard && sameDay(s.day, d));
    bool nextToHard(DateTime d) =>
        hardWeekdays.contains(addDays(d, -1).weekday) ||
        hardWeekdays.contains(addDays(d, 1).weekday);
    final clear = [
      for (final d in window)
        if (!taken.contains(d) && !hardOn(d) && !nextToHard(d)) d
    ];
    final near = [
      for (final d in window)
        if (!taken.contains(d) && !hardOn(d) && nextToHard(d)) d
    ];
    final rest = [
      for (final d in window)
        if (!taken.contains(d) && hardOn(d)) d
    ];
    var pool = clear;
    if (pool.length < open.length) {
      pool = [...clear, ...near, ...rest];
    }
    // An even spread of the open plans over the pool.
    final chosen = <DateTime>[];
    if (pool.length <= open.length) {
      chosen.addAll(pool);
    } else {
      final head = pool.take(open.length == 1 ? 1 : pool.length).toList();
      for (var j = 0; j < open.length; j++) {
        final at = open.length == 1
            ? 0
            : (j * (head.length - 1) / (open.length - 1)).round();
        chosen.add(head[at]);
      }
    }
    chosen.sort();
    for (var j = 0; j < open.length && j < chosen.length; j++) {
      dayFor[open[j]] = chosen[j];
    }
  }

  return [
    for (var i = 0; i < created.length; i++)
      if (dayFor[i] != null) session(created[i], dayFor[i]!)
  ];
}
