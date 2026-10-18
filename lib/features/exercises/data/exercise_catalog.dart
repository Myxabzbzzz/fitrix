import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MuscleGroup { chest, back, shoulders, arms, legs, glutes, core }

enum Equipment { barbell, dumbbell, cable, machine, bodyweight, kettlebell }

/// One exercise from the bundled library (`assets/data/exercises.json`).
class ExerciseInfo {
  final String id;
  final String name;
  final MuscleGroup group;
  final List<String> primary;
  final List<String> secondary;
  final Equipment equipment;
  final String pattern;
  final String level;
  final bool compound;

  /// Body areas that carry the load: legs, back, chest, arms, shoulders.
  final List<String> loads;
  final List<String> steps;
  final List<String> mistakes;

  /// Ids of similar exercises.
  final List<String> similar;
  final List<String> aliases;

  const ExerciseInfo({
    required this.id,
    required this.name,
    required this.group,
    required this.primary,
    required this.secondary,
    required this.equipment,
    required this.pattern,
    required this.level,
    required this.compound,
    required this.loads,
    required this.steps,
    required this.mistakes,
    required this.similar,
    this.aliases = const [],
  });

  factory ExerciseInfo.fromJson(Map<String, dynamic> j) {
    List<String> list(String key) =>
        [for (final v in (j[key] as List? ?? const [])) v as String];
    return ExerciseInfo(
      id: j['id'] as String,
      name: j['name'] as String,
      group: MuscleGroup.values.byName(j['group'] as String),
      primary: list('primary'),
      secondary: list('secondary'),
      equipment: Equipment.values.byName(j['equipment'] as String),
      pattern: j['pattern'] as String,
      level: j['level'] as String,
      compound: j['compound'] as bool? ?? false,
      loads: list('loads'),
      steps: list('steps'),
      mistakes: list('mistakes'),
      similar: list('similar'),
      aliases: list('aliases'),
    );
  }
}

class ExerciseCatalog {
  final List<ExerciseInfo> _all;
  final Map<String, ExerciseInfo> _byId;
  final Map<String, ExerciseInfo> _byName;

  ExerciseCatalog(List<ExerciseInfo> exercises)
      : _all = List.unmodifiable(exercises),
        _byId = {for (final e in exercises) e.id: e},
        _byName = _index(exercises);

  static Map<String, ExerciseInfo> _index(List<ExerciseInfo> exercises) {
    final map = <String, ExerciseInfo>{};
    // Names win over aliases, so register aliases first.
    for (final e in exercises) {
      for (final a in e.aliases) {
        map[_norm(a)] = e;
      }
    }
    for (final e in exercises) {
      map[_norm(e.name)] = e;
    }
    return map;
  }

  static String _norm(String s) => s.trim().toLowerCase();

  static const assetPath = 'assets/data/exercises.json';

  static Future<ExerciseCatalog> load(AssetBundle bundle) async {
    final raw = jsonDecode(await bundle.loadString(assetPath)) as List;
    return ExerciseCatalog([
      for (final e in raw) ExerciseInfo.fromJson(e as Map<String, dynamic>),
    ]);
  }

  List<ExerciseInfo> get all => _all;

  /// Matches the name or an alias, ignoring case.
  ExerciseInfo? byName(String name) => _byName[_norm(name)];

  ExerciseInfo? byId(String id) => _byId[id];

  List<ExerciseInfo> similarTo(ExerciseInfo e) => [
        for (final id in e.similar)
          if (_byId[id] != null) _byId[id]!
      ];
}

final exerciseCatalogProvider = FutureProvider<ExerciseCatalog>(
  (ref) => ExerciseCatalog.load(rootBundle),
);
