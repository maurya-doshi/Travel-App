import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_hackathon/features/map/presentation/map_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:travel_hackathon/core/theme/premium_theme.dart';

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
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.travel_hackathon',
              ),
              
              // Markers Layer
              pinsAsync.when(
                data: (pins) => MarkerLayer(
                  markers: pins.map((pin) {
                    return Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 120,
                      height: 120,
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
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: PremiumTheme.primary.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                      style: GoogleFonts.dmSans(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                   Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: PremiumTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: PremiumTheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.tune, color: Colors.white, size: 16),
                   ),
                ],
              ),
            ).animate().slideY(begin: -1, duration: 600.ms, curve: Curves.easeOutBack),
          ),

          // 3. Floating User Stats / Context (Optional - keeping minimal)
        ],
      ),
      
      // 4. Premium FAB
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        decoration: BoxDecoration(
          gradient: PremiumTheme.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
             BoxShadow(color: PremiumTheme.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'map_fab',
          backgroundColor: Colors.transparent, // Use container gradient
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_location_alt, color: Colors.white),
          label: Text('Host Event', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () {
              context.push('/create-event');
          },
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
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
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Effect
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PremiumTheme.primary.withOpacity(0.15),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
              
              // Core Pin (Gradient)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA566FF), Color(0xFF7B66FF)], // Purple Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                     BoxShadow(color: PremiumTheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 24),
              ),
              
              // Notification Badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9F1C), // Orange structure
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 4, height: 4),
                ),
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
