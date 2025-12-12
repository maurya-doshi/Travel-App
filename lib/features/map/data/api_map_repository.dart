import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:travel_hackathon/features/map/data/map_repository.dart';
import 'package:travel_hackathon/features/map/domain/destination_pin_model.dart';

class ApiMapRepository implements MapRepository {
  final ApiService _apiService;

  ApiMapRepository(this._apiService);

  @override
  Future<List<DestinationPin>> getPinsInArea(double lat, double lng, double radiusKm) async {
    // Note: The backend currently returns ALL pins via /pins. 
    // In a real app we'd pass lat/lng/radius to the backend.
    final List<dynamic> data = await _apiService.get('/pins');
    
    // Backend returns proper fields now
    return data.map((json) {
       return DestinationPin.fromJson(json); 
    }).toList();
  }

  @override
  Future<void> createPin(DestinationPin pin) async {
    await _apiService.post('/pins', {
      'city': pin.city,
      'type': 'attraction', // default or from pin
      'activeVisitorCount': pin.activeVisitorCount
    });
  }

  @override
  Stream<DestinationPin> watchPin(String pinId) {
    // Sse or polling could go here. For now, just return a single future as stream?
    // Or just unimplemented as the backend is REST.
    throw UnimplementedError('Realtime updates not yet implemented');
  }
}
