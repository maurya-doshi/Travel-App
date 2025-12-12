import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/features/map/presentation/map_screen.dart';
import 'package:travel_hackathon/features/social/presentation/chat_screen.dart';
import 'package:travel_hackathon/features/social/presentation/events_screen.dart';
import 'package:travel_hackathon/features/auth/presentation/otp_login_screen.dart';
import 'package:travel_hackathon/core/presentation/scaffold_with_navbar.dart';
import 'package:travel_hackathon/features/auth/presentation/profile_screen.dart';
import 'package:travel_hackathon/features/social/presentation/create_event_screen.dart';
import 'package:travel_hackathon/features/discovery/presentation/city_selection_screen.dart';

import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Global key for valid context in shell
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellMap');
  final _shellNavigatorExploreKey = GlobalKey<NavigatorState>(debugLabel: 'shellExplore');
  final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  final userId = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    // refreshListenable: ValueNotifier(userId), // Ideally needs a real listenable
    redirect: (context, state) {
      final isLoggedIn = userId != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

      return null;
    },
    routes: [
      // AUTH
      GoRoute(
        path: '/login',
        builder: (context, state) => const OtpLoginScreen(),
      ),

      // TABS (Shell)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // TAB 1: MAP
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMapKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          
          // TAB 2: EXPLORE (City Selection -> Events)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExploreKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const CitySelectionScreen(),
                routes: [
                   GoRoute(
                    path: 'events', // /explore/events
                    builder: (context, state) {
                      final city = state.uri.queryParameters['city'] ?? 'Bangalore';
                      return EventsScreen(city: city);
                    },
                   ),
                ]
              ),
            ],
          ),

          // TAB 3: PROFILE
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // GLOBAL ROUTES (Push on top of tabs)
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootNavigatorKey, // Hide tabs for chat
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/create-event',
        parentNavigatorKey: _rootNavigatorKey, // Hide tabs for create
        builder: (context, state) => const CreateEventScreen(),
      ),
    ],
  );
});
