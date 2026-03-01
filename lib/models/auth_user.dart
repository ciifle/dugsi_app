import 'package:kobac/models/dummy_user.dart';

/// User model from API login response.
class AuthUser {
  final int id;
  final String name;
  final String? email;
  final String? emisNumber;
  final String role; // API returns e.g. SCHOOL_ADMIN, TEACHER, STUDENT, PARENT
  final int? schoolId;

  const AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.emisNumber,
    required this.role,
    this.schoolId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'emis_number': emisNumber,
      'role': role,
      'school_id': schoolId,
    };
  }

  static int _parseId(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _parseId(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      emisNumber: json['emis_number'] as String?,
      role: json['role'] as String? ?? 'STUDENT',
      schoolId: json['school_id'] != null ? _parseId(json['school_id']) : null,
    );
  }

  /// Map API role string to UI UserRole enum.
  UserRole get userRole => roleFromApiString(role);
}

/// Maps backend role (e.g. SCHOOL_ADMIN) to UI UserRole.
UserRole roleFromApiString(String apiRole) {
  final upper = apiRole.toUpperCase();
  switch (upper) {
    case 'SCHOOL_ADMIN':
      return UserRole.schoolAdmin;
    case 'TEACHER':
      return UserRole.teacher;
    case 'STUDENT':
      return UserRole.student;
    case 'PARENT':
      return UserRole.parent;
    default:
      return UserRole.student;
  }
}

/// UI role string for display/selector (school_admin, teacher, student, parent).
String roleToUiString(UserRole role) {
  switch (role) {
    case UserRole.schoolAdmin:
      return 'school_admin';
    case UserRole.teacher:
      return 'teacher';
    case UserRole.student:
      return 'student';
    case UserRole.parent:
      return 'parent';
  }
}
