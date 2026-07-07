import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/models/prescription.dart';

// ── Design Tokens ──────────────────────────────────────────────
const _text = Color(0xFF4A3325);
const _sub = Color(0xFFD4A387);
const _border = Color(0xFFB88E74);
const _teal = Color(0xFF2E8B90);
const _amber = Color(0xFFD97736);
const _bg = Color(0xFFF7F4EB);

// ── Time slot model ────────────────────────────────────────────
class _DoseSlot {
  final String label;      // e.g. "Morning"
  final String timeStr;    // e.g. "08:00 AM"
  final int hour;          // 24h for comparison
  final List<String> meds; // medicine names due at this slot
  bool isTaken;

  _DoseSlot({
    required this.label,
    required this.timeStr,
    required this.hour,
    required this.meds,
    this.isTaken = false,
  });
}

class DoseTimeline extends StatefulWidget {
  const DoseTimeline({super.key});

  @override
  State<DoseTimeline> createState() => _DoseTimelineState();
}

class _DoseTimelineState extends State<DoseTimeline> {
  // Patient-overridden "taken" slots — persisted within session
  final Set<String> _manuallyTaken = {};
  final Set<String> _manuallySkipped = {};

  // Build slots from active prescriptions
  List<_DoseSlot> _buildSlots(List<Prescription> vault) {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Collect all medicines from active (undispensed) prescriptions
    final Map<String, List<String>> slotMeds = {
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
      'Night': [],
    };

    for (final rx in vault.where((r) => !r.isDispensed)) {
      for (final med in rx.medicines) {
        if (med.morning) slotMeds['Morning']!.add(med.name);
        if (med.afternoon) slotMeds['Afternoon']!.add(med.name);
        if (med.evening) slotMeds['Evening']!.add(med.name);
        if (med.night) slotMeds['Night']!.add(med.name);
      }
    }

    // Fixed time mappings
    final slotConfig = [
      {'label': 'Morning', 'timeStr': '08:00 AM', 'hour': 8},
      {'label': 'Afternoon', 'timeStr': '01:00 PM', 'hour': 13},
      {'label': 'Evening', 'timeStr': '06:00 PM', 'hour': 18},
      {'label': 'Night', 'timeStr': '10:00 PM', 'hour': 22},
    ];

    final slots = <_DoseSlot>[];
    for (final cfg in slotConfig) {
      final label = cfg['label'] as String;
      final meds = slotMeds[label]!;
      if (meds.isEmpty) continue; // skip empty slots

      final hour = cfg['hour'] as int;
      final slotMinutes = hour * 60;

      // Auto-done: current time is past this slot by at least 30 min
      final autoDone = currentMinutes >= slotMinutes + 30;
      // Patient can override via tap
      final key = label;
      final isTaken = _manuallyTaken.contains(key) ||
          (autoDone && !_manuallySkipped.contains(key));

      slots.add(_DoseSlot(
        label: label,
        timeStr: cfg['timeStr'] as String,
        hour: hour,
        meds: meds,
        isTaken: isTaken,
      ));
    }

    return slots;
  }

  void _toggleSlot(String key, bool currentlyTaken) {
    setState(() {
      if (currentlyTaken) {
        // Mark as not taken (skip override)
        _manuallyTaken.remove(key);
        _manuallySkipped.add(key);
      } else {
        // Mark as taken (taken override)
        _manuallySkipped.remove(key);
        _manuallyTaken.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vault = appState.patientVault;
    final slots = _buildSlots(vault);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Intake Timeline',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border.withOpacity(0.4), width: 1),
              ),
              child: Text(
                'Today',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _border,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Empty state ─────────────────────────────────────────
        if (slots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 36, color: _border),
                  const SizedBox(height: 8),
                  Text(
                    'No medications scheduled for today.',
                    style: GoogleFonts.inter(color: _sub, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          // ── Timeline ───────────────────────────────────────────
          ...List.generate(slots.length, (i) {
            final slot = slots[i];
            final isLast = i == slots.length - 1;
            final isNext = !slot.isTaken &&
                (i == 0 || slots[i - 1].isTaken);
            return _buildSlotRow(slot, isLast, isNext);
          }),
      ],
    );
  }

  Widget _buildSlotRow(_DoseSlot slot, bool isLast, bool isNext) {
    final Color dotColor = slot.isTaken ? _teal : (isNext ? _amber : _border);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline spine ───────────────────────────────────
          Column(
            children: [
              // Dot / Checkmark
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: slot.isTaken
                      ? _teal
                      : (isNext
                          ? _amber.withOpacity(0.15)
                          : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 1.5),
                ),
                child: slot.isTaken
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : (isNext
                        ? const Icon(Icons.access_time_rounded,
                            color: _amber, size: 13)
                        : null),
              ),
              // Connector line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: _border.withOpacity(0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Slot content ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time + status row
                  Row(
                    children: [
                      Text(
                        slot.timeStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: dotColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: dotColor.withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          slot.isTaken
                              ? 'Taken'
                              : (isNext ? 'Due Next' : 'Upcoming'),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: dotColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Medicine chips ──────────────────────────
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: slot.meds
                        .map((name) => _medChip(name, slot.isTaken))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // ── Tap action ──────────────────────────────
                  GestureDetector(
                    onTap: () => _toggleSlot(slot.label, slot.isTaken),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          slot.isTaken
                              ? Icons.undo_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 14,
                          color: slot.isTaken ? _sub : _teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          slot.isTaken ? 'Mark as not taken' : 'Mark as taken',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: slot.isTaken ? _sub : _teal,
                          ),
                        ),
                      ],
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

  Widget _medChip(String name, bool isTaken) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isTaken
            ? _teal.withOpacity(0.08)
            : _border.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTaken
              ? _teal.withOpacity(0.35)
              : _border.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medication_rounded,
            size: 12,
            color: isTaken ? _teal : _border,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isTaken ? _teal : _text,
              decoration: isTaken ? TextDecoration.lineThrough : null,
              decorationColor: _teal,
            ),
          ),
        ],
      ),
    );
  }
}
