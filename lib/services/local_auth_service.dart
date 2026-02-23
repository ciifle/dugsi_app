import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dummy_user.dart';

class LocalAuthService {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  static const String _userKey = 'local_user_session';

  final List<DummyUser> _dummyUsers = [
    DummyUser(
      id: '1',
      email: 'admin@school.com',
      password: '123456',
      name: 'School Admin',
      role: UserRole.schoolAdmin,
      phone: '123-456-7890',
      schoolId: 'school_1',
    ),
    DummyUser(
      id: '2',
      email: 'teacher@school.com',
      password: '123456',
      name: 'Teacher User',
      role: UserRole.teacher,
      phone: '987-654-3210',
      schoolId: 'school_1',
    ),
    DummyUser(
      id: '3',
      email: 'student@school.com',
      password: '123456',
      name: 'Student User',
      role: UserRole.student,
      phone: '555-555-5555',
      schoolId: 'school_1',
    ),
    DummyUser(
      id: '4',
      email: 'parent@school.com',
      password: '123456',
      name: 'Parent User',
      role: UserRole.parent,
      phone: '111-222-3333',
      schoolId: 'school_1',
    ),
  ];

  /// Login with email and password
  Future<DummyUser?> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = _dummyUsers.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.toLowerCase() &&
            u.password == password,
      );

      await _saveSession(user);
      print('✅ User logged in: ${user.email} with role: ${user.role}');
      return user;
    } catch (e) {
      print('❌ Login failed: $e');
      return null;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      print('✅ User logged out, session cleared');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  /// Get currently logged in user
  Future<DummyUser?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userKey);

      if (userJsonStr == null) {
        print('ℹ️ No user session found');
        return null;
      }

      final Map<String, dynamic> userJson = jsonDecode(userJsonStr);
      final user = DummyUser.fromJson(userJson);
      print('✅ Retrieved user: ${user.email} with role: ${user.role}');
      return user;
    } catch (e) {
      print('❌ Error getting current user: $e');
      // Clear corrupted session
      await logout();
      return null;
    }
  }

  /// Save user session to SharedPreferences
  Future<void> _saveSession(DummyUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      print('✅ Session saved for user: ${user.email}');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  /// Change password for current user
  /// Returns true if password was changed successfully, false if current password is wrong or user not found
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // Get current logged in user
      final user = await getCurrentUser();
      if (user == null) {
        print('❌ No user logged in');
        return false;
      }

      // Verify current password
      if (user.password != currentPassword) {
        print('❌ Current password is incorrect');
        return false;
      }

      // Find user in dummy users list
      final index = _dummyUsers.indexWhere((u) => u.id == user.id);
      if (index == -1) {
        print('❌ User not found in dummy users list');
        return false;
      }

      // Create updated user with new password
      final updated = DummyUser(
        id: user.id,
        email: user.email,
        password: newPassword, // New password
        name: user.name,
        role: user.role,
        phone: user.phone,
        schoolId: user.schoolId,
        emisNumber: user.emisNumber,
      );

      // Update in-memory list
      _dummyUsers[index] = updated;

      // Update session with new user data
      await _saveSession(updated);

      print('✅ Password changed successfully for user: ${user.email}');
      return true;
    } catch (e) {
      print('❌ Error changing password: $e');
      return false;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Get current user role
  Future<UserRole?> getCurrentUserRole() async {
    final user = await getCurrentUser();
    return user?.role;
  }
}
