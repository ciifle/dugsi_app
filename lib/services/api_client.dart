import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL for Dugsi API. Use API_URL in production web (e.g. https://api.dugsi.so).
/// Build with: flutter build web --dart-define=API_URL=https://api.dugsi.so
final String kApiBaseUrl = const String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api.dugsi.so',
);

/// Global callback when any request returns 401 (clear session + redirect to Login).
void Function()? onUnauthorized;

/// API client with base URL, default headers, and optional Bearer token.
/// On 401, calls [onUnauthorized] if set (e.g. clear session and navigate to Login).
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  String? _token;

  String? get token => _token;

  void setToken(String? value) {
    _token = value;
  }

  /// Default headers for all requests.
  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  /// GET request.
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await http.get(
      url,
      headers: {..._defaultHeaders, ...?headers},
    );
    _handleStatus(response);
    return response;
  }

  /// POST request.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final response = await http.post(
      url,
      headers: {..._defaultHeaders, ...?headers},
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
      encoding: encoding,
    );
    _handleStatus(response);
    return response;
  }

  /// PATCH request.
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final response = await http.patch(
      url,
      headers: {..._defaultHeaders, ...?headers},
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
      encoding: encoding,
    );
    _handleStatus(response);
    return response;
  }

  /// PUT request.
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final response = await http.put(
      url,
      headers: {..._defaultHeaders, ...?headers},
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
      encoding: encoding,
    );
    _handleStatus(response);
    return response;
  }

  /// DELETE request.
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    final response = await http.delete(
      url,
      headers: {..._defaultHeaders, ...?headers},
    );
    _handleStatus(response);
    return response;
  }

  /// DELETE request with JSON body (e.g. for unlink parent-student).
  Future<http.Response> deleteWithBody(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final request = http.Request('DELETE', url);
    request.headers.addAll({..._defaultHeaders, ...?headers});
    if (body != null) {
      request.body = body is String ? body : jsonEncode(body);
      request.headers['Content-Type'] = 'application/json';
    }
    final streamedResponse = await http.Client().send(request);
    final response = await http.Response.fromStream(streamedResponse);
    _handleStatus(response);
    return response;
  }

  void _handleStatus(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
  }
}

/// Build full URL for an API path (e.g. /api/auth/login).
Uri apiUrl(String path) {
  final base = kApiBaseUrl.endsWith('/') ? kApiBaseUrl : '$kApiBaseUrl/';
  final p = path.startsWith('/') ? path.substring(1) : path;
  return Uri.parse('$base$p');
}
