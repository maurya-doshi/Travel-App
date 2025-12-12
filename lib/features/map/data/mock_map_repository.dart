import 'package:travel_hackathon/features/map/data/map_repository.dart';
import 'package:travel_hackathon/features/map/domain/destination_pin_model.dart';
import 'package:uuid/uuid.dart';

class MockMapRepository implements MapRepository {
  final _uuid = const Uuid();

  // Fake Database
  final List<DestinationPin> _pins = [
    DestinationPin(
      id: 'pin_bangalore_1',
      city: 'Bangalore',
      name: 'Cubbon Park Meetup',
      latitude: 12.9716,
      longitude: 77.5946,
      activeVisitorCount: 142,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DestinationPin(
      id: 'pin_mumbai_1',
      city: 'Mumbai', 
      name: 'Gateway of India',
      latitude: 19.0760,
      longitude: 72.8777,
      activeVisitorCount: 98,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<DestinationPin>> getPinsInArea(double lat, double lng, double radiusKm) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simple mock logic: Return all pins (in real app, use Geo Hashing)
    return _pins;
  }

  @override
  Future<void> createPin(DestinationPin pin) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _pins.add(pin);
  }

  @override
  Stream<DestinationPin> watchPin(String pinId) {
    // Return a stream that emits the pin immediately
    final pin = _pins.firstWhere((p) => p.id == pinId);
    return Stream.value(pin);
  }
}
