import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';

/// Product id -> quantity, persisted in SharedPreferences as JSON.
class CartNotifier extends Notifier<Map<String, int>> {
  static const key = 'cart';
  static const maxPerItem = 20;

  @override
  Map<String, int> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          if (e.value is int && (e.value as int) > 0)
            e.key: (e.value as int).clamp(1, maxPerItem),
      };
    } catch (_) {
      return {};
    }
  }

  int get count => state.values.fold(0, (a, b) => a + b);

  void add(String id) {
    final n = state[id] ?? 0;
    if (n >= maxPerItem) return;
    _set({...state, id: n + 1});
  }

  void remove(String id) {
    final n = state[id] ?? 0;
    if (n == 0) return;
    final next = {...state};
    if (n == 1) {
      next.remove(id);
    } else {
      next[id] = n - 1;
    }
    _set(next);
  }

  void clear() => _set({});

  void _set(Map<String, int> next) {
    state = next;
    ref.read(sharedPreferencesProvider).setString(key, jsonEncode(next));
  }
}
