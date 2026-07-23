// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Role Selection Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — selectRole() preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_system.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  UserRole? _tempSelectedRole;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: AegisMotion.normal);
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: AegisMotion.decelerate);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: AegisMotion.decelerate));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AegisSpacing.xl),

                  // ── AegisRx wordmark + tagline ────────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AegisColors.primarySurface,
                          borderRadius: BorderRadius.circular(AegisRadius.sm),
                          border: Border.all(color: AegisColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: AegisColors.primary, size: 20),
                      ),
                      const SizedBox(width: AegisSpacing.sm),
                      Text(
                        'AegisRx',
                        style: AegisTypography.headlineSmall.copyWith(
                          color: AegisColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AegisSpacing.xl),

                  Text(
                    'Welcome.\nWho are you today?',
                    style: AegisTypography.displaySmall.copyWith(
                      color: AegisColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  Text(
                    'Select your clinical role to enter the secure portal.',
                    style: AegisTypography.bodyMedium.copyWith(
                      color: AegisColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.lg),

                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildRoleCard(
                          role: UserRole.patient,
                          title: 'Patient',
                          subtitle: 'Unlock your health vault.',
                          description:
                              'Manage prescriptions, safety risk dashboard, and sharing consent tokens.',
                          icon: Icons.person_outline_rounded,
                          accentColor: AegisColors.patientAccent,
                          surfaceColor: AegisColors.primarySurface,
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        _buildRoleCard(
                          role: UserRole.doctor,
                          title: 'Doctor',
                          subtitle: 'Clinical AI-powered console.',
                          description:
                              'Review records, run CDSS audits, and cryptographically sign prescriptions.',
                          icon: Icons.medical_services_outlined,
                          accentColor: AegisColors.doctorAccent,
                          surfaceColor: AegisColors.secondarySurface,
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        _buildRoleCard(
                          role: UserRole.pharmacy,
                          title: 'Pharmacist',
                          subtitle: 'Token verification & dispense.',
                          description:
                              'Verify prescription tokens, decrypt signatures, and register dispensations.',
                          icon: Icons.local_pharmacy_outlined,
                          accentColor: AegisColors.pharmacyAccent,
                          surfaceColor: AegisColors.tertiarySurface,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.base),

                  // ── Continue CTA ───────────────────────────────
                  AnimatedOpacity(
                    opacity: _tempSelectedRole != null ? 1.0 : 0.45,
                    duration: AegisMotion.moderate,
                    child: SizedBox(
                      width: double.infinity,
                      height: AegisTokens.btnHeight,
                      child: ElevatedButton(
                        onPressed: _tempSelectedRole == null
                            ? null
                            : () {
                                // ── BUSINESS LOGIC UNCHANGED ──
                                Provider.of<AppState>(context, listen: false)
                                    .selectRole(_tempSelectedRole!);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AegisColors.primary,
                          foregroundColor: AegisColors.onPrimary,
                          disabledBackgroundColor: AegisColors.primarySurface,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                          textStyle: AegisTypography.labelLarge,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _tempSelectedRole != null
                                  ? 'Continue as ${_tempSelectedRole!.name[0].toUpperCase()}${_tempSelectedRole!.name.substring(1)}'
                                  : 'Select a role to continue',
                            ),
                            if (_tempSelectedRole != null) ...[
                              const SizedBox(width: AegisSpacing.sm),
                              const Icon(Icons.arrow_forward_rounded, size: AegisIconSize.sm),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.safeBottom),
                ],
              ),
            ),
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
    required Color accentColor,
    required Color surfaceColor,
  }) {
    final isSelected = _tempSelectedRole == role;

    return AnimatedContainer(
      duration: AegisMotion.moderate,
      curve: AegisMotion.standard,
      decoration: BoxDecoration(
        color: isSelected ? surfaceColor : AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(
          color: isSelected ? accentColor : AegisColors.border,
          width: isSelected ? AegisBorders.thick : AegisBorders.thin,
        ),
        boxShadow: isSelected ? AegisShadows.md : AegisShadows.sm,
      ),
      child: InkWell(
        onTap: () => setState(() => _tempSelectedRole = role),
        borderRadius: AegisRadius.card,
        child: Padding(
          padding: const EdgeInsets.all(AegisSpacing.base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              AnimatedContainer(
                duration: AegisMotion.moderate,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : AegisColors.surfaceDim,
                  borderRadius: BorderRadius.circular(AegisRadius.sm),
                ),
                child: Icon(
                  icon,
                  size: AegisIconSize.lg,
                  color: isSelected ? Colors.white : AegisColors.textSecondary,
                ),
              ),
              const SizedBox(width: AegisSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AegisTypography.titleLarge.copyWith(
                            color: AegisColors.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: AegisSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AegisSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: AegisRadius.chip,
                            ),
                            child: Text(
                              'SELECTED',
                              style: AegisTypography.labelCaps.copyWith(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AegisSpacing.xs),
                    Text(
                      subtitle,
                      style: AegisTypography.titleSmall.copyWith(
                        color: isSelected ? accentColor : AegisColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AegisSpacing.xs),
                    Text(
                      description,
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
