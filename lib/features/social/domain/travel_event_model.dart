import 'package:travel_hackathon/features/auth/domain/user_model.dart';

class TravelEvent {
  static const int kMaxHardParticipantLimit = 20;

  final String id;
  final String city; 
  final String title; 
  final String description; 
  final DateTime eventDate; 
  final bool isDateFlexible;
  final String creatorId; 
  final int maxParticipants;
  final List<String> participantIds; 
  final List<String> pendingRequestIds; 
  final bool requiresApproval; 
  final String status; 

  const TravelEvent({
    required this.id,
    required this.city,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.creatorId,
    required this.maxParticipants,
    required this.participantIds,
    this.pendingRequestIds = const [],
    this.requiresApproval = true,
    this.isDateFlexible = false,
    this.status = 'open',
  });

  bool get isFull => participantIds.length >= maxParticipants;
  bool isAdmin(String uid) => uid == creatorId;

  factory TravelEvent.fromMap(Map<String, dynamic> map, String id) {
    return TravelEvent(
      id: id,
      city: map['city'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      eventDate: DateTime.parse(map['eventDate'] as String),
      creatorId: map['creatorId'] as String,
      maxParticipants: map['maxParticipants'] as int,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      pendingRequestIds: List<String>.from(map['pendingRequestIds'] ?? []),
      requiresApproval: map['requiresApproval'] ?? true,
      isDateFlexible: map['isDateFlexible'] ?? false,
      status: map['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'isDateFlexible': isDateFlexible,
      'creatorId': creatorId,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds,
      'pendingRequestIds': pendingRequestIds,
      'requiresApproval': requiresApproval,
      'status': status,
    };
  }
}
