import 'package:flutter/material.dart';

class InteractionWarningCard extends StatelessWidget {
  final String message;
  final String riskLevel; // LOW, MEDIUM, HIGH

  const InteractionWarningCard({
    super.key,
    required this.message,
    required this.riskLevel,
  });

  Color _getRiskColor() {
    if (riskLevel.toUpperCase() == 'HIGH') return Colors.redAccent;
    if (riskLevel.toUpperCase() == 'MEDIUM') return Colors.orangeAccent;
    return Colors.yellowAccent;
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    return Card(
      color: Colors.black45,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: riskColor, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.report, color: riskColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            )
          ],
        ),
      ),
    );
  }
}
