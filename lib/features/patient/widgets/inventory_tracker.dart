import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_lock/shared/models/prescription.dart';

class InventoryTracker extends StatelessWidget {
  final List<Prescription> prescriptions;

  const InventoryTracker({super.key, required this.prescriptions});

  // 60-30-10 Design Tokens
  static const _text = Color(0xFF4A3325);
  static const _sub = Color(0xFFD4A387);
  static const _border = Color(0xFFB88E74);
  static const _teal = Color(0xFF2E8B90);
  static const _amber = Color(0xFFD97736);
  static const _red = Color(0xFFB33A3A);

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

        rows.add(_buildInventoryRow('${med.name} ${med.strength}'.trim(), remainingPills, totalPills));
        rows.add(const SizedBox(height: 14));
      }
    }

    if (rows.isEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'No active medications in vault.',
          style: GoogleFonts.inter(fontSize: 14, color: _sub),
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
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _text,
          ),
        ),
        const SizedBox(height: 16),
        ...rows,
      ],
    );
  }

  Widget _buildInventoryRow(String name, int remaining, int total) {
    final ratio = remaining / total;
    Color urgencyColor;
    if (ratio < 0.3) {
      urgencyColor = _red;
    } else if (ratio < 0.55) {
      urgencyColor = _amber;
    } else {
      urgencyColor = _teal;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
            ),
            Text(
              '$remaining / $total pills',
              style: GoogleFonts.jetBrainsMono(
                color: _sub,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: _border.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
          ),
        ),
      ],
    );
  }
}
