// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Doctor Prescription Editor Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — speech-to-text, parseVoicePrescription, runAiSafetyAudit,
//                 auto audit debouncer, row management, proceedToOverride preserved
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
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

  // Speech Recognition State — UNCHANGED
  stt.SpeechToText? _speech;
  bool _isListening = false;
  String _transcript = '';
  bool _speechEnabled = false;
  bool _isVoiceProcessing = false;

  // AI Audit State — UNCHANGED
  String _riskBand = 'LOW';
  int _riskScore = 0;
  List<String> _riskReasons = [];
  List<Map<String, String>> _alternatives = [];
  bool _isAuditing = false;
  String _action = 'ALLOW';

  // Concurrency Guard State
  bool _needsAuditAfterCurrent = false;
  int _auditRequestIdCount = 0;
  int _prescriptionVersion = 0;
  Completer<void>? _currentAuditCompleter;

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initMedicationRow();
    _chiefComplaintController.addListener(_onFieldChanged);
    _diagnosisController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).pausePolling(
        screen: 'DoctorPrescriptionEditorScreen',
        reason: 'Doctor editing prescription',
      );
    });
  }

  void _initMedicationRow() {
    final nameCtrl = TextEditingController()..addListener(_onFieldChanged);
    final strengthCtrl = TextEditingController()..addListener(_onFieldChanged);
    final instructionsCtrl = TextEditingController()..addListener(_onFieldChanged);
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
  }

  void _toggleListening() async {
    if (_speech == null) {
      setState(() => _isVoiceProcessing = true);
      try {
        _speech = stt.SpeechToText();
        _speechEnabled = await _speech!.initialize(
          onStatus: (status) => debugPrint('STT Status: $status'),
          onError: (errorVal) => debugPrint('STT Error: $errorVal'),
        );
      } catch (e) {
        debugPrint('Speech initialization failed: $e');
        _speechEnabled = false;
        _speech = null;
      }
      if (mounted) {
        setState(() => _isVoiceProcessing = false);
      }
    }

    if (_speech == null || !_speechEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition is not available or permission denied.',
                style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AegisColors.danger,
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech!.stop();
      if (mounted) setState(() => _isListening = false);
      _showTranscriptConfirmationDialog();
    } else {
      setState(() {
        _isListening = true;
        _transcript = '';
      });
      await _speech!.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _transcript = result.recognizedWords;
            });
          }
        },
      );
    }
  }

  void _showTranscriptConfirmationDialog() {
    final transcriptController = TextEditingController(text: _transcript);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AegisColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AegisRadius.card,
            side: const BorderSide(color: AegisColors.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AegisSpacing.xs),
                decoration: BoxDecoration(
                  color: AegisColors.tertiarySurface,
                  borderRadius: BorderRadius.circular(AegisRadius.xs),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AegisColors.tertiary, size: AegisIconSize.sm),
              ),
              const SizedBox(width: AegisSpacing.sm),
              Text(
                'Verify Dictation Draft',
                style: AegisTypography.headlineSmall.copyWith(color: AegisColors.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review and edit the transcribed prescription if there are errors:',
                style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              ),
              const SizedBox(height: AegisSpacing.md),
              TextField(
                controller: transcriptController,
                maxLines: 4,
                style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AegisColors.background,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AegisRadius.input,
                    borderSide: const BorderSide(color: AegisColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AegisRadius.input,
                    borderSide: const BorderSide(color: AegisColors.tertiary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AegisSpacing.sm),
              Text(
                '⚠️ Disclaimer: Voice parser is an input aid only. Verified clinical checks must always follow.',
                style: AegisTypography.labelSmall.copyWith(
                  color: AegisColors.warningDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: AegisTypography.labelMedium.copyWith(color: AegisColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AegisColors.tertiary, // AI Purple
                shape: RoundedRectangleBorder(
                  borderRadius: AegisRadius.button,
                ),
              ),
              onPressed: () {
                final approvedText = transcriptController.text.trim();
                Navigator.pop(dialogContext);
                if (approvedText.isNotEmpty) {
                  _parseVoicePrescriptionText(approvedText);
                }
              },
              child: Text(
                'Parse & Populate',
                style: AegisTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _parseVoicePrescriptionText(String text) async {
    setState(() => _isVoiceProcessing = true);
    final appState = Provider.of<AppState>(context, listen: false);

    final result = await appState.parseVoicePrescription(
      patientId: widget.patientId,
      doctorId: appState.doctorLicense ?? '889218',
      transcript: text,
    );

    setState(() => _isVoiceProcessing = false);

    if (result != null && result['status'] == 'SUCCESS') {
      final diagnosis = result['diagnosis'] as String? ?? '';
      final medications = result['medications'] as List<dynamic>? ?? [];

      if (diagnosis.isNotEmpty && diagnosis != 'Unknown Diagnosis') {
        _diagnosisController.text = diagnosis;
      }

      if (medications.isNotEmpty) {
        setState(() {
          _medicationRows.clear();

          for (var med in medications) {
            final medMap = med as Map<String, dynamic>;
            final drugName = medMap['drug'] as String? ?? '';
            final dose = medMap['dose'] as String? ?? '';
            final rawFreq = medMap['frequency'] as String? ?? 'Once daily';
            final rawDur = medMap['duration'] as String? ?? '7 Days';

            String cleanFreq = 'Once daily';
            final lowerFreq = rawFreq.toLowerCase();
            if (lowerFreq.contains('twice') || lowerFreq == 'bd' || lowerFreq == 'bid') {
              cleanFreq = 'Twice daily';
            } else if (lowerFreq.contains('three') || lowerFreq == 'tds' || lowerFreq == 'tid') {
              cleanFreq = 'Three times daily';
            } else if (lowerFreq.contains('night') || lowerFreq == 'hs' || lowerFreq.contains('bedtime')) {
              cleanFreq = 'Once at night';
            }

            String durVal = '7';
            final match = RegExp(r'\d+').firstMatch(rawDur);
            if (match != null) {
              durVal = match.group(0)!;
            }

            final nameCtrl = TextEditingController(text: drugName)..addListener(_onFieldChanged);
            final strengthCtrl = TextEditingController(text: dose)..addListener(_onFieldChanged);
            final instructionsCtrl = TextEditingController()..addListener(_onFieldChanged);

            _medicationRows.add({
              'nameController': nameCtrl,
              'strengthController': strengthCtrl,
              'route': 'Oral',
              'frequency': cleanFreq,
              'durationValue': durVal,
              'durationUnit': 'days',
              'morning': false,
              'afternoon': false,
              'evening': false,
              'night': false,
              'beforeFood': false,
              'afterFood': false,
              'instructionsController': instructionsCtrl,
            });
          }
        });

        _runAiAudit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully populated ${medications.length} medications. Clinical audit triggered.',
                style: AegisTypography.bodySmall.copyWith(color: Colors.white),
              ),
              backgroundColor: AegisColors.secondary,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to parse the dictation. Please check connection and try again.',
                style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AegisColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_isListening) {
      try {
        _speech?.stop();
      } catch (_) {}
    }
    _chiefComplaintController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    for (var row in _medicationRows) {
      (row['nameController'] as TextEditingController).dispose();
      (row['strengthController'] as TextEditingController).dispose();
      (row['instructionsController'] as TextEditingController).dispose();
    }
    debugPrint('[AUDIT]\nCancelled\nRequest:\nN/A\nTrigger:\nEditor Disposed\nVersion:\nN/A\nTimestamp:\n${DateTime.now()}');
    super.dispose();
  }

  void _addMedicationRow() {
    final nameCtrl = TextEditingController()..addListener(_onFieldChanged);
    final strengthCtrl = TextEditingController()..addListener(_onFieldChanged);
    final instructionsCtrl = TextEditingController()..addListener(_onFieldChanged);
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
        SnackBar(
          content: Text('At least one medication is required.', style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AegisColors.warning,
        ),
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

  bool _isPrescriptionReadyForAudit(List<Map<String, dynamic>> rows) {
    if (_diagnosisController.text.trim().isEmpty) return false;
    
    bool hasCompletedMed = false;
    for (final row in rows) {
      final name = (row['nameController'] as TextEditingController).text.trim();
      final strength = (row['strengthController'] as TextEditingController).text.trim();
      final freq = row['frequency'] as String? ?? '';
      
      if (name.length >= 3 && strength.isNotEmpty && freq.isNotEmpty) {
        hasCompletedMed = true;
      }
    }
    return hasCompletedMed;
  }

  Future<void> _runAiAudit({bool isFinal = false}) async {
    if (_medicationRows.isEmpty) return;

    _prescriptionVersion++;
    final int currentVersion = _prescriptionVersion;
    final int requestId = ++_auditRequestIdCount;

    if (!isFinal && !_isPrescriptionReadyForAudit(_medicationRows)) {
      debugPrint('[AUDIT]\nSkipped\nRequest:\n$requestId\nTrigger:\nIncomplete Fields\nVersion:\n$currentVersion\nTimestamp:\n${DateTime.now()}');
      return;
    }

    if (_isAuditing) {
      _needsAuditAfterCurrent = true;
      debugPrint('[AUDIT]\nQueued\nRequest:\n$requestId\nTrigger:\n${isFinal ? "Final Audit Request" : "Field Changed"}\nVersion:\n$currentVersion\nTimestamp:\n${DateTime.now()}');
      return;
    }

    setState(() => _isAuditing = true);
    final Stopwatch stopwatch = Stopwatch()..start();
    debugPrint('[AUDIT]\nStarted\nRequest:\n$requestId\nTrigger:\n${isFinal ? "Final Audit" : "Field Changed"}\nVersion:\n$currentVersion\nTimestamp:\n${DateTime.now()}');

    _currentAuditCompleter = Completer<void>();

    try {
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
          _action = res['action'] ?? 'ALLOW';
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
    } catch (e) {
      debugPrint('Error running AI audit: $e');
    } finally {
      stopwatch.stop();
      _isAuditing = false;
      if (mounted) {
        setState(() {});
      }
      _currentAuditCompleter?.complete();
      _currentAuditCompleter = null;
      debugPrint('[AUDIT]\nCompleted\nRequest:\n$requestId\nVersion:\n$currentVersion\nDuration:\n${stopwatch.elapsedMilliseconds}ms\nTimestamp:\n${DateTime.now()}');

      if (_needsAuditAfterCurrent) {
        _needsAuditAfterCurrent = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _runAiAudit();
          }
        });
      }
    }
  }

  void _runLocalMockAudit(String drugName, int offendingRowIndex) {
    setState(() {
      if (drugName.toLowerCase().contains('penicillin') &&
          (widget.patientId.toLowerCase().contains('elena') ||
              widget.patientId.toLowerCase().contains('priya') ||
              widget.patientId.toLowerCase().contains('sharma'))) {
        _riskBand = 'CRITICAL';
        _action = 'BLOCK_UNLESS_OVERRIDE';
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
        _action = 'ALLOW';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied: ${alt['drug']}', style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AegisColors.secondary,
        ),
      );
    }
  }

  void _proceedToOverride() async {
    if (_chiefComplaintController.text.isEmpty ||
        _diagnosisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete Chief Complaint and Provisional Diagnosis.',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AegisColors.warning,
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
        SnackBar(
          content: Text('Please enter drug names for all medication rows.',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AegisColors.warning,
        ),
      );
      return;
    }

    if (_isAuditing && _currentAuditCompleter != null) {
      debugPrint('[AUDIT]\nQueued\nRequest:\nN/A\nTrigger:\nWaiting for current audit to finish before final audit\nVersion:\n$_prescriptionVersion\nTimestamp:\n${DateTime.now()}');
      await _currentAuditCompleter!.future;
    }

    debugPrint('[AUDIT]\nFinal Audit\nRequest:\nN/A\nTrigger:\nProceed to Sign clicked\nVersion:\n$_prescriptionVersion\nTimestamp:\n${DateTime.now()}');
    await _runAiAudit(isFinal: true);

    if (!mounted) return;

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
          action: _action,
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
      hintText: hint,
      hintStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textTertiary),
      enabledBorder: OutlineInputBorder(
        borderRadius: AegisRadius.input,
        borderSide: const BorderSide(color: AegisColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AegisRadius.input,
        borderSide: const BorderSide(color: AegisColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: AegisColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: AegisSpacing.base, vertical: AegisSpacing.md),
    );
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final rawName = appState.doctorName ?? 'Alexander Vance';
    final docName = rawName.startsWith('Dr.') ? rawName : 'Dr. $rawName';
    final docLicense = appState.doctorLicense ?? '889218';
    final docHospital =
        appState.doctorHospital ?? 'Metropolitan Hospital Centre';
    final docSpecialty = appState.doctorSpecialty ?? 'Cardiology';
    final isCritical = _action == 'BLOCK_UNLESS_OVERRIDE' || _action == 'REQUIRE_OVERRIDE';

    Color getAuditColor() {
      switch (_action.toUpperCase()) {
        case 'ALLOW':
          return AegisColors.secondary; // Medical Teal for safe
        case 'REVIEW':
          return AegisColors.warning;   // Orange for warning
        case 'REQUIRE_OVERRIDE':
          return AegisColors.warning;   // Orange for override requirement
        case 'BLOCK_UNLESS_OVERRIDE':
          return AegisColors.danger;    // Red for critical block
        default:
          return AegisColors.secondary;
      }
    }
    final auditColor = getAuditColor();

    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'Clinical Composer'),
      body: Column(
        children: [
          // ── Scrollable Form ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AegisSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Encounter Header Card ─────────────────────
                  DoctorCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.base,
                      vertical: AegisSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: AegisColors.textSecondary,
                          size: AegisIconSize.sm,
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patientName,
                                style: AegisTypography.titleSmall.copyWith(color: AegisColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Provider: $docName ($docLicense) · $docSpecialty · $docHospital',
                                style: AegisTypography.bodySmall.copyWith(color: AegisColors.textTertiary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),

                  // ── AI Voice Dictation Banner (AI Purple) ─────
                  _buildVoiceDictationCard(),

                  // ── Clinical Diagnosis ────────────────────────
                  sectionHeader('Clinical Diagnosis'),
                  DoctorCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _chiefComplaintController,
                          maxLines: 2,
                          style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                          decoration: _inputDec(
                            'Chief Complaint / Problem *',
                            hint: 'e.g. Severe dry cough, chest tightness',
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        TextField(
                          controller: _diagnosisController,
                          style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                          decoration: _inputDec(
                            'Provisional Diagnosis *',
                            hint: 'e.g. Bronchial Asthma Exacerbation',
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                          decoration: _inputDec('Clinical Notes (Optional)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),

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
                          size: AegisIconSize.sm,
                          color: AegisColors.primary,
                        ),
                        label: Text(
                          'Add Medicine',
                          style: AegisTypography.labelSmall.copyWith(
                            color: AegisColors.primary,
                            fontWeight: FontWeight.w700,
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
                  const SizedBox(height: AegisSpacing.xs),
                ],
              ),
            ),
          ),

          // ── AI Audit Bottom Panel ─────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              AegisSpacing.base,
              AegisSpacing.md,
              AegisSpacing.base,
              AegisSpacing.lg,
            ),
            decoration: const BoxDecoration(
              color: AegisColors.surface,
              border: Border(top: BorderSide(color: AegisColors.border)),
              boxShadow: AegisShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audit Status Row
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isAuditing) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AegisColors.tertiary, // AI Purple
                                ),
                              ),
                              const SizedBox(width: AegisSpacing.xs),
                              Text(
                                'AI Auditing...',
                                style: AegisTypography.monoSmall.copyWith(
                                  color: AegisColors.tertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else ...[
                              DoctorStatusBadge(
                                label: 'AI: $_riskBand',
                                color: auditColor,
                                icon: isCritical
                                    ? Icons.dangerous_rounded
                                    : Icons.verified_rounded,
                              ),
                              const SizedBox(width: AegisSpacing.xs),
                              Text(
                                '$_riskScore/100',
                                style: AegisTypography.monoSmall.copyWith(
                                  color: AegisColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AegisSpacing.xs),
                    // Primary action button in Royal Blue
                    ElevatedButton.icon(
                      onPressed: _proceedToOverride,
                      icon: Icon(
                        isCritical
                            ? Icons.warning_amber_rounded
                            : Icons.draw_rounded,
                        size: AegisIconSize.sm,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Proceed to Sign',
                        style: AegisTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AegisColors.primary, // Blue Primary Action
                        minimumSize: Size.zero, // Overrides global theme's Size.fromHeight(48) -> Size(double.infinity, 48)
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AegisSpacing.md,
                          vertical: AegisSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AegisRadius.button,
                        ),
                      ),
                    ),
                  ],
                ),

                // Contraindication warnings
                if (isCritical && _riskReasons.isNotEmpty) ...[
                  const SizedBox(height: AegisSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AegisSpacing.md),
                    decoration: BoxDecoration(
                      color: AegisColors.dangerLight, // Critical Alert = Red
                      borderRadius: AegisRadius.card,
                      border: Border.all(color: AegisColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contraindications:',
                          style: AegisTypography.labelSmall.copyWith(
                            color: AegisColors.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.xs),
                        ..._riskReasons.map(
                          (reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '· ',
                                  style: TextStyle(
                                    color: AegisColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: AegisTypography.bodySmall.copyWith(color: AegisColors.dangerDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_alternatives.isNotEmpty) ...[
                          const SizedBox(height: AegisSpacing.sm),
                          Text(
                            'Safe Alternatives:',
                            style: AegisTypography.labelSmall.copyWith(
                              color: AegisColors.secondary, // Safe recommendation = Teal
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AegisSpacing.xs),
                          ..._alternatives.map(
                            (alt) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: OutlinedButton(
                                onPressed: () => _applyAlternative(alt),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: AegisColors.secondary,
                                    width: AegisBorders.thin,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AegisRadius.sm),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AegisSpacing.md,
                                    vertical: AegisSpacing.xs,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      size: AegisIconSize.xs,
                                      color: AegisColors.secondary,
                                    ),
                                    const SizedBox(width: AegisSpacing.xs),
                                    Flexible(
                                      child: Text(
                                        'Apply: ${alt['label']}',
                                        style: AegisTypography.labelSmall.copyWith(
                                          color: AegisColors.secondary,
                                          fontWeight: FontWeight.w700,
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
      margin: const EdgeInsets.only(bottom: AegisSpacing.md),
      padding: const EdgeInsets.all(AegisSpacing.md),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border),
        boxShadow: AegisShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.sm, vertical: AegisSpacing.xs),
                decoration: BoxDecoration(
                  color: AegisColors.primarySurface,
                  borderRadius: BorderRadius.circular(AegisRadius.xs),
                ),
                child: Text(
                  'Medicine #${index + 1}',
                  style: AegisTypography.monoSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AegisColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AegisColors.danger,
                  size: AegisIconSize.sm,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _removeMedicationRow(index),
                tooltip: 'Remove',
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.sm),

          // Drug name
          TextField(
            controller: row['nameController'] as TextEditingController,
            style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
            decoration: _inputDec('Drug Name *', hint: 'e.g. Amoxicillin'),
          ),
          const SizedBox(height: AegisSpacing.sm),

          // Strength + Route
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      row['strengthController'] as TextEditingController,
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                  decoration: _inputDec('Strength', hint: 'e.g. 500mg'),
                ),
              ),
              const SizedBox(width: AegisSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: row['route'] as String,
                  decoration: _inputDec('Route'),
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                  dropdownColor: AegisColors.surface,
                  items: ['Oral', 'IV', 'IM', 'Topical', 'Inhalation']
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r,
                            style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
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
          const SizedBox(height: AegisSpacing.sm),

          // Frequency
          DropdownButtonFormField<String>(
            value: row['frequency'] as String,
            decoration: _inputDec('Frequency'),
            style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
            dropdownColor: AegisColors.surface,
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
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                ),
              ),
            ).toList(),
            onChanged: (val) {
              setState(() => row['frequency'] = val);
              _triggerAutoAudit();
            },
          ),
          const SizedBox(height: AegisSpacing.sm),

          // Duration (Days + Unit)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: row['durationValue'] as String,
                  keyboardType: TextInputType.number,
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                  decoration: _inputDec('Duration Days', hint: 'e.g. 7'),
                  onChanged: (val) {
                    row['durationValue'] = val;
                    _triggerAutoAudit();
                  },
                ),
              ),
              const SizedBox(width: AegisSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: row['durationUnit'] as String,
                  decoration: _inputDec('Unit'),
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                  dropdownColor: AegisColors.surface,
                  items: ['days', 'weeks', 'months']
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(
                            u,
                            style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
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
          const SizedBox(height: AegisSpacing.md),

          // Timings chips
          Text(
            'Dose Timings',
            style: AegisTypography.labelSmall.copyWith(color: AegisColors.textSecondary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AegisSpacing.xs),
          Wrap(
            spacing: AegisSpacing.xs,
            runSpacing: AegisSpacing.xs,
            children: [
              _timingChip('Morning', row, 'morning'),
              _timingChip('Afternoon', row, 'afternoon'),
              _timingChip('Evening', row, 'evening'),
              _timingChip('Night', row, 'night'),
            ],
          ),
          const SizedBox(height: AegisSpacing.sm),

          // Food relation
          DropdownButtonFormField<String>(
            value: row['beforeFood'] == true
                ? 'Before Food'
                : (row['afterFood'] == true ? 'After Food' : 'None'),
            decoration: _inputDec('Food Relation'),
            style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
            dropdownColor: AegisColors.surface,
            items: ['None', 'Before Food', 'After Food']
                .map(
                  (fr) => DropdownMenuItem(
                    value: fr,
                    child: Text(
                      fr,
                      style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
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
          const SizedBox(height: AegisSpacing.sm),

          // Custom instructions
          TextField(
            controller: row['instructionsController'] as TextEditingController,
            style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
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
        style: AegisTypography.labelSmall.copyWith(
          color: selected ? Colors.white : AegisColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedColor: AegisColors.secondary,
      backgroundColor: AegisColors.background,
      side: BorderSide(color: selected ? AegisColors.secondary : AegisColors.border, width: 1),
      checkmarkColor: Colors.white,
      onSelected: (val) {
        setState(() => row[key] = val);
        _triggerAutoAudit();
      },
    );
  }

  Widget _buildVoiceDictationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AegisSpacing.lg),
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: AegisColors.tertiarySurface, // AI Purple surface for AI feature
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.tertiary.withValues(alpha: 0.4)),
        boxShadow: AegisShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isListening ? Icons.mic_rounded : Icons.auto_awesome_rounded,
                color: _isListening ? AegisColors.danger : AegisColors.tertiary,
                size: AegisIconSize.sm,
              ),
              const SizedBox(width: AegisSpacing.xs),
              Text(
                'AI Dictation & Parsing Assist',
                style: AegisTypography.titleSmall.copyWith(
                  color: AegisColors.tertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_isVoiceProcessing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AegisColors.tertiary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AegisSpacing.sm),
          if (_isListening) ...[
            Container(
              padding: const EdgeInsets.all(AegisSpacing.md),
              decoration: BoxDecoration(
                color: AegisColors.surface,
                borderRadius: BorderRadius.circular(AegisRadius.sm),
                border: Border.all(color: AegisColors.danger.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _transcript.isEmpty ? 'Listening for prescription dictation...' : _transcript,
                    style: AegisTypography.bodyMedium.copyWith(
                      color: AegisColors.textPrimary,
                      fontStyle: _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 4,
                        height: 12.0 + (index % 2 == 0 ? 8.0 : 0.0),
                        decoration: BoxDecoration(
                          color: AegisColors.danger,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  _isListening
                      ? 'Speaking draft. Tap STOP to review.'
                      : (_isVoiceProcessing ? 'Processing transcript with AI...' : 'Tap to dictate prescription details with AI voice parsing.'),
                  style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? AegisColors.danger : AegisColors.tertiary, // AI Purple
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero, // Overrides global theme's Size.fromHeight(48) -> Size(double.infinity, 48)
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.md, vertical: AegisSpacing.xs),
                  shape: RoundedRectangleBorder(
                    borderRadius: AegisRadius.button,
                  ),
                ),
                onPressed: _isVoiceProcessing ? null : _toggleListening,
                icon: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  size: AegisIconSize.xs,
                  color: Colors.white,
                ),
                label: Text(
                  _isListening ? 'STOP' : 'DICTATE',
                  style: AegisTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
