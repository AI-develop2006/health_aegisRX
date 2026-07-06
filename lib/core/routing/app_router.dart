import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_carousel_screen.dart';
import '../../features/onboarding/role_selection_screen.dart';
import '../../features/patient/screens/patient_auth_Screen/patient_login_screen.dart';
import '../../features/patient/screens/patient_auth_Screen/patient_signup_screen.dart';
import '../../features/patient/screens/patient_auth_Screen/patient_verification_screen.dart';
import '../../features/patient/screens/patient_auth_Screen/patient_auth_choice_screen.dart';
import '../../features/patient/screens/patient_secure_signin_screen.dart';
import '../../features/patient/screens/patient_auth_Screen/patient_unlock_setup_screen.dart';
import '../../features/patient/screens/patient_home_shell_screen.dart';
import '../../features/patient/screens/patient_auth_Screen/patient_unlock_screen.dart';
import '../../features/doctor/screens/doctor_login_screen.dart';
import '../../features/doctor/screens/doctor_dashboard_screen.dart';
import '../../features/doctor/screens/doctor_verification_status_screen.dart';
import '../../features/pharmacy/screens/pharmacy_login_screen.dart';
import '../../features/pharmacy/screens/pharmacy_scan_screen.dart';
import '../../features/pharmacy/screens/pharmacy_terminal_auth_screen.dart';

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
    List<Page> pages = [];

    // 1. Onboarding & Welcome Shell
    if (!appState.hasFinishedSplash) {
      pages.add(const MaterialPage(
        key: ValueKey('SplashScreen'),
        child: SplashScreen(),
      ));
    } else if (!appState.hasSeenOnboarding) {
      pages.add(const MaterialPage(
        key: ValueKey('OnboardingCarouselScreen'),
        child: OnboardingCarouselScreen(),
      ));
    } else if (appState.selectedRole == null) {
      pages.add(const MaterialPage(
        key: ValueKey('RoleSelectionScreen'),
        child: RoleSelectionScreen(),
      ));
    }
    // 2. Patient Flows
    else if (appState.selectedRole == UserRole.patient) {
      if (!appState.isLoggedIn) {
        switch (appState.patientAuthState) {
          case PatientAuthState.authChoice:
            pages.add(const MaterialPage(
              key: ValueKey('PatientAuthChoiceScreen'),
              child: PatientAuthChoiceScreen(),
            ));
            break;
          case PatientAuthState.signup:
            pages.add(const MaterialPage(
              key: ValueKey('PatientSignUpScreen'),
              child: PatientSignUpScreen(),
            ));
            break;
          case PatientAuthState.verification:
            pages.add(MaterialPage(
              key: const ValueKey('PatientVerificationScreen'),
              child: PatientVerificationScreen(
                identifier: appState.tempVerificationContact ?? '',
              ),
            ));
            break;
          case PatientAuthState.login:
            pages.add(const MaterialPage(
              key: ValueKey('PatientLoginScreen'),
              child: PatientLoginScreen(),
            ));
            break;
          case PatientAuthState.secureSignIn:
            pages.add(const MaterialPage(
              key: ValueKey('PatientSecureSignInScreen'),
              child: PatientSecureSignInScreen(),
            ));
            break;
          case PatientAuthState.unlockSetup:
            pages.add(const MaterialPage(
              key: ValueKey('PatientUnlockSetupScreen'),
              child: PatientUnlockSetupScreen(),
            ));
            break;
          default:
            pages.add(const MaterialPage(
              key: ValueKey('PatientAuthChoiceScreen'),
              child: PatientAuthChoiceScreen(),
            ));
        }
      } else {
        if (!appState.isUnlocked) {
          pages.add(const MaterialPage(
            key: ValueKey('PatientUnlockScreen'),
            child: PatientUnlockScreen(),
          ));
        } else {
          pages.add(const MaterialPage(
            key: ValueKey('PatientHomeShellScreen'),
            child: PatientHomeShellScreen(),
          ));
        }
      }
    }
    // 3. Doctor Flows
    else if (appState.selectedRole == UserRole.doctor) {
      if (!appState.isLoggedIn) {
        pages.add(const MaterialPage(
          key: ValueKey('DoctorLoginScreen'),
          child: DoctorLoginScreen(),
        ));
      } else {
        if (!appState.isVerified) {
          pages.add(const MaterialPage(
            key: ValueKey('DoctorVerificationStatusScreen'),
            child: DoctorVerificationStatusScreen(),
          ));
        } else {
          pages.add(const MaterialPage(
            key: ValueKey('DoctorDashboardScreen'),
            child: DoctorDashboardScreen(),
          ));
        }
      }
    }
    // 4. Pharmacy Flows
    else if (appState.selectedRole == UserRole.pharmacy) {
      if (!appState.isLoggedIn) {
        pages.add(const MaterialPage(
          key: ValueKey('PharmacyLoginScreen'),
          child: PharmacyLoginScreen(),
        ));
      } else {
        if (!appState.isTerminalVerified) {
          pages.add(const MaterialPage(
            key: ValueKey('PharmacyTerminalAuthScreen'),
            child: PharmacyTerminalAuthScreen(),
          ));
        } else {
          pages.add(const MaterialPage(
            key: ValueKey('PharmacyScanScreen'),
            child: PharmacyScanScreen(),
          ));
        }
      }
    }

    // Default fallback
    if (pages.isEmpty) {
      pages.add(const MaterialPage(
        child: Scaffold(
          body: Center(child: Text('Loading AegisRx...')),
        ),
      ));
    }

    return Navigator(
      key: navigatorKey,
      pages: pages,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {
    // No-op for this simple delegate setup.
  }
}
