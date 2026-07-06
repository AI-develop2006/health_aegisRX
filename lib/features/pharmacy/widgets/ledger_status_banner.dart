import 'package:flutter/material.dart';

class LedgerStatusBanner extends StatelessWidget {
  final String txHash;

  const LedgerStatusBanner({super.key, required this.txHash});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00A86B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF00A86B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ledger Transaction Committed:\n$txHash',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white70),
            ),
          )
        ],
      ),
    );
  }
}
