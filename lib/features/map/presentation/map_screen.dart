import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_hackathon/features/map/presentation/map_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // For BackdropFilter

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  // Default to Bangalore (MSRIT context)
  final _initialCenter = const LatLng(12.9716, 77.5946);
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Watch the pins provider (Loading/Error handling included)
    final pinsAsync = ref.watch(mapPinsProvider(10.0)); // 10km radius

    return Scaffold(
      extendBodyBehindAppBar: true, // Allow map to go behind status bar
      body: Stack(
        children: [
          // 1. Full Screen Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                // Future: Logic for dropping a NEW pin
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
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to Bulletin Board / Events
                          if (pin.city != null) {
                            context.push('/explore/events?city=${pin.city}');
                          }
                        },
                        child: _AnimatedMapMarker(
                           activeCount: pin.activeVisitorCount,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const MarkerLayer(markers: []), 
                error: (e, s) => const MarkerLayer(markers: []),
              ),
            ],
          ),

          // 2. Glassmorphism Header (Search/Context)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search destinations...',
                          style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 16),
                        ),
                      ),
                      Container(
                         padding: const EdgeInsets.all(8),
                         decoration: const BoxDecoration(
                           color: Color(0xFF6A1B9A), // Brand Purple
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.tune, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: -1, duration: 600.ms, curve: Curves.easeOutQuart),

          // 3. Floating User Stats / Context (Optional - keeping minimal)
        ],
      ),
      
      // 4. Premium FAB
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF8E2AA8)],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
             BoxShadow(color: const Color(0xFF6A1B9A).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent, // Use container gradient
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_location_alt, color: Colors.white),
          label: Text('Host Event', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () {
              context.push('/create-event');
          },
        ),
      ).animate().scale(delay: 500.ms),
    );
  }
}

class _AnimatedMapMarker extends StatelessWidget {
  final int activeCount;

  const _AnimatedMapMarker({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing Circle
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Effect
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds),
              
              // Core Pin
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFE05252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Label Pill
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
                '$activeCount active',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ).animate().fade(delay: 300.ms).slideY(begin: 0.5),
      ],
    );
  }
}
