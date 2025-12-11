import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:intl/intl.dart';

class EventsScreen extends ConsumerWidget {
  final String city;

  const EventsScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsForCityProvider(city));

    return Scaffold(
      appBar: AppBar(
        title: Text('Explore $city'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: eventsAsync.when(
        data: (events) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(event.description),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM d, h:mm a').format(event.eventDate)),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${event.participantIds.length}/${event.maxParticipants} joined'),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // In a real app, logic for "Request to Join" vs "Join"
                    // For demo, we assume they are accepted and go to Chat
                    context.push('/chat/${event.id.replaceAll('event_', 'chat_')}');
                  },
                  child: const Text('Join'),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // TODO: Create Event
        label: const Text('New Event'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
