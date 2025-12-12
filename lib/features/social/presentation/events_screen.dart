import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'dart:async';

class EventsScreen extends ConsumerStatefulWidget {
  final String city;

  const EventsScreen({super.key, required this.city});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Poll for updates every 5 seconds (Simulated Real-time)
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      ref.refresh(eventsForCityProvider(widget.city));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsForCityProvider(widget.city));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Personalized Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exploring',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: PremiumTheme.textSecondary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.city,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                            ],
                          ),
                          child: const Icon(Icons.notifications_outlined, color: PremiumTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 2. Search Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: PremiumTheme.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            'Find adventures...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: PremiumTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.tune, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Events List
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Quiet in ${widget.city}', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.push('/create-event'),
                            child: const Text('Start an Event'),
                          )
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = events[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _MinimalistEventCard(event: event, userId: currentUser),
                        );
                      },
                      childCount: events.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error loading events'))),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'events_fab',
        onPressed: () => context.push('/create-event'),
        backgroundColor: PremiumTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text('New Event'),
        icon: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms),
    );
  }
}

class _MinimalistEventCard extends ConsumerWidget {
  final TravelEvent event;
  final String? userId;

  const _MinimalistEventCard({required this.event, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isParticipant = event.participantIds.contains(userId);
    final isPending = event.pendingRequestIds.contains(userId);

    return GestureDetector(
      onTap: () {
        if (isParticipant) {
          context.push('/chat/${event.id.replaceAll('event_', 'chat_')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PremiumTheme.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(event.eventDate).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PremiumTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('d').format(event.eventDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(event.eventDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                // Avatars Placeholder
                SizedBox(
                  height: 32,
                  width: 60,
                  child: Stack(
                    children: [
                      for (int i = 0; i < (event.participantIds.length > 3 ? 3 : event.participantIds.length); i++)
                        Positioned(
                          left: i * 15.0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.person, size: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${event.participantIds.length} Going',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),

                // Ownership Check: Delete & Review
                if (userId != null && userId == event.creatorId) ...[
                  // Review Requests Button
                  if (event.pendingRequestIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Badge(
                          label: Text(event.pendingRequestIds.length.toString()),
                          child: const Icon(Icons.group_add, color: PremiumTheme.primary),
                        ),
                        tooltip: 'Review Requests',
                        onPressed: () {
                           showModalBottomSheet(
                             context: context,
                             backgroundColor: Colors.transparent,
                             isScrollControlled: true,
                             builder: (context) => _RequestsSheet(eventId: event.id, city: event.city),
                           );
                        },
                      ),
                    ),

                  // Delete Button
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () async {
                         final confirm = await showDialog<bool>(
                           context: context, 
                           builder: (c) => AlertDialog(
                             title: const Text('Delete Event?'),
                             content: const Text('This cannot be undone.'),
                             actions: [
                               TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                               TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                             ],
                           )
                         );
                         
                         if (confirm == true) {
                           // userId matches event.creatorId check above ensures userId is not null here
                           await ref.read(socialRepositoryProvider).deleteEvent(event.id, userId!);
                           // ignore: unused_result
                           ref.refresh(eventsForCityProvider(event.city));
                           if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Deleted')));
                           }
                         }
                      }, 
                    ),
                  ),
                ],
                
                if (isParticipant)
                  // Visual Indicator: Arrow
                  const CircleAvatar(
                    backgroundColor: Colors.green, // Updated from OutlinedButton
                    radius: 16,
                    child: Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  )
                else if (isPending)
                   Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20)),
                      child: Text('Pending', style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold)),
                   )
                else
                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(socialRepositoryProvider).joinEvent(event.id, userId ?? '');
                      // ignore: unused_result
                      ref.refresh(eventsForCityProvider(event.city));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Join'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _RequestsSheet extends ConsumerStatefulWidget {
  final String eventId;
  final String city;

  const _RequestsSheet({required this.eventId, required this.city});

  @override
  ConsumerState<_RequestsSheet> createState() => _RequestsSheetState();
}

class _RequestsSheetState extends ConsumerState<_RequestsSheet> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final data = await ref.read(socialRepositoryProvider).getPendingRequests(widget.eventId);
      if (mounted) setState(() { _requests = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _handleAction(String userId, bool accept) async {
    try {
      if (accept) {
        await ref.read(socialRepositoryProvider).acceptRequest(widget.eventId, userId);
      } else {
        await ref.read(socialRepositoryProvider).rejectRequest(widget.eventId, userId);
      }
      
      // Update Local State
      setState(() {
        _requests.removeWhere((r) => r['userId'] == userId);
      });

      // Refresh Parent List
      ref.refresh(eventsForCityProvider(widget.city));
      
      if (_requests.isEmpty && mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Requests',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_requests.isEmpty)
             const Center(child: Text('No more requests'))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final user = _requests[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Text(user['displayName']?[0]?.toUpperCase() ?? '?'),
                    ),
                    title: Text(user['displayName'] ?? 'Unknown User'),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _handleAction(user['userId'], false),
                        ),
                         IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _handleAction(user['userId'], true),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
