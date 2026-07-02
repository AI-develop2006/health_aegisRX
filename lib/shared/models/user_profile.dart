import '../../core/state/app_state.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final UserRole role;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.patient,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'role': role.toString().split('.').last,
    };
  }
}
