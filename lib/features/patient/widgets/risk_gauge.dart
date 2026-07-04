import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiskGauge extends StatelessWidget {
  final int severityScore; // 1-10

  const RiskGauge({super.key, required this.severityScore});

  Color _getRiskColor() {
    if (severityScore >= 8) return Colors.redAccent;
    if (severityScore >= 5) return Colors.orangeAccent;
    return const Color(0xFF10B981); // emerald green
  }

  String _getRiskText() {
    if (severityScore >= 8) return 'CRITICAL';
    if (severityScore >= 5) return 'MEDIUM RISK';
    return 'LOW RISK';
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

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
                backgroundColor: isLight ? Colors.black12 : Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              ),
            ),
            Column(
              children: [
                Text(
                  '$severityScore/10',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                ),
                Text(
                  _getRiskText(),
                  style: TextStyle(
                    fontSize: 10,
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
