import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (user) {
           final name = user?.displayName ?? "Traveler";
           final points = user?.explorerPoints ?? 0;
           // Derive level from points (simple logic: 1000 pts per level)
           final level = (points / 1000).floor() + 1;
           final nextLevel = (level * 1000);
           final progress = (points % 1000) / 1000;

           return Stack(
            children: [
              // Background gradient
             Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                     Color(0xFF6A11CB), // Purple
                     Color(0xFF2575FC), // Blue
                  ], 
                ),
              ),
              height: 480, // Increased to cover stats card
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                           // Actions Row (Rating + Share)
                           Row(
                             children: [
                               // Rating Pill
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.2),
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(color: Colors.white.withOpacity(0.3)),
                                 ),
                                 child: Row(
                                   children: [
                                     const Icon(Icons.star, color: Colors.amber, size: 14),
                                     const SizedBox(width: 4),
                                     Text("4.8", style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                   ],
                                 ),
                               ),
                               const SizedBox(width: 12),
                               
                               // Share Button
                               InkWell(
                                 onTap: () {
                                    // Share logic
                                 },
                                 borderRadius: BorderRadius.circular(20),
                                 child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle
                                    ),
                                    child: const Icon(Icons.share, color: Colors.white, size: 20),
                                 ),
                               ),
                             ],
                           ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Info
                    Column(
                      children: [
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                            child: user?.photoUrl == null ? const Icon(Icons.person, size: 50, color: PremiumTheme.primary) : null,
                          ),
                        ).animate().scale(),
                        
                        const SizedBox(height: 16),
                        
                        Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("Level $level Explorer", style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
                        
                        const SizedBox(height: 24),
                        
                        // Stats Card (Glassmorphism)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceAround,
                             children: [
                                const _StatItem(label: "World Rank", value: "#142"), // Hardcoded for now
                                Container(width: 1, height: 40, color: Colors.white24),
                                const _StatItem(label: "Trips", value: "24"),       // Hardcoded for now
                                Container(width: 1, height: 40, color: Colors.white24),
                                _StatItem(label: "XP Points", value: "$points"),
                             ],
                          ),
                        ).animate().slideY(begin: 0.2, end: 0),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                  
                  // Menu Section
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             // XP Progress
                             Text("Next Level Progress", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                             const SizedBox(height: 12),
                             ClipRRect(
                               borderRadius: BorderRadius.circular(10),
                               child: LinearProgressIndicator(
                                 value: progress, 
                                 minHeight: 8,
                                 backgroundColor: Colors.grey[200],
                                 valueColor: const AlwaysStoppedAnimation(Color(0xFF2575FC)),
                               ),
                             ),
                             const SizedBox(height: 8),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text("$points / $nextLevel XP", style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
                                 Text("Level ${level+1}", style: GoogleFonts.dmSans(color: const Color(0xFF2575FC), fontWeight: FontWeight.bold, fontSize: 12)),
                               ],
                             ),
                             
                             const SizedBox(height: 32),
                             
                             // Menu Items
                             _ProfileMenuTile(
                                icon: Icons.edit_outlined, 
                                title: "Edit Profile", 
                                subtitle: "Personal info, password",
                                onTap: () => context.push('/profile/edit'),
                             ),
                             _ProfileMenuTile(
                                icon: Icons.history_edu_outlined, 
                                title: "Trip History", 
                                subtitle: "Past adventures",
                                onTap: () => context.go('/profile/trips'),
                             ),
                             _ProfileMenuTile(
                                icon: Icons.favorite_border, 
                                title: "Favorites", 
                                subtitle: "Your pinned locations",
                                onTap: () => context.go('/profile/favorites'),
                             ),
                             _ProfileMenuTile(
                                icon: Icons.map_outlined, 
                                title: "Offline Maps", 
                                subtitle: "Downloaded areas",
                                onTap: () => context.go('/profile/offline-maps'),
                             ),
                             
                             const SizedBox(height: 80), // Space for FAB
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
           ],
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Moves FAB above taskbar
        child: FloatingActionButton.extended(
          onPressed: () {
            // Clear session logic
             ref.read(currentUserProvider.notifier).state = null;
             context.go('/auth');
          },
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.logout, size: 20),
          label: Text("Log Out", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7B66FF).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PremiumTheme.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: PremiumTheme.primary, size: 22),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.dmSans(color: Colors.grey[500], fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    ).animate().slideX(begin: 0.1, duration: 400.ms).fadeIn();
  }
}
