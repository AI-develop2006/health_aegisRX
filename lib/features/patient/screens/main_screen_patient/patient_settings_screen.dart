
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  // 60-30-10 Design Tokens
  static const _bg = Color(0xFFF7F4EB);
  static const _card = Color(0xFFFFFFFF);
  static const _text = Color(0xFF4A3325);
  static const _sub = Color(0xFFD4A387);
  static const _border = Color(0xFFB88E74);
  static const _teal = Color(0xFF2E8B90);
  static const _amber = Color(0xFFD97736);
  static const _red = Color(0xFFB33A3A);

  bool _biometricUnlock = false;
  final List<String> _allergies = ['Penicillin'];

  // ── Personal Details Dialog ────────────────────────────────────
  void _openPersonalDetails(AppState appState) {
    final nameCtrl = TextEditingController(text: appState.patientName);
    final idCtrl = TextEditingController(text: appState.patientMobileOrId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border, width: 1),
        ),
        title: Text('Personal Details',
            style: GoogleFonts.sora(
                fontWeight: FontWeight.bold, color: _text, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _styledField(controller: nameCtrl, label: 'Full Name',
                icon: Icons.person_outline),
            const SizedBox(height: 16),
            _styledField(controller: idCtrl, label: 'Mobile / Patient ID',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: _sub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              await appState.updatePatientMobileOrId(idCtrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _toast('Profile updated successfully.');
            },
            child: Text('Save',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Change PIN Dialog ─────────────────────────────────────────
  void _openChangePIN(AppState appState) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border, width: 1),
          ),
          title: Text('Change PIN',
              style: GoogleFonts.sora(
                  fontWeight: FontWeight.bold, color: _text, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (appState.savedPin != null)
                _styledField(
                  controller: currentCtrl,
                  label: 'Current PIN',
                  icon: Icons.lock_outline,
                  obscure: true,
                  keyboardType: TextInputType.number,
                ),
              if (appState.savedPin != null) const SizedBox(height: 12),
              _styledField(
                controller: newCtrl,
                label: 'New PIN (4–6 digits)',
                icon: Icons.lock_reset_outlined,
                obscure: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 12),
              _styledField(
                controller: confirmCtrl,
                label: 'Confirm New PIN',
                icon: Icons.lock_clock_outlined,
                obscure: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!,
                    style: GoogleFonts.inter(color: _red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: _sub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                // Validate current pin if one exists
                if (appState.savedPin != null &&
                    currentCtrl.text != appState.savedPin) {
                  setS(() => error = 'Current PIN is incorrect.');
                  return;
                }
                if (newCtrl.text.length < 4) {
                  setS(() => error = 'PIN must be at least 4 digits.');
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  setS(() => error = 'PINs do not match.');
                  return;
                }
                await appState.savePin(newCtrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _toast('PIN updated successfully.');
              },
              child: Text('Update PIN',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Allergy Declarations Manager ──────────────────────────────
  void _openAllergyManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AllergySheet(
        allergies: List<String>.from(_allergies),
        onSave: (updated) {
          setState(() => _allergies
            ..clear()
            ..addAll(updated));
          _toast('Allergy list saved.');
        },
      ),
    );
  }

  // ── Export Prescription Data ──────────────────────────────────
  void _exportData(AppState appState) {
    final vault = appState.patientVault;
    if (vault.isEmpty) {
      _toast('No prescriptions to export.');
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('=== AegisRx Patient Export ===');
    buffer.writeln('Patient: ${appState.patientName}');
    buffer.writeln('ID: ${appState.patientMobileOrId}');
    buffer.writeln(
        'Exported: ${DateTime.now().toLocal().toString().substring(0, 16)}');
    buffer.writeln('');
    for (final rx in vault) {
      buffer.writeln('--- PRESCRIPTION: ${rx.id} ---');
      buffer.writeln('Doctor: ${rx.doctorName} | ${rx.hospitalName}');
      buffer.writeln('Diagnosis: ${rx.disease}');
      buffer.writeln('Date: ${rx.date} ${rx.time}');
      buffer.writeln(
          'Status: ${rx.isDispensed ? "DISPENSED" : "ACTIVE"}');
      buffer.writeln('Medicines:');
      for (final m in rx.medicines) {
        final timings = <String>[];
        if (m.morning) timings.add('Morning');
        if (m.afternoon) timings.add('Afternoon');
        if (m.evening) timings.add('Evening');
        if (m.night) timings.add('Night');
        buffer.writeln(
            '  • ${m.name} — ${timings.join(", ")} — ${m.beforeFood ? "Before food" : "After food"}');
        if (m.customInstruction.isNotEmpty) {
          buffer.writeln('    Note: ${m.customInstruction}');
        }
      }
      buffer.writeln('');
    }

    final exportText = buffer.toString();

    // Copy to clipboard and show preview dialog
    Clipboard.setData(ClipboardData(text: exportText));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _teal, size: 22),
            const SizedBox(width: 8),
            Text('Exported!',
                style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold, color: _text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${vault.length} prescription(s) copied to clipboard as plain text.',
              style: GoogleFonts.inter(color: _sub, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border.withOpacity(0.5)),
              ),
              child: Text(
                exportText.length > 300
                    ? '${exportText.substring(0, 300)}...'
                    : exportText,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, color: _text, height: 1.6),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Legal Pages ───────────────────────────────────────────────
  void _openLegalPage(String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _text)),
              const SizedBox(height: 6),
              Text('AegisRx Health Lock · v1.0.0',
                  style: GoogleFonts.inter(fontSize: 12, color: _sub)),
              Divider(color: _border.withOpacity(0.3), height: 32),
              Text(body,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: _text, height: 1.8)),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Settings',
            style: GoogleFonts.sora(
                fontWeight: FontWeight.bold, color: _text, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
        children: [
          // ── Patient Profile Badge ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _teal.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _teal, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.patientName,
                          style: GoogleFonts.sora(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _text)),
                      Text('ID: ${appState.patientMobileOrId}',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11, color: _sub)),
                      Text(appState.patientEmailOrId,
                          style:
                              GoogleFonts.inter(fontSize: 12, color: _sub)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Profile Section ───────────────────────────────────
          _sectionLabel('Profile'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            _settingsTile(
              icon: Icons.person_outline,
              label: 'Personal Details',
              sub: 'Update your name and contact info',
              onTap: () => _openPersonalDetails(appState),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Security Section ──────────────────────────────────
          _sectionLabel('Security'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            _settingsTile(
              icon: Icons.lock_outline,
              label: 'Change PIN',
              sub: appState.savedPin != null
                  ? 'PIN is currently set'
                  : 'Set a new access PIN',
              trailing: appState.savedPin != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _teal.withOpacity(0.4), width: 1),
                      ),
                      child: Text('Set',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _teal,
                              fontWeight: FontWeight.bold)),
                    )
                  : null,
              onTap: () => _openChangePIN(appState),
            ),
            _divider(),
            _switchTile(
              icon: Icons.fingerprint,
              label: 'Biometric Unlock',
              sub: 'Use fingerprint or Face ID to unlock',
              value: _biometricUnlock,
              onChanged: (val) {
                setState(() => _biometricUnlock = val);
                _toast(val
                    ? 'Biometric unlock enabled.'
                    : 'Biometric unlock disabled.');
              },
            ),
          ]),
          const SizedBox(height: 20),

          // ── Health Data Section ───────────────────────────────
          _sectionLabel('Health Data'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            _settingsTile(
              icon: Icons.warning_amber_rounded,
              label: 'Allergy Declarations',
              sub: _allergies.isEmpty
                  ? 'No allergies declared'
                  : _allergies.join(', '),
              subColor: _allergies.isNotEmpty ? _amber : _sub,
              onTap: _openAllergyManager,
              trailing: Text(
                '${_allergies.length}',
                style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _allergies.isNotEmpty ? _amber : _sub),
              ),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.download_rounded,
              label: 'Export Prescription Data',
              sub: '${appState.patientVault.length} prescription(s) available',
              onTap: () => _exportData(appState),
            ),
          ]),
          const SizedBox(height: 20),

          // ── About Section ─────────────────────────────────────
          _sectionLabel('About'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            _settingsTile(
              icon: Icons.description_outlined,
              label: 'Terms of Use',
              sub: 'Read our terms of service',
              onTap: () => _openLegalPage('Terms of Use', _kTermsText),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              sub: 'Read our data & privacy policy',
              onTap: () => _openLegalPage('Privacy Policy', _kPrivacyText),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.info_outline,
              label: 'App Version',
              sub: 'AegisRx Health Lock',
              onTap: null,
              trailing: Text('1.0.0',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: _sub)),
            ),
          ]),
          const SizedBox(height: 36),

          // ── Sign Out ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: _card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: _border, width: 1),
                    ),
                    title: Text('Sign Out?',
                        style: GoogleFonts.sora(
                            fontWeight: FontWeight.bold, color: _text)),
                    content: Text(
                        'You will be logged out and returned to the role selection screen.',
                        style: GoogleFonts.inter(color: _sub, fontSize: 14)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(color: _sub)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          appState.clearSession();
                        },
                        child: Text('Sign Out',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: Text('Sign out',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Reusable Builders ─────────────────────────────────────────
  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _border,
              letterSpacing: 1.0),
        ),
      );

  Widget _settingsCard({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1.0),
        ),
        child: Column(children: children),
      );

  Widget _settingsTile({
    required IconData icon,
    required String label,
    String? sub,
    Color? subColor,
    required VoidCallback? onTap,
    Widget? trailing,
  }) =>
      ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: _border, size: 22),
        title: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: _text, fontSize: 15)),
        subtitle: sub != null
            ? Text(sub,
                style: GoogleFonts.inter(
                    fontSize: 12, color: subColor ?? _sub))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: _border)
                : null),
        onTap: onTap,
      );

  Widget _switchTile({
    required IconData icon,
    required String label,
    String? sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Icon(icon, color: _border, size: 22),
        title: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: _text, fontSize: 15)),
        subtitle: sub != null
            ? Text(sub, style: GoogleFonts.inter(fontSize: 12, color: _sub))
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: _teal,
      );

  Widget _divider() => Divider(
        color: _border.withOpacity(0.3),
        height: 1,
        indent: 16,
        endIndent: 16,
      );

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: GoogleFonts.inter(color: _text, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: _sub, fontSize: 13),
          prefixIcon: Icon(icon, color: _border, size: 20),
          filled: true,
          fillColor: _bg,
          counterText: '',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: _border, width: 1.0)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: _border, width: 1.0)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: _teal, width: 1.5)),
        ),
      );
}

// ── Allergy Sheet Widget ───────────────────────────────────────
class _AllergySheet extends StatefulWidget {
  final List<String> allergies;
  final ValueChanged<List<String>> onSave;

  const _AllergySheet({required this.allergies, required this.onSave});

  @override
  State<_AllergySheet> createState() => _AllergySheetState();
}

class _AllergySheetState extends State<_AllergySheet> {
  static const _text = Color(0xFF4A3325);
  static const _sub = Color(0xFFD4A387);
  static const _border = Color(0xFFB88E74);
  static const _teal = Color(0xFF2E8B90);
  static const _amber = Color(0xFFD97736);
  static const _red = Color(0xFFB33A3A);
  static const _bg = Color(0xFFF7F4EB);

  late List<String> _list;
  final _ctrl = TextEditingController();

  final List<String> _commonAllergens = [
    'Penicillin',
    'Aspirin',
    'NSAIDs',
    'Sulfonamides',
    'Codeine',
    'Ibuprofen',
    'Latex',
    'Pollen',
    'Shellfish',
    'Peanuts',
  ];

  @override
  void initState() {
    super.initState();
    _list = List<String>.from(widget.allergies);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addAllergen(String name) {
    final clean = name.trim();
    if (clean.isEmpty || _list.contains(clean)) return;
    setState(() => _list.add(clean));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Allergy Declarations',
                style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _text)),
            const SizedBox(height: 6),
            Text('These are shown to your doctor during prescriptions.',
                style: GoogleFonts.inter(fontSize: 13, color: _sub)),
            const SizedBox(height: 20),

            // Current declared allergies
            if (_list.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _list.map((a) {
                  return Chip(
                    label: Text(a,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: _amber,
                            fontSize: 13)),
                    backgroundColor: _amber.withOpacity(0.1),
                    side: BorderSide(color: _amber.withOpacity(0.4)),
                    deleteIcon:
                        const Icon(Icons.close, size: 16, color: _red),
                    onDeleted: () => setState(() => _list.remove(a)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            if (_list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No allergies declared.',
                    style: GoogleFonts.inter(color: _sub, fontSize: 14)),
              ),
            const SizedBox(height: 20),

            // Add custom allergen
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.inter(color: _text),
                    decoration: InputDecoration(
                      labelText: 'Add allergen manually',
                      labelStyle:
                          GoogleFonts.inter(color: _sub, fontSize: 13),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _border, width: 1)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _border, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _teal, width: 1.5)),
                    ),
                    onSubmitted: _addAllergen,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    elevation: 0,
                    minimumSize: const Size(48, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _addAllergen(_ctrl.text),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Common allergen quick-add chips
            Text('Common allergens',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _border,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonAllergens
                  .where((a) => !_list.contains(a))
                  .map((a) => ActionChip(
                        label: Text(a,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: _text)),
                        backgroundColor: Colors.white,
                        side:
                            const BorderSide(color: _border, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        onPressed: () => _addAllergen(a),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  widget.onSave(_list);
                  Navigator.pop(context);
                },
                child: Text('Save Allergies',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legal Text Constants ───────────────────────────────────────
const _kTermsText = '''
1. Acceptance of Terms
By using the AegisRx Health Lock application, you agree to comply with and be bound by these Terms of Use. If you do not agree, please discontinue use of the application immediately.

2. Purpose of the App
AegisRx Health Lock is a medical data management application designed to securely store, display, and share your prescription records and health information with authorised healthcare providers.

3. User Responsibilities
You are responsible for maintaining the confidentiality of your PIN and biometric credentials. Do not share your session QR code with unauthorized individuals. Report any unauthorized access to your account immediately.

4. Medical Disclaimer
This application does not provide medical advice. All prescriptions must be issued by a licensed medical professional. Always consult a qualified doctor before taking or changing any medication.

5. Data Accuracy
AegisRx displays prescriptions as issued by your doctor. While we use cryptographic signatures to verify data integrity, always verify critical information directly with your healthcare provider.

6. Termination
AegisRx reserves the right to suspend or terminate access to the application in the event of a breach of these terms.

7. Changes to Terms
We may update these Terms of Use from time to time. Continued use of the app following any change constitutes acceptance of the new terms.
''';

const _kPrivacyText = '''
1. Data We Collect
AegisRx Health Lock collects: your name, mobile number, and prescription records issued by your doctor. We do not collect location data, browsing history, or any data unrelated to medical care.

2. How Your Data Is Used
Your prescription data is stored securely on our servers and is only shared with healthcare providers you explicitly authorize through the session QR code mechanism.

3. Cryptographic Security
All prescription records are cryptographically signed and stored on a tamper-evident ledger. Any modification to a prescription will be detected and flagged automatically.

4. Data Storage
Your data is stored on our secure backend servers. Prescription records are associated with your patient ID and are never sold to third parties.

5. Your Rights
You have the right to request deletion of your account and associated data at any time. You may also request a full export of your data through the Settings > Export Prescription Data feature.

6. Third-Party Services
AegisRx does not share your data with advertisers or third-party analytics platforms. Integration with pharmacy dispensing systems is only done with your explicit in-app authorization.

7. Changes to This Policy
We may update this Privacy Policy periodically. We will notify you through the app if significant changes are made. Continued use of the application indicates your acceptance of the updated policy.

8. Contact
For any privacy-related queries, contact support@aegisrx.health
''';
