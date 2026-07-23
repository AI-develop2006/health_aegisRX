// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Unlock Setup Screen (PIN + Biometric)
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — _savePin(), setSession(), setPin() preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';


class PatientUnlockSetupScreen extends StatefulWidget {
  const PatientUnlockSetupScreen({super.key});

  @override
  State<PatientUnlockSetupScreen> createState() => _PatientUnlockSetupScreenState();
}

class _PatientUnlockSetupScreenState extends State<PatientUnlockSetupScreen> {
  final _pinController        = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _useBiometrics  = false;
  bool _obscurePin     = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // ── BUSINESS LOGIC UNCHANGED ──────────────────────────────────────────────
  void _savePin() {
    final pin     = _pinController.text;
    final confirm = _confirmPinController.text;

    if (pin.length < 4 || pin.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be between 4 and 6 digits.')),
      );
      return;
    }

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match.')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final tokenToUse = appState.token ??
        (appState.useMockFrontend ? 'mock-jwt-token-patient-alex' : '');
    appState.setSessionAndPin(role: UserRole.patient, token: tokenToUse, pin: pin);
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: AppBar(
        backgroundColor: AegisColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: AegisIconSize.sm, color: AegisColors.textSecondary),
          onPressed: () =>
              appState.setPatientAuthState(PatientAuthState.secureSignIn),
        ),
        title: Text('Setup Security',
            style: AegisTypography.headlineMedium.copyWith(color: AegisColors.textPrimary)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.pagePadding,
          vertical: AegisSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header illustration ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AegisSpacing.lg),
              decoration: BoxDecoration(
                color: AegisColors.primarySurface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AegisColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: AegisColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.md),
                  Text(
                    'Secure This Device',
                    style: AegisTypography.titleLarge.copyWith(
                        color: AegisColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(
                    'Create a PIN to quickly unlock AegisRx on this device.',
                    style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AegisSpacing.lg),

            // ── PIN fields ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AegisSpacing.base),
              decoration: BoxDecoration(
                color: AegisColors.surface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.border),
                boxShadow: AegisShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AegisColors.primarySurface,
                          borderRadius: BorderRadius.circular(AegisRadius.sm),
                        ),
                        child: const Icon(Icons.pin_rounded,
                            size: AegisIconSize.sm, color: AegisColors.primary),
                      ),
                      const SizedBox(width: AegisSpacing.sm),
                      Text('Create PIN',
                          style: AegisTypography.titleSmall.copyWith(
                              color: AegisColors.textPrimary)),
                    ],
                  ),

                  const SizedBox(height: AegisSpacing.base),
                  const Divider(height: 1, color: AegisColors.border),
                  const SizedBox(height: AegisSpacing.base),

                  // PIN input
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: _obscurePin,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: AegisTypography.monoLarge.copyWith(
                      color: AegisColors.textPrimary,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Enter PIN (4–6 digits)',
                      labelStyle: AegisTypography.bodyMedium.copyWith(
                          color: AegisColors.textSecondary),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AegisColors.textTertiary, size: AegisIconSize.md),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AegisColors.textTertiary,
                          size: AegisIconSize.md,
                        ),
                        onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      ),
                      filled: true,
                      fillColor: AegisColors.background,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AegisRadius.input,
                        borderSide: const BorderSide(
                            color: AegisColors.border, width: AegisBorders.regular),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AegisRadius.input,
                        borderSide: const BorderSide(
                            color: AegisColors.primary, width: AegisBorders.regular),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AegisSpacing.inputPaddingH,
                        vertical: AegisSpacing.inputPaddingV,
                      ),
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.md),

                  // Confirm PIN input
                  TextField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: _obscureConfirm,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: AegisTypography.monoLarge.copyWith(
                      color: AegisColors.textPrimary,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Confirm PIN',
                      labelStyle: AegisTypography.bodyMedium.copyWith(
                          color: AegisColors.textSecondary),
                      prefixIcon: const Icon(Icons.lock_rounded,
                          color: AegisColors.textTertiary, size: AegisIconSize.md),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AegisColors.textTertiary,
                          size: AegisIconSize.md,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      filled: true,
                      fillColor: AegisColors.background,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AegisRadius.input,
                        borderSide: const BorderSide(
                            color: AegisColors.border, width: AegisBorders.regular),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AegisRadius.input,
                        borderSide: const BorderSide(
                            color: AegisColors.primary, width: AegisBorders.regular),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AegisSpacing.inputPaddingH,
                        vertical: AegisSpacing.inputPaddingV,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AegisSpacing.base),

            // ── Biometric toggle ───────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AegisColors.surface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.border),
                boxShadow: AegisShadows.sm,
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AegisSpacing.base,
                  vertical: AegisSpacing.xs,
                ),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _useBiometrics
                        ? AegisColors.primarySurface
                        : AegisColors.surfaceDim,
                    borderRadius: BorderRadius.circular(AegisRadius.sm),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: _useBiometrics
                        ? AegisColors.primary
                        : AegisColors.textTertiary,
                    size: AegisIconSize.md,
                  ),
                ),
                title: Text(
                  'Use Face ID / Fingerprint',
                  style: AegisTypography.titleSmall.copyWith(
                      color: AegisColors.textPrimary),
                ),
                subtitle: Text(
                  'Enable biometric unlock for faster access.',
                  style: AegisTypography.bodySmall.copyWith(
                      color: AegisColors.textSecondary),
                ),
                value: _useBiometrics,
                activeColor: AegisColors.primary,
                onChanged: (val) => setState(() => _useBiometrics = val),
              ),
            ),

            const SizedBox(height: AegisSpacing.xl),

            // ── CTA ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AegisTokens.btnHeight,
              child: ElevatedButton(
                onPressed: _savePin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AegisColors.primary,
                  foregroundColor: AegisColors.onPrimary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                  textStyle: AegisTypography.labelLarge,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: AegisIconSize.sm),
                    SizedBox(width: AegisSpacing.sm),
                    Text('Save & Continue'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AegisSpacing.safeBottom),
          ],
        ),
      ),
    );
  }

}
