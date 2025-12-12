import 'package:travel_hackathon/features/map/data/map_repository.dart';
import 'package:travel_hackathon/features/map/domain/destination_pin_model.dart';
import 'package:uuid/uuid.dart';

class MockMapRepository implements MapRepository {
  final _uuid = const Uuid();

  // Fake Database
  final List<DestinationPin> _pins = [
    DestinationPin(
      id: 'pin_cubbon',
      city: 'Bangalore',
      name: 'Cubbon Park Meetup',
      latitude: 12.9760,
      longitude: 77.5920,
      activeVisitorCount: 142,
      createdAt: DateTime.now(),
    ),
    DestinationPin(
       id: 'pin_indiranagar',
       city: 'Bangalore',
       name: 'Indiranagar Food Walk',
       latitude: 12.9719, 
       longitude: 77.6412,
       activeVisitorCount: 89,
       createdAt: DateTime.now(),
    ),
    DestinationPin(
       id: 'pin_koramangala',
       city: 'Bangalore',
       name: 'Koramangala Startups',
       latitude: 12.9352, 
       longitude: 77.6245,
       activeVisitorCount: 230,
       createdAt: DateTime.now(),
    ),
    DestinationPin(
       id: 'pin_lalbagh',
       city: 'Bangalore',
       name: 'Lalbagh Flower Show',
       latitude: 12.9507, 
       longitude: 77.5848,
       activeVisitorCount: 312,
       createdAt: DateTime.now(),
    ),
    DestinationPin(
       id: 'pin_mg_road',
       city: 'Bangalore',
       name: 'MG Road Pub Crawl',
       latitude: 12.9749, 
       longitude: 77.6094,
       activeVisitorCount: 156,
       createdAt: DateTime.now(),
    ),
    DestinationPin(
       id: 'pin_malleshwaram',
       city: 'Bangalore',
       name: 'Malleshwaram Temple',
       latitude: 13.0068, 
       longitude: 77.5615,
       activeVisitorCount: 45,
       createdAt: DateTime.now(),
    ),
    DestinationPin(
       id: 'pin_hsr',
       city: 'Bangalore',
       name: 'HSR Layout Yoga',
       latitude: 12.9121, 
       longitude: 77.6446,
       activeVisitorCount: 67,
       createdAt: DateTime.now(),
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
