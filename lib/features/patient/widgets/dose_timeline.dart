import 'package:flutter/material.dart';

class DoseTimeline extends StatelessWidget {
  const DoseTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Intake Timeline (Today)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (index) {
          final times = ['08:00 AM', '02:00 PM', '08:00 PM'];
          final meds = ['Metformin 500mg', 'Aspirin 75mg', 'Metformin 500mg'];
          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A86B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index != 2)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.white24,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(times[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(meds[index], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                ],
              )
            ],
          );
        }),
      ],
    );
  }
}
