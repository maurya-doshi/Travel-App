import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Assuming PremiumTheme is defined, if not, replace with Colors.black
import 'package:travel_hackathon/core/theme/premium_theme.dart'; 

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important: Lets map extend behind the bar
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 40, right: 40, bottom: 20),
          child: Container(
            height: 70, // Slightly more compact
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), // Dark Graphite
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Index 0: Map / Explore
                _buildNavItem(context, 0, Icons.map_outlined, Icons.map_rounded),
                
                // Index 1: Events / Social
                _buildNavItem(context, 1, Icons.calendar_month_outlined, Icons.calendar_month),
                
                // Index 2: Profile / Settings
                _buildNavItem(context, 2, Icons.person_outline, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon) {
    final isSelected = navigationShell.currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque, // Ensures clicks are caught
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 26,
        ).animate(target: isSelected ? 1 : 0)
         .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms)
         .shake(hz: 4, curve: Curves.easeInOutCubic, duration: 200.ms), // Subtle shake on tap
      ),
    );
  }
}