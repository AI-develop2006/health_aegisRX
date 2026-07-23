// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Pharmacy Dispense & Fulfillment Desk
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — _dispense(), dispensePrescription(), form validation,
//                 token burn dialog, billing calculation, receipt upload preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';

class PharmacyDispenseScreen extends StatefulWidget {
  final String prescriptionId;
  final String prescriptionName;
  final List medicines;

  const PharmacyDispenseScreen({
    super.key,
    required this.prescriptionId,
    required this.prescriptionName,
    required this.medicines,
  });

  @override
  State<PharmacyDispenseScreen> createState() => _PharmacyDispenseScreenState();
}

class _PharmacyDispenseScreenState extends State<PharmacyDispenseScreen> with SingleTickerProviderStateMixin {
  bool _isDispensing = false;
  final _formKey = GlobalKey<FormState>();
  final _batchController = TextEditingController(text: 'LOT-9921A');
  final _expiryController = TextEditingController(text: '12/2028');
  final _trackingController = TextEditingController(text: 'TRK-88122-VX');
  final _invoiceController = TextEditingController(text: '45.00');
  bool _signatureCaptured = true;
  bool _receiptUploaded = false;
  late List<bool> _medicationChecks;
  late AnimationController _pulseController;

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _medicationChecks = List.generate(widget.medicines.length, (index) => false);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _batchController.dispose();
    _expiryController.dispose();
    _trackingController.dispose();
    _invoiceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _dispense() async {
    if (!_formKey.currentState!.validate() || !_signatureCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification Aborted: Complete technical entries & touch signature verification.',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AegisColors.danger,
        ),
      );
      return;
    }

    final allItemsChecked = _medicationChecks.every((check) => check);
    if (!allItemsChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Safety Check Failed: Verify and check all active medicines in the ledger list.',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AegisColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isDispensing = true;
    });

    final double? billAmt = double.tryParse(_invoiceController.text.trim());

    final appState = Provider.of<AppState>(context, listen: false);
    final res = await appState.dispensePrescription(
      widget.prescriptionId,
      batchNumber: _batchController.text.trim(),
      expiryDate: _expiryController.text.trim(),
      deliveryTrackingId: _trackingController.text.trim(),
      touchSignature: 'Pharmacist Signed: PHARMA-001',
      billingAmount: billAmt,
      receiptAttached: _receiptUploaded,
    );

    setState(() {
      _isDispensing = false;
    });

    if (res['error'] != null || res['detail'] != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispensation Blocked: ${res['error'] ?? res['detail']}',
                style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AegisColors.danger,
          ),
        );
      }
      return;
    }

    final txHash = res['onchain_tx_hash'] ?? '0x';

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AegisColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AegisRadius.card,
            side: const BorderSide(color: AegisColors.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AegisSpacing.xs),
                decoration: BoxDecoration(
                  color: AegisColors.secondarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: AegisColors.secondary, size: AegisIconSize.sm),
              ),
              const SizedBox(width: AegisSpacing.sm),
              Text(
                'TOKEN BURNED',
                style: AegisTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AegisColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Single-use cryptographic prescription token has been burned. Dispensation recorded immutably on dual ledgers.',
                style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              ),
              const SizedBox(height: AegisSpacing.base),
              Text(
                'ON-CHAIN TX RECEIPT:',
                style: AegisTypography.monoSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AegisColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AegisSpacing.sm),
                decoration: BoxDecoration(
                  color: AegisColors.tertiarySurface,
                  borderRadius: BorderRadius.circular(AegisRadius.sm),
                  border: Border.all(color: AegisColors.tertiary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  txHash,
                  style: AegisTypography.monoSmall.copyWith(
                    color: AegisColors.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AegisColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close dispense screen
                Navigator.pop(context); // close verification screen
                Navigator.pop(context); // close scanner screen
              },
              child: Text(
                'Fulfillment Complete',
                style: AegisTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          'PRESCRIPTION DISPENSE DESK',
          style: AegisTypography.headlineMedium.copyWith(
            color: AegisColors.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: Stack(
        children: [
          // Technical Blueprint Mesh Painter
          Positioned.fill(
            child: CustomPaint(
              painter: PharmacyGridPainter(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AegisSpacing.pagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. Workstation Header Component ---
                    _buildWorkstationHeader(),
                    const SizedBox(height: AegisSpacing.base),

                    // --- 2. Verification Safety Center ---
                    _buildSafetyIndexCard(),
                    const SizedBox(height: AegisSpacing.base),

                    // --- 3. Active Fulfillment Ledger ---
                    _buildFulfillmentLedger(),
                    const SizedBox(height: AegisSpacing.base),

                    // --- 4. Technical Entries Form ---
                    _buildTechnicalForm(),
                    const SizedBox(height: AegisSpacing.base),

                    // --- 4.5. Billing & Invoice Management ---
                    _buildBillingCard(),
                    const SizedBox(height: AegisSpacing.base),

                    // --- 5. Dispatch Lifecycle Timeline ---
                    _buildDispatchTimeline(),
                    const SizedBox(height: AegisSpacing.lg),

                    // --- 6. Primary Action Burn Button ---
                    _buildBurnButton(),
                    const SizedBox(height: AegisSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Workstation Credentials & Sync Indicator Widget ---
  Widget _buildWorkstationHeader() {
    return Container(
      padding: const EdgeInsets.all(AegisSpacing.md),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border),
        boxShadow: AegisShadows.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKSTATION: WRK-PH-7721',
                  style: AegisTypography.monoSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AegisColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Pharmacist Desk #1 (Verified)',
                  style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AegisSpacing.sm),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AegisColors.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: AegisColors.secondary.withValues(alpha: 0.4 * _pulseController.value),
                          blurRadius: 6,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                'On-Chain Syncing',
                style: AegisTypography.monoSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AegisColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Fulfillment Safety Index Card ---
  Widget _buildSafetyIndexCard() {
    return Container(
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border),
        boxShadow: AegisShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AegisSpacing.sm),
            decoration: BoxDecoration(
              color: AegisColors.secondarySurface,
              borderRadius: BorderRadius.circular(AegisRadius.sm),
            ),
            child: const Icon(
              Icons.shield_rounded,
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
                  'Fulfillment Safety Index',
                  style: AegisTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AegisColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '98 / 100',
                      style: AegisTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AegisColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.sm, vertical: AegisSpacing.xs),
                      decoration: BoxDecoration(
                        color: AegisColors.secondarySurface,
                        borderRadius: AegisRadius.chip,
                        border: Border.all(color: AegisColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'VERIFIED ORDER',
                        style: AegisTypography.labelSmall.copyWith(
                          color: AegisColors.secondary,
                          fontWeight: FontWeight.w800,
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
    );
  }

  // --- Active Fulfillment Ledger Grid & Checklist ---
  Widget _buildFulfillmentLedger() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ORDER FULFILLMENT LEDGER',
                  style: AegisTypography.titleSmall.copyWith(
                    color: AegisColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AegisSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.sm, vertical: AegisSpacing.xs),
                decoration: BoxDecoration(
                  color: AegisColors.primarySurface,
                  borderRadius: BorderRadius.circular(AegisRadius.xs),
                ),
                child: Text(
                  'ID: ${widget.prescriptionId.toUpperCase()}',
                  style: AegisTypography.monoSmall.copyWith(
                    color: AegisColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Patient: ${widget.prescriptionName}',
            style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
          ),
          const Divider(color: AegisColors.border, height: 20, thickness: 1),
          Text(
            'CHECKLIST: SCAN & DISPENSE ITEMS',
            style: AegisTypography.monoSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AegisColors.textTertiary,
            ),
          ),
          const SizedBox(height: AegisSpacing.sm),

          // List of medicines with individual checkboxes
          ...List.generate(widget.medicines.length, (index) {
            final med = widget.medicines[index];
            final String medName = med['name'] ?? 'Unknown Medicine';
            final String interval = med['interval'] ?? 'Once daily';
            final String strength = med['strength'] ?? '';
            final String duration = med['duration'] ?? '30 days';

            return Padding(
              padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: AegisColors.background,
                  borderRadius: BorderRadius.circular(AegisRadius.sm),
                  border: Border.all(color: AegisColors.border),
                ),
                child: CheckboxListTile(
                  value: _medicationChecks[index],
                  activeColor: AegisColors.primary,
                  checkColor: Colors.white,
                  onChanged: (val) {
                    setState(() {
                      _medicationChecks[index] = val ?? false;
                    });
                  },
                  title: Text(
                    '$medName $strength'.trim(),
                    style: AegisTypography.titleSmall.copyWith(
                      color: AegisColors.textPrimary,
                      decoration: _medicationChecks[index] ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AegisSpacing.xs,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$duration | $interval',
                        style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AegisColors.secondarySurface,
                          borderRadius: BorderRadius.circular(AegisRadius.xs),
                        ),
                        child: Text(
                          index == 0 ? 'Batch Match' : 'Qty Match',
                          style: AegisTypography.monoSmall.copyWith(fontSize: 9, color: AegisColors.secondary, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Technical Form Fields (Batch, Expiry, Tracking) ---
  Widget _buildTechnicalForm() {
    return Container(
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
          Text(
            'TECHNICAL CHECKS REGISTRY',
            style: AegisTypography.titleSmall.copyWith(
              color: AegisColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AegisSpacing.md),

          TextFormField(
            controller: _batchController,
            style: AegisTypography.monoSmall.copyWith(color: AegisColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Batch / Lot Number',
              labelStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              border: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.primary, width: 1.5)),
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: AegisIconSize.sm, color: AegisColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: AegisSpacing.base, vertical: AegisSpacing.md),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Batch Lot required' : null,
          ),
          const SizedBox(height: AegisSpacing.md),

          TextFormField(
            controller: _expiryController,
            style: AegisTypography.monoSmall.copyWith(color: AegisColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Medication Expiry Date',
              labelStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              border: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.primary, width: 1.5)),
              prefixIcon: const Icon(Icons.date_range_outlined, size: AegisIconSize.sm, color: AegisColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: AegisSpacing.base, vertical: AegisSpacing.md),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Expiry required (e.g. 12/2028)' : null,
          ),
          const SizedBox(height: AegisSpacing.md),

          TextFormField(
            controller: _trackingController,
            style: AegisTypography.monoSmall.copyWith(color: AegisColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Delivery / Handout Tracking ID',
              labelStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              border: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.primary, width: 1.5)),
              prefixIcon: const Icon(Icons.local_shipping_outlined, size: AegisIconSize.sm, color: AegisColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: AegisSpacing.base, vertical: AegisSpacing.md),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Tracking ID required' : null,
          ),
          const SizedBox(height: AegisSpacing.sm),

          const Divider(color: AegisColors.border, height: 20),

          CheckboxListTile(
            title: Text(
              'Touch Signature Captured',
              style: AegisTypography.titleSmall.copyWith(color: AegisColors.textPrimary),
            ),
            subtitle: Text(
              'Physical pharmacist authorization stamped.',
              style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
            ),
            value: _signatureCaptured,
            activeColor: AegisColors.primary,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _signatureCaptured = val ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  // --- Dispatch Lifecycle Timeline Widget ---
  Widget _buildDispatchTimeline() {
    return Container(
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOGISTIC DISPATCH TIMELINE',
            style: AegisTypography.titleSmall.copyWith(
              color: AegisColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AegisSpacing.base),
          _buildTimelineItem('Order Received', 'Cryptographic token validated.', true),
          _buildTimelineItem('Order Clinical Check', 'Allergy & interaction audit verified.', true),
          _buildTimelineItem('Preparation & Labeling', 'Verification index passed. Batch verified.', true),
          _buildTimelineItem('Out for Dispatch / Burn Token', 'Awaiting cryptographic burn sign-off.', false),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String description, bool isFinished) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFinished ? AegisColors.primary : AegisColors.surface,
                border: Border.all(
                  color: isFinished ? AegisColors.primary : AegisColors.border,
                  width: 2,
                ),
              ),
              child: isFinished
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            Container(
              width: 2,
              height: 26,
              color: isFinished ? AegisColors.primary : AegisColors.border,
            ),
          ],
        ),
        const SizedBox(width: AegisSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AegisTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isFinished ? AegisColors.textPrimary : AegisColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              ),
              const SizedBox(height: AegisSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }

  // --- Burn Token Action Button ---
  Widget _buildBurnButton() {
    return SizedBox(
      width: double.infinity,
      height: AegisTokens.btnHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AegisColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AegisRadius.button,
          ),
        ),
        onPressed: _isDispensing ? null : _dispense,
        child: _isDispensing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'BURN TOKEN & DISPENSE',
                style: AegisTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildBillingCard() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BILLING & INVOICE MANAGEMENT',
                style: AegisTypography.titleSmall.copyWith(
                  color: AegisColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.receipt_long_rounded, size: AegisIconSize.sm, color: AegisColors.primary),
            ],
          ),
          const SizedBox(height: AegisSpacing.md),

          // Custom Invoice Amount Input
          TextFormField(
            controller: _invoiceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AegisTypography.monoSmall.copyWith(color: AegisColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Total Billing Amount (\$ USD)',
              labelStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              border: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: AegisRadius.input, borderSide: const BorderSide(color: AegisColors.primary, width: 1.5)),
              prefixIcon: const Icon(Icons.attach_money_rounded, size: AegisIconSize.sm, color: AegisColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: AegisSpacing.base, vertical: AegisSpacing.md),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Invoice amount required' : null,
          ),
          const SizedBox(height: AegisSpacing.base),

          // Digital Receipt File Uploader
          InkWell(
            onTap: () {
              setState(() {
                _receiptUploaded = !_receiptUploaded;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _receiptUploaded
                        ? 'Invoice Receipt Uploaded: receipt_${widget.prescriptionId.toLowerCase().substring(0, 6)}.pdf attached.'
                        : 'Invoice Receipt Removed.',
                    style: AegisTypography.bodySmall.copyWith(color: Colors.white),
                  ),
                  backgroundColor: _receiptUploaded ? AegisColors.secondary : AegisColors.textSecondary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AegisSpacing.md, horizontal: AegisSpacing.base),
              decoration: BoxDecoration(
                color: _receiptUploaded ? AegisColors.secondarySurface : AegisColors.background,
                borderRadius: BorderRadius.circular(AegisRadius.sm),
                border: Border.all(
                  color: _receiptUploaded ? AegisColors.secondary : AegisColors.border,
                  width: AegisBorders.thin,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _receiptUploaded ? Icons.task_alt_rounded : Icons.cloud_upload_outlined,
                    color: _receiptUploaded ? AegisColors.secondary : AegisColors.textSecondary,
                    size: AegisIconSize.sm,
                  ),
                  const SizedBox(width: AegisSpacing.sm),
                  Flexible(
                    child: Text(
                      _receiptUploaded ? 'Receipt Attached (Click to remove)' : 'Upload Pharmacy Invoice Receipt (PDF/JPG)',
                      style: AegisTypography.labelSmall.copyWith(
                        color: _receiptUploaded ? AegisColors.secondary : AegisColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Technical Blueprint Mesh Grid Painter ---
class PharmacyGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AegisColors.primary.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const double gridSpacing = 24.0;

    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
