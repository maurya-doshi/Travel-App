import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/features/map/presentation/map_screen.dart';
import 'package:travel_hackathon/features/social/presentation/chat_screen.dart';
import 'package:travel_hackathon/features/social/presentation/events_screen.dart';
import 'package:travel_hackathon/features/discovery/presentation/discovery_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // MAP (Home)
      GoRoute(
        path: '/',
        builder: (context, state) => const MapScreen(),
      ),
      // EVENTS (Bulletin Board)
      GoRoute(
        path: '/events',
        builder: (context, state) {
          final city = state.uri.queryParameters['city'] ?? 'Paris';
          return EventsScreen(city: city);
        },
      ),
      // CHAT
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          return ChatScreen(chatId: chatId);
        },
      ),
      // DISCOVERY (Hotels & Quests)
      GoRoute(
        path: '/discovery',
        builder: (context, state) {
           final city = state.uri.queryParameters['city'] ?? 'Paris';
           return DiscoveryScreen(city: city);
        },
      ),
    ],
  );
});
