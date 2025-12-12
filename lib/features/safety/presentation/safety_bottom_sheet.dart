import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/safety/data/safety_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyBottomSheet extends ConsumerStatefulWidget {
  final double currentLat;
  final double currentLng;

  const SafetyBottomSheet({
    super.key,
    required this.currentLat,
    required this.currentLng,
  });

  @override
  ConsumerState<SafetyBottomSheet> createState() => _SafetyBottomSheetState();
}

class _SafetyBottomSheetState extends ConsumerState<SafetyBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleEmergencyAction(String type) async {
    // 1. If Call Police, launch dialer
    if (type == 'call_police') {
      final Uri launchUri = Uri(scheme: 'tel', path: '100');
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
      return;
    }

    // 2. If Backend Alert, send API request
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider); // Using mock/real user from Auth
      final userId = user ?? 'anonymous_user';

      await ref.read(safetyRepositoryProvider).sendSosSignal(
        userId: userId,
        lat: widget.currentLat,
        lng: widget.currentLng,
        type: type,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert Sent! Help is on the way.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to send alert: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Safety Toolkit',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          // Option 1: Call Police
          _SafetyOption(
            icon: Icons.phone_in_talk,
            label: 'Call Local Police (100)',
            color: Colors.blue[50],
            textColor: Colors.blue[900]!,
            onTap: () => _handleEmergencyAction('call_police'),
          ),
          const SizedBox(height: 12),

          // Option 2: Share Location (SOS)
          _SafetyOption(
            icon: Icons.share_location,
            label: 'Share Live Location',
            color: Colors.red[50],
             textColor: Colors.red[900]!,
            onTap: () => _handleEmergencyAction('emergency'),
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          
           // Option 3: I feel unsafe
          _SafetyOption(
            icon: Icons.remove_red_eye,
            label: 'I feel uncomfortable',
            color: Colors.grey[100],
            textColor: Colors.black87,
            onTap: () => _handleEmergencyAction('uncomfortable'),
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SafetyOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color textColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _SafetyOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (isLoading) 
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(icon, color: textColor),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
