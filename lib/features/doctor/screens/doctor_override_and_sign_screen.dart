import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/glassmorphic_button.dart';

class DoctorOverrideAndSignScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String chiefComplaint;
  final String diagnosis;
  final List<Map<String, String>> medications;
  final String riskBand;
  final int riskScore;
  final List<String> riskReasons;

  const DoctorOverrideAndSignScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.medications,
    required this.riskBand,
    required this.riskScore,
    required this.riskReasons,
  });

  @override
  State<DoctorOverrideAndSignScreen> createState() => _DoctorOverrideAndSignScreenState();
}

class _DoctorOverrideAndSignScreenState extends State<DoctorOverrideAndSignScreen> {
  final _rationaleController = TextEditingController();
  String _overrideCategory = 'Clinical judgment';
  bool _isAcknowledged = false;
  bool _isSigning = false;

  @override
  void dispose() {
    _rationaleController.dispose();
    super.dispose();
  }

  String _generateMockHash() {
    final random = Random();
    const chars = '0123456789abcdef';
    String hash = '0x';
    for (int i = 0; i < 40; i++) {
      hash += chars[random.nextInt(chars.length)];
    }
    return hash;
  }

  void _signAndCommit() {
    final bool requiresOverride = widget.riskBand == 'HIGH' || widget.riskBand == 'CRITICAL';

    if (requiresOverride) {
      if (_rationaleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify the clinical rationale justification.')),
        );
        return;
      }
      if (!_isAcknowledged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please check the Physician Acknowledgement box.')),
        );
        return;
      }
    }

    setState(() {
      _isSigning = true;
    });

    // Simulate cryptographic vault signing & blockchain ledger commit
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isSigning = false;
      });

      final txHash = _generateMockHash();
      final appState = Provider.of<AppState>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text('Prescription Committed', style: GoogleFonts.sora(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Prescription has been encrypted and signed.'),
                  const SizedBox(height: 12),
                  const Text(
                    'Ledger Tx Hash:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      txHash,
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Token status: Active (Burn on Dispense)',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // End doctor-patient consultation session
                  appState.endDoctorPatientSession();

                  // Pop alert dialog
                  Navigator.pop(context);

                  // Pop override screen and editor screen back to dashboard
                  Navigator.pop(context); // pops Override screen
                  Navigator.pop(context); // pops Editor screen
                },
                child: const Text('Back to Dashboard', style: TextStyle(color: Color(0xFF818CF8))),
              )
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bool requiresOverride = widget.riskBand == 'HIGH' || widget.riskBand == 'CRITICAL';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Clinical Verification',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient and Diagnosis details
                Text(
                  'Encrypted Summary',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                NeonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient: ${widget.patientName} (${widget.patientId})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text('Chief Complaint: ${widget.chiefComplaint}'),
                      Text('Provisional Diagnosis: ${widget.diagnosis}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Medicines Summary List
                Text(
                  'Medications list',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.medications.length,
                  itemBuilder: (context, index) {
                    final med = widget.medications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.medication_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med['name']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Strength: ${med['strength']} • Route: ${med['route']} • Freq: ${med['frequency']} • Dur: ${med['duration']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // AI Risk warning info
                if (requiresOverride) ...[
                  Text(
                    'Safety Violations Identified',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                  NeonCard(
                    neonColor: Colors.redAccent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              'AI Risk: ${widget.riskBand} (${widget.riskScore}/100)',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...widget.riskReasons.map(
                          (reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Colors.redAccent)),
                                Expanded(child: Text(reason, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Override text area
                  Text(
                    'Override Justification',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _overrideCategory,
                    decoration: const InputDecoration(labelText: 'Override Category *'),
                    items: ['Clinical judgment', 'Emergency', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _overrideCategory = val ?? 'Clinical judgment';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _rationaleController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Override Rationale / Reason *',
                      hintText: 'e.g. Patient has tolerated drug previously without issues, monitor vitals.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'I acknowledge the risks and take responsibility as the treating physician.',
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                    ),
                    value: _isAcknowledged,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _isAcknowledged = val ?? false;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          // Sign & Commit overlay button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: theme.scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSigning
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back to Editor'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassmorphicButton(
                      baseColor: requiresOverride ? Colors.redAccent : theme.colorScheme.primary,
                      onPressed: _isSigning ? () {} : _signAndCommit,
                      child: _isSigning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign & Commit Rx'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
