import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // For BackdropFilter

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty) {
        throw Exception('Please fill all fields');
      }

      // Call Auth Repository
      final user = await ref.read(authRepositoryProvider).register(email, password, name);
      
      // Update Global User State
      ref.read(currentUserProvider.notifier).state = user.uid;

      if (mounted) {
        context.go('/'); // Go to Map
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      ref.read(currentUserProvider.notifier).state = user.uid;
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Auth Error: $e'),
            behavior: SnackBarBehavior.floating,
             backgroundColor: Colors.redAccent,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Minimalist Header
              Text(
                'Sign Up',
                textAlign: TextAlign.left,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                ),
              ).animate().fade().slideY(begin: -0.2),
              
              const SizedBox(height: 8),
              
              Text(
                'Join the community of explorers.',
                textAlign: TextAlign.left,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 48),

              // 2. Clean Input Fields
              _MinimalistTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'John Doe',
                delay: 300.ms,
              ),
              const SizedBox(height: 20),
               _MinimalistTextField(
                 controller: _emailController,
                 label: 'Email',
                 hint: 'hello@example.com',
                 delay: 400.ms,
               ),
              const SizedBox(height: 20),
               _MinimalistTextField(
                 controller: _passwordController,
                 label: 'Password',
                 hint: '••••••••',
                 obscureText: true,
                 delay: 500.ms,
               ),

              const SizedBox(height: 40),

              // 3. Action Buttons
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : ElevatedButton(
                      onPressed: _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Premium Black
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100), // Full Pill
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fade(delay: 600.ms).scale(),

              const SizedBox(height: 24),

              Center(
                child: Text("or", style: GoogleFonts.lato(color: Colors.grey[400])).animate().fade(delay: 700.ms),
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                  height: 24,
                  loadingBuilder: (c, child, l) => l == null ? child : const Icon(Icons.g_mobiledata),
                  errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata),
                ),
                label: Text(
                  'Continue with Google', 
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ).animate().fade(delay: 800.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimalistTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final Duration delay;

  const _MinimalistTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    ).animate().fade(delay: delay).slideX(begin: -0.1);
  }
}
