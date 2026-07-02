import 'package:flutter/material.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorPrescriptionEditorScreen extends StatefulWidget {
  const DoctorPrescriptionEditorScreen({super.key});

  @override
  State<DoctorPrescriptionEditorScreen> createState() => _DoctorPrescriptionEditorScreenState();
}

class _DoctorPrescriptionEditorScreenState extends State<DoctorPrescriptionEditorScreen> {
  final _drugController = TextEditingController();
  final _dosageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Composer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: NeonCard(
          neonColor: const Color(0xFF0F52BA),
          child: Column(
            children: [
              TextField(
                controller: _drugController,
                decoration: const InputDecoration(labelText: 'Drug Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg, twice daily)'),
              ),
              const SizedBox(height: 24),
              GlassmorphicButton(
                onPressed: () {
                  // Pre-flight audit trigger logic
                },
                child: const Text('Initiate Clinical Safety Check'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
