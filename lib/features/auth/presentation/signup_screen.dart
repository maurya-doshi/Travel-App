import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/auth/presentation/otp_verification_screen.dart';
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

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }

      // Step 1: Send OTP first (Signup Flow)
      final otpResponse = await ref.read(authRepositoryProvider).sendOtp(email); // isLogin false by default

      if (!otpResponse.success) {
         throw Exception(otpResponse.message);
      }
      
      // Step 2: Navigate to Verify Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: email,
              otpHint: otpResponse.otp,
              displayName: name,
              password: password, // Pass password to save after verification
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOtpLogin() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final otpResponse = await ref.read(authRepositoryProvider).sendOtp(email);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: email,
              displayName: name.isNotEmpty ? name : null,
              otpHint: otpResponse.otp, // For hackathon demo
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A00E0), // Deep Purple
                    Color(0xFF8E2DE2), // Bright Violet
                  ],
                ),
              ),
              child: Stack(
                children: [
                   // Decorative Circles for Premium Feel
                   Positioned(
                     top: -100,
                     right: -100,
                     child: Container(
                       width: 300,
                       height: 300,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         color: Colors.white.withOpacity(0.1),
                       ),
                     ),
                   ),
                   Positioned(
                     bottom: -50,
                     left: -50,
                     child: Container(
                       width: 200,
                       height: 200,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         color: Colors.black.withOpacity(0.05),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ).animate().fade().slideY(begin: -0.2),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Begin your journey here',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fade(delay: 200.ms),

                        const SizedBox(height: 48),

                        _GlassTextField(
                          controller: _nameController,
                          icon: Icons.person_outline,
                          hintText: 'Full Name',
                          delay: 300.ms,
                        ),
                        const SizedBox(height: 16),
                        _GlassTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hintText: 'Email Address',
                          delay: 400.ms,
                        ),
                        const SizedBox(height: 16),
                        _GlassTextField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          hintText: 'Password',
                          obscureText: true,
                          delay: 500.ms,
                        ),

                        const SizedBox(height: 32),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.white))
                            : ElevatedButton(
                                onPressed: _handleSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6A1B9A),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Create Account',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ).animate().fade(delay: 600.ms).scale(),

                        const SizedBox(height: 24),

                        Row(children: [
                          Expanded(child: Divider(color: Colors.white24)),
                        ]).animate().fade(delay: 700.ms),

                        const SizedBox(height: 24),

                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: GoogleFonts.lato(color: Colors.white70),
                              children: [
                                TextSpan(
                                  text: "Login",
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: 800.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText;
  final Duration delay;

  const _GlassTextField({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Corrected visibility
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
           BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.lato(color: Colors.black87), // Dark Text
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20), // Dark Icon
          hintText: hintText,
          hintStyle: GoogleFonts.lato(color: Colors.black54), // Dark Hint
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    ).animate().fade(delay: delay).slideX(begin: -0.1);
  }
}
