import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/social/domain/chat_model.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:travel_hackathon/features/social/domain/direct_chat_model.dart';
import 'package:travel_hackathon/features/social/domain/quest_model.dart';

abstract class SocialRepository {
  Stream<List<ChatMessage>> getMessages(String groupId);
  Future<void> sendMessage(String groupId, String text, UserModel sender);
  Future<GroupChat?> getGroupDetails(String groupId);
  Future<List<TravelEvent>> getEvents({
    required String city, 
    DateTime? date, 
    bool? flexibleOnly
  });
  Future<void> joinEvent(String eventId, String userId);
  Future<void> createEvent(TravelEvent event);
  Future<void> deleteEvent(String eventId, String userId);
  Future<List<Map<String, dynamic>>> getPendingRequests(String eventId);
  Future<void> acceptRequest(String eventId, String userId);
  Future<void> rejectRequest(String eventId, String userId);

  // Direct Messages
  Future<DirectChat> createDirectChat(String user1Id, String user2Id);
  Future<List<DirectChat>> getDirectChats(String userId);
  Future<List<DirectMessage>> getDirectMessages(String chatId);
  Future<void> sendDirectMessage(String chatId, String senderId, String text);

  // Quests
  Future<List<Quest>> getQuests();
  Future<Quest?> getQuestForCity(String city);
  Future<void> submitQuestStep(String userId, String questId, String stepId);
  Future<List<String>> getCompletedSteps(String userId);
  
  // Quest Progress
  Future<void> joinQuest(String userId, String questId);
  Future<void> quitQuest(String userId, String questId);
  Future<List<Quest>> getActiveQuests(String userId);
  Future<Map<String, dynamic>> completeStep(String userId, String questId, String stepId);
  Future<Map<String, dynamic>> getQuestProgress(String userId, String questId);

  // Chat Details & Leave
  Future<Map<String, dynamic>> getChatDetails(String chatId);
  Future<void> leaveEvent(String eventId, String userId);
}
