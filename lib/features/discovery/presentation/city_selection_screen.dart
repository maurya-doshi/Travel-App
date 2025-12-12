import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CitySelectionScreen extends StatelessWidget {
  const CitySelectionScreen({super.key});

  final List<Map<String, String>> cities = const [
    {
      'name': 'Bangalore',
      'image': 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'Mumbai',
      'image': 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'Paris',
      'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'New York',
      'image': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'Tokyo',
      'image': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'London',
      'image': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&q=80&w=600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light airy background
      appBar: AppBar(
        title: Text(
          'Destinations',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Header
         SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Where to next?',
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3436),
                    ),
                  ).animate().fade().slideX(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Select a city to explore local events.',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ).animate().fade(delay: 200.ms),
                ],
              ),
            ),
          ),

          // Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Taller cards for cinematic look
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final city = cities[index];
                  return GestureDetector(
                    onTap: () {
                       context.push('/explore/events?city=${city['name']}');
                    },
                    child: _CityCard(city: city, index: index),
                  );
                },
                childCount: cities.length,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom spacer
        ],
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  final Map<String, String> city;
  final int index;

  const _CityCard({required this.city, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Hero(
            tag: 'city_img_${city['name']}',
            child: Image.network(
              city['image']!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: Colors.grey[200]);
              },
            ).animate().shimmer(duration: 1.seconds, delay: 500.ms), // Subtle shimmer on load
          ),
          
          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.5, 1.0],
              ),
            ),
          ),
          
          // Text Content
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city['name']!,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                  ),
                  Container(
                    height: 2,
                    width: 40,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                       color: const Color(0xFFFF6B6B), // Active Color
                       borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (100 * index).ms).fade().slideY(begin: 0.2, curve: Curves.easeOutBack);
  }
}
