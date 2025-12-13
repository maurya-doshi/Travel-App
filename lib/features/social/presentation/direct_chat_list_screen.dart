import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:travel_hackathon/features/social/domain/direct_chat_model.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';

class DirectChatListScreen extends ConsumerStatefulWidget {
  const DirectChatListScreen({super.key});

  @override
  ConsumerState<DirectChatListScreen> createState() => _DirectChatListScreenState();
}

class _DirectChatListScreenState extends ConsumerState<DirectChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider);
    final asyncChats = ref.watch(directChatsProvider(userId ?? ''));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: asyncChats.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No messages yet', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Connect with travelers to start chatting!', style: GoogleFonts.outfit(color: Colors.grey[400])),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUser = chat.otherUser;
              final name = otherUser?['displayName'] ?? 'Unknown';
              // final email = otherUser?['email'] ?? '';
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                onTap: () => context.push('/chats/direct/${chat.id}', extra: name),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: PremiumTheme.primary.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: PremiumTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Start a conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
                trailing: Text(
                  _formatDate(chat.lastMessageTime),
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('h:mm a').format(date);
    }
    return DateFormat('MMM d').format(date);
  }
}
