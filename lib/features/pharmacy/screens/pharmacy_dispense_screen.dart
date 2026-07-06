import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/glassmorphic_button.dart';

class PharmacyDispenseScreen extends StatefulWidget {
  final String prescriptionId;
  final String prescriptionName;
  final List medicines;

  const PharmacyDispenseScreen({
    super.key,
    required this.prescriptionId,
    required this.prescriptionName,
    required this.medicines,
  });

  @override
  State<PharmacyDispenseScreen> createState() => _PharmacyDispenseScreenState();
}

class _PharmacyDispenseScreenState extends State<PharmacyDispenseScreen> {
  bool _isDispensing = false;

  void _dispense() async {
    setState(() {
      _isDispensing = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final res = await appState.dispensePrescription(widget.prescriptionId);

    setState(() {
      _isDispensing = false;
    });

    if (res['error'] != null || res['detail'] != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispense failed: ${res['error'] ?? res['detail']}')),
        );
      }
      return;
    }

    final txHash = res['onchain_tx_hash'] ?? '0x';

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Dispensation Complete', style: TextStyle(fontFamily: 'Sora')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cryptographic single-use token burned successfully.'),
              const SizedBox(height: 12),
              const Text('On-chain ledger update transaction:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  txHash,
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close dispense screen
                Navigator.pop(context); // close verification screen
                Navigator.pop(context); // close scanner screen
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispense Medications', style: TextStyle(fontFamily: 'Sora')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            NeonCard(
              neonColor: const Color(0xFF0F52BA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready for Dispensation',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('Prescription ID: ${widget.prescriptionId}'),
                  Text('Patient: ${widget.prescriptionName}'),
                  const SizedBox(height: 12),
                  const Text('Medications to Handout:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...widget.medicines.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• ${m['name']} (${m['interval']})'),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GlassmorphicButton(
                baseColor: const Color(0xFF0F52BA),
                onPressed: _isDispensing ? null : _dispense,
                child: _isDispensing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Burn Token & Dispense', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
