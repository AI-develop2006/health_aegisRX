import 'package:flutter/material.dart';

class AuditBadge extends StatelessWidget {
  final int severityScore;

  const AuditBadge({super.key, required this.severityScore});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = const Color(0xFF00A86B); // emerald green
    if (severityScore >= 8) {
      badgeColor = Colors.redAccent;
    } else if (severityScore >= 5) {
      badgeColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor, width: 1.0),
      ),
      child: Text(
        'Score: $severityScore/10',
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
