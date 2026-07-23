// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Doctor Patient Search & QR Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — QR scanner, timer polling, _handleConnectionInitiated,
//                 _showWaitingDialog, checkConnectionStatus, navigation preserved
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
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
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1000,
  );

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  @override
  void dispose() {
    _searchController.dispose();
    _qrInputController.dispose();
    _connTimer?.cancel();
    _cameraController.dispose();
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
          SnackBar(
            content: Text(
              'Error: $res',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AegisColors.danger,
          ),
        );
      }
    }
  }

  void _showWaitingDialog(String reqId) {
    final appState = Provider.of<AppState>(context, listen: false);
    _connTimer?.cancel();
    int pollCount = 0;

    void pollStatus(BuildContext dialogCtx) async {
      if (!mounted || !dialogCtx.mounted) return;
      pollCount++;

      if (pollCount > 35) {
        _connTimer?.cancel();
        if (Navigator.canPop(dialogCtx)) {
          Navigator.pop(dialogCtx);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connection request timed out. Please try again.',
                style: AegisTypography.bodySmall.copyWith(color: Colors.white),
              ),
              backgroundColor: AegisColors.warning,
            ),
          );
        }
        return;
      }

      final status = await appState.checkConnectionStatus(reqId);

      if (!mounted || !dialogCtx.mounted) return;

      if (status == 'accepted') {
        _connTimer?.cancel();
        if (Navigator.canPop(dialogCtx)) {
          Navigator.pop(dialogCtx);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Consent validated! Session established.',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AegisColors.secondary,
          ),
        );
        try {
          if (_cameraController.value.isRunning) {
            debugPrint('QR_CAMERA_STOPPING');
            debugPrint('[CAMERA LOG] Stopping camera before navigating to Patient History.');
            await _cameraController.stop();
            debugPrint('QR_CAMERA_STOPPED');
          } else {
            debugPrint('[CAMERA LOG] Camera already stopped, skipping stop before navigation.');
          }
        } catch (e) {
          debugPrint('[CAMERA LOG] Non-blocking camera stop error before navigation: $e');
        }

        if (!mounted) return;
        debugPrint('NAVIGATION_AFTER_CAMERA_RELEASE');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorPatientHistoryScreen(
              patientId: appState.activePatientId!,
              patientName: appState.activePatientName!,
            ),
          ),
        ).then((_) {
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              debugPrint('QR_CAMERA_START');
              debugPrint('[CAMERA LOG] Restarting camera after returning from Patient History.');
              if (!_cameraController.value.isRunning) {
                _cameraController.start().then((_) {
                  debugPrint('[CAMERA LOG] Camera restarted successfully.');
                }).catchError((e) {
                  debugPrint('[CAMERA LOG] Non-blocking camera start error: $e');
                });
              }
            } catch (e) {
              debugPrint('[CAMERA LOG] Non-blocking camera start error after returning: $e');
            }
            Provider.of<AppState>(context, listen: false).resumePolling(
              screen: 'DoctorPatientSearchScreen',
              reason: 'Doctor returned to search screen',
            );
          });
        });
      } else if (status == 'rejected') {
        _connTimer?.cancel();
        if (Navigator.canPop(dialogCtx)) {
          Navigator.pop(dialogCtx);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection rejected by patient.',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AegisColors.danger,
          ),
        );
      } else {
        _connTimer = Timer(
          const Duration(milliseconds: 800),
          () => pollStatus(dialogCtx),
        );
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => pollStatus(dialogContext),
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                      color: AegisColors.secondarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: AegisColors.secondary,
                      size: AegisIconSize.sm,
                    ),
                  ),
                  const SizedBox(width: AegisSpacing.sm),
                  Expanded(
                    child: Text(
                      'Waiting for Consent',
                      style: AegisTypography.headlineSmall.copyWith(
                        color: AegisColors.textPrimary,
                      ),
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
                      color: AegisColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),
                  Text(
                    'A connection request has been sent to the patient\'s wallet. Ask the patient to tap "Accept" in their app.',
                    textAlign: TextAlign.center,
                    style: AegisTypography.bodySmall.copyWith(
                      color: AegisColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AegisSpacing.sm),
                    decoration: BoxDecoration(
                      color: AegisColors.background,
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                      border: Border.all(color: AegisColors.border),
                    ),
                    child: Text(
                      'Patient: ${appState.activePatientName ?? "—"}',
                      style: AegisTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AegisColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _connTimer?.cancel();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: AegisTypography.labelMedium.copyWith(
                      color: AegisColors.danger,
                      fontWeight: FontWeight.w700,
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
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'Connect Patient Vault'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AegisSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ────────────────────────────────────
            DoctorCard(
              borderColor: AegisColors.secondary.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(
                horizontal: AegisSpacing.base,
                vertical: AegisSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AegisColors.secondary,
                    size: AegisIconSize.sm,
                  ),
                  const SizedBox(width: AegisSpacing.sm),
                  Expanded(
                    child: Text(
                      'Scan the patient\'s QR from their AegisRx app or enter their ID manually.',
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── Interactive QR Viewfinder ─────────────────────
            sectionHeader('Patient Consent Scan (QR)'),
            const SizedBox(height: AegisSpacing.xs),
            ClinicalQrScannerViewfinder(
              cameraController: _cameraController,
              onScanCompleted: _handleConnectionInitiated,
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── Manual Input (Collapsible Expansion Tile) ──────
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  'Manual Input / Paste QR Content',
                  style: AegisTypography.titleSmall.copyWith(
                    color: AegisColors.textPrimary,
                  ),
                ),
                leading: const Icon(
                  Icons.keyboard_rounded,
                  color: AegisColors.primary,
                  size: AegisIconSize.sm,
                ),
                childrenPadding: const EdgeInsets.all(AegisSpacing.xs),
                textColor: AegisColors.primary,
                iconColor: AegisColors.primary,
                collapsedTextColor: AegisColors.textPrimary,
                collapsedIconColor: AegisColors.textTertiary,
                children: [
                  DoctorCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _qrInputController,
                          style: AegisTypography.monoSmall.copyWith(
                            color: AegisColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Paste QR Code Content',
                            labelStyle: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary,
                            ),
                            hintText: 'e.g. Elena Vance|Elena_Vance_992818',
                            hintStyle: AegisTypography.monoSmall.copyWith(
                              color: AegisColors.textTertiary,
                            ),
                            prefixIcon: const Icon(
                              Icons.qr_code_2_rounded,
                              color: AegisColors.textTertiary,
                              size: AegisIconSize.sm,
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
                            filled: true,
                            fillColor: AegisColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AegisSpacing.base,
                              vertical: AegisSpacing.md,
                            ),
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        DoctorPrimaryButton(
                          label: 'Connect via QR Code',
                          icon: Icons.link_rounded,
                          onPressed: () {
                            final input = _qrInputController.text.trim();
                            if (input.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please scan or paste patient QR content.',
                                    style: AegisTypography.bodySmall.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AegisColors.warning,
                                ),
                              );
                              return;
                            }
                            _handleConnectionInitiated(input);
                          },
                        ),
                        const SizedBox(height: AegisSpacing.base),
                        TextField(
                          controller: _searchController,
                          style: AegisTypography.monoSmall.copyWith(
                            color: AegisColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Enter Patient ID Manually',
                            labelStyle: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary,
                            ),
                            hintText: 'e.g. Elena_Vance_992818',
                            hintStyle: AegisTypography.monoSmall.copyWith(
                              color: AegisColors.textTertiary,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_pin_rounded,
                              color: AegisColors.textTertiary,
                              size: AegisIconSize.sm,
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
                            filled: true,
                            fillColor: AegisColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AegisSpacing.base,
                              vertical: AegisSpacing.md,
                            ),
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        DoctorOutlinedButton(
                          label: 'Initiate Backup Connection',
                          icon: Icons.connecting_airports_rounded,
                          color: AegisColors.primary,
                          onPressed: () {
                            final input = _searchController.text.trim();
                            if (input.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a valid Patient ID',
                                    style: AegisTypography.bodySmall.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AegisColors.warning,
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
            const SizedBox(height: AegisSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Beautiful Real QR Viewfinder (MobileScanner) ───────────────
class ClinicalQrScannerViewfinder extends StatefulWidget {
  final MobileScannerController cameraController;
  final Function(String) onScanCompleted;

  const ClinicalQrScannerViewfinder({
    super.key,
    required this.cameraController,
    required this.onScanCompleted,
  });

  @override
  State<ClinicalQrScannerViewfinder> createState() =>
      _ClinicalQrScannerViewfinderState();
}

class _ClinicalQrScannerViewfinderState
    extends State<ClinicalQrScannerViewfinder>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isProcessingCode = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('QR_CAMERA_START');
    WidgetsBinding.instance.addObserver(this);
    widget.cameraController.addListener(_onCameraControllerStateChanged);
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    widget.cameraController.removeListener(_onCameraControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onCameraControllerStateChanged() {
    if (_isDisposed) return;
    final val = widget.cameraController.value;
    debugPrint('[CAMERA STATE CHANGE] isInitialized: ${val.isInitialized}, '
        'isRunning: ${val.isRunning}, '
        'hasError: ${val.error != null}');
    if (val.error != null) {
      debugPrint('[CAMERA STATE ERROR] Code: ${val.error!.errorCode}, '
          'Message: ${val.error!.errorDetails?.message}, Details: ${val.error!.errorDetails}');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[CAMERA LOG] AppLifecycleState changed to: $state');
    if (_isDisposed) {
      debugPrint('[CAMERA LOG] Lifecycle state change ignored: disposed.');
      return;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('[CAMERA LOG] App paused/inactive, stopping camera...');
      try {
        if (widget.cameraController.value.isRunning) {
          widget.cameraController.stop().then((_) {
            debugPrint('[CAMERA LOG] Camera stopped successfully via lifecycle.');
          }).catchError((e) {
            debugPrint('[CAMERA LOG] Error in stop() future via lifecycle: $e');
          });
        }
      } catch (e) {
        debugPrint('[CAMERA LOG] Exception stopping camera via lifecycle: $e');
      }
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[CAMERA LOG] App resumed, starting camera...');
      try {
        if (!widget.cameraController.value.isRunning) {
          widget.cameraController.start().then((_) {
            debugPrint('[CAMERA LOG] Camera started successfully via lifecycle.');
          }).catchError((e) {
            debugPrint('[CAMERA LOG] Error in start() future via lifecycle: $e');
          });
        } else {
          debugPrint('[CAMERA LOG] Camera already running. isRunning: ${widget.cameraController.value.isRunning}');
        }
      } catch (e) {
        debugPrint('[CAMERA LOG] Exception starting camera via lifecycle: $e');
      }
    }
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
          backgroundColor: AegisColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AegisRadius.card,
            side: const BorderSide(color: AegisColors.border, width: 1),
          ),
          title: Text(
            'Scan Custom QR / Session ID',
            style: AegisTypography.headlineSmall.copyWith(
              color: AegisColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter or paste any custom patient session token (e.g. name|patientId):',
                  style: AegisTypography.bodySmall.copyWith(
                    color: AegisColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AegisSpacing.md),
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: AegisTypography.monoSmall.copyWith(
                    color: AegisColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Custom Session QR Content',
                    labelStyle: AegisTypography.bodySmall.copyWith(
                      color: AegisColors.textSecondary,
                    ),
                    hintText: 'e.g. John Doe|john_doe_992818',
                    hintStyle: AegisTypography.monoSmall.copyWith(
                      color: AegisColors.textTertiary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AegisRadius.input,
                      borderSide: const BorderSide(color: AegisColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AegisRadius.input,
                      borderSide: const BorderSide(
                        color: AegisColors.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AegisColors.background,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AegisTypography.labelMedium.copyWith(
                  color: AegisColors.danger,
                  fontWeight: FontWeight.w700,
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
                backgroundColor: AegisColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
              ),
              child: Text(
                'Start Scan',
                style: AegisTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
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
        color: const Color(0xFF0F172A), // Dark clinical grid bg
        borderRadius: AegisRadius.card,
        border: Border.all(
          color: AegisColors.tertiary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: AegisRadius.card,
        child: Stack(
          children: [
            // Real camera viewport using MobileScanner package
            Positioned.fill(
              child: MobileScanner(
                controller: widget.cameraController,
                errorBuilder: (context, error, child) {
                  debugPrint('[MOBILE_SCANNER_ERROR] Error occurred in MobileScanner widget:\n'
                      '  Code: ${error.errorCode}\n'
                      '  Message: ${error.errorDetails?.message}\n'
                      '  Details: ${error.errorDetails}');
                  if (error.errorCode ==
                          MobileScannerErrorCode.permissionDenied ||
                      error.errorCode == MobileScannerErrorCode.unsupported) {
                    return Container(
                      color: const Color(0xFF0F172A),
                      padding: const EdgeInsets.all(AegisSpacing.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.no_photography_outlined,
                            color: AegisColors.warning,
                            size: AegisIconSize.lg,
                          ),
                          const SizedBox(height: AegisSpacing.xs),
                          Text(
                            'Camera Access Restricted',
                            style: AegisTypography.titleSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AegisSpacing.xs),
                          Text(
                            'Camera permission is denied or unsupported. Use manual input below to connect patient vault.',
                            textAlign: TextAlign.center,
                            style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary,
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
                  debugPrint('[CAMERA LOG] onDetect: detected ${capture.barcodes.length} barcodes.');
                  if (_isProcessingCode) {
                    debugPrint('[CAMERA LOG] onDetect: already processing, skipping.');
                    return;
                  }
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isEmpty) {
                    debugPrint('[CAMERA LOG] onDetect: empty barcode list.');
                  }
                  for (final barcode in barcodes) {
                    final rawValue = barcode.rawValue;
                    debugPrint('[CAMERA LOG] onDetect: rawValue = "$rawValue", type = ${barcode.type}');
                    if (rawValue != null && rawValue.isNotEmpty) {
                      setState(() {
                        _isProcessingCode = true;
                      });
                      debugPrint('QR_DETECTED');
                      debugPrint('QR_CAMERA_STOPPING');
                      debugPrint('[CAMERA LOG] Valid code detected. Stopping camera...');
                      try {
                        await widget.cameraController.stop();
                        debugPrint('QR_CAMERA_STOPPED');
                      } catch (e) {
                        debugPrint('[CAMERA LOG] Error stopping camera after detection: $e');
                      }
                      widget.onScanCompleted(rawValue);
                      Timer(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _isProcessingCode = false;
                          });
                        }
                      });
                      break;
                    } else {
                      debugPrint('[CAMERA LOG] onDetect: rawValue is null or empty.');
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
                      color: AegisColors.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: AegisColors.secondary.withValues(alpha: 0.8),
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
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: AegisColors.secondary,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: AegisSpacing.base),
                      Text(
                        'Processing Vault Token...',
                        style: AegisTypography.labelMedium.copyWith(
                          color: AegisColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verifying cryptographic P2P access...',
                        style: AegisTypography.monoSmall.copyWith(
                          color: AegisColors.textTertiary,
                        ),
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
                      size: AegisIconSize.xs,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Simulate Scan',
                      style: AegisTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AegisColors
                          .tertiary, // AI Purple for simulate AI scan
                      padding: const EdgeInsets.symmetric(
                        horizontal: AegisSpacing.base,
                        vertical: AegisSpacing.xs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AegisRadius.xs),
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
      ..color = AegisColors
          .secondary // Teal accent
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
