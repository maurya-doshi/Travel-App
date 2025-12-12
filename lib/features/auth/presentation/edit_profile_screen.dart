import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emergencyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    
    // Listen for update success/error
    ref.listen<AsyncValue<void>>(profileControllerProvider, (prev, state) {
      if (state.hasError) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
      } else if (!state.isLoading && !state.hasError && prev?.isLoading == true) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully!')));
         if (mounted && context.canPop()) {
            context.pop();
         }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text('Edit Profile', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error loading profile: $err")),
        data: (user) {
          if (user != null) {
              // Pre-fill controllers if empty (first load)
              if (_emailController.text.isEmpty && user.email.isNotEmpty) _emailController.text = user.email;
              if (_phoneController.text.isEmpty && user.phoneNumber != null) _phoneController.text = user.phoneNumber!;
              if (_emergencyController.text.isEmpty && user.emergencyContact != null) _emergencyController.text = user.emergencyContact!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Change
                Stack(
                  children: [
                     CircleAvatar(
                       radius: 50,
                       backgroundColor: Colors.grey[200],
                       backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : const NetworkImage("https://i.pravatar.cc/300"),
                       child: user?.photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                     ),
                     Positioned(
                       bottom: 0,
                       right: 0,
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: const BoxDecoration(
                           color: PremiumTheme.primary,
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                       ),
                     ),
                  ],
                ),
                const SizedBox(height: 32),

                // Fields - Order: Phone, Emergency, Email, Password
                _buildTextField("Phone Number", "Enter phone number", controller: _phoneController),
                const SizedBox(height: 20),
                _buildTextField("Emergency Contact No.", "Enter emergency contact", controller: _emergencyController),
                const SizedBox(height: 20),
                _buildTextField("Email Address", "Enter email address", controller: _emailController),
                const SizedBox(height: 20),

                _buildTextField(
                  "Change Password", 
                  "••••••••", 
                  isPassword: true, 
                  controller: _passwordController,
                  hint: "Enter to change password"
                ),

                const SizedBox(height: 80), // Space for FAB
              ],
            ).animate().fadeIn(duration: 400.ms),
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Moves FAB above taskbar
        child: FloatingActionButton.extended(
            onPressed: () {
                final user = userAsync.value;
                if (user != null) {
                    final updatedUser = user.copyWith(
                        email: _emailController.text,
                        phoneNumber: _phoneController.text,
                        emergencyContact: _emergencyController.text,
                    );
                    
                    ref.read(profileControllerProvider.notifier).updateProfile(
                        updatedUser, 
                        password: _passwordController.text.isEmpty ? null : _passwordController.text
                    );
                }
            },
            backgroundColor: PremiumTheme.primary,
            icon: ref.watch(profileControllerProvider).isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check, color: Colors.white),
            label: Text("Save", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String placeholder, {bool isPassword = false, TextEditingController? controller, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint ?? placeholder,
            hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
