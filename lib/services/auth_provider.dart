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
  AuthProvider() {
    onUnauthorized = _handleUnauthorized;
  }

  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _token;
  AuthUser? _user;
  dynamic _profile; // TeacherProfile | StudentProfile | ParentProfile | SchoolAdminProfile | null
  String? _profileError; // e.g. "Your account is missing profile data. Contact your admin."

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  AuthUser? get user => _user;
  dynamic get profile => _profile;
  String? get profileError => _profileError;

  TeacherProfile? get teacherProfile => _profile is TeacherProfile ? _profile as TeacherProfile : null;
  StudentProfile? get studentProfile => _profile is StudentProfile ? _profile as StudentProfile : null;
  ParentProfile? get parentProfile => _profile is ParentProfile ? _profile as ParentProfile : null;
  SchoolAdminProfile? get schoolAdminProfile => _profile is SchoolAdminProfile ? _profile as SchoolAdminProfile : null;

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
    _isAuthenticated = true;

    final meResult = await auth_svc.getMe();
    if (meResult is auth_svc.GetMeSuccess) {
      _user = meResult.data.user;
      _profile = meResult.data.profile;
      _profileError = null;
      await AuthStorage().saveSession(
        token: _token!,
        user: _user,
        profile: _profile,
        profileRole: _user?.role,
      );
    } else if (meResult is auth_svc.GetMeFailure) {
      if (meResult.statusCode == 401) {
        await AuthStorage().clearSession();
        _token = null;
        _user = null;
        _profile = null;
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
        _profileError = null;
        await AuthStorage().saveSession(
          token: _token!,
          user: _user,
          profile: _profile,
          profileRole: _user?.role,
        );
      } else {
        _user = result.user;
        _profile = null;
        _profileError = (meResult is auth_svc.GetMeFailure) ? meResult.message : null;
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
  Future<String?> loginWithIdentifier(String identifier, String password) async {
    final result = await auth_svc.loginWithIdentifier(identifier, password);

    if (result is auth_svc.LoginSuccess) {
      _token = result.token;
      ApiClient().setToken(_token);
      final meResult = await auth_svc.getMe();
      if (meResult is auth_svc.GetMeSuccess) {
        _user = meResult.data.user;
        _profile = meResult.data.profile;
        _profileError = null;
        await AuthStorage().saveSession(
          token: _token!,
          user: _user,
          profile: _profile,
          profileRole: _user?.role,
        );
      } else {
        _user = result.user;
        _profile = null;
        _profileError = (meResult is auth_svc.GetMeFailure) ? meResult.message : null;
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
      _profileError = null;
      await AuthStorage().saveSession(
        token: _token!,
        user: _user,
        profile: _profile,
        profileRole: _user?.role,
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
    await AuthStorage().clearSession();
    _token = null;
    _user = null;
    _profile = null;
    _profileError = null;
    _isAuthenticated = false;
    ApiClient().setToken(null);
    try {
      StudentService().clearCache();
    } catch (_) {}
    notifyListeners();

    final navContext = authNavigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      Navigator.of(navContext).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _handleUnauthorized() {
    AuthStorage().clearSession().then((_) {
      _token = null;
      _user = null;
      _profile = null;
      _profileError = null;
      _isAuthenticated = false;
      ApiClient().setToken(null);
      notifyListeners();
      final navContext = authNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        Navigator.of(navContext).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }
}
