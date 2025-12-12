import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded Favorites
    final favorites = [
      {
        "name": "Eiffel Tower",
        "location": "Paris, France",
        "rating": "4.8",
        "type": "Landmark",
        "image": "https://upload.wikimedia.org/wikipedia/commons/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg"
      },
      {
        "name": "Taj Mahal",
        "location": "Agra, India",
        "rating": "4.9",
        "type": "Historical",
        "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Taj_Mahal-03.jpg"
      },
      {
        "name": "Kyoto Ancient Temples",
        "location": "Kyoto, Japan",
        "rating": "4.7",
        "type": "Culture",
        "image": "https://upload.wikimedia.org/wikipedia/commons/2/25/Kinkaku-ji_20111124_122345.jpg"
      },
      {
        "name": "Santorini Sunsets",
        "location": "Santorini, Greece",
        "rating": "4.9",
        "type": "Nature",
        "image": "https://upload.wikimedia.org/wikipedia/commons/f/f6/Oia_Santorini_Greece.jpg"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text('Favorites', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final item = favorites[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  child: Image.network(
                    item['image']!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 120, height: 120, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(item['location']!, style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                          children: [
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: PremiumTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(item['type']!, style: GoogleFonts.dmSans(color: PremiumTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(" ${item['rating']}", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                    onPressed: (){}, 
                    icon: const Icon(Icons.favorite, color: Colors.redAccent)
                )
              ],
            ),
          ).animate().fadeIn(delay: (100 * index).ms).slideX();
        },
      ),
    );
  }
}
