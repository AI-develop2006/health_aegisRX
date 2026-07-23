// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Settings Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — all dialogs, exports, allergy management,
//                 PIN change, biometric toggle, legal pages, clearSession() preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  bool _biometricUnlock = false;
  final List<String> _allergies = [];

  @override
  void initState() {
    super.initState();
    // UNCHANGED — same initState logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.fetchPatientProfile().then((_) {
        if (mounted) {
          setState(() {
            _allergies.clear();
            _allergies.addAll(appState.patientAllergies);
          });
        }
      });
    });
  }

  // ── BUSINESS LOGIC: Personal Details Dialog ─── UNCHANGED ─────────────────
  void _openPersonalDetails(AppState appState) {
    final nameCtrl = TextEditingController(text: appState.patientName);
    final idCtrl = TextEditingController(text: appState.patientMobileOrId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AegisColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AegisRadius.card,
          side: const BorderSide(color: AegisColors.border),
        ),
        title: Text(
          'Personal Details',
          style: AegisTypography.headlineSmall.copyWith(
            color: AegisColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _styledField(
              controller: nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: AegisSpacing.md),
            _styledField(
              controller: idCtrl,
              label: 'Mobile / Patient ID',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AegisTypography.labelMedium.copyWith(
                color: AegisColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AegisColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
            ),
            onPressed: () async {
              await appState.updatePatientMobileOrId(idCtrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _toast('Profile updated successfully.');
            },
            child: Text(
              'Save',
              style: AegisTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUSINESS LOGIC: Change PIN Dialog ─── UNCHANGED ───────────────────────
  void _openChangePIN(AppState appState) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AegisColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AegisRadius.card,
            side: const BorderSide(color: AegisColors.border),
          ),
          title: Text(
            'Change PIN',
            style: AegisTypography.headlineSmall.copyWith(
              color: AegisColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (appState.savedPin != null)
                _styledField(
                  controller: currentCtrl,
                  label: 'Current PIN',
                  icon: Icons.lock_outline,
                  obscure: true,
                  keyboardType: TextInputType.number,
                ),
              if (appState.savedPin != null)
                const SizedBox(height: AegisSpacing.sm),
              _styledField(
                controller: newCtrl,
                label: 'New PIN (4–6 digits)',
                icon: Icons.lock_reset_outlined,
                obscure: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: AegisSpacing.sm),
              _styledField(
                controller: confirmCtrl,
                label: 'Confirm New PIN',
                icon: Icons.lock_clock_outlined,
                obscure: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              if (error != null) ...[
                const SizedBox(height: AegisSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AegisSpacing.sm),
                  decoration: BoxDecoration(
                    color: AegisColors.dangerLight,
                    borderRadius: BorderRadius.circular(AegisRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: AegisIconSize.sm,
                        color: AegisColors.danger,
                      ),
                      const SizedBox(width: AegisSpacing.xs),
                      Text(
                        error!,
                        style: AegisTypography.labelSmall.copyWith(
                          color: AegisColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: AegisTypography.labelMedium.copyWith(
                  color: AegisColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AegisColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
              ),
              onPressed: () async {
                // UNCHANGED — PIN validation logic
                if (appState.savedPin != null &&
                    currentCtrl.text != appState.savedPin) {
                  setS(() => error = 'Current PIN is incorrect.');
                  return;
                }
                if (newCtrl.text.length < 4) {
                  setS(() => error = 'PIN must be at least 4 digits.');
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  setS(() => error = 'PINs do not match.');
                  return;
                }
                await appState.savePin(newCtrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _toast('PIN updated successfully.');
              },
              child: Text(
                'Update PIN',
                style: AegisTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUSINESS LOGIC: Allergy Manager ─── UNCHANGED ─────────────────────────
  void _openAllergyManager() {
    final appState = Provider.of<AppState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AegisColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AllergySheet(
        allergies: List<String>.from(_allergies),
        onSave: (updated) async {
          setState(
            () => _allergies
              ..clear()
              ..addAll(updated),
          );
          final success = await appState.savePatientAllergies(updated);
          if (success) {
            _toast('Allergy list saved successfully.');
          } else {
            _toast('Allergy list updated locally.');
          }
        },
      ),
    );
  }

  // ── BUSINESS LOGIC: Export ─── UNCHANGED ──────────────────────────────────
  void _exportData(AppState appState) {
    final vault = appState.patientVault;
    if (vault.isEmpty) {
      _toast('No prescriptions to export.');
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('=== AegisRx Patient Export ===');
    buffer.writeln('Patient: ${appState.patientName}');
    buffer.writeln('ID: ${appState.patientMobileOrId}');
    buffer.writeln(
      'Exported: ${DateTime.now().toLocal().toString().substring(0, 16)}',
    );
    buffer.writeln('');
    for (final rx in vault) {
      buffer.writeln('--- PRESCRIPTION: ${rx.id} ---');
      buffer.writeln('Doctor: ${rx.doctorName} | ${rx.hospitalName}');
      buffer.writeln('Diagnosis: ${rx.disease}');
      buffer.writeln('Date: ${rx.date} ${rx.time}');
      buffer.writeln('Status: ${rx.isDispensed ? "DISPENSED" : "ACTIVE"}');
      buffer.writeln('Medicines:');
      for (final m in rx.medicines) {
        final timings = <String>[];
        if (m.morning) timings.add('Morning');
        if (m.afternoon) timings.add('Afternoon');
        if (m.evening) timings.add('Evening');
        if (m.night) timings.add('Night');
        buffer.writeln(
          '  • ${m.name} — ${timings.join(", ")} — ${m.beforeFood ? "Before food" : "After food"}',
        );
        if (m.customInstruction.isNotEmpty) {
          buffer.writeln('    Note: ${m.customInstruction}');
        }
      }
      buffer.writeln('');
    }
    final exportText = buffer.toString();
    Clipboard.setData(ClipboardData(text: exportText));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AegisColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AegisRadius.card,
          side: const BorderSide(color: AegisColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AegisSpacing.xs),
              decoration: BoxDecoration(
                color: AegisColors.successLight,
                borderRadius: BorderRadius.circular(AegisRadius.xs),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AegisColors.success,
                size: AegisIconSize.sm,
              ),
            ),
            const SizedBox(width: AegisSpacing.sm),
            Text(
              'Exported!',
              style: AegisTypography.headlineSmall.copyWith(
                color: AegisColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${vault.length} prescription(s) copied to clipboard as plain text.',
              style: AegisTypography.bodySmall.copyWith(
                color: AegisColors.textSecondary,
              ),
            ),
            const SizedBox(height: AegisSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AegisSpacing.sm),
              decoration: BoxDecoration(
                color: AegisColors.surfaceDim,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.border),
              ),
              child: Text(
                exportText.length > 300
                    ? '${exportText.substring(0, 300)}...'
                    : exportText,
                style: AegisTypography.monoSmall.copyWith(
                  color: AegisColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AegisColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Done',
              style: AegisTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUSINESS LOGIC: Legal Pages ─── UNCHANGED ─────────────────────────────
  void _openLegalPage(String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AegisColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(
            AegisSpacing.pagePadding,
            AegisSpacing.sm,
            AegisSpacing.pagePadding,
            AegisSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AegisColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AegisSpacing.base),
              Text(
                title,
                style: AegisTypography.headlineMedium.copyWith(
                  color: AegisColors.textPrimary,
                ),
              ),
              const SizedBox(height: AegisSpacing.xs),
              Text(
                'AegisRx Health Lock · v1.0.0',
                style: AegisTypography.bodySmall.copyWith(
                  color: AegisColors.textTertiary,
                ),
              ),
              const SizedBox(height: AegisSpacing.md),
              const Divider(color: AegisColors.border),
              const SizedBox(height: AegisSpacing.md),
              Text(
                body,
                style: AegisTypography.bodyMedium.copyWith(
                  color: AegisColors.textPrimary,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AegisTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AegisColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String initials = appState.patientName.isNotEmpty
        ? appState.patientName
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : 'P';

    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: AppBar(
        backgroundColor: AegisColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: AegisSpacing.pagePadding,
        title: Text(
          'Settings',
          style: AegisTypography.headlineMedium.copyWith(
            color: AegisColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.pagePadding,
          vertical: AegisSpacing.base,
        ),
        children: [
          // ── Profile Badge Card ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(AegisSpacing.base),
            decoration: BoxDecoration(
              color: AegisColors.surface,
              borderRadius: AegisRadius.card,
              border: Border.all(color: AegisColors.border),
              boxShadow: AegisShadows.sm,
            ),
            child: Row(
              children: [
                // Avatar initials circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AegisColors.primary,
                    borderRadius: BorderRadius.circular(AegisRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AegisTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AegisSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.patientName,
                        style: AegisTypography.titleMedium.copyWith(
                          color: AegisColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${appState.patientMobileOrId}',
                        style: AegisTypography.monoSmall.copyWith(
                          color: AegisColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        appState.patientEmailOrId,
                        style: AegisTypography.bodySmall.copyWith(
                          color: AegisColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AegisSpacing.sm,
                    vertical: AegisSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AegisColors.secondarySurface,
                    borderRadius: AegisRadius.chip,
                    border: Border.all(
                      color: AegisColors.secondary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Patient',
                    style: AegisTypography.labelSmall.copyWith(
                      color: AegisColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AegisSpacing.lg),

          // ── Profile Section ──────────────────────────────────
          _SectionHeader(label: 'Profile'),
          const SizedBox(height: AegisSpacing.sm),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                iconColor: AegisColors.primary,
                label: 'Personal Details',
                sub: 'Update your name and contact info',
                onTap: () => _openPersonalDetails(appState),
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.base),

          // ── Security Section ─────────────────────────────────
          _SectionHeader(label: 'Security'),
          const SizedBox(height: AegisSpacing.sm),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                iconColor: AegisColors.primary,
                label: 'Change PIN',
                sub: appState.savedPin != null
                    ? 'PIN is currently set'
                    : 'Set a new access PIN',
                onTap: () => _openChangePIN(appState),
                trailing: appState.savedPin != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AegisSpacing.sm,
                          vertical: AegisSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AegisColors.secondarySurface,
                          borderRadius: AegisRadius.chip,
                          border: Border.all(
                            color: AegisColors.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Set',
                          style: AegisTypography.labelSmall.copyWith(
                            color: AegisColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              const Divider(height: 1, color: AegisColors.border, indent: 56),
              _SwitchTile(
                icon: Icons.fingerprint,
                iconColor: AegisColors.primary,
                label: 'Biometric Unlock',
                sub: 'Use fingerprint or Face ID to unlock',
                value: _biometricUnlock,
                onChanged: (val) {
                  setState(() => _biometricUnlock = val);
                  _toast(
                    val
                        ? 'Biometric unlock enabled.'
                        : 'Biometric unlock disabled.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.base),

          // ── Health Data Section ──────────────────────────────
          _SectionHeader(label: 'Health Data'),
          const SizedBox(height: AegisSpacing.sm),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.warning_amber_rounded,
                iconColor: _allergies.isNotEmpty
                    ? AegisColors.warning
                    : AegisColors.textTertiary,
                label: 'Allergy Declarations',
                sub: _allergies.isEmpty
                    ? 'No allergies declared'
                    : _allergies.join(', '),
                subColor: _allergies.isNotEmpty ? AegisColors.warning : null,
                onTap: _openAllergyManager,
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _allergies.isNotEmpty
                        ? AegisColors.dangerLight
                        : AegisColors.surfaceDim,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_allergies.length}',
                      style: AegisTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _allergies.isNotEmpty
                            ? AegisColors.danger
                            : AegisColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AegisColors.border, indent: 56),
              _SettingsTile(
                icon: Icons.download_rounded,
                iconColor: AegisColors.secondary,
                label: 'Export Prescription Data',
                sub:
                    '${appState.patientVault.length} prescription(s) available',
                onTap: () => _exportData(appState),
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.base),

          // ── About Section ────────────────────────────────────
          _SectionHeader(label: 'About'),
          const SizedBox(height: AegisSpacing.sm),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: AegisColors.textSecondary,
                label: 'Terms of Use',
                sub: 'Read our terms of service',
                onTap: () => _openLegalPage('Terms of Use', _kTermsText),
              ),
              const Divider(height: 1, color: AegisColors.border, indent: 56),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AegisColors.textSecondary,
                label: 'Privacy Policy',
                sub: 'Read our data & privacy policy',
                onTap: () => _openLegalPage('Privacy Policy', _kPrivacyText),
              ),
              const Divider(height: 1, color: AegisColors.border, indent: 56),
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AegisColors.textTertiary,
                label: 'App Version',
                sub: 'AegisRx Health Lock',
                onTap: null,
                trailing: Text(
                  '1.0.0',
                  style: AegisTypography.monoSmall.copyWith(
                    color: AegisColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.xl),

          // ── Sign Out ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: AegisTokens.btnHeight,
            child: ElevatedButton.icon(
              onPressed: () {
                // UNCHANGED — sign out dialog + clearSession()
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AegisColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: AegisRadius.card,
                      side: const BorderSide(color: AegisColors.border),
                    ),
                    title: Text(
                      'Sign Out?',
                      style: AegisTypography.headlineSmall.copyWith(
                        color: AegisColors.textPrimary,
                      ),
                    ),
                    content: Text(
                      'You will be logged out and returned to the role selection screen.',
                      style: AegisTypography.bodyMedium.copyWith(
                        color: AegisColors.textSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: AegisTypography.labelMedium.copyWith(
                            color: AegisColors.textSecondary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AegisColors.danger,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AegisRadius.button,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          appState.clearSession();
                        },
                        child: Text(
                          'Sign Out',
                          style: AegisTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: AegisIconSize.sm,
              ),
              label: Text(
                'Sign out',
                style: AegisTypography.labelLarge.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AegisColors.danger,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
              ),
            ),
          ),
          const SizedBox(height: AegisSpacing.xxl),
        ],
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    maxLength: maxLength,
    style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: AegisTypography.bodySmall.copyWith(
        color: AegisColors.textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        color: AegisColors.textTertiary,
        size: AegisIconSize.sm,
      ),
      filled: true,
      fillColor: AegisColors.background,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: AegisRadius.input,
        borderSide: const BorderSide(color: AegisColors.border, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AegisRadius.input,
        borderSide: const BorderSide(color: AegisColors.border, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AegisRadius.input,
        borderSide: const BorderSide(color: AegisColors.primary, width: 1.5),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Reusable Settings Components
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Text(
      label.toUpperCase(),
      style: AegisTypography.labelSmall.copyWith(
        color: AegisColors.textTertiary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AegisColors.surface,
      borderRadius: AegisRadius.card,
      border: Border.all(color: AegisColors.border),
      boxShadow: AegisShadows.sm,
    ),
    child: Column(children: children),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sub;
  final Color? subColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.sub,
    this.subColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AegisSpacing.base,
      vertical: AegisSpacing.xs,
    ),
    leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AegisRadius.sm),
      ),
      child: Icon(icon, color: iconColor, size: AegisIconSize.sm),
    ),
    title: Text(
      label,
      style: AegisTypography.bodyMedium.copyWith(
        color: AegisColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: sub != null
        ? Text(
            sub!,
            style: AegisTypography.bodySmall.copyWith(
              color: subColor ?? AegisColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : null,
    trailing:
        trailing ??
        (onTap != null
            ? const Icon(
                Icons.chevron_right,
                color: AegisColors.textTertiary,
                size: AegisIconSize.md,
              )
            : null),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: AegisRadius.card),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AegisSpacing.base,
      vertical: AegisSpacing.xs,
    ),
    secondary: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AegisRadius.sm),
      ),
      child: Icon(icon, color: iconColor, size: AegisIconSize.sm),
    ),
    title: Text(
      label,
      style: AegisTypography.bodyMedium.copyWith(
        color: AegisColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: sub != null
        ? Text(
            sub!,
            style: AegisTypography.bodySmall.copyWith(
              color: AegisColors.textSecondary,
            ),
          )
        : null,
    value: value,
    onChanged: onChanged,
    activeColor: AegisColors.primary,
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AegisColors.primarySurface;
      }
      return AegisColors.border;
    }),
  );
}

// ── Allergy Sheet Widget ───────────────────────────────────────────────────
class _AllergySheet extends StatefulWidget {
  final List<String> allergies;
  final ValueChanged<List<String>> onSave;

  const _AllergySheet({required this.allergies, required this.onSave});

  @override
  State<_AllergySheet> createState() => _AllergySheetState();
}

class _AllergySheetState extends State<_AllergySheet> {
  late List<String> _list;
  final _ctrl = TextEditingController();

  // UNCHANGED — same allergen list
  final List<String> _commonAllergens = [
    'Penicillin',
    'Aspirin',
    'NSAIDs',
    'Sulfonamides',
    'Codeine',
    'Ibuprofen',
    'Latex',
    'Pollen',
    'Shellfish',
    'Peanuts',
  ];

  @override
  void initState() {
    super.initState();
    _list = List<String>.from(widget.allergies);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addAllergen(String name) {
    final clean = name.trim();
    if (clean.isEmpty || _list.contains(clean)) return;
    setState(() => _list.add(clean));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AegisSpacing.pagePadding,
          AegisSpacing.sm,
          AegisSpacing.pagePadding,
          AegisSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AegisColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AegisSpacing.base),

            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AegisColors.dangerLight,
                    borderRadius: BorderRadius.circular(AegisRadius.sm),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AegisColors.danger,
                    size: AegisIconSize.md,
                  ),
                ),
                const SizedBox(width: AegisSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allergy Declarations',
                        style: AegisTypography.headlineSmall.copyWith(
                          color: AegisColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Shown to your doctor during prescriptions.',
                        style: AegisTypography.bodySmall.copyWith(
                          color: AegisColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AegisSpacing.base),
            const Divider(color: AegisColors.border),
            const SizedBox(height: AegisSpacing.base),

            // Declared allergies chips
            if (_list.isNotEmpty)
              Wrap(
                spacing: AegisSpacing.xs,
                runSpacing: AegisSpacing.xs,
                children: _list.map((a) {
                  return Chip(
                    label: Text(
                      a,
                      style: AegisTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AegisColors.danger,
                      ),
                    ),
                    backgroundColor: AegisColors.dangerLight,
                    side: BorderSide(
                      color: AegisColors.danger.withValues(alpha: 0.3),
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: AegisIconSize.xs,
                      color: AegisColors.danger,
                    ),
                    onDeleted: () => setState(() => _list.remove(a)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                    ),
                  );
                }).toList(),
              ),
            if (_list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AegisSpacing.sm),
                child: Text(
                  'No allergies declared.',
                  style: AegisTypography.bodyMedium.copyWith(
                    color: AegisColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: AegisSpacing.base),

            // Custom allergen input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: AegisTypography.bodyMedium.copyWith(
                      color: AegisColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Add allergen manually',
                      labelStyle: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AegisColors.background,
                      border: OutlineInputBorder(
                        borderRadius: AegisRadius.input,
                        borderSide: const BorderSide(
                          color: AegisColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AegisRadius.input,
                        borderSide: const BorderSide(
                          color: AegisColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AegisRadius.input,
                        borderSide: const BorderSide(
                          color: AegisColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: _addAllergen,
                  ),
                ),
                const SizedBox(width: AegisSpacing.sm),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AegisColors.primary,
                    elevation: 0,
                    minimumSize: const Size(48, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: AegisRadius.input,
                    ),
                  ),
                  onPressed: () => _addAllergen(_ctrl.text),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: AegisIconSize.md,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AegisSpacing.base),

            // Common allergens quick-add
            Text(
              'Common allergens',
              style: AegisTypography.labelSmall.copyWith(
                color: AegisColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AegisSpacing.sm),
            Wrap(
              spacing: AegisSpacing.xs,
              runSpacing: AegisSpacing.xs,
              children: _commonAllergens
                  .where((a) => !_list.contains(a))
                  .map(
                    (a) => ActionChip(
                      label: Text(
                        a,
                        style: AegisTypography.labelSmall.copyWith(
                          color: AegisColors.textPrimary,
                        ),
                      ),
                      backgroundColor: AegisColors.surface,
                      side: const BorderSide(
                        color: AegisColors.border,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AegisRadius.sm),
                      ),
                      onPressed: () => _addAllergen(a),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // Save button
            SizedBox(
              width: double.infinity,
              height: AegisTokens.btnHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AegisColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AegisRadius.button,
                  ),
                ),
                onPressed: () {
                  widget.onSave(_list);
                  Navigator.pop(context);
                },
                child: Text(
                  'Save Allergies',
                  style: AegisTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legal Text Constants ── UNCHANGED ──────────────────────────────────────
const _kTermsText = '''
1. Acceptance of Terms
By using the AegisRx Health Lock application, you agree to comply with and be bound by these Terms of Use. If you do not agree, please discontinue use of the application immediately.

2. Purpose of the App
AegisRx Health Lock is a medical data management application designed to securely store, display, and share your prescription records and health information with authorised healthcare providers.

3. User Responsibilities
You are responsible for maintaining the confidentiality of your PIN and biometric credentials. Do not share your session QR code with unauthorized individuals. Report any unauthorized access to your account immediately.

4. Medical Disclaimer
This application does not provide medical advice. All prescriptions must be issued by a licensed medical professional. Always consult a qualified doctor before taking or changing any medication.

5. Data Accuracy
AegisRx displays prescriptions as issued by your doctor. While we use cryptographic signatures to verify data integrity, always verify critical information directly with your healthcare provider.

6. Termination
AegisRx reserves the right to suspend or terminate access to the application in the event of a breach of these terms.

7. Changes to Terms
We may update these Terms of Use from time to time. Continued use of the app following any change constitutes acceptance of the new terms.
''';

const _kPrivacyText = '''
1. Data We Collect
AegisRx Health Lock collects: your name, mobile number, and prescription records issued by your doctor. We do not collect location data, browsing history, or any data unrelated to medical care.

2. How Your Data Is Used
Your prescription data is stored securely on our servers and is only shared with healthcare providers you explicitly authorize through the session QR code mechanism.

3. Cryptographic Security
All prescription records are cryptographically signed and stored on a tamper-evident ledger. Any modification to a prescription will be detected and flagged automatically.

4. Data Storage
Your data is stored on our secure backend servers. Prescription records are associated with your patient ID and are never sold to third parties.

5. Your Rights
You have the right to request deletion of your account and associated data at any time. You may also request a full export of your data through the Settings > Export Prescription Data feature.

6. Third-Party Services
AegisRx does not share your data with advertisers or third-party analytics platforms. Integration with pharmacy dispensing systems is only done with your explicit in-app authorization.

7. Changes to This Policy
We may update this Privacy Policy periodically. We will notify you through the app if significant changes are made. Continued use of the application indicates your acceptance of the updated policy.

8. Contact
For any privacy-related queries, contact support@aegisrx.health
''';
