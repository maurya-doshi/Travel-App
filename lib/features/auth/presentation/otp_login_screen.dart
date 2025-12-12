import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController(); // Hidden controller for PIN logic
  final FocusNode _otpFocusNode = FocusNode();

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _timer = 30;

  // Mock Logic
  final String _mockOtp = "123456";

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(email);
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _otpFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text;
    if (otp.length != 6) return;

    setState(() => _isLoading = true);
    
    try {
      final user = await ref.read(authRepositoryProvider).verifyOtp(_emailController.text.trim(), otp);

      // 1. Success! Create Session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid); 
      await prefs.setString('user_email', user.email);

      // 2. Update App State
      ref.read(currentUserProvider.notifier).state = user.uid;

      // 3. Navigate
      if (mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid Code or Expired: $e'), backgroundColor: Colors.red),
      );
      _otpController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Header
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PremiumTheme.textSecondary,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn().slideY(begin: -0.5),
              const SizedBox(height: 8),
              Text(
                _isOtpSent ? 'Verify It\'s You' : 'Let\'s Get Started',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 16),
              Text(
                _isOtpSent 
                  ? 'We sent a 6-digit code to ${_emailController.text}. Enter it below.' 
                  : 'Enter your email to continue. We will create an account for you if one doesn\'t exist.',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 48),

              // UI Transition between Email and OTP
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation),
                  child: child,
                )),
                child: _isOtpSent ? _buildOtpInput() : _buildEmailInput(),
              ),
              
              const Spacer(),
              
              Center(
                child: Text(
                  _isOtpSent ? "Didn't receive code? Resend in $_timer s" : "By continuing, you verify that you are not a robot 🤖",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      key: const ValueKey('email_input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(16),
             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
           ),
           child: TextField(
             controller: _emailController,
             decoration: InputDecoration(
               border: InputBorder.none,
               hintText: 'name@example.com',
               hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
               icon: const Icon(Icons.email_outlined, color: Colors.black,),
             ),
             style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
           ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
             padding: const EdgeInsets.symmetric(vertical: 20),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      key: const ValueKey('otp_input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hidden TextField for Input Handling
        SizedBox(
          height: 0,
          width: 0,
          child: TextField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (val) {
              setState(() {});
              if (val.length == 6) _verifyOtp();
            },
          ),
        ),
        
        // Custom PIN Boxes
        GestureDetector(
          onTap: () => _otpFocusNode.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final isFilled = _otpController.text.length > index;
              final isFocused = _otpController.text.length == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 60,
                decoration: BoxDecoration(
                  color: isFilled ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                alignment: Alignment.center,
                child: Text(
                  isFilled ? _otpController.text[index] : '',
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    color: isFilled ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
           style: ElevatedButton.styleFrom(
             backgroundColor: Colors.black,
             padding: const EdgeInsets.symmetric(vertical: 20),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: _isLoading 
             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
             : const Text('Verify & Login'),
        ),
        
        const SizedBox(height: 16),
        // Demo button removed
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _isOtpSent = false),
          child: Text("Change Email", style: TextStyle(color: PremiumTheme.textSecondary)),
        ),
      ],
    );
  }
}
