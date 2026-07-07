import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/models/prescription.dart';
import 'patient_prescription_detail_screen.dart';

class PatientMedicationListScreen extends StatefulWidget {
  const PatientMedicationListScreen({super.key});

  @override
  State<PatientMedicationListScreen> createState() =>
      _PatientMedicationListScreenState();
}

class _PatientMedicationListScreenState
    extends State<PatientMedicationListScreen> {
  // 60-30-10 Design Tokens
  static const _bg = Color(0xFFF7F4EB);
  static const _card = Color(0xFFFFFFFF);
  static const _text = Color(0xFF4A3325);
  static const _sub = Color(0xFFD4A387);
  static const _border = Color(0xFFB88E74);
  static const _teal = Color(0xFF2E8B90);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMedicationTap(Prescription parentRx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PatientPrescriptionDetailScreen(prescription: parentRx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vault = appState.patientVault;

    // Extract medications dynamically
    final List<Map<String, dynamic>> activeMeds = [];
    final List<Map<String, dynamic>> pastMeds = [];

    for (var rx in vault) {
      for (var med in rx.medicines) {
        if (_searchQuery.isNotEmpty &&
            !med.name.toLowerCase().contains(_searchQuery)) {
          continue;
        }
        final List<String> timings = [];
        if (med.morning) timings.add('Morning');
        if (med.afternoon) timings.add('Afternoon');
        if (med.evening) timings.add('Evening');
        if (med.night) timings.add('Night');
        final scheduleStr = timings.isEmpty ? med.interval : timings.join(', ');
        final medData = {'med': med, 'rx': rx, 'schedule': scheduleStr};

        if (rx.isDispensed) {
          pastMeds.add(medData);
        } else {
          activeMeds.add(medData);
        }
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'All Medications',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: _text,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: _text),
              decoration: InputDecoration(
                hintText: 'Search medications',
                hintStyle: GoogleFonts.inter(color: _sub),
                prefixIcon: const Icon(Icons.search, color: _border),
                filled: true,
                fillColor: _card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _teal, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 28),

            // Active Medications
            Text(
              'Active Medications',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _teal,
              ),
            ),
            const SizedBox(height: 12),
            activeMeds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No active medications found.',
                      style: GoogleFonts.inter(color: _sub, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeMeds.length,
                    itemBuilder: (context, index) {
                      final item = activeMeds[index];
                      final MedicineItem med = item['med'];
                      final Prescription rx = item['rx'];
                      final String schedule = item['schedule'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () => _onMedicationTap(rx),
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _teal.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    color: _teal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: GoogleFonts.sora(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _text,
                                        ),
                                      ),
                                      Text(
                                        '$schedule · Dr. ${rx.doctorName}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _sub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: _border,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),

            // Past Medications
            Text(
              'Past Medications',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _border,
              ),
            ),
            const SizedBox(height: 12),
            pastMeds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No past medications found.',
                      style: GoogleFonts.inter(color: _sub, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pastMeds.length,
                    itemBuilder: (context, index) {
                      final item = pastMeds[index];
                      final MedicineItem med = item['med'];
                      final Prescription rx = item['rx'];
                      final String schedule = item['schedule'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () => _onMedicationTap(rx),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _border.withOpacity(0.5),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _border.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: _border,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: GoogleFonts.sora(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _sub,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        '$schedule · Dr. ${rx.doctorName}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _sub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: _border,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
