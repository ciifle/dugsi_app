import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

const String _base = 'api/teacher';

// ==================== HELPERS ====================
int _parseId(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
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
  for (final value in raw.values) {
    if (value is List) return value;
  }
  return [];
}

void devLogResponse(String context, int statusCode, String body) {
  print('[$context] API response: status=$statusCode body=${body.length > 500 ? "${body.substring(0, 500)}..." : body}');
}

// ==================== MODELS ====================

/// GET /api/teacher/assignments -> [{ id, class: {id, name}, subject: {id, name} }]
class TeacherAssignmentModel {
  final int id;
  final Map<String, dynamic> class_;
  final Map<String, dynamic> subject;

  TeacherAssignmentModel({
    required this.id,
    required this.class_,
    required this.subject,
  });

  int get classId => _parseId(class_['id']);
  String get className => _str(class_['name']);
  int get subjectId => _parseId(subject['id']);
  String get subjectName => _str(subject['name']);

  factory TeacherAssignmentModel.fromJson(Map<String, dynamic> json) {
    final c = json['class'] ?? json['Class'] ?? json['class_'];
    final s = json['subject'] ?? json['Subject'] ?? json['subject_'];
    return TeacherAssignmentModel(
      id: _parseId(json['id']),
      class_: c is Map<String, dynamic> ? c : {'id': 0, 'name': _str(json['class_name'] ?? json['className'])},
      subject: s is Map<String, dynamic> ? s : {'id': 0, 'name': _str(json['subject_name'] ?? json['subjectName'])},
    );
  }
}

/// Student in class (for attendance/marks). GET /api/teacher/classes/{class_id}/students if available.
class TeacherStudentModel {
  final int id;
  final String? name;
  final String? emisNumber;
  final int? classId;

  TeacherStudentModel({required this.id, this.name, this.emisNumber, this.classId});

  factory TeacherStudentModel.fromJson(Map<String, dynamic> json) {
    return TeacherStudentModel(
      id: _parseId(json['id'] ?? json['student_id']),
      name: _strOpt(json['name'] ?? json['student_name'] ?? json['studentName']),
      emisNumber: _strOpt(json['emis_number'] ?? json['emisNumber']),
      classId: json['class_id'] != null ? _parseId(json['class_id']) : (json['class'] is Map ? _parseId((json['class'] as Map)['id']) : null),
    );
  }
}

/// Attendance record for POST body: { student_id, status }
class TeacherAttendanceRecord {
  final int studentId;
  final String status;

  TeacherAttendanceRecord({required this.studentId, required this.status});

  Map<String, dynamic> toJson() => {'student_id': studentId, 'status': status};
}

/// GET /api/teacher/marks -> Mark list item
class TeacherMarkModel {
  final int id;
  final int examId;
  final int studentId;
  final int subjectId;
  final int? teacherId;
  final num marksObtained;
  final num maxMarks;
  final String? grade;
  final String? studentName;
  final String? examName;
  final String? subjectName;

  TeacherMarkModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    this.teacherId,
    required this.marksObtained,
    required this.maxMarks,
    this.grade,
    this.studentName,
    this.examName,
    this.subjectName,
  });

  factory TeacherMarkModel.fromJson(Map<String, dynamic> json) {
    String? nameFrom(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isNotEmpty ? v : null;
      if (v is Map && v['name'] != null) return v['name'].toString();
      return null;
    }
    final student = json['student'] ?? json['Student'];
    final exam = json['exam'] ?? json['Exam'];
    final subject = json['subject'] ?? json['Subject'];
    return TeacherMarkModel(
      id: _parseId(json['id']),
      examId: _parseId(json['exam_id'] ?? json['examId']),
      studentId: _parseId(json['student_id'] ?? json['studentId']),
      subjectId: _parseId(json['subject_id'] ?? json['subjectId']),
      teacherId: json['teacher_id'] != null ? _parseId(json['teacher_id']) : null,
      marksObtained: _parseNum(json['marks_obtained'] ?? json['marksObtained'] ?? 0),
      maxMarks: _parseNum(json['max_marks'] ?? json['maxMarks'] ?? 100),
      grade: _strOpt(json['grade']),
      studentName: nameFrom(student) ?? _strOpt(json['student_name'] ?? json['studentName']),
      examName: nameFrom(exam) ?? _strOpt(json['exam_name'] ?? json['examName']),
      subjectName: nameFrom(subject) ?? _strOpt(json['subject_name'] ?? json['subjectName']),
    );
  }
}

// ==================== RESULT TYPES ====================
sealed class TeacherResult<T> {}
class TeacherSuccess<T> extends TeacherResult<T> {
  final T data;
  TeacherSuccess(this.data);
}
class TeacherError extends TeacherResult<Never> {
  final String message;
  final int? statusCode;
  TeacherError(this.message, [this.statusCode]);
}

// ==================== SERVICE ====================
final _client = ApiClient();

class TeacherService {
  TeacherService._();
  static final TeacherService _instance = TeacherService._();
  factory TeacherService() => _instance;

  /// GET /api/teacher/assignments
  Future<TeacherResult<List<TeacherAssignmentModel>>> listAssignments() async {
    try {
      final response = await _client.get(apiUrl('$_base/assignments'));
      devLogResponse('TeacherService.listAssignments', response.statusCode, response.body);
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Teacher profile not found. Contact school admin.', 403);
      }
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load assignments.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['assignments', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => TeacherAssignmentModel.fromJson(e)).toList();
      return TeacherSuccess(items);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.listAssignments'));
    }
  }

  /// GET /api/teacher/classes/{class_id}/students
  Future<TeacherResult<List<TeacherStudentModel>>> listStudentsByClass(int classId) async {
    try {
      final response = await _client.get(apiUrl('$_base/classes/$classId/students'));
      devLogResponse('TeacherService.listStudentsByClass', response.statusCode, response.body);
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Not allowed to view this class.', 403);
      }
      if (response.statusCode == 404) {
        return TeacherError('Student list not available. Contact admin to enable GET /api/teacher/classes/{class_id}/students.', 404);
      }
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load students.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['students', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => TeacherStudentModel.fromJson(e)).toList();
      return TeacherSuccess(items);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.listStudentsByClass'));
    }
  }

  /// POST /api/teacher/attendance  Body: { class_id, date, records: [{ student_id, status }] }
  Future<TeacherResult<void>> takeAttendance({
    required int classId,
    required String date,
    required List<TeacherAttendanceRecord> records,
  }) async {
    try {
      final body = {
        'class_id': classId,
        'date': date,
        'records': records.map((r) => r.toJson()).toList(),
      };
      final response = await _client.post(apiUrl('$_base/attendance'), body: body);
      devLogResponse('TeacherService.takeAttendance', response.statusCode, response.body);
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Not allowed to take attendance for this class.', 403);
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        return TeacherError(_errorMessage(response) ?? 'Could not save attendance.', response.statusCode);
      }
      return TeacherSuccess(null);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.takeAttendance'));
    }
  }

  /// PATCH /api/teacher/attendance  Body: { attendance_id, status }
  Future<TeacherResult<void>> updateAttendance({
    required int attendanceId,
    required String status,
  }) async {
    try {
      final body = {'attendance_id': attendanceId, 'status': status};
      final response = await _client.patch(apiUrl('$_base/attendance'), body: body);
      devLogResponse('TeacherService.updateAttendance', response.statusCode, response.body);
      if (response.statusCode == 403) return TeacherError(_errorMessage(response) ?? 'Not allowed.', 403);
      if (response.statusCode == 404) return TeacherError('Attendance record not found.', 404);
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not update attendance.', response.statusCode);
      }
      return TeacherSuccess(null);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.updateAttendance'));
    }
  }

  /// GET /api/teacher/marks?exam_id=&class_id=&subject_id=
  Future<TeacherResult<List<TeacherMarkModel>>> listMarks({
    int? examId,
    int? classId,
    int? subjectId,
  }) async {
    try {
      final params = <String, String>{};
      if (examId != null && examId > 0) params['exam_id'] = examId.toString();
      if (classId != null && classId > 0) params['class_id'] = classId.toString();
      if (subjectId != null && subjectId > 0) params['subject_id'] = subjectId.toString();
      final uri = params.isEmpty ? apiUrl('$_base/marks') : apiUrl('$_base/marks').replace(queryParameters: params);
      final response = await _client.get(uri);
      devLogResponse('TeacherService.listMarks', response.statusCode, response.body);
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Not allowed for this class/subject.', 403);
      }
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load marks.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['marks', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => TeacherMarkModel.fromJson(e)).toList();
      return TeacherSuccess(items);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.listMarks'));
    }
  }

  /// POST /api/teacher/marks
  Future<TeacherResult<TeacherMarkModel>> createMark({
    required int examId,
    required int studentId,
    required int subjectId,
    required num marksObtained,
    required num maxMarks,
  }) async {
    try {
      final body = {
        'exam_id': examId,
        'student_id': studentId,
        'subject_id': subjectId,
        'marks_obtained': marksObtained,
        'max_marks': maxMarks,
      };
      final response = await _client.post(apiUrl('$_base/marks'), body: body);
      devLogResponse('TeacherService.createMark', response.statusCode, response.body);
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Not allowed for this class/subject.', 403);
      }
      if (response.statusCode == 409) {
        return TeacherError(_errorMessage(response) ?? 'Marks already exist for this exam/student/subject. Use update.', 409);
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        return TeacherError(_errorMessage(response) ?? 'Could not save marks.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final map = raw is Map ? (raw['mark'] ?? raw['data'] ?? raw) : null;
      if (map is! Map<String, dynamic>) return TeacherError('Invalid response.');
      return TeacherSuccess(TeacherMarkModel.fromJson(map));
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.createMark'));
    }
  }

  /// PATCH /api/teacher/marks/{id}
  Future<TeacherResult<void>> updateMark(int id, {required num marksObtained, required num maxMarks}) async {
    try {
      final body = {'marks_obtained': marksObtained, 'max_marks': maxMarks};
      final response = await _client.patch(apiUrl('$_base/marks/$id'), body: body);
      devLogResponse('TeacherService.updateMark', response.statusCode, response.body);
      if (response.statusCode == 403) return TeacherError(_errorMessage(response) ?? 'Not allowed.', 403);
      if (response.statusCode == 404) return TeacherError('Mark not found.', 404);
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not update marks.', response.statusCode);
      }
      return TeacherSuccess(null);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.updateMark'));
    }
  }

  /// DELETE /api/teacher/marks/{id}
  Future<TeacherResult<void>> deleteMark(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/marks/$id'));
      devLogResponse('TeacherService.deleteMark', response.statusCode, response.body);
      if (response.statusCode == 403) return TeacherError(_errorMessage(response) ?? 'Not allowed.', 403);
      if (response.statusCode == 404) return TeacherError('Mark not found.', 404);
      if (response.statusCode != 200 && response.statusCode != 204) {
        return TeacherError(_errorMessage(response) ?? 'Could not delete mark.', response.statusCode);
      }
      return TeacherSuccess(null);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.deleteMark'));
    }
  }
}
