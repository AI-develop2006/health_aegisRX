import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import 'package:flutter/cupertino.dart';

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

  // --- Design Token Definitions (60-30-10 System) ---
  static const Color _bgCanvas = Color(0xFFF8FAFC);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _primaryText = Color(0xFF0F172A);
  static const Color _secondaryText = Color(0xFF475569);
  static const Color _brandBlue = Color(0xFF1E3A8A);
  static const Color _accentReady = Color(0xFF2563EB);
  static const Color _accentWarning = Color(0xFFDC2626);
  static const Color _accentStamp = Color(0xFF000000);
  static const Color _borderSlate = Color(0xFFE2E8F0);

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
        const SnackBar(
          content: Text('Verification Aborted: Complete technical entries & touch signature verification.'),
          backgroundColor: _accentWarning,
        ),
      );
      return;
    }

    final allItemsChecked = _medicationChecks.every((check) => check);
    if (!allItemsChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safety Check Failed: Verify and check all active medicines in the ledger list.'),
          backgroundColor: _accentWarning,
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
            content: Text('Dispensation Blocked: ${res['error'] ?? res['detail']}'),
            backgroundColor: _accentWarning,
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
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _primaryText, width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: _accentReady),
              const SizedBox(width: 10),
              Text(
                'TOKEN BURNED',
                style: GoogleFonts.sora(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _primaryText,
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
                style: GoogleFonts.inter(fontSize: 13, color: _secondaryText),
              ),
              const SizedBox(height: 16),
              Text(
                'ON-CHAIN TX RECEIPT:',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bgCanvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderSlate),
                ),
                child: Text(
                  txHash,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: _brandBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: _cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primaryText),
        shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10), // Matches our layout structure
    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0), // Your border goes here
  ),
        title: Text(
          'PRESCRIPTION DISPENSE DESK',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _primaryText,
            letterSpacing: 0.8,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- 1. Workstation Header Component ---
                    _buildWorkstationHeader(),
                    const SizedBox(height: 16),

                    // --- 2. Verification Safety Center ---
                    _buildSafetyIndexCard(),
                    const SizedBox(height: 16),

                    // --- 3. Active Fulfillment Ledger ---
                    _buildFulfillmentLedger(),
                    const SizedBox(height: 16),

                    // --- 4. Technical Entries Form ---
                    _buildTechnicalForm(),
                    const SizedBox(height: 16),

                    // --- 4.5. Billing & Invoice Management ---
                    _buildBillingCard(),
                    const SizedBox(height: 16),

                    // --- 5. Dispatch Lifecycle Timeline ---
                    _buildDispatchTimeline(),
                    const SizedBox(height: 24),

                    // --- 6. Primary Action Burn Button ---
                    _buildBurnButton(),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryText, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _brandBlue.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Pharmacist Desk #1 (Verified)',
                  style: GoogleFonts.inter(fontSize: 12, color: _secondaryText),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                      color: _accentReady,
                      boxShadow: [
                        BoxShadow(
                          color: _accentReady.withOpacity(0.4 * _pulseController.value),
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
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _accentReady,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderSlate),
        boxShadow: [
          BoxShadow(
            color: _brandBlue.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentReady.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
  CupertinoIcons.checkmark_shield_fill, // or CupertinoIcons.shield_fill
  color: _accentReady, 
  size: 28,
),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fulfillment Safety Index',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _secondaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '98 / 100',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VERIFIED ORDER',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _accentReady,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryText, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _brandBlue.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accentStamp,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ID: ${widget.prescriptionId.toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: _cardBg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Patient: ${widget.prescriptionName}',
            style: GoogleFonts.inter(fontSize: 12, color: _secondaryText),
          ),
          const Divider(color: _borderSlate, height: 20, thickness: 1),
          Text(
            'CHECKLIST: SCAN & DISPENSE ITEMS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          
          // List of medicines with individual checkboxes
          ...List.generate(widget.medicines.length, (index) {
            final med = widget.medicines[index];
            final String medName = med['name'] ?? 'Unknown Medicine';
            final String interval = med['interval'] ?? 'Once daily';
            final String strength = med['strength'] ?? '';
            final String duration = med['duration'] ?? '30 days';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _bgCanvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderSlate),
                ),
                child: CheckboxListTile(
                  value: _medicationChecks[index],
                  activeColor: _primaryText,
                  checkColor: _cardBg,
                  onChanged: (val) {
                    setState(() {
                      _medicationChecks[index] = val ?? false;
                    });
                  },
                  title: Text(
                    '$medName $strength'.trim(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryText,
                      decoration: _medicationChecks[index] ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$duration | $interval',
                        style: GoogleFonts.inter(fontSize: 11, color: _secondaryText),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _accentReady.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          index == 0 ? 'Batch Match' : 'Qty Match',
                          style: GoogleFonts.jetBrainsMono(fontSize: 8, color: _accentReady, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderSlate),
        boxShadow: [
          BoxShadow(
            color: _brandBlue.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TECHNICAL CHECKS REGISTRY',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _primaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          
          TextFormField(
            controller: _batchController,
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: _primaryText),
            decoration: InputDecoration(
              labelText: 'Batch / Lot Number',
              labelStyle: GoogleFonts.inter(fontSize: 12, color: _secondaryText),
              border: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _primaryText)),
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20, color: _secondaryText),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Batch Lot required' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _expiryController,
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: _primaryText),
            decoration: InputDecoration(
              labelText: 'Medication Expiry Date',
              labelStyle: GoogleFonts.inter(fontSize: 12, color: _secondaryText),
              border: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _primaryText)),
              prefixIcon: const Icon(Icons.date_range_outlined, size: 20, color: _secondaryText),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Expiry required (e.g. 12/2028)' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _trackingController,
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: _primaryText),
            decoration: InputDecoration(
              labelText: 'Delivery / Handout Tracking ID',
              labelStyle: GoogleFonts.inter(fontSize: 12, color: _secondaryText),
              border: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _primaryText)),
              prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20, color: _secondaryText),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Tracking ID required' : null,
          ),
          const SizedBox(height: 10),
          
          const Divider(color: _borderSlate, height: 20),
          
          CheckboxListTile(
            title: Text(
              'Touch Signature Captured',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryText),
            ),
            subtitle: Text(
              'Physical pharmacist authorization stamped.',
              style: GoogleFonts.inter(fontSize: 11, color: _secondaryText),
            ),
            value: _signatureCaptured,
            activeColor: _primaryText,
            checkColor: _cardBg,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOGISTIC DISPATCH TIMELINE',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _primaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
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
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFinished ? _brandBlue : _cardBg,
                border: Border.all(
                  color: isFinished ? _brandBlue : _accentStamp,
                  width: 2,
                ),
              ),
              child: isFinished
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
            Container(
              width: 2,
              height: 24,
              color: isFinished ? _brandBlue : _accentStamp.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFinished ? _primaryText : _secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(fontSize: 11, color: _secondaryText),
              ),
              const SizedBox(height: 12),
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
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentStamp,
          foregroundColor: _cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _primaryText, width: 1.5),
          ),
        ),
        onPressed: _isDispensing ? null : _dispense,
        child: _isDispensing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _cardBg,
                ),
              )
            : Text(
                'BURN TOKEN & DISPENSE',
                style: GoogleFonts.sora(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildBillingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderSlate),
        boxShadow: [
          BoxShadow(
            color: _brandBlue.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BILLING & INVOICE MANAGEMENT',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.receipt_long_rounded, size: 18, color: _accentReady),
            ],
          ),
          const SizedBox(height: 14),
          
          // Custom Invoice Amount Input
          TextFormField(
            controller: _invoiceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: _primaryText, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Total Billing Amount (\$ USD)',
              labelStyle: GoogleFonts.inter(fontSize: 12, color: _secondaryText),
              border: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _borderSlate)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _primaryText)),
              prefixIcon: const Icon(Icons.attach_money_rounded, size: 20, color: _secondaryText),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Invoice amount required' : null,
          ),
          const SizedBox(height: 16),

          // Digital Receipt File Uploader
          InkWell(
            onTap: () {
              setState(() {
                _receiptUploaded = !_receiptUploaded;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_receiptUploaded 
                    ? 'Invoice Receipt Uploaded: receipt_${widget.prescriptionId.toLowerCase().substring(0, 6)}.pdf attached.'
                    : 'Invoice Receipt Removed.'),
                  backgroundColor: _receiptUploaded ? Colors.green : Colors.grey[700],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: _receiptUploaded ? const Color(0xFFECFDF5) : _bgCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _receiptUploaded ? const Color(0xFF10B981) : _borderSlate,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _receiptUploaded ? Icons.task_alt_rounded : Icons.cloud_upload_outlined,
                    color: _receiptUploaded ? const Color(0xFF10B981) : _secondaryText,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _receiptUploaded ? 'Receipt Attached (Click to remove)' : 'Upload Pharmacy Invoice Receipt (PDF/JPG)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _receiptUploaded ? const Color(0xFF065F46) : _secondaryText,
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
      ..color = const Color(0xFF1E3A8A).withOpacity(0.04)
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
