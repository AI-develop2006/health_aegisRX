import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/state/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      final response = await http.get(
        Uri.parse(
          '${appState.backendUrl}/api/doctor/patient-history/${Uri.encodeComponent(widget.patientId)}'
          '?doctor_id=${Uri.encodeComponent(appState.doctorLicense ?? "9876543210")}',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          _historyData = jsonDecode(response.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        try {
          final decoded =
              jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            _error = decoded['detail'] ?? 'Failed to retrieve patient history';
            _isLoading = false;
          });
        } catch (_) {
          setState(() {
            _error = 'Server Error (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ClinicalScaffold(
        appBar: clinicalAppBar(title: 'Patient Medical File'),
        body: const Center(
          child: CircularProgressIndicator(color: Dr.green),
        ),
      );
    }

    if (_error != null) {
      return ClinicalScaffold(
        appBar: clinicalAppBar(title: 'Patient Medical File'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 56, color: Dr.red),
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center, style: Dr.heading(15)),
                const SizedBox(height: 24),
                DoctorOutlinedButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: _fetchHistory,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pInfo =
        _historyData?['patient_info'] as Map<String, dynamic>? ?? {};
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
            icon: const Icon(Icons.refresh_rounded, color: Dr.sub),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Dr.green,
        onRefresh: _fetchHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient Demographics Card ─────────────────────
              DoctorCard(
                borderColor: Dr.green.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.patientName,
                                  style: Dr.heading(18),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Age: $age · Gender: $gender',
                                  style: Dr.meta(13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const DoctorStatusBadge(
                            label: 'Active Session',
                            color: Dr.green,
                            icon: Icons.wifi_tethering_rounded),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.patientId}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, color: Dr.sub),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Divider(
                        color: Dr.border, height: 28),

                    // Allergies
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: Dr.red),
                        const SizedBox(width: 6),
                        Text('Allergies', style: Dr.heading(13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    allergies.isEmpty
                        ? Text('No known allergies recorded',
                            style: Dr.meta(13)
                                .copyWith(fontStyle: FontStyle.italic))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: allergies
                                .map((a) => _chip(a.toString(), Dr.red))
                                .toList(),
                          ),
                    const SizedBox(height: 16),

                    // Conditions
                    Row(
                      children: [
                        const Icon(Icons.medical_information_outlined,
                            size: 14, color: Dr.amber),
                        const SizedBox(width: 6),
                        Text('Chronic Conditions', style: Dr.heading(13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: conditions
                          .map((c) => _chip(c.toString(), Dr.amber))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Encounter Logs ────────────────────────────────
              sectionHeader('Encounter Logs (Blockchain Ledger)'),
              if (visits.isEmpty)
                DoctorCard(
                  child: Center(
                    child: Text('No prior encounter logs found.',
                        style: Dr.meta(13)
                            .copyWith(fontStyle: FontStyle.italic)),
                  ),
                )
              else
                ...visits.map((visit) {
                  final data =
                      visit['data'] as Map<String, dynamic>? ?? {};
                  final timestamp = visit['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                              visit['timestamp'])
                          .toLocal()
                          .toString()
                          .substring(0, 16)
                      : 'Unknown Date';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DoctorCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(timestamp,
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11, color: Dr.green)),
                          const SizedBox(height: 4),
                          Text(
                            'Dr. ${data['doctor_name'] ?? '—'} · ${data['hospital'] ?? '—'}',
                            style: Dr.body(13)
                                .copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Diagnosis: ${data['disease'] ?? '—'} · Rx: ${data['rx_id'] ?? '—'}',
                            style: Dr.meta(12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // ── Historical Prescriptions ──────────────────────
              sectionHeader('Historical Prescriptions'),
              if (prescriptions.isEmpty)
                DoctorCard(
                  child: Center(
                    child: Text('No prior prescriptions found.',
                        style: Dr.meta(13)
                            .copyWith(fontStyle: FontStyle.italic)),
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
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DoctorCard(
                      borderColor: rc.withOpacity(0.3),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${rx['date'] ?? ''} · ${rx['time'] ?? ''}',
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11, color: Dr.sub),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DoctorStatusBadge(
                                  label: riskLabel(riskBand),
                                  color: rc),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(medStr,
                              style: Dr.body(13).copyWith(
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                rx['onchain_tx_hash'] != null
                                    ? Icons.verified_user_rounded
                                    : Icons.cloud_done_outlined,
                                size: 14,
                                color: rx['onchain_tx_hash'] != null
                                    ? Dr.green
                                    : Dr.sub,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rx['onchain_tx_hash'] != null
                                      ? 'Ledger Anchor Verified (Hash: ${rx['onchain_tx_hash'].toString().length > 18 ? rx['onchain_tx_hash'].toString().substring(0, 16) : rx['onchain_tx_hash']}...)'
                                      : 'Local Sync (Offline Vault)',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    color: rx['onchain_tx_hash'] != null
                                        ? Dr.green
                                        : Dr.sub,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (override != null &&
                              override.toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Dr.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Dr.amber.withOpacity(0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.shield_outlined,
                                      color: Dr.amber, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Justification: $override',
                                      style: Dr.meta(12).copyWith(
                                          fontStyle: FontStyle.italic),
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
              const SizedBox(height: 28),

              // ── Write Prescription CTA ────────────────────────
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}
