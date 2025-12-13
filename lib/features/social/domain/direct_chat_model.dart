class DirectChat {
  final String id;
  final String user1Id;
  final String user2Id;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, dynamic>? otherUser; // For display

  DirectChat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.lastMessage,
    required this.lastMessageTime,
    this.otherUser,
  });

  factory DirectChat.fromJson(Map<String, dynamic> json) {
    return DirectChat(
      id: json['id'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      otherUser: json['otherUser'],
    );
  }
}

class DirectMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? senderName;

  DirectMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.senderName,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      senderName: json['senderName'],
    );
  }
}
