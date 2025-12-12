class GroupChat {
  final String id;
  final String eventId; 
  final String name; 
  final List<String> memberIds;
  final String? lastMessageText;
  final DateTime? lastMessageTime;

  const GroupChat({
    required this.id,
    required this.eventId,
    required this.name,
    required this.memberIds,
    this.lastMessageText,
    this.lastMessageTime,
  });

  factory GroupChat.fromMap(Map<String, dynamic> map, String id) {
    return GroupChat(
      id: id,
      eventId: map['eventId'] as String,
      name: map['name'] as String,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageTime: map['lastMessageTime'] != null 
          ? DateTime.parse(map['lastMessageTime']) 
          : null,
    );
  }

  factory GroupChat.fromJson(Map<String, dynamic> map) {
    return GroupChat.fromMap(map, map['id'] as String);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'memberIds': memberIds,
      'lastMessageText': lastMessageText,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> map) {
    return ChatMessage.fromMap(map, map['id'] as String);
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
