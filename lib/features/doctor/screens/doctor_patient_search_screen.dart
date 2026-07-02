import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorPatientSearchScreen extends StatelessWidget {
  const DoctorPatientSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registry Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Enter Sovereign patient ID...',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: NeonCard(
                      neonColor: Colors.blueGrey,
                      child: ListTile(
                        title: Text(index == 0 ? 'Priya Sharma' : 'Elena Vance'),
                        subtitle: Text(index == 0 ? 'ID: priya_123' : 'ID: elena_vance'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
