// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Doctor Patient History Screen (Medical File)
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — _fetchHistory(), HTTP GET endpoints, appState reads,
//                 data parsing, navigation to DoctorPrescriptionEditorScreen preserved
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
import '../doctor_theme.dart';
import 'doctor_prescription_editor_screen.dart';

class DoctorPatientHistoryScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPatientHistoryScreen> createState() =>
      _DoctorPatientHistoryScreenState();
}

class _DoctorPatientHistoryScreenState
    extends State<DoctorPatientHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _historyData;

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AppState>(context, listen: false).pausePolling(
        screen: 'DoctorPatientHistoryScreen',
        reason: 'Doctor reviewing patient history',
      );
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      final response = await http
          .get(
            Uri.parse(
              '${appState.backendUrl}/api/doctor/patient-history/${Uri.encodeComponent(widget.patientId)}'
              '?doctor_id=${Uri.encodeComponent(appState.doctorLicense ?? "9876543210")}',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _historyData = jsonDecode(response.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (!mounted) return;
          setState(() {
            _error = decoded['detail'] ?? 'Failed to retrieve patient history';
            _isLoading = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _error = 'Server Error (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ClinicalScaffold(
        appBar: clinicalAppBar(title: 'Patient Medical File'),
        body: const Center(
          child: CircularProgressIndicator(color: AegisColors.secondary),
        ),
      );
    }

    if (_error != null) {
      return ClinicalScaffold(
        appBar: clinicalAppBar(title: 'Patient Medical File'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AegisSpacing.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AegisColors.danger,
                ),
                const SizedBox(height: AegisSpacing.base),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AegisTypography.headlineSmall.copyWith(
                    color: AegisColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AegisSpacing.lg),
                DoctorOutlinedButton(
                  label: 'Retry Connection',
                  icon: Icons.refresh_rounded,
                  color: AegisColors.primary,
                  onPressed: _fetchHistory,
                ),
                const SizedBox(height: AegisSpacing.md),
                DoctorPrimaryButton(
                  label: 'Write Prescription (Offline Mode)',
                  icon: Icons.edit_note_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorPrescriptionEditorScreen(
                        patientId: widget.patientId,
                        patientName: widget.patientName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pInfo = _historyData?['patient_info'] as Map<String, dynamic>? ?? {};
    final age = pInfo['age'] ?? '—';
    final gender = pInfo['gender'] ?? 'Unknown';
    final List<dynamic> conditions =
        pInfo['conditions'] as List<dynamic>? ?? ['None Recorded'];
    final List<dynamic> allergies =
        _historyData?['allergies'] as List<dynamic>? ?? [];
    final List<dynamic> prescriptions =
        _historyData?['prescriptions'] as List<dynamic>? ?? [];
    final List<dynamic> visits =
        _historyData?['visit_history'] as List<dynamic>? ?? [];

    return ClinicalScaffold(
      appBar: clinicalAppBar(
        title: 'Patient Medical File',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AegisColors.textSecondary,
            ),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
          TextButton(
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.cancelActiveSession();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Disconnect',
              style: AegisTypography.labelSmall.copyWith(
                color: AegisColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AegisColors.secondary,
        onRefresh: _fetchHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AegisSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient Demographics Card ─────────────────────
              DoctorCard(
                borderColor: AegisColors.secondary.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patientName,
                                style: AegisTypography.headlineMedium.copyWith(
                                  color: AegisColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Age: $age · Gender: $gender',
                                style: AegisTypography.bodySmall.copyWith(
                                  color: AegisColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.xs),
                        const DoctorStatusBadge(
                          label: 'Active Session',
                          color: AegisColors.secondary, // Medical Teal
                          icon: Icons.wifi_tethering_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.patientId}',
                      style: AegisTypography.monoSmall.copyWith(
                        color: AegisColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Divider(color: AegisColors.border, height: 28),

                    // Allergies (Red for Critical Safety)
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: AegisIconSize.xs,
                          color: AegisColors.danger,
                        ),
                        const SizedBox(width: AegisSpacing.xs),
                        Text(
                          'Allergies',
                          style: AegisTypography.titleSmall.copyWith(
                            color: AegisColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AegisSpacing.xs),
                    allergies.isEmpty
                        ? Text(
                            'No known allergies recorded',
                            style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Wrap(
                            spacing: AegisSpacing.xs,
                            runSpacing: AegisSpacing.xs,
                            children: allergies
                                .map(
                                  (a) => _chip(
                                    a.toString(),
                                    AegisColors.danger,
                                    AegisColors.dangerLight,
                                  ),
                                )
                                .toList(),
                          ),
                    const SizedBox(height: AegisSpacing.base),

                    // Conditions (Orange for Warnings)
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_information_outlined,
                          size: AegisIconSize.xs,
                          color: AegisColors.warning,
                        ),
                        const SizedBox(width: AegisSpacing.xs),
                        Text(
                          'Chronic Conditions',
                          style: AegisTypography.titleSmall.copyWith(
                            color: AegisColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AegisSpacing.xs),
                    Wrap(
                      spacing: AegisSpacing.xs,
                      runSpacing: AegisSpacing.xs,
                      children: conditions
                          .map(
                            (c) => _chip(
                              c.toString(),
                              AegisColors.warning,
                              AegisColors.warningLight,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AegisSpacing.lg),

              // ── Encounter Logs (Hyperledger Blockchain) ──────
              sectionHeader('Encounter Logs (Blockchain Ledger)'),
              if (visits.isEmpty)
                DoctorCard(
                  child: Center(
                    child: Text(
                      'No prior encounter logs found.',
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...visits.map((visit) {
                  final data = visit['data'] as Map<String, dynamic>? ?? {};
                  final timestamp = visit['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          visit['timestamp'],
                        ).toLocal().toString().substring(0, 16)
                      : 'Unknown Date';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                    child: DoctorCard(
                      padding: const EdgeInsets.all(AegisSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AegisSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AegisColors.tertiarySurface,
                                  borderRadius: BorderRadius.circular(
                                    AegisRadius.xs,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.link_rounded,
                                  size: AegisIconSize.xs,
                                  color: AegisColors.tertiary,
                                ),
                              ),
                              const SizedBox(width: AegisSpacing.xs),
                              Text(
                                timestamp,
                                style: AegisTypography.monoSmall.copyWith(
                                  color: AegisColors.tertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dr. ${data['doctor_name'] ?? '—'} · ${data['hospital'] ?? '—'}',
                            style: AegisTypography.titleSmall.copyWith(
                              color: AegisColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Diagnosis: ${data['disease'] ?? '—'} · Rx: ${data['rx_id'] ?? '—'}',
                            style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: AegisSpacing.lg),

              // ── Historical Prescriptions ──────────────────────
              sectionHeader('Historical Prescriptions'),
              if (prescriptions.isEmpty)
                DoctorCard(
                  child: Center(
                    child: Text(
                      'No prior prescriptions found.',
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...prescriptions.map((rx) {
                  final List<dynamic> meds =
                      rx['medicines'] as List<dynamic>? ?? [];
                  final medStr = meds
                      .map((m) => '${m['name']} (${m['interval']})')
                      .join(', ');
                  final riskBand = rx['riskBand'] ?? 'LOW';
                  final override = rx['overrideReason'];
                  final rc = riskColor(riskBand);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                    child: DoctorCard(
                      borderColor: rc.withValues(alpha: 0.4),
                      padding: const EdgeInsets.all(AegisSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${rx['date'] ?? ''} · ${rx['time'] ?? ''}',
                                  style: AegisTypography.monoSmall.copyWith(
                                    color: AegisColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DoctorStatusBadge(
                                label: riskLabel(riskBand),
                                color: rc,
                              ),
                            ],
                          ),
                          const SizedBox(height: AegisSpacing.xs),
                          Text(
                            medStr,
                            style: AegisTypography.titleSmall.copyWith(
                              color: AegisColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AegisSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                rx['onchain_tx_hash'] != null
                                    ? Icons.verified_user_rounded
                                    : Icons.cloud_done_outlined,
                                size: AegisIconSize.xs,
                                color: rx['onchain_tx_hash'] != null
                                    ? AegisColors
                                          .tertiary // AI/Blockchain Purple
                                    : AegisColors.textTertiary,
                              ),
                              const SizedBox(width: AegisSpacing.xs),
                              Expanded(
                                child: Text(
                                  rx['onchain_tx_hash'] != null
                                      ? 'Ledger Anchor Verified (Hash: ${rx['onchain_tx_hash'].toString().length > 18 ? rx['onchain_tx_hash'].toString().substring(0, 16) : rx['onchain_tx_hash']}...)'
                                      : 'Local Sync (Offline Vault)',
                                  style: AegisTypography.monoSmall.copyWith(
                                    color: rx['onchain_tx_hash'] != null
                                        ? AegisColors.tertiary
                                        : AegisColors.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (override != null &&
                              override.toString().isNotEmpty) ...[
                            const SizedBox(height: AegisSpacing.sm),
                            Container(
                              padding: const EdgeInsets.all(AegisSpacing.sm),
                              decoration: BoxDecoration(
                                color: AegisColors.warningLight,
                                borderRadius: BorderRadius.circular(
                                  AegisRadius.sm,
                                ),
                                border: Border.all(
                                  color: AegisColors.warning.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: AegisColors.warning,
                                    size: AegisIconSize.xs,
                                  ),
                                  const SizedBox(width: AegisSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'Justification: $override',
                                      style: AegisTypography.bodySmall.copyWith(
                                        color: AegisColors.warningDark,
                                        fontStyle: FontStyle.italic,
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
                  );
                }),
              const SizedBox(height: AegisSpacing.xl),

              // ── Write Prescription CTA (Royal Blue Primary Action) ──
              DoctorPrimaryButton(
                label: 'Write New Prescription',
                icon: Icons.note_add_rounded,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorPrescriptionEditorScreen(
                      patientId: widget.patientId,
                      patientName: widget.patientName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AegisSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisSpacing.sm,
        vertical: AegisSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AegisRadius.sm),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: AegisBorders.thin,
        ),
      ),
      child: Text(
        label,
        style: AegisTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
