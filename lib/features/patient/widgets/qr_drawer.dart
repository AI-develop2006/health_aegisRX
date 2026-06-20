import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:health_lock/core/constants/app_colors.dart';

import 'package:health_lock/shared/models/prescription.dart';
import 'package:health_lock/main.dart'; // To access SimulationState

/// Shows the QR code for a prescription as a popup modal dialog
void showQrPopup(BuildContext context, Prescription prescription) {
  final state = Provider.of<SimulationState>(context, listen: false);

  // Format QR code data as: DATA##SIGNATURE
  final String medsJson = jsonEncode(prescription.medicines.map((m) => m.toJson()).toList());
  final String rawPayload = '${prescription.id}|${prescription.doctorName}|${prescription.hospitalName}|${prescription.patientName}|${prescription.disease}|${prescription.date}|${prescription.time}|$medsJson|${prescription.doctorSignId}';
  final String qrCodeData = '$rawPayload##${prescription.signature}';

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'QR Code Popup',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.borderWhite,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.tintViolet,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: AppColors.pharmacyViolet,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'PHARMACY CHECKOUT QR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pharmacyViolet,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.mutedText,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderWhite, height: 1),
                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderWhite),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pharmacyViolet.withValues(alpha: 0.05),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrCodeData,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Prescription info
                  Text(
                    prescription.disease,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dr. ${prescription.doctorName} • ${prescription.hospitalName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Instruction
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.tintViolet,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.pharmacyViolet.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 14, color: AppColors.pharmacyViolet),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Scan at pharmacy to dispense medications',
                            style: TextStyle(fontSize: 11, color: AppColors.pharmacyViolet, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${state.backendUrl}/pharmacy-portal?rxId=${prescription.id}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.mutedText,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Legacy inline QR Drawer — kept for backward compatibility but now triggers popup
class QrDrawer extends StatelessWidget {
  final Prescription prescription;

  const QrDrawer({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    // Auto-trigger popup on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showQrPopup(context, prescription);
      // Deselect prescription after showing popup
      final state = Provider.of<SimulationState>(context, listen: false);
      state.selectPrescription(null);
    });
    return const SizedBox.shrink();
  }
}
