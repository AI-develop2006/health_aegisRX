import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConsultationStatusChip extends StatelessWidget {
  final String status;

  const ConsultationStatusChip({super.key, required this.status});

  // 60-30-10 Design Tokens
  static const _teal = Color(0xFF2E8B90);
  static const _amber = Color(0xFFD97736);
  static const _red = Color(0xFFB33A3A);
  static const _border = Color(0xFFB88E74);

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'accepted':
        return _teal;
      case 'pending':
        return _amber;
      case 'rejected':
        return _red;
      default:
        return _border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final label = status.toLowerCase() == 'inactive'
        ? 'NO SESSION'
        : status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
