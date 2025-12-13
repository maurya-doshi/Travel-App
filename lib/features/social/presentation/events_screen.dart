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
  String _selectedCategory = 'All';

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
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                margin: const EdgeInsets.only(right: 16),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: PremiumTheme.primary),
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      context.pop();
                                    } else {
                                      context.go('/map');
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: Column(
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
                                      widget.city == 'All' ? 'Trending Everywhere' : widget.city,
                                      style: Theme.of(context).textTheme.displayLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Messages Button
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () => context.push('/messages'),
                            child: const Icon(Icons.chat_bubble_outline, color: PremiumTheme.primary, size: 20),
                          ),
                        ),

                        if (widget.city != 'All')
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
                            widget.city == 'All' ? 'Search global events...' : 'Find adventures in ${widget.city}...',
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
                    const SizedBox(height: 24),
                    
                    // 3. Category Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          'All', 'Adventure', 'Chill', 'Party', 'Nature', 'Cultural'
                        ].map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                              selectedColor: Colors.black,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20), 
                                side: BorderSide(color: Colors.grey[200]!)
                              ),
                              elevation: 0,
                              pressElevation: 0,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2.5 Popular Destinations (Global Only)
            if (widget.city == 'All')
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Popular Destinations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _CityCard(city: 'Goa', image: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?q=80&w=1000&auto=format&fit=crop', color: Colors.teal),
                          _CityCard(city: 'Bangalore', image: 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?q=80&w=1000&auto=format&fit=crop', color: Colors.indigo),
                          _CityCard(city: 'Mumbai', image: 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?q=80&w=1000&auto=format&fit=crop', color: Colors.orange),
                          _CityCard(city: 'Delhi', image: 'https://images.unsplash.com/photo-1587474260584-136574528615?q=80&w=1000&auto=format&fit=crop', color: Colors.red),
                          _CityCard(city: 'Manali', image: 'https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?q=80&w=1000&auto=format&fit=crop', color: Colors.blue),
                        ].map((card) => Padding(padding: const EdgeInsets.only(right: 16), child: card)).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Trending Events',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // 3. Events List
            eventsAsync.when(
              data: (allEvents) {
                // FILTER
                final events = _selectedCategory == 'All' 
                    ? allEvents 
                    : allEvents.where((e) => e.category == _selectedCategory).toList();

                if (events.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                             'No $_selectedCategory events found', 
                             style: Theme.of(context).textTheme.bodyMedium
                          ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          heroTag: 'events_fab',
          onPressed: () => context.push('/create-event'),
          backgroundColor: PremiumTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          label: const Text('New Event'),
          icon: const Icon(Icons.add),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }
}

class _MinimalistEventCard extends ConsumerWidget {
  final TravelEvent event;
  final String? userId;

  const _MinimalistEventCard({required this.event, required this.userId});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Adventure': return Colors.orange;
      case 'Chill': return Colors.blue;
      case 'Party': return Colors.purple;
      case 'Nature': return Colors.green;
      case 'Cultural': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isParticipant = event.participantIds.contains(userId);
    final isPending = event.pendingRequestIds.contains(userId);

    return GestureDetector(
      onTap: () {
        if (isParticipant) {
          context.push('/chat/chat_${event.id}');
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(event.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.category.toUpperCase(),
                              style: TextStyle(
                                color: _getCategoryColor(event.category),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // City Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 10, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  event.city,
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(event.eventDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organized by ${event.creatorId == userId ? 'Me' : event.creatorName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
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

                // Message Host Button
                if (userId != null && userId != event.creatorId)
                   IconButton(
                     icon: const Icon(Icons.chat_bubble_outline, color: PremiumTheme.primary),
                     tooltip: 'Message Host',
                     onPressed: () async {
                       try {
                         final chat = await ref.read(socialRepositoryProvider).createDirectChat(userId!, event.creatorId);
                         if (context.mounted) {
                           context.push('/chats/direct/${chat.id}', extra: event.creatorName);
                         }
                       } catch (e) {
                         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                       }
                     },
                   ),

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
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                          onPressed: () async {
                              try {
                                final currentUserId = ref.read(currentUserProvider);
                                final chat = await ref.read(socialRepositoryProvider).createDirectChat(
                                  currentUserId!,
                                  user['userId']
                                );
                                if (context.mounted) {
                                   context.push('/chats/direct/${chat.id}', extra: user['displayName']);
                                } 
                              } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                          },
                        ),
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


class _CityCard extends StatelessWidget {
  final String city;
  final String image;
  final Color color;

  const _CityCard({required this.city, required this.image, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/bulletin'),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color,
          image: DecorationImage(
            image: NetworkImage(image),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(20),
             gradient: LinearGradient(
               begin: Alignment.topCenter,
               end: Alignment.bottomCenter,
               colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
             ),
          ),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomLeft,
          child: Text(
            city,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
