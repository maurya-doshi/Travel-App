import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/social/data/mock_social_repository.dart';
import 'package:travel_hackathon/features/social/data/social_repository.dart';
import 'package:travel_hackathon/features/social/domain/chat_model.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:travel_hackathon/features/social/domain/quest_model.dart';

import 'package:travel_hackathon/core/services/api_service_provider.dart';
import 'package:travel_hackathon/features/social/data/api_social_repository.dart';
import 'package:travel_hackathon/features/social/domain/direct_chat_model.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApiSocialRepository(apiService);
});

// Events for a specific city
final eventsForCityProvider = FutureProvider.family<List<TravelEvent>, String>((ref, city) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getEvents(city: city);
});

// Messages for a specific chat
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getMessages(chatId);
});

// Direct Chats List for a User

final directChatsProvider = FutureProvider.family<List<DirectChat>, String>((ref, userId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getDirectChats(userId);
});

// Direct Messages for a Chat
final directMessagesProvider = FutureProvider.family<List<DirectMessage>, String>((ref, chatId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getDirectMessages(chatId);
});

// Quests
final allQuestsProvider = FutureProvider<List<Quest>>((ref) async {
  return ref.watch(socialRepositoryProvider).getQuests();
});

final questForCityProvider = FutureProvider.family<Quest?, String>((ref, city) async {
  return ref.watch(socialRepositoryProvider).getQuestForCity(city);
});

final userQuestProgressProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  return ref.watch(socialRepositoryProvider).getCompletedSteps(userId);
});

// Active Quests (user has joined)
final activeQuestsProvider = FutureProvider.family<List<Quest>, String>((ref, userId) async {
  return ref.watch(socialRepositoryProvider).getActiveQuests(userId);
});

// Progress for a specific quest
final questProgressProvider = FutureProvider.family<Map<String, dynamic>, ({String userId, String questId})>((ref, params) async {
  return ref.watch(socialRepositoryProvider).getQuestProgress(params.userId, params.questId);
});
