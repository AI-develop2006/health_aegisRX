// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient History Screen (Vault Ledger)
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — vault reads, visit parsing, navigation preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../shared/models/prescription.dart';
import '../patient_prescription_detail_screen.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vault = appState.patientVault;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AegisColors.background,
        appBar: AppBar(
          backgroundColor: AegisColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: AegisSpacing.pagePadding,
          title: Text(
            'Health Vault Ledger',
            style: AegisTypography.headlineMedium.copyWith(
                color: AegisColors.textPrimary),
          ),
          bottom: TabBar(
            labelColor: AegisColors.primary,
            unselectedLabelColor: AegisColors.textTertiary,
            indicatorColor: AegisColors.primary,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: AegisTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: AegisTypography.labelMedium,
            dividerColor: AegisColors.border,
            tabs: const [
              Tab(
                icon: Icon(Icons.description_rounded, size: AegisIconSize.sm),
                text: 'Prescriptions',
              ),
              Tab(
                icon: Icon(Icons.link_rounded, size: AegisIconSize.sm),
                text: 'Ledger',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PrescriptionsTab(vault: vault),
            _VisitsLedgerTab(appState: appState),
          ],
        ),
      ),
    );
  }
}

// ── Prescriptions Tab ─────────────────────────────────────────────────────
class _PrescriptionsTab extends StatelessWidget {
  final List<Prescription> vault;
  const _PrescriptionsTab({required this.vault});

  @override
  Widget build(BuildContext context) {
    if (vault.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AegisColors.surfaceDim,
                borderRadius: BorderRadius.circular(AegisRadius.md),
              ),
              child: const Icon(Icons.history_rounded,
                  size: AegisIconSize.xxl, color: AegisColors.textTertiary),
            ),
            const SizedBox(height: AegisSpacing.base),
            Text('No prescription history found.',
                style: AegisTypography.bodyMedium.copyWith(
                    color: AegisColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisSpacing.pagePadding,
        vertical: AegisSpacing.base,
      ),
      itemCount: vault.length,
      itemBuilder: (context, index) {
        final rx = vault[index];
        final bool isActive = !rx.isDispensed;
        final Color statusColor =
            isActive ? AegisColors.secondary : AegisColors.textTertiary;
        final Color statusBg =
            isActive ? AegisColors.secondarySurface : AegisColors.surfaceDim;

        return Padding(
          padding: const EdgeInsets.only(bottom: AegisSpacing.md),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PatientPrescriptionDetailScreen(prescription: rx),
              ),
            ),
            borderRadius: AegisRadius.card,
            child: Container(
              padding: const EdgeInsets.all(AegisSpacing.base),
              decoration: BoxDecoration(
                color: AegisColors.surface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.border),
                boxShadow: AegisShadows.sm,
              ),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius:
                          BorderRadius.circular(AegisRadius.sm),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: statusColor,
                      size: AegisIconSize.md,
                    ),
                  ),
                  const SizedBox(width: AegisSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rx.doctorName,
                          style: AegisTypography.titleSmall.copyWith(
                              color: AegisColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${rx.hospitalName} · ${rx.disease}',
                          style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary),
                        ),
                        const SizedBox(height: AegisSpacing.xs),
                        Text(
                          '${rx.date}  ${rx.time}',
                          style: AegisTypography.monoSmall.copyWith(
                              color: AegisColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AegisSpacing.sm,
                          vertical: AegisSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: AegisRadius.chip,
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Dispensed',
                          style: AegisTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AegisSpacing.xs),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: AegisIconSize.xs,
                          color: AegisColors.textTertiary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Visits Ledger Tab ─────────────────────────────────────────────────────
class _VisitsLedgerTab extends StatelessWidget {
  final AppState appState;
  const _VisitsLedgerTab({required this.appState});

  @override
  Widget build(BuildContext context) {
    final visits = appState.visitHistory;

    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AegisColors.tertiarySurface,
                borderRadius: BorderRadius.circular(AegisRadius.md),
              ),
              child: const Icon(Icons.link_rounded,
                  size: AegisIconSize.xxl, color: AegisColors.tertiary),
            ),
            const SizedBox(height: AegisSpacing.base),
            Text('No visit logs written to the ledger yet.',
                style: AegisTypography.bodyMedium.copyWith(
                    color: AegisColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisSpacing.pagePadding,
        vertical: AegisSpacing.base,
      ),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        // UNCHANGED — visit parsing logic
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
          padding: const EdgeInsets.only(bottom: AegisSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AegisSpacing.base),
            decoration: BoxDecoration(
              color: AegisColors.surface,
              borderRadius: AegisRadius.card,
              border: Border.all(color: AegisColors.border),
              boxShadow: AegisShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hyperledger icon — AI Purple
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AegisColors.tertiarySurface,
                        borderRadius: BorderRadius.circular(AegisRadius.sm),
                      ),
                      child: const Icon(Icons.link_rounded,
                          color: AegisColors.tertiary, size: AegisIconSize.md),
                    ),
                    const SizedBox(width: AegisSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docName,
                            style: AegisTypography.titleSmall.copyWith(
                                color: AegisColors.textPrimary),
                          ),
                          Text(
                            hospital,
                            style: AegisTypography.bodySmall.copyWith(
                                color: AegisColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AegisSpacing.sm,
                        vertical: AegisSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AegisColors.secondarySurface,
                        borderRadius: AegisRadius.chip,
                        border: Border.all(
                            color: AegisColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Verified',
                        style: AegisTypography.labelSmall.copyWith(
                          color: AegisColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AegisSpacing.sm),
                const Divider(height: 1, color: AegisColors.border),
                const SizedBox(height: AegisSpacing.sm),

                // Data rows
                _LedgerRow(label: 'Indication', value: disease),
                const SizedBox(height: AegisSpacing.xs),
                _LedgerRow(
                  label: 'Prescription ID',
                  value: rxId,
                  isMono: true,
                  valueColor: AegisColors.tertiary,
                ),
                const SizedBox(height: AegisSpacing.xs),
                _LedgerRow(
                  label: 'Ledger Timestamp',
                  value: date.isNotEmpty ? date : timestamp,
                  isMono: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final Color? valueColor;

  const _LedgerRow({
    required this.label,
    required this.value,
    this.isMono = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AegisTypography.labelSmall.copyWith(
            color: AegisColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AegisSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isMono
                ? AegisTypography.monoSmall.copyWith(
                    color: valueColor ?? AegisColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  )
                : AegisTypography.bodySmall.copyWith(
                    color: valueColor ?? AegisColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
