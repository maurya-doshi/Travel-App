import 'dart:async';
import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/social/data/social_repository.dart';
import 'package:travel_hackathon/features/social/domain/chat_model.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:travel_hackathon/features/social/domain/direct_chat_model.dart';
import 'package:travel_hackathon/features/social/domain/quest_model.dart';

class ApiSocialRepository implements SocialRepository {
  final ApiService _apiService;

  ApiSocialRepository(this._apiService);

  @override
  Future<List<TravelEvent>> getEvents({
    required String city,
    DateTime? date,
    bool? flexibleOnly,
  }) async {
    // Backend return all events. We filter here.
    final List<dynamic> data = await _apiService.get('/events');
    
    // Parse
    List<TravelEvent> events = data.map((json) => TravelEvent.fromMap(json, json['id'])).toList();

    // Filter
    return events.where((e) {
      if (city != 'All' && e.city != city) return false;
      if (flexibleOnly == true && !e.isDateFlexible) return false;
      // Date filter logic (simple day match)
      if (date != null) {
        final isSameDay = e.eventDate.year == date.year &&
            e.eventDate.month == date.month &&
            e.eventDate.day == date.day;
        if (!isSameDay && !e.isDateFlexible) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<GroupChat?> getGroupDetails(String groupId) async {
    // groupId in frontend usage often mix eventId and chatId. 
    // Mock used 'chat_' prefix. Backend chat ID is UUID.
    // If groupId is not found, we assume it's an eventId and fetch chat for it?
    // Let's assume groupId passed here IS the chatId from the event.
    // Wait, the UI might pass eventId expecting to get chat.
    // The backend endpoint is /chats/:eventId.
    
    try {
      final data = await _apiService.get('/chats/$groupId'); // Try treating as eventId first?
      // Backend returns: { id, eventId, memberIds }
      // GroupChat expects: id, eventId, name, memberIds. Name comes from event.
      // We might need to fetch event title.
      // This is getting complex because backend chat object is minimal.
      
      // OPTION 2: If the backend throws 404, maybe groupId is the actual chat ID?
      // But we have endpoint /chats/:eventId.
      // Let's rely on eventId usage.
      
      // We need event details for the name
      // There is no single event endpoint in backend? /events returns all. 
      // I should add GET /events/:id or just filter from all (inefficient but works for hackathon).
      
      // Let's fetch all events and find the one.
      final List<dynamic> allEvents = await _apiService.get('/events');
      final event = allEvents.firstWhere((e) => e['id'] == data['eventId'], orElse: () => null);
      
      return GroupChat(
        id: data['id'],
        eventId: data['eventId'],
        name: event != null ? event['title'] : 'Group Chat',
        memberIds: List<String>.from(data['memberIds']),
      );
    } catch (e) {
      // If error, maybe return null
      return null;
    }
  }

  @override
  Stream<List<ChatMessage>> getMessages(String groupId) async* {
    // Polling every 2 seconds
    while (true) {
      try {
        final List<dynamic> data = await _apiService.get('/chats/$groupId/messages');
        yield data.map((json) {
           return ChatMessage(
             id: json['id'],
             senderId: json['senderId'],
             senderName: json['senderName'] ?? 'Unknown',
             text: json['text'],
             timestamp: DateTime.parse(json['timestamp']),
           );
        }).toList();
      } catch (e) {
        // print error?
        yield [];
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Future<void> sendMessage(String groupId, String text, UserModel sender) async {
    await _apiService.post('/chats/$groupId/messages', {
      'senderId': sender.uid,
      'text': text
    });
  }

  // Define joinEvent if it's part of the requirement, but it's not in the abstract class I saw.
  // I will check if I need to extend the abstract class.
  // The plan said "Integrate API calls ... joinEvent".
  // I likely need to adding joinEvent to SocialRepository interface.
  @override
  Future<void> joinEvent(String eventId, String userId) async {
     await _apiService.post('/events/$eventId/join', {'userId': userId});
  }

  @override
  Future<void> createEvent(TravelEvent event) async {
    await _apiService.post('/events', {
      'city': event.city,
      'title': event.title,
      'eventDate': event.eventDate.toIso8601String(),
      'isDateFlexible': event.isDateFlexible,
      'creatorId': event.creatorId,
      'requiresApproval': event.requiresApproval,
      'category': event.category,
    });
  }
  @override
  Future<List<Map<String, dynamic>>> getPendingRequests(String eventId) async {
    final response = await _apiService.get('/events/$eventId/requests');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> acceptRequest(String eventId, String userId) async {
    await _apiService.post('/events/$eventId/accept', {'userId': userId});
  }

  @override
  Future<void> rejectRequest(String eventId, String userId) async {
    await _apiService.post('/events/$eventId/reject', {'userId': userId});
  }

  @override
  Future<void> deleteEvent(String eventId, String userId) async {
    await _apiService.delete('/events/$eventId', headers: {'x-user-id': userId});
  }

  // --- DM Implementation ---

  @override
  Future<DirectChat> createDirectChat(String user1Id, String user2Id) async {
    final response = await _apiService.post('/chats/direct', {
      'user1Id': user1Id,
      'user2Id': user2Id,
    });
    return DirectChat.fromJson(response);
  }

  @override
  Future<List<DirectChat>> getDirectChats(String userId) async {
    final response = await _apiService.get('/chats/direct/user/$userId');
    return (response as List).map((e) => DirectChat.fromJson(e)).toList();
  }

  @override
  Future<List<DirectMessage>> getDirectMessages(String chatId) async {
    final response = await _apiService.get('/chats/direct/$chatId/messages');
    return (response as List).map((e) => DirectMessage.fromJson(e)).toList();
  }

  @override
  Future<void> sendDirectMessage(String chatId, String senderId, String text) async {
    await _apiService.post('/chats/direct/$chatId/messages', {
      'senderId': senderId,
      'text': text,
    });
  }
  // --- Quests ---

  @override
  Future<List<Quest>> getQuests() async {
    final response = await _apiService.get('/quests');
    return (response as List).map((e) => Quest.fromJson(e)).toList();
  }

  @override
  Future<Quest?> getQuestForCity(String city) async {
    try {
      final response = await _apiService.get('/quests/city/$city');
      return Quest.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> submitQuestStep(String userId, String questId, String stepId) async {
    await _apiService.post('/quests/progress', {
      'userId': userId,
      'questId': questId,
      'stepId': stepId,
    });
  }

  @override
  Future<List<String>> getCompletedSteps(String userId) async {
    final response = await _apiService.get('/quests/progress/$userId');
    return (response as List).map((e) => e['stepId'] as String).toList();
  }

  // --- Quest Progress ---

  @override
  Future<void> joinQuest(String userId, String questId) async {
    await _apiService.post('/quests/join', {
      'userId': userId,
      'questId': questId,
    });
  }

  @override
  Future<void> quitQuest(String userId, String questId) async {
    await _apiService.post('/quests/quit', {
      'userId': userId,
      'questId': questId,
    });
  }

  @override
  Future<List<Quest>> getActiveQuests(String userId) async {
    final response = await _apiService.get('/quests/active/$userId');
    return (response as List).map((e) => Quest.fromJson(e)).toList();
  }

  @override
  Future<Map<String, dynamic>> completeStep(String userId, String questId, String stepId) async {
    final response = await _apiService.post('/quests/step/complete', {
      'userId': userId,
      'questId': questId,
      'stepId': stepId,
    });
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getQuestProgress(String userId, String questId) async {
    final response = await _apiService.get('/quests/progress/$userId/$questId');
    return response as Map<String, dynamic>;
  }

  // --- CHAT DETAILS ---
  @override
  Future<Map<String, dynamic>> getChatDetails(String chatId) async {
    final response = await _apiService.get('/chats/$chatId/details');
    return response as Map<String, dynamic>;
  }

  // --- LEAVE EVENT ---
  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    await _apiService.post('/events/$eventId/leave', {'userId': userId});
  }
}
