import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/teachers_service.dart';

const String _base = 'api/school-admin';

// ==================== HELPERS ====================
int _parseId(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
String _str(dynamic v) => v == null ? '' : v.toString().trim();
String? _strOpt(dynamic v) => v == null ? null : v.toString().trim();

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

List<dynamic> _extractList(dynamic raw, List<String> keys) {
  if (raw is List) return raw;
  if (raw is! Map) return [];
  for (final k in keys) {
    if (raw[k] is List) return raw[k] as List<dynamic>;
  }
  // Nested: data.subjects, data.teachers, data.items
  final data = raw['data'];
  if (data is Map) {
    for (final k in keys) {
      if (data[k] is List) return data[k] as List<dynamic>;
    }
    if (data['items'] is List) return data['items'] as List<dynamic>;
  }
  for (final value in raw.values) {
    if (value is List) return value;
  }
  return [];
}

void devLogResponse(String context, int statusCode, String body) {
  print('[$context] API response: status=$statusCode body=${body.length > 500 ? "${body.substring(0, 500)}..." : body}');
}

// ==================== MODELS ====================

/// Assignment: { id, teacher: { id, fullName, email }, class: { id, name }, subject: { id, name } }
class AssignmentModel {
  final int id;
  final Map<String, dynamic> teacher;
  final Map<String, dynamic> class_;
  final Map<String, dynamic> subject;

  AssignmentModel({
    required this.id,
    required this.teacher,
    required this.class_,
    required this.subject,
  });

  int get teacherId => _parseId(teacher['id']);
  String get teacherName => _str(teacher['fullName'] ?? teacher['full_name'] ?? teacher['name']);
  String? get teacherEmail => _strOpt(teacher['email']);
  int get classId => _parseId(class_['id']);
  String get className => _str(class_['name']);
  int get subjectId => _parseId(subject['id']);
  String get subjectName => _str(subject['name']);

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final t = json['teacher'] ?? json['Teacher'];
    final c = json['class'] ?? json['Class'] ?? json['class_'];
    final s = json['subject'] ?? json['Subject'] ?? json['subject_'];
    return AssignmentModel(
      id: _parseId(json['id']),
      teacher: t is Map<String, dynamic> ? t : {'id': 0, 'fullName': '', 'email': ''},
      class_: c is Map<String, dynamic> ? c : {'id': 0, 'name': ''},
      subject: s is Map<String, dynamic> ? s : {'id': 0, 'name': ''},
    );
  }
}

/// SubjectsResponse: { subjects: [ { id, name } ] }
class ClassSubjectItem {
  final int id;
  final String name;

  ClassSubjectItem({required this.id, required this.name});

  factory ClassSubjectItem.fromJson(Map<String, dynamic> json) {
    return ClassSubjectItem(
      id: _parseId(json['id'] ?? json['subject_id']),
      name: _str(json['name'] ?? json['subject_name'] ?? json['subjectName']),
    );
  }
}

/// TeachersResponse: { teachers: [ { id, fullName, email } ] } — reuse TeacherModel from teachers_service
// We use TeacherModel.fromJson for listClassSubjectTeachers.

// ==================== RESULT TYPES ====================
sealed class AssignmentResult<T> {}
class AssignmentSuccess<T> extends AssignmentResult<T> {
  final T data;
  AssignmentSuccess(this.data);
}
class AssignmentError extends AssignmentResult<Never> {
  final String message;
  final int? statusCode;
  AssignmentError(this.message, [this.statusCode]);
}

// ==================== SERVICE ====================
final _client = ApiClient();

class SchoolAdminAssignmentsService {
  SchoolAdminAssignmentsService._();
  static final SchoolAdminAssignmentsService _instance = SchoolAdminAssignmentsService._();
  factory SchoolAdminAssignmentsService() => _instance;

  /// GET /api/school-admin/assignments?teacher_id=&class_id=&subject_id=
  Future<AssignmentResult<List<AssignmentModel>>> listAssignments({
    int? teacherId,
    int? classId,
    int? subjectId,
  }) async {
    try {
      final params = <String, String>{};
      if (teacherId != null && teacherId > 0) params['teacher_id'] = teacherId.toString();
      if (classId != null && classId > 0) params['class_id'] = classId.toString();
      if (subjectId != null && subjectId > 0) params['subject_id'] = subjectId.toString();
      final uri = params.isEmpty
          ? apiUrl('$_base/assignments')
          : apiUrl('$_base/assignments').replace(queryParameters: params);
      final response = await _client.get(uri);
      devLogResponse('SchoolAdminAssignmentsService.listAssignments', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return AssignmentError(_errorMessage(response) ?? 'Could not load assignments.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['assignments', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => AssignmentModel.fromJson(e)).toList();
      return AssignmentSuccess(items);
    } catch (e, st) {
      return AssignmentError(userFriendlyMessage(e, st, 'SchoolAdminAssignmentsService.listAssignments'));
    }
  }

  /// GET /api/school-admin/assignments/{id}
  Future<AssignmentResult<AssignmentModel>> getAssignment(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/assignments/$id'));
      devLogResponse('SchoolAdminAssignmentsService.getAssignment', response.statusCode, response.body);
      if (response.statusCode == 404) return AssignmentError('Assignment not found.', 404);
      if (response.statusCode != 200) {
        return AssignmentError(_errorMessage(response) ?? 'Could not load assignment.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final map = raw is Map ? (raw['assignment'] ?? raw['data'] ?? raw) : null;
      if (map is! Map<String, dynamic>) return AssignmentError('Invalid response.');
      return AssignmentSuccess(AssignmentModel.fromJson(map));
    } catch (e, st) {
      return AssignmentError(userFriendlyMessage(e, st, 'SchoolAdminAssignmentsService.getAssignment'));
    }
  }

  /// POST /api/school-admin/assignments  Body: { teacher_id, class_id, subject_id }
  Future<AssignmentResult<AssignmentModel>> createAssignment({
    required int teacherId,
    required int classId,
    required int subjectId,
  }) async {
    try {
      final body = {
        'teacher_id': teacherId,
        'class_id': classId,
        'subject_id': subjectId,
      };
      final response = await _client.post(apiUrl('$_base/assignments'), body: body);
      devLogResponse('SchoolAdminAssignmentsService.createAssignment', response.statusCode, response.body);
      if (response.statusCode == 409) {
        return AssignmentError(_errorMessage(response) ?? 'Assignment already exists.', 409);
      }
      if (response.statusCode == 404) {
        return AssignmentError(_errorMessage(response) ?? 'Teacher, class or subject not found.', 404);
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        return AssignmentError(_errorMessage(response) ?? 'Could not create assignment.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final map = raw is Map ? (raw['assignment'] ?? raw['data'] ?? raw) : null;
      if (map is! Map<String, dynamic>) return AssignmentError('Invalid response.');
      return AssignmentSuccess(AssignmentModel.fromJson(map));
    } catch (e, st) {
      return AssignmentError(userFriendlyMessage(e, st, 'SchoolAdminAssignmentsService.createAssignment'));
    }
  }

  /// DELETE /api/school-admin/assignments/{id}
  Future<AssignmentResult<void>> deleteAssignment(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/assignments/$id'));
      devLogResponse('SchoolAdminAssignmentsService.deleteAssignment', response.statusCode, response.body);
      if (response.statusCode == 404) return AssignmentError('Assignment not found.', 404);
      if (response.statusCode != 200 && response.statusCode != 204) {
        return AssignmentError(_errorMessage(response) ?? 'Could not delete assignment.', response.statusCode);
      }
      return AssignmentSuccess(null);
    } catch (e, st) {
      return AssignmentError(userFriendlyMessage(e, st, 'SchoolAdminAssignmentsService.deleteAssignment'));
    }
  }

  /// GET /api/school-admin/classes/{class_id}/subjects
  Future<AssignmentResult<List<ClassSubjectItem>>> listClassSubjects(int classId) async {
    try {
      final response = await _client.get(apiUrl('$_base/classes/$classId/subjects'));
      devLogResponse('SchoolAdminAssignmentsService.listClassSubjects', response.statusCode, response.body);
      if (response.statusCode == 404) return AssignmentError('Class not found.', 404);
      if (response.statusCode != 200) {
        return AssignmentError(_errorMessage(response) ?? 'Could not load subjects for class.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['subjects', 'assignments', 'data', 'items']);
      final items = <ClassSubjectItem>[];
      final seenIds = <int>{};
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          final subjectMap = e['subject'] ?? e['Subject'] ?? e;
          if (subjectMap is Map<String, dynamic>) {
            final item = ClassSubjectItem.fromJson(subjectMap);
            if (item.id > 0 && seenIds.add(item.id)) items.add(item);
          } else {
            final item = ClassSubjectItem.fromJson(e);
            if (item.id > 0 && seenIds.add(item.id)) items.add(item);
          }
        }
      }
      return AssignmentSuccess(items);
    } catch (e, st) {
      return AssignmentError(userFriendlyMessage(e, st, 'SchoolAdminAssignmentsService.listClassSubjects'));
    }
  }

  /// GET /api/school-admin/classes/{class_id}/subjects/{subject_id}/teachers
  Future<AssignmentResult<List<TeacherModel>>> listClassSubjectTeachers(int classId, int subjectId) async {
    try {
      final response = await _client.get(apiUrl('$_base/classes/$classId/subjects/$subjectId/teachers'));
      devLogResponse('SchoolAdminAssignmentsService.listClassSubjectTeachers', response.statusCode, response.body);
      if (response.statusCode == 404) return AssignmentError('Class or subject not found.', 404);
      if (response.statusCode != 200) {
        return AssignmentError(_errorMessage(response) ?? 'Could not load teachers for class/subject.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['teachers', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => TeacherModel.fromJson(e)).toList();
      return AssignmentSuccess(items);
    } catch (e, st) {
      return AssignmentError(userFriendlyMessage(e, st, 'SchoolAdminAssignmentsService.listClassSubjectTeachers'));
    }
  }
}
