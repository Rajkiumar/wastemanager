import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import '../services/theme_service.dart';
import '../services/accessibility_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfileService _profileService;
  late Future<Map<String, dynamic>> _preferencesFuture;
  final AccessibilityService _accessibilityService = AccessibilityService();

  String _selectedLanguage = 'en';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _highContrastMode = false;

  @override
  void initState() {
    super.initState();
    _profileService = UserProfileService();
    _preferencesFuture = _loadPreferences();
    _loadAccessibilitySettings();
  }

  Future<void> _loadAccessibilitySettings() async {
    await _accessibilityService.init();
    if (mounted) {
      setState(() {
        _highContrastMode = _accessibilityService.isHighContrastEnabled();
      });
    }
  }

  Future<Map<String, dynamic>> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final profile = await _profileService.getUserProfileByUid(user.uid);
    if (profile != null) {
      setState(() {
        _selectedLanguage = profile.preferences['language'] ?? 'en';
        _notificationsEnabled =
            profile.preferences['notificationsEnabled'] ?? true;
        _darkModeEnabled = profile.preferences['darkMode'] ?? false;
      });
      ThemeController.instance.setDarkMode(_darkModeEnabled);
      return profile.preferences;
    }
    return {};
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _profileService.updatePreferences({
        'language': _selectedLanguage,
        'notificationsEnabled': _notificationsEnabled,
        'darkMode': _darkModeEnabled,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _preferencesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notifications Section
                _buildSectionTitle('Notifications'),
                _buildToggleTile(
                  title: 'Enable Notifications',
                  subtitle: 'Get alerts for pickup reminders and updates',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _savePreferences();
                  },
                ),
                const Divider(height: 24),

                // Theme Section
                _buildSectionTitle('Appearance'),
                _buildToggleTile(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme for better visibility',
                  value: _darkModeEnabled,
                  onChanged: (value) async {
                    setState(() => _darkModeEnabled = value);
                    await ThemeController.instance.setDarkMode(value);
                    await _savePreferences();
                  },
                ),
                const SizedBox(height: 12),
                _buildToggleTile(
                  title: 'High Contrast Mode',
                  subtitle: 'Increase color contrast for better visibility',
                  value: _highContrastMode,
                  onChanged: (value) async {
                    setState(() => _highContrastMode = value);
                    await _accessibilityService.setHighContrast(value);
                  },
                ),
                const Divider(height: 24),

                // Language Section
                _buildSectionTitle('Language'),
                _buildDropdownTile(
                  title: 'Select Language',
                  subtitle: 'Choose your preferred language',
                  value: _selectedLanguage,
                  items: {'en': 'English'},
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value);
                    _savePreferences();
                  },
                ),
                const Divider(height: 24),

                // Account Section
                _buildSectionTitle('Account'),
                _buildActionTile(
                  icon: Icons.email_outlined,
                  title: 'Change Email',
                  subtitle: 'Update your email address',
                  onTap: _showChangeEmailDialog,
                ),
                const SizedBox(height: 8),
                _buildActionTile(
                  icon: Icons.lock_outlined,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 24),

                // Privacy Section
                _buildSectionTitle('Privacy & Data'),
                _buildActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  onTap: _showPrivacyPolicy,
                ),
                const SizedBox(height: 8),
                _buildActionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  onTap: _showDeleteAccountDialog,
                  isDestructive: true,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.green,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required Map<String, String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: items.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            underline: const SizedBox(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.green),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: const Text('Email change feature coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We value your privacy. Your email and profile data are stored securely.'
            'We never sell your data.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && passwordController.text.isNotEmpty) {
                  await user.updatePassword(passwordController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Delete user profile from Firestore
                  await _profileService.updateProfile(user.uid, {
                    'deletedAt': DateTime.now(),
                  });
                  // Delete user from Firebase Auth
                  await user.delete();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
