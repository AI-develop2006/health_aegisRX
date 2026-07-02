import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorAiAuditResultScreen extends StatelessWidget {
  const DoctorAiAuditResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Audit Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const NeonCard(
              neonColor: Colors.orangeAccent,
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.orangeAccent),
                title: Text('Medium Risk Warning'),
                subtitle: Text('Drug-Allergy interaction detected: Patient is allergic to Penicillin. Suggested alternative: Ciprofloxacin.'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Proceed to Override Decision'),
            ),
          ],
        ),
      ),
    );
  }
}
