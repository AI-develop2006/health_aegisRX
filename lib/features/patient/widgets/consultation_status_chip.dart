import 'package:flutter/material.dart';

class ConsultationStatusChip extends StatelessWidget {
  final String status;

  const ConsultationStatusChip({super.key, required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'accepted':
        return const Color(0xFF00A86B); // emerald green
      case 'pending':
        return Colors.orangeAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.0),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
