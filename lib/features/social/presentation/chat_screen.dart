import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/core/services/api_service.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  void _showMembersSheet(BuildContext context, List<dynamic> members) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Members (${members.length})', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...members.map((m) => ListTile(
              leading: CircleAvatar(
                backgroundColor: m['isCreator'] == true ? PremiumTheme.primary : PremiumTheme.secondary,
                child: Text(
                  (m['displayName'] ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(m['displayName'] ?? 'Unknown'),
              trailing: m['isCreator'] == true
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PremiumTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Host', style: TextStyle(color: PremiumTheme.primary, fontSize: 12)),
                    )
                  : null,
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveGroup(BuildContext context, WidgetRef ref, String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text('You will be removed from this event and lose access to the chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = ref.read(currentUserProvider);
    if (userId == null) return;

    try {
      await ref.read(socialRepositoryProvider).leaveEvent(eventId, userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left the group'), backgroundColor: Colors.orange),
        );
        context.go('/chats');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _closeEvent(BuildContext context, WidgetRef ref, String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Event?'),
        content: const Text('This will remove the event from the Bulletin Board. The group chat will remain active for members.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Close Event', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = ref.read(currentUserProvider);
    if (userId == null) return;

    try {
      final api = ApiService();
      await api.post('/events/$eventId/close', {'userId': userId});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event closed successfully'), backgroundColor: Colors.orange),
        );
        ref.invalidate(chatDetailsProvider(chatId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showPendingRequests(BuildContext context, WidgetRef ref, String eventId) async {
    final api = ApiService();
    
    try {
      final requests = await api.get('/events/$eventId/requests') as List<dynamic>;
      
      if (!context.mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pending Requests (${requests.length})',
                style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (requests.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('No pending requests', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: PremiumTheme.primary,
                            child: Text(
                              (req['displayName']?.toString().substring(0, 1) ?? '?').toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(req['displayName'] ?? 'Unknown'),
                          subtitle: Text(req['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () async {
                                  await api.post('/events/$eventId/accept', {'userId': req['userId']});
                                  Navigator.pop(ctx);
                                  ref.invalidate(chatDetailsProvider(chatId));
                                  ref.invalidate(eventsForCityProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${req['displayName']} approved!'), backgroundColor: Colors.green),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () async {
                                  await api.post('/events/$eventId/reject', {'userId': req['userId']});
                                  Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${req['displayName']} rejected'), backgroundColor: Colors.orange),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));
    final chatDetailsAsync = ref.watch(chatDetailsProvider(chatId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: chatDetailsAsync.when(
          data: (details) => GestureDetector(
            onTap: () => _showMembersSheet(context, List<dynamic>.from(details['members'] ?? [])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details['eventTitle'] ?? 'Group Chat',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(details['members'] as List?)?.length ?? 0} members • Tap for info',
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          loading: () => Text('Loading...', style: GoogleFonts.dmSans(color: Colors.black87)),
          error: (e, s) {
            debugPrint('Chat details error: $e');
            return Text('Group Chat', style: GoogleFonts.dmSans(color: Colors.black87));
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          chatDetailsAsync.when(
            data: (details) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'members') {
                  _showMembersSheet(context, List<dynamic>.from(details['members'] ?? []));
                } else if (value == 'requests') {
                  _showPendingRequests(context, ref, details['eventId']);
                } else if (value == 'close') {
                  _closeEvent(context, ref, details['eventId']);
                } else if (value == 'leave') {
                  _leaveGroup(context, ref, details['eventId']);
                }
              },
              itemBuilder: (ctx) {
                final isCreator = ref.read(currentUserProvider) == details['creatorId'];
                return [
                  const PopupMenuItem(value: 'members', child: Text('View Members')),
                  if (isCreator)
                    const PopupMenuItem(value: 'requests', child: Text('📨 View Requests')),
                  if (isCreator && details['status'] != 'closed')
                    const PopupMenuItem(value: 'close', child: Text('Close Event', style: TextStyle(color: Colors.orange))),
                  const PopupMenuItem(
                    value: 'leave',
                    child: Text('Leave Group', style: TextStyle(color: Colors.red)),
                  ),
                ];
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
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
              backgroundColor: PremiumTheme.secondary,
              child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? PremiumTheme.primary : Colors.white,
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
                      child: Text(senderName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PremiumTheme.primary)),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
             decoration: BoxDecoration(color: PremiumTheme.primary, shape: BoxShape.circle),
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
