// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Home Shell Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — IndexedStack, _currentIndex, all routes preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/design_system.dart';
import 'main_screen_patient/patient_dashboard_screen.dart';
import 'main_screen_patient/patient_history_screen.dart';
import 'patient_share_screen.dart';
import 'main_screen_patient/patient_settings_screen.dart';

class PatientHomeShellScreen extends StatefulWidget {
  const PatientHomeShellScreen({super.key});

  @override
  State<PatientHomeShellScreen> createState() => _PatientHomeShellScreenState();
}

class _PatientHomeShellScreenState extends State<PatientHomeShellScreen> {
  int _currentIndex = 0;

  // UNCHANGED — same screens, same order
  final List<Widget> _screens = [
    const PatientDashboardScreen(),
    const PatientHistoryScreen(),
    const PatientShareScreen(),
    const PatientSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AegisColors.surface,
          border: const Border(
            top: BorderSide(color: AegisColors.border, width: 1.0),
          ),
          boxShadow: AegisShadows.md,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AegisSpacing.base,
              vertical: AegisSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'Vault',
                  index: 1,
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  icon: Icons.qr_code_outlined,
                  activeIcon: Icons.qr_code_rounded,
                  label: 'Share',
                  index: 2,
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  icon: Icons.manage_accounts_outlined,
                  activeIcon: Icons.manage_accounts_rounded,
                  label: 'Settings',
                  index: 3,
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom nav item with pill indicator ───────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AegisMotion.moderate,
        curve: AegisMotion.decelerate,
        padding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.md,
          vertical: AegisSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AegisColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AegisRadius.chip,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AegisMotion.fast,
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: AegisIconSize.base,
                color: isActive
                    ? AegisColors.primary
                    : AegisColors.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AegisTypography.labelSmall.copyWith(
                color: isActive
                    ? AegisColors.primary
                    : AegisColors.textTertiary,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
