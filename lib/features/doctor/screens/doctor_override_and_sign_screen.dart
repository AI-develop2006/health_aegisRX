import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../doctor_theme.dart';

class DoctorOverrideAndSignScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String chiefComplaint;
  final String diagnosis;
  final List<Map<String, dynamic>> medications;
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
  State<DoctorOverrideAndSignScreen> createState() =>
      _DoctorOverrideAndSignScreenState();
}

class _DoctorOverrideAndSignScreenState
    extends State<DoctorOverrideAndSignScreen> {
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
    final bool requiresOverride =
        widget.riskBand == 'HIGH' || widget.riskBand == 'CRITICAL';

    if (requiresOverride) {
      if (_rationaleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please specify the clinical rationale.')),
        );
        return;
      }
      if (!_isAcknowledged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please check the Physician Acknowledgement box.')),
        );
        return;
      }
    }

    setState(() => _isSigning = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> medicinesPayload =
        widget.medications.map((med) {
      return {
        'name': '${med['name']} ${med['strength']}'.trim(),
        'interval': med['frequency'] ?? 'Once daily',
        'morning': med['morning'] == true,
        'afternoon': med['afternoon'] == true,
        'evening': med['evening'] == true,
        'night': med['night'] == true,
        'beforeFood': med['beforeFood'] == true,
        'afterFood': med['afterFood'] == true,
        'customInstruction': med['instructions'] ?? '',
      };
    }).toList();

    final randomRxId = 'RX-${1000 + Random().nextInt(9000)}';
    final rxData = {
      'id': randomRxId,
      'doctorName': appState.doctorLicense != null
          ? 'Dr. ${appState.doctorLicense}'
          : 'Dr. Alexander Vance',
      'hospitalName':
          appState.doctorHospital ?? 'Metropolitan Hospital Centre',
      'patientName': widget.patientName,
      'patient_id': widget.patientId,
      'disease': widget.diagnosis,
      'date': dateStr,
      'time': timeStr,
      'medicines': medicinesPayload,
      'doctorSignId': appState.doctorLicense ?? '889218',
      'riskBand': widget.riskBand,
      'overrideReason':
          requiresOverride ? _rationaleController.text.trim() : null,
    };

    appState.createPrescription(rxData).then((res) {
      if (!mounted) return;
      setState(() => _isSigning = false);

      if (res['error'] != null || res['detail'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${res['error'] ?? res['detail'] ?? 'Prescription failed'}')),
        );
        return;
      }

      final txHash = res['onchain_tx_hash'] ?? (appState.useMockFrontend ? _generateMockHash() : null);
      if (txHash == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('On-chain signature failed: EVM node transaction reverted. Mocks disabled.'),
          ),
        );
        return;
      }
      final signature = res['signature'] ?? 'Unknown signature';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Dr.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Dr.border),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Dr.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: Dr.green, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Prescription Committed',
                      style: Dr.heading(16),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Prescription has been encrypted, signed, and recorded on the blockchain ledger.',
                    style: Dr.meta(13),
                  ),
                  const SizedBox(height: 16),
                  Text('Ledger Transaction Hash',
                      style: Dr.heading(12)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Dr.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Dr.border),
                    ),
                    child: Text(
                      txHash,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, color: Dr.green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Cryptographic Signature', style: Dr.heading(12)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Dr.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Dr.border),
                    ),
                    child: Text(
                      signature,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: Dr.sub),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const DoctorStatusBadge(
                    label: 'Active — Burn on Dispense',
                    color: Dr.green,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  appState.endDoctorPatientSession();
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Back to Dashboard',
                    style: GoogleFonts.inter(
                        color: Dr.green, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool requiresOverride =
        widget.riskBand == 'HIGH' || widget.riskBand == 'CRITICAL';

    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'Clinical Verification & Sign'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Risk Alert Banner (shown only if required) ──
                if (requiresOverride) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Dr.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Dr.red.withOpacity(0.4), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.dangerous_rounded,
                                color: Dr.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI Risk: ${widget.riskBand} · Score ${widget.riskScore}/100',
                                style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Dr.red),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...widget.riskReasons.map((reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('· ',
                                      style: TextStyle(
                                          color: Dr.red,
                                          fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(reason,
                                        style: Dr.body(13)
                                            .copyWith(color: Dr.red)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // ── Safe Banner ─────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Dr.green.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Dr.green.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Dr.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI Safety Audit Passed — Safe to Dispense.',
                            style: Dr.body(13).copyWith(color: Dr.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Patient & Diagnosis Summary ───────────────
                sectionHeader('Prescription Summary'),
                DoctorCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(widget.patientName,
                                style: Dr.heading(15),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(widget.patientId,
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11, color: Dr.sub)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                          'Complaint: ${widget.chiefComplaint}',
                          style: Dr.meta(13)),
                      Text('Diagnosis: ${widget.diagnosis}',
                          style: Dr.meta(13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Medication List ───────────────────────────
                sectionHeader('Medications (${widget.medications.length})'),
                ...widget.medications.asMap().entries.map((entry) {
                  final med = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DoctorCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Dr.green.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medication_rounded,
                                color: Dr.green, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(med['name'] ?? '',
                                    style: Dr.body(14).copyWith(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  '${med['strength']} · ${med['route']} · ${med['frequency']} · ${med['duration']}',
                                  style: Dr.meta(12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // ── Override Form (only if high risk) ─────────
                if (requiresOverride) ...[
                  sectionHeader('Clinical Override Justification'),
                  DoctorCard(
                    borderColor: Dr.red.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _overrideCategory,
                          decoration: InputDecoration(
                            labelText: 'Override Category *',
                            labelStyle: Dr.meta(13),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Dr.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Dr.green, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Dr.bg,
                          ),
                          items: [
                            'Clinical judgment',
                            'Emergency',
                            'No alternative available',
                            'Prior tolerance documented',
                            'Other',
                          ]
                              .map((c) => DropdownMenuItem(
                                  value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _overrideCategory =
                                  val ?? 'Clinical judgment'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _rationaleController,
                          maxLines: 3,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: Dr.text),
                          decoration: InputDecoration(
                            labelText: 'Override Rationale *',
                            labelStyle: Dr.meta(13),
                            hintText:
                                'e.g. Patient has tolerated drug previously without issues, monitor vitals.',
                            hintStyle: Dr.meta(12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Dr.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Dr.green, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Dr.bg,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: Dr.red.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Dr.red.withOpacity(0.2)),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            title: Text(
                              'I acknowledge the identified risks and assume full clinical responsibility as the treating physician.',
                              style: Dr.body(13).copyWith(height: 1.4),
                            ),
                            value: _isAcknowledged,
                            activeColor: Dr.green,
                            checkColor: Colors.white,
                            onChanged: (val) => setState(
                                () => _isAcknowledged = val ?? false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Fixed bottom action bar ─────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Dr.card,
                border: const Border(top: BorderSide(color: Dr.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DoctorOutlinedButton(
                      label: 'Back to Editor',
                      color: Dr.sub,
                      onPressed:
                          _isSigning ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DoctorPrimaryButton(
                      label: 'Sign & Commit Rx',
                      icon: Icons.draw_rounded,
                      isLoading: _isSigning,
                      onPressed: _signAndCommit,
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
