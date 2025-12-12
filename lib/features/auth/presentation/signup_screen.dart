import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF8E24AA),
              Color(0xFFAB47BC),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: GoogleFonts.oswald(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: -0.5),
                  const SizedBox(height: 16),
                  Text(
                    'Join us on a new adventure!',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ).animate().fade(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: 48),
                  _buildTextField(
                    context,
                    controller: _nameController,
                    icon: Icons.person,
                    hintText: 'Name',
                  ).animate().fade(duration: 500.ms, delay: 400.ms).slideX(begin: -0.5),
                  const SizedBox(height: 24),
                  _buildTextField(
                    context,
                    controller: _emailController,
                    icon: Icons.email,
                    hintText: 'Email',
                  ).animate().fade(duration: 500.ms, delay: 600.ms).slideX(begin: 0.5),
                  const SizedBox(height: 24),
                  _buildTextField(
                    context,
                    controller: _passwordController,
                    icon: Icons.lock,
                    hintText: 'Password',
                    obscureText: true,
                  ).animate().fade(duration: 500.ms, delay: 800.ms).slideX(begin: -0.5),
                  const SizedBox(height: 48),
                  _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                    onPressed: _handleSignup,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF6A1B9A),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ).animate().fade(duration: 500.ms, delay: 1000.ms).scale(),
                  
                  const SizedBox(height: 16),
                  
                  // GOOGLE BUTTON
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: TextStyle(color: Colors.white70)),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ]),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.white),
                      label: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
                       style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                    ),
                  ).animate().fade(duration: 500.ms, delay: 1200.ms).moveY(begin: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      ref.read(currentUserProvider.notifier).state = user.uid;
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Auth Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(BuildContext context, {
    required TextEditingController controller,
    required IconData icon, 
    required String hintText, 
    bool obscureText = false
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.lato(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.white,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.lato(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}
