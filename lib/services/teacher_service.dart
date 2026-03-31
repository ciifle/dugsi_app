import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/periods_service.dart';
import 'package:kobac/services/class_subjects_service.dart';

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

/// Unwrap { data: { ... } } so both top-level and nested payloads work.
Map<String, dynamic> _unwrapPayload(Map<String, dynamic> raw) {
  final data = raw['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data as Map);
  return raw;
}

void devLogResponse(String context, int statusCode, String body) {
  print('[$context] API response: status=$statusCode body=${body.length > 500 ? "${body.substring(0, 500)}..." : body}');
}

// ==================== MODELS ====================

/// Assigned class from dashboard (assignedClasses).
class TeacherAssignedClassModel {
  final int id;
  final String name;

  TeacherAssignedClassModel({required this.id, required this.name});

  factory TeacherAssignedClassModel.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json['id'] ?? json['class_id'] ?? json['classId']);
    final name = _str(json['name'] ?? json['class_name'] ?? json['className']);
    return TeacherAssignedClassModel(id: id, name: name.isEmpty && id == 0 ? 'Unassigned' : name);
  }

  String get displayName => (id == 0 || name.isEmpty) ? 'Unassigned' : name;
}

/// Timetable entry from dashboard (timetables). Supports nested Class/Subject or flat class_name/subject_name.
class TeacherTimetableEntryModel {
  final int id;
  final String day;
  final String startTime;
  final String endTime;
  final int classId;
  final String className;
  final int subjectId;
  final String subjectName;
  final int? periodId;
  final PeriodModel? period;

  TeacherTimetableEntryModel({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    this.periodId,
    this.period,
  });

  String get classDisplayName => (classId == 0 || className.isEmpty) ? 'Unassigned' : className;
  String get subjectDisplayName => (subjectId == 0 || subjectName.isEmpty) ? '—' : subjectName;
  String get timeRange => '$startTime–$endTime';

  factory TeacherTimetableEntryModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    final classObj = json['class'] ?? json['Class'];
    final subjectObj = json['subject'] ?? json['Subject'];
    int cId = 0;
    String cName = '';
    if (classObj is Map) {
      cId = parseId((classObj as Map)['id']);
      cName = str((classObj as Map)['name']);
    } else {
      cId = parseId(json['class_id'] ?? json['classId']);
      cName = str(json['class_name'] ?? json['className']);
    }
    int sId = 0;
    String sName = '';
    if (subjectObj is Map) {
      sId = parseId((subjectObj as Map)['id']);
      sName = str((subjectObj as Map)['name']);
    } else {
      sId = parseId(json['subject_id'] ?? json['subjectId']);
      sName = str(json['subject_name'] ?? json['subjectName']);
    }
    String day = str(json['day'] ?? '');
    if (day.isEmpty) day = '—';
    
    PeriodModel? periodMod;
    final periodObj = json['period'] ?? json['Period'];
    if (periodObj is Map<String, dynamic>) {
      periodMod = PeriodModel.fromJson(periodObj);
    }
    
    int? pid;
    if (json['period_id'] != null) pid = int.tryParse(json['period_id'].toString());
    if (json['periodId'] != null) pid = int.tryParse(json['periodId'].toString());
    if (pid == 0) pid = null;
    if (pid == null && periodMod != null && periodMod.id > 0) pid = periodMod.id;

    String start = str(json['start_time'] ?? json['startTime'] ?? '');
    if (start.isEmpty && periodMod != null) start = periodMod.startTime;
    
    String end = str(json['end_time'] ?? json['endTime'] ?? '');
    if (end.isEmpty && periodMod != null) end = periodMod.endTime;
    
    if (start.length == 5) start = '$start:00';
    if (end.length == 5) end = '$end:00';
    return TeacherTimetableEntryModel(
      id: _parseId(json['id'] ?? json['timetable_id']),
      day: day,
      startTime: start.length >= 8 ? start.substring(0, 5) : start,
      endTime: end.length >= 8 ? end.substring(0, 5) : end,
      classId: cId,
      className: cName,
      subjectId: sId,
      subjectName: sName,
      periodId: pid,
      period: periodMod,
    );
  }
}

/// Dashboard response: GET /api/teacher/dashboard -> { assignedClasses, assignments, timetables }
class TeacherDashboardModel {
  final List<TeacherAssignedClassModel> assignedClasses;
  final List<TeacherAssignmentModel> assignments;
  final List<TeacherTimetableEntryModel> timetables;

  TeacherDashboardModel({
    required this.assignedClasses,
    required this.assignments,
    required this.timetables,
  });

  factory TeacherDashboardModel.fromJson(Map<String, dynamic> json) {
    final classesRaw = _extractList(json, ['assignedClasses', 'assigned_classes', 'classes']);
    final assignmentsRaw = _extractList(json, ['assignments', 'data']);
    final timetablesRaw = _extractList(json, ['timetables', 'timetable', 'schedules']);
    final classes = classesRaw.whereType<Map<String, dynamic>>().map((e) {
      if (e.containsKey('id') || e.containsKey('class_id') || e.containsKey('name') || e.containsKey('class_name')) {
        return TeacherAssignedClassModel.fromJson(Map<String, dynamic>.from(e));
      }
      final nested = e['class'] ?? e['Class'];
      if (nested is Map) return TeacherAssignedClassModel.fromJson(Map<String, dynamic>.from(nested as Map));
      return TeacherAssignedClassModel.fromJson(Map<String, dynamic>.from(e));
    }).toList();
    final assignments = assignmentsRaw.whereType<Map<String, dynamic>>().map(TeacherAssignmentModel.fromJson).toList();
    final timetables = timetablesRaw.whereType<Map<String, dynamic>>().map(TeacherTimetableEntryModel.fromJson).toList();
    // If backend omits assignedClasses but returns assignments, derive unique classes so UI never shows 0 when data exists.
    List<TeacherAssignedClassModel> finalClasses = classes;
    if (finalClasses.isEmpty && assignments.isNotEmpty) {
      final seen = <int>{};
      final derived = <TeacherAssignedClassModel>[];
      for (final a in assignments) {
        final id = a.classId;
        if (id > 0 && seen.add(id)) {
          derived.add(TeacherAssignedClassModel(id: id, name: a.className.isNotEmpty ? a.className : 'Class $id'));
        }
      }
      finalClasses = derived;
    }
    return TeacherDashboardModel(
      assignedClasses: finalClasses,
      assignments: assignments,
      timetables: timetables,
    );
  }
}

/// GET /api/teacher/assignments -> [{ id, class: {id, name}, subject: {id, name} }]
/// Backend may send class_id/classId, class_name/className; never show "class 0" — use classDisplayName.
class TeacherAssignmentModel {
  final int id;
  final Map<String, dynamic> class_;
  final Map<String, dynamic> subject;

  TeacherAssignmentModel({
    required this.id,
    required this.class_,
    required this.subject,
  });

  int get classId => _parseId(class_['id'] ?? class_['class_id'] ?? class_['classId']);
  String get className => _str(class_['name'] ?? class_['class_name'] ?? class_['className']);
  int get subjectId => _parseId(subject['id'] ?? subject['subject_id'] ?? subject['subjectId']);
  String get subjectName => _str(subject['name'] ?? subject['subject_name'] ?? subject['subjectName']);

  /// Use for display: never show "class 0"; show "Unassigned" when class missing.
  String get classDisplayName => (classId == 0 || className.trim().isEmpty) ? 'Unassigned' : className;

  factory TeacherAssignmentModel.fromJson(Map<String, dynamic> json) {
    final c = json['class'] ?? json['Class'] ?? json['class_'];
    final s = json['subject'] ?? json['Subject'] ?? json['subject_'];
    Map<String, dynamic> classMap;
    if (c is Map<String, dynamic>) {
      classMap = Map<String, dynamic>.from(c);
    } else {
      final cId = json['class_id'] ?? json['classId'];
      final cName = _str(json['class_name'] ?? json['className']);
      classMap = {'id': cId, 'name': cName};
    }
    Map<String, dynamic> subjectMap;
    if (s is Map<String, dynamic>) {
      subjectMap = Map<String, dynamic>.from(s);
    } else {
      final sId = json['subject_id'] ?? json['subjectId'];
      final sName = _str(json['subject_name'] ?? json['subjectName']);
      subjectMap = {'id': sId, 'name': sName};
    }
    return TeacherAssignmentModel(
      id: _parseId(json['id']),
      class_: classMap,
      subject: subjectMap,
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

/// Teacher attendance model for GET response (camelCase fields)
class TeacherAttendanceModel {
  final int id;
  final int studentId;
  final String studentName;
  final int classId;
  final String className;
  final int subjectId;
  final String subjectName;
  final int teacherId;
  final String teacherName;
  final String date;
  final String time;
  final String period;
  final String status;
  final int schoolId;

  TeacherAttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.time,
    required this.period,
    required this.status,
    required this.schoolId,
  });

  factory TeacherAttendanceModel.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceModel(
      id: _parseId(json['id']),
      studentId: _parseId(json['studentId']),
      studentName: _str(json['studentName']),
      classId: _parseId(json['classId']),
      className: _str(json['className']),
      subjectId: _parseId(json['subjectId']),
      subjectName: _str(json['subjectName']),
      teacherId: _parseId(json['teacherId']),
      teacherName: _str(json['teacherName']),
      date: _str(json['date']),
      time: _str(json['time']),
      period: _str(json['period']),
      status: _str(json['status']),
      schoolId: _parseId(json['schoolId']),
    );
  }
}

/// Exam list item for marks entry (GET /api/teacher/exams)
class TeacherExamModel {
  final int id;
  final String name;
  final String? date;
  final int? classId;
  final int? subjectId;
  final String? className;
  final String? subjectName;

  TeacherExamModel({
    required this.id,
    required this.name,
    this.date,
    this.classId,
    this.subjectId,
    this.className,
    this.subjectName,
  });

  factory TeacherExamModel.fromJson(Map<String, dynamic> json) {
    return TeacherExamModel(
      id: _parseId(json['id']),
      name: _str(json['name']),
      date: _strOpt(json['date']),
      classId: json['classId'] != null ? _parseId(json['classId']) : (json['class_id'] != null ? _parseId(json['class_id']) : null),
      subjectId: json['subjectId'] != null ? _parseId(json['subjectId']) : (json['subject_id'] != null ? _parseId(json['subject_id']) : null),
      className: _strOpt(json['className'] ?? json['class_name']),
      subjectName: _strOpt(json['subjectName'] ?? json['subject_name']),
    );
  }

  String get displayLabel {
    final dateStr = date != null && date!.length >= 10 ? ' (${date!.substring(0, 10)})' : '';
    if (className != null && subjectName != null) {
      return '$name — $className — $subjectName$dateStr';
    }
    return '$name$dateStr';
  }
}

/// Marks entry result from GET /api/teacher/marks. 
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
      if (v is Map && v['studentName'] != null) return v['studentName'].toString();
      if (v is Map && v['fullName'] != null) return v['fullName'].toString();
      return null;
    }
    final student = json['student'] ?? json['Student'];
    final exam = json['exam'] ?? json['Exam'];
    final subject = json['subject'] ?? json['Subject'];
    final classObj = json['class'] ?? json['Class'];
    
    return TeacherMarkModel(
      id: _parseId(json['id']),
      examId: _parseId(json['exam_id'] ?? json['examId']),
      studentId: _parseId(json['student_id'] ?? json['studentId']),
      subjectId: _parseId(json['subject_id'] ?? json['subjectId']),
      teacherId: json['teacher_id'] != null ? _parseId(json['teacher_id']) : null,
      marksObtained: _parseNum(json['marks_obtained'] ?? json['marksObtained'] ?? 0),
      maxMarks: _parseNum(json['max_marks'] ?? json['maxMarks'] ?? 100),
      grade: _strOpt(json['grade']),
      studentName: _strOpt(json['studentName'] ?? json['student_name']) ?? nameFrom(student),
      examName: _strOpt(json['examName'] ?? json['exam_name']) ?? nameFrom(exam),
      subjectName: _strOpt(json['subjectName'] ?? json['subject_name']) ?? nameFrom(subject),
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

  /// GET /api/teacher/class-subjects?class_id=
  Future<TeacherResult<List<ClassSubjectModel>>> listClassSubjects(int classId) async {
    try {
      final response = await _client.get(apiUrl('$_base/class-subjects?class_id=$classId'));
      devLogResponse('TeacherService.listClassSubjects', response.statusCode, response.body);
      
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load class subjects. Please try again.', response.statusCode);
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
          list = data['class_subjects'] as List<dynamic>? ?? 
                   data['items'] as List<dynamic>? ?? 
                   data['data'] as List<dynamic>? ?? [];
        } else if (raw['class_subjects'] is List) {
          list = raw['class_subjects'] as List<dynamic>;
        } else if (raw['items'] is List) {
          list = raw['items'] as List<dynamic>;
        } else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) { found = value; break; }
          }
          if (found == null) return TeacherError('Invalid response from server. Please try again.');
          list = found;
        }
      } else {
        return TeacherError('Invalid response from server. Please try again.');
      }
      
      final classSubjects = <ClassSubjectModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            classSubjects.add(ClassSubjectModel.fromJson(e));
          } catch (_) {}
        }
      }
      return TeacherSuccess(classSubjects);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.listClassSubjects'));
    }
  }

  /// GET /api/teacher/dashboard — source of truth for teacher panel (assignedClasses, assignments, timetables).
  Future<TeacherResult<TeacherDashboardModel>> getDashboard() async {
    try {
      final response = await _client.get(apiUrl('$_base/dashboard'));
      devLogResponse('TeacherService.getDashboard', response.statusCode, response.body);
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Teacher profile not found. Contact school admin.', 403);
      }
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load dashboard.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      if (raw is! Map<String, dynamic>) {
        return TeacherError('Invalid dashboard response.');
      }
      final payload = _unwrapPayload(raw);
      final model = TeacherDashboardModel.fromJson(payload);
      debugPrint('TeacherService.getDashboard: assignments=${model.assignments.length}, assignedClasses=${model.assignedClasses.length}, timetables=${model.timetables.length}');
      return TeacherSuccess(model);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.getDashboard'));
    }
  }

  /// GET /api/teacher/assignments (kept for backward compatibility; prefer getDashboard).
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
      final payload = raw is Map ? _unwrapPayload(Map<String, dynamic>.from(raw as Map)) : <String, dynamic>{};
      final list = _extractList(payload.isNotEmpty ? payload : raw, ['assignments', 'data', 'items']);
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
      final payload = raw is Map ? _unwrapPayload(Map<String, dynamic>.from(raw as Map)) : <String, dynamic>{};
      final list = _extractList(payload.isNotEmpty ? payload : raw, ['students', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => TeacherStudentModel.fromJson(e)).toList();
      return TeacherSuccess(items);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.listStudentsByClass'));
    }
  }

  /// POST /api/teacher/attendance  Body: { class_id, date, records: [{ student_id, status }] }
  Future<TeacherResult<Map<String, dynamic>>> takeAttendance({
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
      
      debugPrint('[Teacher Attendance POST] URL: ${apiUrl('$_base/attendance')}');
      debugPrint('[Teacher Attendance POST] Body: ${jsonEncode(body)}');
      
      final response = await _client.post(apiUrl('$_base/attendance'), body: body);
      
      debugPrint('[Teacher Attendance POST] Response Status: ${response.statusCode}');
      debugPrint('[Teacher Attendance POST] Response Body: ${response.body}');
      
      if (response.statusCode == 400) {
        return TeacherError(_errorMessage(response) ?? 'Invalid request body.', 400);
      }
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Not allowed to take attendance for this class or invalid time window.', 403);
      }
      if (response.statusCode == 404) {
        return TeacherError(_errorMessage(response) ?? 'Class not found.', 404);
      }
      if (response.statusCode == 409) {
        return TeacherError(_errorMessage(response) ?? 'Attendance already exists for this class and date.', 409);
      }
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not save attendance.', response.statusCode);
      }
      
      final responseData = _parseJson(response.body);
      if (responseData is Map<String, dynamic>) {
        return TeacherSuccess(responseData);
      } else {
        return TeacherError('Invalid response format.');
      }
    } catch (e, st) {
      debugPrint('[Teacher Attendance POST] Exception: $e');
      debugPrint('[Teacher Attendance POST] Stack Trace: $st');
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.takeAttendance'));
    }
  }

  /// GET /api/teacher/attendance?class_id=1&date=2026-03-31
  Future<TeacherResult<List<TeacherAttendanceModel>>> listAttendance({
    int? classId,
    String? date,
  }) async {
    try {
      final params = <String, String>{};
      if (classId != null && classId > 0) params['class_id'] = classId.toString();
      if (date != null && date.isNotEmpty) params['date'] = date;
      
      final uri = params.isEmpty ? apiUrl('$_base/attendance') : apiUrl('$_base/attendance').replace(queryParameters: params);
      
      debugPrint('[Teacher Attendance GET] URL: $uri');
      
      final response = await _client.get(uri);
      
      debugPrint('[Teacher Attendance GET] Response Status: ${response.statusCode}');
      debugPrint('[Teacher Attendance GET] Response Body: ${response.body}');
      
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load attendance.', response.statusCode);
      }
      
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is Map<String, dynamic>) {
        if (raw['attendance'] is List) {
          list = raw['attendance'] as List<dynamic>;
        } else {
          return TeacherError('Invalid response format: missing attendance array.');
        }
      } else if (raw is List) {
        list = raw;
      } else {
        return TeacherError('Invalid response format.');
      }
      
      final records = <TeacherAttendanceModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try { 
            records.add(TeacherAttendanceModel.fromJson(e)); 
          } catch (err) {
            debugPrint('[Teacher Attendance GET] Error parsing record: $err');
          }
        }
      }
      
      return TeacherSuccess(records);
    } catch (e, st) {
      debugPrint('[Teacher Attendance GET] Exception: $e');
      debugPrint('[Teacher Attendance GET] Stack Trace: $st');
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.listAttendance'));
    }
  }

  /// PATCH /api/teacher/attendance  Body: { class_id, date, records: [{ student_id, status }] }
  Future<TeacherResult<Map<String, dynamic>>> updateAttendance({
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
      
      debugPrint('[Teacher Attendance PATCH] URL: ${apiUrl('$_base/attendance')}');
      debugPrint('[Teacher Attendance PATCH] Body: ${jsonEncode(body)}');
      
      final response = await _client.patch(apiUrl('$_base/attendance'), body: body);
      
      debugPrint('[Teacher Attendance PATCH] Response Status: ${response.statusCode}');
      debugPrint('[Teacher Attendance PATCH] Response Body: ${response.body}');
      
      if (response.statusCode == 400) {
        return TeacherError(_errorMessage(response) ?? 'Invalid request body.', 400);
      }
      if (response.statusCode == 403) {
        return TeacherError(_errorMessage(response) ?? 'Not allowed to update attendance for this class or invalid time window.', 403);
      }
      if (response.statusCode == 404) {
        return TeacherError(_errorMessage(response) ?? 'Class not found.', 404);
      }
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not update attendance.', response.statusCode);
      }
      
      final responseData = _parseJson(response.body);
      if (responseData is Map<String, dynamic>) {
        return TeacherSuccess(responseData);
      } else {
        return TeacherError('Invalid response format.');
      }
    } catch (e, st) {
      debugPrint('[Teacher Attendance PATCH] Exception: $e');
      debugPrint('[Teacher Attendance PATCH] Stack Trace: $st');
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

  /// GET /api/teacher/exams — school-wide exams (no class/subject filtering)
  Future<TeacherResult<List<TeacherExamModel>>> listExams({int? classId, int? subjectId}) async {
    try {
      // Exams are now school-wide, ignore class/subject filters
      final response = await _client.get(apiUrl('$_base/exams'));
      devLogResponse('TeacherService.listExams', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load exams.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final payload = raw is Map ? _unwrapPayload(Map<String, dynamic>.from(raw as Map)) : <String, dynamic>{};
      final list = _extractList(payload.isNotEmpty ? payload : raw, ['exams', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => TeacherExamModel.fromJson(e)).toList();
      return TeacherSuccess(items);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeacherService.listExams'));
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
