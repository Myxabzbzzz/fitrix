import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';
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
    final profile = _ref.read(profileProvider).valueOrNull ??
        await _ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;
    await _ref.read(profileProvider.notifier).saveProfile(
          ProfileValidator.normalize(
              profile.copyWith(weight: formatProfileNumber(w.kg))),
        );
    unawaited(_ref.read(accountServiceProvider)?.profileChanged());
  }
}
