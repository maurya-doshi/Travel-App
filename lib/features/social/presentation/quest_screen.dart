import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/social/domain/quest_model.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuestDiscoveryScreen extends ConsumerWidget {
  const QuestDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(allQuestsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cultural Quests', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: questsAsync.when(
        data: (quests) {
          if (quests.isEmpty) {
            return const Center(child: Text("No quests available yet."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return _QuestCard(quest: quest);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;

  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quests/${quest.city}'), // We'll add this route
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(_getCityImage(quest.city)),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: PremiumTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      quest.reward,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quest.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        quest.city,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '${quest.steps.length} Stops',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  String _getCityImage(String city) {
    // Placeholder logic - ideally from DB or Unsplash
    switch (city.toLowerCase()) {
      case 'mumbai': return 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?q=80&w=600&auto=format&fit=crop';
      case 'delhi': return 'https://images.unsplash.com/photo-1587474260584-136574528615?q=80&w=600&auto=format&fit=crop';
      case 'bangalore': return 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?q=80&w=600&auto=format&fit=crop';
      case 'jaipur': return 'https://images.unsplash.com/photo-1477587458883-47145ed94245?q=80&w=600&auto=format&fit=crop';
      case 'goa': return 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?q=80&w=600&auto=format&fit=crop';
      default: return 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?q=80&w=600&auto=format&fit=crop';
    }
  }
}
