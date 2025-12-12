import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EventsScreen extends ConsumerWidget {
  final String city;

  const EventsScreen({super.key, required this.city});

  // Helpers to get city image (duplicated from CitySelection for simplicity in this file scope)
  String _getCityImage(String cityName) {
     final map = {
       'Bangalore': 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?auto=format&fit=crop&q=80&w=800',
       'Mumbai': 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?auto=format&fit=crop&q=80&w=800',
       'Paris': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=800',
       'New York': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&q=80&w=800',
       'Tokyo': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&q=80&w=800',
       'London': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&q=80&w=800',
     };
     return map[cityName] ?? 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&q=80&w=800';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsForCityProvider(city));
    final cityImage = _getCityImage(city);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light airy bg
      body: CustomScrollView(
        slivers: [
          // 1. Cinematic Header
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                city, 
                style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, shadows: [const Shadow(color: Colors.black54, blurRadius: 4)]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    cityImage,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(color: Colors.grey[300]);
                    },
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: () {}),
              ),
            ],
          ),

          // 2. Events List
          eventsAsync.when(
            data: (events) {
               if (events.isEmpty) {
                 return SliverFillRemaining(
                   child: Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                         const SizedBox(height: 16),
                         Text('No events in $city yet.', style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 16)),
                         const SizedBox(height: 8),
                         OutlinedButton(
                           onPressed: () => context.push('/create-event'),
                           child: const Text('Be the first to host!'),
                         )
                       ],
                     ).animate().fadeIn(),
                   ),
                 );
               }

               return SliverPadding(
                 padding: const EdgeInsets.all(16),
                 sliver: SliverList(
                   delegate: SliverChildBuilderDelegate(
                     (context, index) {
                       final event = events[index];
                       return _EventCard(event: event, index: index);
                     },
                     childCount: events.length,
                   ),
                 ),
               );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom spacer for FAB
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-event'),
        label: Text('Host Event', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF6A1B9A), // Brand Purple
        foregroundColor: Colors.white,
      ).animate().scale(delay: 500.ms),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final TravelEvent event;
  final int index;

  const _EventCard({required this.event, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Detailed Check/Preview
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                    ),
                    if (event.requiresApproval)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                         child: const Text('Approval', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                       ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Info Row
                Row(
                  children: [
                     Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                     const SizedBox(width: 6),
                     Text(DateFormat('MMM d, h:mm a').format(event.eventDate), style: GoogleFonts.lato(color: Colors.grey[700], fontSize: 14)),
                     const SizedBox(width: 16),
                     Icon(Icons.people, size: 16, color: Colors.grey[600]),
                     const SizedBox(width: 6),
                     Text('${event.participantIds.length} joined', style: GoogleFonts.lato(color: Colors.grey[700], fontSize: 14)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Button (Full Width)
                SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final currentUser = ref.watch(currentUserProvider);
                      final userId = currentUser ?? 'test-user-1'; 
                      final isParticipant = event.participantIds.contains(userId);
                      final isPending = event.pendingRequestIds.contains(userId);

                      if (isParticipant) {
                         return OutlinedButton.icon(
                           icon: const Icon(Icons.chat_bubble_outline, size: 18),
                           label: const Text('Open Chat'),
                           style: OutlinedButton.styleFrom(
                             foregroundColor: Colors.green,
                             side: const BorderSide(color: Colors.green),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                           onPressed: () => context.push('/chat/${event.id.replaceAll('event_', 'chat_')}'),
                         );
                      }
                      
                      if (isPending) {
                          return Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
                            child: const Text('Request Pending', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                          );
                      }

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A), // Brand Purple
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          // Call API
                          await ref.read(socialRepositoryProvider).joinEvent(event.id, userId);
                          // Refresh List
                          // ignore: unused_result
                          ref.refresh(eventsForCityProvider(event.city)); // Optimistic update ideally
                          
                          if (!event.requiresApproval) {
                             if (context.mounted) {
                               context.push('/chat/${event.id.replaceAll('event_', 'chat_')}');
                             }
                          } else {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent! Waiting for approval.')));
                             }
                          }
                        },
                        child: Text(
                          event.requiresApproval ? 'Request to Join' : 'Join Now', 
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold)
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (100 * index).ms).slideX(begin: 0.2).fade();
  }
}
