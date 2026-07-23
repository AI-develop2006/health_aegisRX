// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Medication List Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — search logic, activeMeds/pastMeds derivation,
//                 _onMedicationTap(), navigation preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // UNCHANGED — same search listener
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

  // UNCHANGED — same navigation
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

    // UNCHANGED — same medication derivation logic
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
        final scheduleStr =
            timings.isEmpty ? med.interval : timings.join(', ');
        final medData = {'med': med, 'rx': rx, 'schedule': scheduleStr};

        if (rx.isDispensed) {
          pastMeds.add(medData);
        } else {
          activeMeds.add(medData);
        }
      }
    }

    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: AppBar(
        backgroundColor: AegisColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: AegisIconSize.sm, color: AegisColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Medications',
          style: AegisTypography.headlineMedium
              .copyWith(color: AegisColors.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AegisSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ───────────────────────────────────────
            TextField(
              controller: _searchController,
              style: AegisTypography.bodyMedium
                  .copyWith(color: AegisColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search medications',
                hintStyle: AegisTypography.bodyMedium
                    .copyWith(color: AegisColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AegisColors.textTertiary, size: AegisIconSize.md),
                filled: true,
                fillColor: AegisColors.surface,
                border: OutlineInputBorder(
                  borderRadius: AegisRadius.input,
                  borderSide:
                      const BorderSide(color: AegisColors.border, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AegisRadius.input,
                  borderSide:
                      const BorderSide(color: AegisColors.border, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AegisRadius.input,
                  borderSide: const BorderSide(
                      color: AegisColors.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AegisSpacing.md),
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── Active Medications ───────────────────────────────
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AegisColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AegisSpacing.xs),
                Text(
                  'Active Medications',
                  style: AegisTypography.titleSmall.copyWith(
                    color: AegisColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${activeMeds.length}',
                  style: AegisTypography.labelSmall.copyWith(
                    color: AegisColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AegisSpacing.sm),
            activeMeds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AegisSpacing.md),
                    child: Text(
                      'No active medications found.',
                      style: AegisTypography.bodySmall
                          .copyWith(color: AegisColors.textSecondary),
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
                        padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                        child: InkWell(
                          onTap: () => _onMedicationTap(rx),
                          borderRadius: AegisRadius.card,
                          child: Container(
                            padding: const EdgeInsets.all(AegisSpacing.md),
                            decoration: BoxDecoration(
                              color: AegisColors.surface,
                              borderRadius: AegisRadius.card,
                              border: Border.all(color: AegisColors.border),
                              boxShadow: AegisShadows.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AegisColors.secondarySurface,
                                    borderRadius: BorderRadius.circular(
                                        AegisRadius.sm),
                                  ),
                                  child: const Icon(
                                    Icons.medication_rounded,
                                    color: AegisColors.secondary,
                                    size: AegisIconSize.md,
                                  ),
                                ),
                                const SizedBox(width: AegisSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: AegisTypography.titleSmall
                                            .copyWith(
                                                color:
                                                    AegisColors.textPrimary),
                                      ),
                                      Text(
                                        '$schedule · Dr. ${rx.doctorName}',
                                        style: AegisTypography.bodySmall
                                            .copyWith(
                                                color: AegisColors
                                                    .textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: AegisIconSize.xs,
                                  color: AegisColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: AegisSpacing.lg),

            // ── Past Medications ─────────────────────────────────
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AegisColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AegisSpacing.xs),
                Text(
                  'Past Medications',
                  style: AegisTypography.titleSmall.copyWith(
                    color: AegisColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pastMeds.length}',
                  style: AegisTypography.labelSmall.copyWith(
                    color: AegisColors.textTertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AegisSpacing.sm),
            pastMeds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AegisSpacing.md),
                    child: Text(
                      'No past medications found.',
                      style: AegisTypography.bodySmall
                          .copyWith(color: AegisColors.textSecondary),
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
                        padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                        child: InkWell(
                          onTap: () => _onMedicationTap(rx),
                          borderRadius: AegisRadius.card,
                          child: Container(
                            padding: const EdgeInsets.all(AegisSpacing.md),
                            decoration: BoxDecoration(
                              color: AegisColors.surface,
                              borderRadius: AegisRadius.card,
                              border: Border.all(
                                  color: AegisColors.border
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AegisColors.surfaceDim,
                                    borderRadius: BorderRadius.circular(
                                        AegisRadius.sm),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: AegisColors.textTertiary,
                                    size: AegisIconSize.md,
                                  ),
                                ),
                                const SizedBox(width: AegisSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: AegisTypography.titleSmall
                                            .copyWith(
                                          color: AegisColors.textSecondary,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        '$schedule · Dr. ${rx.doctorName}',
                                        style: AegisTypography.bodySmall
                                            .copyWith(
                                                color: AegisColors
                                                    .textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: AegisIconSize.xs,
                                  color: AegisColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: AegisSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
