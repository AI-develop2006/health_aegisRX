import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import 'pharmacy_dispense_screen.dart';

class PharmacyVerificationScreen extends StatefulWidget {
  final String rawPayload;
  final String signature;

  const PharmacyVerificationScreen({
    super.key,
    required this.rawPayload,
    required this.signature,
  });

  @override
  State<PharmacyVerificationScreen> createState() =>
      _PharmacyVerificationScreenState();
}

class _PharmacyVerificationScreenState
    extends State<PharmacyVerificationScreen> {
  bool _isLoading = true;
  bool _verified = false;
  String _verdict = 'UNKNOWN';
  String? _errorMsg;
  Map<String, dynamic>? _prescriptionData;
  bool _chainVerified = false;

  @override
  void initState() {
    super.initState();
    _performVerification();
  }

  void _performVerification() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final res = await appState.verifyScan(widget.rawPayload, widget.signature);

    setState(() {
      _isLoading = false;
      _verified = res['verified'] == true;
      _verdict = res['verdict'] ?? 'UNKNOWN';
      _errorMsg = res['error'];
      _prescriptionData = res['prescription'];
      _chainVerified = res['chain_verified'] == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cryptographically verifying signature & ledger state...'),
          ],
        ),
      );
    } else if (!_verified) {
      content = Column(
        children: [
          NeonCard(
            neonColor: const Color(0xFFEF4444), // Critical Red
            child: ListTile(
              leading: const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 40,
              ),
              title: Text(
                'Verification Failed: $_verdict',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _errorMsg ??
                    'Prescription verification failed. Signature is invalid or single-use token already burned.',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GlassmorphicButton(
            baseColor: Colors.grey,
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Scanner'),
          ),
        ],
      );
    } else {
      final rx = _prescriptionData!;
      final medsList = rx['medicines'] as List? ?? [];

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonCard(
            neonColor: const Color(0xFF10B981), // Emerald green
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF10B981),
                    size: 36,
                  ),
                  title: const Text(
                    'Signature Verified',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Hash Match Succeeded. Doctor signature verified against NPI root key. Ledger Sync: ${_chainVerified ? "VERIFIED ON-CHAIN" : "LOCAL BLOCK"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Prescription Details',
            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescription ID: ${rx['id']}',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Patient: ${rx['patientName']}'),
                Text('Diagnosis: ${rx['disease']}'),
                Text(
                  'Clinician: ${rx['doctorName']} (NPI: ${rx['doctorSignId']})',
                ),
                Text('Hospital: ${rx['hospitalName']}'),
                Text('Date: ${rx['date']} • Time: ${rx['time']}'),
                const Divider(height: 24, color: Colors.white24),
                const Text(
                  'Medications:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...medsList.map((m) {
                  final List<String> timings = [];
                  if (m['morning'] == true) timings.add('Morning');
                  if (m['afternoon'] == true) timings.add('Afternoon');
                  if (m['evening'] == true) timings.add('Evening');
                  if (m['night'] == true) timings.add('Night');
                  final timingStr = timings.isEmpty
                      ? m['interval']
                      : timings.join(', ');
                  final foodStr = m['beforeFood'] == true
                      ? ' (Before Food)'
                      : (m['afterFood'] == true ? ' (After Food)' : '');
                  final custom =
                      m['customInstruction'] != null &&
                          m['customInstruction'].toString().isNotEmpty
                      ? " - ${m['customInstruction']}"
                      : "";
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text('• ${m['name']} - $timingStr$foodStr$custom'),
                  );
                }),
              ],
            ),
          ),
          if (rx['overrideReason'] != null &&
              rx['overrideReason'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            NeonCard(
              neonColor: const Color(0xFFF59E0B), // Warning Orange
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'CLINICAL OVERRIDE DETECTED',
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFFF59E0B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This prescription triggered AI safety warnings. The prescribing clinician submitted the following override justification:',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      '"${rx['overrideReason']}"',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GlassmorphicButton(
              baseColor: const Color(0xFF10B981),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PharmacyDispenseScreen(
                      prescriptionId: rx['id'],
                      prescriptionName: rx['patientName'],
                      medicines: medsList,
                    ),
                  ),
                );
              },
              child: const Text(
                'Proceed to Dispensation Desk',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cryptographic Verification',
          style: TextStyle(fontFamily: 'Sora'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }
}
