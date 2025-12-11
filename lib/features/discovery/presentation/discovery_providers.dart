import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/discovery/data/discovery_repository.dart';
import 'package:travel_hackathon/features/discovery/data/mock_discovery_repository.dart';
import 'package:travel_hackathon/features/discovery/domain/discovery_models.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return MockDiscoveryRepository();
});

final hotelsProvider = FutureProvider.family<List<Hotel>, String>((ref, city) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.getHotels(0, 0); // Mock ignoring logic
});

final questsProvider = FutureProvider.family<List<Quest>, String>((ref, pinId) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.getQuests(pinId);
});
