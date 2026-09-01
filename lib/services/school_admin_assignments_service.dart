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

/// Returns a backend-provided error message, but never a raw database/HTML
/// failure (e.g. driver/SQL errors) — those fall back to null so callers use
/// their own clean, user-facing default message instead.
String? _errorMessage(http.Response response) {
  if (response.body.isEmpty) return null;
  try {
    final m = jsonDecode(response.body);
    String? raw;
    if (m is Map && m['message'] != null) raw = m['message'] as String;
    if (raw == null && m is Map && m['error'] != null) {
      raw = m['error'] as String;
    }
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    final looksLikeRawServerError =
        lower.contains('<html') ||
        lower.contains('sql') ||
        lower.contains('unknown column') ||
        lower.contains('stack trace') ||
        lower.contains('exception') ||
        lower.contains('at line ');
    return looksLikeRawServerError ? null : raw;
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
  print(
    '[$context] API response: status=$statusCode body=${body.length > 500 ? "${body.substring(0, 500)}..." : body}',
  );
}

// ==================== MODELS ====================

/// Assignment: { id, teacher: { id, fullName, email }, class: { id, name },
/// subject: { id, name }, academic_year_id, academic_year: { id, name } }
class AssignmentModel {
  final int id;
  final Map<String, dynamic> teacher;
  final Map<String, dynamic> class_;
  final Map<String, dynamic> subject;
  final int academicYearId;
  final Map<String, dynamic>? academicYear;

  AssignmentModel({
    required this.id,
    required this.teacher,
    required this.class_,
    required this.subject,
    this.academicYearId = 0,
    this.academicYear,
  });

  int get teacherId => _parseId(teacher['id']);
  String get teacherName =>
      _str(teacher['fullName'] ?? teacher['full_name'] ?? teacher['name']);
  String? get teacherEmail => _strOpt(teacher['email']);
  int get classId => _parseId(class_['id']);
  String get className => _str(class_['name']);
  int get subjectId => _parseId(subject['id']);
  String get subjectName => _str(subject['name']);
  String get academicYearName {
    final name = academicYear?['name'];
    return name == null ? '' : _str(name);
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final t = json['teacher'] ?? json['Teacher'];
    final c = json['class'] ?? json['Class'] ?? json['class_'];
    final s = json['subject'] ?? json['Subject'] ?? json['subject_'];
    final ay =
        json['academic_year'] ?? json['academicYear'] ?? json['AcademicYear'];
    return AssignmentModel(
      id: _parseId(json['id']),
      teacher: t is Map<String, dynamic>
          ? t
          : {'id': 0, 'fullName': '', 'email': ''},
      class_: c is Map<String, dynamic> ? c : {'id': 0, 'name': ''},
      subject: s is Map<String, dynamic> ? s : {'id': 0, 'name': ''},
      academicYearId: _parseId(
        json['academic_year_id'] ?? json['academicYearId'] ?? ay?['id'],
      ),
      academicYear: ay is Map<String, dynamic> ? ay : null,
    );
  }
}

/// SubjectsResponse: { subjects: [ { id, name, is_exam_subject } ] }
class ClassSubjectItem {
  final int id;
  final String name;

  /// Whether this class subject participates in exams/grading. Defaults to
  /// `true` when absent, matching the backend's own default so legacy rows
  /// without the field are treated as exam subjects.
  final bool isExamSubject;

  ClassSubjectItem({
    required this.id,
    required this.name,
    this.isExamSubject = true,
  });

  factory ClassSubjectItem.fromJson(Map<String, dynamic> json) {
    bool parseExamFlag(dynamic v) {
      if (v == null) return true;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return true;
    }

    return ClassSubjectItem(
      id: _parseId(json['id'] ?? json['subject_id']),
      name: _str(json['name'] ?? json['subject_name'] ?? json['subjectName']),
      isExamSubject: parseExamFlag(
        json['is_exam_subject'] ?? json['isExamSubject'],
      ),
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

class BulkAssignmentResponse {
  final int createdCount;
  final List<AssignmentModel> assignments;
  const BulkAssignmentResponse({
    required this.createdCount,
    required this.assignments,
  });
}

// ==================== SERVICE ====================
final _client = ApiClient();

class SchoolAdminAssignmentsService {
  SchoolAdminAssignmentsService._();
  static final SchoolAdminAssignmentsService _instance =
      SchoolAdminAssignmentsService._();
  factory SchoolAdminAssignmentsService() => _instance;

  /// GET /api/school-admin/assignments?teacher_id=&class_id=&subject_id=&academic_year_id=
  Future<AssignmentResult<List<AssignmentModel>>> listAssignments({
    int? teacherId,
    int? classId,
    int? subjectId,
    int? academicYearId,
  }) async {
    try {
      final params = <String, String>{};
      if (teacherId != null && teacherId > 0)
        params['teacher_id'] = teacherId.toString();
      if (classId != null && classId > 0)
        params['class_id'] = classId.toString();
      if (subjectId != null && subjectId > 0)
        params['subject_id'] = subjectId.toString();
      if (academicYearId != null && academicYearId > 0)
        params['academic_year_id'] = academicYearId.toString();
      final uri = params.isEmpty
          ? apiUrl('$_base/assignments')
          : apiUrl('$_base/assignments').replace(queryParameters: params);
      final response = await _client.get(uri);
      devLogResponse(
        'SchoolAdminAssignmentsService.listAssignments',
        response.statusCode,
        response.body,
      );
      if (response.statusCode != 200) {
        return AssignmentError(
          _errorMessage(response) ??
              'Unable to load assignments. Please try again.',
          response.statusCode,
        );
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['assignments', 'data', 'items']);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map((e) => AssignmentModel.fromJson(e))
          .toList();
      return AssignmentSuccess(items);
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.listAssignments',
        ),
      );
    }
  }

  /// GET /api/school-admin/assignments/{id}
  Future<AssignmentResult<AssignmentModel>> getAssignment(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/assignments/$id'));
      devLogResponse(
        'SchoolAdminAssignmentsService.getAssignment',
        response.statusCode,
        response.body,
      );
      if (response.statusCode == 404)
        return AssignmentError('Assignment not found.', 404);
      if (response.statusCode != 200) {
        return AssignmentError(
          _errorMessage(response) ?? 'Could not load assignment.',
          response.statusCode,
        );
      }
      final raw = _parseJson(response.body);
      final map = raw is Map ? (raw['assignment'] ?? raw['data'] ?? raw) : null;
      if (map is! Map<String, dynamic>)
        return AssignmentError('Invalid response.');
      return AssignmentSuccess(AssignmentModel.fromJson(map));
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.getAssignment',
        ),
      );
    }
  }

  /// POST /api/school-admin/assignments  Body: { teacher_id, class_id, subject_id, academic_year_id }
  Future<AssignmentResult<AssignmentModel>> createAssignment({
    required int teacherId,
    required int classId,
    required int subjectId,
    required int academicYearId,
  }) async {
    try {
      final body = {
        'teacher_id': teacherId,
        'class_id': classId,
        'subject_id': subjectId,
        'academic_year_id': academicYearId,
      };
      final response = await _client.post(
        apiUrl('$_base/assignments'),
        body: body,
      );
      devLogResponse(
        'SchoolAdminAssignmentsService.createAssignment',
        response.statusCode,
        response.body,
      );
      if (response.statusCode == 409) {
        return AssignmentError(
          _errorMessage(response) ?? 'Assignment already exists.',
          409,
        );
      }
      if (response.statusCode == 404) {
        return AssignmentError(
          _errorMessage(response) ?? 'Teacher, class or subject not found.',
          404,
        );
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        return AssignmentError(
          _errorMessage(response) ?? 'Could not create assignment.',
          response.statusCode,
        );
      }
      final raw = _parseJson(response.body);
      final map = raw is Map ? (raw['assignment'] ?? raw['data'] ?? raw) : null;
      if (map is! Map<String, dynamic>)
        return AssignmentError('Invalid response.');
      return AssignmentSuccess(AssignmentModel.fromJson(map));
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.createAssignment',
        ),
      );
    }
  }

  /// POST /api/school-admin/course-assignments/bulk
  /// Body: { teacher_id, academic_year_id, assignments: [{class_id, subject_id}, ...] }
  Future<AssignmentResult<BulkAssignmentResponse>> createBulkAssignments({
    required int teacherId,
    required int academicYearId,
    required List<Map<String, int>> assignments,
  }) async {
    try {
      final response = await _client.post(
        apiUrl('$_base/course-assignments/bulk'),
        body: {
          'teacher_id': teacherId,
          'academic_year_id': academicYearId,
          'assignments': assignments,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        return AssignmentError(
          _errorMessage(response) ?? 'Could not create teacher assignments.',
          response.statusCode,
        );
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['assignments', 'data', 'items']);
      final values = list
          .whereType<Map>()
          .map(
            (item) => AssignmentModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      final map = raw is Map ? raw : const {};
      final count = _parseId(
        map['created_count'] ?? map['createdCount'] ?? values.length,
      );
      return AssignmentSuccess(
        BulkAssignmentResponse(createdCount: count, assignments: values),
      );
    } catch (error, stack) {
      return AssignmentError(
        userFriendlyMessage(
          error,
          stack,
          'SchoolAdminAssignmentsService.createBulkAssignments',
        ),
      );
    }
  }

  /// PATCH /api/school-admin/assignments/:id
  /// Body: teacher_id (optional), class_id (optional), subject_id (optional).
  /// Response: { "assignment": { id, teacherId, classId, subjectId, Teacher, Class, Subject } }
  Future<AssignmentResult<AssignmentModel>> updateAssignment(
    int id, {
    int? teacherId,
    int? classId,
    int? subjectId,
    int? academicYearId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (teacherId != null && teacherId > 0) body['teacher_id'] = teacherId;
      if (classId != null && classId > 0) body['class_id'] = classId;
      if (subjectId != null && subjectId > 0) body['subject_id'] = subjectId;
      if (academicYearId != null && academicYearId > 0)
        body['academic_year_id'] = academicYearId;
      final response = await _client.patch(
        apiUrl('$_base/assignments/$id'),
        body: body,
      );
      devLogResponse(
        'SchoolAdminAssignmentsService.updateAssignment',
        response.statusCode,
        response.body,
      );
      if (response.statusCode == 404) {
        return AssignmentError(
          _errorMessage(response) ?? 'Assignment not found.',
          404,
        );
      }
      if (response.statusCode == 409) {
        return AssignmentError(
          _errorMessage(response) ?? 'Duplicate assignment.',
          409,
        );
      }
      if (response.statusCode != 200) {
        return AssignmentError(
          _errorMessage(response) ?? 'Could not update assignment.',
          response.statusCode,
        );
      }
      final raw = _parseJson(response.body);
      final map = raw is Map ? (raw['assignment'] ?? raw['data'] ?? raw) : null;
      if (map is! Map<String, dynamic>)
        return AssignmentError('Invalid response.');
      return AssignmentSuccess(AssignmentModel.fromJson(map));
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.updateAssignment',
        ),
      );
    }
  }

  /// DELETE /api/school-admin/assignments/{id}
  Future<AssignmentResult<void>> deleteAssignment(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/assignments/$id'));
      devLogResponse(
        'SchoolAdminAssignmentsService.deleteAssignment',
        response.statusCode,
        response.body,
      );
      if (response.statusCode == 404)
        return AssignmentError('Assignment not found.', 404);
      if (response.statusCode != 200 && response.statusCode != 204) {
        return AssignmentError(
          _errorMessage(response) ?? 'Could not delete assignment.',
          response.statusCode,
        );
      }
      return AssignmentSuccess(null);
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.deleteAssignment',
        ),
      );
    }
  }

  /// DELETE /api/school-admin/assignments/academic-year/{academicYearId}
  /// Deletes every course assignment for the given academic year. Returns the
  /// backend's reported deleted_count when available.
  Future<AssignmentResult<int?>> deleteAssignmentsForYear(
    int academicYearId,
  ) async {
    try {
      final response = await _client.delete(
        apiUrl('$_base/assignments/academic-year/$academicYearId'),
      );
      devLogResponse(
        'SchoolAdminAssignmentsService.deleteAssignmentsForYear',
        response.statusCode,
        response.body,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        return AssignmentError(
          _errorMessage(response) ??
              'Could not reset assignments for this year. Please try again.',
          response.statusCode,
        );
      }
      return AssignmentSuccess(_deletedCount(response));
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.deleteAssignmentsForYear',
        ),
      );
    }
  }

  /// DELETE /api/school-admin/assignments/academic-year/{academicYearId}/teacher/{teacherId}
  /// Deletes a single teacher's course assignments for the given academic
  /// year. Returns the backend's reported deleted_count when available.
  Future<AssignmentResult<int?>> deleteAssignmentsForTeacherYear({
    required int academicYearId,
    required int teacherId,
  }) async {
    try {
      final response = await _client.delete(
        apiUrl(
          '$_base/assignments/academic-year/$academicYearId/teacher/$teacherId',
        ),
      );
      devLogResponse(
        'SchoolAdminAssignmentsService.deleteAssignmentsForTeacherYear',
        response.statusCode,
        response.body,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        return AssignmentError(
          _errorMessage(response) ??
              "Could not clear this teacher's assignments. Please try again.",
          response.statusCode,
        );
      }
      return AssignmentSuccess(_deletedCount(response));
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.deleteAssignmentsForTeacherYear',
        ),
      );
    }
  }

  int? _deletedCount(http.Response response) {
    final raw = _parseJson(response.body);
    if (raw is! Map<String, dynamic>) return null;
    final data = raw['data'];
    final source = data is Map<String, dynamic> ? data : raw;
    final value = source['deleted_count'] ?? source['deletedCount'];
    if (value == null) return null;
    return value is int ? value : int.tryParse(value.toString());
  }

  /// GET /api/school-admin/classes/{class_id}/subjects
  /// Response: { "subjects": [ { "id", "name" } ] } or { "subjects": [] }. Handle empty arrays safely.
  Future<AssignmentResult<List<ClassSubjectItem>>> listClassSubjects(
    int classId,
  ) async {
    try {
      final response = await _client.get(
        apiUrl('$_base/classes/$classId/subjects'),
      );
      devLogResponse(
        'SchoolAdminAssignmentsService.listClassSubjects',
        response.statusCode,
        response.body,
      );
      if (response.statusCode == 404)
        return AssignmentError('Class not found.', 404);
      if (response.statusCode != 200) {
        return AssignmentError(
          _errorMessage(response) ?? 'Could not load subjects for class.',
          response.statusCode,
        );
      }
      final raw = _parseJson(response.body);
      List<dynamic> list = [];
      if (raw is Map && raw['subjects'] is List) {
        list = raw['subjects'] as List<dynamic>;
      } else {
        list = _extractList(raw, ['subjects', 'assignments', 'data', 'items']);
      }
      final items = <ClassSubjectItem>[];
      final seenIds = <int>{};
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          final subjectMap = e['subject'] ?? e['Subject'] ?? e;
          if (subjectMap is Map<String, dynamic>) {
            // `is_exam_subject` may sit on the outer row (sibling of a
            // nested `subject` object) rather than inside it — fall back to
            // the outer row's value when the inner map doesn't have one.
            final merged = identical(subjectMap, e)
                ? e
                : {
                    ...subjectMap,
                    if (!subjectMap.containsKey('is_exam_subject') &&
                        !subjectMap.containsKey('isExamSubject'))
                      'is_exam_subject':
                          e['is_exam_subject'] ?? e['isExamSubject'],
                  };
            final item = ClassSubjectItem.fromJson(merged);
            if (item.id > 0 && seenIds.add(item.id)) items.add(item);
          } else {
            final item = ClassSubjectItem.fromJson(e);
            if (item.id > 0 && seenIds.add(item.id)) items.add(item);
          }
        }
      }
      return AssignmentSuccess(items);
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.listClassSubjects',
        ),
      );
    }
  }

  /// GET /api/school-admin/classes/{class_id}/subjects/{subject_id}/teachers
  Future<AssignmentResult<List<TeacherModel>>> listClassSubjectTeachers(
    int classId,
    int subjectId,
  ) async {
    try {
      final response = await _client.get(
        apiUrl('$_base/classes/$classId/subjects/$subjectId/teachers'),
      );
      devLogResponse(
        'SchoolAdminAssignmentsService.listClassSubjectTeachers',
        response.statusCode,
        response.body,
      );
      if (response.statusCode == 404)
        return AssignmentError('Class or subject not found.', 404);
      if (response.statusCode != 200) {
        return AssignmentError(
          _errorMessage(response) ??
              'Could not load teachers for class/subject.',
          response.statusCode,
        );
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['teachers', 'data', 'items']);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map((e) => TeacherModel.fromJson(e))
          .toList();
      return AssignmentSuccess(items);
    } catch (e, st) {
      return AssignmentError(
        userFriendlyMessage(
          e,
          st,
          'SchoolAdminAssignmentsService.listClassSubjectTeachers',
        ),
      );
    }
  }
}
