import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/social/domain/chat_model.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';

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
}
