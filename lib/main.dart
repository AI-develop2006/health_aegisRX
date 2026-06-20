import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_lock/firebase_options.dart';

import 'package:flutter/foundation.dart';
import 'package:health_lock/core/constants/app_colors.dart';
import 'package:health_lock/core/theme/app_theme.dart';
import 'package:health_lock/shared/models/prescription.dart';
import 'package:health_lock/features/patient/screens/patient_vault.dart';
import 'package:health_lock/features/patient/screens/patient_login.dart';
import 'package:health_lock/core/constants/mock_prescriptions.dart';
import 'package:health_lock/features/patient/screens/onboarding_screen.dart';
import 'package:health_lock/features/patient/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint(
      'Firebase initialization with currentPlatform failed: $e. Trying fallback options...',
    );
    FirebaseOptions? options;
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final appId = dotenv.env['FIREBASE_APP_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];

    if (apiKey != null &&
        apiKey.isNotEmpty &&
        apiKey != 'your-api-key-here' &&
        appId != null &&
        appId.isNotEmpty &&
        appId != '1:1234567890:web:1234567890abcdef') {
      options = FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId ?? '',
        projectId: projectId ?? '',
        storageBucket: storageBucket,
        iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'],
      );
    }

    try {
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
    } catch (e2) {
      debugPrint(
        'Firebase fallback initialization failed: $e2. Running in Offline Mock mode.',
      );
    }
  }
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
  String _backendUrl = 'http://localhost:5000';
  bool _isLoading = false;
  Timer? _pollTimer;
  String? _activePendingRequestId;
  final Set<String> _promptedRequestIds = {};

  // Firebase Auth variables
  User? _firebaseUser;
  bool _isOfflineGuest = false;
  StreamSubscription<User?>? _authSubscription;
  String _guestName = 'Elena Vance';

  List<Prescription> get patientVault => _patientVault;
  bool get isAttendanceActive => _isAttendanceActive;
  String get backendUrl => _backendUrl;
  bool get isLoading => _isLoading;
  String? get activePendingRequestId => _activePendingRequestId;

  // Auth getters
  User? get firebaseUser => _firebaseUser;
  bool get isOfflineGuest => _isOfflineGuest;
  bool get isAuthenticated => _firebaseUser != null || _isOfflineGuest;

  String get patientName {
    if (_firebaseUser != null) {
      return _firebaseUser!.displayName ?? _guestName;
    }
    return _isOfflineGuest ? _guestName : 'Guest';
  }

  String get patientEmailOrId {
    if (_firebaseUser != null) {
      return _firebaseUser!.email ?? _firebaseUser!.uid;
    }
    return _isOfflineGuest ? 'elena.vance@healthlock.org' : 'Guest User ID';
  }

  Future<void> updatePatientName(String newName) async {
    _guestName = newName;
    if (_firebaseUser != null) {
      try {
        await _firebaseUser!.updateDisplayName(newName);
        await _firebaseUser!.reload();
        _firebaseUser = FirebaseAuth.instance.currentUser;
      } catch (e) {
        debugPrint('Failed to update Firebase display name: $e');
      }
    }
    notifyListeners();
  }

  SimulationState() {
    try {
      // Listen to Firebase Auth state changes
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        _firebaseUser = user;
        if (user != null) {
          _isOfflineGuest = false;
          fetchPrescriptions();
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint(
        'Firebase Auth not initialized: $e. Operating in sandbox mode.',
      );
    }

    fetchPrescriptions();
    // Live polling: Sync with MongoDB backend every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isAuthenticated) {
        fetchPrescriptions(silent: true);
        checkPendingConsultations();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // Auth actions
  void loginOfflineGuest() {
    _isOfflineGuest = true;
    fetchPrescriptions();
    notifyListeners();
  }

  Future<String?> loginWithGoogle() async {
    try {
      // Google Sign-In package does not natively support Windows Desktop.
      // Guard against running on Windows and suggest testing on Android, iOS, or Web.
      if (defaultTargetPlatform == TargetPlatform.windows && !kIsWeb) {
        return 'Google Sign-In is not supported on Windows Desktop. Please test on Android, iOS, or Web.';
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return 'Google sign in aborted by user';
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Google authentication failed';
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('MissingPluginException')) {
        return 'Google Sign-In native plugin not compiled. Please stop the app completely and run "flutter run" again to perform a full build.';
      }
      return errStr;
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Authentication failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Firebase sign out failed: $e');
    }
    _isOfflineGuest = false;
    _firebaseUser = null;
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
    if (!value) {
      _activePendingRequestId = null;
      _promptedRequestIds.clear();
    }
    notifyListeners();
  }

  void selectPrescription(Prescription? rx) {
    // Local selection state inside Patient app to view checkout QR code
    _selectedPrescription = rx;
    notifyListeners();
  }

  Prescription? _selectedPrescription;
  Prescription? get selectedPrescriptionQR => _selectedPrescription;

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
    if (!_isAttendanceActive) return;
    try {
      final response = await http.get(
        Uri.parse(
          '$_backendUrl/api/consultation/pending?patient=${Uri.encodeComponent(patientName)}',
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
class PatientVaultHome extends StatelessWidget {
  const PatientVaultHome({super.key});

  @override
  Widget build(BuildContext context) {
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

          // Core Patient Vault Interface
          const SafeArea(child: PatientVault()),
        ],
      ),
    );
  }
}
