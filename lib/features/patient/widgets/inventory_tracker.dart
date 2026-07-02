import 'package:flutter/material.dart';

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
        _buildInventoryRow('Metformin 500mg', 12, 30),
        const SizedBox(height: 8),
        _buildInventoryRow('Aspirin 75mg', 25, 30),
      ],
    );
  }

  Widget _buildInventoryRow(String name, int remaining, int total) {
    final ratio = remaining / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 14)),
            Text('$remaining / $total pills', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(
            ratio < 0.3 ? Colors.redAccent : const Color(0xFF0F52BA),
          ),
        ),
      ],
    );
  }
}
