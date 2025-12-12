import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text('My Trips', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Booking"),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: PremiumTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: PremiumTheme.primary,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TripList(type: 'completed'),
          _TripList(type: 'cancelled'),
        ],
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final String type;
  const _TripList({required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'cancelled') {
        return Center(child: Text("No cancelled trips", style: GoogleFonts.dmSans(color: Colors.grey)));
    }

    // Hardcoded Data
    final trips = [
      {
        "title": "Vadodara & Bengaluru",
        "dates": "18 Oct - 26 Oct",
        "flights": "2 Flights",
        "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Lakshmi_Vilas_Palace_Vadodara_India.jpg", // Vadodara Palace (Full Res)
        "details": {
           "airline": "IndiGo",
           "flightNo": "6E-554",
           "depCity": "Bengaluru",
           "arrCity": "Vadodara",
           "depTime": "13:20",
           "arrTime": "15:25",
           "depDate": "Sat, 18 Oct 25",
           "arrDate": "Sat, 18 Oct 25",
           "bookingId": "NF782J"
        }
      },
      {
        "title": "Mumbai & Goa",
        "dates": "10 Sep - 15 Sep",
        "flights": "2 Flights",
        "bookingId": "AB123C",
        "image": "https://upload.wikimedia.org/wikipedia/commons/2/20/Gateway_of_India.jpg", // Mumbai (Full Res)
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _TripCard(data: trips[index]);
      },
    );
  }
}

class _TripCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _TripCard({required this.data});

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // MAIN CARD (Clickable)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomLeft: _expanded ? Radius.zero : const Radius.circular(24),
                bottomRight: _expanded ? Radius.zero : const Radius.circular(24)
            ),
            child: Stack(
              children: [
                // Background Image
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: _expanded ? Radius.zero : const Radius.circular(24),
                        bottomRight: _expanded ? Radius.zero : const Radius.circular(24)
                    ),
                    image: DecorationImage(
                      image: NetworkImage(widget.data['image']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                    ),
                  ),
                ),
                
                // Content Overlay
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.data['title'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.data['dates'], style: GoogleFonts.dmSans(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(widget.data['flights'], style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                
                // Status Pill
                Positioned(
                    top: 16, left: 16,
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text("Completed", style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ),

                // Arrow
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                    child: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // EXPANDED DETAILS
          AnimatedCrossFade(
            duration: 300.ms,
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: widget.data['details'] != null ? _buildDetails(widget.data['details']) : const Padding(padding: EdgeInsets.all(16), child: Text("No details available")),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildDetails(Map<String, dynamic> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: Colors.white,
           borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
            ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
             // Booking ID Clone
             Row(
                 children: [
                     CircleAvatar(
                         radius: 16, 
                         backgroundImage: const NetworkImage("https://upload.wikimedia.org/wikipedia/commons/1/15/Lakshmi_Vilas_Palace_Vadodara_India.jpg"), // Small thumbnail
                     ),
                     const SizedBox(width: 8),
                     Text("Booking ID: ${details['bookingId']}", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                 ],
             ),
             const SizedBox(height: 16),
             
             // Flight Info Card
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                ),
                child: Column(
                    children: [
                        // Header
                        Row(
                            children: [
                                const Icon(Icons.flight_takeoff, color: PremiumTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(details['airline'] ?? "Airline", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text("Mandeepsinh", style: GoogleFonts.dmSans(color: Colors.grey)), 
                            ],
                        ),
                        const Divider(height: 24),
                        // Path
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                _CityTime(city: details['depCity'], time: details['depTime'], date: details['depDate'], alignLeft: true),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                _CityTime(city: details['arrCity'], time: details['arrTime'], date: details['arrDate'], alignLeft: false),
                            ],
                        ),
                        const SizedBox(height: 16),
                        // Actions
                        Row(
                            children: [
                                Expanded(child: OutlinedButton(onPressed: (){}, child: const Text("Invoice"))),
                                const SizedBox(width: 12),
                                Expanded(child: ElevatedButton(onPressed: (){}, child: const Text("View Details"))),
                            ],
                        )
                    ],
                ),
            ),
             
             
        ],
      ),
    );
  }
}

class _CityTime extends StatelessWidget {
    final String city;
    final String time;
    final String date;
    final bool alignLeft;

    const _CityTime({required this.city, required this.time, required this.date, required this.alignLeft});

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
                Text(city, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(time, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 24)),
                Text(date, style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
            ],
        );
    }
}
