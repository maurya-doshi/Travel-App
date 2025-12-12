import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/auth/presentation/otp_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // New
  bool _isLoading = false;
  bool _isPasswordLogin = true; // Default to Password

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isPasswordLogin) {
        // PASSWORD LOGIN
        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          _showError('Please enter password');
           setState(() => _isLoading = false);
          return;
        }
        
        final session = await ref.read(authRepositoryProvider).login(email, password);
        // Verify success implies valid session
        ref.read(currentUserProvider.notifier).state = session.user.uid;
        if (mounted) context.go('/map'); // Or '/' which redirects to map

      } else {
        // OTP LOGIN
        final otpResponse = await ref.read(authRepositoryProvider).sendOtp(email, isLogin: true);

        if (!otpResponse.success) {
           throw Exception(otpResponse.message);
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                email: email,
                otpHint: otpResponse.otp,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showError(String message) {
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
  }

  // NOTE: Removed old _handleOtpLogin since logic is merged above

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background (Reused)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A00E0), 
                    Color(0xFF8E2DE2), 
                  ],
                ),
              ),
              child: Stack(
                children: [
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
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fade().slideY(begin: -0.2),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Login to continue your adventure',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ).animate().fade(delay: 200.ms),

                        const SizedBox(height: 48),

                        // Toggle Options
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             _LoginOptionTab(
                               title: 'Password',
                               isSelected: _isPasswordLogin,
                               onTap: () => setState(() => _isPasswordLogin = true),
                             ),
                             const SizedBox(width: 16),
                             _LoginOptionTab(
                               title: 'OTP',
                               isSelected: !_isPasswordLogin,
                               onTap: () => setState(() => _isPasswordLogin = false),
                             ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _GlassTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hintText: 'Email Address',
                          delay: 300.ms,
                        ),

                        if (_isPasswordLogin) ...[
                          const SizedBox(height: 16),
                          _GlassTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hintText: 'Password',
                            obscureText: true,
                            delay: 400.ms,
                          ),
                        ],

                        const SizedBox(height: 32),

                         ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleLogin,
                          icon: Icon(_isPasswordLogin ? Icons.login : Icons.password, size: 24),
                          label: Text(
                            _isPasswordLogin ? 'Login' : 'Send OTP', 
                            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: const Color(0xFF6A1B9A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ).animate().fade(delay: 500.ms).slideY(begin: 0.2),

                        const SizedBox(height: 24),

                        Row(children: [
                          Expanded(child: Divider(color: Colors.white24)),
                        ]),

                        const SizedBox(height: 24),

                        TextButton(
                          onPressed: () => context.go('/signup'),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: GoogleFonts.lato(color: Colors.white70),
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: 600.ms),
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

class _LoginOptionTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoginOptionTab({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          title,
          style: GoogleFonts.lato(
            color: isSelected ? const Color(0xFF6A1B9A) : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
