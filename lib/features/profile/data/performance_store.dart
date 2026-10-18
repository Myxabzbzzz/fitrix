import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';

enum Sex { male, female }

/// Training numbers the server profile has no columns for. Kept on the
/// device only (SharedPreferences, [performanceProfileKey]).
class PerformanceProfile {
  const PerformanceProfile({
    this.sex,
    this.restingHr,
    this.maxHr,
    this.lthr,
    this.ftpW,
    this.fiveK,
  });

  final Sex? sex;
  final int? restingHr;
  final int? maxHr;
  final int? lthr;
  final int? ftpW;
  final Duration? fiveK;

  static const empty = PerformanceProfile();

  Map<String, Object?> toJson() => {
        if (sex != null) 'sex': sex!.name,
        if (restingHr != null) 'restingHr': restingHr,
        if (maxHr != null) 'maxHr': maxHr,
        if (lthr != null) 'lthr': lthr,
        if (ftpW != null) 'ftpW': ftpW,
        if (fiveK != null) 'fiveKSeconds': fiveK!.inSeconds,
      };

  factory PerformanceProfile.fromJson(Map<String, dynamic> json) {
    int? intOf(String key) {
      final v = json[key];
      return v is num ? v.toInt() : null;
    }

    final sexName = json['sex'];
    final five = intOf('fiveKSeconds');
    return PerformanceProfile(
      sex: Sex.values.where((s) => s.name == sexName).firstOrNull,
      restingHr: intOf('restingHr'),
      maxHr: intOf('maxHr'),
      lthr: intOf('lthr'),
      ftpW: intOf('ftpW'),
      fiveK: five == null ? null : Duration(seconds: five),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PerformanceProfile &&
      other.sex == sex &&
      other.restingHr == restingHr &&
      other.maxHr == maxHr &&
      other.lthr == lthr &&
      other.ftpW == ftpW &&
      other.fiveK == fiveK;

  @override
  int get hashCode => Object.hash(sex, restingHr, maxHr, lthr, ftpW, fiveK);
}

const performanceProfileKey = 'performance_profile_v1';

class PerformanceNotifier extends StateNotifier<PerformanceProfile> {
  PerformanceNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static PerformanceProfile _read(SharedPreferences prefs) {
    final raw = prefs.getString(performanceProfileKey);
    if (raw == null) return PerformanceProfile.empty;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return PerformanceProfile.fromJson(json);
      }
    } catch (_) {}
    return PerformanceProfile.empty;
  }

  /// Replaces the whole profile (null fields mean "not set").
  Future<void> save(PerformanceProfile profile) async {
    state = profile;
    await _prefs.setString(performanceProfileKey, jsonEncode(profile.toJson()));
  }
}

final performanceProfileProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceProfile>(
  (ref) => PerformanceNotifier(ref.watch(sharedPreferencesProvider)),
);
