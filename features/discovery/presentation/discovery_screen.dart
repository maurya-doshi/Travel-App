import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/discovery/presentation/discovery_providers.dart';

class DiscoveryScreen extends ConsumerWidget {
  final String city;

  const DiscoveryScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(hotelsProvider(city));
    final questsAsync = ref.watch(questsProvider(city));

    return Scaffold(
      appBar: AppBar(title: Text('Discover $city')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Available Quests'),
            SizedBox(
              height: 180,
              child: questsAsync.when(
                data: (quests) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    final quest = quests[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50], // Quest Color
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.stars, color: Colors.orange[700]),
                          const Spacer(),
                          Text(quest.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${quest.pointsReward} pts', style: TextStyle(color: Colors.orange[800])),
                        ],
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Social Stays'),
            hotelsAsync.when(
              data: (hotels) => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: hotels.length,
                itemBuilder: (context, index) {
                  final hotel = hotels[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                         width: 60, 
                         height: 60, 
                         color: Colors.grey[300], 
                         child: const Icon(Icons.hotel),
                      ),
                      title: Text(hotel.name),
                      subtitle: Text('\$${hotel.pricePerNight.toInt()}/night • ⭐ ${hotel.rating}'),
                      trailing: const Text('3 friends here', style: TextStyle(color: Colors.teal, fontSize: 10)),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load hotels')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
