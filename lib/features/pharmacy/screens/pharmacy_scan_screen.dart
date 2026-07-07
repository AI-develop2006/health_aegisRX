import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import 'pharmacy_verification_screen.dart';

class PharmacyScanScreen extends StatefulWidget {
  const PharmacyScanScreen({super.key});

  @override
  State<PharmacyScanScreen> createState() => _PharmacyScanScreenState();
}

class _PharmacyScanScreenState extends State<PharmacyScanScreen> {
  final _payloadController = TextEditingController();

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  void _submitScan() {
    final fullPayload = _payloadController.text.trim();
    if (fullPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste a scanned prescription payload.')),
      );
      return;
    }

    // Expected format: payload##signature
    final parts = fullPayload.split('##');
    if (parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid payload format. Must contain "##" separator.')),
      );
      return;
    }

    final rawPayload = parts[0];
    final signature = parts[1];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyVerificationScreen(
          rawPayload: rawPayload,
          signature: signature,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Scanner', style: TextStyle(fontFamily: 'Sora')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).clearSession();
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Sora'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste the raw data stream from the client checkout wallet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _payloadController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Raw Scanned Payload (Data##Signature)',
                    hintText: 'e.g. RX-1234|Dr. Alex...##0xabc...',
                    prefixIcon: Icon(Icons.paste_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicButton(
                  baseColor: const Color(0xFF0F52BA),
                  onPressed: _submitScan,
                  child: const Text('Verify Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
