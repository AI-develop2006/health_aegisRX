import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class PharmacyScanScreen extends StatelessWidget {
  const PharmacyScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Scanner'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: NeonCard(
            neonColor: const Color(0xFF0F52BA),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF0F52BA)),
                const SizedBox(height: 24),
                const Text(
                  'Scan Patient Pharmacy QR Code',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Trigger camera scan emulation
                  },
                  child: const Text('Initialize Camera'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
