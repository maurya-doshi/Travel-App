import 'package:travel_hackathon/features/discovery/domain/discovery_models.dart';

abstract class DiscoveryRepository {
  Future<List<Hotel>> getHotels(double lat, double lng);
  Future<List<Quest>> getQuests(String pinId);
  Future<int> completeQuest(String questId, String userId);
}
