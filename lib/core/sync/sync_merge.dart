/// Pure merge rules for sync. No I/O, so every rule is unit-testable.
library;

import 'dart:convert';

import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

int? micros(DateTime? time) => time?.microsecondsSinceEpoch;

/// Whether [plan] (a live plan or a tombstone) has changes the server
/// hasn't confirmed yet.
bool isPlanDirty(WorkoutTemplate plan, Map<String, PlanVersion> versions) {
  if (plan.deletedAt != null) return true;
  final version = versions[plan.id];
  return version == null || version.local != micros(plan.updatedAt);
}

class PlanMerge {
  /// Live plans, in display order.
  final List<WorkoutTemplate> plans;

  /// Deletions still to be pushed.
  final List<WorkoutTemplate> tombstones;
  final Map<String, PlanVersion> versions;

  /// Whether [plans] or [tombstones] differ from the local input.
  final bool changed;

  const PlanMerge(this.plans, this.tombstones, this.versions, this.changed);
}

/// Merges pulled plans into local ones, last write wins per plan.
///
/// - A local plan without unsynced changes always takes the server's
///   version (including its deletion).
/// - A plan changed on both sides: the local change wins if the server
///   still has the version this device last synced (nobody else changed
///   it), otherwise the newer of the two timestamps wins. Plans without a
///   timestamp (built-in / pre-sync) lose.
/// - Tombstones take part like any other change.
/// - Plans only on the server are added after the local ones, by position.
///
/// With [fullPull] (the remote list is complete) a local plan the server
/// doesn't have is marked unsynced so it gets pushed again.
PlanMerge mergePlans({
  required List<WorkoutTemplate> local,
  required List<WorkoutTemplate> tombstones,
  required Map<String, PlanVersion> versions,
  required List<RemotePlan> remote,
  bool fullPull = false,
}) {
  final nextVersions = Map.of(versions);
  final remoteById = {for (final r in remote) r.id: r};
  final plans = <WorkoutTemplate>[];
  final nextTombstones = <WorkoutTemplate>[];
  var changed = false;

  bool localWins(WorkoutTemplate mine, RemotePlan theirs) {
    final base = versions[mine.id];
    if (base != null && base.server == micros(theirs.updatedAt)) return true;
    final mineTime = micros(mine.updatedAt);
    return mineTime != null && mineTime > micros(theirs.updatedAt)!;
  }

  void takeRemote(RemotePlan theirs) {
    final time = micros(theirs.updatedAt)!;
    if (theirs.isDeleted) {
      nextVersions.remove(theirs.id);
    } else {
      nextVersions[theirs.id] = PlanVersion(local: time, server: time);
      plans.add(theirs.template);
    }
  }

  for (final mine in local) {
    final theirs = remoteById.remove(mine.id);
    if (theirs == null) {
      if (fullPull) nextVersions.remove(mine.id);
      plans.add(mine);
    } else if (isPlanDirty(mine, versions) && localWins(mine, theirs)) {
      plans.add(mine);
    } else {
      takeRemote(theirs);
      if (theirs.isDeleted || !_samePlan(mine, theirs.template)) {
        changed = true;
      }
    }
  }

  for (final tombstone in tombstones) {
    final theirs = remoteById.remove(tombstone.id);
    if (theirs == null || localWins(tombstone, theirs)) {
      nextTombstones.add(tombstone);
    } else {
      takeRemote(theirs);
      changed = true;
    }
  }

  final added = remoteById.values.where((r) => !r.isDeleted).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  for (final theirs in added) {
    takeRemote(theirs);
    changed = true;
  }
  for (final theirs in remoteById.values.where((r) => r.isDeleted)) {
    nextVersions.remove(theirs.id);
  }

  return PlanMerge(plans, nextTombstones, nextVersions, changed);
}

bool _samePlan(WorkoutTemplate a, WorkoutTemplate b) =>
    jsonEncode(a.toJson()) == jsonEncode(b.toJson());

class UnionMerge<T> {
  final List<T> items;

  /// Whether anything was added to the local list.
  final bool changed;

  const UnionMerge(this.items, this.changed);
}

/// Union by id for append-only data (history, chat). Local items win on an
/// id clash (they're identical anyway) and keep their order; items only
/// on the server are slotted in by [compare] (after local ones on ties).
UnionMerge<T> unionById<T>({
  required List<T> local,
  required Iterable<T> remote,
  required String Function(T) idOf,
  required int Function(T, T) compare,
}) {
  final known = {for (final item in local) idOf(item)};
  final added = stableSorted(
    [
      for (final item in remote)
        if (known.add(idOf(item))) item,
    ],
    compare,
  );
  if (added.isEmpty) return UnionMerge(local, false);

  final merged = <T>[];
  var i = 0, j = 0;
  while (i < local.length && j < added.length) {
    merged.add(compare(added[j], local[i]) < 0 ? added[j++] : local[i++]);
  }
  merged
    ..addAll(local.skip(i))
    ..addAll(added.skip(j));
  return UnionMerge(merged, true);
}

/// Ids known to be on the server after a pull of [remoteIds]. A full pull
/// is the whole truth, so anything local it lacks gets pushed again.
Set<String> syncedAfterPull(
  Set<String> synced,
  Iterable<String> remoteIds, {
  required bool fullPull,
}) =>
    fullPull ? {...remoteIds} : {...synced, ...remoteIds};

List<T> stableSorted<T>(List<T> items, int Function(T, T) compare) {
  final indexed = items.asMap().entries.toList()
    ..sort((a, b) {
      final result = compare(a.value, b.value);
      return result != 0 ? result : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// Workout history order: newest first.
int newestFirst(CompletedWorkout a, CompletedWorkout b) =>
    b.finishedAt.compareTo(a.finishedAt);
