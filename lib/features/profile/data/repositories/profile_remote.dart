import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';

/// The signed-in user's row in the `profiles` table.
abstract class ProfileRemote {
  /// The row for [userId], or null if the user never saved a profile.
  Future<ProfileRow?> fetch(String userId);

  /// Inserts or updates the row (see [ProfileRow.toUpsert]).
  Future<void> upsert(ProfileRow row, {bool includeProfile = true});
}

class SupabaseProfileRemote implements ProfileRemote {
  SupabaseProfileRemote(this._client);

  final SupabaseClient _client;

  static const _timeout = Duration(seconds: 15);

  @override
  Future<ProfileRow?> fetch(String userId) async {
    final json = await _client
        .from(ProfileRow.table)
        .select(ProfileRow.columns)
        .eq('id', userId)
        .maybeSingle()
        .timeout(_timeout);
    return json == null ? null : ProfileRow.fromJson(json);
  }

  @override
  Future<void> upsert(ProfileRow row, {bool includeProfile = true}) async {
    await _client
        .from(ProfileRow.table)
        .upsert(row.toUpsert(includeProfile: includeProfile))
        .timeout(_timeout);
  }
}
