import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _cityController = TextEditingController(text: 'Bangalore'); // Default
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _requiresApproval = false;
  bool _isFlexible = false;
  bool _isLoading = false;

  Future<void> _create() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => _isLoading = true);
    
    // Combine Date and Time
    final eventDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final event = TravelEvent(
      id: '', // Backend generates ID
      city: _cityController.text,
      title: _titleController.text,
      eventDate: eventDate,
      isDateFlexible: _isFlexible,
      creatorId: currentUser,
      requiresApproval: _requiresApproval,
      participantIds: [currentUser],
    );

    try {
      await ref.read(socialRepositoryProvider).createEvent(event);
      if (mounted) {
        // Updated redirect to the new events route
        context.go('/explore/events?city=${_cityController.text}');
        // ignore: unused_result
        ref.refresh(eventsForCityProvider(_cityController.text));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, 
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6A1B9A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6A1B9A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Host an Experience', style: GoogleFonts.oswald(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Text
            Text(
              "Let's create something memorable.",
              style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
            ).animate().fade().slideY(begin: 0.2),
            
            const SizedBox(height: 32),
            
            // 1. WHAT
            _SectionHeader(title: 'THE BASICS', icon: Icons.info_outline, delay: 100),
            const SizedBox(height: 16),
            _CustomTextField(
              controller: _titleController, 
              label: 'Give it a name', 
              hint: 'e.g. Sunset Yoga at Cubbon Park',
              delay: 200,
            ),
            const SizedBox(height: 16),
             _CustomTextField(
              controller: _cityController, 
              label: 'Where is it happening?', 
              hint: 'City Name',
              icon: Icons.location_on_outlined,
              delay: 300,
            ),
            
            const SizedBox(height: 32),

            // 2. WHEN
            _SectionHeader(title: 'DATE & TIME', icon: Icons.calendar_today_outlined, delay: 400),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateTimeCard(
                    label: 'Date', 
                    value: DateFormat('MMM d, y').format(_selectedDate), 
                    icon: Icons.calendar_month, 
                    onTap: _pickDate,
                    delay: 500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateTimeCard(
                    label: 'Time', 
                    value: _selectedTime.format(context), 
                    icon: Icons.access_time, 
                    onTap: _pickTime,
                    delay: 600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 3. SETTINGS
             _SectionHeader(title: 'SETTINGS', icon: Icons.tune, delay: 700),
             const SizedBox(height: 16),
             _SwitchCard(
               title: 'Moderated Entry', 
               subtitle: 'You approve who joins.', 
               value: _requiresApproval, 
               onChanged: (v) => setState(() => _requiresApproval = v),
               delay: 800,
             ),
             const SizedBox(height: 12),
             _SwitchCard(
               title: 'Flexible Schedule', 
               subtitle: 'Date can be discussed in chat.', 
               value: _isFlexible, 
               onChanged: (v) => setState(() => _isFlexible = v),
               delay: 900,
             ),

            const SizedBox(height: 48),

            // SUBMIT
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: const Color(0xFF6A1B9A).withOpacity(0.4),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('PUBLISH EVENT', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              ),
            ).animate(delay: 1.seconds).scale(curve: Curves.easeOutBack),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- Local Components ---

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int delay;

  const _SectionHeader({required this.title, required this.icon, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.5)),
      ],
    ).animate(delay: delay.ms).fadeIn().slideX(begin: -0.2);
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final int delay;

  const _CustomTextField({required this.controller, required this.label, required this.hint, this.icon, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50], // Very light grey
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: GoogleFonts.lato(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
        ),
      ),
    ).animate(delay: delay.ms).fadeIn().slideY(begin: 0.2);
  }
}

class _DateTimeCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final int delay;

  const _DateTimeCard({required this.label, required this.value, required this.icon, required this.onTap, required this.delay});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5), // Light purple tint
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6A1B9A), size: 20),
            const SizedBox(height: 12),
            Text(label.toUpperCase(), style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFFAB47BC), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.oswald(fontSize: 18, color: const Color(0xFF4A148C), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ).animate(delay: delay.ms).scale();
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final int delay;

  const _SwitchCard({required this.title, required this.subtitle, required this.value, required this.onChanged, required this.delay});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value, 
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600])),
      activeColor: const Color(0xFF6A1B9A),
    ).animate(delay: delay.ms).fadeIn();
  }
}
