import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Class model (school-admin scope). API returns id and name.
class ClassModel {
  final int id;
  final String name;

  const ClassModel({required this.id, required this.name});

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    return ClassModel(
      id: parseId(json['id'] ?? json['class_id']),
      name: str(json['name'] ?? json['class_name'] ?? json['className']),
    );
  }
}

sealed class ClassResult<T> {}

class ClassSuccess<T> extends ClassResult<T> {
  final T data;
  ClassSuccess(this.data);
}

class ClassError extends ClassResult<Never> {
  final String message;
  final int? statusCode;
  ClassError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/classes';

dynamic _parseJson(String body) {
  try {
    return body.isNotEmpty ? jsonDecode(body) : null;
  } catch (_) {
    return null;
  }
}

String? _errorMessage(http.Response response) {
  if (response.body.isEmpty) return null;
  try {
    final m = jsonDecode(response.body);
    if (m is Map && m['message'] != null) return m['message'] as String;
    if (m is Map && m['error'] != null) return m['error'] as String;
  } catch (_) {}
  return null;
}

class ClassesService {
  ClassesService._();
  static final ClassesService _instance = ClassesService._();
  factory ClassesService() => _instance;

  /// POST /api/school-admin/classes  Body: { "name": "string" }
  Future<ClassResult<ClassModel>> createClass(Map<String, dynamic> data) async {
    try {
      final body = {'name': data['name'] is String ? data['name'] as String : data['name'].toString()};
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('ClassesService.createClass', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return ClassError('Invalid response from server. Please try again.');
        final m = raw as Map<String, dynamic>;
        final classMap = m['class'] ?? m['data'] ?? m;
        if (classMap is! Map<String, dynamic>) return ClassError('Invalid response from server. Please try again.');
        return ClassSuccess(ClassModel.fromJson(classMap));
      }
      if (response.statusCode == 400) return ClassError(_errorMessage(response) ?? 'Invalid data. Please try again.', 400);
      return ClassError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return ClassError(userFriendlyMessage(e, st, 'ClassesService.createClass'));
    }
  }

  /// GET /api/school-admin/classes
  Future<ClassResult<List<ClassModel>>> listClasses() async {
    try {
      final response = await _client.get(apiUrl(_base));
      devLogResponse('ClassesService.listClasses', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return ClassError(_errorMessage(response) ?? 'Could not load classes. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          // Nested: { "data": { "classes": [...] } } or { "data": { "items": [...] } }
          list = data['classes'] as List<dynamic>? ??
              data['items'] as List<dynamic>? ??
              data['data'] as List<dynamic>? ??
              [];
        } else if (raw['classes'] is List) {
          list = raw['classes'] as List<dynamic>;
        } else if (raw['items'] is List) {
          list = raw['items'] as List<dynamic>;
        } else {
          // Fallback: use first list value in the map (e.g. "result", "list", etc.)
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) {
              found = value as List<dynamic>;
              break;
            }
          }
          if (found == null) {
            return ClassError(_errorMessage(response) ?? 'Invalid response from server. Please try again.');
          }
          list = found;
        }
      } else {
        return ClassError('Invalid response from server. Please try again.');
      }
      final classes = <ClassModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            classes.add(ClassModel.fromJson(e));
          } catch (_) {}
        }
      }
      return ClassSuccess(classes);
    } catch (e, st) {
      return ClassError(userFriendlyMessage(e, st, 'ClassesService.listClasses'));
    }
  }

  /// GET /api/school-admin/classes/{id}
  Future<ClassResult<ClassModel>> getClass(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('ClassesService.getClass', response.statusCode, response.body);
      if (response.statusCode == 404) return ClassError('Class not found.', 404);
      if (response.statusCode != 200) {
        return ClassError(_errorMessage(response) ?? 'Could not load class. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['class'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return ClassError('Invalid response from server. Please try again.');
      }
      return ClassSuccess(ClassModel.fromJson(map));
    } catch (e, st) {
      return ClassError(userFriendlyMessage(e, st, 'ClassesService.getClass'));
    }
  }

  /// PATCH /api/school-admin/classes/{id}  Body: { "name": "string" }
  Future<ClassResult<ClassModel>> updateClass(int id, Map<String, dynamic> data) async {
    try {
      final body = {'name': data['name'] is String ? data['name'] as String : data['name'].toString()};
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('ClassesService.updateClass', response.statusCode, response.body);
      if (response.statusCode == 404) return ClassError('Class not found.', 404);
      if (response.statusCode != 200) {
        return ClassError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['class'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return ClassError('Invalid response from server. Please try again.');
      }
      return ClassSuccess(ClassModel.fromJson(map));
    } catch (e, st) {
      return ClassError(userFriendlyMessage(e, st, 'ClassesService.updateClass'));
    }
  }

  /// DELETE /api/school-admin/classes/{id}
  Future<ClassResult<bool>> deleteClass(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('ClassesService.deleteClass', response.statusCode, response.body);
      if (response.statusCode == 404) return ClassError('Class not found.', 404);
      if (response.statusCode != 200) {
        return ClassError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return ClassSuccess(true);
    } catch (e, st) {
      return ClassError(userFriendlyMessage(e, st, 'ClassesService.deleteClass'));
    }
  }
}
