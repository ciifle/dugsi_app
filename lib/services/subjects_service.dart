import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Subject model (school-admin scope). API returns id and name.
class SubjectModel {
  final int id;
  final String name;

  const SubjectModel({required this.id, required this.name});

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    return SubjectModel(
      id: parseId(json['id'] ?? json['subject_id']),
      name: str(json['name'] ?? json['subject_name'] ?? json['subjectName']),
    );
  }
}

sealed class SubjectResult<T> {}

class SubjectSuccess<T> extends SubjectResult<T> {
  final T data;
  SubjectSuccess(this.data);
}

class SubjectError extends SubjectResult<Never> {
  final String message;
  final int? statusCode;
  SubjectError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/subjects';

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

class SubjectsService {
  SubjectsService._();
  static final SubjectsService _instance = SubjectsService._();
  factory SubjectsService() => _instance;

  /// POST /api/school-admin/subjects  Body: { "name": "string" }
  Future<SubjectResult<SubjectModel>> createSubject(Map<String, dynamic> data) async {
    try {
      final body = {'name': data['name'] is String ? data['name'] as String : data['name'].toString()};
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('SubjectsService.createSubject', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return SubjectError('Invalid response from server. Please try again.');
        final m = raw as Map<String, dynamic>;
        final subjectMap = m['subject'] ?? m['data'] ?? m;
        if (subjectMap is! Map<String, dynamic>) return SubjectError('Invalid response from server. Please try again.');
        return SubjectSuccess(SubjectModel.fromJson(subjectMap));
      }
      if (response.statusCode == 400) return SubjectError(_errorMessage(response) ?? 'Invalid data. Please try again.', 400);
      return SubjectError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return SubjectError(userFriendlyMessage(e, st, 'SubjectsService.createSubject'));
    }
  }

  /// GET /api/school-admin/subjects
  Future<SubjectResult<List<SubjectModel>>> listSubjects() async {
    try {
      final response = await _client.get(apiUrl(_base));
      devLogResponse('SubjectsService.listSubjects', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return SubjectError(_errorMessage(response) ?? 'Could not load subjects. Please try again.', response.statusCode);
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
          list = data['subjects'] as List<dynamic>? ??
              data['items'] as List<dynamic>? ??
              data['data'] as List<dynamic>? ??
              [];
        } else if (raw['subjects'] is List) {
          list = raw['subjects'] as List<dynamic>;
        } else if (raw['items'] is List) {
          list = raw['items'] as List<dynamic>;
        } else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) {
              found = value as List<dynamic>;
              break;
            }
          }
          if (found == null) {
            return SubjectError(_errorMessage(response) ?? 'Invalid response from server. Please try again.');
          }
          list = found;
        }
      } else {
        return SubjectError('Invalid response from server. Please try again.');
      }
      final subjects = <SubjectModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            subjects.add(SubjectModel.fromJson(e));
          } catch (_) {}
        }
      }
      return SubjectSuccess(subjects);
    } catch (e, st) {
      return SubjectError(userFriendlyMessage(e, st, 'SubjectsService.listSubjects'));
    }
  }

  /// GET /api/school-admin/subjects/{id}
  Future<SubjectResult<SubjectModel>> getSubject(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('SubjectsService.getSubject', response.statusCode, response.body);
      if (response.statusCode == 404) return SubjectError('Subject not found.', 404);
      if (response.statusCode != 200) {
        return SubjectError(_errorMessage(response) ?? 'Could not load subject. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['subject'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return SubjectError('Invalid response from server. Please try again.');
      }
      return SubjectSuccess(SubjectModel.fromJson(map));
    } catch (e, st) {
      return SubjectError(userFriendlyMessage(e, st, 'SubjectsService.getSubject'));
    }
  }

  /// PATCH /api/school-admin/subjects/{id}  Body: { "name": "string" }
  Future<SubjectResult<SubjectModel>> updateSubject(int id, Map<String, dynamic> data) async {
    try {
      final body = {'name': data['name'] is String ? data['name'] as String : data['name'].toString()};
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('SubjectsService.updateSubject', response.statusCode, response.body);
      if (response.statusCode == 404) return SubjectError('Subject not found.', 404);
      if (response.statusCode != 200) {
        return SubjectError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['subject'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return SubjectError('Invalid response from server. Please try again.');
      }
      return SubjectSuccess(SubjectModel.fromJson(map));
    } catch (e, st) {
      return SubjectError(userFriendlyMessage(e, st, 'SubjectsService.updateSubject'));
    }
  }

  /// PUT /api/school-admin/subjects/{id}  Body: { "name": "string" }
  Future<SubjectResult<SubjectModel>> replaceSubject(int id, Map<String, dynamic> data) async {
    try {
      final body = {'name': data['name'] is String ? data['name'] as String : data['name'].toString()};
      final response = await _client.put(apiUrl('$_base/$id'), body: body);
      devLogResponse('SubjectsService.replaceSubject', response.statusCode, response.body);
      if (response.statusCode == 404) return SubjectError('Subject not found.', 404);
      if (response.statusCode != 200) {
        return SubjectError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['subject'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return SubjectError('Invalid response from server. Please try again.');
      }
      return SubjectSuccess(SubjectModel.fromJson(map));
    } catch (e, st) {
      return SubjectError(userFriendlyMessage(e, st, 'SubjectsService.replaceSubject'));
    }
  }

  /// DELETE /api/school-admin/subjects/{id}
  Future<SubjectResult<bool>> deleteSubject(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('SubjectsService.deleteSubject', response.statusCode, response.body);
      if (response.statusCode == 404) return SubjectError('Subject not found.', 404);
      if (response.statusCode != 200) {
        return SubjectError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return SubjectSuccess(true);
    } catch (e, st) {
      return SubjectError(userFriendlyMessage(e, st, 'SubjectsService.deleteSubject'));
    }
  }
}
