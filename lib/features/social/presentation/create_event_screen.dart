import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/features/social/domain/travel_event_model.dart';

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
        ref.invalidate(eventsForCityProvider(_cityController.text));
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
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host an Experience')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Image Placeholder (or just a nice card)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.event_note, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            
            // FORM CARD
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Event Details", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'e.g. Sunset Hike, Food Walk',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                     TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DATE & TIME CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("When & Where", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.calendar_month, color: Colors.blue),
                      ),
                      title: Text(DateFormat('EEEE, MMMM d, y').format(_selectedDate)),
                      subtitle: const Text('Date'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickDate,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.access_time, color: Colors.orange),
                      ),
                      title: Text(_selectedTime.format(context)),
                      subtitle: const Text('Time'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // OPTIONS
            Card(
               child: Column(
                 children: [
                   SwitchListTile(
                    title: const Text('Moderated Entry'),
                    subtitle: const Text('Review requests before they join'),
                    secondary: const Icon(Icons.security),
                    value: _requiresApproval,
                    onChanged: (val) => setState(() => _requiresApproval = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Flexible Schedule'),
                    subtitle: const Text('Date/Time can be discussed'),
                    secondary: const Icon(Icons.shuffle),
                    value: _isFlexible,
                    onChanged: (val) => setState(() => _isFlexible = val),
                  ),
                 ],
               ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _create,
                icon: _isLoading ? const SizedBox() : const Icon(Icons.rocket_launch),
                label: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CREATE ADVENTURE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
