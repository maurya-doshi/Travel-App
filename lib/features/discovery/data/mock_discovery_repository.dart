import 'package:travel_hackathon/features/discovery/data/discovery_repository.dart';
import 'package:travel_hackathon/features/discovery/domain/discovery_models.dart';

class MockDiscoveryRepository implements DiscoveryRepository {
  final List<Hotel> _hotels = [
    const Hotel(
      id: 'h1',
      name: 'Grand Paris Hotel',
      address: '12 Rue de Rivoli',
      pricePerNight: 120.0,
      rating: 4.5,
      imageUrl: 'https://placehold.co/600x400/006C5B/FFF?text=Grand+Paris',
      lat: 48.8566,
      lng: 2.3522,
    ),
    const Hotel(
      id: 'h2',
      name: 'Backpacker Hostel',
      address: '5 Avenue Gare du Nord',
      pricePerNight: 25.0,
      rating: 4.0,
      imageUrl: 'https://placehold.co/600x400/e67e22/FFF?text=Hostel',
      lat: 48.8800,
      lng: 2.3550,
    ),
  ];

  final List<Quest> _quests = [
    Quest(
      id: 'q1',
      title: 'Selfie at Eiffel',
      description: 'Take a picture at the summit.',
      pointsReward: 50,
      type: 'check-in',
      targetLat: 48.8584,
      targetLng: 2.2945,
    ),
    Quest(
      id: 'q2',
      title: 'Find the Secret Cafe',
      description: 'Scan the QR code at Le Marais hidden spot.',
      pointsReward: 120,
      type: 'qr-code',
      secretCode: 'CAFE123',
    ),
  ];

  @override
  Future<List<Hotel>> getHotels(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _hotels;
  }

  @override
  Future<List<Quest>> getQuests(String pinId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _quests;
  }

  @override
  Future<int> completeQuest(String questId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 50; // Points earned
  }
}
