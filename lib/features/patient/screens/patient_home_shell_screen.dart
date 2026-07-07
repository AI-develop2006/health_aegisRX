import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen_patient/patient_dashboard_screen.dart';
import 'main_screen_patient/patient_history_screen.dart';
import 'patient_share_screen.dart';
import 'main_screen_patient/patient_settings_screen.dart';

// ── Design Tokens ──────────────────────────────────────────────
const _kBg = Color(0xFFF7F4EB); // 60% Cream Canvas
const _kCard = Color(0xFFFFFFFF); // Card surfaces
const _kText = Color(0xFF4A3325); // 30% Deep Bronze
const _kBorder = Color(0xFFB88E74); // Brushed Copper
const _kTeal = Color(0xFF2E8B90); // 10% Medical Teal (active)

class PatientHomeShellScreen extends StatefulWidget {
  const PatientHomeShellScreen({super.key});

  @override
  State<PatientHomeShellScreen> createState() => _PatientHomeShellScreenState();
}

class _PatientHomeShellScreenState extends State<PatientHomeShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PatientDashboardScreen(),
    const PatientHistoryScreen(),
    const PatientShareScreen(),
    const PatientSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _kCard,
          border: const Border(top: BorderSide(color: _kBorder, width: 1.0)),
          boxShadow: [
            BoxShadow(
              color: _kBorder.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: _kCard,
          selectedItemColor: _kTeal,
          unselectedItemColor: _kBorder,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded, color: _kTeal),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded, color: _kTeal),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share_outlined),
              activeIcon: Icon(Icons.share_rounded, color: _kTeal),
              label: 'Share',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded, color: _kTeal),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
