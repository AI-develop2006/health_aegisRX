import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class PharmacyDispenseScreen extends StatelessWidget {
  const PharmacyDispenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispense Medications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const NeonCard(
              neonColor: Color(0xFF0F52BA),
              child: ListTile(
                title: Text('Ready for Dispensation'),
                subtitle: Text('Drug: Metformin 500mg\nQty: 30 pills\nRefills remaining: 2'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Trigger token burn and ledger entry
              },
              child: const Text('Burn Token & Dispense'),
            ),
          ],
        ),
      ),
    );
  }
}
