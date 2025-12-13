import 'package:travel_hackathon/features/auth/domain/user_model.dart';

class TravelEvent {
  static const int kMaxHardParticipantLimit = 20;

  final String id;
  final String city; 
  final String title; 
  final DateTime eventDate; 
  final bool isDateFlexible;
  final String creatorId; 
  final String creatorName;
  final String category;
  final List<String> participantIds; 
  final List<String> pendingRequestIds; 
  final bool requiresApproval; 
  final String status; 

  const TravelEvent({
    required this.id,
    required this.city,
    required this.title,
    required this.eventDate,
    required this.creatorId,
    this.creatorName = 'Unknown',
    this.category = 'General',
    required this.participantIds,
    this.pendingRequestIds = const [],
    this.requiresApproval = true,
    this.isDateFlexible = false,
    this.status = 'open',
  });

  bool get isFull => false; // Removed maxParticipants logic
  bool isAdmin(String uid) => uid == creatorId;

  factory TravelEvent.fromMap(Map<String, dynamic> map, String id) {
    return TravelEvent(
      id: id,
      city: map['city'] as String,
      title: map['title'] as String,
      eventDate: DateTime.parse(map['eventDate'] as String),
      creatorId: map['creatorId'] as String,
      creatorName: map['creatorName'] as String? ?? 'Unknown',
      category: map['category'] as String? ?? 'General',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      pendingRequestIds: List<String>.from(map['pendingRequestIds'] ?? []),
      requiresApproval: map['requiresApproval'] ?? true,
      isDateFlexible: map['isDateFlexible'] ?? false,
      status: map['status'] as String? ?? 'open',
    );
  }

  factory TravelEvent.fromJson(Map<String, dynamic> map) {
    return TravelEvent.fromMap(map, map['id'] as String);
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'title': title,
      'eventDate': eventDate.toIso8601String(),
      'isDateFlexible': isDateFlexible,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'category': category,
      'participantIds': participantIds,
      'pendingRequestIds': pendingRequestIds,
      'requiresApproval': requiresApproval,
      'status': status,
    };
  }
}
