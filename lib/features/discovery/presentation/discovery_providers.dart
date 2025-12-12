import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/discovery/data/discovery_repository.dart';
import 'package:travel_hackathon/features/discovery/domain/quest_model.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';

// Fetch Quests for a City
final questsProvider = FutureProvider.family<List<QuestModel>, String>((ref, city) async {
  final repository = ref.watch(discoveryRepositoryProvider);
  final userId = ref.watch(currentUserProvider);
  return repository.fetchQuests(city, userId: userId);
});

// User Location Provider (Simulated for validation)
class UserLocationState {
  final double latitude;
  final double longitude;
  UserLocationState(this.latitude, this.longitude);
}

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  UserLocationNotifier() : super(UserLocationState(12.9716, 77.5946)); // Default BLR

  void setLocation(double lat, double lng) {
    state = UserLocationState(lat, lng);
  }
}

final userLocationProvider = StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  return UserLocationNotifier();
});
