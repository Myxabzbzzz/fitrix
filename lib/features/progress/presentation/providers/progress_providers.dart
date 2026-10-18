import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/doc_deletions.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';

final bodyWeightStoreProvider = Provider<BodyWeightStore>(
  (ref) => BodyWeightStore(ref.watch(sharedPreferencesProvider)),
);

/// Weigh-ins, oldest first.
final bodyWeightProvider =
    StateNotifierProvider<BodyWeightNotifier, List<WeighIn>>(
  (ref) => BodyWeightNotifier(ref),
);

class BodyWeightNotifier extends StateNotifier<List<WeighIn>> {
  final Ref _ref;
  BodyWeightNotifier(this._ref)
      : super(_ref.read(bodyWeightStoreProvider).all());

  /// Stores the weigh-in and updates the profile weight the same way Edit
  /// profile does (save, then upload in the background).
  Future<void> log(WeighIn w) async {
    await _ref.read(bodyWeightStoreProvider).add(w);
    state = _ref.read(bodyWeightStoreProvider).all();
    _ref.read(localChangesProvider).notify();
    final profile = _ref.read(profileProvider).valueOrNull ??
        await _ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;
    await _ref.read(profileProvider.notifier).saveProfile(
          ProfileValidator.normalize(
              profile.copyWith(weight: formatProfileNumber(w.kg))),
        );
    unawaited(_ref.read(accountServiceProvider)?.profileChanged());
  }

  /// Stores the weigh-in without touching the profile. Returns the weigh-in
  /// of the same day it replaced, if any.
  Future<WeighIn?> record(WeighIn w) async {
    final store = _ref.read(bodyWeightStoreProvider);
    final replaced = store
        .all()
        .where((e) =>
            e.at.year == w.at.year &&
            e.at.month == w.at.month &&
            e.at.day == w.at.day)
        .firstOrNull;
    await store.add(w);
    state = store.all();
    _ref.read(localChangesProvider).notify();
    return replaced;
  }

  /// Takes back [record]: removes the weigh-in at [at] and puts [replaced]
  /// back.
  Future<void> unrecord(DateTime at, {WeighIn? replaced}) async {
    final store = _ref.read(bodyWeightStoreProvider);
    await store.remove(at);
    if (replaced != null) await store.add(replaced);
    state = store.all();
    // The restored weigh-in is the same day's doc with older content; only
    // without one is the day's doc gone.
    if (replaced == null) {
      recordDocDeleted(_ref, 'weight', dayKey(at));
    } else {
      _ref.read(localChangesProvider).notify();
    }
  }

  /// Weigh-ins pulled from the cloud: screens re-read the store.
  void refresh() => state = _ref.read(bodyWeightStoreProvider).all();
}
