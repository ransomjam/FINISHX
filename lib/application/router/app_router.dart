import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/archive/journey_archive_screen.dart';
import '../../features/archive/journey_queue_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/completion/journey_completion_reflection_screen.dart';
import '../../features/completion/journey_completion_screen.dart';
import '../../features/dashboard/home_dashboard_screen.dart';
import '../../features/dashboard/notifications_screen.dart';
import '../../features/dashboard/profile_settings_screen.dart';
import '../../features/group/accountability_group_screen.dart';
import '../../features/journey/journey_schedule_screen.dart';
import '../../features/journey/my_journey_screen.dart';
import '../../features/onboarding/group_welcome_screen.dart';
import '../../features/onboarding/journey_wizard_screen.dart';
import '../../features/reflection/weekly_checkin_screen.dart';
import '../../features/session/focus_mode_screen.dart';
import '../../features/session/journey_update_screen.dart';
import '../../features/session/session_reflection_screen.dart';
import 'finishx_shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final isSignIn = state.uri.queryParameters['intent'] == 'signin';
          return AuthScreen(isSignInIntent: isSignIn);
        },
      ),
      GoRoute(
        path: '/wizard',
        builder: (context, state) {
          final isQueue = state.uri.queryParameters['mode'] == 'queue';
          return JourneyWizardScreen(isQueueMode: isQueue);
        },
      ),
      GoRoute(
        path: '/group-welcome',
        builder: (context, state) => const GroupWelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return FinishXShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journey',
                builder: (context, state) => const MyJourneyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/group',
                builder: (context, state) => const AccountabilityGroupScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/archive',
                builder: (context, state) => const JourneyArchiveScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/archive/:archiveId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final archiveId = state.pathParameters['archiveId']!;
          return ArchiveDetailScreen(archiveId: archiveId);
        },
      ),
      GoRoute(
        path: '/queue',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JourneyQueueScreen(),
      ),
      GoRoute(
        path: '/schedule',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JourneyScheduleScreen(),
      ),
      GoRoute(
        path: '/focus',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FocusModeScreen(),
      ),
      GoRoute(
        path: '/session-reflection/:sessionId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return SessionReflectionScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/journey-update',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          return JourneyUpdateScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/weekly-checkin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeeklyCheckInScreen(),
      ),
      GoRoute(
        path: '/complete-reflection',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JourneyCompletionReflectionScreen(),
      ),
      GoRoute(
        path: '/journey-completed',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JourneyCompletionScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
