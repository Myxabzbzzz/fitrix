import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'package:fitrix/core/text/normalize.dart';
import 'package:fitrix/features/content/data/models.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/shop/data/models.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';

/// What the built-in catalogs say on screen in the app language: the
/// [CatalogOverlay] plus the catalogs needed to recognise English names
/// stored in workouts, plans and history. Every method falls back to the
/// English it was given; nothing here is ever stored.
class CatalogText {
  CatalogText(this.overlay, {this.exercises, this.programs, this.seed});

  static final english = CatalogText(CatalogOverlay.empty);

  final CatalogOverlay overlay;
  final ExerciseCatalog? exercises;
  final ProgramCatalog? programs;

  /// The bundled seed content (`seed_content.json`). When given, a content
  /// field reads its translation only while the row's English text equals
  /// the seed's for that id, so a server edit is not hidden. Null: no check.
  final Map<String, dynamic>? seed;

  bool get isEnglish => overlay.isEmpty;

  String _t(String catalog, List<String> path, String english) =>
      isEnglish ? english : overlay.text(catalog, path, english);

  // Exercises ---------------------------------------------------------

  String exerciseName(ExerciseInfo e) =>
      _t('exercises', ['exercises', e.id, 'name'], e.name);

  List<String> exerciseSteps(ExerciseInfo e) => isEnglish
      ? e.steps
      : overlay.list('exercises', ['exercises', e.id, 'steps'], e.steps);

  List<String> exerciseMistakes(ExerciseInfo e) => isEnglish
      ? e.mistakes
      : overlay.list('exercises', ['exercises', e.id, 'mistakes'], e.mistakes);

  /// Names people search for in the app language (not shown).
  List<String> exerciseAliases(ExerciseInfo e) => isEnglish
      ? const []
      : overlay.words('exercises', ['exercises', e.id, 'aliases']);

  /// A primary / secondary muscle ("Front delts").
  String muscle(String english) =>
      _t('exercises', ['muscles', english], english);

  /// A movement pattern ("Horizontal push").
  String pattern(String english) =>
      _t('exercises', ['patterns', english], english);

  /// An exercise name as stored in a workout, plan or history (English):
  /// the catalog exercise it names (by name or alias), else the starter
  /// workouts' and programs' exercise names, else as stored.
  String exercise(String stored) {
    if (isEnglish) return stored;
    final info = exercises?.byName(stored);
    // An alias ("Plank (sec)") may carry more than the catalog name (the
    // unit), so the workouts' own translation comes first for it.
    final isCatalogName =
        info != null && normalizeName(stored) == normalizeName(info.name);
    if (isCatalogName) {
      final name = exerciseName(info);
      if (name != info.name) return name;
    }
    final direct =
        overlay.text('workout_catalog', ['exerciseNames', stored], '');
    if (direct.isNotEmpty) return direct;
    if (info != null && !isCatalogName) {
      final name = exerciseName(info);
      if (name != info.name) return name;
    }
    final trimmed = stored.trim();
    if (trimmed != stored) {
      final t = overlay.text('workout_catalog', ['exerciseNames', trimmed], '');
      if (t.isNotEmpty) return t;
    }
    return stored;
  }

  /// The English name to store for an exercise [typed] by the user: when it
  /// reads (after [searchFold]) like the app-language name of a catalog
  /// exercise or of one of [known] (English names already in the workout),
  /// that English name; else [typed] as it is.
  String canonicalExerciseName(String typed,
      {Iterable<String> known = const []}) {
    if (isEnglish) return typed;
    final f = searchFold(typed);
    if (f.isEmpty) return typed;
    for (final english in [
      ...known,
      for (final e in exercises?.all ?? const <ExerciseInfo>[]) e.name,
    ]) {
      if (searchFold(exercise(english)) == f) return english;
    }
    return typed;
  }

  /// Whether [query] (already lower case and trimmed) finds [e] by its
  /// English name or aliases or by those of the app language.
  bool exerciseMatches(ExerciseInfo e, String query) {
    final q = searchFold(query);
    if (q.isEmpty) return true;
    bool has(String s) => searchFold(s).contains(q);
    return has(e.name) ||
        e.aliases.any(has) ||
        (!isEnglish && (has(exerciseName(e)) || exerciseAliases(e).any(has)));
  }

  // Foods -------------------------------------------------------------

  String foodName(Food f) => _t('foods', ['foods', f.id, 'name'], f.name);

  /// A portion label ("1 bowl").
  String portion(String english) => _t('foods', ['portions', english], english);

  /// A logged food: the catalog food's name in the app language while the
  /// entry still carries the catalog's English name; otherwise as logged.
  String foodEntryName(FoodEntry e, FoodCatalog? foods) {
    if (isEnglish || e.foodId == null) return e.name;
    final f = foods?.byId(e.foodId!);
    return f != null && f.name == e.name ? foodName(f) : e.name;
  }

  // Training programs -------------------------------------------------

  String programName(TrainingProgram p) =>
      _t('training_programs', [p.id, 'name'], p.name);

  String programAuthor(TrainingProgram p) =>
      _t('training_programs', [p.id, 'author'], p.author);

  String programSummary(TrainingProgram p) =>
      _t('training_programs', [p.id, 'summary'], p.summary);

  List<String> programRules(TrainingProgram p) => isEnglish
      ? p.progressionRules
      : overlay.list(
          'training_programs', [p.id, 'progressionRules'], p.progressionRules);

  /// The name of [p]'s session [s] ("Day A1").
  String sessionName(TrainingProgram p, ProgramSession s) {
    if (isEnglish) return s.name;
    final names = overlay.list('training_programs', [p.id, 'sessions'],
        [for (final x in p.sessions) x.name]);
    final i = p.sessions.indexOf(s);
    if (i >= 0) return names[i];
    final byName = p.sessions.indexWhere((x) => x.name == s.name);
    return byName >= 0 ? names[byName] : s.name;
  }

  /// A program session name stored in a plan or a template, looked up in
  /// [programId]'s sessions, or in every program when it is not known.
  String _storedSessionName(String name, {String? programId}) {
    final all = programs?.programs ?? const <TrainingProgram>[];
    for (final p in all) {
      if (programId != null && p.id != programId) continue;
      for (final s in p.sessions) {
        if (s.name == name) return sessionName(p, s);
      }
    }
    return name;
  }

  // Workouts ----------------------------------------------------------

  static WorkoutTemplate? _starter(String? id) {
    if (id == null) return null;
    for (final t in WorkoutCatalog.defaults) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// A workout's title as stored (template, finished workout, plan): a
  /// starter workout the user hasn't renamed, or a program session
  /// ("GZCLP · Day A1") in the app language; anything else as stored.
  String workoutTitle(String? templateId, String name) {
    if (isEnglish) return name;
    final starter = _starter(templateId);
    if (starter != null && starter.name == name) {
      return _t('workout_catalog', ['templates', starter.id, 'name'], name);
    }
    for (final p in programs?.programs ?? const <TrainingProgram>[]) {
      final prefix = '${p.name} · ';
      if (!name.startsWith(prefix)) continue;
      final session = name.substring(prefix.length);
      for (final s in p.sessions) {
        if (s.name == session) {
          return '${programName(p)} · ${sessionName(p, s)}';
        }
      }
    }
    return name;
  }

  String templateName(WorkoutTemplate t) => workoutTitle(t.id, t.name);

  /// A template's focus ("Upper body"); a program session's focus is the
  /// session name.
  String templateFocus(WorkoutTemplate t) {
    if (isEnglish) return t.focus;
    final starter = _starter(t.id);
    if (starter != null && starter.focus == t.focus) {
      return _t('workout_catalog', ['templates', t.id, 'focus'], t.focus);
    }
    return t.focus;
  }

  String completedTitle(CompletedWorkout w) =>
      workoutTitle(w.templateId, w.name);

  /// A week-plan session's title: a program session (its id starts with
  /// `prog-<program>-`) or a starter workout in the app language.
  String planTitle(PlannedSession s) {
    if (isEnglish) return s.title;
    for (final p in programs?.programs ?? const <TrainingProgram>[]) {
      if (s.id.startsWith(programSessionPrefix(p.id))) {
        return _storedSessionName(s.title, programId: p.id);
      }
    }
    return workoutTitle(s.templateId, s.title);
  }

  // Seed / cloud content ---------------------------------------------

  String _c(String section, String id, String field, String english) {
    if (isEnglish) return english;
    final seed = this.seed;
    if (seed != null) {
      Object? seedEnglish;
      for (final r in seed[section] as List? ?? const []) {
        if (r is Map && r['id'] == id) seedEnglish = r[field];
      }
      if (seedEnglish != english) return english;
    }
    return overlay.text('seed_content', [section, id, field], english);
  }

  Product product(Product p) => isEnglish
      ? p
      : Product(
          id: p.id,
          name: _c('products', p.id, 'name', p.name),
          category: p.category,
          priceCents: p.priceCents,
          currency: p.currency,
          image: p.image,
          word: p.word,
        );

  Program program(Program p) => isEnglish
      ? p
      : Program(
          id: p.id,
          title: _c('programs', p.id, 'title', p.title),
          meta: _c('programs', p.id, 'meta', p.meta),
          level: p.level,
          sport: p.sport,
          image: p.image,
        );

  Article article(Article a) => isEnglish
      ? a
      : Article(
          id: a.id,
          tag: _c('articles', a.id, 'tag', a.tag),
          title: _c('articles', a.id, 'title', a.title),
          body: _c('articles', a.id, 'body', a.body),
          minutes: a.minutes,
        );

  Challenge challenge(Challenge c) => isEnglish
      ? c
      : Challenge(
          id: c.id,
          title: _c('challenges', c.id, 'title', c.title),
          description: _c('challenges', c.id, 'description', c.description),
          dailyTarget: _c('challenges', c.id, 'daily_target', c.dailyTarget),
          days: c.days,
          startsOn: c.startsOn,
          endsOn: c.endsOn,
        );

  Place place(Place p) => isEnglish
      ? p
      : Place(
          id: p.id,
          name: _c('places', p.id, 'name', p.name),
          kind: p.kind,
          type: _c('places', p.id, 'type', p.type),
          lat: p.lat,
          lon: p.lon,
          hours: p.hours == null ? null : _c('places', p.id, 'hours', p.hours!),
          note: p.note == null ? null : _c('places', p.id, 'note', p.note!),
        );
}

/// The bundled seed content, to tell a server edit from the seed's text.
final bundledSeedProvider = FutureProvider<Map<String, dynamic>>(
    (ref) => ref.watch(seedLoaderProvider)());

/// [CatalogText] for the app language. English until the overlay and the
/// catalogs have loaded.
final catalogTextProvider = Provider<CatalogText>((ref) {
  final overlay = ref.watch(catalogOverlayProvider);
  if (overlay.isEmpty) return CatalogText.english;
  return CatalogText(
    overlay,
    exercises: ref.watch(exerciseCatalogProvider).valueOrNull,
    programs: ref.watch(programCatalogProvider).valueOrNull,
    // Until the seed has loaded nothing matches it: English.
    seed: ref.watch(bundledSeedProvider).valueOrNull ?? const {},
  );
});
