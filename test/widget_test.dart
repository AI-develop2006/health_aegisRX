import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:health_lock/main.dart';

void main() {
  testWidgets('SovereignShield Sandbox bootstrap test', (WidgetTester tester) async {
    final state = SimulationState();
    state.loginOfflineGuest(); // Bypass login gate for testing vault screen

    await tester.pumpWidget(
      ChangeNotifierProvider<SimulationState>.value(
        value: state,
        child: const SovereignShieldApp(),
      ),
    );

    // Verify that the dashboard header is rendered
    expect(find.text('SOVEREIGN SHIELD'), findsOneWidget);
    expect(find.text('Elena Vance'), findsOneWidget);

    state.dispose(); // Cancel the periodic polling timer to avoid leaks
  });
}
