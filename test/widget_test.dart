import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:health_lock/main.dart';
import 'package:health_lock/core/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AegisRx App Bootstrap Test', (WidgetTester tester) async {
    // Pre-populate SharedPreferences so AppState's async _initSession() loads an authenticated session
    SharedPreferences.setMockInitialValues({
      'finished_splash': true,
      'completed_onboarding': true,
      'session_patient': '{"token": "dummy_token", "name": "Elena Vance", "patient_id": "992818"}',
      'saved_pin': '1234',
    });

    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: AegisRxApp(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    // Verify patient dashboard renders welcome message and core widgets
    expect(find.text('Good day, Elena Vance'), findsOneWidget);
    expect(find.text('Prescriptions'), findsOneWidget);
    expect(find.text('Allergy Alerts'), findsOneWidget);

    // Clean up resources to prevent pending timer errors
    appState.dispose();
  });
}




