import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return const Center(child: Text('No messages yet.'));
                
                return ListView.builder(
                  reverse: false, // In real app, true + reverse list
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == 'user_1'; // Hardcoded 'me' for demo

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(msg.senderName,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800])),
                            Text(msg.text),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading chat')),
            ),
          ),
          _ChatInput(chatId: chatId),
        ],
      ),
    );
  }
}

class _ChatInput extends ConsumerStatefulWidget {
  final String chatId;
  const _ChatInput({required this.chatId});

  @override
  ConsumerState<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<_ChatInput> {
  final _controller = TextEditingController();

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    
    // Hardcoded User for Demo
    final me = const UserModel(
        uid: 'user_1',
        email: 'me@test.com',
        displayName: 'Me',
        explorerPoints: 100);

    ref.read(socialRepositoryProvider).sendMessage(
          widget.chatId,
          _controller.text,
          me,
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.teal),
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
