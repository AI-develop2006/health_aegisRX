import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoseTimeline extends StatelessWidget {
  const DoseTimeline({super.key});

  Color _getDotColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFF59E0B); // Amber - Morning
      case 1:
        return const Color(0xFF3B82F6); // Blue - Afternoon
      case 2:
        return const Color(0xFF8B5CF6); // Violet - Night
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isLight ? const Color(0xFF64748B) : Colors.white60,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Intake Timeline (Today)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLegendItem(context, const Color(0xFFF59E0B), 'Morning'),
            const SizedBox(width: 16),
            _buildLegendItem(context, const Color(0xFF3B82F6), 'Afternoon'),
            const SizedBox(width: 16),
            _buildLegendItem(context, const Color(0xFF8B5CF6), 'Night'),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(3, (index) {
          final times = ['08:00 AM', '02:00 PM', '08:00 PM'];
          final meds = ['Metformin 500mg', 'Aspirin 75mg', 'Metformin 500mg'];
          final dotColor = _getDotColor(index);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  if (index != 2)
                    Container(
                      width: 2,
                      height: 48,
                      color: isLight ? Colors.black12 : Colors.white24,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      times[index],
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meds[index],
                      style: GoogleFonts.inter(
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              )
            ],
          );
        }),
      ],
    );
  }
}
