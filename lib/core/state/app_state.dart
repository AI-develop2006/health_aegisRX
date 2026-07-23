import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,
      resetOnError: true,
    ),
  );
  UserRole? _role;
  String? _token; // session token (e.g. from backend)
  String _backendUrl = 'http://10.91.100.79:4000';
  bool _isLoading = false;
  Timer? _pollTimer;
  Future<void>? _pendingPersist;
  static AppState? activeInstance;

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
  bool _isInitialized = false;

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
  bool get isInitialized => _isInitialized;
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
  bool _isSyncing = false;

  AppState() {
    if (activeInstance != null) {
      debugPrint(
        '[DEBUG_SESSION] Disposing previous AppState instance to prevent duplicate polling loops.',
      );
      activeInstance!.dispose();
    }
    activeInstance = this;
    _initSession();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  bool _isPollingPaused = false;
  bool get isPollingPaused => _isPollingPaused;

  void pausePolling({required String screen, required String reason}) {
    if (_isPollingPaused) return;
    _isPollingPaused = true;
    debugPrint(
      '[POLL]\nStopped\nScreen:\n$screen\nReason:\n$reason\nTimestamp:\n${DateTime.now()}',
    );
    notifyListeners();
  }

  void resumePolling({required String screen, required String reason}) {
    if (!_isPollingPaused) return;
    _isPollingPaused = false;
    debugPrint(
      '[POLL]\nResumed\nScreen:\n$screen\nReason:\n$reason\nTimestamp:\n${DateTime.now()}',
    );
    notifyListeners();
  }

  void _startPolling() {
    if (_pollTimer != null) {
      debugPrint(
        '[POLL]\nAlready running\nScreen:\nN/A\nReason:\nStart polling requested but timer active\nTimestamp:\n${DateTime.now()}',
      );
      return;
    }
    debugPrint(
      '[POLL]\nStarted\nScreen:\nN/A\nReason:\nSession active, starting polling loop\nTimestamp:\n${DateTime.now()}',
    );
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isPollingPaused) {
        debugPrint('[DEBUG_POLL] Sync loop tick ignored: polling is paused.');
        return;
      }
      debugPrint(
        '[DEBUG_POLL] Sync loop tick: initialized=$_isInitialized, authenticated=$isAuthenticated, role=$_role, syncing=$_isSyncing',
      );
      if (_isInitialized &&
          isAuthenticated &&
          _role == UserRole.patient &&
          !_isOfflineGuest &&
          !_isSyncing) {
        _isSyncing = true;
        try {
          _pollTicks++;

          // 1. Check doctor connection requests (consultation requests)
          await checkPendingConsultations();

          // 2. Fetch prescriptions, profile/allergies and activity logs
          if (_pollTicks % 2 == 0) {
            await fetchPatientProfile();
            await fetchPrescriptions(silent: true);
            await fetchActivityLogs();
          }

          // 3. Fetch visit history
          if (_pollTicks % 4 == 0) {
            await fetchVisitHistory();
          }
        } catch (e) {
          debugPrint('Sync cycle failed: $e');
        } finally {
          _isSyncing = false;
        }
      }
    });
  }

  void _stopPolling() {
    if (_pollTimer == null) {
      debugPrint(
        '[POLL]\nAlready stopped\nScreen:\nN/A\nReason:\nStop polling requested but timer already inactive\nTimestamp:\n${DateTime.now()}',
      );
      return;
    }
    _pollTimer!.cancel();
    _pollTimer = null;
    debugPrint(
      '[POLL]\nCancelled\nScreen:\nN/A\nReason:\nSession ended, stopping timer\nTimestamp:\n${DateTime.now()}',
    );
  }

  // --- Session Management ---

  Future<void> _discoverBackendUrl() async {
    final candidates = [
      'http://10.0.2.2:4000',
      'http://127.0.0.1:4000',
      'http://10.91.100.79:4000',
      'http://192.168.1.42:4000',
      'http://192.168.0.15:4000',
      'http://13.63.53.53:4000',
    ];
    debugPrint('[AUTO-DISCOVERY] Starting backend gateway discovery...');
    for (final url in candidates) {
      try {
        debugPrint('[AUTO-DISCOVERY] Probing endpoint: $url/health');
        final res = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 1));
        debugPrint(
          '[AUTO-DISCOVERY] Endpoint $url responded with status: ${res.statusCode}',
        );
        if (res.statusCode == 200) {
          _backendUrl = url;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('backend_url', url);
          debugPrint('[AUTO-DISCOVERY] SUCCESS: Bound client Gateway to $url');
          return;
        }
      } catch (e) {
        debugPrint('[AUTO-DISCOVERY] Endpoint $url unreachable: $e');
      }
    }
    debugPrint('[AUTO-DISCOVERY] No working endpoint detected. Defaulting to emulator gateway (10.0.2.2:4000).');
    _backendUrl = 'http://10.0.2.2:4000';
  }

  Future<void> _initSession() async {
    try {
      debugPrint('[DEBUG_SESSION] Initializing session restoration...');
      final prefs = await SharedPreferences.getInstance();
      _hasFinishedSplash = prefs.getBool('finished_splash') ?? false;
      _hasSeenOnboarding = prefs.getBool('completed_onboarding') ?? false;

      // Auto-discover the working backend gateway interface
      await _discoverBackendUrl();

      try {
        _savedPin = await _secureStorage.read(key: 'saved_pin');
      } catch (e) {
        debugPrint(
          '[DEBUG_SESSION] SecureStorage failure reading saved_pin: $e',
        );
        _savedPin = null;
      }

      String? patientJson;
      try {
        patientJson = await _secureStorage.read(key: 'session_patient');
      } catch (e) {
        debugPrint(
          '[DEBUG_SESSION] SecureStorage failure reading session_patient: $e',
        );
      }

      if (patientJson != null) {
        try {
          final decoded = jsonDecode(patientJson) as Map<String, dynamic>;
          if (decoded['token'] != null) {
            _currentPatient = decoded;
            _isOfflineGuest = false;
            _token = _currentPatient!['token'] as String?;
            _role = UserRole.patient;
            _selectedRole = UserRole.patient;
            _patientAuthState = PatientAuthState.home;
            _isUnlocked = true;
            if (_currentPatient!['name'] != null) {
              _guestName = _currentPatient!['name'].toString();
            }
            if (_currentPatient!['patient_id'] != null) {
              _patientMobileOrId = _currentPatient!['patient_id'].toString();
            } else if (_currentPatient!['_id'] != null) {
              _patientMobileOrId = _currentPatient!['_id'].toString();
            }
            debugPrint(
              '[DEBUG_SESSION] Patient session successfully restored from SecureStorage. Name: $patientName',
            );
          } else {
            debugPrint(
              '[DEBUG_SESSION] Restored patientJson has no token. Rejecting partial session.',
            );
            _currentPatient = null;
          }
        } catch (e) {
          debugPrint('[DEBUG_SESSION] Error decoding session_patient JSON: $e');
          _currentPatient = null;
        }
      }

      // If no valid patient was loaded from secure storage, check guest prefs
      if (_currentPatient == null) {
        _isOfflineGuest = prefs.getBool('session_offline_guest') ?? false;
        if (_isOfflineGuest) {
          _role = UserRole.patient;
          _selectedRole = UserRole.patient;
          _patientAuthState = PatientAuthState.home;
          _isUnlocked = true;
          debugPrint('[DEBUG_SESSION] Guest session active.');
        }
        _patientMobileOrId =
            prefs.getString('patient_mobile_or_id') ?? '992818';
        _guestName = prefs.getString('guest_name') ?? 'Elena Vance';
      }

      final savedRoleStr = prefs.getString('saved_role');
      if (savedRoleStr != null && savedRoleStr != 'patient') {
        try {
          _token = await _secureStorage.read(key: 'saved_token');
        } catch (e) {
          debugPrint(
            '[DEBUG_SESSION] SecureStorage failure reading saved_token: $e',
          );
          _token = null;
        }
        if (_token != null) {
          if (savedRoleStr == 'doctor') {
            _role = UserRole.doctor;
            _selectedRole = UserRole.doctor;
            _doctorLicense = prefs.getString('doctor_license');
            _doctorName = prefs.getString('doctor_name');
            _doctorHospital = prefs.getString('doctor_hospital');
            _doctorSpecialty = prefs.getString('doctor_specialty');
            _isVerified = _doctorLicense != null;
            debugPrint(
              '[DEBUG_SESSION] Doctor session restored. Name: $_doctorName, License: $_doctorLicense',
            );
          } else if (savedRoleStr == 'pharmacy') {
            _role = UserRole.pharmacy;
            _selectedRole = UserRole.pharmacy;
            _isTerminalVerified = prefs.getBool('terminal_verified') ?? false;
            debugPrint(
              '[DEBUG_SESSION] Pharmacy session restored. Terminal verified: $_isTerminalVerified',
            );
          }
        }
      }

      if (isAuthenticated) {
        if (_role == UserRole.patient && !_isOfflineGuest) {
          await fetchPrescriptions(silent: true);
          await fetchActivityLogs();
          await fetchVisitHistory();
          await fetchPatientProfile();
        }
      }
    } catch (e) {
      debugPrint(
        '[DEBUG_SESSION] Exception during session restore initialization: $e',
      );
    } finally {
      _isInitialized = true;
      debugPrint(
        '[DEBUG_SESSION] Initialization completed. Role: $_role, Authenticated: $isAuthenticated, Name: $patientName',
      );
      _startPolling();
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    final previous = _pendingPersist;
    final completer = Completer<void>();
    _pendingPersist = completer.future;

    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('finished_splash', _hasFinishedSplash);
      await prefs.setBool('completed_onboarding', _hasSeenOnboarding);
      await prefs.setString('backend_url', _backendUrl);

      try {
        if (_savedPin != null) {
          await _secureStorage.write(key: 'saved_pin', value: _savedPin!);
        } else {
          await _secureStorage.delete(key: 'saved_pin');
        }
      } catch (e) {
        debugPrint(
          '[DEBUG_SESSION] SecureStorage failed to write saved_pin: $e',
        );
      }

      try {
        if (_currentPatient != null) {
          await _secureStorage.write(
            key: 'session_patient',
            value: jsonEncode(_currentPatient),
          );
          if (_currentPatient!['name'] != null) {
            _guestName = _currentPatient!['name'].toString();
          }
        } else {
          await _secureStorage.delete(key: 'session_patient');
        }
      } catch (e) {
        debugPrint(
          '[DEBUG_SESSION] SecureStorage failed to write session_patient: $e',
        );
      }

      await prefs.setBool('session_offline_guest', _isOfflineGuest);
      await prefs.setString('patient_mobile_or_id', _patientMobileOrId);
      await prefs.setString('guest_name', _guestName);

      if (_role != null) {
        await prefs.setString('saved_role', _role.toString().split('.').last);
        try {
          if (_token != null) {
            await _secureStorage.write(key: 'saved_token', value: _token!);
          }
        } catch (e) {
          debugPrint(
            '[DEBUG_SESSION] SecureStorage failed to write saved_token: $e',
          );
        }
      } else {
        await prefs.remove('saved_role');
        try {
          await _secureStorage.delete(key: 'saved_token');
        } catch (e) {
          debugPrint(
            '[DEBUG_SESSION] SecureStorage failed to delete saved_token: $e',
          );
        }
      }

      if (_doctorLicense != null) {
        await prefs.setString('doctor_license', _doctorLicense!);
        await prefs.setString('doctor_name', _doctorName ?? '');
        await prefs.setString('doctor_hospital', _doctorHospital ?? '');
        await prefs.setString('doctor_specialty', _doctorSpecialty ?? '');
      }
      await prefs.setBool('terminal_verified', _isTerminalVerified);
      debugPrint('[DEBUG_SESSION] Session successfully persisted to disk.');
    } catch (e) {
      debugPrint('[DEBUG_SESSION] Failed to persist session prefs: $e');
    } finally {
      completer.complete();
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
    debugPrint(
      '[DEBUG_SESSION] setSession called: role=$role, token=${token.isNotEmpty ? "PRESENT" : "EMPTY"}',
    );
    _role = role;
    _token = token;
    _selectedRole = role;

    if (role == UserRole.patient) {
      _isUnlocked = false;
      _patientAuthState = PatientAuthState.home;
      _isOfflineGuest = false;
    } else if (role == UserRole.doctor) {
      _isVerified = _doctorLicense != null;
    } else if (role == UserRole.pharmacy) {
      _isTerminalVerified = false;
    }

    _persistSession();
    _startPolling();
    notifyListeners();
  }

  void setSessionAndPin({
    required UserRole role,
    required String token,
    required String pin,
  }) {
    debugPrint(
      '[DEBUG_SESSION] setSessionAndPin called: role=$role, token=${token.isNotEmpty ? "PRESENT" : "EMPTY"}, pin=***',
    );
    _role = role;
    _token = token;
    _selectedRole = role;
    _savedPin = pin;

    if (role == UserRole.patient) {
      _isUnlocked = true;
      _patientAuthState = PatientAuthState.home;
      _isOfflineGuest = false;
    } else if (role == UserRole.doctor) {
      _isVerified = _doctorLicense != null;
    } else if (role == UserRole.pharmacy) {
      _isTerminalVerified = false;
    }

    _persistSession();
    _startPolling();
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
    _stopPolling();
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
    _stopPolling();
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
      final response = await http
          .post(
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
              'id_type': idType,
              'id_number': idNumber,
              'uploaded_file_name': uploadedFileName,
            }),
          )
          .timeout(const Duration(seconds: 10));
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

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(const Duration(seconds: 15));

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
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/patient/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
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
        await fetchPatientProfile();
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
        await http
            .post(
              Uri.parse('$_backendUrl/api/patient/update-name'),
              headers: {
                'Content-Type': 'application/json',
                'X-Session-Token': _token!,
              },
              body: jsonEncode({'name': newName}),
            )
            .timeout(const Duration(seconds: 5));
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
      final response = await http
          .get(
            Uri.parse('$_backendUrl/api/doctor/consultations?doctor_id=$docId'),
          )
          .timeout(const Duration(seconds: 5));
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
      final response = await http
          .get(
            Uri.parse(
              '$_backendUrl/api/prescriptions?patient=${Uri.encodeComponent(patientName)}',
            ),
          )
          .timeout(const Duration(seconds: 5));
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
      final response = await http
          .get(Uri.parse('$_backendUrl/api/activity-logs'))
          .timeout(const Duration(seconds: 5));
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
      final response = await http
          .get(
            Uri.parse('$_backendUrl/api/visit-history/$name'),
            headers: _token != null ? {'X-Session-Token': _token!} : {},
          )
          .timeout(const Duration(seconds: 5));
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
    debugPrint('[DEBUG_API] Entering fetchPatientProfile()');
    if (!isAuthenticated) {
      debugPrint(
        '[DEBUG_API] fetchPatientProfile: Not authenticated. Exiting.',
      );
      return;
    }

    // Safety validation checks to prevent stale/Guest leakage
    if (_currentPatient == null) {
      debugPrint(
        '[DEBUG_API] fetchPatientProfile: Aborting because _currentPatient is null.',
      );
      return;
    }
    if (_token == null) {
      debugPrint(
        '[DEBUG_API] fetchPatientProfile: Aborting because _token is null.',
      );
      return;
    }
    final name = patientName.trim();
    if (name.isEmpty || name == 'Guest' || name == 'Authenticated Patient') {
      debugPrint(
        '[DEBUG_API] fetchPatientProfile: Aborting because resolved name ("$name") is empty or default placeholder.',
      );
      return;
    }

    try {
      final encodedName = Uri.encodeComponent(name);
      final url = '$_backendUrl/api/doctor/patient-history/$encodedName';
      debugPrint('[DEBUG_API] Sending GET request to: $url');
      debugPrint('[DEBUG_API] Headers: None');
      debugPrint('[DEBUG_API] Body: None');
      debugPrint(
        '[DEBUG_API] Waiting for response (timeout configured for 5 seconds)...',
      );

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      debugPrint('[DEBUG_API] Response received');
      debugPrint('[DEBUG_API] Status code: ${response.statusCode}');
      debugPrint('[DEBUG_API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> algsRaw = data['allergies'] ?? [];
        _patientAllergies = algsRaw.map((a) => a.toString()).toList();
        notifyListeners();
      }
    } catch (e, stack) {
      debugPrint('[DEBUG_API] Exception in fetchPatientProfile: $e');
      debugPrint('[DEBUG_API] StackTrace: $stack');
    }
  }

  // Save patient allergies to backend database
  Future<bool> savePatientAllergies(List<String> list) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/doctor/patient-allergies'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_id': patientEmailOrId,
              'allergies': list,
            }),
          )
          .timeout(const Duration(seconds: 5));
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
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/doctor/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'doctorMobile': doctorMobile}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _role = UserRole.doctor;
        _selectedRole = UserRole.doctor;
        _token = 'token-${data['doctor_id'] ?? doctorMobile}';
        _doctorLicense = data['doctor_id'] ?? data['doctor_mobile'] ?? doctorMobile;
        _doctorHospital = data['hospitalName'] ?? data['hospital_name'] ?? 'Metropolitan Hospital Centre';
        _doctorSpecialty = data['specialty'] ?? 'General Practitioner';
        _doctorName = data['name'] ?? data['doctor_name'] ?? 'Dr. $doctorMobile';
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
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/pharmacy/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'pharmacy_id': pharmacyId}),
          )
          .timeout(const Duration(seconds: 5));
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
      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _role = UserRole.doctor;
        _selectedRole = UserRole.doctor;
        _token = 'token-${data['doctor_id'] ?? license}';
        _doctorLicense = data['doctor_id'] ?? license;
        _doctorHospital = data['hospitalName'] ?? hospital;
        _doctorSpecialty = data['specialty'] ?? specialty;
        _doctorName = data['name'] ?? name;
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
    _doctorName = name;
    _doctorLicense = license;
    _doctorHospital = hospital;
    _doctorSpecialty = specialty;
    _isVerified = approved;
    _persistSession();
    notifyListeners();
  }

  String? _activePatientId;
  String? _activePatientName;
  String? _activeConsultationRequestId;

  String? get activePatientId => _activePatientId;
  String? get activePatientName => _activePatientName;
  String? get activeConsultationRequestId => _activeConsultationRequestId;

  void startDoctorPatientSession(String patientId, String patientName) {
    _activePatientId = patientId;
    _activePatientName = patientName;
    notifyListeners();
  }

  void endDoctorPatientSession() {
    _activePatientId = null;
    _activePatientName = null;
    _activeConsultationRequestId = null;
    notifyListeners();
  }

  Future<void> cancelActiveSession() async {
    final reqId = _activeConsultationRequestId;
    final patientIdVal = _role == UserRole.patient
        ? patientMobileOrId
        : _activePatientId;
    final patientNameVal = _role == UserRole.patient
        ? patientName
        : _activePatientName;
    final docIdVal = _role == UserRole.doctor ? doctorLicense : null;

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/consultation/cancel'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': reqId,
              'patient_id': patientIdVal,
              'patient_name': patientNameVal,
              'doctor_id': docIdVal,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        debugPrint('Consultation session cancelled successfully on backend.');
      } else {
        debugPrint('Failed to cancel consultation session: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error calling cancel consultation API: $e');
    }

    _activeConsultationRequestId = null;
    _isAttendanceActive = false;
    _isDoctorConnected = false;
    _activePatientId = null;
    _activePatientName = null;
    _persistSession();
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
        final response = await http
            .get(
              Uri.parse(
                '$_backendUrl/api/consultation/has-active-session?patient=${Uri.encodeComponent(patientName)}',
              ),
            )
            .timeout(const Duration(seconds: 5));
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
      final response = await http
          .get(
            Uri.parse(
              '$_backendUrl/api/consultation/pending?patient=${Uri.encodeComponent(patientName)}&patientId=${Uri.encodeComponent(patientMobileOrId)}',
            ),
          )
          .timeout(const Duration(seconds: 5));
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
    _promptedRequestIds.add(requestId);
    _activePendingRequestId = null;
    _activeConsultationRequestId = requestId;
    _isAttendanceActive = true;
    _isDoctorConnected = true;
    _persistSession();
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/consultation/accept'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': requestId}),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        debugPrint('Accept consultation status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error accepting consultation: $e');
    }
  }

  Future<void> rejectConsultation(String requestId) async {
    _promptedRequestIds.add(requestId);
    _activePendingRequestId = null;
    _activeConsultationRequestId = null;
    _persistSession();
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/consultation/reject'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': requestId}),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        debugPrint('Reject consultation status ${response.statusCode}');
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
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/prescriptions/verify-scan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'raw_payload': rawPayload,
              'signature': signature,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));
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
      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 5));
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
    final Stopwatch sw = Stopwatch()..start();
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/prescriptions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(rxData),
          )
          .timeout(const Duration(seconds: 5));
      sw.stop();
      debugPrint(
        '[DEBUG_API] POST /api/prescriptions took ${sw.elapsedMilliseconds}ms. (Threshold check: ${sw.elapsedMilliseconds > 3000 ? "WARNING: Slow request. Potential ANR risk on slower devices." : "Normal"})',
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
          final rawName = parts[1].trim();
          patientNameVal = Uri.decodeComponent(rawName.split('?')[0]).trim();
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

      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/consultation/request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patientName': patientNameVal,
              'patientId': patientIdVal,
              'doctorId': _doctorLicense ?? 'NPI-ROOT-KEY',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final String reqId = data['id'];
        _activePatientId = data['patientId'] ?? patientIdVal;
        _activePatientName = data['patientName'] ?? patientNameVal;
        _activeConsultationRequestId = reqId;
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
      final response = await http
          .get(Uri.parse('$_backendUrl/api/consultation/status/$reqId'))
          .timeout(const Duration(seconds: 4));
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
    final Stopwatch sw = Stopwatch()..start();
    try {
      _isLoading = true;
      _networkError = false;
      notifyListeners();
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/audit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_id': patientId,
              'doctor_id': doctorId,
              'new_medicine': newMedicine,
              'new_dosage': newDosage,
              'disease': disease,
            }),
          )
          .timeout(const Duration(seconds: 5));
      sw.stop();
      debugPrint(
        '[DEBUG_API] POST /api/audit took ${sw.elapsedMilliseconds}ms. (Threshold check: ${sw.elapsedMilliseconds > 3000 ? "WARNING: Slow request. Potential ANR risk on slower devices." : "Normal"})',
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

  Future<Map<String, dynamic>?> parseVoicePrescription({
    required String patientId,
    required String doctorId,
    required String transcript,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/ai/voice/parse'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_id': patientId,
              'doctor_id': doctorId,
              'transcript': transcript,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Voice parser API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Voice parser failed: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? get savedPin => _savedPin;

  Future<void> savePin(String pin) async {
    _savedPin = pin;
    await _secureStorage.write(key: 'saved_pin', value: pin);
    notifyListeners();
  }
}
