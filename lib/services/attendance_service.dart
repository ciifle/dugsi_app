import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/models/attendance_report.dart';
import 'package:kobac/models/lesson_attendance.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/attendance_diagnostics.dart';
import 'package:kobac/services/pdf_file_result.dart';

/// Attendance record model (school-admin scope).
/// Backend returns flattened root-level fields (studentName, teacherName, className, subjectName, date, time, period, status).
/// Do not expect nested User objects.
class AttendanceModel {
  final int id;
  final int? studentId;
  final int? classId;
  final String? date;
  final String? status;
  final String? recordedAt;
  final String? createdAt;
  /// Flattened from API (root-level).
  final String? studentName;
  final String? emisNumber;
  final String? teacherName;
  final String? className;
  final String? subjectName;
  final String? time;
  final String? period;

  const AttendanceModel({
    required this.id,
    this.studentId,
    this.classId,
    this.date,
    this.status,
    this.recordedAt,
    this.createdAt,
    this.studentName,
    this.emisNumber,
    this.teacherName,
    this.className,
    this.subjectName,
    this.time,
    this.period,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    return AttendanceModel(
      id: parseId(json['id'] ?? json['attendance_id']),
      studentId: json['student_id'] != null || json['studentId'] != null ? parseId(json['student_id'] ?? json['studentId']) : null,
      classId: json['class_id'] != null || json['classId'] != null ? parseId(json['class_id'] ?? json['classId']) : null,
      date: strOpt(json['date']),
      status: strOpt(json['status']),
      recordedAt: strOpt(json['recorded_at'] ?? json['recordedAt']),
      createdAt: strOpt(json['created_at'] ?? json['createdAt']),
      studentName: strOpt(json['studentName'] ?? json['student_name']),
      emisNumber: strOpt(json['emisNumber'] ?? json['emis_number']),
      teacherName: strOpt(json['teacherName'] ?? json['teacher_name']),
      className: strOpt(json['className'] ?? json['class_name']),
      subjectName: strOpt(json['subjectName'] ?? json['subject_name']),
      time: strOpt(json['time']),
      period: strOpt(json['period']),
    );
  }
}

sealed class AttendanceResult<T> {}

class AttendanceSuccess<T> extends AttendanceResult<T> {
  final T data;
  AttendanceSuccess(this.data);
}

class AttendanceError extends AttendanceResult<Never> {
  final String message;
  final int? statusCode;

  /// Machine-readable backend code, e.g. ATTENDANCE_NOT_RECORDED.
  final String? code;
  AttendanceError(this.message, [this.statusCode, this.code]);
}

/// Flutter-side code for a 200 whose body does not match the contract.
const String kInvalidResponseCode = 'INVALID_RESPONSE';

/// User-facing message for a lesson attendance failure. Known backend codes
/// get fixed wording; other backend messages are shown only when they look
/// like plain validation text (never SQL, HTML or stack traces).
String lessonAttendanceErrorMessage({
  String? code,
  int? statusCode,
  String? backendMessage,
  required String fallback,
}) {
  switch (code) {
    case 'LESSON_SELECTION_REQUIRED':
      return 'Select a lesson before taking attendance.';
    case 'ATTENDANCE_NOT_RECORDED':
      return 'No attendance has been recorded for this lesson yet.';
    case 'FUTURE_ATTENDANCE_DATE':
      return 'Attendance cannot be taken for a future date. Choose today or an earlier date.';
    case 'DATE_OUTSIDE_ACADEMIC_YEAR':
      return 'The selected date is outside the selected academic year. Choose a date within the academic year.';
    case 'LESSON_NOT_FOUND':
      return 'The selected timetable lesson could not be found.';
    case 'LESSON_DAY_MISMATCH':
      return 'The selected lesson is not scheduled on this date. Reload the lessons and try again.';
    case 'STUDENT_NOT_ENROLLED':
      return 'Some students are no longer enrolled in this class. Reload the register and try again.';
    case 'ENROLLMENT_NOT_FOUND':
      return 'This student was not enrolled in the selected academic year.';
    case 'INVALID_DATE_RANGE':
      return 'The start date must be on or before the end date.';
    case 'DATE_RANGE_OUTSIDE_ACADEMIC_YEAR':
      // The backend message names the academic year's own date range.
      final text = backendMessage?.trim() ?? '';
      return text.isNotEmpty && text.length <= 200
          ? text
          : 'The date range must be within the selected academic year.';
    case kInvalidResponseCode:
      return 'The server sent an unexpected response. Please try again.';
  }
  if (statusCode == 401) return 'Your session has expired. Please sign in again.';
  if (statusCode == 403) {
    return 'You do not have permission to manage attendance for this class.';
  }
  if (statusCode != null && statusCode >= 500) {
    return 'The server could not complete this request. Please try again in a moment.';
  }
  final text = backendMessage?.trim() ?? '';
  final lower = text.toLowerCase();
  final unsafe = text.isEmpty ||
      text.length > 200 ||
      lower.contains('column') ||
      lower.contains('er_') ||
      lower.contains('sql') ||
      lower.contains('<html') ||
      lower.contains('stack') ||
      lower.contains('sequelize') ||
      lower.contains('constraint') ||
      (lower.contains(' at ') && lower.contains('.js'));
  if (statusCode == 404 && unsafe) return fallback;
  return unsafe ? fallback : text;
}

final _client = ApiClient();
const _base = 'api/school-admin/attendance';

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

Uri _listUrl({int? classId, String? date}) {
  final params = <String, String>{};
  if (classId != null && classId > 0) params['class_id'] = classId.toString();
  if (date != null && date.isNotEmpty) params['date'] = date;
  final uri = apiUrl(_base);
  return params.isEmpty ? uri : uri.replace(queryParameters: params);
}

class AttendanceService {
  AttendanceService._();
  static final AttendanceService _instance = AttendanceService._();
  factory AttendanceService() => _instance;

  /// GET /api/school-admin/attendance?class_id=&date=
  Future<AttendanceResult<List<AttendanceModel>>> listAttendance({int? classId, String? date}) async {
    try {
      final response = await _client.get(_listUrl(classId: classId, date: date));
      devLogResponse('AttendanceService.listAttendance', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return AttendanceError(_errorMessage(response) ?? 'Could not load attendance.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is List) list = data;
        else if (raw['attendance'] is List) list = raw['attendance'] as List<dynamic>;
        else if (raw['items'] is List) list = raw['items'] as List<dynamic>;
        else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) { found = value; break; }
          }
          if (found == null) return AttendanceError(_errorMessage(response) ?? 'Invalid response.');
          list = found;
        }
      } else {
        return AttendanceError('Invalid response from server.');
      }
      final records = <AttendanceModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try { records.add(AttendanceModel.fromJson(e)); } catch (_) {}
        }
      }
      return AttendanceSuccess(records);
    } catch (e, st) {
      return AttendanceError(userFriendlyMessage(e, st, 'AttendanceService.listAttendance'));
    }
  }

  /// GET /api/school-admin/attendance/{id}
  Future<AttendanceResult<AttendanceModel>> getAttendance(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('AttendanceService.getAttendance', response.statusCode, response.body);
      if (response.statusCode == 404) return AttendanceError('Attendance record not found.', 404);
      if (response.statusCode != 200) {
        return AttendanceError(_errorMessage(response) ?? 'Could not load record.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['attendance'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return AttendanceError('Invalid response from server.');
      }
      return AttendanceSuccess(AttendanceModel.fromJson(map));
    } catch (e, st) {
      return AttendanceError(userFriendlyMessage(e, st, 'AttendanceService.getAttendance'));
    }
  }

  /// PATCH /api/school-admin/attendance/{id}  Body: { status }
  Future<AttendanceResult<AttendanceModel>> updateAttendanceStatus(int id, Map<String, dynamic> payload) async {
    try {
      final status = payload['status'] is String ? payload['status'] as String : payload['status'].toString();
      final body = {'status': status};
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('AttendanceService.updateAttendanceStatus', response.statusCode, response.body);
      if (response.statusCode == 404) return AttendanceError('Attendance record not found.', 404);
      if (response.statusCode != 200) {
        return AttendanceError(_errorMessage(response) ?? 'Could not update.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['attendance'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return AttendanceError('Invalid response from server.');
      }
      return AttendanceSuccess(AttendanceModel.fromJson(map));
    } catch (e, st) {
      return AttendanceError(userFriendlyMessage(e, st, 'AttendanceService.updateAttendanceStatus'));
    }
  }

  /// DELETE /api/school-admin/attendance/{id}
  Future<AttendanceResult<bool>> deleteAttendance(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('AttendanceService.deleteAttendance', response.statusCode, response.body);
      if (response.statusCode == 404) return AttendanceError('Attendance record not found.', 404);
      if (response.statusCode != 200) {
        return AttendanceError(_errorMessage(response) ?? 'Could not delete.', response.statusCode);
      }
      return AttendanceSuccess(true);
    } catch (e, st) {
      return AttendanceError(userFriendlyMessage(e, st, 'AttendanceService.deleteAttendance'));
    }
  }

  // --- Lesson attendance (shared with Teacher attendance records) ---------
  // The backend derives teacher, subject, period, time and school from
  // timetable_id + the JWT; those are never sent from here. Every call logs
  // its request, response and failures to the terminal in debug builds
  // (attendance_diagnostics.dart) while users only see friendly messages.

  Map<String, String> _lessonQuery({
    required int academicYearId,
    required int classId,
    required String date,
    int? timetableId,
  }) => {
    'academic_year_id': academicYearId.toString(),
    'class_id': classId.toString(),
    'date': date,
    if (timetableId != null) 'timetable_id': timetableId.toString(),
  };

  AttendanceError _httpError(
    String operation,
    String method,
    http.Response response,
    Uri url,
    String fallback, {
    String tag = kAttendanceErrorTag,
  }) {
    final raw = _parseJson(response.body);
    final map = raw is Map ? raw : const {};
    final code = map['code']?.toString();
    final backendMessage = map['message']?.toString();
    logAttendanceError(
      tag: tag,
      operation: operation,
      endpoint: '$method ${url.path}',
      parameters: url.queryParameters,
      status: response.statusCode,
      code: code,
      message: backendMessage,
      responseBody: response.body,
    );
    return AttendanceError(
      lessonAttendanceErrorMessage(
        code: code,
        statusCode: response.statusCode,
        backendMessage: backendMessage,
        fallback: fallback,
      ),
      response.statusCode,
      code,
    );
  }

  /// A 200 whose body does not match the contract: never a crash, never a
  /// fake "server error" — a distinct INVALID_RESPONSE with full diagnostics.
  AttendanceError _invalidResponse(
    String operation,
    http.Response response,
    Uri url, {
    Object? exception,
    StackTrace? stackTrace,
    String tag = kAttendanceErrorTag,
  }) {
    logAttendanceError(
      tag: tag,
      operation: '$operation (parse)',
      endpoint: 'GET ${url.path}',
      parameters: url.queryParameters,
      status: response.statusCode,
      code: kInvalidResponseCode,
      message: 'Response did not match the expected attendance JSON contract.',
      responseBody: response.body,
      exception: exception,
      stackTrace: stackTrace,
    );
    return AttendanceError(
      lessonAttendanceErrorMessage(code: kInvalidResponseCode, fallback: ''),
      response.statusCode,
      kInvalidResponseCode,
    );
  }

  AttendanceError _exceptionError(
    String operation,
    Uri url,
    Object e,
    StackTrace st, {
    String tag = kAttendanceErrorTag,
  }) {
    logAttendanceError(
      tag: tag,
      operation: operation,
      endpoint: url.path,
      parameters: url.queryParameters,
      message: 'Request failed before a response was received.',
      exception: e,
      stackTrace: st,
    );
    return AttendanceError(
      userFriendlyMessage(e, st, 'AttendanceService.$operation'),
    );
  }

  /// Unwraps a `{data: {...}}` / `{register: {...}}` envelope if present;
  /// the current backend returns the object unwrapped.
  static Map<String, dynamic>? _payload(dynamic raw, String key) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map.containsKey('students') || map.containsKey('lessons')) return map;
    final nested = map[key] ?? map['data'];
    return nested is Map ? Map<String, dynamic>.from(nested) : map;
  }

  /// GET /api/school-admin/attendance/lessons?academic_year_id=&class_id=&date=
  Future<AttendanceResult<AttendanceLessonsResult>> listLessons({
    required int academicYearId,
    required int classId,
    required String date,
  }) async {
    const op = 'loadLessons';
    final url = apiUrl('$_base/lessons').replace(
      queryParameters: _lessonQuery(
        academicYearId: academicYearId,
        classId: classId,
        date: date,
      ),
    );
    logAttendanceRequest(op, 'GET', url);
    final http.Response response;
    try {
      response = await _client.get(url);
    } catch (e, st) {
      return _exceptionError(op, url, e, st);
    }
    logAttendanceResponse(op, response.statusCode, response.body);
    if (response.statusCode != 200) {
      return _httpError(
        op,
        'GET',
        response,
        url,
        'Could not load the lessons for this class.',
      );
    }
    try {
      final payload = _payload(_parseJson(response.body), 'lessons');
      if (payload == null || payload['lessons'] is! List) {
        return _invalidResponse(op, response, url);
      }
      return AttendanceSuccess(AttendanceLessonsResult.fromJson(payload));
    } catch (e, st) {
      return _invalidResponse(op, response, url, exception: e, stackTrace: st);
    }
  }

  /// GET /api/school-admin/attendance/register?academic_year_id=&class_id=&date=&timetable_id=
  ///
  /// A lesson with no attendance yet is a normal 200: every enrolled student
  /// comes back with `status: null`.
  Future<AttendanceResult<LessonRegister>> getRegister({
    required int academicYearId,
    required int classId,
    required String date,
    required int timetableId,
  }) async {
    const op = 'loadRegister';
    final url = apiUrl('$_base/register').replace(
      queryParameters: _lessonQuery(
        academicYearId: academicYearId,
        classId: classId,
        date: date,
        timetableId: timetableId,
      ),
    );
    logAttendanceRequest(op, 'GET', url);
    final http.Response response;
    try {
      response = await _client.get(url);
    } catch (e, st) {
      return _exceptionError(op, url, e, st);
    }
    logAttendanceResponse(op, response.statusCode, response.body);
    if (response.statusCode != 200) {
      return _httpError(
        op,
        'GET',
        response,
        url,
        'Could not load the attendance register.',
      );
    }
    try {
      final register = LessonRegister.tryParse(
        _payload(_parseJson(response.body), 'register'),
      );
      if (register == null) return _invalidResponse(op, response, url);
      return AttendanceSuccess(register);
    } catch (e, st) {
      return _invalidResponse(op, response, url, exception: e, stackTrace: st);
    }
  }

  /// PUT /api/school-admin/attendance/register
  /// Body: { academic_year_id, class_id, date, timetable_id, records: [{student_id, status}] }
  /// Partial: students omitted from [records] are left untouched by the backend.
  Future<AttendanceResult<RegisterSaveResult>> saveRegister({
    required int academicYearId,
    required int classId,
    required String date,
    required int timetableId,
    required List<RegisterRecord> records,
  }) async {
    const op = 'saveRegister';
    final url = apiUrl('$_base/register');
    final body = <String, Object?>{
      'academic_year_id': academicYearId,
      'class_id': classId,
      'date': date,
      'timetable_id': timetableId,
      'records': [for (final r in records) r.toJson()],
    };
    logAttendanceRequest(op, 'PUT', url, body: body);
    final http.Response response;
    try {
      response = await _client.put(url, body: body);
    } catch (e, st) {
      return _exceptionError(op, url, e, st);
    }
    logAttendanceResponse(op, response.statusCode, response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      return _httpError(
        op,
        'PUT',
        response,
        url,
        'Could not save attendance. Please try again.',
      );
    }
    try {
      final raw = _parseJson(response.body);
      // The save itself succeeded; a missing/odd embedded register only
      // means the caller reloads it with a GET.
      return AttendanceSuccess(
        raw is Map
            ? RegisterSaveResult.fromJson(Map<String, dynamic>.from(raw))
            : const RegisterSaveResult(),
      );
    } catch (e, st) {
      logAttendanceError(
        operation: '$op (parse)',
        endpoint: 'PUT ${url.path}',
        status: response.statusCode,
        responseBody: response.body,
        exception: e,
        stackTrace: st,
      );
      return AttendanceSuccess(const RegisterSaveResult());
    }
  }

  /// GET /api/school-admin/attendance/register/print -> application/pdf.
  /// 404 ATTENDANCE_NOT_RECORDED when the lesson has no attendance yet.
  Future<AttendanceResult<PdfFileResult>> printRegister({
    required int academicYearId,
    required int classId,
    required String date,
    required int timetableId,
  }) => _fetchPdf(
    'printRegister',
    apiUrl('$_base/register/print').replace(
      queryParameters: _lessonQuery(
        academicYearId: academicYearId,
        classId: classId,
        date: date,
        timetableId: timetableId,
      ),
    ),
    'Could not download the attendance PDF. Please try again.',
  );

  /// Binary PDF download shared by the lesson register and both reports.
  /// A 200 that is not a genuine PDF (HTML page, proxy error, JSON) is an
  /// error, never a file, and the body is never parsed as JSON on success.
  Future<AttendanceResult<PdfFileResult>> _fetchPdf(
    String op,
    Uri url,
    String fallback, {
    String tag = kAttendanceErrorTag,
  }) async {
    logAttendanceRequest(op, 'GET', url);
    final http.Response response;
    try {
      response = await _client.get(
        url,
        headers: const {'Accept': 'application/pdf'},
      );
    } catch (e, st) {
      return _exceptionError(op, url, e, st, tag: tag);
    }
    if (response.statusCode != 200) {
      logAttendanceResponse(op, response.statusCode, response.body);
      return _httpError(op, 'GET', response, url, fallback, tag: tag);
    }
    final file = pdfFileResultFromResponse(response);
    final b = file?.bytes;
    final isPdf = b != null &&
        b.length > 4 &&
        b[0] == 0x25 &&
        b[1] == 0x50 &&
        b[2] == 0x44 &&
        b[3] == 0x46;
    attendanceLog('[ADMIN ATTENDANCE RESPONSE]', {
      'operation': op,
      'status': response.statusCode,
      'content-type': response.headers['content-type'],
      'bytes': response.bodyBytes.length,
      'filename': file?.filename,
    });
    if (!isPdf) {
      logAttendanceError(
        tag: tag,
        operation: '$op (not a PDF)',
        endpoint: 'GET ${url.path}',
        parameters: url.queryParameters,
        status: response.statusCode,
        message: 'Expected application/pdf starting with %PDF.',
        responseBody: response.body,
      );
      return AttendanceError(fallback, response.statusCode);
    }
    return AttendanceSuccess(file!);
  }

  // --- Attendance reports ---------------------------------------------------
  // The JSON preview and the PDF share the backend report service, so the
  // same query parameters always describe the same report. School scope comes
  // from the JWT; school_id is never sent.

  Map<String, String> _reportQuery({
    required int academicYearId,
    required String startDate,
    required String endDate,
    int? classId,
  }) => {
    'academic_year_id': academicYearId.toString(),
    if (classId != null) 'class_id': classId.toString(),
    'start_date': startDate,
    'end_date': endDate,
  };

  Uri classReportUrl({
    required int academicYearId,
    required int classId,
    required String startDate,
    required String endDate,
    bool print = false,
  }) => apiUrl('$_base/reports/class${print ? '/print' : ''}').replace(
    queryParameters: _reportQuery(
      academicYearId: academicYearId,
      classId: classId,
      startDate: startDate,
      endDate: endDate,
    ),
  );

  Uri studentReportUrl({
    required int studentId,
    required int academicYearId,
    required String startDate,
    required String endDate,
    bool print = false,
  }) => apiUrl(
    '$_base/reports/student/$studentId${print ? '/print' : ''}',
  ).replace(
    queryParameters: _reportQuery(
      academicYearId: academicYearId,
      startDate: startDate,
      endDate: endDate,
    ),
  );

  Future<AttendanceResult<T>> _getReport<T>(
    String type,
    Uri url,
    Map<String, Object?> context,
    T? Function(dynamic) parse,
    int Function(T) recordCount,
  ) async {
    final op = '${type}Report';
    attendanceLog(kReportTag, {'Type': type, ...context});
    logAttendanceRequest(op, 'GET', url);
    final http.Response response;
    try {
      response = await _client.get(url);
    } catch (e, st) {
      return _exceptionError(op, url, e, st, tag: kReportErrorTag);
    }
    logAttendanceResponse(op, response.statusCode, response.body);
    if (response.statusCode != 200) {
      return _httpError(
        op,
        'GET',
        response,
        url,
        'Could not load the attendance report.',
        tag: kReportErrorTag,
      );
    }
    try {
      final report = parse(_parseJson(response.body));
      if (report == null) {
        return _invalidResponse(op, response, url, tag: kReportErrorTag);
      }
      attendanceLog('$kReportTag WORKING', {
        'Type': type,
        'Records': recordCount(report),
      });
      return AttendanceSuccess(report);
    } catch (e, st) {
      return _invalidResponse(
        op,
        response,
        url,
        exception: e,
        stackTrace: st,
        tag: kReportErrorTag,
      );
    }
  }

  /// GET /api/school-admin/attendance/reports/class
  Future<AttendanceResult<ClassAttendanceReport>> getClassReport({
    required int academicYearId,
    required int classId,
    required String startDate,
    required String endDate,
  }) => _getReport<ClassAttendanceReport>(
    'class',
    classReportUrl(
      academicYearId: academicYearId,
      classId: classId,
      startDate: startDate,
      endDate: endDate,
    ),
    {
      'AcademicYear': academicYearId,
      'Class': classId,
      'Start': startDate,
      'End': endDate,
    },
    ClassAttendanceReport.tryParse,
    (r) => r.summary.counts.recordedSessions,
  );

  /// GET /api/school-admin/attendance/reports/class/print
  Future<AttendanceResult<PdfFileResult>> printClassReport({
    required int academicYearId,
    required int classId,
    required String startDate,
    required String endDate,
  }) => _fetchPdf(
    'printClassReport',
    classReportUrl(
      academicYearId: academicYearId,
      classId: classId,
      startDate: startDate,
      endDate: endDate,
      print: true,
    ),
    'Could not download the class attendance PDF. Please try again.',
    tag: kReportErrorTag,
  );

  /// GET /api/school-admin/attendance/reports/student/:studentId
  Future<AttendanceResult<StudentAttendanceReport>> getStudentReport({
    required int studentId,
    required int academicYearId,
    required String startDate,
    required String endDate,
  }) => _getReport<StudentAttendanceReport>(
    'student',
    studentReportUrl(
      studentId: studentId,
      academicYearId: academicYearId,
      startDate: startDate,
      endDate: endDate,
    ),
    {
      'Student': studentId,
      'AcademicYear': academicYearId,
      'Start': startDate,
      'End': endDate,
    },
    StudentAttendanceReport.tryParse,
    (r) => r.counts.recordedSessions,
  );

  /// GET /api/school-admin/attendance/reports/student/:studentId/print
  Future<AttendanceResult<PdfFileResult>> printStudentReport({
    required int studentId,
    required int academicYearId,
    required String startDate,
    required String endDate,
  }) => _fetchPdf(
    'printStudentReport',
    studentReportUrl(
      studentId: studentId,
      academicYearId: academicYearId,
      startDate: startDate,
      endDate: endDate,
      print: true,
    ),
    'Could not download the student attendance PDF. Please try again.',
    tag: kReportErrorTag,
  );
}
