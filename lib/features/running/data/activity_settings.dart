import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';

/// Whether the voice speaks, per activity (prefs `activity_voice_v1`).
/// Kinds never set follow [ActivityProfile.voiceDefault].
class ActivityVoiceNotifier extends StateNotifier<Map<ActivityKind, bool>> {
  ActivityVoiceNotifier(this._prefs) : super(_load(_prefs));

  static const key = 'activity_voice_v1';

  final SharedPreferences _prefs;

  static Map<ActivityKind, bool> _load(SharedPreferences prefs) {
    final saved = <ActivityKind, bool>{};
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        for (final e in (jsonDecode(raw) as Map).entries) {
          final kind =
              ActivityKind.values.where((k) => k.name == e.key).firstOrNull;
          if (kind != null && e.value is bool) saved[kind] = e.value as bool;
        }
      } catch (_) {}
    }
    return {
      for (final k in ActivityKind.values)
        k: saved[k] ?? profileFor(k).voiceDefault,
    };
  }

  void set(ActivityKind kind, bool on) {
    state = {...state, kind: on};
    _prefs.setString(
        key, jsonEncode({for (final e in state.entries) e.key.name: e.value}));
  }
}

final activityVoiceProvider =
    StateNotifierProvider<ActivityVoiceNotifier, Map<ActivityKind, bool>>(
        (ref) => ActivityVoiceNotifier(ref.read(sharedPreferencesProvider)));
