import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/neon_card.dart';

class PatientMedicationListScreen extends StatefulWidget {
  const PatientMedicationListScreen({super.key});

  @override
  State<PatientMedicationListScreen> createState() => _PatientMedicationListScreenState();
}

class _PatientMedicationListScreenState extends State<PatientMedicationListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _activeMeds = [
    { "name": "Metformin 500 mg", "details": "Twice daily", "id": "med1" },
    { "name": "Atorvastatin 10 mg", "details": "Once at night", "id": "med2" }
  ];

  final List<Map<String, String>> _pastMeds = [
    { "name": "Amoxicillin 500 mg", "details": "Stopped - completed 7 day course", "id": "med3" }
  ];

  void _onMedicationTap(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Medication detail for "$name" coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // 60-30-10 Color Tokens
    final bg60 = isLight ? const Color(0xFFF5F6FA) : const Color(0xFF0B0F19);
    final accent10 = isLight ? const Color(0xFF4F46E5) : const Color(0xFF818CF8);

    return Scaffold(
      backgroundColor: bg60,
      appBar: AppBar(
        backgroundColor: bg60,
        title: const Text('All Medications', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
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
              decoration: InputDecoration(
                hintText: 'Search medications',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 28),

            // Active Medications Section
            Text(
              'Active medications',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent10,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeMeds.length,
              itemBuilder: (context, index) {
                final med = _activeMeds[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _onMedicationTap(med['name']!),
                    child: NeonCard(
                      neonColor: accent10,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent10.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.medical_services_rounded, color: accent10),
                        ),
                        title: Text(
                          med['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          med['details']!,
                          style: TextStyle(
                            color: isLight ? Colors.black54 : Colors.white70,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Past Medications Section
            Text(
              'Past medications',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pastMeds.length,
              itemBuilder: (context, index) {
                final med = _pastMeds[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _onMedicationTap(med['name']!),
                    child: NeonCard(
                      neonColor: Colors.blueGrey,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history_rounded, color: Colors.blueGrey),
                        ),
                        title: Text(
                          med['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          med['details']!,
                          style: TextStyle(
                            color: isLight ? Colors.black54 : Colors.white70,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
