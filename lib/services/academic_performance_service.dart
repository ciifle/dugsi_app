import 'dart:convert';

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

int _int(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<dynamic> _list(dynamic value) => value is List ? value : const [];

sealed class PerformanceResult<T> {}

class PerformanceSuccess<T> extends PerformanceResult<T> {
  final T data;
  final String message;
  PerformanceSuccess(this.data, [this.message = '']);
}

class PerformanceError extends PerformanceResult<Never> {
  final String message;
  final int? statusCode;
  PerformanceError(this.message, [this.statusCode]);
}

class RankedStudent {
  final int position;
  final int studentId;
  final String name;
  final String emis;
  final String className;
  final double percentage;
  final String grade;
  final String status;

  const RankedStudent({
    required this.position,
    required this.studentId,
    required this.name,
    required this.emis,
    required this.className,
    required this.percentage,
    required this.grade,
    required this.status,
  });

  factory RankedStudent.fromJson(
    Map<String, dynamic> json, {
    bool schoolRank = false,
  }) {
    final classMap = _map(json['class']);
    return RankedStudent(
      position: _int(json[schoolRank ? 'school_position' : 'position']),
      studentId: _int(json['student_id']),
      name: (json['student_name'] ?? '').toString(),
      emis: (json['emis_number'] ?? '').toString(),
      className: (classMap['name'] ?? json['class_name'] ?? '').toString(),
      percentage: _double(json['percentage']),
      grade: (json['letter_grade'] ?? '').toString(),
      status: (json['result_status'] ?? '').toString(),
    );
  }
}

class SubjectPerformance {
  final String name;
  final double marks;
  final double maximum;
  final double percentage;
  final String grade;
  final String status;

  const SubjectPerformance({
    required this.name,
    required this.marks,
    required this.maximum,
    required this.percentage,
    required this.grade,
    required this.status,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    final subject = _map(json['subject']);
    return SubjectPerformance(
      name: (json['subject_name'] ?? subject['name'] ?? '').toString(),
      marks: _double(json['marks_obtained'] ?? json['obtained_marks']),
      maximum: _double(json['maximum_marks'] ?? json['max_marks']),
      percentage: _double(json['percentage']),
      grade: (json['letter_grade'] ?? json['grade'] ?? '').toString(),
      status: (json['result_status'] ?? json['status'] ?? '').toString(),
    );
  }
}

class StudentAcademicPerformance {
  final String studentName;
  final String yearName;
  final String className;
  final double totalMarks;
  final double maximumMarks;
  final double percentage;
  final String grade;
  final String status;
  final int? position;
  final int totalStudents;
  final List<SubjectPerformance> subjects;

  const StudentAcademicPerformance({
    required this.studentName,
    required this.yearName,
    required this.className,
    required this.totalMarks,
    required this.maximumMarks,
    required this.percentage,
    required this.grade,
    required this.status,
    required this.position,
    required this.totalStudents,
    required this.subjects,
  });

  factory StudentAcademicPerformance.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']).isNotEmpty ? _map(json['data']) : json;
    final student = _map(data['student']);
    final year = _map(data['academic_year']);
    final classMap = _map(data['class']);
    final performance = _map(data['performance']);
    final rawPosition = performance['class_position'];
    return StudentAcademicPerformance(
      studentName: (student['name'] ?? '').toString(),
      yearName: (year['name'] ?? '').toString(),
      className: (classMap['name'] ?? '').toString(),
      totalMarks: _double(performance['total_marks']),
      maximumMarks: _double(performance['maximum_marks']),
      percentage: _double(performance['percentage']),
      grade: (performance['letter_grade'] ?? '').toString(),
      status: (performance['result_status'] ?? '').toString(),
      position: rawPosition == null ? null : _int(rawPosition),
      totalStudents: _int(performance['total_students_in_class']),
      subjects: _list(data['subjects'])
          .whereType<Map>()
          .map((e) => SubjectPerformance.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ClassRankingResponse {
  final String className;
  final String yearName;
  final int total;
  final int passed;
  final int failed;
  final List<RankedStudent> students;

  const ClassRankingResponse({
    required this.className,
    required this.yearName,
    required this.total,
    required this.passed,
    required this.failed,
    required this.students,
  });

  factory ClassRankingResponse.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']).isNotEmpty ? _map(json['data']) : json;
    final summary = _map(data['summary']);
    return ClassRankingResponse(
      className: (_map(data['class'])['name'] ?? '').toString(),
      yearName: (_map(data['academic_year'])['name'] ?? '').toString(),
      total: _int(summary['total_students']),
      passed: _int(summary['passed_students']),
      failed: _int(summary['failed_students']),
      students: _list(data['students'])
          .whereType<Map>()
          .map((e) => RankedStudent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class TopStudentsResponse {
  final String yearName;
  final List<RankedStudent> students;

  const TopStudentsResponse({required this.yearName, required this.students});

  factory TopStudentsResponse.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']).isNotEmpty ? _map(json['data']) : json;
    return TopStudentsResponse(
      yearName: (_map(data['academic_year'])['name'] ?? '').toString(),
      students: _list(data['top_students'])
          .whereType<Map>()
          .map(
            (e) => RankedStudent.fromJson(
              Map<String, dynamic>.from(e),
              schoolRank: true,
            ),
          )
          .toList(),
    );
  }
}

class AcademicPerformanceService {
  final ApiClient _client = ApiClient();

  Future<PerformanceResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => _passwordRequest('api/student/profile/change-password', {
    'current_password': currentPassword,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  });

  Future<PerformanceResult<void>> resetStudentPassword({
    required int studentId,
    required String newPassword,
    required String confirmPassword,
  }) => _passwordRequest(
    'api/school-admin/students/$studentId/reset-password',
    {'new_password': newPassword, 'confirm_password': confirmPassword},
  );

  /// School admin's own password change (distinct from [resetStudentPassword],
  /// which resets a student's password). POST api/school-admin/change-password.
  Future<PerformanceResult<void>> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => _passwordRequest('api/school-admin/change-password', {
    'current_password': currentPassword,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  }, method: 'POST');

  Future<PerformanceResult<void>> _passwordRequest(
    String path,
    Map<String, String> body, {
    String method = 'PATCH',
  }) async {
    try {
      final response = method == 'POST'
          ? await _client.post(apiUrl(path), body: body)
          : await _client.patch(apiUrl(path), body: body);
      final json = _decode(response.body);
      final message = (_map(json)['message'] ?? '').toString();
      if (response.statusCode == 200) {
        return PerformanceSuccess(null, message);
      }
      return PerformanceError(
        message.isEmpty ? 'Request failed. Please try again.' : message,
        response.statusCode,
      );
    } catch (error, stack) {
      return PerformanceError(
        userFriendlyMessage(error, stack, 'AcademicPerformanceService'),
      );
    }
  }

  Future<PerformanceResult<StudentAcademicPerformance>> performance({
    int? academicYearId,
    int? examId,
  }) => _get('api/student/academic-performance', {
    if (academicYearId != null) 'academic_year_id': '$academicYearId',
    if (examId != null) 'exam_id': '$examId',
  }, StudentAcademicPerformance.fromJson);

  Future<PerformanceResult<ClassRankingResponse>> classRankings({
    required int classId,
    required int academicYearId,
    int? examId,
    int? limit,
    int? page,
  }) => _get(
    'api/school-admin/classes/$classId/student-rankings',
    {
      'academic_year_id': '$academicYearId',
      if (examId != null) 'exam_id': '$examId',
      if (limit != null) 'limit': '$limit',
      if (page != null) 'page': '$page',
    },
    ClassRankingResponse.fromJson,
  );

  Future<PerformanceResult<TopStudentsResponse>> topStudents({
    int? academicYearId,
    int? examId,
    int limit = 10,
  }) => _get('api/school-admin/analytics/top-students', {
    if (academicYearId != null) 'academic_year_id': '$academicYearId',
    if (examId != null) 'exam_id': '$examId',
    'limit': '$limit',
  }, TopStudentsResponse.fromJson);

  Future<PerformanceResult<T>> _get<T>(
    String path,
    Map<String, String> query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final uri = apiUrl(path).replace(queryParameters: query);
      final response = await _client.get(uri);
      final json = _decode(response.body);
      if (response.statusCode == 200 && json is Map) {
        return PerformanceSuccess(parse(Map<String, dynamic>.from(json)));
      }
      final message = (_map(json)['message'] ?? _map(json)['error']).toString();
      return PerformanceError(
        message.isEmpty ? 'Could not load data. Please try again.' : message,
        response.statusCode,
      );
    } catch (error, stack) {
      return PerformanceError(
        userFriendlyMessage(error, stack, 'AcademicPerformanceService'),
      );
    }
  }

  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
