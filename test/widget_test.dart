import 'package:flutter_test/flutter_test.dart';
import 'package:health_lock/main.dart';
import 'package:health_lock/core/state/app_state.dart';

void main() {
  testWidgets('AegisRx App Bootstrap Test', (WidgetTester tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      AegisRxApp(appState: appState),
    );

    // Verify patient dashboard renders default welcome message
    expect(find.text('AegisRx Patient Vault'), findsOneWidget);
    expect(find.text('Welcome to AegisRx Patient Vault'), findsOneWidget);
  });
}
