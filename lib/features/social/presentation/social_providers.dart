import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/social/data/mock_social_repository.dart';
import 'package:travel_hackathon/features/social/data/social_repository.dart';
import 'package:travel_hackathon/features/social/domain/chat_model.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return MockSocialRepository();
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
