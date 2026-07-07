import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/state/app_state.dart';

class PatientShareScreen extends StatelessWidget {
  const PatientShareScreen({super.key});

  // 60-30-10 Design Tokens
  static const _bg = Color(0xFFF7F4EB);
  static const _card = Color(0xFFFFFFFF);
  static const _text = Color(0xFF4A3325);
  static const _sub = Color(0xFFD4A387);
  static const _border = Color(0xFFB88E74);
  static const _teal = Color(0xFF2E8B90);
  static const _amber = Color(0xFFD97736);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final patientId = appState.patientMobileOrId;
    final patientName = appState.patientName;
    final qrPayload = 'aegisrx://patient/$patientId/$patientName';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Share Vault Access',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: _text,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section heading
            Text(
              'Share your information',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Present the QR code below to your clinical doctor or pharmacist to authorize temporary session read access to your vault.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _sub,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Share with Doctor button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Doctor sharing integration is coming soon.')),
                  );
                },
                icon: const Icon(Icons.send_rounded,
                    size: 18, color: Colors.white),
                label: Text(
                  'Share with my doctor',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Divider(color: _border.withOpacity(0.4)),
            const SizedBox(height: 28),

            // ── QR Code Card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'Scan to Connect',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show this QR to your doctor or pharmacist.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: _sub),
                  ),
                  const SizedBox(height: 28),
                  // QR code with copper border frame
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border, width: 2),
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 180.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF4A3325),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF4A3325),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Patient ID tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: _teal.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      'ID: $patientId',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Warning note ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _amber.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _amber.withOpacity(0.4), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This QR code grants temporary read-only access. Only share with authorized medical personnel.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _text, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
