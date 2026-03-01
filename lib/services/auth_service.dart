import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/models/auth_user.dart';
import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/services/api_client.dart';

/// Timeout for login request (avoids hanging on CORS/network failure).
const Duration _kLoginTimeout = Duration(seconds: 25);

/// Safe message for network/CORS/unknown errors. Never use exception.toString() to avoid null crash on web.
const String _kNetworkErrorMessage = 'Network error. Please try again.';
const String _kGenericErrorMessage = 'Something went wrong. Please try again.';

/// Result of login attempt.
sealed class LoginResult {}

class LoginSuccess extends LoginResult {
  final String token;
  final AuthUser user;
  LoginSuccess({required this.token, required this.user});
}

class LoginFailure extends LoginResult {
  final String message;
  final int? statusCode;
  LoginFailure({required this.message, this.statusCode});
}

/// Builds login request body by role: student -> emis_number+password; others -> email+password.
Map<String, String> buildLoginBody(UserRole role, {
  String? emisNumber,
  String? email,
  required String password,
}) {
  if (role == UserRole.student) {
    return {
      'emis_number': emisNumber ?? '',
      'password': password,
    };
  }
  return {
    'email': email ?? '',
    'password': password,
  };
}

/// Builds login body from a single identifier: if it contains '@' use email+password, else emis_number+password.
/// Backend accepts only one identifier (either email or emis_number), not both.
Map<String, String> buildLoginBodyFromIdentifier(String identifier, String password) {
  final trimmed = identifier.trim();
  if (trimmed.contains('@')) {
    return {'email': trimmed, 'password': password};
  }
  return {'emis_number': trimmed, 'password': password};
}

/// Login with a single identifier (email or EMIS number) and password. No role selection needed.
Future<LoginResult> loginWithIdentifier(String identifier, String password) async {
  final body = buildLoginBodyFromIdentifier(identifier, password);
  final uri = apiUrl('api/auth/login');
  if (kDebugMode) {
    debugPrint('AuthService: POST $uri');
  }
  try {
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_kLoginTimeout, onTimeout: () {
      throw TimeoutException('Login timeout');
    });

    if (response.statusCode == 200) {
      final data = _parseJson(response.body ?? '');
      if (data == null) {
        return LoginFailure(message: 'Invalid response from server');
      }
      final token = data['token'] as String?;
      final userJson = data['user'];
      if (token == null || token.isEmpty || userJson == null) {
        return LoginFailure(message: 'Invalid response from server');
      }
      if (userJson is! Map<String, dynamic>) {
        return LoginFailure(message: 'Invalid response from server');
      }
      try {
        final user = AuthUser.fromJson(userJson);
        return LoginSuccess(token: token, user: user);
      } catch (_) {
        return LoginFailure(message: 'Invalid response from server');
      }
    }

    if (response.statusCode == 401) {
      return LoginFailure(message: 'Invalid credentials', statusCode: 401);
    }

    return LoginFailure(
      message: _errorMessage(response),
      statusCode: response.statusCode,
    );
  } on TimeoutException {
    return LoginFailure(message: _kNetworkErrorMessage);
  } on http.ClientException {
    return LoginFailure(message: _kNetworkErrorMessage);
  } catch (_) {
    return LoginFailure(message: _kGenericErrorMessage);
  }
}

/// Calls POST /api/auth/login and returns LoginSuccess or LoginFailure.
Future<LoginResult> loginWithCredentials(
  UserRole role, {
  String? emisNumber,
  String? email,
  required String password,
}) async {
  final body = buildLoginBody(
    role,
    emisNumber: emisNumber,
    email: email,
    password: password,
  );

  final uri = apiUrl('api/auth/login');
  if (kDebugMode) {
    debugPrint('AuthService: POST $uri');
  }
  try {
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_kLoginTimeout, onTimeout: () {
      throw TimeoutException('Login timeout');
    });

    if (response.statusCode == 200) {
      final data = _parseJson(response.body ?? '');
      if (data == null) {
        return LoginFailure(message: 'Invalid response from server');
      }
      final token = data['token'] as String?;
      final userJson = data['user'];
      if (token == null || token.isEmpty || userJson == null) {
        return LoginFailure(message: 'Invalid response from server');
      }
      if (userJson is! Map<String, dynamic>) {
        return LoginFailure(message: 'Invalid response from server');
      }
      try {
        final user = AuthUser.fromJson(userJson);
        return LoginSuccess(token: token, user: user);
      } catch (_) {
        return LoginFailure(message: 'Invalid response from server');
      }
    }

    if (response.statusCode == 401) {
      return LoginFailure(message: 'Invalid credentials', statusCode: 401);
    }

    return LoginFailure(
      message: _errorMessage(response),
      statusCode: response.statusCode,
    );
  } on TimeoutException {
    return LoginFailure(message: _kNetworkErrorMessage);
  } on http.ClientException {
    return LoginFailure(message: _kNetworkErrorMessage);
  } catch (_) {
    return LoginFailure(message: _kGenericErrorMessage);
  }
}

Map<String, dynamic>? _parseJson(String body) {
  try {
    return body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : null;
  } catch (_) {
    return null;
  }
}

String _errorMessage(http.Response response) {
  final body = response.body;
  if (body.isEmpty) return 'Request failed (${response.statusCode})';
  try {
    final m = jsonDecode(body);
    if (m is Map) {
      final msg = m['message'];
      if (msg != null) {
        final s = msg is String ? msg : '$msg';
        if (s.isNotEmpty) return s;
      }
    }
  } catch (_) {}
  return 'Request failed (${response.statusCode})';
}

// ==================== GET /api/auth/me ====================

/// Result of GET /api/auth/me.
sealed class GetMeResult {}

class GetMeSuccess extends GetMeResult {
  final AuthMeResponse data;
  GetMeSuccess(this.data);
}

class GetMeFailure extends GetMeResult {
  final String message;
  final int? statusCode;
  GetMeFailure({required this.message, this.statusCode});
}

/// GET /api/auth/me — returns user + role-specific profile. Requires Bearer token.
/// Call after login and on app start when token exists.
Future<GetMeResult> getMe() async {
  final uri = apiUrl('api/auth/me');
  try {
    final response = await ApiClient().get(uri);
    if (response.statusCode == 401) {
      return GetMeFailure(message: 'Unauthorized', statusCode: 401);
    }
    if (response.statusCode == 404) {
      return GetMeFailure(
        message: 'Your account is missing profile data. Contact your admin.',
        statusCode: 404,
      );
    }
    if (response.statusCode != 200) {
      return GetMeFailure(
        message: _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    final data = _parseJson(response.body);
    if (data == null || data is! Map<String, dynamic>) {
      return GetMeFailure(message: 'Invalid response from server');
    }
    final userJson = data['user'];
    if (userJson == null || userJson is! Map<String, dynamic>) {
      return GetMeFailure(message: 'Invalid response: user missing');
    }
    final user = AuthUser.fromJson(userJson);
    final profileJson = data['profile'];
    final profile = parseProfileByRole(user.role, profileJson);
    return GetMeSuccess(AuthMeResponse(user: user, profile: profile));
  } catch (_) {
    return GetMeFailure(message: _kGenericErrorMessage);
  }
}
