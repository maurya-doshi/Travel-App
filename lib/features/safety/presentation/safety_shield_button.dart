import 'package:flutter/material.dart';
import 'package:travel_hackathon/features/safety/presentation/safety_bottom_sheet.dart';

class SafetyShieldButton extends StatelessWidget {
  // Hardcoded current location for Hackathon MVP, 
  // in real app this comes from Geolocator stream
  final double currentLat; 
  final double currentLng;

  const SafetyShieldButton({
    super.key,
    this.currentLat = 12.9716, // Bangalore default
    this.currentLng = 77.5946,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'safety_shield',
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue[700],
      elevation: 4,
         shape: const CircleBorder(), // Explicit circle shape
        // Make it distinct from the main FAB
      child: const Icon(Icons.shield_outlined, size: 28),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => SafetyBottomSheet(
            currentLat: currentLat,
            currentLng: currentLng,
          ),
        );
      },
    );
  }
}
