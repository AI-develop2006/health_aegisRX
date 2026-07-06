import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  bool _biometricUnlock = false;

  void _showComingSoon(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: 'Sora')),
        content: const Text('This feature is coming soon in a future release.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final secondaryAccent = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Settings', style: TextStyle(fontFamily: 'Sora')),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Section Profile
          _buildSectionHeader('Profile'),
          const SizedBox(height: 8),
          NeonCard(
            neonColor: primaryAccent,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline, color: primaryAccent),
                  title: const Text(
                    'Personal details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon('Personal Details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Security
          _buildSectionHeader('Security'),
          const SizedBox(height: 8),
          NeonCard(
            neonColor: secondaryAccent,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline, color: secondaryAccent),
                  title: const Text(
                    'Change PIN',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon('Change PIN'),
                ),
                const Divider(color: Colors.white10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(Icons.fingerprint, color: secondaryAccent),
                  title: const Text(
                    'Biometric unlock',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  value: _biometricUnlock,
                  onChanged: (val) {
                    setState(() {
                      _biometricUnlock = val;
                    });
                  },
                  activeColor: secondaryAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section About
          _buildSectionHeader('About'),
          const SizedBox(height: 8),
          NeonCard(
            neonColor: Colors.blueGrey,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
                  title: const Text(
                    'Terms of Use',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon('Terms of Use'),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blueGrey),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon('Privacy Policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Sign out button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                appState.clearSession();
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: const Text(
                'Sign out',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }
}
