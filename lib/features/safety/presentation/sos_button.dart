import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/discovery/presentation/discovery_providers.dart';
import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A red SOS button that triggers an emergency alert.
/// Uses the simulated user location from `userLocationProvider`.
class SosButton extends ConsumerWidget {
  const SosButton({super.key});

  Future<void> _triggerSOS(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Trigger SOS?'),
          ],
        ),
        content: const Text(
          'This will:\n\n'
          '• Dial emergency services (112)\n'
          '• Send your location to emergency contacts\n\n'
          'Only use in a real emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('TRIGGER SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Get user info
    final userId = ref.read(currentUserProvider);
    final userLoc = ref.read(userLocationProvider);

    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    // 1. Send SOS to backend
    try {
      final api = ApiService();
      final result = await api.post('/safety/sos', {
        'userId': userId,
        'latitude': userLoc.latitude,
        'longitude': userLoc.longitude,
        'type': 'emergency',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS sent! ${result['contactsNotified']} contacts notified.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('SOS backend error: $e');
    }

    // 2. Dial emergency services
    final Uri phoneUri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _triggerSOS(context, ref),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.shield, color: Colors.white, size: 26),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms),
    );
  }
}
