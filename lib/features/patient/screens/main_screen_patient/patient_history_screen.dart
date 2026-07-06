import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  final List<Map<String, String>> _historyData = const [
    {
      "date": "20 June 2026",
      "text": "Started Metformin 500 mg twice daily."
    },
    {
      "date": "25 June 2026",
      "text": "Doctor updated Atorvastatin from 5 mg to 10 mg."
    },
    {
      "date": "28 June 2026",
      "text": "You reported a mild headache."
    }
  ];

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
        title: const Text('History', style: TextStyle(fontFamily: 'Sora')),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          final item = _historyData[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: NeonCard(
              neonColor: accent10,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['date']!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['text']!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
