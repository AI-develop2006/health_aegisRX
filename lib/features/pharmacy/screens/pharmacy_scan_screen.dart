import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import 'pharmacy_verification_screen.dart';

class PharmacyScanScreen extends StatefulWidget {
  const PharmacyScanScreen({super.key});

  @override
  State<PharmacyScanScreen> createState() => _PharmacyScanScreenState();
}

class _PharmacyScanScreenState extends State<PharmacyScanScreen> with SingleTickerProviderStateMixin {
  final _payloadController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessingCode = false;
  late AnimationController _scannerAnimController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _scannerAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scannerAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(_scannerAnimController);
  }

  @override
  void dispose() {
    _payloadController.dispose();
    _cameraController.dispose();
    _scannerAnimController.dispose();
    super.dispose();
  }

  void _onCodeScanned(String fullPayload) {
    if (_isProcessingCode) return;
    setState(() => _isProcessingCode = true);

    // Expected format: payload##signature
    final parts = fullPayload.split('##');
    if (parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR payload format. Must contain "##" separator.')),
      );
      setState(() => _isProcessingCode = false);
      return;
    }

    final rawPayload = parts[0];
    final signature = parts[1];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyVerificationScreen(
          rawPayload: rawPayload,
          signature: signature,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessingCode = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prescription Scanner', style: TextStyle(fontFamily: 'Sora')),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.camera_alt_rounded), text: 'Camera Scan'),
              Tab(icon: Icon(Icons.edit_note_rounded), text: 'Paste Payload'),
            ],
            indicatorColor: Color(0xFF0F52BA),
            labelColor: Color(0xFF0F52BA),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sora'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                Provider.of<AppState>(context, listen: false).clearSession();
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Live Camera Scan
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: NeonCard(
                  neonColor: const Color(0xFF0F52BA),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Live Viewfinder',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Sora'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Align the checkout QR code within the frame to verify.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1A1B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F52BA).withOpacity(0.3), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: MobileScanner(
                                  controller: _cameraController,
                                  onDetect: (capture) {
                                    if (_isProcessingCode) return;
                                    final List<Barcode> barcodes = capture.barcodes;
                                    for (final barcode in barcodes) {
                                      final rawValue = barcode.rawValue;
                                      if (rawValue != null && rawValue.isNotEmpty) {
                                        _onCodeScanned(rawValue);
                                        break;
                                      }
                                    }
                                  },
                                ),
                              ),
                              // Laser Line Scanner Animation
                              AnimatedBuilder(
                                animation: _scannerAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: 240 * _scannerAnimation.value,
                                    left: 16,
                                    right: 16,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F52BA),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0F52BA).withOpacity(0.8),
                                            blurRadius: 6,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Viewfinder brackets
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ScannerBracketsPainter(
                                    color: const Color(0xFF0F52BA),
                                  ),
                                ),
                              ),
                              if (_isProcessingCode)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.6),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF0F52BA),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tab 2: Manual Paste Payload
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: NeonCard(
                  neonColor: const Color(0xFF0F52BA),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_document, size: 64, color: Color(0xFF0F52BA)),
                      const SizedBox(height: 16),
                      const Text(
                        'Manual Payload Verification',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Sora'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Paste the raw data stream from the client checkout wallet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _payloadController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Raw Scanned Payload (Data##Signature)',
                          hintText: 'e.g. RX-1234|Dr. Alex...##0xabc...',
                          prefixIcon: Icon(Icons.paste_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassmorphicButton(
                        onPressed: _isProcessingCode ? null : () => _onCodeScanned(_payloadController.text.trim()),
                        child: const Text('Verify Scanned Payload'),
                      ),
                    ],
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

class _ScannerBracketsPainter extends CustomPainter {
  final Color color;
  _ScannerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    const len = 16.0;
    // Top Left
    canvas.drawPath(Path()..moveTo(0, len)..lineTo(0, 0)..lineTo(len, 0), paint);
    // Top Right
    canvas.drawPath(Path()..moveTo(size.width - len, 0)..lineTo(size.width, 0)..lineTo(size.width, len), paint);
    // Bottom Left
    canvas.drawPath(Path()..moveTo(0, size.height - len)..lineTo(0, size.height)..lineTo(len, size.height), paint);
    // Bottom Right
    canvas.drawPath(Path()..moveTo(size.width - len, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
