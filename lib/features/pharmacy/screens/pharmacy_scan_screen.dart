// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Pharmacy Scanner & Queue Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — MobileScanner, camera controller, _onCodeScanned,
//                 payload splitting (Data##Signature), navigation to PharmacyVerificationScreen
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
import 'pharmacy_verification_screen.dart';

class PharmacyScanScreen extends StatefulWidget {
  const PharmacyScanScreen({super.key});

  @override
  State<PharmacyScanScreen> createState() => _PharmacyScanScreenState();
}

class _PharmacyScanScreenState extends State<PharmacyScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _payloadController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1000,
  );
  bool _isProcessingCode = false;
  bool _isDisposed = false;
  late AnimationController _scannerAnimController;
  late Animation<double> _scannerAnimation;

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    debugPrint('QR_CAMERA_START');
    WidgetsBinding.instance.addObserver(this);
    _cameraController.addListener(_onCameraControllerStateChanged);
    _scannerAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scannerAnimation = Tween<double>(
      begin: 0.08,
      end: 0.92,
    ).animate(_scannerAnimController);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.removeListener(_onCameraControllerStateChanged);
    _payloadController.dispose();
    try {
      debugPrint('[CAMERA LOG] Disposing pharmacy camera controller');
      _cameraController.dispose();
      debugPrint('QR_CAMERA_DISPOSED');
    } catch (e) {
      debugPrint('[CAMERA LOG] Non-blocking pharmacy camera cleanup: $e');
    }
    _scannerAnimController.dispose();
    super.dispose();
  }

  void _onCameraControllerStateChanged() {
    if (_isDisposed) return;
    final val = _cameraController.value;
    debugPrint(
      '[CAMERA STATE CHANGE] (Pharmacy) isInitialized: ${val.isInitialized}, '
      'isRunning: ${val.isRunning}, '
      'hasError: ${val.error != null}',
    );
    if (val.error != null) {
      debugPrint(
        '[CAMERA STATE ERROR] (Pharmacy) Code: ${val.error!.errorCode}, '
        'Message: ${val.error!.errorDetails?.message}, Details: ${val.error!.errorDetails}',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[CAMERA LOG] AppLifecycleState changed to: $state');
    if (_isDisposed) {
      debugPrint('[CAMERA LOG] Lifecycle state change ignored: disposed.');
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint(
        '[CAMERA LOG] App paused/inactive, stopping camera (Pharmacy)...',
      );
      try {
        if (_cameraController.value.isRunning) {
          _cameraController
              .stop()
              .then((_) {
                debugPrint(
                  '[CAMERA LOG] Camera stopped successfully via lifecycle (Pharmacy).',
                );
              })
              .catchError((e) {
                debugPrint(
                  '[CAMERA LOG] Error in stop() future via lifecycle (Pharmacy): $e',
                );
              });
        }
      } catch (e) {
        debugPrint(
          '[CAMERA LOG] Exception stopping camera via lifecycle (Pharmacy): $e',
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[CAMERA LOG] App resumed, starting camera (Pharmacy)...');
      try {
        if (!_cameraController.value.isRunning) {
          _cameraController
              .start()
              .then((_) {
                debugPrint(
                  '[CAMERA LOG] Camera started successfully via lifecycle (Pharmacy).',
                );
              })
              .catchError((e) {
                debugPrint(
                  '[CAMERA LOG] Error in start() future via lifecycle (Pharmacy): $e',
                );
              });
        } else {
          debugPrint(
            '[CAMERA LOG] Camera already running (Pharmacy). isRunning: ${_cameraController.value.isRunning}',
          );
        }
      } catch (e) {
        debugPrint(
          '[CAMERA LOG] Exception starting camera via lifecycle (Pharmacy): $e',
        );
      }
    }
  }

  void _onCodeScanned(String fullPayload) async {
    if (_isProcessingCode) return;
    setState(() => _isProcessingCode = true);

    // Expected format: payload##signature
    final parts = fullPayload.split('##');
    if (parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid QR payload format. Must contain "##" separator.',
            style: AegisTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AegisColors.danger,
        ),
      );
      setState(() => _isProcessingCode = false);
      return;
    }

    final rawPayload = parts[0];
    final signature = parts[1];

    try {
      if (_cameraController.value.isRunning) {
        debugPrint('QR_CAMERA_STOPPING');
        await _cameraController.stop();
        debugPrint('QR_CAMERA_STOPPED');
      }
    } catch (e) {
      debugPrint('[CAMERA LOG] Non-blocking camera stop error before navigation (Pharmacy): $e');
    }

    if (!mounted) return;
    debugPrint('NAVIGATION_AFTER_CAMERA_RELEASE');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyVerificationScreen(
          rawPayload: rawPayload,
          signature: signature,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          debugPrint('QR_CAMERA_START');
          debugPrint(
            '[CAMERA LOG] Restarting camera after returning from Pharmacy Verification.',
          );
          if (!_cameraController.value.isRunning) {
            _cameraController.start().then((_) {
              debugPrint('[CAMERA LOG] Camera restarted successfully (Pharmacy).');
            }).catchError((e) {
              debugPrint('[CAMERA LOG] Non-blocking camera start error (Pharmacy): $e');
            });
          }
        } catch (e) {
          debugPrint(
            '[CAMERA LOG] Non-blocking camera start error after returning (Pharmacy): $e',
          );
        }
        setState(() => _isProcessingCode = false);
      });
    });
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AegisColors.background,
        appBar: AppBar(
          backgroundColor: AegisColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Prescription Scanner Desk',
            style: AegisTypography.headlineMedium.copyWith(
              color: AegisColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.camera_alt_rounded, size: AegisIconSize.sm),
                text: 'Camera Scan',
              ),
              Tab(
                icon: Icon(Icons.edit_note_rounded, size: AegisIconSize.sm),
                text: 'Paste Payload',
              ),
            ],
            indicatorColor: AegisColors.primary,
            labelColor: AegisColors.primary,
            unselectedLabelColor: AegisColors.textSecondary,
            labelStyle: AegisTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: AegisTypography.labelMedium,
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: AegisColors.textSecondary,
              ),
              tooltip: 'Sign Out',
              onPressed: () {
                Provider.of<AppState>(context, listen: false).clearSession();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Live Camera Scan ─────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AegisSpacing.pagePadding),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AegisSpacing.lg),
                  decoration: BoxDecoration(
                    color: AegisColors.surface,
                    borderRadius: AegisRadius.card,
                    border: Border.all(color: AegisColors.border),
                    boxShadow: AegisShadows.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Live Viewfinder',
                        style: AegisTypography.headlineSmall.copyWith(
                          color: AegisColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AegisSpacing.xs),
                      Text(
                        'Align the checkout QR code within the frame to verify.',
                        textAlign: TextAlign.center,
                        style: AegisTypography.bodySmall.copyWith(
                          color: AegisColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AegisSpacing.lg),
                      Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A), // Dark viewport
                          borderRadius: AegisRadius.card,
                          border: Border.all(
                            color: AegisColors.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: AegisRadius.card,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: MobileScanner(
                                  controller: _cameraController,
                                  errorBuilder: (context, error, child) {
                                    debugPrint(
                                      '[MOBILE_SCANNER_ERROR] Error occurred in MobileScanner widget (Pharmacy):\n'
                                      '  Code: ${error.errorCode}\n'
                                      '  Message: ${error.errorDetails?.message}\n'
                                      '  Details: ${error.errorDetails}',
                                    );
                                    if (error.errorCode ==
                                            MobileScannerErrorCode
                                                .permissionDenied ||
                                        error.errorCode ==
                                            MobileScannerErrorCode
                                                .unsupported) {
                                      return Container(
                                        color: const Color(0xFF0F172A),
                                        padding: const EdgeInsets.all(
                                          AegisSpacing.md,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.no_photography_outlined,
                                              color: AegisColors.warning,
                                              size: AegisIconSize.lg,
                                            ),
                                            const SizedBox(
                                              height: AegisSpacing.xs,
                                            ),
                                            Text(
                                              'Camera Access Restricted',
                                              style: AegisTypography.titleSmall
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(
                                              height: AegisSpacing.xs,
                                            ),
                                            Text(
                                              'Use manual payload entry below.',
                                              textAlign: TextAlign.center,
                                              style: AegisTypography.bodySmall
                                                  .copyWith(
                                                    color: AegisColors
                                                        .textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return Container(
                                      color: const Color(0xFF0F172A),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AegisColors.secondary,
                                        ),
                                         ),
                                    );
                                  },
                                  onDetect: (capture) async {
                                    debugPrint('QR_DETECTED');
                                    debugPrint(
                                      '[CAMERA LOG] onDetect (Pharmacy): detected ${capture.barcodes.length} barcodes.',
                                    );
                                    if (_isProcessingCode) {
                                      debugPrint(
                                        '[CAMERA LOG] onDetect (Pharmacy): already processing, skipping.',
                                      );
                                      return;
                                    }
                                    final List<Barcode> barcodes =
                                        capture.barcodes;
                                    if (barcodes.isEmpty) {
                                      debugPrint(
                                        '[CAMERA LOG] onDetect (Pharmacy): empty barcode list.',
                                      );
                                    }
                                    for (final barcode in barcodes) {
                                      final rawValue = barcode.rawValue;
                                      debugPrint(
                                        '[CAMERA LOG] onDetect (Pharmacy): rawValue = "$rawValue", type = ${barcode.type}',
                                      );
                                      if (rawValue != null &&
                                          rawValue.isNotEmpty) {
                                        debugPrint('QR_CAMERA_STOPPING');
                                        debugPrint(
                                          '[CAMERA LOG] Valid code detected (Pharmacy). Stopping camera...',
                                        );
                                        try {
                                          await _cameraController.stop();
                                          debugPrint('QR_CAMERA_STOPPED');
                                        } catch (e) {
                                          debugPrint(
                                            '[CAMERA LOG] Error stopping camera after detection (Pharmacy): $e',
                                          );
                                        }
                                        _onCodeScanned(rawValue);
                                        break;
                                      } else {
                                        debugPrint(
                                          '[CAMERA LOG] onDetect (Pharmacy): rawValue is null or empty.',
                                        );
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
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: AegisColors.secondary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AegisColors.secondary
                                                .withValues(alpha: 0.8),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
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
                                    color: AegisColors.secondary,
                                  ),
                                ),
                              ),
                              if (_isProcessingCode)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AegisColors.secondary,
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

            // ── Tab 2: Manual Paste Payload ────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AegisSpacing.pagePadding),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AegisSpacing.lg),
                  decoration: BoxDecoration(
                    color: AegisColors.surface,
                    borderRadius: AegisRadius.card,
                    border: Border.all(color: AegisColors.border),
                    boxShadow: AegisShadows.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AegisSpacing.md),
                        decoration: BoxDecoration(
                          color: AegisColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_document,
                          size: 48,
                          color: AegisColors.primary,
                        ),
                      ),
                      const SizedBox(height: AegisSpacing.base),
                      Text(
                        'Manual Payload Verification',
                        style: AegisTypography.headlineSmall.copyWith(
                          color: AegisColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AegisSpacing.xs),
                      Text(
                        'Paste the raw data stream from the client checkout wallet.',
                        textAlign: TextAlign.center,
                        style: AegisTypography.bodySmall.copyWith(
                          color: AegisColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AegisSpacing.lg),
                      TextField(
                        controller: _payloadController,
                        maxLines: 4,
                        style: AegisTypography.monoSmall.copyWith(
                          color: AegisColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Raw Scanned Payload (Data##Signature)',
                          labelStyle: AegisTypography.bodySmall.copyWith(
                            color: AegisColors.textSecondary,
                          ),
                          hintText: 'e.g. RX-1234|Dr. Alex...##0xabc...',
                          hintStyle: AegisTypography.monoSmall.copyWith(
                            color: AegisColors.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.paste_rounded,
                            color: AegisColors.textTertiary,
                            size: AegisIconSize.sm,
                          ),
                          filled: true,
                          fillColor: AegisColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AegisRadius.input,
                            borderSide: const BorderSide(
                              color: AegisColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AegisRadius.input,
                            borderSide: const BorderSide(
                              color: AegisColors.border,
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
                      ),
                      const SizedBox(height: AegisSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: AegisTokens.btnHeight,
                        child: ElevatedButton(
                          onPressed: _isProcessingCode
                              ? null
                              : () => _onCodeScanned(
                                  _payloadController.text.trim(),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AegisColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: AegisRadius.button,
                            ),
                          ),
                          child: Text(
                            'Verify Scanned Payload',
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
