import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Provides a simulated user location that can be updated via long-press on the map.
/// This is used instead of real GPS for hackathon demo purposes.
final simulationLocationProvider = StateProvider<LatLng>((ref) {
  // Default to Mumbai Gateway of India
  return const LatLng(18.9220, 72.8347);
});

/// Helper to check if user is "at" a location (within threshold)
bool isUserNearLocation(LatLng userLoc, LatLng targetLoc, {double thresholdMeters = 200}) {
  const distance = Distance();
  final meters = distance.as(LengthUnit.Meter, userLoc, targetLoc);
  return meters <= thresholdMeters;
}
