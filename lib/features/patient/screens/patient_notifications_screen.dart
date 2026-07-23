// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Notifications Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — acceptConsultation(), rejectConsultation(),
//                 pendingRequestId, Navigator.pop() all preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
// ignore: unused_import
import '../../../shared/models/prescription.dart';

class PatientNotificationsScreen extends StatelessWidget {
  const PatientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String? pendingRequestId = appState.activePendingRequestId;

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
          'Notifications',
          style: AegisTypography.headlineMedium.copyWith(
              color: AegisColors.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AegisSpacing.pagePadding),
        child: pendingRequestId == null
            ? Center(
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
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: AegisIconSize.xxl,
                        color: AegisColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AegisSpacing.base),
                    Text(
                      'No new notifications.',
                      style: AegisTypography.bodyMedium.copyWith(
                        color: AegisColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AegisSpacing.xs),
                    Text(
                      'You\'re all caught up.',
                      style: AegisTypography.bodySmall.copyWith(
                          color: AegisColors.textTertiary),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AegisSpacing.sm,
                            vertical: AegisSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AegisColors.warningLight,
                            borderRadius: AegisRadius.chip,
                            border: Border.all(
                                color: AegisColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle,
                                  size: 6, color: AegisColors.warning),
                              const SizedBox(width: AegisSpacing.xs),
                              Text(
                                'Action Required',
                                style: AegisTypography.labelSmall.copyWith(
                                  color: AegisColors.warningDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Text(
                          'Pending Requests',
                          style: AegisTypography.titleSmall.copyWith(
                              color: AegisColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AegisSpacing.base),

                    // ── Pending request card ─────────────────────
                    Container(
                      padding: const EdgeInsets.all(AegisSpacing.base),
                      decoration: BoxDecoration(
                        color: AegisColors.surface,
                        borderRadius: AegisRadius.card,
                        border: Border.all(
                            color: AegisColors.secondary.withValues(alpha: 0.4),
                            width: AegisBorders.regular),
                        boxShadow: AegisShadows.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AegisColors.secondarySurface,
                                  borderRadius:
                                      BorderRadius.circular(AegisRadius.sm),
                                ),
                                child: const Icon(
                                  Icons.emergency_share_rounded,
                                  color: AegisColors.secondary,
                                  size: AegisIconSize.md,
                                ),
                              ),
                              const SizedBox(width: AegisSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Doctor Connection Request',
                                      style: AegisTypography.titleSmall.copyWith(
                                          color: AegisColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: $pendingRequestId',
                                      style: AegisTypography.monoSmall.copyWith(
                                          color: AegisColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AegisSpacing.md),
                          const Divider(height: 1, color: AegisColors.border),
                          const SizedBox(height: AegisSpacing.md),

                          Text(
                            'A doctor is requesting temporary session access to view your health profile and write a prescription. Do you grant access?',
                            style: AegisTypography.bodyMedium.copyWith(
                              color: AegisColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: AegisSpacing.base),

                          // Action buttons — UNCHANGED logic
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  appState.rejectConsultation(pendingRequestId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Request declined successfully.',
                                        style: AegisTypography.bodySmall
                                            .copyWith(color: Colors.white),
                                      ),
                                      backgroundColor: AegisColors.danger,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AegisColors.danger,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: const BorderSide(
                                    color: AegisColors.danger,
                                    width: AegisBorders.regular,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AegisSpacing.base,
                                    vertical: AegisSpacing.sm,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AegisRadius.button),
                                  textStyle: AegisTypography.labelMedium,
                                ),
                                child: Text(
                                  'Decline',
                                  style: AegisTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AegisColors.danger,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AegisSpacing.sm),
                              ElevatedButton(
                                onPressed: () {
                                  appState.acceptConsultation(pendingRequestId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Access session granted successfully.',
                                        style: AegisTypography.bodySmall
                                            .copyWith(color: Colors.white),
                                      ),
                                      backgroundColor: AegisColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AegisColors.secondary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AegisSpacing.lg,
                                    vertical: AegisSpacing.sm,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AegisRadius.button),
                                  textStyle: AegisTypography.labelMedium,
                                ),
                                child: Text(
                                  'Grant Access',
                                  style: AegisTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
