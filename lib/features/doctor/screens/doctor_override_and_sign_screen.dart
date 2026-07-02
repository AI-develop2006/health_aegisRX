import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorOverrideAndSignScreen extends StatefulWidget {
  const DoctorOverrideAndSignScreen({super.key});

  @override
  State<DoctorOverrideAndSignScreen> createState() => _DoctorOverrideAndSignScreenState();
}

class _DoctorOverrideAndSignScreenState extends State<DoctorOverrideAndSignScreen> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Override & Sign'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            NeonCard(
              neonColor: Colors.redAccent,
              child: Column(
                children: [
                  const Text('Explain Override Justification', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Enter clinical justification...'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Apply cryptographic signature logic
              },
              child: const Text('Confirm Override & Sign Rx'),
            ),
          ],
        ),
      ),
    );
  }
}
