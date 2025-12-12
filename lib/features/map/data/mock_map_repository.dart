import 'package:travel_hackathon/features/map/data/map_repository.dart';
import 'package:travel_hackathon/features/map/domain/destination_pin_model.dart';
import 'package:uuid/uuid.dart';

class MockMapRepository implements MapRepository {
  final _uuid = const Uuid();

  // Fake Database
  final List<DestinationPin> _pins = [
    DestinationPin(
      id: 'pin_paris_1',
      city: 'Paris',
      name: 'Eiffel Tower Meetup',
      latitude: 48.8584,
      longitude: 2.2945,

      activeVisitorCount: 124,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DestinationPin(
      id: 'pin_paris_2',
      city: 'Paris', 
      name: 'Louvre Art Walk',
      latitude: 48.8606,
      longitude: 2.3376,

      activeVisitorCount: 45,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    DestinationPin(
      id: 'pin_london_1',
      city: 'London',
      name: 'Big Ben Sightseeing',
      latitude: 51.5007,
      longitude: -0.1246,

      activeVisitorCount: 89,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
