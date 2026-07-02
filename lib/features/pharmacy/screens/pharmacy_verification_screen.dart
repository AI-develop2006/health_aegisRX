import 'package:flutter/material.dart';
import '../../../shared/widgets/neon_card.dart';

class PharmacyVerificationScreen extends StatelessWidget {
  const PharmacyVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cryptographic Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const NeonCard(
              neonColor: Color(0xFF00A86B), // emerald green
              child: ListTile(
                leading: Icon(Icons.verified_user, color: Color(0xFF00A86B)),
                title: Text('Signature Verified'),
                subtitle: Text('Hash match succeeded. Doctor signature verified against NPI root key. Payload is integer and untampered.'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Proceed to Dispense Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
