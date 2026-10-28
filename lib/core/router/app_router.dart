import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/auth/data/auth_gateway.dart';
import 'package:fitrix/features/intro/presentation/screens/intro_screen.dart';
import 'package:fitrix/features/language/presentation/screens/language_screen.dart';
import 'package:fitrix/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/about_me_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:fitrix/features/chat/presentation/screens/chat_screen.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_all_chats_screen.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_hub_screen.dart';
import 'package:fitrix/features/transition/presentation/screens/chat_transition_screen.dart';
import 'package:fitrix/features/checkin/presentation/screens/recovery_screen.dart';
import 'package:fitrix/features/plan/presentation/screens/week_plan_screen.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/connected_apps_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/hr_zones_screen.dart';
import 'package:fitrix/features/shell/presentation/fading_branch_container.dart';
import 'package:fitrix/features/shell/presentation/main_shell.dart';
import 'package:fitrix/features/exercises/presentation/add_exercise_screen.dart';
import 'package:fitrix/features/exercises/presentation/exercise_detail_screen.dart';
import 'package:fitrix/features/exercises/presentation/exercise_library_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/screens/my_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/screens/workout_complete_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/body_weight_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/lift_detail_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/progress_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/records_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/training_load_screen.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/presentation/screens/add_food_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/food_detail_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/micros_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/targets_screen.dart';
import 'package:fitrix/features/content/presentation/article_screen.dart';
import 'package:fitrix/features/content/presentation/discover_screen.dart';
import 'package:fitrix/features/shop/presentation/shop_screen.dart';
import 'package:fitrix/features/map/presentation/map_screen.dart';
import 'package:fitrix/features/cycling/presentation/cycling_screen.dart';
import 'package:fitrix/features/skiing/presentation/skiing_screen.dart';
import 'package:fitrix/features/football/presentation/football_screen.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';
import 'package:fitrix/features/running/presentation/screens/run_summary_screen.dart';
import 'package:fitrix/features/running/presentation/screens/running_screen.dart';
import 'package:fitrix/features/programs/presentation/screens/program_detail_screen.dart';
import 'package:fitrix/features/programs/presentation/screens/program_progress_screen.dart';
import 'package:fitrix/features/programs/presentation/screens/programs_screen.dart';
import 'package:fitrix/features/profile/presentation/widgets/about_me_guard.dart';

class AppRouter {
  // Onboarding
  static const String intro = '/';
  static const String language = '/language';
  static const String signIn = '/sign-in';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String transition = '/transition';

  // Runs (full screen, above the tab bar)
  static const String liveRun = '/run/live';

  /// A saved run; [justFinished] opens it with the rating and Save.
  static String runSummary(String id, {bool justFinished = false}) =>
      '/run/$id${justFinished ? '?new=1' : ''}';

  // Main app (tab bar)
  static const String discover = '/discover';
  static const String shop = '/shop';
  static const String home = '/home';
  static const String felix = '/felix';
  static const String felixAll = '/felix/all';
  static String felixChat(AssistantTopic t) => '/felix/chat/${t.id}';
  static const String me = '/me';
  static const String aboutMe = '/me/about';
  static const String hrZones = '/me/zones';
  static const String editProfile = '/me/edit';
  static const String connectedApps = '/me/apps';

  // Home sections
  static const String workouts = '/home/workouts';
  static const String workoutComplete = '/home/workouts/complete';
  static const String exerciseLibrary = '/home/workouts/exercises';
  static const String addExercise = '/home/workouts/exercises/add';
  static const String programs = '/home/programs';
  static const String programsActive = '/home/programs/active';
  static String program(String id) => '/home/programs/$id';
  static const String progress = '/home/progress';
  static const String progressLoad = '/home/progress/load';
  static const String progressRecords = '/home/progress/records';
  static const String progressWeight = '/home/progress/weight';
  static const String nutrition = '/home/nutrition';
  static const String nutritionAdd = '/home/nutrition/add';
  static const String nutritionMicros = '/home/nutrition/micros';
  static const String nutritionTargets = '/home/nutrition/targets';
  static const String fitrixMap = '/home/map';
  static const String recovery = '/home/checkin/recovery';
  static const String weekPlan = '/home/plan';

  static String article(String id) => '$discover/article/$id';

  /// The add-food screen for [slot] (breakfast, lunch, dinner or snack).
  static String addFood(MealSlot slot) => '$nutritionAdd?slot=${slot.name}';

  static String foodDetail(String id, MealSlot slot) =>
      '$nutrition/food/$id?slot=${slot.name}';

  static String exercise(String id) => '$exerciseLibrary/$id';

  /// The add-exercise picker for the live log; [replace] swaps the exercise
  /// at [index] instead of adding.
  static String addExerciseTo({bool replace = false, int index = 0}) =>
      '$addExercise?mode=${replace ? 'replace' : 'add'}&index=$index';

  /// The detail screen of one lift; [name] is the exercise name.
  static String progressLift(String name) =>
      '$progress/lift/${Uri.encodeComponent(name)}';

  static String sportWorkouts(Sport sport) => '$workouts/${sport.name}';

  static const _onboardingRoutes = {
    intro,
    language,
    signIn,
    profile,
    chat,
    transition,
  };

  /// Onboarding steps that need an account when Supabase is available.
  static const _signedInOnboardingRoutes = {profile, chat, transition};

  /// Where navigation to [location] should go instead, or null to allow it.
  ///
  /// [authEnabled] is false in local-only mode (no Supabase): then only
  /// "onboarded users skip onboarding" applies, as before accounts existed.
  /// [signedIn] means a session exists for the account whose data is on
  /// this device.
  static String? redirectFor({
    required String location,
    required bool onboardingComplete,
    required bool authEnabled,
    required bool signedIn,
  }) {
    if (authEnabled && !signedIn) {
      // Signed out elsewhere or session revoked: sign in again. The local
      // data stays if the same account comes back.
      if (onboardingComplete) return location == signIn ? null : signIn;
      if (_signedInOnboardingRoutes.contains(location)) return signIn;
      return null;
    }
    // Once onboarding is done, every launch (and any stray link back into
    // onboarding) lands on Home instead.
    if (onboardingComplete && _onboardingRoutes.contains(location)) {
      return home;
    }
    return null;
  }

  /// The app's router; created once in `main()` via [create].
  static late GoRouter router;

  /// [auth] is null in local-only mode.
  static GoRouter create(AppSession session, {AuthGateway? auth}) =>
      router = GoRouter(
        initialLocation: intro,
        refreshListenable:
            auth == null ? session : Listenable.merge([session, auth]),
        redirect: (context, state) => redirectFor(
          location: state.matchedLocation,
          onboardingComplete: session.onboardingComplete,
          authEnabled: auth != null,
          signedIn: auth != null &&
              auth.userId != null &&
              auth.userId == session.accountUserId,
        ),
        routes: [
          GoRoute(
            path: intro,
            name: 'intro',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const IntroScreen(),
            ),
          ),
          GoRoute(
            path: language,
            name: 'language',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const LanguageScreen(),
            ),
          ),
          GoRoute(
            path: signIn,
            name: 'signIn',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SignInScreen(),
            ),
          ),
          GoRoute(
            path: profile,
            name: 'profile',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: chat,
            name: 'chat',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ChatScreen(),
            ),
          ),
          GoRoute(
            path: transition,
            name: 'transition',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatTransitionScreen(),
            ),
          ),
          // Above the shell: no tab bar. 'live' before ':id'.
          GoRoute(
            path: liveRun,
            name: 'liveRun',
            // A modal: slides up, and slides back down when closed with
            // its chevron-down.
            pageBuilder: (context, state) => slideUpPage(
              context,
              state,
              const LiveRunScreen(),
            ),
          ),
          GoRoute(
            path: '/run/:id',
            name: 'runSummary',
            builder: (context, state) => RunSummaryScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              justFinished: state.uri.queryParameters['new'] == '1',
            ),
          ),
          StatefulShellRoute(
            builder: (context, state, navigationShell) => MainShell(
                navigationShell: navigationShell, location: state.uri.path),
            // Tabs keep their state like an IndexedStack but cross-fade.
            navigatorContainerBuilder: (context, navigationShell, children) =>
                FadingBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: discover,
                    name: 'discover',
                    builder: (context, state) => const DiscoverScreen(),
                    routes: [
                      GoRoute(
                        path: 'article/:id',
                        name: 'article',
                        builder: (context, state) =>
                            ArticleScreen(id: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: shop,
                    name: 'shop',
                    builder: (context, state) => const ShopScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: home,
                    name: 'home',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: HomeScreen(),
                    ),
                    // Sections open with a circle reveal from the tapped tile.
                    routes: [
                      GoRoute(
                        path: 'workouts',
                        name: 'workouts',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const MyWorkoutsScreen(),
                        ),
                        routes: [
                          // Before ':sport' so they aren't read as a sport.
                          GoRoute(
                            path: 'complete',
                            name: 'workoutComplete',
                            builder: (context, state) =>
                                const WorkoutCompleteScreen(),
                          ),
                          GoRoute(
                            path: 'exercises',
                            name: 'exerciseLibrary',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const ExerciseLibraryScreen(),
                            ),
                            routes: [
                              // Before ':id' so "add" isn't read as an id.
                              GoRoute(
                                path: 'add',
                                name: 'addExercise',
                                builder: (context, state) => AddExerciseScreen(
                                  replace: state.uri.queryParameters['mode'] ==
                                      'replace',
                                  index: int.tryParse(
                                          state.uri.queryParameters['index'] ??
                                              '') ??
                                      0,
                                ),
                              ),
                              GoRoute(
                                path: ':id',
                                name: 'exerciseDetail',
                                builder: (context, state) =>
                                    ExerciseDetailScreen(
                                        id: state.pathParameters['id']!),
                              ),
                            ],
                          ),
                          // Before ':sport' so they aren't read as a sport.
                          GoRoute(
                            path: 'running',
                            name: 'runningWorkouts',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const RunningScreen(),
                            ),
                          ),
                          GoRoute(
                            path: 'football',
                            name: 'footballWorkouts',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const FootballScreen(),
                            ),
                          ),
                          GoRoute(
                            path: 'cycling',
                            name: 'cyclingWorkouts',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const CyclingScreen(),
                            ),
                          ),
                          GoRoute(
                            path: 'winterSports',
                            name: 'winterSportsWorkouts',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const SkiingScreen(),
                            ),
                          ),
                          GoRoute(
                            path: ':sport',
                            name: 'sportWorkouts',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              SportWorkoutsScreen(
                                sport: Sport.fromName(
                                    state.pathParameters['sport']!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'programs',
                        name: 'programs',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const ProgramsScreen(),
                        ),
                        routes: [
                          // Before ':id' so "active" isn't read as an id.
                          GoRoute(
                            path: 'active',
                            name: 'programActive',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const ProgramProgressScreen(),
                            ),
                          ),
                          GoRoute(
                            path: ':id',
                            name: 'programDetail',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              ProgramDetailScreen(
                                  id: state.pathParameters['id']!),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'progress',
                        name: 'progress',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const ProgressScreen(),
                        ),
                        routes: [
                          GoRoute(
                            path: 'load',
                            name: 'progressLoad',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const TrainingLoadScreen(),
                            ),
                          ),
                          GoRoute(
                            path: 'records',
                            name: 'progressRecords',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const RecordsScreen(),
                            ),
                          ),
                          GoRoute(
                            path: 'lift/:name',
                            name: 'progressLift',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              LiftDetailScreen(
                                  name: state.pathParameters['name']!),
                            ),
                          ),
                          GoRoute(
                            path: 'weight',
                            name: 'progressWeight',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const BodyWeightScreen(),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'nutrition',
                        name: 'nutrition',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const NutritionScreen(),
                        ),
                        routes: [
                          GoRoute(
                            path: 'add',
                            name: 'nutritionAdd',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              AddFoodScreen(
                                  slot: MealSlot.fromName(
                                      state.uri.queryParameters['slot'])),
                            ),
                          ),
                          GoRoute(
                            path: 'food/:id',
                            name: 'nutritionFood',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              FoodDetailScreen(
                                id: state.pathParameters['id']!,
                                slot: MealSlot.fromName(
                                    state.uri.queryParameters['slot']),
                              ),
                            ),
                          ),
                          GoRoute(
                            path: 'micros',
                            name: 'nutritionMicros',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const MicrosScreen(),
                            ),
                          ),
                          GoRoute(
                            path: 'targets',
                            name: 'nutritionTargets',
                            pageBuilder: (context, state) => circleRevealPage(
                              context,
                              state,
                              const TargetsScreen(),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'checkin/recovery',
                        name: 'recovery',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const RecoveryScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'plan',
                        name: 'weekPlan',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const WeekPlanScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'map',
                        name: 'fitrixMap',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const MapScreen(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: felix,
                    name: 'felix',
                    builder: (context, state) => const FelixHubScreen(),
                    routes: [
                      GoRoute(
                        path: 'all',
                        name: 'felixAll',
                        builder: (context, state) =>
                            const FelixAllChatsScreen(),
                      ),
                      GoRoute(
                        path: 'chat/:topic',
                        name: 'felixChat',
                        redirect: (context, state) => AssistantTopic.fromId(
                                    state.pathParameters['topic'] ?? '') ==
                                null
                            ? felix
                            : null,
                        builder: (context, state) => FelixChatScreen(
                          // Key by topic: another topic gets a fresh screen.
                          key: ValueKey(state.pathParameters['topic']),
                          topic: AssistantTopic.fromId(
                              state.pathParameters['topic']!)!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: me,
                    name: 'me',
                    builder: (context, state) => const ProfileTabScreen(),
                    routes: [
                      GoRoute(
                        path: 'about',
                        name: 'aboutMe',
                        builder: (context, state) => const AboutMeScreen(),
                        // Leaving by another route (e.g. re-tapping the
                        // Profile tab) asks about unsaved edits too.
                        onExit: aboutMeOnExit,
                      ),
                      GoRoute(
                        path: 'zones',
                        name: 'hrZones',
                        builder: (context, state) => const HrZonesScreen(),
                      ),
                      GoRoute(
                        path: 'edit',
                        name: 'editProfile',
                        builder: (context, state) => const EditProfileScreen(),
                      ),
                      GoRoute(
                        path: 'apps',
                        name: 'connectedApps',
                        builder: (context, state) =>
                            const ConnectedAppsScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}

/// A full-screen modal page that slides up from the bottom and back down
/// when it closes (instant with reduced motion).
Page<void> slideUpPage(
    BuildContext context, GoRouterState state, Widget child) {
  final reduced = Motion.reduced(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    fullscreenDialog: true,
    transitionDuration: reduced ? Duration.zero : Motion.slow,
    reverseTransitionDuration: reduced ? Duration.zero : Motion.medium,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.curve,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position:
            Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}
