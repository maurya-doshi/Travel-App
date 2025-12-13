import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Provider for user's group chats
final userGroupChatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final api = ApiService();
  final response = await api.get('/chats/groups/$userId');
  return List<Map<String, dynamic>>.from(response);
});

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider);

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view chats')),
      );
    }

    final groupChatsAsync = ref.watch(userGroupChatsProvider(userId));
    final directChatsAsync = ref.watch(directChatsProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Chats', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userGroupChatsProvider(userId));
          ref.invalidate(directChatsProvider(userId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- GROUP CHATS SECTION ---
            _SectionHeader(title: 'Group Chats', icon: Icons.groups),
            const SizedBox(height: 12),
            groupChatsAsync.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return _EmptySection(
                    message: 'No group chats yet',
                    action: 'Join an event to start chatting!',
                    onTap: () => context.go('/bulletin'),
                  );
                }
                return Column(
                  children: chats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final chat = entry.value;
                    return _GroupChatTile(
                      chatId: chat['chatId'] ?? '',
                      eventTitle: chat['eventTitle'] ?? 'Group Chat',
                      city: chat['city'] ?? '',
                      status: chat['status'] ?? 'open',
                      isCreator: chat['isCreator'] == true,
                      index: index,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading group chats: $e'),
              ),
            ),

            const SizedBox(height: 32),

            // --- DIRECT MESSAGES SECTION ---
            _SectionHeader(title: 'Direct Messages', icon: Icons.chat_bubble_outline),
            const SizedBox(height: 12),
            directChatsAsync.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return _EmptySection(
                    message: 'No direct messages yet',
                    action: 'Message someone from an event!',
                  );
                }
                return Column(
                  children: chats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final chat = entry.value;
                    final otherUserId = chat.user1Id == userId ? chat.user2Id : chat.user1Id;
                    return _DirectChatTile(
                      chatId: chat.id,
                      otherUserId: otherUserId,
                      index: index,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading DMs: $e'),
              ),
            ),
            
            const SizedBox(height: 100), // Bottom padding for navbar
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: PremiumTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  final String action;
  final VoidCallback? onTap;

  const _EmptySection({required this.message, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
          if (onTap != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onTap, child: Text(action)),
          ] else
            Text(action, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
}

class _GroupChatTile extends StatelessWidget {
  final String chatId;
  final String eventTitle;
  final String city;
  final String status;
  final bool isCreator;
  final int index;

  const _GroupChatTile({
    required this.chatId,
    required this.eventTitle,
    required this.city,
    required this.status,
    required this.isCreator,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = status == 'closed';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/chat/$chatId'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isClosed
                        ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!])
                        : PremiumTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              eventTitle,
                              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCreator) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PremiumTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Host', style: TextStyle(color: PremiumTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(city, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          if (isClosed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Closed', style: TextStyle(color: Colors.orange[700], fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
  }
}

class _DirectChatTile extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final int index;

  const _DirectChatTile({
    required this.chatId,
    required this.otherUserId,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // For simplicity, showing userId. In production, fetch displayName.
    final displayName = otherUserId.replaceAll('user_', '').replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/chats/direct/$chatId', extra: displayName),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: PremiumTheme.secondary,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
  }
}
