import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../doctor_theme.dart';
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
  State<DoctorPrescriptionEditorScreen> createState() =>
      _DoctorPrescriptionEditorScreenState();
}

class _DoctorPrescriptionEditorScreenState
    extends State<DoctorPrescriptionEditorScreen> {
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
    _addMedicationRow();
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
      (row['nameController'] as TextEditingController).dispose();
      (row['strengthController'] as TextEditingController).dispose();
      (row['instructionsController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addMedicationRow() {
    final nameCtrl = TextEditingController()..addListener(_onFieldChanged);
    final strengthCtrl = TextEditingController()..addListener(_onFieldChanged);
    final instructionsCtrl = TextEditingController()
      ..addListener(_onFieldChanged);
    setState(() {
      _medicationRows.add({
        'nameController': nameCtrl,
        'strengthController': strengthCtrl,
        'route': 'Oral',
        'frequency': 'Once daily',
        'durationValue': '7',
        'durationUnit': 'days',
        'morning': false,
        'afternoon': false,
        'evening': false,
        'night': false,
        'beforeFood': false,
        'afterFood': false,
        'instructionsController': instructionsCtrl,
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
      (row['nameController'] as TextEditingController).dispose();
      (row['strengthController'] as TextEditingController).dispose();
      (row['instructionsController'] as TextEditingController).dispose();
    });
    _triggerAutoAudit();
  }

  void _onFieldChanged() => _triggerAutoAudit();

  void _triggerAutoAudit() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _runAiAudit();
    });
  }

  void _runAiAudit() async {
    if (_medicationRows.isEmpty) return;

    final validRows = _medicationRows.where((row) {
      final name = (row['nameController'] as TextEditingController).text.trim();
      return name.isNotEmpty;
    }).toList();

    if (validRows.isEmpty) {
      setState(() {
        _riskBand = 'LOW';
        _riskScore = 0;
        _riskReasons = [];
        _alternatives = [];
      });
      return;
    }

    setState(() => _isAuditing = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final firstValidRow = validRows.first;
    final medName = (firstValidRow['nameController'] as TextEditingController).text.trim();
    final rowIndex = _medicationRows.indexOf(firstValidRow);

    final medNames = validRows
        .map((row) => (row['nameController'] as TextEditingController).text.trim())
        .join(', ');
    final dosages = validRows.map((row) {
      final medStrength =
          (row['strengthController'] as TextEditingController).text.trim();
      final freq = row['frequency'] ?? '';
      return '$medStrength $freq'.trim();
    }).join(', ');

    final res = await appState.runAiSafetyAudit(
      patientId: widget.patientId,
      doctorId: appState.doctorLicense ?? '889218',
      newMedicine: medNames,
      newDosage: dosages,
      disease: _diagnosisController.text.trim().isNotEmpty
          ? _diagnosisController.text.trim()
          : 'Hypertension',
    );

    if (!mounted) return;
    setState(() => _isAuditing = false);

    if (res != null) {
      final allergyCheck = res['allergy_check'] ?? {};
      final interactionCheck = res['interaction_check'] ?? {};
      final dupCheck = res['duplicate_check'] ?? {};

      final List<String> reasons = [];
      if (allergyCheck['allergy_conflict'] == true) {
        reasons.add('Allergy Conflict: Severe risk matching patient profile.');
      }
      if (interactionCheck['interaction_risk'] == 'HIGH' ||
          interactionCheck['interaction_risk'] == 'CRITICAL') {
        reasons.add(
          'Drug Interaction: ${interactionCheck['interaction_details']}',
        );
      }
      if (dupCheck['is_duplicate'] == true) {
        reasons.add('Duplicate Therapy: ${dupCheck['duplicate_details']}');
      }

      final List<dynamic> altsRaw =
          allergyCheck['suggested_alternatives'] ??
          interactionCheck['alternatives'] ??
          [];
      final List<Map<String, String>> altsParsed = altsRaw.map((a) {
        final String label = a.toString();
        final drug = label.split(' ').first;
        return {
          'label': label,
          'drug': drug,
          'strength': label.contains('500mg')
              ? '500mg'
              : (label.contains('250mg') ? '250mg' : '500mg'),
          'frequency': label.contains('twice') ? 'Twice daily' : 'Once daily',
          'rowIndex': rowIndex.toString(),
        };
      }).toList();

      setState(() {
        final riskLevelStr = res['risk_level'] ?? 'SAFE';
        _riskBand = riskLevelStr == 'SAFE'
            ? 'LOW'
            : (riskLevelStr == 'WARNING' ? 'HIGH' : 'CRITICAL');
        _riskScore =
            res['risk_score'] ??
            (res['confidence_score'] != null
                ? (res['confidence_score'] * 100).round()
                : 10);
        if (_riskBand == 'CRITICAL') {
          _riskScore = max(90, _riskScore);
        } else if (_riskBand == 'HIGH') {
          _riskScore = max(70, _riskScore);
        }
        _riskReasons = reasons.isNotEmpty
            ? reasons
            : (res['clinical_explanation'] != null
                  ? [res['clinical_explanation']]
                  : []);
        _alternatives = altsParsed;
      });
    } else {
      _runLocalMockAudit(medName, rowIndex);
    }
  }

  void _runLocalMockAudit(String drugName, int offendingRowIndex) {
    setState(() {
      if (drugName.toLowerCase().contains('penicillin') &&
          widget.patientId == 'elena_vance') {
        _riskBand = 'CRITICAL';
        _riskScore = 95;
        _riskReasons = [
          'Drug-Allergy Interaction: Patient is highly allergic to Penicillin. (Rules Fallback)',
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
        ];
      } else {
        _riskBand = 'LOW';
        _riskScore = 8;
        _riskReasons = [];
        _alternatives = [];
      }
    });
  }

  void _applyAlternative(Map<String, String> alt) {
    final int index = int.parse(alt['rowIndex']!);
    if (index >= 0 && index < _medicationRows.length) {
      setState(() {
        (_medicationRows[index]['nameController'] as TextEditingController)
                .text =
            alt['drug']!;
        (_medicationRows[index]['strengthController'] as TextEditingController)
                .text =
            alt['strength']!;
        _medicationRows[index]['frequency'] = alt['frequency']!;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Applied: ${alt['drug']}')));
    }
  }

  void _proceedToOverride() {
    if (_chiefComplaintController.text.isEmpty ||
        _diagnosisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete Chief Complaint and Provisional Diagnosis.',
          ),
        ),
      );
      return;
    }
    final List<Map<String, dynamic>> finalMeds = _medicationRows.map((row) {
      return {
        'name': (row['nameController'] as TextEditingController).text,
        'strength': (row['strengthController'] as TextEditingController).text,
        'route': row['route'].toString(),
        'frequency': row['frequency'].toString(),
        'duration': '${row['durationValue']} ${row['durationUnit']}',
        'instructions':
            (row['instructionsController'] as TextEditingController).text,
        'morning': row['morning'] == true,
        'afternoon': row['afternoon'] == true,
        'evening': row['evening'] == true,
        'night': row['night'] == true,
        'beforeFood': row['beforeFood'] == true,
        'afterFood': row['afterFood'] == true,
      };
    }).toList();

    if (finalMeds.any((med) => med['name'].trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter drug names for all medication rows.'),
        ),
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

  // ── Input decoration helper ───────────────────────────────────
  InputDecoration _inputDec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: Dr.meta(13),
      hintText: hint,
      hintStyle: Dr.meta(12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Dr.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Dr.green, width: 1.5),
      ),
      filled: true,
      fillColor: Dr.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final docHospital =
        appState.doctorHospital ?? 'Metropolitan Hospital Centre';
    final docSpecialty = appState.doctorSpecialty ?? 'Cardiology';
    final isCritical = _riskBand == 'CRITICAL' || _riskBand == 'HIGH';
    final auditColor = isCritical ? Dr.red : Dr.green;

    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'Clinical Composer'),
      body: Column(
        children: [
          // ── Scrollable Form ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Encounter Header Card ─────────────────────
                  DoctorCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: Dr.sub,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patientName,
                                style: Dr.heading(14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Provider: Dr. — · $docSpecialty · $docHospital',
                                style: Dr.meta(11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Clinical Diagnosis ────────────────────────
                  sectionHeader('Clinical Diagnosis'),
                  DoctorCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _chiefComplaintController,
                          maxLines: 2,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Dr.text,
                          ),
                          decoration: _inputDec(
                            'Chief Complaint / Problem *',
                            hint: 'e.g. Severe dry cough, chest tightness',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _diagnosisController,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Dr.text,
                          ),
                          decoration: _inputDec(
                            'Provisional Diagnosis *',
                            hint: 'e.g. Bronchial Asthma Exacerbation',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Dr.text,
                          ),
                          decoration: _inputDec('Clinical Notes (Optional)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Medication Section Header ──────────────────
                  Row(
                    children: [
                      Expanded(
                        child: sectionHeader(
                          'Medication Regimen (${_medicationRows.length})',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addMedicationRow,
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Dr.green,
                        ),
                        label: Text(
                          'Add Medicine',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Dr.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Medication Rows ───────────────────────────
                  ...List.generate(_medicationRows.length, (index) {
                    final row = _medicationRows[index];
                    return _buildMedRow(index, row);
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── AI Audit Bottom Panel ─────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Dr.card,
              border: Border(top: BorderSide(color: Dr.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audit Status Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAuditing) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Dr.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'AI Auditing...',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: Dr.sub,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            Flexible(
                              child: DoctorStatusBadge(
                                label: 'AI: $_riskBand',
                                color: auditColor,
                                icon: isCritical
                                    ? Icons.dangerous_rounded
                                    : Icons.verified_rounded,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_riskScore/100',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: Dr.sub,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _proceedToOverride,
                      icon: Icon(
                        isCritical
                            ? Icons.warning_amber_rounded
                            : Icons.draw_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Proceed to Sign',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: auditColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),

                // Contraindication warnings
                if (isCritical && _riskReasons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Dr.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Dr.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contraindications:',
                          style: GoogleFonts.sora(
                            color: Dr.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._riskReasons.map(
                          (reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '· ',
                                  style: TextStyle(
                                    color: Dr.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: Dr.body(12).copyWith(color: Dr.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_alternatives.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Safe Alternatives:',
                            style: GoogleFonts.sora(
                              color: Dr.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ..._alternatives.map(
                            (alt) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: OutlinedButton(
                                onPressed: () => _applyAlternative(alt),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Dr.green,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Dr.green,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Apply: ${alt['label']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Dr.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildMedRow(int index, Map<String, dynamic> row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dr.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Dr.border),
        boxShadow: const [Dr.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Dr.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Medicine #${index + 1}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Dr.green,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Dr.red,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _removeMedicationRow(index),
                tooltip: 'Remove',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Drug name
          TextField(
            controller: row['nameController'] as TextEditingController,
            style: GoogleFonts.inter(fontSize: 14, color: Dr.text),
            decoration: _inputDec('Drug Name *', hint: 'e.g. Amoxicillin'),
          ),
          const SizedBox(height: 10),

          // Strength + Route
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      row['strengthController'] as TextEditingController,
                  style: GoogleFonts.inter(fontSize: 14, color: Dr.text),
                  decoration: _inputDec('Strength', hint: 'e.g. 500mg'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: row['route'] as String,
                  decoration: _inputDec('Route'),
                  style: GoogleFonts.inter(fontSize: 13, color: Dr.text),
                  dropdownColor: Dr.card,
                  items: ['Oral', 'IV', 'IM', 'Topical', 'Inhalation']
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Dr.text,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => row['route'] = val);
                    _triggerAutoAudit();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Frequency (Full width)
          DropdownButtonFormField<String>(
            value: row['frequency'] as String,
            decoration: _inputDec('Frequency'),
            style: GoogleFonts.inter(fontSize: 13, color: Dr.text),
            dropdownColor: Dr.card,
            items: [
              'Once daily',
              'Twice daily',
              'Three times daily',
              'Once at night',
            ].map(
              (f) => DropdownMenuItem(
                value: f,
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Dr.text,
                  ),
                ),
              ),
            ).toList(),
            onChanged: (val) {
              setState(() => row['frequency'] = val);
              _triggerAutoAudit();
            },
          ),
          const SizedBox(height: 10),

          // Duration (Days + Unit)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: row['durationValue'] as String,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 14, color: Dr.text),
                  decoration: _inputDec('Duration Days', hint: 'e.g. 7'),
                  onChanged: (val) {
                    row['durationValue'] = val;
                    _triggerAutoAudit();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: row['durationUnit'] as String,
                  decoration: _inputDec('Unit'),
                  style: GoogleFonts.inter(fontSize: 13, color: Dr.text),
                  dropdownColor: Dr.card,
                  items: ['days', 'weeks', 'months']
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(
                            u,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Dr.text,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => row['durationUnit'] = val);
                    _triggerAutoAudit();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timings chips
          Text(
            'Dose Timings',
            style: Dr.meta(12).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _timingChip('Morning', row, 'morning'),
              _timingChip('Afternoon', row, 'afternoon'),
              _timingChip('Evening', row, 'evening'),
              _timingChip('Night', row, 'night'),
            ],
          ),
          const SizedBox(height: 10),

          // Food relation
          DropdownButtonFormField<String>(
            value: row['beforeFood'] == true
                ? 'Before Food'
                : (row['afterFood'] == true ? 'After Food' : 'None'),
            decoration: _inputDec('Food Relation'),
            style: GoogleFonts.inter(fontSize: 13, color: Dr.text),
            dropdownColor: Dr.card,
            items: ['None', 'Before Food', 'After Food']
                .map(
                  (fr) => DropdownMenuItem(
                    value: fr,
                    child: Text(
                      fr,
                      style: GoogleFonts.inter(fontSize: 13, color: Dr.text),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                row['beforeFood'] = val == 'Before Food';
                row['afterFood'] = val == 'After Food';
              });
              _triggerAutoAudit();
            },
          ),
          const SizedBox(height: 10),

          // Custom instructions
          TextField(
            controller: row['instructionsController'] as TextEditingController,
            style: GoogleFonts.inter(fontSize: 14, color: Dr.text),
            decoration: _inputDec(
              'Custom Instructions',
              hint: 'e.g. Take with warm water',
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingChip(String label, Map<String, dynamic> row, String key) {
    final selected = row[key] == true;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: selected ? Colors.white : Dr.sub,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: Dr.green,
      backgroundColor: Dr.bg,
      side: BorderSide(color: selected ? Dr.green : Dr.border, width: 1),
      checkmarkColor: Colors.white,
      onSelected: (val) {
        setState(() => row[key] = val);
        _triggerAutoAudit();
      },
    );
  }
}
