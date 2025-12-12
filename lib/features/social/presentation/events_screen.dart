import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EventsScreen extends ConsumerWidget {
  final String city;

  const EventsScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsForCityProvider(city));
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
                              city,
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
                          Text('Quiet in $city', style: Theme.of(context).textTheme.bodyMedium),
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

    return Container(
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
              
              if (isParticipant)
                OutlinedButton(
                  onPressed: () => context.push('/chat/${event.id.replaceAll('event_', 'chat_')}'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: Colors.green.shade300),
                  ),
                  child: const Text('Chat', style: TextStyle(color: Colors.green)),
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
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
