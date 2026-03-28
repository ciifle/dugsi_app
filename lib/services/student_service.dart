import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/periods_service.dart';

const String _base = 'api/student';

// ==================== MODELS ====================

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

/// GET /api/student/me -> student with Class, User (if any).
/// Prefer root-level fields (name, emisNumber, classId, className); do not rely on nested User for display.
class StudentMeModel {
  final int id;
  final String? name;
  final String? emisNumber;
  final int? classId;
  final String? className;
  final Map<String, dynamic>? class_;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? school;

  StudentMeModel({
    required this.id,
    this.name,
    this.emisNumber,
    this.classId,
    this.className,
    this.class_,
    this.user,
    this.school,
  });

  factory StudentMeModel.fromJson(Map<String, dynamic> json) {
    final c = json['class'] ?? json['Class'] ?? json['class_'];
    String? cn;
    if (c is Map && c['name'] != null) cn = c['name'].toString();
    cn ??= _strOpt(json['class_name'] ?? json['className']);
    return StudentMeModel(
      id: _parseId(json['id'] ?? json['student_id']),
      name: _strOpt(json['name'] ?? json['student_name'] ?? json['studentName']),
      emisNumber: _strOpt(json['emis_number'] ?? json['emisNumber']),
      classId: c is Map ? _parseId(c['id']) : _parseId(json['class_id'] ?? json['classId']),
      className: cn,
      class_: c is Map<String, dynamic> ? c : null,
      user: json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : (json['User'] is Map<String, dynamic> ? json['User'] as Map<String, dynamic> : null),
      school: json['school'] is Map<String, dynamic> ? json['school'] as Map<String, dynamic> : null,
    );
  }
}

/// Marks list item
class StudentMarkModel {
  final int id;
  final Map<String, dynamic> exam;
  final Map<String, dynamic> subject;
  final Map<String, dynamic>? teacher;
  final Map<String, dynamic>? class_;
  final num marksObtained;
  final num maxMarks;
  final num? percentage;
  final String? grade;

  StudentMarkModel({
    required this.id,
    required this.exam,
    required this.subject,
    this.teacher,
    this.class_,
    required this.marksObtained,
    required this.maxMarks,
    this.percentage,
    this.grade,
  });

  factory StudentMarkModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parseNested(dynamic v, String nameKey, String fallbackName) {
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is String) return {'id': 0, 'name': v};
      return {'id': 0, 'name': _str(json[nameKey] ?? fallbackName)};
    }

    return StudentMarkModel(
      id: _parseId(json['id']),
      exam: parseNested(json['exam'] ?? json['Exam'], 'exam_name', 'Exam'),
      subject: parseNested(json['subject'] ?? json['Subject'], 'subject_name', 'Subject'),
      teacher: json['teacher'] is Map ? Map<String, dynamic>.from(json['teacher'] as Map) : (json['Teacher'] is Map ? Map<String, dynamic>.from(json['Teacher'] as Map) : null),
      class_: json['class'] is Map ? Map<String, dynamic>.from(json['class'] as Map) : (json['Class'] is Map ? Map<String, dynamic>.from(json['Class'] as Map) : null),
      marksObtained: _parseNum(json['marks_obtained'] ?? json['marksObtained'] ?? 0),
      maxMarks: _parseNum(json['max_marks'] ?? json['maxMarks'] ?? 100),
      percentage: json['percentage'] != null ? _parseNum(json['percentage']) : null,
      grade: _strOpt(json['grade']),
    );
  }
}

/// Result report: exam, student, results[], summary
class StudentResultReportModel {
  final Map<String, dynamic> exam;
  final Map<String, dynamic>? student;
  final List<Map<String, dynamic>> results;
  final Map<String, dynamic>? summary;

  StudentResultReportModel({
    required this.exam,
    this.student,
    required this.results,
    this.summary,
  });

  factory StudentResultReportModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'results' and 'subjects' from API response
    List<dynamic> r = [];
    if (json['results'] is List) {
      r = json['results'] as List;
    } else if (json['subjects'] is List) {
      r = json['subjects'] as List;
    }
    
    // Update summary field names to match API response
    Map<String, dynamic>? summary = json['summary'] is Map ? json['summary'] as Map<String, dynamic> : null;
    if (summary != null) {
      // Map API summary fields to expected field names
      summary = {
        'total_marks_obtained': summary['total_marks_obtained'] ?? summary['total_obtained'] ?? 0,
        'total_max_marks': summary['total_max_marks'] ?? summary['total_max'] ?? 0,
        'percentage': summary['overall_percentage'] ?? summary['percentage'] ?? 0,
        'grade': summary['overall_grade'] ?? summary['grade'] ?? 'N/A',
      };
    }
    
    return StudentResultReportModel(
      exam: json['exam'] is Map ? json['exam'] as Map<String, dynamic> : {'id': 0, 'name': ''},
      student: json['student'] is Map ? json['student'] as Map<String, dynamic> : null,
      results: r.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList(),
      summary: summary,
    );
  }
}

/// Fee item for student. Backend may return flattened root-level (studentName, emisNumber, amount, status, paidAmount, remainingAmount, Payments).
class StudentFeeModel {
  final int id;
  final num amount;
  final num paidAmount;
  final num remainingAmount;
  final String? status;
  final String? createdAt;
  final String? studentName;
  final String? emisNumber;
  final List<dynamic>? payments;

  StudentFeeModel({
    required this.id,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    this.status,
    this.createdAt,
    this.studentName,
    this.emisNumber,
    this.payments,
  });

  factory StudentFeeModel.fromJson(Map<String, dynamic> json) {
    List<dynamic>? payList;
    final p = json['Payments'] ?? json['payments'];
    if (p is List) payList = p;
    return StudentFeeModel(
      id: _parseId(json['id']),
      amount: _parseNum(json['amount'] ?? 0),
      paidAmount: _parseNum(json['paid_amount'] ?? json['paidAmount'] ?? 0),
      remainingAmount: _parseNum(json['remaining_amount'] ?? json['remainingAmount'] ?? 0),
      status: _strOpt(json['status']),
      createdAt: _strOpt(json['created_at'] ?? json['createdAt']),
      studentName: _strOpt(json['studentName'] ?? json['student_name']),
      emisNumber: _strOpt(json['emisNumber'] ?? json['emis_number']),
      payments: payList,
    );
  }
}

/// Payment history item
class StudentPaymentModel {
  final int id;
  final int feeId;
  final num amount;
  final String? method;
  final String? createdAt;

  StudentPaymentModel({
    required this.id,
    required this.feeId,
    required this.amount,
    this.method,
    this.createdAt,
  });

  factory StudentPaymentModel.fromJson(Map<String, dynamic> json) {
    return StudentPaymentModel(
      id: _parseId(json['id']),
      feeId: _parseId(json['fee_id'] ?? json['feeId'] ?? 0),
      amount: _parseNum(json['amount'] ?? 0),
      method: _strOpt(json['method']),
      createdAt: _strOpt(json['created_at'] ?? json['createdAt']),
    );
  }
}

/// Notice item
class StudentNoticeModel {
  final int id;
  final String title;
  final String? content;
  final String? createdAt;

  StudentNoticeModel({
    required this.id,
    required this.title,
    this.content,
    this.createdAt,
  });

  factory StudentNoticeModel.fromJson(Map<String, dynamic> json) {
    return StudentNoticeModel(
      id: _parseId(json['id']),
      title: _str(json['title'] ?? ''),
      content: _strOpt(json['content']),
      createdAt: _strOpt(json['created_at'] ?? json['createdAt']),
    );
  }
}

/// Timetable slot
class StudentTimetableSlotModel {
  final int id;
  final String? day;
  final String? startTime;
  final String? endTime;
  final Map<String, dynamic>? subject;
  final Map<String, dynamic>? teacher;
  final int? periodId;
  final PeriodModel? period;

  StudentTimetableSlotModel({
    required this.id,
    this.day,
    this.startTime,
    this.endTime,
    this.subject,
    this.teacher,
    this.periodId,
    this.period,
  });

  factory StudentTimetableSlotModel.fromJson(Map<String, dynamic> json) {
    PeriodModel? periodMod;
    if (json['period'] is Map<String, dynamic>) {
      periodMod = PeriodModel.fromJson(json['period']);
    } else if (json['Period'] is Map<String, dynamic>) {
      periodMod = PeriodModel.fromJson(json['Period']);
    }

    int? pid;
    if (json['period_id'] != null) pid = int.tryParse(json['period_id'].toString());
    if (json['periodId'] != null) pid = int.tryParse(json['periodId'].toString());
    if (pid == 0) pid = null;
    if (pid == null && periodMod != null && periodMod.id > 0) pid = periodMod.id;

    String? startStr = _strOpt(json['start_time'] ?? json['startTime']);
    if ((startStr == null || startStr.isEmpty) && periodMod != null) startStr = periodMod.startTime;

    String? endStr = _strOpt(json['end_time'] ?? json['endTime']);
    if ((endStr == null || endStr.isEmpty) && periodMod != null) endStr = periodMod.endTime;

    return StudentTimetableSlotModel(
      id: _parseId(json['id']),
      day: _strOpt(json['day']),
      startTime: startStr,
      endTime: endStr,
      subject: json['subject'] is Map ? json['subject'] as Map<String, dynamic> : null,
      teacher: json['teacher'] is Map ? json['teacher'] as Map<String, dynamic> : null,
      periodId: pid,
      period: periodMod,
    );
  }
}

/// Attendance record. Backend may return flattened root-level (studentName, className, date, time, period, status).
class StudentAttendanceRecordModel {
  final int id;
  final String? date;
  final String? status;
  final String? studentName;
  final String? className;
  final String? time;
  final String? period;

  StudentAttendanceRecordModel({
    required this.id,
    this.date,
    this.status,
    this.studentName,
    this.className,
    this.time,
    this.period,
  });

  factory StudentAttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecordModel(
      id: _parseId(json['id']),
      date: _strOpt(json['date']),
      status: _strOpt(json['status']),
      studentName: _strOpt(json['studentName'] ?? json['student_name']),
      className: _strOpt(json['className'] ?? json['class_name']),
      time: _strOpt(json['time']),
      period: _strOpt(json['period']),
    );
  }
}

/// Exam list item
class StudentExamModel {
  final int id;
  final String name;

  StudentExamModel({required this.id, required this.name});

  factory StudentExamModel.fromJson(Map<String, dynamic> json) {
    return StudentExamModel(
      id: _parseId(json['id']),
      name: _str(json['name'] ?? ''),
    );
  }
}

// ==================== RESULT TYPES ====================
sealed class StudentResult<T> {}
class StudentSuccess<T> extends StudentResult<T> {
  final T data;
  StudentSuccess(this.data);
}
class StudentError extends StudentResult<Never> {
  final String message;
  final int? statusCode;
  StudentError(this.message, [this.statusCode]);
}

// ==================== HELPERS ====================
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

// ==================== SERVICE ====================
final _client = ApiClient();

/// In-memory cache for session (clear on logout is handled by app).
StudentMeModel? _cachedMe;
List<StudentExamModel>? _cachedExams;

class StudentService {
  StudentService._();
  static final StudentService _instance = StudentService._();
  factory StudentService() => _instance;

  void clearCache() {
    _cachedMe = null;
    _cachedExams = null;
  }

  /// GET /api/student/me — cached for session.
  Future<StudentResult<StudentMeModel>> getMe({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedMe != null) return StudentSuccess(_cachedMe!);
    try {
      final response = await _client.get(apiUrl('$_base/me'));
      devLogResponse('StudentService.getMe', response.statusCode, response.body);
      if (response.statusCode == 404) return StudentError('Student profile not found.', 404);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load profile.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      if (raw == null || raw is! Map) return StudentError('Invalid response.');
      final student = raw['student'] ?? raw['data'] ?? raw;
      if (student is! Map<String, dynamic>) return StudentError('Invalid response.');
      final model = StudentMeModel.fromJson(student);
      _cachedMe = model;
      return StudentSuccess(model);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.getMe'));
    }
  }

  /// GET /api/student/marks?exam_id=&subject_id=
  Future<StudentResult<List<StudentMarkModel>>> listMarks({int? examId, int? subjectId}) async {
    try {
      final params = <String, String>{};
      if (examId != null && examId > 0) params['exam_id'] = examId.toString();
      if (subjectId != null && subjectId > 0) params['subject_id'] = subjectId.toString();
      final uri = params.isEmpty ? apiUrl('$_base/marks') : apiUrl('$_base/marks').replace(queryParameters: params);
      final response = await _client.get(uri);
      devLogResponse('StudentService.listMarks', response.statusCode, response.body);
      if (response.statusCode == 403) return StudentError(_errorMessage(response) ?? 'Exams module disabled.', 403);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load marks.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['marks', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => StudentMarkModel.fromJson(e)).toList();
      return StudentSuccess(items);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.listMarks'));
    }
  }

  /// GET /api/student/results/{exam_id}
  Future<StudentResult<StudentResultReportModel>> getResultReport(int examId) async {
    try {
      final response = await _client.get(apiUrl('$_base/results/$examId'));
      devLogResponse('StudentService.getResultReport', response.statusCode, response.body);
      if (response.statusCode == 403) return StudentError(_errorMessage(response) ?? 'Exams module disabled.', 403);
      if (response.statusCode == 404) return StudentError('Exam or results not found.', 404);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load results.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      if (raw == null || raw is! Map<String, dynamic>) return StudentError('Invalid response.');
      return StudentSuccess(StudentResultReportModel.fromJson(raw));
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.getResultReport'));
    }
  }

  /// GET /api/student/exams — cached for session.
  Future<StudentResult<List<StudentExamModel>>> listExams({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedExams != null) return StudentSuccess(_cachedExams!);
    try {
      final response = await _client.get(apiUrl('$_base/exams'));
      devLogResponse('StudentService.listExams', response.statusCode, response.body);
      if (response.statusCode == 403) return StudentError(_errorMessage(response) ?? 'Exams module disabled.', 403);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load exams.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['exams', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => StudentExamModel.fromJson(e)).toList();
      _cachedExams = items;
      return StudentSuccess(items);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.listExams'));
    }
  }

  /// GET /api/student/fees
  Future<StudentResult<List<StudentFeeModel>>> listFees() async {
    try {
      final response = await _client.get(apiUrl('$_base/fees'));
      devLogResponse('StudentService.listFees', response.statusCode, response.body);
      if (response.statusCode == 403) return StudentError(_errorMessage(response) ?? 'Payments module disabled.', 403);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load fees.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['fees', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => StudentFeeModel.fromJson(e)).toList();
      return StudentSuccess(items);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.listFees'));
    }
  }

  /// GET /api/student/payments
  Future<StudentResult<List<StudentPaymentModel>>> listPayments() async {
    try {
      final response = await _client.get(apiUrl('$_base/payments'));
      devLogResponse('StudentService.listPayments', response.statusCode, response.body);
      if (response.statusCode == 403) return StudentError(_errorMessage(response) ?? 'Payments module disabled.', 403);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load payments.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['payments', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => StudentPaymentModel.fromJson(e)).toList();
      return StudentSuccess(items);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.listPayments'));
    }
  }

  /// POST /api/student/payments  Body: { fee_id, amount, method }
  Future<StudentResult<StudentPaymentModel>> payFee({
    required int feeId,
    required num amount,
    required String method,
  }) async {
    try {
      final body = {'fee_id': feeId, 'amount': amount, 'method': method};
      final response = await _client.post(apiUrl('$_base/payments'), body: body);
      devLogResponse('StudentService.payFee', response.statusCode, response.body);
      if (response.statusCode == 400) return StudentError(_errorMessage(response) ?? 'Invalid fee or amount.', 400);
      if (response.statusCode == 403) return StudentError(_errorMessage(response) ?? 'Payments module disabled.', 403);
      if (response.statusCode == 404) return StudentError(_errorMessage(response) ?? 'Fee or student not found.', 404);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return StudentError(_errorMessage(response) ?? 'Payment failed.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic>? map;
      if (raw is Map<String, dynamic>) {
        map = raw['payment'] ?? raw['data'] ?? raw;
      }
      if (map == null) return StudentError('Invalid response.');
      return StudentSuccess(StudentPaymentModel.fromJson(map));
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.payFee'));
    }
  }

  /// GET /api/student/notices
  Future<StudentResult<List<StudentNoticeModel>>> listNotices() async {
    try {
      final response = await _client.get(apiUrl('$_base/notices'));
      devLogResponse('StudentService.listNotices', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load notices.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['notices', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => StudentNoticeModel.fromJson(e)).toList();
      return StudentSuccess(items);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.listNotices'));
    }
  }

  /// GET /api/student/timetable?day=MON|TUE|...
  Future<StudentResult<List<StudentTimetableSlotModel>>> getTimetable({String? day}) async {
    try {
      final uri = day != null && day.isNotEmpty
          ? apiUrl('$_base/timetable').replace(queryParameters: {'day': day})
          : apiUrl('$_base/timetable');
      final response = await _client.get(uri);
      devLogResponse('StudentService.getTimetable', response.statusCode, response.body);
      if (response.statusCode == 404) return StudentError('Timetable or profile not found.', 404);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load timetable.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['timetable', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => StudentTimetableSlotModel.fromJson(e)).toList();
      return StudentSuccess(items);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.getTimetable'));
    }
  }

  /// GET /api/student/attendance?date=YYYY-MM-DD or from=&to=
  Future<StudentResult<List<StudentAttendanceRecordModel>>> listAttendance({
    String? date,
    String? from,
    String? to,
  }) async {
    try {
      final params = <String, String>{};
      if (date != null && date.isNotEmpty) params['date'] = date;
      if (from != null && from.isNotEmpty) params['from'] = from;
      if (to != null && to.isNotEmpty) params['to'] = to;
      final uri = params.isEmpty ? apiUrl('$_base/attendance') : apiUrl('$_base/attendance').replace(queryParameters: params);
      final response = await _client.get(uri);
      devLogResponse('StudentService.listAttendance', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load attendance.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final list = _extractList(raw, ['attendance', 'data', 'items']);
      final items = list.whereType<Map<String, dynamic>>().map((e) => StudentAttendanceRecordModel.fromJson(e)).toList();
      return StudentSuccess(items);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentService.listAttendance'));
    }
  }
}
