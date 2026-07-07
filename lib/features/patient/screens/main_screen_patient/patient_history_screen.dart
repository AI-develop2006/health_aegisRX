import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../shared/models/prescription.dart';
import '../patient_prescription_detail_screen.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  // 60-30-10 Design Tokens
  static const _bg = Color(0xFFF7F4EB);
  static const _card = Color(0xFFFFFFFF);
  static const _text = Color(0xFF4A3325);
  static const _sub = Color(0xFFD4A387);
  static const _border = Color(0xFFB88E74);
  static const _teal = Color(0xFF2E8B90);
  static const _red = Color(0xFFB33A3A);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vault = appState.patientVault;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          title: Text(
            'Health Vault Ledger',
            style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: _text),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            labelColor: _teal,
            unselectedLabelColor: _sub,
            indicatorColor: _teal,
            labelStyle: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.sora(fontSize: 13),
            tabs: const [
              Tab(text: 'Prescriptions', icon: Icon(Icons.description_rounded, size: 20)),
              Tab(text: 'Visits Ledger', icon: Icon(Icons.verified_user_rounded, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrescriptionsTab(context, vault),
            _buildVisitsTab(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsTab(BuildContext context, List<Prescription> vault) {
    if (vault.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 64, color: _border),
            const SizedBox(height: 16),
            Text(
              'No prescription history found.',
              style: GoogleFonts.inter(color: _sub, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: vault.length,
      itemBuilder: (context, index) {
        final rx = vault[index];
        final statusColor = rx.isDispensed ? _red : _teal;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PatientPrescriptionDetailScreen(prescription: rx),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Icon(Icons.description_rounded,
                        color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rx.doctorName,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${rx.hospitalName} · ${rx.disease}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _sub),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${rx.date} at ${rx.time}',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 10, color: _border),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: _border),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitsTab(AppState appState) {
    final visits = appState.visitHistory;
    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 64, color: _border),
            const SizedBox(height: 16),
            Text(
              'No visit logs written to the ledger yet.',
              style: GoogleFonts.inter(color: _sub, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final block = visits[index];
        final map = block is Map ? block : {};
        final data = map['data'] is Map ? map['data'] : map;
        final timestamp = map['timestamp'] ?? '';

        final docName = data['doctor_name'] ?? 'Doctor';
        final hospital = data['hospital'] ?? 'Hospital';
        final disease = data['disease'] ?? 'Consultation';
        final rxId = data['rx_id'] ?? 'N/A';
        final date = data['date'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: _teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docName,
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _text,
                            ),
                          ),
                          Text(
                            hospital,
                            style: GoogleFonts.inter(fontSize: 11, color: _sub),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Indication:',
                      style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      disease,
                      style: GoogleFonts.inter(fontSize: 12, color: _text),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prescription ID:',
                      style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      rxId,
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _border, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ledger Timestamp:',
                      style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      date.isNotEmpty ? date : timestamp,
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _border),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
