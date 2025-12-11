import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/map/data/map_repository.dart';
import 'package:travel_hackathon/features/map/data/mock_map_repository.dart';
import 'package:travel_hackathon/features/map/domain/destination_pin_model.dart';

// The Repository Provider (Swappable for Real implementation later)
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MockMapRepository();
});

// The state of pins currently visible
final mapPinsProvider = FutureProvider.family<List<DestinationPin>, double>((ref, radiusKm) async {
  final repository = ref.watch(mapRepositoryProvider);
  // Hardcoded Lat/Lng for mock (Paris Center)
  return repository.getPinsInArea(48.8566, 2.3522, radiusKm);
});
