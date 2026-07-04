import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import 'doctor_override_and_sign_screen.dart';

class DoctorPrescriptionEditorScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorPrescriptionEditorScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPrescriptionEditorScreen> createState() => _DoctorPrescriptionEditorScreenState();
}

class _DoctorPrescriptionEditorScreenState extends State<DoctorPrescriptionEditorScreen> {
  final _chiefComplaintController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _medicationRows = [];
  Timer? _debounceTimer;

  // AI Audit State
  String _riskBand = 'LOW';
  int _riskScore = 0;
  List<String> _riskReasons = [];
  List<Map<String, String>> _alternatives = [];
  bool _isAuditing = false;

  @override
  void initState() {
    super.initState();
    // Start with 1 empty medication row
    _addMedicationRow();

    // Listeners for auto-audit triggers on diagnosis and chief complaint
    _chiefComplaintController.addListener(_onFieldChanged);
    _diagnosisController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _debounceTimer?.cancel();
    for (var row in _medicationRows) {
      row['nameController'].dispose();
      row['strengthController'].dispose();
      row['instructionsController'].dispose();
    }
    super.dispose();
  }

  void _addMedicationRow() {
    final nameController = TextEditingController();
    final strengthController = TextEditingController();
    final instructionsController = TextEditingController();

    nameController.addListener(_onFieldChanged);
    strengthController.addListener(_onFieldChanged);
    instructionsController.addListener(_onFieldChanged);

    setState(() {
      _medicationRows.add({
        'nameController': nameController,
        'strengthController': strengthController,
        'route': 'Oral',
        'frequency': 'Once daily',
        'durationValue': '7',
        'durationUnit': 'days',
        'instructionsController': instructionsController,
      });
    });
    _triggerAutoAudit();
  }

  void _removeMedicationRow(int index) {
    if (_medicationRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one medication is required.')),
      );
      return;
    }
    setState(() {
      final row = _medicationRows.removeAt(index);
      row['nameController'].dispose();
      row['strengthController'].dispose();
      row['instructionsController'].dispose();
    });
    _triggerAutoAudit();
  }

  void _onFieldChanged() {
    _triggerAutoAudit();
  }

  void _triggerAutoAudit() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _runAiAudit();
      }
    });
  }

  void _runAiAudit() {
    setState(() {
      _isAuditing = true;
    });

    // Simulate rapid API validation round
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      bool hasPenicillin = false;
      int offendingRowIndex = -1;

      for (int i = 0; i < _medicationRows.length; i++) {
        final drugName = _medicationRows[i]['nameController'].text.trim().toLowerCase();
        if (drugName.contains('penicillin')) {
          hasPenicillin = true;
          offendingRowIndex = i;
          break;
        }
      }

      setState(() {
        _isAuditing = false;
        // Penicillin Allergy Risk Scenario (triggers critical alerts for patient Elena Vance)
        if (hasPenicillin && widget.patientId == 'elena_vance') {
          _riskBand = 'CRITICAL';
          _riskScore = 95;
          _riskReasons = [
            'Drug-Allergy Interaction: Patient Elena Vance is highly allergic to Penicillin compounds.',
            'Severe risk of acute anaphylaxis and medical emergency.',
          ];
          _alternatives = [
            {
              'label': 'Ciprofloxacin 500mg twice daily for 7 days',
              'drug': 'Ciprofloxacin',
              'strength': '500mg',
              'frequency': 'Twice daily',
              'rowIndex': offendingRowIndex.toString(),
            },
            {
              'label': 'Erythromycin 250mg twice daily for 10 days',
              'drug': 'Erythromycin',
              'strength': '250mg',
              'frequency': 'Twice daily',
              'rowIndex': offendingRowIndex.toString(),
            }
          ];
        } else {
          // Normal Baseline state
          _riskBand = 'LOW';
          _riskScore = 8;
          _riskReasons = [];
          _alternatives = [];
        }
      });
    });
  }

  void _applyAlternative(Map<String, String> alt) {
    final int index = int.parse(alt['rowIndex']!);
    if (index >= 0 && index < _medicationRows.length) {
      setState(() {
        _medicationRows[index]['nameController'].text = alt['drug']!;
        _medicationRows[index]['strengthController'].text = alt['strength']!;
        _medicationRows[index]['frequency'] = alt['frequency']!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied safe alternative: ${alt['drug']}')),
      );
    }
  }

  void _proceedToOverride() {
    if (_chiefComplaintController.text.isEmpty || _diagnosisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete Chief Complaint and Provisional Diagnosis.')),
      );
      return;
    }

    final List<Map<String, String>> finalMeds = _medicationRows.map((row) {
      return {
        'name': row['nameController'].text.toString(),
        'strength': row['strengthController'].text.toString(),
        'route': row['route'].toString(),
        'frequency': row['frequency'].toString(),
        'duration': '${row['durationValue']} ${row['durationUnit']}',
        'instructions': row['instructionsController'].text.toString(),
      };
    }).toList();

    // Check if medication row name is empty
    if (finalMeds.any((med) => med['name']!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter drug names for all medication rows.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorOverrideAndSignScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
          chiefComplaint: _chiefComplaintController.text,
          diagnosis: _diagnosisController.text,
          medications: finalMeds,
          riskBand: _riskBand,
          riskScore: _riskScore,
          riskReasons: _riskReasons,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final appState = Provider.of<AppState>(context);

    // Doctor fallback
    final docName = 'Dr. Alexander Vance';
    final docHospital = appState.doctorHospital ?? 'Metropolitan Hospital Centre';
    final docSpecialty = appState.doctorSpecialty ?? 'Cardiology';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Clinical Composer',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Structured header: Patient & Doctor Info
                  NeonCard(
                    borderWidth: 0.5,
                    neonColor: theme.colorScheme.primary.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Encounter Details',
                          style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient: ${widget.patientName} (${widget.patientId == 'elena_vance' ? 'Female, Age 28' : 'Female, Age 34'})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Provider: $docName • $docSpecialty ($docHospital)',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Problem & Diagnosis Inputs
                  Text(
                    'Clinical Diagnosis',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chiefComplaintController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint / Problem *',
                      hintText: 'e.g. Severe dry cough, chest tightness',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Provisional Diagnosis *',
                      hintText: 'e.g. Bronchial Asthma Exacerbation',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes (Optional)',
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Medications Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medication Regimen *',
                        style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addMedicationRow,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Row'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dynamic Medication Rows List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medicationRows.length,
                    itemBuilder: (context, index) {
                      final row = _medicationRows[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Medicine #${index + 1}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => _removeMedicationRow(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row['nameController'],
                              decoration: const InputDecoration(
                                labelText: 'Drug Name (e.g. Penicillin)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: row['strengthController'],
                                    decoration: const InputDecoration(
                                      labelText: 'Strength (e.g. 500mg)',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: row['route'],
                                    decoration: const InputDecoration(labelText: 'Route'),
                                    items: ['Oral', 'IV', 'IM', 'Topical', 'Inhalation']
                                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        row['route'] = val;
                                      });
                                      _triggerAutoAudit();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: row['frequency'],
                                    decoration: const InputDecoration(labelText: 'Frequency'),
                                    items: ['Once daily', 'Twice daily', 'Three times daily', 'Once at night']
                                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        row['frequency'] = val;
                                      });
                                      _triggerAutoAudit();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: row['durationValue'],
                                    decoration: const InputDecoration(labelText: 'Dur.'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      row['durationValue'] = val;
                                      _triggerAutoAudit();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: row['durationUnit'],
                                    decoration: const InputDecoration(labelText: 'Unit'),
                                    items: ['days', 'weeks', 'months']
                                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        row['durationUnit'] = val;
                                      });
                                      _triggerAutoAudit();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. AI Safety Audit Bottom Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF0F172A),
              border: Border(
                top: BorderSide(color: isLight ? Colors.black12 : Colors.white10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (_isAuditing) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Auditing...',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.blueAccent),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _riskBand == 'CRITICAL'
                                  ? Colors.redAccent.withOpacity(0.12)
                                  : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _riskBand == 'CRITICAL' ? Colors.redAccent : Colors.green,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'AI RISK: $_riskBand',
                              style: TextStyle(
                                color: _riskBand == 'CRITICAL' ? Colors.redAccent : Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Score: $_riskScore/100',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12),
                          ),
                        ]
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _proceedToOverride,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _riskBand == 'CRITICAL' ? Colors.redAccent : theme.colorScheme.primary,
                      ),
                      child: const Text('Proceed to Sign', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                if (_riskBand == 'CRITICAL' && _riskReasons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contraindication warnings:',
                          style: GoogleFonts.sora(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._riskReasons.map(
                          (reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Colors.redAccent)),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Suggested Safe Alternatives:',
                          style: GoogleFonts.sora(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._alternatives.map(
                          (alt) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF10B981), width: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () => _applyAlternative(alt),
                                child: Text(
                                  'Apply: ${alt['label']}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
