import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryTracker extends StatelessWidget {
  const InventoryTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInventoryRow(context, 'Metformin 500mg', 12, 30),
        const SizedBox(height: 12),
        _buildInventoryRow(context, 'Aspirin 75mg', 25, 30),
      ],
    );
  }

  Widget _buildInventoryRow(BuildContext context, String name, int remaining, int total) {
    final ratio = remaining / total;
    Color urgencyColor;
    if (ratio < 0.3) {
      urgencyColor = Colors.redAccent;
    } else if (ratio < 0.5) {
      urgencyColor = const Color(0xFFF59E0B); // Amber
    } else {
      urgencyColor = const Color(0xFF10B981); // Green
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '$remaining / $total pills',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? Colors.black.withOpacity(0.08)
                : Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
          ),
        ),
      ],
    );
  }
}
