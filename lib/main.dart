import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:health_lock/core/constants/app_colors.dart';
import 'package:health_lock/core/theme/app_theme.dart';
import 'package:health_lock/shared/models/prescription.dart';
import 'package:health_lock/features/patient/screens/patient_vault.dart';
import 'package:health_lock/features/patient/screens/patient_login.dart';
import 'package:health_lock/core/constants/mock_prescriptions.dart';
import 'package:health_lock/features/patient/screens/onboarding_screen.dart';
import 'package:health_lock/features/patient/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SimulationState(),
      child: const SovereignShieldApp(),
    ),
  );
}

class SovereignShieldApp extends StatefulWidget {
  const SovereignShieldApp({super.key});

  @override
  State<SovereignShieldApp> createState() => _SovereignShieldAppState();
}

class _SovereignShieldAppState extends State<SovereignShieldApp> {
  bool _showSplash = true;
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SimulationState>(context);

    Widget homeWidget;
    if (_showSplash) {
      homeWidget = SplashScreen(
        key: const ValueKey('splash'),
        onFinished: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    } else if (_showOnboarding) {
      homeWidget = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onFinished: () {
          setState(() {
            _showOnboarding = false;
          });
        },
      );
    } else {
      homeWidget = state.isAuthenticated
          ? const PatientVaultHome(key: ValueKey('vault'))
          : const PatientLogin(key: ValueKey('login'));
    }

    return MaterialApp(
      title: 'HealthLock',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: homeWidget,
      ),
    );
  }
}

// ==========================================
// STATE MANAGEMENT (Provider with REST Sync)
// ==========================================

class SimulationState extends ChangeNotifier {
  List<Prescription> _patientVault = [];
  bool _isAttendanceActive = false;
  int? _sessionStartMs;
  String _backendUrl =
      (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
      ? 'http://10.0.2.2:4000'
      : 'http://localhost:4000';
  bool _isLoading = false;
  Timer? _pollTimer;
  String? _activePendingRequestId;
  final Set<String> _promptedRequestIds = {};
  List<dynamic> _activityLogs = [];
  List<dynamic> _visitHistory = [];

  // Auth state
  Map<String, dynamic>? _currentPatient;
  bool _isOfflineGuest = false;
  String _guestName = 'Elena Vance';
  String _patientMobileOrId = '992818';

  List<Prescription> get patientVault => _patientVault;
  bool get isAttendanceActive => _isAttendanceActive;
  int? get sessionStartMs => _sessionStartMs;
  List<dynamic> get visitHistory => _visitHistory;
  String get backendUrl => _backendUrl;
  String get patientMobileOrId => _patientMobileOrId;
  String get patientId {
    final cleanName = patientName.replaceAll(RegExp(r'\s+'), '_');
    return '${cleanName}_$patientMobileOrId';
  }

  bool get isLoading => _isLoading;
  String? get activePendingRequestId => _activePendingRequestId;
  List<dynamic> get activityLogs => _activityLogs;

  // Auth getters
  bool get isOfflineGuest => _isOfflineGuest;
  bool get isAuthenticated => _currentPatient != null || _isOfflineGuest;

  String get patientName {
    if (_currentPatient != null) {
      return _currentPatient!['name'] as String? ?? _guestName;
    }
    return _isOfflineGuest ? _guestName : 'Guest';
  }

  String get patientEmailOrId {
    if (_currentPatient != null) {
      return _currentPatient!['email'] as String? ?? 'patient@healthlock.org';
    }
    return _isOfflineGuest ? 'elena.vance@healthlock.org' : 'Guest User ID';
  }

  Future<void> updatePatientName(String newName) async {
    _guestName = newName;
    if (_currentPatient != null) {
      try {
        final token = _currentPatient!['token'] as String? ?? '';
        await http.post(
          Uri.parse('$_backendUrl/api/patient/update-name'),
          headers: {
            'Content-Type': 'application/json',
            'X-Session-Token': token,
          },
          body: jsonEncode({'name': newName}),
        );
        _currentPatient = {..._currentPatient!, 'name': newName};
      } catch (e) {
        debugPrint('Failed to update patient name: $e');
      }
    }
    notifyListeners();
  }

  Future<void> updatePatientMobileOrId(String newId) async {
    _patientMobileOrId = newId;
    notifyListeners();
  }

  SimulationState() {
    fetchPrescriptions();
    fetchActivityLogs();
    fetchVisitHistory();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isAuthenticated) {
        fetchPrescriptions(silent: true);
        checkPendingConsultations();
        fetchActivityLogs();
        fetchVisitHistory();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Auth actions
  void loginOfflineGuest() {
    _isOfflineGuest = true;
    fetchPrescriptions();
    notifyListeners();
  }

  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/patient/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );
      if (response.statusCode == 200) {
        _currentPatient = jsonDecode(response.body) as Map<String, dynamic>;
        _isOfflineGuest = false;
        fetchPrescriptions();
        fetchVisitHistory();
        notifyListeners();
        return null;
      }
      final detail = jsonDecode(response.body)['detail'] ?? 'Login failed';
      return detail as String;
    } catch (e) {
      return 'Cannot reach server. Check your connection.';
    }
  }

  Future<String?> signUpWithEmail(String email, String password, {String name = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/patient/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'name': name.isNotEmpty ? name : email.split('@').first,
        }),
      );
      if (response.statusCode == 200) {
        _currentPatient = jsonDecode(response.body) as Map<String, dynamic>;
        _isOfflineGuest = false;
        fetchPrescriptions();
        fetchVisitHistory();
        notifyListeners();
        return null;
      }
      final detail = jsonDecode(response.body)['detail'] ?? 'Registration failed';
      return detail as String;
    } catch (e) {
      return 'Cannot reach server. Check your connection.';
    }
  }

  void signOut() {
    _currentPatient = null;
    _isOfflineGuest = false;
    _patientVault = [];
    _selectedPrescription = null;
    notifyListeners();
  }

  void setBackendUrl(String url) {
    _backendUrl = url;
    fetchPrescriptions();
    notifyListeners();
  }

  void setAttendance(bool value) {
    _isAttendanceActive = value;
    if (value) {
      _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
    } else {
      _activePendingRequestId = null;
      _promptedRequestIds.clear();
      _sessionStartMs = null;
    }
    notifyListeners();
  }

  Future<void> fetchVisitHistory() async {
    if (_currentPatient == null) return;
    try {
      final token = _currentPatient!['token'] as String? ?? '';
      final name = Uri.encodeComponent(patientName);
      final response = await http.get(
        Uri.parse('$_backendUrl/api/visit-history/$name'),
        headers: {'X-Session-Token': token},
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

  void selectPrescription(Prescription? rx) {
    // Local selection state inside Patient app to view checkout QR code
    _selectedPrescription = rx;
    notifyListeners();
  }

  Prescription? _selectedPrescription;
  Prescription? get selectedPrescriptionQR => _selectedPrescription;

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
      }
    } catch (e) {
      // Gracefully handle server offline events during setup
      debugPrint('MongoDB Sync Server standby offline... ($e)');
      if (_patientVault.isEmpty) {
        _patientVault = List.from(mockPrescriptionsList);
      }
    } finally {
      if (_isLoading) {
        _isLoading = false;
      }
      if (_patientVault.isEmpty) {
        _patientVault = List.from(mockPrescriptionsList);
      }
      notifyListeners();
    }
  }

  void endSession() {
    _isAttendanceActive = false;
    _selectedPrescription = null;
    _activePendingRequestId = null;
    _promptedRequestIds.clear();
    notifyListeners();
  }

  Future<void> checkPendingConsultations() async {
    // When attendance is active, check if the doctor submitted a prescription (session auto-completed)
    if (_isAttendanceActive) {
      try {
        final response = await http.get(
          Uri.parse('$_backendUrl/api/consultation/has-active-session?patient=${Uri.encodeComponent(patientName)}'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['active'] == false) {
            _isAttendanceActive = false;
            await fetchPrescriptions(); // Refresh vault to show new prescription
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Error checking active session: $e');
      }
      return;
    }
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
        _isAttendanceActive = true; // Auto-activate consultation session
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
}

// Global UI Layout scaffold for the Patient Wallet
// Global UI Layout scaffold for the Patient Wallet (Tab Switcher)
class PatientVaultHome extends StatefulWidget {
  const PatientVaultHome({super.key});

  @override
  State<PatientVaultHome> createState() => _PatientVaultHomeState();
}

class _PatientVaultHomeState extends State<PatientVaultHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SimulationState>(context);

    final List<Widget> tabs = [
      SafeArea(
        child: PatientVault(
          onNotificationTap: () {
            setState(() {
              _currentIndex = 1;
            });
          },
        ),
      ),
      const SafeArea(child: NotificationsView()),
    ];

    return Scaffold(
      backgroundColor: AppColors.baseCanvas,
      body: Stack(
        children: [
          // Ambient Layer Shaders (Deep visual backlights)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientBlue.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientGreen.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          tabs[_currentIndex],
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: AppColors.darkRimGray),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppColors.darkRimGray,
          selectedItemColor: AppColors.clinicalBlue,
          unselectedItemColor: AppColors.mutedText,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.folder_shared_rounded),
              label: 'HEALTH VAULT',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: state.activePendingRequestId != null,
                backgroundColor: AppColors.crimsonLockout,
                label: const Text(
                  '1',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
                child: const Icon(Icons.notifications_active_rounded),
              ),
              label: 'NOTIFICATIONS',
            ),
          ],
        ),
      ),
    );
  }
}

// Notifications View displaying Link Requests and Clinical Logs from DB
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SimulationState>(context);

    // Filter logs for relevance to the current patient
    final allLogs = state.activityLogs;
    final patientLogs = allLogs.where((log) {
      final name = log['patientName']?.toString().toLowerCase() ?? '';
      return name == 'n/a' || name.contains(state.patientName.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.clinicalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.clinicalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                // 1. Practitioner Request Notification (if active)
                if (state.activePendingRequestId != null) ...[
                  GlassCard(
                    borderRadius: 16,
                    backgroundColor: AppColors.deepNavy,
                    border: Border.all(
                      color: AppColors.clinicalBlue.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Practitioner Link Request',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'A doctor is requesting secure authorization to connect and write credentials to your patient profile.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white30),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  state.rejectConsultation(
                                    state.activePendingRequestId!,
                                  );
                                },
                                child: const Text(
                                  'DECLINE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emeraldAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  state.acceptConsultation(
                                    state.activePendingRequestId!,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Doctor access granted. Session active.',
                                      ),
                                      backgroundColor: AppColors.emeraldAccent,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'ACCEPT ACCESS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Loop Dynamic Notification Items from DB
                if (patientLogs.isEmpty && state.activePendingRequestId == null)
                  const GlassCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 32,
                              color: AppColors.mutedText,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No security logs found.',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...patientLogs.map((log) {
                    final String eventType = log['eventType'] ?? 'INFO';
                    final String details = log['details'] ?? '';

                    IconData iconData = Icons.info_outline;
                    Color iconColor = AppColors.clinicalBlue;
                    String title = 'Ledger Event';

                    if (eventType == 'CREATE_PRESCRIPTION') {
                      iconData = Icons.medication_rounded;
                      iconColor = AppColors.clinicalBlue;
                      title = 'Prescription Issued';
                    } else if (eventType == 'DISPENSE_PRESCRIPTION') {
                      iconData = Icons.local_pharmacy_outlined;
                      iconColor = AppColors.crimsonLockout;
                      title = 'Medications Dispensed';
                    } else if (eventType.contains('SCAN_PHARMACY')) {
                      iconData = Icons.qr_code_scanner_rounded;
                      iconColor = Colors.teal;
                      title = 'Zero-Trust Verification';
                    } else if (eventType == 'ACCEPT_ACCESS') {
                      iconData = Icons.security_rounded;
                      iconColor = AppColors.emeraldAccent;
                      title = 'Doctor Access Authorized';
                    } else if (eventType == 'REJECT_ACCESS') {
                      iconData = Icons.block_outlined;
                      iconColor = AppColors.crimsonLockout;
                      title = 'Doctor Access Blocked';
                    } else if (eventType.contains('LOGIN') ||
                        eventType.contains('REGISTER')) {
                      iconData = Icons.person_outline_rounded;
                      iconColor = Colors.amber;
                      title = 'Security Portal Session';
                    }

                    // Format Timeago
                    DateTime? dt;
                    if (log['timestamp'] != null) {
                      try {
                        dt = DateTime.parse(log['timestamp'].toString());
                      } catch (_) {}
                    }
                    String timeStr = 'Recent';
                    if (dt != null) {
                      final diff = DateTime.now().difference(dt.toLocal());
                      if (diff.inSeconds < 60) {
                        timeStr = 'Just now';
                      } else if (diff.inMinutes < 60) {
                        timeStr = '${diff.inMinutes}m ago';
                      } else if (diff.inHours < 24) {
                        timeStr = '${diff.inHours}h ago';
                      } else {
                        timeStr = '${diff.inDays}d ago';
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassCard(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: iconColor, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    details,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.mutedText,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
