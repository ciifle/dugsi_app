import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/models/auth_user.dart';

const String _keyToken = 'auth_token';
const String _keyUser = 'auth_user';
const String _keyProfile = 'auth_profile';
const String _keyProfileRole = 'auth_profile_role';
const String _keyFeesEnabled = 'auth_fees_enabled';

/// Secure storage for auth session (token + user + profile).
class AuthStorage {
  AuthStorage._();
  static final AuthStorage _instance = AuthStorage._();
  factory AuthStorage() => _instance;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Save token, user, optional profile, and optional school feature flags (persisted for offline display).
  Future<void> saveSession({
    required String token,
    AuthUser? user,
    dynamic profile,
    String? profileRole,
    bool? feesEnabled,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    if (user != null) {
      await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
    } else {
      await _storage.delete(key: _keyUser);
    }
    if (profile != null && profileRole != null) {
      try {
        final map = _profileToMap(profile);
        if (map != null) {
          await _storage.write(key: _keyProfile, value: jsonEncode(map));
          await _storage.write(key: _keyProfileRole, value: profileRole);
        }
      } catch (_) {
        await _storage.delete(key: _keyProfile);
        await _storage.delete(key: _keyProfileRole);
      }
    } else {
      await _storage.delete(key: _keyProfile);
      await _storage.delete(key: _keyProfileRole);
    }
    if (feesEnabled != null) {
      await _storage.write(key: _keyFeesEnabled, value: feesEnabled ? '1' : '0');
    } else {
      await _storage.delete(key: _keyFeesEnabled);
    }
  }

  Map<String, dynamic>? _profileToMap(dynamic profile) {
    if (profile is TeacherProfile) {
      return {
        'id': profile.id,
        'user_id': profile.userId,
        'school_id': profile.schoolId,
        'full_name': profile.fullName,
        'phone': profile.phone,
        'mother_name': profile.motherName,
        'graduated_university': profile.graduatedUniversity,
        'gender': profile.gender,
        'address': profile.address,
        'email': profile.email,
      };
    }
    if (profile is StudentProfile) {
      return {
        'id': profile.id,
        'user_id': profile.userId,
        'school_id': profile.schoolId,
        'class_id': profile.classId,
        'emisNumber': profile.emisNumber,
        'studentName': profile.studentName,
        'motherName': profile.motherName,
        'birthDate': profile.birthDate,
        'sex': profile.sex,
        'telephone': profile.telephone,
        'birthPlace': profile.birthPlace,
        'nationality': profile.nationality,
        'studentState': profile.studentState,
        'studentDistrict': profile.studentDistrict,
        'studentVillage': profile.studentVillage,
        'refugeeStatus': profile.refugeeStatus,
        'orphanStatus': profile.orphanStatus,
        'disabilityStatus': profile.disabilityStatus,
        'guardianName': profile.guardianName,
        'schoolName': profile.schoolName,
        'className': profile.className,
        'age': profile.age,
        'absenteeismStatus': profile.absenteeismStatus,
        'Class': profile.class_,
      };
    }
    if (profile is ParentProfile) {
      return {
        'id': profile.id,
        'user_id': profile.userId,
        'school_id': profile.schoolId,
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'linked_students': profile.linkedStudents.map((s) => {'id': s.id, 'name': s.name, 'emis_number': s.emisNumber, 'class_name': s.className}).toList(),
      };
    }
    if (profile is SchoolAdminProfile) {
      return {'id': profile.id, 'user_id': profile.userId, 'school_id': profile.schoolId, 'name': profile.name, 'email': profile.email};
    }
    return null;
  }

  dynamic _mapToProfile(String? role, Map<String, dynamic>? map) {
    if (role == null || map == null) return null;
    return parseProfileByRole(role, map);
  }

  /// Load stored session. Returns null if no session.
  Future<AuthSession?> loadSession() async {
    final token = await _storage.read(key: _keyToken);
    if (token == null || token.isEmpty) return null;

    final userJson = await _storage.read(key: _keyUser);
    AuthUser? user;
    if (userJson != null && userJson.isNotEmpty) {
      try {
        user = AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    final profileJson = await _storage.read(key: _keyProfile);
    final profileRole = await _storage.read(key: _keyProfileRole);
    dynamic profile;
    if (profileJson != null && profileRole != null) {
      try {
        final map = jsonDecode(profileJson) as Map<String, dynamic>;
        profile = _mapToProfile(profileRole, map);
      } catch (_) {}
    }

    bool? feesEnabled;
    final feesEnabledStr = await _storage.read(key: _keyFeesEnabled);
    if (feesEnabledStr == '1') feesEnabled = true;
    if (feesEnabledStr == '0') feesEnabled = false;

    return AuthSession(token: token, user: user, profile: profile, feesEnabled: feesEnabled);
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyUser);
      await _storage.delete(key: _keyProfile);
      await _storage.delete(key: _keyProfileRole);
      await _storage.delete(key: _keyFeesEnabled);
      await _storage.deleteAll();
    } catch (_) {}
  }
}

class AuthSession {
  final String token;
  final AuthUser? user;
  final dynamic profile;
  final bool? feesEnabled;

  AuthSession({required this.token, this.user, this.profile, this.feesEnabled});
}
