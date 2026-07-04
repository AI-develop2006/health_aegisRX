import 'package:flutter/foundation.dart';

enum UserRole { patient, doctor, pharmacy }

enum PatientAuthState {
  authChoice,
  signup,
  verification,
  login,
  secureSignIn,
  unlockSetup,
  home,
}

class AppState extends ChangeNotifier {
  UserRole? _role;
  String? _token; // e.g. Cognito JWT

  // Onboarding & Role Selection States
  bool _hasFinishedSplash = false;
  bool _hasSeenOnboarding = false;
  UserRole? _selectedRole;

  // Patient Sub-Authentication Flow State
  PatientAuthState _patientAuthState = PatientAuthState.authChoice;
  String? _tempVerificationContact;

  // Local Security States
  bool _isUnlocked = false; // Patient PIN / biometric unlock
  String? _savedPin; // Custom local PIN

  // Doctor Verification States
  bool _isVerified = false; // Doctor registration status
  String? _doctorLicense;
  String? _doctorHospital;
  String? _doctorSpecialty;

  // Pharmacy Workstation/Hardware States
  bool _isTerminalVerified = false;

  // Getters
  UserRole? get role => _role;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _role != null;

  bool get hasFinishedSplash => _hasFinishedSplash;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  UserRole? get selectedRole => _selectedRole;
  PatientAuthState get patientAuthState => _patientAuthState;
  String? get tempVerificationContact => _tempVerificationContact;

  bool get isUnlocked => _isUnlocked;
  bool get isVerified => _isVerified;
  bool get isTerminalVerified => _isTerminalVerified;

  String? get doctorLicense => _doctorLicense;
  String? get doctorHospital => _doctorHospital;
  String? get doctorSpecialty => _doctorSpecialty;

  void completeSplash() {
    _hasFinishedSplash = true;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  void selectRole(UserRole role) {
    _selectedRole = role;
    if (role == UserRole.patient) {
      _patientAuthState = PatientAuthState.authChoice;
    }
    notifyListeners();
  }

  void setPatientAuthState(PatientAuthState state) {
    _patientAuthState = state;
    notifyListeners();
  }

  void setTempVerificationContact(String contact) {
    _tempVerificationContact = contact;
    notifyListeners();
  }

  void setSession({
    required UserRole role,
    required String token,
  }) {
    _role = role;
    _token = token;
    _selectedRole = role;
    
    // Auto-setup based on role logins
    if (role == UserRole.patient) {
      // requires PIN unlock
      _isUnlocked = false;
      _patientAuthState = PatientAuthState.home;
    } else if (role == UserRole.doctor) {
      // defaults to false if license request was never sent/approved
      _isVerified = _doctorLicense != null; 
    } else if (role == UserRole.pharmacy) {
      // requires terminal hardware key verify
      _isTerminalVerified = false;
    }

    notifyListeners();
  }

  void clearSession() {
    _role = null;
    _token = null;
    _isUnlocked = false;
    _isTerminalVerified = false;
    _patientAuthState = PatientAuthState.login;
    notifyListeners();
  }

  void resetFlow() {
    _role = null;
    _token = null;
    _selectedRole = null;
    _isUnlocked = false;
    _isTerminalVerified = false;
    _patientAuthState = PatientAuthState.authChoice;
    notifyListeners();
  }

  // Patient PIN setup/unlock
  void setPin(String pin) {
    _savedPin = pin;
    _isUnlocked = true;
    _patientAuthState = PatientAuthState.home;
    notifyListeners();
  }

  bool unlockDevice(String pin) {
    if (_savedPin == null || _savedPin == pin || pin == "1234") { // Allow 1234 default
      _isUnlocked = true;
      _patientAuthState = PatientAuthState.home;
      notifyListeners();
      return true;
    }
    return false;
  }

  String? _activePatientId;
  String? _activePatientName;

  String? get activePatientId => _activePatientId;
  String? get activePatientName => _activePatientName;

  void startDoctorPatientSession(String patientId, String patientName) {
    _activePatientId = patientId;
    _activePatientName = patientName;
    notifyListeners();
  }

  void endDoctorPatientSession() {
    _activePatientId = null;
    _activePatientName = null;
    notifyListeners();
  }

  // Doctor Verification Request
  void requestDoctorVerification({
    required String name,
    required String license,
    required String hospital,
    required String specialty,
    bool approved = true,
  }) {
    _doctorLicense = license;
    _doctorHospital = hospital;
    _doctorSpecialty = specialty;
    _isVerified = approved;
    notifyListeners();
  }

  // Pharmacy workstation authentication
  void verifyPharmacyTerminal() {
    _isTerminalVerified = true;
    notifyListeners();
  }
}
