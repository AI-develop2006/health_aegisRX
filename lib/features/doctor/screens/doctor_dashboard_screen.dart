import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practitioner Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          NeonCard(
            neonColor: const Color(0xFF0F52BA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected Encounters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Patient: Elena Vance'),
                  subtitle: const Text('Status: Active Session Established'),
                  trailing: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Write Rx'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
