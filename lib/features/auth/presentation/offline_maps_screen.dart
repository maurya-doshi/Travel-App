import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class OfflineMapsScreen extends StatelessWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded Downloads
    final downloads = [
      {
        "name": "Bangalore - Central",
        "size": "45 MB",
        "date": "Expires in 29 days",
        "progress": 1.0, 
      },
      {
        "name": "Mysore City",
        "size": "22 MB",
        "date": "Expires in 30 days",
        "progress": 1.0,
      },
      {
        "name": "Goa (North)",
        "size": "150 MB",
        "date": "Downloading...",
        "progress": 0.6,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text('Offline Maps', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
            IconButton(onPressed: (){}, icon: const Icon(Icons.settings_outlined, color: Colors.black))
        ],
      ),
      body: Column(
        children: [
            // Header Info
            Container(
                padding: const EdgeInsets.all(20),
                color: Colors.grey[50],
                child: Row(
                    children: [
                        const Icon(Icons.cloud_download_outlined, size: 32, color: Colors.black54),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Text(
                                "Maps stored on your device can be used without an internet connection.",
                                style: GoogleFonts.dmSans(color: Colors.black54, fontSize: 13),
                            ),
                        )
                    ],
                ),
            ),
            
            Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                         final item = downloads[index];
                         final isDownloading = (item['progress'] as double) < 1.0;

                         return ListTile(
                             contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                             leading: Container(
                                 width: 50, height: 50,
                                 decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                                 child: Center(
                                     child: isDownloading 
                                        ? CircularProgressIndicator(value: item['progress'] as double, strokeWidth: 3)
                                        : const Icon(Icons.map, color: Colors.blue),
                                 ),
                             ),
                             title: Text(item['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                             subtitle: Text(isDownloading ? "${(item['progress'] as double)*100}% Downloaded" : "${item['size']} • ${item['date']}", style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
                             trailing: IconButton(
                                 icon: const Icon(Icons.more_vert, color: Colors.grey),
                                 onPressed: (){},
                             ),
                         ).animate().fadeIn(delay: (100*index).ms);
                    },
                ),
            ),
            
            Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                        onPressed: (){},
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text("Select your own map"),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                    ),
                ),
            ),
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}
