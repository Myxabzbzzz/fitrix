// Screenshot tour harness: pumps the whole app (real router, real theme,
// real Inter / Exo 2 fonts) with seeded data and writes PNGs of each screen.
//
// Not part of the normal `flutter test` run: the entry file is not named
// `*_test.dart`, so it is only run when passed explicitly (see tour.dart).
import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/data/checkin_store.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/football/data/match_store.dart';
import 'package:fitrix/features/health/data/health_daily_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/map/data/location.dart' as maploc;
import 'package:fitrix/features/map/data/routing_service.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/data/ski_math.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/run_voice.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/main.dart';

import '../support/fake_auth.dart';
import '../support/fake_health_source.dart';

/// Where the PNGs go. Override with --dart-define=TOUR_OUT=/some/dir.
const tourOut = String.fromEnvironment('TOUR_OUT',
    defaultValue:
        '/private/tmp/claude-501/-Users-myxabzbzzzz--------fitrix/3181f353-a107-40c3-9418-ab2c1542d488/scratchpad/tour');

/// A Tuesday morning; the week started on Monday the 19th.
final tourNow = DateTime(2026, 10, 20, 10, 30);

// ---------------------------------------------------------------- fonts

bool _fontsLoaded = false;

/// Loads the app's real fonts (Inter, Exo 2 from assets) plus Material
/// icons and Roboto (named by Material typography), so screenshots show
/// real glyphs instead of the test font's boxes. Call once per test.
Future<void> loadAppFonts(WidgetTester t) async {
  if (_fontsLoaded) return;
  await t.runAsync(() async {
    Future<ByteData> file(String path) async =>
        ByteData.view(Uint8List.fromList(File(path).readAsBytesSync()).buffer);

    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();

    final exo = FontLoader('Exo 2');
    for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
      exo.addFont(rootBundle.load('assets/fonts/Exo2-$w.ttf'));
    }
    await exo.load();

    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();

    // Material typography names Roboto explicitly in some places.
    final sdk = Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    final roboto = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold']) {
      final f = File('$sdk/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
      if (f.existsSync()) roboto.addFont(file(f.path));
    }
    await roboto.load();

    // Text whose style names no family at all (e.g. a theme textStyle
    // without fontFamily) still renders in the test font, as boxes: on a
    // phone it would be the system font, not Inter. The boxes are kept on
    // purpose, they mark exactly those places.
  });
  _fontsLoaded = true;
}

// ---------------------------------------------------------------- matrix

class TourConfig {
  const TourConfig(this.id,
      {required this.size,
      required this.dpr,
      this.dark = false,
      this.lang = 'ru',
      this.textScale = 1});
  final String id;
  final Size size;
  final double dpr;
  final bool dark;
  final String lang;
  final double textScale;
}

const pro = Size(393, 852);
const se = Size(375, 667);

const proRuLight = TourConfig('pro-ru-light', size: pro, dpr: 3);
const proRuDark = TourConfig('pro-ru-dark', size: pro, dpr: 3, dark: true);
const seRuLight = TourConfig('se-ru-light', size: se, dpr: 2);
const seRuScaled = TourConfig('se-ru-x1.3', size: se, dpr: 2, textScale: 1.3);
const proEnLight = TourConfig('pro-en-light', size: pro, dpr: 3, lang: 'en');
const proEnDark =
    TourConfig('pro-en-dark', size: pro, dpr: 3, lang: 'en', dark: true);

// ---------------------------------------------------------------- fakes

class SilentSpeaker implements Speaker {
  @override
  Future<Set<String>> languages() async => {'en', 'ru', 'uz', 'es'};
  @override
  Future<void> prepare() async {}
  @override
  Future<bool> speak(String text, {required String language}) async => true;
  @override
  Future<void> stop() async {}
}

class TourLocationSource implements LocationSource {
  StreamController<RunPoint>? _c;
  void emit(RunPoint p) => _c?.add(p);
  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;
  @override
  Future<bool> reducedAccuracy() async => false;
  @override
  Stream<RunPoint> start() =>
      (_c = StreamController<RunPoint>(sync: true)).stream;
  @override
  Future<void> stop() async {
    await _c?.close();
    _c = null;
  }
}

class _MapLocation implements maploc.LocationSource {
  @override
  Future<LatLng?> current() async => const LatLng(41.3104, 69.2789);
}

/// One pixel of OSM's land colour (#F2EFE9): maps look like a real (empty)
/// map without the network. Note OSM tiles stay light in dark mode too.
final Uint8List _blankPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP49P4lAAWhAstl7N0JAAAAAElFTkSuQmCC');

class BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_blankPng);
}

class SilentFelixApi extends ChatApiService {
  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    Map<String, Object>? context,
    List<String>? images,
    void Function(ChatAction action)? onAction,
  }) async* {
    yield 'OK';
  }
}

class _NoRouting implements RoutingService {
  @override
  Future<RouteSet> plan(LatLng from, LatLng to) async =>
      const RouteSet(covered: false, plans: {});
}

// ---------------------------------------------------------------- catalogs

class Catalogs {
  static ExerciseCatalog? exercises;
  static FoodCatalog? foods;
  static ProgramCatalog? programs;
  static Map<String, dynamic>? seed;
  static final overlays = <String, CatalogOverlay>{};

  static Future<void> load() async {
    exercises ??= await ExerciseCatalog.load(rootBundle);
    foods ??= await FoodCatalog.load(rootBundle);
    programs ??= await ProgramCatalog.load(rootBundle);
    seed ??= await loadBundledSeed();
    // Translations too: an asset read started inside the test's fake async
    // never finishes, which left every screen in English.
    for (final l in const ['en', 'ru', 'uz', 'es']) {
      overlays[l] ??= await CatalogOverlay.load(rootBundle, l);
    }
  }
}

// ---------------------------------------------------------------- seed

/// What a scene starts from. Defaults: a signed-in, onboarded user with a
/// few weeks of history, a plan for this week, today's check-in, food and
/// Health data.
class Seed {
  const Seed({
    this.onboarded = true,
    this.profile = true,
    this.history = true,
    this.plan = true,
    this.planToday = true,
    this.checkIn = true,
    this.food = true,
    this.weights = true,
    this.health = true,
    this.sportHistory = true,
    this.chats = true,
    this.extraPrefs = const {},
  });

  final bool onboarded,
      profile,
      history,
      plan,
      planToday,
      checkIn,
      food,
      weights,
      health,
      sportHistory,
      chats;
  final Map<String, Object> extraPrefs;

  static const empty = Seed(
    history: false,
    plan: false,
    checkIn: false,
    food: false,
    weights: false,
    health: false,
    sportHistory: false,
    chats: false,
  );
}

String _dk(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _day(int back) =>
    DateTime(tourNow.year, tourNow.month, tourNow.day - back);

Map<String, Object> _basePrefs(TourConfig c, Seed s) => {
      AppConstants.keyOnboardingComplete: s.onboarded,
      'language': c.lang,
      'theme_mode': c.dark ? 'dark' : 'light',
      if (s.profile) ...{
        AppConstants.keyUserName: c.lang == 'ru' ? 'Алексей' : 'Alex',
        AppConstants.keyUserSurname: c.lang == 'ru' ? 'Смирнов' : 'Smith',
        AppConstants.keyUserAge: '29',
        AppConstants.keyUserWeight: '78',
        AppConstants.keyUserHeight: '181',
        AppConstants.keyUserGoal:
            c.lang == 'ru' ? 'Набрать мышечную массу' : 'Build muscle',
        AppConstants.keyUserExperience: c.lang == 'ru' ? 'Средний' : 'Medium',
        AppConstants.keyUserSports: ['Gym', 'Running', 'Cycling', 'Football'],
        AppConstants.keyUserEmail: 'alex@example.com',
        performanceProfileKey: jsonEncode({
          'sex': 'male',
          'restingHr': 54,
          'maxHr': 190,
        }),
      },
      if (s.health)
        'health_connection_v1': jsonEncode({
          'connected': true,
          'writeWorkouts': true,
          'lastReadAt': tourNow.toIso8601String(),
        }),
      if (s.chats) ..._chatPrefs(c),
      ...s.extraPrefs,
    };

ChatMessage _m(int n, String text, MessageSender who,
        {Map<String, dynamic>? action, bool applied = false}) =>
    ChatMessage(
      id: 'msg-$n',
      content: text,
      sender: who,
      timestamp: tourNow.subtract(Duration(minutes: 40 - n * 3)),
      action: action == null ? null : ChatAction.tryParse(action),
      actionApplied: applied,
    );

Map<String, Object> _chatPrefs(TourConfig c) {
  final ru = c.lang == 'ru';
  const a = MessageSender.assistant, u = MessageSender.user;
  final gym = [
    _m(
        0,
        ru
            ? 'Привет! Я Феликс, твой тренер по залу. Чем помочь?'
            : 'Hi! I am Felix, your gym coach. How can I help?',
        a),
    _m(
        1,
        ru
            ? 'Составь мне программу на 3 дня в неделю, хочу набрать массу'
            : 'Make me a 3-day plan, I want to build muscle',
        u),
    _m(
        2,
        ru
            ? 'Отличная цель. Вот сплит верх/низ: два дня на верх тела и один на ноги. Начни с умеренных весов и добавляй 2,5 кг, когда все подходы выполнены.'
            : 'Great goal. Here is an upper/lower split: two upper-body days and one leg day. Start moderate and add 2.5 kg once all sets are done.',
        a,
        action: {
          'type': 'workout_plan',
          'sport': 'gym',
          'templates': [
            {
              'name': ru ? 'Верх тела' : 'Upper body',
              'exercises': [
                {'name': 'Bench press', 'sets': 4, 'reps': 8, 'kg': 72.5},
                {'name': 'Barbell row', 'sets': 4, 'reps': 10, 'kg': 60},
                {'name': 'Overhead press', 'sets': 3, 'reps': 10, 'kg': 40},
              ],
            },
            {
              'name': ru ? 'Ноги' : 'Legs',
              'exercises': [
                {'name': 'Squat', 'sets': 5, 'reps': 5, 'kg': 95},
                {'name': 'Romanian deadlift', 'sets': 3, 'reps': 10, 'kg': 70},
              ],
            },
          ],
        }),
    _m(3, ru ? 'Я похудел на 1,5 кг за месяц' : 'I lost 1.5 kg this month', u),
    _m(4, ru ? 'Обновлю вес в профиле.' : 'I will update your weight.', a,
        action: {'type': 'weight', 'mode': 'delta', 'kg': -1.5}, applied: true),
  ];
  final food = [
    _m(
        0,
        ru ? 'Привет! Я помогу с питанием.' : 'Hi! I can help with nutrition.',
        a),
    _m(
        1,
        ru
            ? 'На обед съел куриную грудку 200 г и рис 150 г'
            : 'Lunch: chicken breast 200 g and rice 150 g',
        u),
    _m(2, ru ? 'Записал примерно так:' : 'Logged roughly like this:', a,
        action: {
          'type': 'food_log',
          'slot': 'lunch',
          'items': [
            {
              'name': ru ? 'куриная грудка' : 'chicken breast',
              'grams': 200,
              'kcal': 330,
              'protein': 62,
              'carbs': 0,
              'fat': 7.2
            },
            {
              'name': ru ? 'рис отварной' : 'boiled rice',
              'grams': 150,
              'kcal': 195,
              'protein': 4,
              'carbs': 42,
              'fat': 0.5
            },
          ],
        }),
    _m(3, ru ? 'А что на ужин?' : 'And for dinner?', u),
    _m(
        4,
        ru
            ? 'Вот вариант на остаток дня:'
            : 'Here is an idea for the rest of the day:',
        a,
        action: {
          'type': 'meal_plan',
          'meals': [
            {
              'name': ru ? 'Ужин' : 'Dinner',
              'items': ru
                  ? 'Лосось, киноа, овощи на пару'
                  : 'Salmon, quinoa, steamed vegetables',
              'kcal': 640
            },
            {
              'name': ru ? 'Перекус' : 'Snack',
              'items': ru ? 'Творог 5%, ягоды' : 'Cottage cheese, berries',
              'kcal': 240
            },
          ],
        }),
  ];
  final app = [
    _m(0, lookupAppLocalizations(Locale(c.lang)).assistantGreeting, a),
    _m(
        1,
        ru ? 'Как подключить Apple Health?' : 'How do I connect Apple Health?',
        u),
    _m(
        2,
        ru
            ? 'Открой Профиль → Подключённые приложения и нажми «Подключить».'
            : 'Open Profile → Connected apps and tap Connect.',
        a),
  ];
  return {
    '${AppConstants.keyChatHistory}_gym': ChatMessage.encodeMessages(gym),
    '${AppConstants.keyChatHistory}_nutrition':
        ChatMessage.encodeMessages(food),
    AppConstants.keyChatHistory: ChatMessage.encodeMessages(app),
  };
}

CompletedWorkout _gym(WorkoutTemplate t, DateTime at, {double bump = 0}) {
  final ex = [
    for (final e in t.exercises)
      Exercise(name: e.name, sets: [
        for (final s in e.sets)
          WorkoutSet(
              previousKg: s.kg,
              previousReps: s.reps,
              kg: s.kg == 0 ? 0 : s.kg + bump,
              reps: s.reps,
              done: true),
      ]),
  ];
  return CompletedWorkout(
    id: 'gym-${t.id}-${at.millisecondsSinceEpoch}',
    templateId: t.id,
    name: t.name,
    sport: t.sport,
    startedAt: at,
    finishedAt: at.add(const Duration(minutes: 68)),
    exercises: ex,
    sessionRpe: 7,
  );
}

const _mPerDeg = 111319.49;

List<List<double>> tourRoute(int n, {double wiggle = 0.0004}) => [
      for (var i = 0; i < n; i++)
        [
          41.3104 + i * 0.0006 + sin(i / 3) * wiggle,
          69.2789 + i * 0.0005 + cos(i / 4) * wiggle,
        ]
    ];

RunDetails tourRun(DateTime at, double meters, Duration moving) => RunDetails(
      startedAt: at,
      moving: moving,
      elapsed: moving + const Duration(minutes: 2),
      pauses: 1,
      meters: meters,
      elevationGain: 42,
      splits: [
        for (var k = 1; k <= meters ~/ 1000; k++)
          RunSplit(
              km: k,
              meters: 1000,
              time: Duration(
                  seconds: moving.inSeconds * 1000 ~/ meters + (k % 3) * 7)),
        if (meters % 1000 > 0)
          RunSplit(
              km: meters ~/ 1000,
              meters: meters % 1000,
              time: Duration(
                  seconds:
                      (moving.inSeconds * (meters % 1000) / meters).round())),
      ],
      route: tourRoute(40),
      kind: ActivityKind.run,
      rpe: 6,
    );

RunDetails tourRide(DateTime at, {bool indoor = false}) => RunDetails(
      startedAt: at,
      moving: const Duration(minutes: 52, seconds: 10),
      elapsed: const Duration(minutes: 56),
      pauses: 1,
      meters: indoor ? 21400 : 23750,
      elevationGain: indoor ? null : 185,
      elevationLoss: indoor ? null : 176,
      splits: const [
        RunSplit(km: 5, meters: 5000, time: Duration(seconds: 640)),
        RunSplit(km: 10, meters: 5000, time: Duration(seconds: 610)),
        RunSplit(km: 15, meters: 5000, time: Duration(seconds: 668)),
        RunSplit(km: 20, meters: 5000, time: Duration(seconds: 655)),
        RunSplit(km: 20, meters: 3750, time: Duration(seconds: 557)),
      ],
      route: indoor ? const [] : tourRoute(60, wiggle: 0.002),
      kind: ActivityKind.ride,
      maxSpeed: 13.4,
      indoor: indoor,
      avgPowerW: indoor ? 182 : null,
      rpe: 7,
    );

SkiDescent _descent(
        DateTime t0, int n, double meters, double vertical, int from, int to) =>
    SkiDescent(
      start: t0.add(Duration(minutes: n * 14)),
      end: t0.add(Duration(minutes: n * 14, seconds: 140 + n * 25)),
      meters: meters,
      vertical: vertical,
      maxSpeed: 14.0 + n * 0.8,
      avgSpeed: 7.2,
      routeFrom: from,
      routeTo: to,
    );

RunDetails tourSki(DateTime at) => RunDetails(
      startedAt: at,
      moving: const Duration(hours: 1, minutes: 48),
      elapsed: const Duration(hours: 4, minutes: 12),
      pauses: 0,
      meters: 9850,
      splits: const [],
      route: tourRoute(36, wiggle: 0.003),
      kind: ActivityKind.ski,
      rpe: 6,
      ski: SkiDay(
        descents: [
          _descent(at, 1, 1650, 320, 0, 6),
          _descent(at, 2, 2100, 410, 6, 12),
          _descent(at, 3, 1800, 350, 12, 18),
          _descent(at, 4, 2300, 455, 18, 26),
          _descent(at, 5, 2000, 380, 26, 35),
        ],
        lifts: 5,
        liftTime: const Duration(minutes: 62),
      ),
    );

/// Applies [s] to the container's stores (before the app is pumped).
Future<void> applySeed(ProviderContainer c, SharedPreferences prefs,
    TourConfig cfg, Seed s) async {
  final defaults = WorkoutCatalog.defaults;
  final history = c.read(workoutHistoryProvider.notifier);
  if (s.history) {
    var bump = 0.0;
    for (final back in [26, 23, 21, 19, 16, 14, 12, 9, 7, 5, 3, 1]) {
      final t = defaults[back % 3];
      history.add(
          _gym(t, _day(back).add(const Duration(hours: 18)), bump: bump),
          toHealth: false);
      bump += 1.25;
    }
    history.add(_gym(defaults[3], _day(4).add(const Duration(hours: 8))),
        toHealth: false);
  }
  if (s.sportHistory) {
    final runs = c.read(runsProvider.notifier);
    void save(String id, Sport sport, String name, RunDetails d,
        {String templateId = 'free'}) {
      history.add(
          CompletedWorkout(
            id: id,
            templateId: templateId,
            name: name,
            sport: sport,
            startedAt: d.startedAt,
            finishedAt: d.startedAt.add(d.elapsed),
            exercises: const [],
            sessionRpe: d.rpe,
          ),
          toHealth: false);
      runs.put(id, d);
    }

    final ru = cfg.lang == 'ru';
    save(
        'run-1',
        Sport.running,
        ru ? 'Утренняя пробежка' : 'Morning run',
        tourRun(_day(0).add(const Duration(hours: 7)), 6420,
            const Duration(minutes: 33, seconds: 18)));
    save(
        'run-2',
        Sport.running,
        ru ? 'Пробежка' : 'Run',
        tourRun(_day(2).add(const Duration(hours: 7)), 10050,
            const Duration(minutes: 54, seconds: 41)));
    save(
        'run-3',
        Sport.running,
        ru ? 'Лёгкий бег' : 'Easy run',
        tourRun(_day(6).add(const Duration(hours: 19)), 4200,
            const Duration(minutes: 25, seconds: 3)));
    save('ride-1', Sport.cycling, ru ? 'Вечерний заезд' : 'Evening ride',
        tourRide(_day(1).add(const Duration(hours: 18))));
    save('ride-2', Sport.cycling, ru ? 'Велотренажёр' : 'Indoor ride',
        tourRide(_day(5).add(const Duration(hours: 19)), indoor: true));
    save('ski-1', Sport.winterSports, ru ? 'Чимган' : 'Chimgan',
        tourSki(DateTime(2026, 2, 14, 10)));
    // A football match.
    final match = MatchLog(
      type: FootballType.match,
      date: _day(3).add(const Duration(hours: 20)),
      format: '7x7',
      minutes: 70,
      position: 'CM',
      rpe: 8,
      goalsFor: 5,
      goalsAgainst: 3,
      goals: 1,
      assists: 2,
      note: ru ? 'Хорошо держали мяч' : 'Kept the ball well',
      templateId: footballLogTemplateId,
    );
    history.add(
        CompletedWorkout(
          id: 'fb-1',
          templateId: footballLogTemplateId,
          name: ru ? 'Матч 7×7' : 'Match 7×7',
          sport: Sport.football,
          startedAt: match.date,
          finishedAt: match.date.add(const Duration(minutes: 70)),
          exercises: const [],
          sessionRpe: 8,
        ),
        toHealth: false);
    c.read(matchesProvider.notifier).put('fb-1', match);
  }
  if (s.plan) {
    final monday = weekStartOf(tourNow);
    final ru = cfg.lang == 'ru';
    await c.read(weekPlanProvider.notifier).addAll([
      PlannedSession(
          id: 'p-mon',
          day: monday,
          sport: Sport.gym,
          title: defaults[1].name,
          templateId: defaults[1].id,
          minutes: 70,
          intensity: Intensity.normal),
      if (s.planToday)
        PlannedSession(
            id: 'p-tue',
            day: addDays(monday, 1),
            sport: Sport.gym,
            title: defaults[0].name,
            templateId: defaults[0].id,
            minutes: 75,
            intensity: Intensity.hard),
      PlannedSession(
          id: 'p-wed',
          day: addDays(monday, 2),
          sport: Sport.running,
          title: ru ? 'Лёгкий бег 6 км' : 'Easy run 6 km',
          minutes: 40,
          intensity: Intensity.easy),
      PlannedSession(
          id: 'p-thu',
          day: addDays(monday, 3),
          sport: Sport.gym,
          title: defaults[2].name,
          templateId: defaults[2].id,
          minutes: 70,
          intensity: Intensity.hard),
      PlannedSession(
          id: 'p-sat',
          day: addDays(monday, 5),
          sport: Sport.football,
          title: ru ? 'Футбол с друзьями' : 'Football with friends',
          minutes: 90,
          intensity: Intensity.normal),
      PlannedSession(
          id: 'p-sun',
          day: addDays(monday, 6),
          sport: Sport.cycling,
          title: ru ? 'Длинный заезд' : 'Long ride',
          minutes: 120,
          intensity: Intensity.easy),
    ]);
  }
  if (s.food) {
    final foods = Catalogs.foods!;
    final log = c.read(foodLogProvider.notifier);
    var n = 0;
    Future<void> add(String id, int grams, MealSlot slot, int hour) async {
      final f = foods.byId(id);
      if (f == null) return;
      await log.add(FoodEntry.fromFood(f,
          grams: grams,
          slot: slot,
          at: _day(0).add(Duration(hours: hour)),
          id: 'food-${n++}'));
    }

    await add('egg_boiled', 120, MealSlot.breakfast, 8);
    await add('greek_yogurt', 180, MealSlot.breakfast, 8);
    await add('chicken_breast', 200, MealSlot.lunch, 13);
    await add('salmon', 150, MealSlot.lunch, 13);
    await add('cottage_cheese', 150, MealSlot.snack, 16);
  }
  if (s.weights) {
    final store = c.read(bodyWeightProvider.notifier);
    for (var w = 0; w < 10; w++) {
      await store.log(WeighIn(
          at: _day(63 - w * 7).add(const Duration(hours: 7)),
          kg: 81.4 - w * 0.38 + (w.isEven ? 0.2 : -0.1)));
    }
  }
}

/// Writes data that must be in prefs before the providers first read them.
Future<void> preSeed(SharedPreferences prefs, Seed s) async {
  if (s.health) {
    await HealthDailyStore(prefs, now: () => tourNow).putAll({
      for (var i = 0; i <= 7; i++)
        _dk(_day(i)): HealthDay(
          sleep: Duration(minutes: 7 * 60 + 12 - i * 9),
          sleepSource: 'Apple Watch',
          restingHr: i == 0 ? 57 : 53 + i % 3,
          hrv: i == 0 ? 41 : 47 + i % 4,
          hrvKind: HrvKind.sdnn,
          steps: i == 0 ? 6240 : 8200 + (i * 913) % 4100,
        ),
    });
  }
  if (s.checkIn) {
    await CheckInStore(prefs, now: () => tourNow).save(CheckIn(
      at: tourNow.subtract(const Duration(hours: 2, minutes: 50)),
      sleep: const Duration(hours: 7, minutes: 12),
      quality: SleepQuality.good,
      soreness: Soreness.light,
      sore: const {BodyArea.legs},
      energy: Level3.ok,
      stress: Level3.low,
    ));
  }
}

// ---------------------------------------------------------------- rig

class TourRig {
  TourRig(this.t, this.cfg, this.container, this.router, this.source);
  final WidgetTester t;
  final TourConfig cfg;
  final ProviderContainer container;
  final GoRouter router;
  final TourLocationSource source;
  DateTime now = tourNow;

  String ru(String ruText, String enText) => cfg.lang == 'ru' ? ruText : enText;

  /// Element under the top route, for showing sheets.
  BuildContext get context => t.element(find.byType(Scaffold).last);

  Future<void> go(String location) async {
    router.go(location);
    await settle();
  }

  Future<void> push(String location) async {
    unawaited(router.push(location));
    await settle();
  }

  /// Pumps until no frame is scheduled (max ~3 s), without failing on
  /// endless animations.
  Future<void> settle({int maxFrames = 30}) async {
    // Real time for asset images to decode (they load outside fake async).
    for (var round = 0; round < 3; round++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < maxFrames; i++) {
      await t.pump(const Duration(milliseconds: 100));
      if (!t.binding.hasScheduledFrame) break;
    }
  }

  Future<void> tapKey(String key) async {
    final f = find.byKey(ValueKey(key));
    await t.ensureVisible(f.first);
    await t.pump();
    await t.tap(f.first);
    await settle();
  }

  Future<void> tapText(String text) async {
    final f = find.text(text);
    await t.ensureVisible(f.first);
    await t.pump();
    await t.tap(f.first);
    await settle();
  }

  void fix(int sec, double eastM, double northM, [double? alt]) {
    now = tourNow.add(Duration(seconds: sec));
    source.emit(RunPoint(
        lat: 41.3104 + northM / _mPerDeg,
        lng: 69.2789 + eastM / (_mPerDeg * cos(41 * pi / 180)),
        alt: alt,
        accuracy: 5,
        at: now));
  }

  RunRecorder get recorder => container.read(runRecorderProvider.notifier);
}

final _log = <String>[];

Future<TourRig> pumpTour(WidgetTester t, TourConfig cfg,
    {Seed seed = const Seed(), String? initial, bool auth = false}) async {
  await loadAppFonts(t);
  await t.runAsync(Catalogs.load);
  t.view.physicalSize = cfg.size * cfg.dpr;
  t.view.devicePixelRatio = cfg.dpr;
  t.view.padding = FakeViewPadding(
      top: (cfg.size == pro ? 59 : 20) * cfg.dpr,
      bottom: (cfg.size == pro ? 34 : 0) * cfg.dpr);
  t.view.viewPadding = t.view.padding;
  t.platformDispatcher.textScaleFactorTestValue = cfg.textScale;
  t.platformDispatcher.platformBrightnessTestValue =
      cfg.dark ? Brightness.dark : Brightness.light;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);

  SharedPreferences.setMockInitialValues(_basePrefs(cfg, seed));
  final prefs = await SharedPreferences.getInstance();
  await preSeed(prefs, seed);
  final session = AppSession(prefs);
  final source = TourLocationSource();
  late TourRig rig;
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appSessionProvider.overrideWithValue(session),
    clockProvider.overrideWithValue(() => rig.now),
    locationSourceProvider.overrideWithValue(source),
    speakerProvider.overrideWithValue(SilentSpeaker()),
    mapTileProviderProvider.overrideWithValue(BlankTiles()),
    maploc.locationSourceProvider.overrideWithValue(_MapLocation()),
    routingServiceProvider.overrideWithValue(_NoRouting()),
    healthSourceProvider.overrideWithValue(FakeHealthSource()),
    chatApiServiceProvider.overrideWithValue(SilentFelixApi()),
    exerciseCatalogProvider.overrideWith((ref) async => Catalogs.exercises!),
    foodCatalogProvider.overrideWith((ref) async => Catalogs.foods!),
    programCatalogProvider.overrideWith((ref) async => Catalogs.programs!),
    seedLoaderProvider.overrideWithValue(() async => Catalogs.seed!),
    catalogOverlayLoaderProvider.overrideWith((ref) async =>
        Catalogs.overlays[ref.watch(selectedLanguageProvider)] ??
        CatalogOverlay.empty),
    if (auth) authGatewayProvider.overrideWithValue(FakeAuthGateway()),
  ]);
  addTearDown(container.dispose);
  final router = AppRouter.create(session);
  rig = TourRig(t, cfg, container, router, source);
  await applySeed(container, prefs, cfg, seed);
  await t.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: FitrixApp(router: router),
  ));
  await rig.settle();
  if (initial != null) await rig.go(initial);
  return rig;
}

// ---------------------------------------------------------------- capture

/// Writes the whole screen to `<tourOut>/<cfg.id>/<name>.png`. Layout errors
/// (overflows) thrown so far are logged to `<tourOut>/errors.log`.
Future<void> shot(TourRig r, String name) async {
  final t = r.t;
  await t.pump();
  final dir = Directory('$tourOut/${r.cfg.id}')..createSync(recursive: true);
  final path = '${dir.path}/$name.png';
  final view = t.binding.renderViews.first;
  await t.runAsync(() async {
    final layer = view.debugLayer! as OffsetLayer;
    final image = await layer.toImage(view.paintBounds);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  Object? e;
  final errors = <String>[];
  while ((e = t.takeException()) != null) {
    errors.add(e.toString().split('\n').take(6).join(' | '));
  }
  if (errors.isNotEmpty) {
    final line = '${r.cfg.id}/$name: ${errors.join(' || ')}';
    _log.add(line);
    File('$tourOut/errors.log')
        .writeAsStringSync('$line\n', mode: FileMode.append);
  }
}

/// The biggest vertical scrollable that is on screen in the top route.
ScrollableState? mainScrollable(WidgetTester t) {
  ScrollableState? best;
  var bestArea = 0.0;
  for (final e in find.byType(Scrollable).hitTestable().evaluate()) {
    final s = (e as StatefulElement).state as ScrollableState;
    if (s.position.axis != Axis.vertical) continue;
    if (s.position.maxScrollExtent <= 0) continue;
    final box = e.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    final area = box.size.width * box.size.height;
    if (area > bestArea) {
      bestArea = area;
      best = s;
    }
  }
  return best;
}

/// [shot] of the top, then of each further screenful of the main list.
Future<void> shotPages(TourRig r, String name, {int maxPages = 5}) async {
  await shot(r, '${name}_1');
  final s = mainScrollable(r.t);
  if (s == null) return;
  final pos = s.position;
  for (var p = 2; p <= maxPages; p++) {
    if (pos.pixels >= pos.maxScrollExtent - 1) break;
    pos.jumpTo(
        min(pos.maxScrollExtent, pos.pixels + pos.viewportDimension * 0.8));
    await r.settle();
    await shot(r, '${name}_$p');
  }
}
