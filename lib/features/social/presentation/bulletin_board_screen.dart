import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_hackathon/core/constants/city_constants.dart';
import 'package:travel_hackathon/features/discovery/presentation/widgets/city_search_sheet.dart';

class BulletinBoardScreen extends ConsumerStatefulWidget {
  final String? initialCity;
  const BulletinBoardScreen({super.key, this.initialCity});

  @override
  ConsumerState<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends ConsumerState<BulletinBoardScreen> {
  late String _selectedCity;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity ?? 'All';
    // Auto-refresh every 10 seconds for live updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(eventsForCityProvider(_selectedCity));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsForCityProvider(_selectedCity));
    final userId = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Bulletin Board', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: PremiumTheme.primary, size: 28),
            onPressed: () => context.push('/create-event'),
          ),
        ],
      ),
      body: Column(
        children: [
          // City Filter - Search Bar Style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => CitySearchSheet(
                    onCitySelected: (city) {
                      Navigator.pop(context);
                      setState(() => _selectedCity = city);
                    },
                  ),
                );
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: PremiumTheme.primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCity == 'All' ? 'Search all cities...' : _selectedCity,
                        style: GoogleFonts.dmSans(
                          color: _selectedCity == 'All' ? Colors.grey[600] : Colors.black87,
                          fontSize: 16,
                          fontWeight: _selectedCity == 'All' ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedCity != 'All')
                      GestureDetector(
                        onTap: () => setState(() => _selectedCity = 'All'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: PremiumTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune, color: Colors.white, size: 16),
                      ),
                  ],
                ),
              ),
            ).animate().slideY(begin: -0.5, duration: 400.ms, curve: Curves.easeOut),
          ),
          
          // Events List
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                // Filter to only show 'open' status events (or events without status for backward compat)
                final openEvents = events.where((e) => 
                  e.status == null || e.status == 'open'
                ).toList();
                
                if (openEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No open events', style: GoogleFonts.dmSans(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.push('/create-event'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create one!'),
                        ),
                      ],
                    ).animate().fade(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(eventsForCityProvider(_selectedCity));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Extra bottom for navbar
                    itemCount: openEvents.length,
                    itemBuilder: (context, index) {
                      final event = openEvents[index];
                      final isCreator = event.creatorId == userId;
                      final isParticipant = event.participantIds.contains(userId);
                      final isPending = event.pendingRequestIds.contains(userId);

                      return _BulletinCard(
                        event: event,
                        isCreator: isCreator,
                        isParticipant: isParticipant,
                        isPending: isPending,
                        userId: userId,
                        index: index,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading events: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletinCard extends ConsumerWidget {
  final dynamic event;
  final bool isCreator;
  final bool isParticipant;
  final bool isPending;
  final String? userId;
  final int index;

  const _BulletinCard({
    required this.event,
    required this.isCreator,
    required this.isParticipant,
    required this.isPending,
    required this.userId,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PremiumTheme.primary.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PremiumTheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(event.city, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                if (event.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(event.category!, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ),
                const Spacer(),
                if (event.requiresApproval)
                  const Icon(Icons.lock, size: 16, color: Colors.orange),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (event.isDateFlexible) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Flexible', style: TextStyle(color: Colors.blue[700], fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${isCreator ? "You" : event.creatorName ?? "Unknown"}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text('${event.participantIds.length} going', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                if (isCreator)
                  TextButton(
                    onPressed: () => context.push('/chat/chat_${event.id}'),
                    child: const Text('Open Chat'),
                  )
                else if (isParticipant)
                  TextButton.icon(
                    onPressed: () => context.push('/chat/chat_${event.id}'),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Chat'),
                  )
                else if (isPending)
                  TextButton(
                    onPressed: null,
                    child: Text('Pending...', style: TextStyle(color: Colors.orange[700])),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (userId == null) return;
                      await ref.read(socialRepositoryProvider).joinEvent(event.id, userId!);
                      ref.invalidate(eventsForCityProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(event.requiresApproval ? 'Request sent!' : 'Joined!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(event.requiresApproval ? 'Request to Join' : 'Join'),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
  }
}
