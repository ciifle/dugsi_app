import 'dart:async';
import 'package:kobac/services/teacher_attendance_sync.dart';
import 'package:flutter/material.dart';

import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/models/auth_user.dart';
import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/auth_storage.dart';
import 'package:kobac/services/auth_service.dart' as auth_svc;
import 'package:kobac/services/student_service.dart';

/// Global navigator key so logout/401 can reset to Login from anywhere.
final GlobalKey<NavigatorState> authNavigatorKey = GlobalKey<NavigatorState>();

/// Auth state and actions. User + profile from GET /api/auth/me.
class AuthProvider extends ChangeNotifier {
  String? _attendanceOwner;
  String? _attendanceToken;

  /// Offline attendance worker for the signed-in teacher; null otherwise.
  /// Scoped to school + user so accounts never see each other's data.
  Future<TeacherAttendanceSync>? get attendanceSync =>
      _attendanceOwner == null ? null : TeacherAttendanceSync.current;

  @override
  void notifyListeners() {
    final teacher = _user;
    final schoolId = teacher?.schoolId;
    final owner =
        _isAuthenticated &&
            teacher?.role.toUpperCase() == 'TEACHER' &&
            schoolId != null
        ? TeacherAttendanceSync.ownerKey(schoolId, teacher!.id)
        : null;
    if (owner != _attendanceOwner) {
      _attendanceOwner = owner;
      _attendanceToken = _token;
      if (owner == null) {
        TeacherAttendanceSync.stopWorker();
      } else {
        unawaited(
          TeacherAttendanceSync.forTeacher(
            schoolId: schoolId!,
            userId: teacher!.id,
            token: () => _attendanceOwner == owner ? _token : null,
          ).then<void>((_) {}, onError: (Object error) {}),
        );
      }
    } else if (owner != null && _token != _attendanceToken) {
      // Same teacher signed in again (e.g. after expiry): resume sending.
      _attendanceToken = _token;
      TeacherAttendanceSync.current?.then((s) => s.wake(), onError: (_) {});
    }
    super.notifyListeners();
  }

  AuthProvider() {
    onUnauthorized = _handleUnauthorized;
  }

  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _token;
  AuthUser? _user;
  dynamic
  _profile; // TeacherProfile | StudentProfile | ParentProfile | SchoolAdminProfile | null
  SchoolBranding? _school;
  SchoolFeatures? _schoolFeatures;
  String?
  _profileError; // e.g. "Your account is missing profile data. Contact your admin."
  bool?
  _feesEnabled; // from GET /api/auth/me (school-level feature flag); null = not enabled

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  AuthUser? get user => _user;
  dynamic get profile => _profile;
  SchoolBranding? get school => _school;
  SchoolFeatures? get schoolFeatures => _schoolFeatures;
  String? get profileError => _profileError;

  /// True when the school has fees/payment feature enabled. Missing feature information is treated as disabled.
  bool get feesEnabled => _feesEnabled ?? false;

  /// A server feature denial overrides cached visibility until /me is refreshed.
  void disableFinanceAccess() {
    if (_feesEnabled == false) return;
    _feesEnabled = false;
    notifyListeners();
  }

  bool get examsEnabled => _schoolFeatures?.examsEnabled ?? true;

  /// Exam Fee Custom module. Fails closed: missing/null is OFF. Independent
  /// of [feesEnabled] (payments).
  bool get examFeeCustomEnabled =>
      _schoolFeatures?.examFeeCustomEnabled ?? false;

  /// A server EXAM_FEE_CUSTOM_NOT_ENABLED denial hides the module until the
  /// next /me refresh replaces the features.
  void disableExamFeeAccess() {
    if (!examFeeCustomEnabled) return;
    _schoolFeatures = (_schoolFeatures ?? const SchoolFeatures()).copyWith(
      examFeeCustomEnabled: false,
    );
    notifyListeners();
  }

  TeacherProfile? get teacherProfile =>
      _profile is TeacherProfile ? _profile as TeacherProfile : null;
  StudentProfile? get studentProfile =>
      _profile is StudentProfile ? _profile as StudentProfile : null;
  ParentProfile? get parentProfile =>
      _profile is ParentProfile ? _profile as ParentProfile : null;
  SchoolAdminProfile? get schoolAdminProfile =>
      _profile is SchoolAdminProfile ? _profile as SchoolAdminProfile : null;
  FinanceProfile? get financeProfile =>
      _profile is FinanceProfile ? _profile as FinanceProfile : null;

  /// Call on app start: load session, set token, then call GET /api/auth/me to refresh user+profile.
  Future<void> initializeAuth() async {
    _isLoading = true;
    _profileError = null;
    notifyListeners();

    final session = await AuthStorage().loadSession();
    if (session == null) {
      _token = null;
      _user = null;
      _profile = null;
      _school = null;
      _schoolFeatures = null;
      _feesEnabled = null;
      _isAuthenticated = false;
      ApiClient().setToken(null);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _token = session.token;
    ApiClient().setToken(_token);
    _user = session.user;
    _profile = session.profile;
    _school = session.school;
    _schoolFeatures = session.schoolFeatures;
    _feesEnabled = session.feesEnabled;
    _isAuthenticated = true;

    final meResult = await auth_svc.getMe();
    if (meResult is auth_svc.GetMeSuccess) {
      _user = meResult.data.user;
      _profile = meResult.data.profile;
      _school = meResult.data.school;
      _schoolFeatures = meResult.data.schoolFeatures;
      _feesEnabled = meResult.data.feesEnabled;
      _profileError = null;
      await AuthStorage().saveSession(
        token: _token!,
        user: _user,
        profile: _profile,
        profileRole: _user?.role,
        feesEnabled: _feesEnabled,
        school: _school,
        schoolFeatures: _schoolFeatures,
      );
    } else if (meResult is auth_svc.GetMeFailure) {
      if (meResult.statusCode == 401) {
        await AuthStorage().clearSession();
        _token = null;
        _user = null;
        _profile = null;
        _school = null;
        _schoolFeatures = null;
        _isAuthenticated = false;
        ApiClient().setToken(null);
      } else {
        _profileError = meResult.message;
        // Keep session user/profile from storage for offline display
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login; on success calls GET /api/auth/me and stores user + profile.
  Future<String?> login(
    UserRole role, {
    String? emisNumber,
    String? email,
    required String password,
  }) async {
    final result = await auth_svc.loginWithCredentials(
      role,
      emisNumber: emisNumber,
      email: email,
      password: password,
    );

    if (result is auth_svc.LoginSuccess) {
      _token = result.token;
      ApiClient().setToken(_token);
      final meResult = await auth_svc.getMe();
      if (meResult is auth_svc.GetMeSuccess) {
        _user = meResult.data.user;
        _profile = meResult.data.profile;
        _school = meResult.data.school;
        _schoolFeatures = meResult.data.schoolFeatures;
        _feesEnabled = meResult.data.feesEnabled;
        _profileError = null;
        await AuthStorage().saveSession(
          token: _token!,
          user: _user,
          profile: _profile,
          profileRole: _user?.role,
          feesEnabled: _feesEnabled,
          school: _school,
          schoolFeatures: _schoolFeatures,
        );
      } else {
        _user = result.user;
        _profile = null;
        _school = null;
        _schoolFeatures = null;
        _feesEnabled = null;
        _profileError = (meResult is auth_svc.GetMeFailure)
            ? meResult.message
            : null;
        await AuthStorage().saveSession(token: _token!, user: _user);
      }
      _isAuthenticated = true;
      notifyListeners();
      return null;
    }
    if (result is auth_svc.LoginFailure) {
      final msg = result.message;
      return (msg != null && msg.isNotEmpty) ? msg : 'Login failed';
    }
    return 'Login failed';
  }

  /// Login with identifier; on success calls GET /api/auth/me and stores user + profile.
  Future<String?> loginWithIdentifier(
    String identifier,
    String password,
  ) async {
    final result = await auth_svc.loginWithIdentifier(identifier, password);

    if (result is auth_svc.LoginSuccess) {
      _token = result.token;
      ApiClient().setToken(_token);
      final meResult = await auth_svc.getMe();
      if (meResult is auth_svc.GetMeSuccess) {
        _user = meResult.data.user;
        _profile = meResult.data.profile;
        _school = meResult.data.school;
        _schoolFeatures = meResult.data.schoolFeatures;
        _feesEnabled = meResult.data.feesEnabled;
        _profileError = null;
        await AuthStorage().saveSession(
          token: _token!,
          user: _user,
          profile: _profile,
          profileRole: _user?.role,
          feesEnabled: _feesEnabled,
          school: _school,
          schoolFeatures: _schoolFeatures,
        );
      } else {
        _user = result.user;
        _profile = null;
        _school = null;
        _schoolFeatures = null;
        _feesEnabled = null;
        _profileError = (meResult is auth_svc.GetMeFailure)
            ? meResult.message
            : null;
        await AuthStorage().saveSession(token: _token!, user: _user);
      }
      _isAuthenticated = true;
      notifyListeners();
      return null;
    }
    if (result is auth_svc.LoginFailure) {
      final msg = result.message;
      return (msg != null && msg.isNotEmpty) ? msg : 'Login failed';
    }
    return 'Login failed';
  }

  /// Re-call GET /api/auth/me and update user + profile (e.g. pull-to-refresh on profile screen).
  Future<String?> refreshMe() async {
    if (_token == null) return 'Not logged in';
    final meResult = await auth_svc.getMe();
    if (meResult is auth_svc.GetMeSuccess) {
      _user = meResult.data.user;
      _profile = meResult.data.profile;
      _school = meResult.data.school;
      _schoolFeatures = meResult.data.schoolFeatures;
      _feesEnabled = meResult.data.feesEnabled;
      _profileError = null;
      await AuthStorage().saveSession(
        token: _token!,
        user: _user,
        profile: _profile,
        profileRole: _user?.role,
        feesEnabled: _feesEnabled,
        school: _school,
        schoolFeatures: _schoolFeatures,
      );
      notifyListeners();
      return null;
    }
    if (meResult is auth_svc.GetMeFailure) {
      if (meResult.statusCode == 401) {
        await logout();
        return meResult.message;
      }
      _profileError = meResult.message;
      notifyListeners();
      return meResult.message;
    }
    return 'Could not refresh profile';
  }

  Future<void> logout() async {
    final user = _user;
    if (user != null &&
        user.role.toUpperCase() == 'TEACHER' &&
        user.schoolId != null) {
      // Queued attendance is kept until the server confirms it.
      TeacherAttendanceSync.stopWorker();
      try {
        await TeacherAttendanceSync.clearDownloadedData(
          user.schoolId!,
          user.id,
        );
      } catch (_) {}
    }
    await AuthStorage().clearSession();
    _token = null;
    _user = null;
    _profile = null;
    _school = null;
    _schoolFeatures = null;
    _feesEnabled = null;
    _profileError = null;
    _isAuthenticated = false;
    ApiClient().setToken(null);
    try {
      StudentService().clearCache();
    } catch (_) {}
    notifyListeners();

    final navContext = authNavigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      Navigator.of(
        navContext,
      ).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _handleUnauthorized() {
    AuthStorage().clearSession().then((_) {
      _token = null;
      _user = null;
      _profile = null;
      _school = null;
      _schoolFeatures = null;
      _feesEnabled = null;
      _profileError = null;
      _isAuthenticated = false;
      ApiClient().setToken(null);
      notifyListeners();
      final navContext = authNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        Navigator.of(
          navContext,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }
}
