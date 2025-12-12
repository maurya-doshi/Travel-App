import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  void _onTap(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined), 
            selectedIcon: Icon(Icons.map), 
            label: 'Map'
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined), 
            selectedIcon: Icon(Icons.explore), 
            label: 'Explore'
          ),
           NavigationDestination(
            icon: Icon(Icons.person_outline), 
            selectedIcon: Icon(Icons.person), 
            label: 'Profile'
          ),
        ],
      ),
    );
  }
}
