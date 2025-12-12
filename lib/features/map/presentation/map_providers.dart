import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/map/data/map_repository.dart';
import 'package:travel_hackathon/features/map/data/mock_map_repository.dart';
import 'package:travel_hackathon/features/map/domain/destination_pin_model.dart';

import 'package:travel_hackathon/core/services/api_service_provider.dart';
import 'package:travel_hackathon/features/map/data/api_map_repository.dart';

// The Repository Provider (Swappable for Real implementation later)
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApiMapRepository(apiService);
});

// The state of pins currently visible
final mapPinsProvider = FutureProvider.family<List<DestinationPin>, double>((ref, radiusKm) async {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.getPinsInArea(12.9716, 77.5946, radiusKm);
});
