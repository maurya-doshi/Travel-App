import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current user ID (or full user object if we had it loaded)
    final uid = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.oswald(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
             // 1. Avatar Section
             Center(
               child: Stack(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.grey[300]!, width: 2),
                     ),
                     child: CircleAvatar(
                       radius: 60,
                       backgroundColor: Colors.grey[100],
                       child: Icon(Icons.person, size: 60, color: Colors.grey[400]),
                     ),
                   ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                   Positioned(
                     bottom: 0,
                     right: 0,
                     child: Container(
                       padding: const EdgeInsets.all(10),
                       decoration: const BoxDecoration(
                         color: Colors.black, // Premium Black
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                     ),
                   ),
                 ],
               ),
             ),
             
             const SizedBox(height: 24),
             
             // 2. Identity
             Text(
               uid ?? 'Guest Traveler',
               style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
             ).animate().fade().slideY(begin: 0.2),
             const SizedBox(height: 8),
             Text(
               'Explorer Level 1',
               style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
             ).animate().fade(delay: 100.ms),

             const SizedBox(height: 32),
             
             // 3. Stats Row
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFFF5F7FA),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: const [
                   _StatItem(label: 'Trips', value: '4'),
                   _StatItem(label: 'Photos', value: '12'),
                   _StatItem(label: 'Reviews', value: '8'),
                 ],
               ),
             ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

             const SizedBox(height: 32),
             
             // 4. Menu options
             const _ProfileMenuItem(icon: Icons.favorite_border, title: 'Favorites', delay: 300),
             const _ProfileMenuItem(icon: Icons.history, title: 'Trip History', delay: 400),
             const _ProfileMenuItem(icon: Icons.payment, title: 'Payment Methods', delay: 500),
             const SizedBox(height: 24),
             const Divider(),
             const SizedBox(height: 24),
             
             // 5. Logout
             SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    // clear session
                    ref.read(currentUserProvider.notifier).state = null;
                    // go to signup
                    context.go('/signup');
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text('Log Out', style: GoogleFonts.lato(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
             ).animate(delay: 600.ms).fade(),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int delay;

  const _ProfileMenuItem({required this.icon, required this.title, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 20),
              const SizedBox(width: 16),
              Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    ).animate(delay: delay.ms).slideX(begin: 0.1).fade();
  }
}
