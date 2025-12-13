import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your screens
import 'package:travel_hackathon/features/auth/presentation/signup_screen.dart';
import 'package:travel_hackathon/features/auth/presentation/login_screen.dart';
import 'package:travel_hackathon/core/presentation/scaffold_with_navbar.dart';
import 'package:travel_hackathon/features/auth/presentation/profile_screen.dart';
import 'package:travel_hackathon/features/social/presentation/create_event_screen.dart';
import 'package:travel_hackathon/features/discovery/presentation/city_selection_screen.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/map/presentation/map_screen.dart'; 
import 'package:travel_hackathon/features/social/presentation/events_screen.dart'; 
import 'package:travel_hackathon/features/social/presentation/chat_screen.dart'; 
import 'package:travel_hackathon/features/social/presentation/direct_chat_list_screen.dart';
import 'package:travel_hackathon/features/social/presentation/direct_chat_screen.dart';
import 'package:travel_hackathon/features/social/presentation/quest_screen.dart'; // Quests
import 'package:travel_hackathon/features/social/presentation/quest_details_screen.dart';
import 'package:travel_hackathon/features/auth/presentation/edit_profile_screen.dart';
import 'package:travel_hackathon/features/social/presentation/bulletin_board_screen.dart';
import 'package:travel_hackathon/features/social/presentation/chats_screen.dart';
import 'package:travel_hackathon/features/splash/presentation/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _sectionNavigatorKey = GlobalKey<NavigatorState>(); 

final routerProvider = Provider<GoRouter>((ref) {
  // Global key for valid context in shell
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellMap');
  final _shellNavigatorBulletinKey = GlobalKey<NavigatorState>(debugLabel: 'shellBulletin');
  final _shellNavigatorChatsKey = GlobalKey<NavigatorState>(debugLabel: 'shellChats');
  final _shellNavigatorQuestsKey = GlobalKey<NavigatorState>(debugLabel: 'shellQuests');
  final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  final userId = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final isLoggedIn = userId != null;
      final path = state.uri.toString();
      final isAuthRoute = path == '/signup' || path == '/login';
      final isSplash = path == '/splash';

      // Allow splash to play
      if (isSplash) return null;

      if (!isLoggedIn && !isAuthRoute) return '/signup';
      if (isLoggedIn && isAuthRoute) return '/map';

      return null;
    },
    routes: [
      // SPLASH (No Shell)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // AUTH (No Shell)
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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

          // BRANCH 2: Bulletin Board (Public Events)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBulletinKey, 
            routes: [
              GoRoute(
                path: '/bulletin',
                builder: (context, state) {
                  final city = state.uri.queryParameters['city'];
                  return BulletinBoardScreen(initialCity: city);
                },
              ),
              GoRoute(
                path: '/create-event',
                builder: (context, state) => const CreateEventScreen(),
              ),
            ],
          ),

          // BRANCH 3: Chats (Group Chats + DMs)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorChatsKey,
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatsScreen(),
              ),
            ],
          ),

          // BRANCH 4: Quests
          StatefulShellBranch(
            navigatorKey: _shellNavigatorQuestsKey,
            routes: [
              GoRoute(
                path: '/quests',
                builder: (context, state) => const QuestDiscoveryScreen(),
                routes: [
                  GoRoute(
                    path: ':city',
                    builder: (context, state) {
                      final city = state.pathParameters['city'] ?? '';
                      return QuestDetailsScreen(city: city);
                    },
                  ),
                ],
              ),
            ],
          ),

          // BRANCH 5: Profile
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(chatId: id);
        },
      ),
      // Direct Messages
      GoRoute(
        path: '/messages',
        builder: (context, state) => const DirectChatListScreen(),
      ),
      GoRoute(
        path: '/chats/direct/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final otherName = state.extra as String? ?? 'Chat';
          return DirectChatScreen(chatId: id, otherUserName: otherName);
        },
      ),
    ],
  );
});