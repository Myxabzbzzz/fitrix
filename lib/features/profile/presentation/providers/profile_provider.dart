import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier(ref.read(profileRepositoryProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile();
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Stores onboarding answers (goal, experience, sports) on the saved
  /// profile, leaving the other fields as they are. Doesn't flip the state
  /// to loading, so screens watching the profile don't flicker.
  Future<void> saveAnswers({
    String? goal,
    String? experience,
    List<String>? sports,
  }) async {
    try {
      final current = await _repository.getProfile() ??
          UserProfile(name: '', surname: '', age: '', weight: '', height: '');
      final updated = current.copyWith(
        goal: goal,
        experience: experience,
        sports: sports,
      );
      await _repository.saveProfile(updated);
      state = AsyncValue.data(updated);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Sets the weight ("78.5") on the saved profile without flipping the
  /// state to loading. Returns false (changing nothing) when there is no
  /// saved profile or saving failed.
  Future<bool> saveWeight(String weight) async {
    try {
      final current = await _repository.getProfile();
      if (current == null) return false;
      final updated = current.copyWith(weight: weight);
      await _repository.saveProfile(updated);
      state = AsyncValue.data(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
