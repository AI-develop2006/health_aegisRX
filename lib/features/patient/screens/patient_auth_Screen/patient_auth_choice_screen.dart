import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0F1D);
const _kCard   = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kAccent = Color(0xFF0EA5E9);
const _kText   = Color(0xFFFFFFFF);
const _kMuted  = Color(0xFF94A3B8);

/// Shared mesh painter used across all auth screens
class _AuthMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const step = 44.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shared field decoration for all auth input fields
InputDecoration _authFieldDecoration({
  required String label,
  required IconData prefixIcon,
  Widget? suffix,
  String? hint,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _kMuted, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: _kMuted, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: _kMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _kCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );

/// Primary CTA button with Cyber Shield Blue
class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _AuthButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccent,
          disabledBackgroundColor: _kAccent.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PATIENT AUTH CHOICE SCREEN
// ════════════════════════════════════════════════════════════════════════════

class PatientAuthChoiceScreen extends StatelessWidget {
  const PatientAuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _AuthMeshPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Back
                  IconButton(
                    onPressed: () => appState.resetFlow(),
                    icon: const Icon(CupertinoIcons.arrow_left, color: _kMuted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(height: 32),

                  // Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kAccent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Icon(CupertinoIcons.lock_shield_fill, size: 36, color: _kAccent),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Patient Vault Access',
                    style: GoogleFonts.sora(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Decentralized encryption secures your medical identity.',
                    style: GoogleFonts.inter(fontSize: 14, color: _kMuted, height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  // New patient
                  _ChoiceTile(
                    icon: CupertinoIcons.person_badge_plus_fill,
                    title: 'I am a new patient',
                    subtitle: 'Create your sovereign health vault with cryptographic key pairs.',
                    color: _kAccent,
                    onTap: () => appState.setPatientAuthState(PatientAuthState.signup),
                  ),

                  const SizedBox(height: 16),

                  // Existing patient
                  _ChoiceTile(
                    icon: CupertinoIcons.lock_open_fill,
                    title: 'I already have an account',
                    subtitle: 'Decrypt and unlock your existing medical vault records.',
                    color: const Color(0xFF10B981),
                    onTap: () => appState.setPatientAuthState(PatientAuthState.login),
                  ),

                  const Spacer(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: Text(
                        'AegisRx · HealthLock Security Gateway',
                        style: GoogleFonts.inter(fontSize: 11, color: _kMuted.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: _kMuted, height: 1.4)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 16, color: _kMuted),
          ],
        ),
      ),
    );
  }
}
