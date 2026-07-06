import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../shared/widgets/neon_card.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _tempSelectedRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Welcome to AegisRx',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to use AegisRx.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildRoleCard(
                      role: UserRole.patient,
                      title: 'Patient',
                      subtitle: 'Unlock your health vault.',
                      description: 'Manage your prescriptions, safety risk index dashboard, and sharing consent tokens.',
                      icon: Icons.person,
                      activeColor: const Color(0xFF4F46E5), // Sovereign Indigo
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      role: UserRole.doctor,
                      title: 'Doctor',
                      subtitle: 'Clinical console with AI safety audits.',
                      description: 'Review patient records, run automated drug-allergy audits, and cryptographically sign prescriptions.',
                      icon: Icons.local_hospital,
                      activeColor: const Color(0xFF0D9488), // Clinical Teal
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      role: UserRole.pharmacy,
                      title: 'Pharmacist',
                      subtitle: 'Token-based verification and dispense.',
                      description: 'Verify patient prescription tokens, decrypt cryptographic signatures, and register dispensations.',
                      icon: Icons.medication,
                      activeColor: const Color(0xFF3B82F6), // Royal Blue
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _tempSelectedRole == null
                      ? null
                      : () {
                          Provider.of<AppState>(context, listen: false)
                              .selectRole(_tempSelectedRole!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _tempSelectedRole == role;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tempSelectedRole = role;
        });
      },
      child: NeonCard(
        neonColor: isSelected ? activeColor : Colors.transparent,
        borderWidth: isSelected ? 2.0 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.1) : theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? activeColor : (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? activeColor : (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
