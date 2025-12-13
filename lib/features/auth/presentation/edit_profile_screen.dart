import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:travel_hackathon/core/services/api_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null) return;

    try {
      final api = ApiService();
      // Load user data
      final userData = await api.get('/users/$userId');
      _nameController.text = userData['displayName'] ?? '';
      _phoneController.text = userData['phoneNumber'] ?? '';

      // Load emergency contacts
      final contacts = await api.get('/safety/contacts/$userId');
      setState(() {
        _emergencyContacts = List<Map<String, dynamic>>.from(contacts ?? []);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final api = ApiService();
      await api.put('/users/$userId', {
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addEmergencyContact() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null) return;

    final name = _contactNameController.text.trim();
    final phone = _contactPhoneController.text.trim();
    final email = _contactEmailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact name is required')),
      );
      return;
    }

    try {
      final api = ApiService();
      final result = await api.post('/safety/contacts', {
        'userId': userId,
        'name': name,
        'phone': phone,
        'email': email,
      });

      if (result['success'] == true) {
        _contactNameController.clear();
        _contactPhoneController.clear();
        _contactEmailController.clear();
        _loadProfile(); // Refresh list
      }
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  Future<void> _deleteContact(String id) async {
    try {
      final api = ApiService();
      await api.delete('/safety/contacts/$id');
      _loadProfile(); // Refresh list
    } catch (e) {
      debugPrint('Error deleting contact: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PremiumTheme.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildSection(
                    title: 'Personal Information',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Display Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Emergency Contacts Section
                  _buildSection(
                    title: 'Emergency Contacts',
                    subtitle: 'These people will be notified when you trigger SOS',
                    child: Column(
                      children: [
                        // Existing Contacts List
                        ..._emergencyContacts.map((contact) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: PremiumTheme.accent,
                            child: Text(
                              (contact['name'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(contact['name'] ?? 'Unknown'),
                          subtitle: Text(contact['email'] ?? contact['phone'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteContact(contact['id']),
                          ),
                        )),

                        const Divider(),

                        // Add New Contact Form
                        _buildTextField(
                          controller: _contactNameController,
                          label: 'Contact Name',
                          icon: Icons.person_add_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _contactPhoneController,
                          label: 'Contact Phone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _contactEmailController,
                          label: 'Contact Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _addEmergencyContact,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PremiumTheme.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Save Profile', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: PremiumTheme.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: PremiumTheme.textSecondary)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: PremiumTheme.primary),
        filled: true,
        fillColor: PremiumTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PremiumTheme.primary, width: 2),
        ),
      ),
    );
  }
}
