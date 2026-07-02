import 'package:flutter/material.dart';

class RiskGauge extends StatelessWidget {
  final int severityScore; // 1-10

  const RiskGauge({super.key, required this.severityScore});

  Color _getRiskColor() {
    if (severityScore >= 8) return Colors.redAccent;
    if (severityScore >= 5) return Colors.orangeAccent;
    return const Color(0xFF00A86B); // emerald green
  }

  String _getRiskText() {
    if (severityScore >= 8) return 'CRITICAL';
    if (severityScore >= 5) return 'MEDIUM RISK';
    return 'LOW RISK';
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: severityScore / 10.0,
                strokeWidth: 12,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              ),
            ),
            Column(
              children: [
                Text(
                  '$severityScore/10',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  _getRiskText(),
                  style: TextStyle(fontSize: 10, color: riskColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
