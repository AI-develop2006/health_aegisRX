import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: load persisted auth/role from secure storage or Cognito.
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
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
