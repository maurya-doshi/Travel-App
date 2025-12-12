import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:travel_hackathon/features/discovery/domain/quest_model.dart';
import 'package:travel_hackathon/core/services/api_service_provider.dart';

// Riverpod Provider
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApiDiscoveryRepository(apiService);
});

abstract class DiscoveryRepository {
  Future<List<QuestModel>> fetchQuests(String city, {String? userId});
  Future<int> completeQuest(String questId, String userId);
}

class ApiDiscoveryRepository implements DiscoveryRepository {
  final ApiService _apiService;

  ApiDiscoveryRepository(this._apiService);

  @override
  Future<List<QuestModel>> fetchQuests(String city, {String? userId}) async {
    final response = await _apiService.get('/quests?city=$city&userId=${userId ?? ""}');
    return (response as List).map((e) => QuestModel.fromJson(e)).toList();
  }

  @override
  Future<int> completeQuest(String questId, String userId) async {
    final response = await _apiService.post('/quests/$questId/complete', {
      'userId': userId,
    });
    return response['pointsAwarded'] ?? 0;
  }
}
