import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Import your screens
import 'package:travel_hackathon/features/auth/presentation/signup_screen.dart';
import 'package:travel_hackathon/core/presentation/scaffold_with_navbar.dart';
import 'package:travel_hackathon/features/auth/presentation/profile_screen.dart';
import 'package:travel_hackathon/features/social/presentation/create_event_screen.dart';
import 'package:travel_hackathon/features/discovery/presentation/city_selection_screen.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/map/presentation/map_screen.dart'; // Assuming this is still needed for the map route
import 'package:travel_hackathon/features/social/presentation/events_screen.dart'; // Assuming this is still needed for events route

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _sectionNavigatorKey = GlobalKey<NavigatorState>(); // This might be replaced by specific shell keys

final routerProvider = Provider<GoRouter>((ref) {
  // Global key for valid context in shell
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellMap');
  final _shellNavigatorExploreKey = GlobalKey<NavigatorState>(debugLabel: 'shellExplore');
  final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  final userId = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/signup',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final isLoggedIn = userId != null;
      final isLoggingIn = state.uri.toString() == '/signup';

      if (!isLoggedIn && !isLoggingIn) return '/signup';
      if (isLoggedIn && isLoggingIn) return '/';

      return null;
    },
    routes: [
      // AUTH (No Shell)
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // THE SHELL ROUTE (Wraps the tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // BRANCH 1: Map
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMapKey,
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),

          // BRANCH 2: Events (or Explore based on the new keys)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExploreKey, // Assuming this replaces the old events branch
            routes: [
              GoRoute(
                path: '/events', // Keeping the old path for now, but might be '/explore'
                builder: (context, state) => const EventsScreen(), // Or CitySelectionScreen
              ),
              GoRoute(
                path: '/create-event',
                builder: (context, state) => const CreateEventScreen(),
              ),
              GoRoute(
                path: '/city-selection',
                builder: (context, state) => const CitySelectionScreen(),
              ),
            ],
          ),

          // BRANCH 3: Profile
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
    ],
  );
});