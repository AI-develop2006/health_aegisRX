import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/state/app_state.dart';
import '../doctor_theme.dart';
import 'doctor_patient_history_screen.dart';

class DoctorPatientSearchScreen extends StatefulWidget {
  const DoctorPatientSearchScreen({super.key});

  @override
  State<DoctorPatientSearchScreen> createState() =>
      _DoctorPatientSearchScreenState();
}

class _DoctorPatientSearchScreenState extends State<DoctorPatientSearchScreen> {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $res')));
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
            _connTimer = Timer.periodic(const Duration(milliseconds: 1500), (
              timer,
            ) async {
              if (!mounted) {
                timer.cancel();
                return;
              }
              final appState = Provider.of<AppState>(context, listen: false);
              final status = await appState.checkConnectionStatus(reqId);
              if (status == 'accepted') {
                timer.cancel();
                if (context.mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Consent validated! Session established.'),
                    ),
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
                      content: Text('Connection rejected by patient.'),
                    ),
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
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Dr.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Waiting for Consent',
                      style: Dr.heading(16),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                        color: Dr.text,
                      ),
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
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: Dr.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Dr.green,
                    size: 18,
                  ),
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

            // ── Interactive QR Viewfinder ─────────────────────
            sectionHeader('Patient Consent Scan (QR)'),
            const SizedBox(height: 8),
            ClinicalQrScannerViewfinder(
              onScanCompleted: _handleConnectionInitiated,
            ),
            const SizedBox(height: 24),

            // ── Manual Input (Collapsible Expansion Tile) ──────
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  'Manual Input / Paste QR Content',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Dr.text,
                  ),
                ),
                leading: const Icon(Icons.keyboard_rounded, color: Dr.green),
                childrenPadding: const EdgeInsets.all(4),
                textColor: Dr.green,
                iconColor: Dr.green,
                collapsedTextColor: Dr.text,
                collapsedIconColor: Dr.sub,
                children: [
                  DoctorCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _qrInputController,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: Dr.text,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Paste QR Code Content',
                            labelStyle: Dr.meta(13),
                            hintText: 'e.g. Elena Vance|Elena_Vance_992818',
                            hintStyle: Dr.meta(12),
                            prefixIcon: const Icon(
                              Icons.qr_code_2_rounded,
                              color: Dr.sub,
                              size: 20,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Dr.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Dr.green,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Dr.bg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DoctorPrimaryButton(
                          label: 'Connect via QR Code',
                          icon: Icons.link_rounded,
                          onPressed: () {
                            final input = _qrInputController.text.trim();
                            if (input.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please scan or paste patient QR content.',
                                  ),
                                ),
                              );
                              return;
                            }
                            _handleConnectionInitiated(input);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: Dr.text,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Enter Patient ID Manually',
                            labelStyle: Dr.meta(13),
                            hintText: 'e.g. Elena_Vance_992818',
                            hintStyle: Dr.meta(12),
                            prefixIcon: const Icon(
                              Icons.person_pin_rounded,
                              color: Dr.sub,
                              size: 20,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Dr.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Dr.green,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Dr.bg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DoctorOutlinedButton(
                          label: 'Initiate Backup Connection',
                          icon: Icons.connecting_airports_rounded,
                          onPressed: () {
                            final input = _searchController.text.trim();
                            if (input.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a valid Patient ID',
                                  ),
                                ),
                              );
                              return;
                            }
                            _handleConnectionInitiated(input);
                          },
                        ),
                      ],
                    ),
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

// ── Beautiful Real QR Viewfinder (MobileScanner) ───────────────
class ClinicalQrScannerViewfinder extends StatefulWidget {
  final Function(String) onScanCompleted;

  const ClinicalQrScannerViewfinder({super.key, required this.onScanCompleted});

  @override
  State<ClinicalQrScannerViewfinder> createState() =>
      _ClinicalQrScannerViewfinderState();
}

class _ClinicalQrScannerViewfinderState
    extends State<ClinicalQrScannerViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessingCode = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _triggerScan(String label, String value) {
    if (_isProcessingCode) return;
    setState(() {
      _isProcessingCode = true;
    });
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isProcessingCode = false;
        });
        widget.onScanCompleted(value);
      }
    });
  }

  void _showCustomScanDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Dr.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Dr.border, width: 1),
          ),
          title: Text('Scan Custom QR / Session ID', style: Dr.heading(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter or paste any custom patient session token (e.g. name|patientId):',
                style: Dr.meta(12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Dr.text),
                decoration: InputDecoration(
                  labelText: 'Custom Session QR Content',
                  labelStyle: Dr.meta(13),
                  hintText: 'e.g. John Doe|john_doe_992818',
                  hintStyle: Dr.meta(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Dr.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Dr.green, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Dr.bg,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Dr.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final input = textController.text.trim();
                Navigator.pop(context);
                if (input.isNotEmpty) {
                  String label = 'Custom Profile';
                  if (input.contains('|')) {
                    label = input.split('|')[0].trim();
                  } else if (input.contains('aegisrx://patient/')) {
                    final stripped = input
                        .replaceAll('aegisrx://patient/', '')
                        .trim();
                    if (stripped.contains('/')) {
                      label = stripped.split('/')[1].trim();
                    } else {
                      label = stripped;
                    }
                  }
                  _triggerScan(label, input);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Dr.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Start Scan',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A1B), // Dark medical grid bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Dr.green.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Real camera viewport using MobileScanner package
            Positioned.fill(
              child: MobileScanner(
                controller: _cameraController,
                onDetect: (capture) {
                  if (_isProcessingCode) return;
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final rawValue = barcode.rawValue;
                    if (rawValue != null && rawValue.isNotEmpty) {
                      setState(() {
                        _isProcessingCode = true;
                      });
                      widget.onScanCompleted(rawValue);
                      Timer(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _isProcessingCode = false;
                          });
                        }
                      });
                      break;
                    }
                  }
                },
              ),
            ),
            // Viewfinder brackets
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(painter: ViewfinderPainter()),
              ),
            ),
            // Laser Line animation
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  top: 220 * _animation.value,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: Dr.green,
                      boxShadow: [
                        BoxShadow(
                          color: Dr.green.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Scanning Status & Overlay
            if (_isProcessingCode)
              Container(
                color: Colors.black.withOpacity(0.75),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Dr.green,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Processing Vault Token...',
                        style: GoogleFonts.inter(
                          color: Dr.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verifying cryptographic P2P access...',
                        style: Dr.meta(11),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCustomScanDialog(),
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Simulate Scan',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A3C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

// ── Viewfinder Corners Custom Painter ──────────────────────────
class ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF2E8B90) // Teal accent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    const len = 16.0;
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      paint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height)
        ..lineTo(len, size.height),
      paint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
