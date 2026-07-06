import 'package:flutter/material.dart';

class TokenStatusChip extends StatelessWidget {
  final bool isDispensed;

  const TokenStatusChip({super.key, required this.isDispensed});

  @override
  Widget build(BuildContext context) {
    final chipColor = isDispensed ? Colors.redAccent : const Color(0xFF00A86B);
    final chipText = isDispensed ? 'BURNED / DISPENSED' : 'ACTIVE / AVAILABLE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor, width: 1.0),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
