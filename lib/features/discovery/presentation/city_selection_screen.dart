import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';

class CitySelectionScreen extends StatelessWidget {
  const CitySelectionScreen({super.key});

  final List<Map<String, dynamic>> cities = const [
    {
      'name': 'Bangalore',
      'country': 'India',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'Mumbai',
      'country': 'India',
      'rating': 4.7,
      'image': 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'Paris',
      'country': 'France',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'New York',
      'country': 'USA',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'Tokyo',
      'country': 'Japan',
      'rating': 5.0,
      'image': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&q=80&w=600',
    },
    {
      'name': 'London',
      'country': 'UK',
      'rating': 4.7,
      'image': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&q=80&w=600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: PremiumTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Next Trip',
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn().slideX(),
                ],
              ),
            ),
            
            // Carousel
            Expanded(
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.75),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return GestureDetector(
                    onTap: () {
                       context.push('/explore/events?city=${city['name']}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: _ParallaxCityCard(city: city, index: index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 100), // Space for Floating Nav
          ],
        ),
      ),
    );
  }
}

class _ParallaxCityCard extends StatelessWidget {
  final Map<String, dynamic> city;
  final int index;

  const _ParallaxCityCard({required this.city, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(
            city['image']!,
            fit: BoxFit.cover,
          ),
          
          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1.0],
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            city['rating'].toString(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  city['name']!,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
                Text(
                  city['country']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: const Icon(Icons.arrow_forward, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }
}
