import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: NeonCard(
              neonColor: Colors.blueGrey,
              child: ListTile(
                title: Text('Prescription ID: RX-00$index'),
                subtitle: const Text('Doctor: Dr. Marcus Vance\nDispensed: Yes'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          );
        },
      ),
    );
  }
}
