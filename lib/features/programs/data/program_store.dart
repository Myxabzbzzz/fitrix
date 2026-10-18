import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';

/// The program the user is following. [sessionTemplateIds] maps a program
/// session name to the workout template created for it.
class ActiveProgram {
  final String programId;
  final DateTime start;

  /// 1 = Monday.
  final List<int> weekdays;
  final Map<String, String> sessionTemplateIds;

  ActiveProgram({
    required this.programId,
    required DateTime start,
    required this.weekdays,
    required this.sessionTemplateIds,
  }) : start = dateOnly(start);

  Map<String, dynamic> toJson() => {
        'programId': programId,
        'start': '${start.year.toString().padLeft(4, '0')}-'
            '${start.month.toString().padLeft(2, '0')}-'
            '${start.day.toString().padLeft(2, '0')}',
        'weekdays': weekdays,
        'sessionTemplateIds': sessionTemplateIds,
      };

  /// Throws on anything malformed.
  factory ActiveProgram.fromJson(Map<String, dynamic> j) {
    final parts = (j['start'] as String).split('-');
    if (parts.length != 3) throw const FormatException('bad start');
    final days = [for (final d in j['weekdays'] as List) d as int];
    if (days.isEmpty || days.any((d) => d < 1 || d > 7)) {
      throw const FormatException('bad weekdays');
    }
    return ActiveProgram(
      programId: j['programId'] as String,
      start: DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
      weekdays: days,
      sessionTemplateIds: {
        for (final e in (j['sessionTemplateIds'] as Map).entries)
          e.key as String: e.value as String,
      },
    );
  }
}

class ProgramStore {
  static const key = 'active_program_v1';

  final SharedPreferences _prefs;
  ProgramStore(this._prefs);

  /// Null when nothing is saved or the saved value is unreadable.
  ActiveProgram? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return ActiveProgram.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ActiveProgram p) =>
      _prefs.setString(key, jsonEncode(p.toJson()));

  Future<void> clear() => _prefs.remove(key);
}
