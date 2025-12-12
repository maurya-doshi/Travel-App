import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light blue-grey
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip Squad', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('Online', style: GoogleFonts.lato(fontSize: 12, color: Colors.green)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert), 
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                          child: const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text('Start the conversation!', style: GoogleFonts.lato(color: Colors.grey[600])),
                      ],
                    ).animate().scale(),
                  );
                }
                
                return ListView.builder(
                  reverse: false, 
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgs = messages[index];
                    final currentUid = ref.watch(currentUserProvider);
                    final isMe = msgs.senderId == currentUid;
                    
                    return _MessageBubble(
                      message: msgs.text, 
                      isMe: isMe, 
                      senderName: msgs.senderName,
                      index: index,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Messages unavailable')),
            ),
          ),
          _ChatInput(chatId: chatId),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;
  final int index;

  const _MessageBubble({required this.message, required this.isMe, required this.senderName, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE0E0E0),
              child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', style: GoogleFonts.oswald(color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6A1B9A) : Colors.white, // Purple or White
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(senderName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple[300])),
                    ),
                  Text(
                    message,
                    style: GoogleFonts.lato(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate(delay: (20 * index).ms).slideY(begin: 0.1).fade(),
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
    
    final uid = ref.read(currentUserProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
      return;
    }

    final me = UserModel(uid: uid, email: 'user@example.com', displayName: 'Me', explorerPoints: 0);

    ref.read(socialRepositoryProvider).sendMessage(widget.chatId, _controller.text, me);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), // Bottom padding for iOS home indicator
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.lato(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
           Container(
             decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle),
             child: IconButton(
               icon: const Icon(Icons.send, color: Colors.white, size: 20),
               onPressed: _send,
             ),
           ),
        ],
      ),
    );
  }
}
