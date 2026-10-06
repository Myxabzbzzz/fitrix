import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/widgets/coming_soon_screen.dart';
import 'package:fitrix/features/auth/data/auth_gateway.dart';
import 'package:fitrix/features/intro/presentation/screens/intro_screen.dart';
import 'package:fitrix/features/language/presentation/screens/language_screen.dart';
import 'package:fitrix/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/about_me_screen.dart';
import 'package:fitrix/features/chat/presentation/screens/chat_screen.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/transition/presentation/screens/chat_transition_screen.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
import 'package:fitrix/features/shell/presentation/fading_branch_container.dart';
import 'package:fitrix/features/shell/presentation/main_shell.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/screens/my_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/progress_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';

class AppRouter {
  // Onboarding
  static const String intro = '/';
  static const String language = '/language';
  static const String signIn = '/sign-in';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String transition = '/transition';

  // Main app (tab bar)
  static const String discover = '/discover';
  static const String shop = '/shop';
  static const String home = '/home';
  static const String felix = '/felix';
  static const String me = '/me';

  // Home sections
  static const String workouts = '/home/workouts';
  static const String progress = '/home/progress';
  static const String nutrition = '/home/nutrition';
  static const String fitrixMap = '/home/map';

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
          StatefulShellRoute(
            builder: (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
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
                    builder: (context, state) => const ComingSoonScreen(
                      title: 'Discover',
                      icon: Icons.explore_outlined,
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: shop,
                    name: 'shop',
                    builder: (context, state) => const ComingSoonScreen(
                      title: 'Shop',
                      icon: Icons.shopping_cart_outlined,
                      imageAsset: 'assets/images/tile_shop.png',
                    ),
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
                        path: 'progress',
                        name: 'progress',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const ProgressScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'nutrition',
                        name: 'nutrition',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const NutritionScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'map',
                        name: 'fitrixMap',
                        pageBuilder: (context, state) => circleRevealPage(
                          context,
                          state,
                          const ComingSoonScreen(
                            title: 'Fitrix map',
                            icon: Icons.map_outlined,
                            imageAsset: 'assets/images/tile_map.png',
                          ),
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
                    builder: (context, state) => const FelixChatScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: me,
                    name: 'me',
                    builder: (context, state) => const AboutMeScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}
