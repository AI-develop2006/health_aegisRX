import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../doctor_theme.dart';
import 'doctor_patient_history_screen.dart';

class DoctorPatientSearchScreen extends StatefulWidget {
  const DoctorPatientSearchScreen({super.key});

  @override
  State<DoctorPatientSearchScreen> createState() =>
      _DoctorPatientSearchScreenState();
}

class _DoctorPatientSearchScreenState
    extends State<DoctorPatientSearchScreen> {
  final _searchController = TextEditingController();
  final _qrInputController = TextEditingController();
  Timer? _connTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _qrInputController.dispose();
    _connTimer?.cancel();
    super.dispose();
  }

  void _handleConnectionInitiated(String input) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final res = await appState.requestPatientConnection(input);
    if (res == null) return;

    if (res.startsWith('PENDING:')) {
      final reqId = res.split(':')[1];
      _showWaitingDialog(reqId);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $res')),
        );
      }
    }
  }

  void _showWaitingDialog(String reqId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _connTimer?.cancel();
            _connTimer = Timer.periodic(
                const Duration(milliseconds: 1500), (timer) async {
              if (!mounted) {
                timer.cancel();
                return;
              }
              final appState =
                  Provider.of<AppState>(context, listen: false);
              final status = await appState.checkConnectionStatus(reqId);
              if (status == 'accepted') {
                timer.cancel();
                if (context.mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Consent validated! Session established.')),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorPatientHistoryScreen(
                        patientId: appState.activePatientId!,
                        patientName: appState.activePatientName!,
                      ),
                    ),
                  );
                }
              } else if (status == 'rejected') {
                timer.cancel();
                if (context.mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Connection rejected by patient.')),
                  );
                }
              }
            });

            return AlertDialog(
              backgroundColor: Dr.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Dr.border, width: 1),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Dr.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded,
                        color: Dr.green, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Waiting for Consent',
                        style: Dr.heading(16),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Dr.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'A connection request has been sent to the patient\'s wallet. Ask the patient to tap "Accept" in their app.',
                    textAlign: TextAlign.center,
                    style: Dr.meta(13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Dr.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Dr.border),
                    ),
                    child: Text(
                      'Patient: ${Provider.of<AppState>(context, listen: false).activePatientName ?? "—"}',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Dr.text),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _connTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: Dr.red,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'Connect Patient Vault'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ────────────────────────────────────
            DoctorCard(
              borderColor: Dr.green.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Dr.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scan the patient\'s QR from their AegisRx app or enter their ID manually.',
                      style: Dr.meta(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── QR Scan Block ──────────────────────────────────
            sectionHeader('Patient Consent Scan (QR)'),
            DoctorCard(
              borderColor: Dr.green.withOpacity(0.35),
              child: Column(
                children: [
                  TextField(
                    controller: _qrInputController,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 13, color: Dr.text),
                    decoration: InputDecoration(
                      labelText: 'Scan or Paste QR Code Content',
                      labelStyle: Dr.meta(13),
                      hintText: 'e.g. Elena Vance|Elena_Vance_992818',
                      hintStyle: Dr.meta(12),
                      prefixIcon: const Icon(Icons.qr_code_2_rounded,
                          color: Dr.sub, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Dr.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Dr.green, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Dr.bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DoctorPrimaryButton(
                    label: 'Connect via QR Code',
                    icon: Icons.link_rounded,
                    onPressed: () {
                      final input = _qrInputController.text.trim();
                      if (input.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please scan or paste patient QR content.')),
                        );
                        return;
                      }
                      _handleConnectionInitiated(input);
                    },
                  ),
                  const SizedBox(height: 10),
                  DoctorOutlinedButton(
                    label: 'Simulate Scan (Elena Vance)',
                    icon: Icons.flash_on_rounded,
                    color: Dr.amber,
                    onPressed: () {
                      _qrInputController.text =
                          'Elena Vance|Elena_Vance_992818';
                      _handleConnectionInitiated(
                          'Elena Vance|Elena_Vance_992818');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Manual Entry Block ─────────────────────────────
            sectionHeader('Backup Connection (Manual Entry)'),
            DoctorCard(
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 13, color: Dr.text),
                    decoration: InputDecoration(
                      labelText: 'Enter Patient ID Manually',
                      labelStyle: Dr.meta(13),
                      hintText: 'e.g. Elena_Vance_992818',
                      hintStyle: Dr.meta(12),
                      prefixIcon: const Icon(Icons.person_pin_rounded,
                          color: Dr.sub, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Dr.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Dr.green, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Dr.bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DoctorOutlinedButton(
                    label: 'Initiate Backup Connection',
                    icon: Icons.connecting_airports_rounded,
                    onPressed: () {
                      final input = _searchController.text.trim();
                      if (input.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please enter a valid Patient ID')),
                        );
                        return;
                      }
                      _handleConnectionInitiated(input);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
