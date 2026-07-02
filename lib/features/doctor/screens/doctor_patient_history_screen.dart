import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorPatientHistoryScreen extends StatelessWidget {
  const DoctorPatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Vault History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: NeonCard(
              neonColor: const Color(0xFF0F52BA),
              child: ListTile(
                title: Text('Prescribed Drug: ${index == 0 ? 'Metformin' : 'Aspirin'}'),
                subtitle: const Text('Date: 2026-06-25\nStatus: Dispensed'),
              ),
            ),
          );
        },
      ),
    );
  }
}
