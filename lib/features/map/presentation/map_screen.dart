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
        actions: [
           IconButton(
             icon: const Icon(Icons.person),
             onPressed: () {}, // TODO: Profile
           )
        ],
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
                  width: 60,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to Bulletin Board
                      if (pin.city != null) {
                        context.push('/events?city=${pin.city}');
                      }
                    },
                    child: Column(
                      children: [
                        const Icon(Icons.location_on, color: Colors.teal, size: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [BoxShadow(blurRadius: 2)],
                          ),
                          child: Text(
                            pin.activeVisitorCount.toString(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_location_alt),
        onPressed: () {
            // TODO: Drop pin UI
        },
      ),
    );
  }
}
