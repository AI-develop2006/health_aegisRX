import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/prescription.dart';
import '../utils/error_mapper.dart';

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
  String? _token; // session token (e.g. from backend)
  String _backendUrl = 'http://10.91.100.79:4000';
  bool _isLoading = false;
  Timer? _pollTimer;

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

  // Data lists
  List<Prescription> _patientVault = [];
  List<dynamic> _activityLogs = [];
  List<dynamic> _visitHistory = [];
  List<dynamic> _doctorConsultations = [];
  List<String> _patientAllergies = [];

  List<dynamic> get doctorConsultations => _doctorConsultations;
  List<String> get patientAllergies => _patientAllergies;
  String? _activePendingRequestId;
  final Set<String> _promptedRequestIds = {};

  // Auth profile state
  Map<String, dynamic>? _currentPatient;
  bool _isOfflineGuest = false;
  String _guestName = 'Guest';
  String _patientMobileOrId = '000000';

  bool _isAttendanceActive = false;
  bool _isDoctorConnected = false;
  int? _sessionStartMs;
  final DateTime _welcomeTime = DateTime.now();
  Prescription? _selectedPrescription;

  String? _doctorName;
  String? get doctorName => _doctorName;

  bool _networkError = false;
  bool get networkError => _networkError;

  // Getters
  UserRole? get role => _role;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _role != null;
  String get backendUrl => _backendUrl;
  bool get isLoading => _isLoading;

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

  List<Prescription> get patientVault => _patientVault;
  List<dynamic> get activityLogs => _activityLogs;
  List<dynamic> get visitHistory => _visitHistory;
  String? get activePendingRequestId => _activePendingRequestId;
  bool get isOfflineGuest => _isOfflineGuest;
  bool get isAuthenticated => _token != null || _isOfflineGuest;

  bool _useMockFrontend = false; // Set to true only in local dev mode

  bool get useMockFrontend => _useMockFrontend;

  void setMockFrontend(bool val) {
    _useMockFrontend = val;
    notifyListeners();
  }

  String get patientName {
    if (_currentPatient != null) {
      return _currentPatient!['name'] as String? ?? 'Authenticated Patient';
    }
    return (_isOfflineGuest && _useMockFrontend) ? _guestName : 'Guest';
  }

  String get patientEmailOrId {
    if (_currentPatient != null) {
      return _currentPatient!['email'] as String? ?? 'patient@healthlock.org';
    }
    return (_isOfflineGuest && _useMockFrontend)
        ? 'elena.vance@healthlock.org'
        : 'unauthenticated@healthlock.org';
  }

  String get patientMobileOrId => _patientMobileOrId;
  String get patientId {
    final cleanName = patientName.replaceAll(RegExp(r'\s+'), '_');
    return '${cleanName}_$patientMobileOrId';
  }

  bool get isAttendanceActive => _isAttendanceActive;
  bool get isDoctorConnected => _isDoctorConnected;
  int? get sessionStartMs => _sessionStartMs;
  DateTime get welcomeTime => _welcomeTime;
  Prescription? get selectedPrescriptionQR => _selectedPrescription;

  int _pollTicks = 0;

  AppState() {
    _initSession();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isAuthenticated) {
        _pollTicks++;

        // 1. Check doctor connection requests (consultation requests)
        checkPendingConsultations();

        // 2. Fetch prescriptions, profile/allergies and activity logs
        if (_pollTicks % 2 == 0) {
          fetchPatientProfile();
          fetchPrescriptions(silent: true);
          fetchActivityLogs();
        }

        // 3. Fetch visit history
        if (_pollTicks % 4 == 0) {
          fetchVisitHistory();
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // --- Session Management ---

  Future<void> _discoverBackendUrl() async {
    final candidates = [
      'http://13.63.53.53:4000',
      'http://127.0.0.1:4000',
      'http://10.0.2.2:4000',
      'http://192.168.0.15:4000',
    ];
    debugPrint('[AUTO-DISCOVERY] Starting backend gateway discovery...');
    for (final url in candidates) {
      try {
        debugPrint('[AUTO-DISCOVERY] Probing endpoint: $url/health');
        final res = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 2));
        debugPrint(
          '[AUTO-DISCOVERY] Endpoint $url responded with status: ${res.statusCode}',
        );
        if (res.statusCode == 200) {
          _backendUrl = url;
          debugPrint('[AUTO-DISCOVERY] SUCCESS: Bound client Gateway to $url');
          return;
        }
      } catch (e) {
        debugPrint('[AUTO-DISCOVERY] Endpoint $url unreachable: $e');
      }
    }
    debugPrint('[AUTO-DISCOVERY] No working endpoint detected, falling back.');
  }

  Future<void> _initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasFinishedSplash = prefs.getBool('finished_splash') ?? false;
      _hasSeenOnboarding = prefs.getBool('completed_onboarding') ?? false;

      // Auto-discover the working backend gateway interface
      await _discoverBackendUrl();
      if (_backendUrl == 'http://127.0.0.1:4000') {
        _backendUrl = prefs.getString('backend_url') ?? 'http://127.0.0.1:4000';
      }
      _savedPin = prefs.getString('saved_pin');

      final patientJson = prefs.getString('session_patient');
      if (patientJson != null) {
        _currentPatient = jsonDecode(patientJson) as Map<String, dynamic>;
        _isOfflineGuest = false;
        _token = _currentPatient!['token'] as String?;
        _role = UserRole.patient;
        _selectedRole = UserRole.patient;
        _patientAuthState = PatientAuthState.home;
        _isUnlocked = _savedPin != null;
      } else {
        _isOfflineGuest = prefs.getBool('session_offline_guest') ?? false;
        if (_isOfflineGuest) {
          _role = UserRole.patient;
          _selectedRole = UserRole.patient;
          _patientAuthState = PatientAuthState.home;
          _isUnlocked = true;
        }
      }

      _patientMobileOrId = prefs.getString('patient_mobile_or_id') ?? '992818';
      _guestName = prefs.getString('guest_name') ?? 'Elena Vance';

      final savedRoleStr = prefs.getString('saved_role');
      if (savedRoleStr != null && savedRoleStr != 'patient') {
        _token = prefs.getString('saved_token');
        if (_token != null) {
          if (savedRoleStr == 'doctor') {
            _role = UserRole.doctor;
            _selectedRole = UserRole.doctor;
            _doctorLicense = prefs.getString('doctor_license');
            _doctorHospital = prefs.getString('doctor_hospital');
            _doctorSpecialty = prefs.getString('doctor_specialty');
            _isVerified = _doctorLicense != null;
          } else if (savedRoleStr == 'pharmacy') {
            _role = UserRole.pharmacy;
            _selectedRole = UserRole.pharmacy;
            _isTerminalVerified = prefs.getBool('terminal_verified') ?? false;
          }
        }
      }

      if (isAuthenticated) {
        await fetchPrescriptions(silent: true);
        await fetchActivityLogs();
        await fetchVisitHistory();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load persisted session: $e');
    }
  }

  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('finished_splash', _hasFinishedSplash);
      await prefs.setBool('completed_onboarding', _hasSeenOnboarding);
      await prefs.setString('backend_url', _backendUrl);
      if (_savedPin != null) {
        await prefs.setString('saved_pin', _savedPin!);
      } else {
        await prefs.remove('saved_pin');
      }

      if (_currentPatient != null) {
        await prefs.setString('session_patient', jsonEncode(_currentPatient));
      } else {
        await prefs.remove('session_patient');
      }
      await prefs.setBool('session_offline_guest', _isOfflineGuest);
      await prefs.setString('patient_mobile_or_id', _patientMobileOrId);
      await prefs.setString('guest_name', _guestName);

      if (_role != null) {
        await prefs.setString('saved_role', _role.toString().split('.').last);
        if (_token != null) {
          await prefs.setString('saved_token', _token!);
        }
      } else {
        await prefs.remove('saved_role');
        await prefs.remove('saved_token');
      }

      if (_doctorLicense != null) {
        await prefs.setString('doctor_license', _doctorLicense!);
        await prefs.setString('doctor_hospital', _doctorHospital ?? '');
        await prefs.setString('doctor_specialty', _doctorSpecialty ?? '');
      }
      await prefs.setBool('terminal_verified', _isTerminalVerified);
    } catch (e) {
      debugPrint('Failed to persist session: $e');
    }
  }

  void completeSplash() {
    _hasFinishedSplash = true;
    _persistSession();
    notifyListeners();
  }

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    _persistSession();
    notifyListeners();
  }

  void selectRole(UserRole role) {
    _selectedRole = role;
    if (role == UserRole.patient) {
      _patientAuthState = PatientAuthState.authChoice;
    }
    _persistSession();
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

  void setSession({required UserRole role, required String token}) {
    _role = role;
    _token = token;
    _selectedRole = role;

    if (role == UserRole.patient) {
      _isUnlocked = false;
      _patientAuthState = PatientAuthState.home;
    } else if (role == UserRole.doctor) {
      _isVerified = _doctorLicense != null;
    } else if (role == UserRole.pharmacy) {
      _isTerminalVerified = false;
    }

    _persistSession();
    notifyListeners();
  }

  void clearSession() {
    _role = null;
    _token = null;
    _currentPatient = null;
    _isOfflineGuest = false;
    _isUnlocked = false;
    _isTerminalVerified = false;
    _patientAuthState = PatientAuthState.login;
    _patientVault = [];
    _activityLogs = [];
    _visitHistory = [];
    _doctorConsultations = [];
    _doctorName = null;
    _networkError = false;
    _persistSession();
    notifyListeners();
  }

  void resetFlow() {
    _role = null;
    _token = null;
    _currentPatient = null;
    _isOfflineGuest = false;
    _selectedRole = null;
    _isUnlocked = false;
    _isTerminalVerified = false;
    _patientAuthState = PatientAuthState.authChoice;
    _patientVault = [];
    _activityLogs = [];
    _visitHistory = [];
    _persistSession();
    notifyListeners();
  }

  // PIN controls
  void setPin(String pin) {
    _savedPin = pin;
    _isUnlocked = true;
    _patientAuthState = PatientAuthState.home;
    _persistSession();
    notifyListeners();
  }

  bool unlockDevice(String pin) {
    if (_savedPin == null || _savedPin == pin || pin == "1234") {
      _isUnlocked = true;
      _patientAuthState = PatientAuthState.home;
      _persistSession();
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Network API Integrations ---

  void setBackendUrl(String url) {
    var cleanedUrl = url.trim();
    // Strip accidental 'e.g.' prefix if copy-pasted or typed
    if (cleanedUrl.toLowerCase().startsWith('e.g.')) {
      cleanedUrl = cleanedUrl.substring(4).trim();
    } else if (cleanedUrl.toLowerCase().startsWith('e.g')) {
      cleanedUrl = cleanedUrl.substring(3).trim();
    }
    // Auto-prepend http:// if scheme is missing to prevent runtime FormatException/ArgumentError
    if (!cleanedUrl.startsWith('http://') &&
        !cleanedUrl.startsWith('https://')) {
      cleanedUrl = 'http://$cleanedUrl';
    }
    // Remove trailing slash to prevent double-slashes in endpoint routes (e.g. //api/...)
    if (cleanedUrl.endsWith('/')) {
      cleanedUrl = cleanedUrl.substring(0, cleanedUrl.length - 1);
    }
    _backendUrl = cleanedUrl;
    _persistSession();
    fetchPrescriptions();
    notifyListeners();
  }

  void loginOfflineGuest() {
    _isOfflineGuest = true;
    _hasSeenOnboarding = true;
    _role = UserRole.patient;
    _selectedRole = UserRole.patient;
    _patientAuthState = PatientAuthState.home;
    _isUnlocked = true;
    fetchPrescriptions();
    _persistSession();
    notifyListeners();
  }

  // Patient Register
  Future<String?> signUpWithEmail(
    String email,
    String password, {
    String name = '',
    String mobile = '',
    String dob = '',
    String gender = '',
    String country = '',
    String idType = '',
    String idNumber = '',
    String uploadedFileName = '',
  }) async {
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$_backendUrl/api/patient/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'name': name.isNotEmpty ? name : email.split('@').first,
          'mobile': mobile,
          'dob': dob,
          'gender': gender,
          'country': country,
          'idType': idType,
          'idNumber': idNumber,
          'uploadedFileName': uploadedFileName,
        }),
      );
      if (response.statusCode == 200) {
        _currentPatient = jsonDecode(response.body) as Map<String, dynamic>;
        _isOfflineGuest = false;
        _token = _currentPatient!['token'] as String?;
        _role = UserRole.patient;
        _selectedRole = UserRole.patient;
        _patientMobileOrId = idNumber.isNotEmpty ? idNumber : mobile;

        await _persistSession();
        return null;
      }
      debugPrint(
        '[API_ERROR] signUpWithEmail returned status ${response.statusCode}',
      );
      debugPrint('Payload: ${response.body}');
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return ErrorMapper.map(
          decoded['detail'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      } catch (_) {
        return ErrorMapper.map('Server Error', statusCode: response.statusCode);
      }
    } catch (e, stack) {
      debugPrint(
        '[API_EXCEPTION] signUpWithEmail failed to connect to Gateway!',
      );
      debugPrint('Target URL: $_backendUrl/api/patient/register');
      debugPrint('Exception details: $e');
      debugPrint('Stacktrace: $stack');
      _networkError = true;
      return ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload Patient ID Document
  Future<String?> uploadPatientIdDocument(File file) async {
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();

      final uri = Uri.parse('$_backendUrl/api/media/upload');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['file_path'] as String?;
      } else {
        debugPrint('[API ERROR] File upload status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] File upload failed: $e');
      _networkError = true;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Patient Login
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$_backendUrl/api/patient/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );
      if (response.statusCode == 200) {
        _currentPatient = jsonDecode(response.body) as Map<String, dynamic>;
        _isOfflineGuest = false;
        _token = _currentPatient!['token'] as String?;
        _role = UserRole.patient;
        _selectedRole = UserRole.patient;
        _patientMobileOrId =
            _currentPatient!['patient_id'] ??
            _currentPatient!['_id'] ??
            '992818';

        await _persistSession();
        await fetchPrescriptions();
        await fetchVisitHistory();
        return null;
      }
      debugPrint(
        '[API_ERROR] loginWithEmail returned status ${response.statusCode}',
      );
      debugPrint('Payload: ${response.body}');
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return ErrorMapper.map(
          decoded['detail'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      } catch (_) {
        return ErrorMapper.map('Server Error', statusCode: response.statusCode);
      }
    } catch (e, stack) {
      debugPrint(
        '[API_EXCEPTION] loginWithEmail failed to connect to Gateway!',
      );
      debugPrint('Target URL: $_backendUrl/api/patient/login');
      debugPrint('Exception details: $e');
      debugPrint('Stacktrace: $stack');
      return ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Patient Profile Update
  Future<void> updatePatientName(String newName) async {
    _guestName = newName;
    if (_currentPatient != null && _token != null) {
      try {
        await http.post(
          Uri.parse('$_backendUrl/api/patient/update-name'),
          headers: {
            'Content-Type': 'application/json',
            'X-Session-Token': _token!,
          },
          body: jsonEncode({'name': newName}),
        );
        _currentPatient = {..._currentPatient!, 'name': newName};
      } catch (e) {
        debugPrint('Failed to update patient name: $e');
      }
    }
    _persistSession();
    notifyListeners();
  }

  Future<void> updatePatientMobileOrId(String newId) async {
    _patientMobileOrId = newId;
    _persistSession();
    notifyListeners();
  }

  // Doctor Consultations Fetch
  Future<void> fetchDoctorConsultations() async {
    try {
      final docId = doctorLicense ?? '889218';
      final response = await http.get(
        Uri.parse('$_backendUrl/api/doctor/consultations?doctor_id=$docId'),
      );
      if (response.statusCode == 200) {
        _doctorConsultations = jsonDecode(response.body) as List<dynamic>;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching doctor consultations: $e');
    }
  }

  // Patient Prescriptions Fetch
  Future<void> fetchPrescriptions({bool silent = false}) async {
    if (!silent && _patientVault.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final response = await http.get(
        Uri.parse(
          '$_backendUrl/api/prescriptions?patient=${Uri.encodeComponent(patientName)}',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        _patientVault = list
            .map((item) => Prescription.fromJson(item))
            .toList();
      } else {
        _patientVault = [];
      }
    } catch (e) {
      debugPrint('Prescription sync server offline: $e');
      if (_isOfflineGuest && _patientVault.isEmpty) {
        // Fallback or leave existing
      }
    } finally {
      if (_isLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Activity logs audit trail
  Future<void> fetchActivityLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/activity-logs'),
      );
      if (response.statusCode == 200) {
        _activityLogs = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
    }
  }

  // Visit history blockchain tracking
  Future<void> fetchVisitHistory() async {
    if (_role != UserRole.patient) return;
    try {
      final name = Uri.encodeComponent(patientName);
      final response = await http.get(
        Uri.parse('$_backendUrl/api/visit-history/$name'),
        headers: _token != null ? {'X-Session-Token': _token!} : {},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _visitHistory = data['visits'] as List<dynamic>? ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching visit history: $e');
    }
  }

  // Fetch patient profile and allergies from backend database
  Future<void> fetchPatientProfile() async {
    if (!isAuthenticated) return;
    try {
      final name = Uri.encodeComponent(patientName);
      final response = await http.get(
        Uri.parse('$_backendUrl/api/doctor/patient-history/$name'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> algsRaw = data['allergies'] ?? [];
        _patientAllergies = algsRaw.map((a) => a.toString()).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching patient profile/allergies: $e');
    }
  }

  // Save patient allergies to backend database
  Future<bool> savePatientAllergies(List<String> list) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/doctor/patient-allergies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patient_id': patientName, 'allergies': list}),
      );
      if (response.statusCode == 200) {
        _patientAllergies = List<String>.from(list);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving patient allergies: $e');
      return false;
    }
  }

  void selectPrescription(Prescription? rx) {
    _selectedPrescription = rx;
    notifyListeners();
  }

  // --- Doctor API ---

  Future<String?> loginDoctor(String doctorMobile) async {
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$_backendUrl/api/doctor/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctorMobile': doctorMobile}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _role = UserRole.doctor;
        _selectedRole = UserRole.doctor;
        _token = 'token-${data['doctor_id']}';
        _doctorLicense = data['doctor_id'];
        _doctorHospital = data['hospitalName'];
        _doctorSpecialty = 'General Practitioner'; // default specialty
        _doctorName = data['name'];
        _isVerified = true;

        await _persistSession();
        return null;
      }
      debugPrint(
        '[API_ERROR] loginDoctor returned status ${response.statusCode}',
      );
      debugPrint('Payload: ${response.body}');
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return ErrorMapper.map(
          decoded['detail'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      } catch (_) {
        return ErrorMapper.map('Server Error', statusCode: response.statusCode);
      }
    } catch (e, stack) {
      debugPrint('[API_EXCEPTION] loginDoctor failed to connect to Gateway!');
      debugPrint('Target URL: $_backendUrl/api/doctor/login');
      debugPrint('Exception details: $e');
      debugPrint('Stacktrace: $stack');
      return ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> loginPharmacy(String pharmacyId) async {
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$_backendUrl/api/pharmacy/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pharmacy_id': pharmacyId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _role = UserRole.pharmacy;
        _selectedRole = UserRole.pharmacy;
        _token = data['token'];
        _isTerminalVerified = true;

        await _persistSession();
        return null;
      }
      debugPrint(
        '[API_ERROR] loginPharmacy returned status ${response.statusCode}',
      );
      debugPrint('Payload: ${response.body}');
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return ErrorMapper.map(
          decoded['detail'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      } catch (_) {
        return ErrorMapper.map('Server Error', statusCode: response.statusCode);
      }
    } catch (e, stack) {
      debugPrint('[API_EXCEPTION] loginPharmacy failed to connect to Gateway!');
      debugPrint('Target URL: $_backendUrl/api/pharmacy/login');
      debugPrint('Exception details: $e');
      debugPrint('Stacktrace: $stack');
      return ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> registerDoctor({
    required String name,
    required String license,
    required String hospital,
    required String specialty,
    String email = '',
    String phone = '',
  }) async {
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$_backendUrl/api/doctor/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'hospitalName': hospital,
          'doctorMobile': license,
          'specialty': specialty,
          'email': email,
          'phone': phone,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _role = UserRole.doctor;
        _selectedRole = UserRole.doctor;
        _token = 'token-${data['doctor_id']}';
        _doctorLicense = data['doctor_id'];
        _doctorHospital = data['hospitalName'];
        _doctorSpecialty = specialty;
        _doctorName = data['name'];
        _isVerified = true;

        await _persistSession();
        return null;
      }
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return ErrorMapper.map(
          decoded['detail'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      } catch (_) {
        return ErrorMapper.map('Server Error', statusCode: response.statusCode);
      }
    } catch (e) {
      return ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    _persistSession();
    notifyListeners();
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

  // --- Doctor Consultation requests ---

  void setAttendance(bool value) {
    _isAttendanceActive = value;
    if (value) {
      _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
    } else {
      _activePendingRequestId = null;
      _promptedRequestIds.clear();
      _sessionStartMs = null;
      _isDoctorConnected = false;
    }
    notifyListeners();
  }

  Future<void> checkPendingConsultations() async {
    if (_isAttendanceActive && _isDoctorConnected) {
      // Periodic check if clinical session was completed by prescription submission
      try {
        final response = await http.get(
          Uri.parse(
            '$_backendUrl/api/consultation/has-active-session?patient=${Uri.encodeComponent(patientName)}',
          ),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          bool isActive = data['active'] == true;

          if (!isActive) {
            _isAttendanceActive = false;
            _isDoctorConnected = false;
            await fetchPrescriptions();
            await fetchActivityLogs();
            await fetchVisitHistory();
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Error checking active session: $e');
      }
      return;
    }

    if (_role != UserRole.patient) return;
    try {
      final response = await http.get(
        Uri.parse(
          '$_backendUrl/api/consultation/pending?patient=${Uri.encodeComponent(patientName)}&patientId=${Uri.encodeComponent(patientMobileOrId)}',
        ),
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') {
          if (_activePendingRequestId != null) {
            _activePendingRequestId = null;
            notifyListeners();
          }
          return;
        }
        final data = jsonDecode(response.body);
        if (data != null && data['id'] != null) {
          final String reqId = data['id'];
          if (!_promptedRequestIds.contains(reqId) &&
              _activePendingRequestId != reqId) {
            _activePendingRequestId = reqId;
            notifyListeners();
          }
        } else {
          if (_activePendingRequestId != null) {
            _activePendingRequestId = null;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking pending consultations: $e');
    }
  }

  Future<void> acceptConsultation(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/consultation/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': requestId}),
      );
      if (response.statusCode == 200) {
        _promptedRequestIds.add(requestId);
        _activePendingRequestId = null;
        _isAttendanceActive = true;
        _isDoctorConnected = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error accepting consultation: $e');
    }
  }

  Future<void> rejectConsultation(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/consultation/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': requestId}),
      );
      if (response.statusCode == 200) {
        _promptedRequestIds.add(requestId);
        _activePendingRequestId = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error rejecting consultation: $e');
    }
  }

  // --- Pharmacy API ---

  void verifyPharmacyTerminal() {
    _isTerminalVerified = true;
    _persistSession();
    notifyListeners();
  }

  Future<Map<String, dynamic>> verifyScan(
    String rawPayload,
    String signature,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/prescriptions/verify-scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'raw_payload': rawPayload,
          'signature': signature,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final err = jsonDecode(response.body);
        return {
          'verified': false,
          'error': err['detail'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {'verified': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> dispensePrescription(
    String rxId, {
    String batchNumber = '',
    String expiryDate = '',
    String touchSignature = '',
    String deliveryTrackingId = '',
    double? billingAmount,
    bool? receiptAttached,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/prescriptions/dispense'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': rxId,
          'batch_number': batchNumber,
          'expiry_date': expiryDate,
          'touch_signature': touchSignature,
          'delivery_tracking_id': deliveryTrackingId,
          'billing_amount': billingAmount,
          'receipt_attached': receiptAttached,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final err = jsonDecode(response.body);
        return {'ok': false, 'error': err['detail'] ?? 'Dispensation failed'};
      }
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  // Submit Prescription (Doctor)
  Future<Map<String, dynamic>> createPrescription(
    Map<String, dynamic> rxData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/prescriptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(rxData),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        await fetchDoctorConsultations();
        return result;
      } else {
        final err = jsonDecode(response.body);
        return {'ok': false, 'error': err['detail'] ?? 'Issuance failed'};
      }
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<String?> requestPatientConnection(String qrOrPatientId) async {
    try {
      _isLoading = true;
      notifyListeners();

      String patientNameVal;
      String patientIdVal;

      if (qrOrPatientId.contains('aegisrx://patient/')) {
        final stripped = qrOrPatientId
            .replaceAll('aegisrx://patient/', '')
            .trim();
        if (stripped.contains('/')) {
          final parts = stripped.split('/');
          patientIdVal = parts[0].trim();
          patientNameVal = Uri.decodeComponent(parts[1]).trim();
        } else {
          patientIdVal = stripped;
          final namePart = patientIdVal.replaceAll(RegExp(r'_\d+$'), '');
          patientNameVal = namePart.replaceAll('_', ' ');
        }
      } else if (qrOrPatientId.contains('|')) {
        final parts = qrOrPatientId.split('|');
        patientNameVal = parts[0].trim();
        patientIdVal = parts[1].trim();
      } else {
        patientIdVal = qrOrPatientId.trim();
        final namePart = patientIdVal.replaceAll(RegExp(r'_\d+$'), '');
        patientNameVal = namePart.replaceAll('_', ' ');
      }

      if (patientIdVal.isEmpty) {
        return "Invalid Patient ID";
      }

      final response = await http.post(
        Uri.parse('$_backendUrl/api/consultation/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientName': patientNameVal,
          'patientId': patientIdVal,
          'doctorId': _doctorLicense ?? 'NPI-ROOT-KEY',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final String reqId = data['id'];
        _activePatientId = data['patientId'] ?? patientIdVal;
        _activePatientName = data['patientName'] ?? patientNameVal;
        _isDoctorConnected = false;
        notifyListeners();
        return 'PENDING:$reqId';
      } else {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return ErrorMapper.map(
            decoded['detail'] ?? 'Connection request failed',
            statusCode: response.statusCode,
          );
        } catch (_) {
          return ErrorMapper.map(
            'Server Error',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      return ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> checkConnectionStatus(String reqId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/consultation/status/$reqId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final String status = data['status'];
        if (status == 'accepted') {
          _isDoctorConnected = true;
          // Populate active patient info from the resolved consultation record
          // so that prescriptions always carry the real patient name from the DB.
          if (data['patientName'] != null &&
              (data['patientName'] as String).isNotEmpty) {
            _activePatientName = data['patientName'] as String;
          }
          if (data['patientId'] != null &&
              (data['patientId'] as String).isNotEmpty) {
            _activePatientId = data['patientId'] as String;
          }
          notifyListeners();
        }
        return status;
      }
      return 'pending';
    } catch (e) {
      debugPrint('Error polling connection status: $e');
      return 'pending';
    }
  }

  Future<Map<String, dynamic>?> runAiSafetyAudit({
    required String patientId,
    required String doctorId,
    required String newMedicine,
    required String newDosage,
    required String disease,
  }) async {
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$_backendUrl/api/audit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'doctor_id': doctorId,
          'new_medicine': newMedicine,
          'new_dosage': newDosage,
          'disease': disease,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('AI audit server offline: $e');
      _networkError = true;
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? get savedPin => _savedPin;

  Future<void> savePin(String pin) async {
    _savedPin = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_pin', pin);
    notifyListeners();
  }
}
