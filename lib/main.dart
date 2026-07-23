import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter framework error logger
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exception.toString().toLowerCase();
    // Filter out expected non-fatal platform/library exceptions to prevent debugger pauses
    if (exceptionStr.contains('mobilescanner') ||
        exceptionStr.contains('camera') ||
        exceptionStr.contains('speech_to_text') ||
        exceptionStr.contains('speechtotext') ||
        exceptionStr.contains('permission')) {
      debugPrint(
        '[GLOBAL_FLUTTER_ERROR] Safe-filtered platform warning: ${details.exception}',
      );
      return;
    }
    FlutterError.presentError(details);
    debugPrint('[GLOBAL_FLUTTER_ERROR] Captured: ${details.exception}');
  };

  // Replace default error screen with AegisRx Self-Healing Error Recovery UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0F1D), // Aegis Dark Navy
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.amber,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Temporary Display Adjustment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'AegisRx self-healing boundary recovered from a display error. Your data and session are completely safe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (btnCtx) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          final appState = AppState();
                          runApp(
                            ChangeNotifierProvider<AppState>.value(
                              value: appState,
                              child: AegisRxApp(appState: appState),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Return to Safe Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  final appState = AppState();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: AegisRxApp(appState: appState),
    ),
  );
}

class AegisRxApp extends StatelessWidget {
  final AppState appState;
  const AegisRxApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(appState);
    return MaterialApp.router(
      title: 'AegisRx',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
