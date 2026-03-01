import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/students_service.dart';

/// Linked student summary (from parent's linked_students or students array).
class LinkedStudentRef {
  final int id;
  final String studentName;
  final String? emisNumber;
  final String? className;

  const LinkedStudentRef({
    required this.id,
    required this.studentName,
    this.emisNumber,
    this.className,
  });

  factory LinkedStudentRef.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    return LinkedStudentRef(
      id: parseId(json['id']),
      studentName: str(json['studentName'] ?? json['student_name']),
      emisNumber: strOpt(json['emisNumber'] ?? json['emis_number']),
      className: strOpt(json['className'] ?? json['class_name']),
    );
  }
}

/// Parent model (school-admin scope).
class ParentModel {
  final int id;
  final String name;
  final String email;
  final List<LinkedStudentRef> linkedStudents;

  const ParentModel({
    required this.id,
    required this.name,
    required this.email,
    this.linkedStudents = const [],
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    List<LinkedStudentRef> students = [];
    final raw = json['linked_students'] ?? json['linkedStudents'] ?? json['students'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          try {
            students.add(LinkedStudentRef.fromJson(e));
          } catch (_) {}
        }
      }
    }
    return ParentModel(
      id: parseId(json['id']),
      name: str(json['name']),
      email: str(json['email']),
      linkedStudents: students,
    );
  }
}

sealed class ParentResult<T> {}

class ParentSuccess<T> extends ParentResult<T> {
  final T data;
  ParentSuccess(this.data);
}

class ParentError extends ParentResult<Never> {
  final String message;
  final int? statusCode;
  ParentError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/parents';

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

class ParentsService {
  ParentsService._();
  static final ParentsService _instance = ParentsService._();
  factory ParentsService() => _instance;

  /// POST /api/school-admin/parents
  Future<ParentResult<ParentModel>> createParent({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final body = {'name': name, 'email': email, 'password': password};
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('ParentsService.createParent', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return ParentError('Invalid response from server. Please try again.');
        final m = raw as Map<String, dynamic>;
        final parentMap = m['parent'] ?? m;
        if (parentMap is! Map<String, dynamic>) return ParentError('Invalid response from server. Please try again.');
        return ParentSuccess(ParentModel.fromJson(parentMap));
      }
      if (response.statusCode == 409) return ParentError('Email already exists', 409);
      if (response.statusCode == 400) return ParentError(_errorMessage(response) ?? 'Invalid data. Please check and try again.', 400);
      return ParentError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return ParentError(userFriendlyMessage(e, st, 'ParentsService.createParent'));
    }
  }

  /// GET /api/school-admin/parents
  Future<ParentResult<List<ParentModel>>> listParents() async {
    try {
      final response = await _client.get(apiUrl(_base));
      devLogResponse('ParentsService.listParents', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return ParentError(_errorMessage(response) ?? 'Could not load parents. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['data'] is List) {
          list = raw['data'] as List<dynamic>;
        } else if (raw['parents'] is List) {
          list = raw['parents'] as List<dynamic>;
        } else {
          return ParentError(_errorMessage(response) ?? 'Invalid response from server. Please try again.');
        }
      } else {
        return ParentError('Invalid response from server. Please try again.');
      }
      final parents = <ParentModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            parents.add(ParentModel.fromJson(e));
          } catch (_) {}
        }
      }
      return ParentSuccess(parents);
    } catch (e, st) {
      return ParentError(userFriendlyMessage(e, st, 'ParentsService.listParents'));
    }
  }

  /// GET /api/school-admin/parents/{id}
  Future<ParentResult<ParentModel>> getParent(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('ParentsService.getParent', response.statusCode, response.body);
      if (response.statusCode == 404) return ParentError('Parent not found.', 404);
      if (response.statusCode != 200) {
        return ParentError(_errorMessage(response) ?? 'Could not load parent. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['parent'] as Map<String, dynamic>? ?? raw;
      } else {
        return ParentError('Invalid response from server. Please try again.');
      }
      return ParentSuccess(ParentModel.fromJson(map));
    } catch (e, st) {
      return ParentError(userFriendlyMessage(e, st, 'ParentsService.getParent'));
    }
  }

  /// PATCH /api/school-admin/parents/{id}
  Future<ParentResult<ParentModel>> updateParent(int id, Map<String, dynamic> body) async {
    try {
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('ParentsService.updateParent', response.statusCode, response.body);
      if (response.statusCode == 404) return ParentError('Parent not found.', 404);
      if (response.statusCode == 409) return ParentError('Email already exists', 409);
      if (response.statusCode != 200) {
        return ParentError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['parent'] as Map<String, dynamic>? ?? raw;
      } else {
        return ParentError('Invalid response from server. Please try again.');
      }
      return ParentSuccess(ParentModel.fromJson(map));
    } catch (e, st) {
      return ParentError(userFriendlyMessage(e, st, 'ParentsService.updateParent'));
    }
  }

  /// DELETE /api/school-admin/parents/{id}
  Future<ParentResult<bool>> deleteParent(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('ParentsService.deleteParent', response.statusCode, response.body);
      if (response.statusCode == 404) return ParentError('Parent not found.', 404);
      if (response.statusCode != 200) {
        return ParentError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return ParentSuccess(true);
    } catch (e, st) {
      return ParentError(userFriendlyMessage(e, st, 'ParentsService.deleteParent'));
    }
  }

  /// POST /api/school-admin/parents/link-student
  Future<ParentResult<bool>> linkStudent({required int parentId, required int studentId}) async {
    try {
      final body = {'parent_id': parentId, 'student_id': studentId};
      final response = await _client.post(apiUrl('$_base/link-student'), body: body);
      devLogResponse('ParentsService.linkStudent', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return ParentError(_errorMessage(response) ?? 'Could not link. Please try again.', response.statusCode);
      }
      return ParentSuccess(true);
    } catch (e, st) {
      return ParentError(userFriendlyMessage(e, st, 'ParentsService.linkStudent'));
    }
  }

  /// DELETE /api/school-admin/parents/link-student (with body)
  Future<ParentResult<bool>> unlinkStudent({required int parentId, required int studentId}) async {
    try {
      final body = {'parent_id': parentId, 'student_id': studentId};
      final response = await _client.deleteWithBody(apiUrl('$_base/link-student'), body: body);
      devLogResponse('ParentsService.unlinkStudent', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return ParentError(_errorMessage(response) ?? 'Could not unlink. Please try again.', response.statusCode);
      }
      return ParentSuccess(true);
    } catch (e, st) {
      return ParentError(userFriendlyMessage(e, st, 'ParentsService.unlinkStudent'));
    }
  }
}
