import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_hackathon/features/map/presentation/map_providers.dart';
import 'package:travel_hackathon/features/discovery/presentation/discovery_providers.dart';
import 'package:travel_hackathon/features/discovery/data/discovery_repository.dart';
import 'package:travel_hackathon/features/discovery/domain/quest_model.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/discovery/presentation/widgets/city_search_sheet.dart';
import 'package:travel_hackathon/core/services/city_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  void _unlockQuest(String questId) async {
    final userId = ref.read(currentUserProvider);
    if (userId == null) return;

    try {
      final points = await ref.read(discoveryRepositoryProvider).completeQuest(questId, userId);
      
      // Refresh list to update UI state
      ref.refresh(questsProvider('Bangalore'));

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _QuestCompleteDialog(points: points),
        );
      }
    } catch (e) {
      debugPrint("Quest unlock failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(mapPinsProvider(10.0));
    final userLocation = ref.watch(userLocationProvider);
    final userId = ref.watch(currentUserProvider);
    final activeQuestsAsync = userId != null 
        ? ref.watch(activeQuestsProvider(userId)) 
        : null;
    final hasActiveQuest = activeQuestsAsync?.valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          // 1. Full Screen Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(userLocation.latitude, userLocation.longitude), // Center on user
              initialZoom: 14.0,
              onTap: (_, point) {
                // Simulate User Movement
                ref.read(userLocationProvider.notifier).setLocation(point.latitude, point.longitude);
              },
            ),
            children: [
              // Styled Map Layer
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  PremiumTheme.primary.withOpacity(0.05), 
                  BlendMode.srcOver,
                ),
                child: TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.travel_hackathon',
                ),
              ),
              
              // Normal Pins Layer
              pinsAsync.when(
                data: (pins) => MarkerLayer(
                  markers: pins.map((pin) {
                    return Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 120,
                      height: 120,
                      child: GestureDetector(
                        onTap: () {
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

              // USER AVATAR LAYER
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(userLocation.latitude, userLocation.longitude),
                    width: 60,
                    height: 60,
                    child: const _UserAvatarMarker(),
                  ),
                ],
              ),
            ],
          ),

          // 2. Glassmorphism Header (Search)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CitySearchSheet(
                        onCitySelected: (city) async {
                          Navigator.pop(context);
                          // Fetch Coords
                          final coords = await CityService().getCityCoordinates(city);
                          if (coords != null) {
                            _mapController.move(LatLng(coords[0], coords[1]), 13.0);
                          }
                        },
                      ),
                    );
                  },
                  child: Container(
                    height: 50,
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
                          ),
                          child: const Icon(Icons.tune, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: -1, duration: 600.ms, curve: Curves.easeOutBack),

              ],
            ),
          ),
        ],
      ),
      
      // 4. FAB Area - Quest Button (if active) + Host Event
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quest FAB - only show if user has active quest
          if (hasActiveQuest)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  final activeQuest = activeQuestsAsync?.valueOrNull?.first;
                  if (activeQuest != null) {
                    context.push('/quests/${activeQuest.city}');
                  } else {
                    context.push('/quests');
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4F7C82), Color(0xFF2E5E63)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4F7C82).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.explore, color: Colors.white, size: 24),
                ),
              ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
            ),
          // Host Event FAB
          Container(
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
              backgroundColor: Colors.transparent, 
              elevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
              label: Text('Host Event', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                  context.push('/create-event');
              },
            ),
          ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

// --- WIDGETS ---

class _QuestMarker extends StatelessWidget {
  final QuestModel quest;
  const _QuestMarker({required this.quest});

  @override
  Widget build(BuildContext context) {
    // Gold Star for Quest
    // If completed, maybe dim it or add a checkmark
    return Column(
      children: [
         Icon(
            Icons.star,
            color: quest.isCompleted ? Colors.grey : const Color(0xFFFFD700), // Gold if active
            size: 40,
            shadows: [
              if (!quest.isCompleted)
                BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.6), blurRadius: 15, spreadRadius: 2)
            ],
         ).animate(onPlay: (c) => quest.isCompleted ? null : c.repeat(reverse: true))
          .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
         
         const SizedBox(height: 4),
         Container(
           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
           decoration: BoxDecoration(
             color: Colors.black54,
             borderRadius: BorderRadius.circular(8),
           ),
           child: Text(
             quest.points.toString(),
             style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
           ),
         )
      ],
    );
  }
}

class _UserAvatarMarker extends StatelessWidget {
  const _UserAvatarMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueAccent,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      child: const Icon(Icons.person, color: Colors.white),
    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
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
        SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PremiumTheme.primary.withOpacity(0.15),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
              
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [PremiumTheme.primary, PremiumTheme.secondary], // Use Theme
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
              
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFFF9F1C), shape: BoxShape.circle),
                  child: const SizedBox(width: 4, height: 4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
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

class _QuestCompleteDialog extends StatelessWidget {
  final int points;
  const _QuestCompleteDialog({required this.points});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withOpacity(0.2),
            ),
          ).animate().scale(duration: 1.seconds, curve: Curves.easeInOut),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                const SizedBox(height: 16),
                Text("QUEST COMPLETE!", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Text("You've discovered a famous location.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                Text("+$points Points", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber[700])),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Awesome!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Active Quest Step Marker for Home Map
class _ActiveQuestStepMarker extends StatelessWidget {
  final int stepNumber;
  final bool isCompleted;
  final String questTitle;

  const _ActiveQuestStepMarker({
    required this.stepNumber,
    required this.isCompleted,
    required this.questTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$questTitle - Step $stepNumber${isCompleted ? " ✓" : ""}',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600])
              : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: isCompleted 
                  ? Colors.green.withOpacity(0.4) 
                  : const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  '$stepNumber',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    ).animate().scale(delay: Duration(milliseconds: stepNumber * 50));
  }
}
