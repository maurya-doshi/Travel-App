import 'dart:async';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/social/data/social_repository.dart';
import 'package:travel_hackathon/features/social/domain/chat_model.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';

class MockSocialRepository implements SocialRepository {
  // Fake Events
  final List<TravelEvent> _events = [
    TravelEvent(
      id: 'event_louvre_1',
      city: 'Paris',
      title: 'Louvre Guided Tour (English)',
      eventDate: DateTime.now().add(const Duration(days: 2)),
      creatorId: 'user_1',
      participantIds: ['user_1', 'user_2', 'user_3'],
      requiresApproval: true,
      pendingRequestIds: ['user_5'],
      isDateFlexible: false,
      status: 'open',
    ),
    TravelEvent(
      id: 'event_dinner_1',
      city: 'Paris',
      title: 'Cheap Ramen Night',
      eventDate: DateTime.now().add(const Duration(hours: 4)),
      creatorId: 'user_4',
      participantIds: ['user_4'],
      requiresApproval: false, // Open to join
      isDateFlexible: true,
      status: 'open',
    ),
    // BANGALORE EVENTS
    TravelEvent(
      id: 'event_blr_1',
      city: 'Bangalore',
      title: 'Cubbon Park Morning Run',
      eventDate: DateTime.now().add(const Duration(days: 1, hours: 2)),
      creatorId: 'user_blr_1',
      participantIds: ['user_blr_1', 'user_blr_2', 'test-user-1'],
      requiresApproval: false,
      isDateFlexible: false,
      status: 'open',
    ),
    TravelEvent(
      id: 'event_blr_2',
      city: 'Bangalore',
      title: 'Tech Meetup @ Indiranagar',
      eventDate: DateTime.now().add(const Duration(days: 3, hours: 10)),
      creatorId: 'user_blr_3',
      participantIds: ['user_blr_3', 'user_blr_4'],
      requiresApproval: true,
      isDateFlexible: true,
      status: 'open',
    ),
    // MUMBAI EVENTS
    TravelEvent(
      id: 'event_mum_1',
      city: 'Mumbai',
      title: 'Marine Drive Sunset',
      eventDate: DateTime.now().add(const Duration(hours: 5)),
      creatorId: 'user_mum_1',
      participantIds: ['user_mum_1', 'user_mum_2', 'user_mum_5'],
      requiresApproval: false,
      isDateFlexible: true,
      status: 'open',
    ),
  ];

  // Fake Chats
  final Map<String, List<ChatMessage>> _messages = {
    'chat_louvre_1': [
      ChatMessage(
        id: 'm1',
        senderId: 'user_1',
        senderName: 'Alice',
        text: 'Hey everyone, the guide is booked for 2 PM!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'm2',
        senderId: 'user_2',
        senderName: 'Bob',
        text: 'Awesome, how much do we owe you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]
  };

  @override
  Future<List<TravelEvent>> getEvents({required String city, DateTime? date, bool? flexibleOnly}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _events.where((e) => e.city == city).toList();
  }

  @override
  Future<GroupChat?> getGroupDetails(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Determine which event links to this chat
    final event = _events.firstWhere((e) => e.id == groupId.replaceAll('chat_', 'event_'), 
        orElse: () => _events.first);
    
    return GroupChat(
      id: groupId,
      eventId: event.id,
      name: event.title,
      memberIds: event.participantIds,
    );
  }

  // Stream Controllers for "Real-time" updates
  final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};

  @override
  Stream<List<ChatMessage>> getMessages(String groupId) {
    if (!_streamControllers.containsKey(groupId)) {
      _streamControllers[groupId] = StreamController<List<ChatMessage>>.broadcast();
      // Push initial data
      Future.microtask(() {
         if (!_streamControllers[groupId]!.isClosed) {
           _streamControllers[groupId]!.add(_messages[groupId] ?? []);
         }
      });
    }
    return _streamControllers[groupId]!.stream;
  }

  @override
  Future<void> sendMessage(String groupId, String text, UserModel sender) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: sender.uid,
      senderName: sender.displayName,
      text: text,
      timestamp: DateTime.now(),
    );
    
    // Add to local storage
    if (_messages.containsKey(groupId)) {
      _messages[groupId]!.add(newMessage);
    } else {
      _messages[groupId] = [newMessage];
    }

    // Push update to stream
    _streamControllers[groupId]?.add(List.from(_messages[groupId]!));

    // Mock Bot Reply
    _triggerBotReply(groupId);
  }

  void _triggerBotReply(String groupId) async {
    await Future.delayed(const Duration(seconds: 2));
    final botMessage = ChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user_1',
      senderName: 'Alice (Guide)',
      text: _getBotResponse(),
      timestamp: DateTime.now(),
    );
     if (_messages.containsKey(groupId)) {
      _messages[groupId]!.add(botMessage);
      _streamControllers[groupId]?.add(List.from(_messages[groupId]!));
    }
  }

  String _getBotResponse() {
    final responses = [
      "That sounds perfect! 🌟",
      "I'll be there a bit early to grab tickets.",
      "Does everyone have the address?",
      "Can't wait! 📸",
      "Don't forget to bring water!",
      "I think Bob mentioned he's bringing snacks.",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  @override
  Future<void> joinEvent(String eventId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> createEvent(TravelEvent event) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _events.add(event);
  }
}
