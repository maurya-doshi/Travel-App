import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_hackathon/features/map/presentation/map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Default to Bangalore (MSRIT context)
  final _initialCenter = const LatLng(12.9716, 77.5946);

  @override
  Widget build(BuildContext context) {
    // Watch the pins provider (Loading/Error handling included)
    final pinsAsync = ref.watch(mapPinsProvider(10.0)); // 10km radius

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Map'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 13.0,
          onTap: (tapPosition, point) {
            // TODO: Logic for dropping a NEW pin
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.travel_hackathon',
          ),
          // Markers Layer
          pinsAsync.when(
            data: (pins) => MarkerLayer(
              markers: pins.map((pin) {
                return Marker(
                  point: LatLng(pin.latitude, pin.longitude),
                  width: 100,
                  height: 100,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to Bulletin Board
                      if (pin.city != null) {
                        context.push('/explore/events?city=${pin.city}');
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFE05252)], // Coral Gradient
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                               BoxShadow(
                                 color: Colors.black.withOpacity(0.3),
                                 blurRadius: 6,
                                 offset: const Offset(0, 3),
                               )
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.location_city, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people, size: 10, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${pin.activeVisitorCount} active',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const MarkerLayer(markers: []), 
            error: (e, s) {
              // Show error snackbar or handled internally
              return const MarkerLayer(markers: []);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Host'),
        onPressed: () {
            context.push('/create-event');
        },
      ),
    );
  }
}
