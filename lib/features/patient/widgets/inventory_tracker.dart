// ─────────────────────────────────────────────────────────────
// AegisRx Patient Widget — InventoryTracker
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';
import 'package:health_lock/shared/models/prescription.dart';

class InventoryTracker extends StatelessWidget {
  final List<Prescription> prescriptions;

  const InventoryTracker({super.key, required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    final activeRxs = prescriptions.where((rx) => !rx.isDispensed).toList();
    final List<Widget> rows = [];

    for (var rx in activeRxs) {
      for (var med in rx.medicines) {
        int totalDays = 30;
        final durParts = med.duration.split(' ');
        if (durParts.isNotEmpty) {
          totalDays = int.tryParse(durParts.first) ?? 30;
        }

        int dailyCount = 0;
        if (med.morning) dailyCount++;
        if (med.afternoon) dailyCount++;
        if (med.evening) dailyCount++;
        if (med.night) dailyCount++;
        if (dailyCount == 0) dailyCount = 1;

        final totalPills = totalDays * dailyCount;
        int remainingPills = totalPills;
        try {
          final rxDate = DateTime.parse(rx.date);
          final elapsedDays = DateTime.now().difference(rxDate).inDays;
          if (elapsedDays > 0) {
            remainingPills = max(0, totalPills - (elapsedDays * dailyCount));
          }
        } catch (_) {
          remainingPills = (totalPills * 0.6).round();
        }

        rows.add(_buildInventoryRow(
            '${med.name} ${med.strength}'.trim(), remainingPills, totalPills));
        rows.add(const SizedBox(height: AegisSpacing.md));
      }
    }

    if (rows.isEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: AegisSpacing.sm),
        child: Text(
          'No active medications in vault.',
          style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textTertiary),
        ),
      ));
    } else {
      rows.removeLast();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Status',
          style: AegisTypography.titleMedium.copyWith(color: AegisColors.textPrimary),
        ),
        const SizedBox(height: AegisSpacing.base),
        ...rows,
      ],
    );
  }

  Widget _buildInventoryRow(String name, int remaining, int total) {
    final ratio = total > 0 ? remaining / total : 0.0;

    Color urgencyColor;
    Color trackColor;
    if (ratio < 0.3) {
      urgencyColor = AegisColors.danger;
      trackColor = AegisColors.dangerLight;
    } else if (ratio < 0.55) {
      urgencyColor = AegisColors.warning;
      trackColor = AegisColors.warningLight;
    } else {
      urgencyColor = AegisColors.success;
      trackColor = AegisColors.successLight;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: AegisTypography.titleSmall.copyWith(color: AegisColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AegisSpacing.sm),
            Text(
              '$remaining / $total pills',
              style: AegisTypography.monoSmall.copyWith(color: AegisColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AegisSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AegisRadius.xs),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
          ),
        ),
      ],
    );
  }
}
