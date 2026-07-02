import 'package:flutter/foundation.dart';

enum UserRole { patient, doctor, pharmacy }

class AppState extends ChangeNotifier {
  UserRole? _role;
  String? _token; // e.g. Cognito JWT

  UserRole? get role => _role;
  String? get token => _token;

  bool get isLoggedIn => _token != null && _role != null;

  void setSession({
    required UserRole role,
    required String token,
  }) {
    _role = role;
    _token = token;
    notifyListeners();
  }

  void clearSession() {
    _role = null;
    _token = null;
    notifyListeners();
  }
}
