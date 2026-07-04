import 'package:flutter/material.dart';
import 'main_screen_patient/patient_dashboard_screen.dart';
import 'main_screen_patient/patient_history_screen.dart';
import 'patient_share_screen.dart';
import 'main_screen_patient/patient_settings_screen.dart';

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
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isLight ? Colors.black12 : Colors.white10,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isLight ? Colors.white : const Color(0xFF111827),
          selectedItemColor: const Color(0xFF818CF8), // Electric Indigo
          unselectedItemColor: isLight ? Colors.black38 : Colors.white38,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF818CF8)),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded, color: Color(0xFF818CF8)),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share_rounded),
              activeIcon: Icon(Icons.share_rounded, color: Color(0xFF818CF8)),
              label: 'Share',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings_rounded, color: Color(0xFF818CF8)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
