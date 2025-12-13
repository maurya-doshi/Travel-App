import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/core/constants/city_constants.dart';

class CitySelectionScreen extends StatelessWidget {
  const CitySelectionScreen({super.key});

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
                itemCount: kSupportedCities.length,
                itemBuilder: (context, index) {
                  final city = kSupportedCities[index];
                  return GestureDetector(
                    onTap: () {
                       context.push('/bulletin');
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
