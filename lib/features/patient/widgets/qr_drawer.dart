import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:health_lock/core/constants/app_colors.dart';
import 'package:health_lock/core/theme/app_theme.dart';
import 'package:health_lock/shared/models/prescription.dart';
import 'package:health_lock/main.dart'; // To access SimulationState

class QrDrawer extends StatelessWidget {
  final Prescription prescription;

  const QrDrawer({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SimulationState>(context);

    return GlassCard(
      borderRadius: 16,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PHARMACY CHECKOUT QR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.clinicalBlue,
                  letterSpacing: 0.8,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.mutedText,
                  size: 16,
                ),
                onPressed: () => state.selectPrescription(null),
              ),
            ],
          ),
          Divider(color: AppColors.borderWhite, height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: '${state.backendUrl}/pharmacy-portal?rxId=${prescription.id}',
              version: QrVersions.auto,
              size: 150,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            prescription.disease,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan at pharmacy to dispense medications',
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${state.backendUrl}/pharmacy-portal?rxId=${prescription.id}',
            style: AppTheme.monoStyle.copyWith(
              fontSize: 9,
              color: AppColors.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Visual QR Code Matrix Painter utilizing hash strings
class QrMatrixPainter extends CustomPainter {
  final String hash;
  final Color activeColor;

  QrMatrixPainter({
    required this.hash,
    this.activeColor = AppColors.primaryText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cellCount = 15;
    final cellSize = size.width / cellCount;
    final random = Random(hash.hashCode);

    for (int r = 0; r < cellCount; r++) {
      for (int c = 0; c < cellCount; c++) {
        // Draw standard QR Finder Patterns at corners
        bool isFinder =
            (r < 4 && c < 4) ||
            (r < 4 && c >= cellCount - 4) ||
            (r >= cellCount - 4 && c < 4);

        if (isFinder) {
          paint.color = activeColor;
          bool draw =
              (r == 0 || r == 3 || c == 0 || c == 3) ||
              (r == 1 && c == 1) ||
              (r == 1 && c == 2) ||
              (r == 2 && c == 1) ||
              (r == 2 && c == 2);

          if (r < 4 && c >= cellCount - 4) {
            int localC = c - (cellCount - 4);
            draw =
                (r == 0 || r == 3 || localC == 0 || localC == 3) ||
                (r == 1 && localC == 1) ||
                (r == 1 && localC == 2) ||
                (r == 2 && localC == 1) ||
                (r == 2 && localC == 2);
          }
          if (r >= cellCount - 4 && c < 4) {
            int localR = r - (cellCount - 4);
            draw =
                (localR == 0 || localR == 3 || c == 0 || c == 3) ||
                (localR == 1 && c == 1) ||
                (localR == 1 && c == 2) ||
                (localR == 2 && c == 1) ||
                (localR == 2 && c == 2);
          }

          if (draw) {
            canvas.drawRect(
              Rect.fromLTWH(
                c * cellSize + 0.5,
                r * cellSize + 0.5,
                cellSize - 1,
                cellSize - 1,
              ),
              paint,
            );
          }
        } else {
          final active = random.nextBool() || random.nextDouble() > 0.65;
          paint.color = active
              ? activeColor.withValues(alpha: 0.85)
              : AppColors.borderWhite.withValues(alpha: 0.6);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellSize + 1.5,
                r * cellSize + 1.5,
                cellSize - 3,
                cellSize - 3,
              ),
              const Radius.circular(1.0),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrMatrixPainter oldDelegate) =>
      oldDelegate.hash != hash;
}
