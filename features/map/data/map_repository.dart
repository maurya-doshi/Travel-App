import 'package:travel_hackathon/features/map/domain/destination_pin_model.dart';

abstract class MapRepository {
  Future<List<DestinationPin>> getPinsInArea(double lat, double lng, double radiusKm);
  Future<void> createPin(DestinationPin pin);
  Stream<DestinationPin> watchPin(String pinId);
}
