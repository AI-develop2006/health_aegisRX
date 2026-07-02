import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../../features/patient/screens/patient_dashboard_screen.dart';
import '../../features/patient/screens/patient_login_screen.dart';

RouterConfig<Object> createAppRouter(AppState appState) {
  return RouterConfig(
    routerDelegate: _SimpleRouterDelegate(
      appState: appState,
    ),
  );
}

class _SimpleRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  final AppState appState;

  _SimpleRouterDelegate({required this.appState}) {
    appState.addListener(notifyListeners);
  }

  @override
  void dispose() {
    appState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        if (!appState.isLoggedIn)
          const MaterialPage(
            child: PatientLoginScreen(),
          )
        else
          const MaterialPage(
            child: PatientDashboardScreen(),
          ),
      ],
      onPopPage: (route, result) => route.didPop(result),
    );
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {
    // No-op for this simple example.
  }
}
