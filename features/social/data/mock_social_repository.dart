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
      description: 'We are a group of 3 looking for 2 more to split a guide cost.',
      eventDate: DateTime.now().add(const Duration(days: 2)),
      creatorId: 'user_1',
      maxParticipants: 5,
      participantIds: ['user_1', 'user_2', 'user_3'],
      requiresApproval: true,
      pendingRequestIds: ['user_5'],
      isDateFlexible: false,
    ),
    TravelEvent(
      id: 'event_dinner_1',
      city: 'Paris',
      title: 'Cheap Ramen Night',
      description: 'Just grabbing food at Rue Sainte-Anne.',
      eventDate: DateTime.now().add(const Duration(hours: 4)),
      creatorId: 'user_4',
      maxParticipants: 8,
      participantIds: ['user_4'],
      requiresApproval: false, // Open to join
      isDateFlexible: true,
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

  @override
  Stream<List<ChatMessage>> getMessages(String groupId) {
    return Stream.value(_messages[groupId] ?? []);
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
    
    if (_messages.containsKey(groupId)) {
      _messages[groupId]!.add(newMessage);
    } else {
      _messages[groupId] = [newMessage];
    }
  }
}
