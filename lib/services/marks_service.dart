import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Marks entry model (school-admin scope).
class MarkModel {
  final int id;
  final int examId;
  final int studentId;
  final int subjectId;
  final int marksObtained;
  final int maxMarks;
  final int? teacherId;
  final String? grade;
  final String? createdAt;

  const MarkModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    required this.marksObtained,
    required this.maxMarks,
    this.teacherId,
    this.grade,
    this.createdAt,
  });

  factory MarkModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    return MarkModel(
      id: parseId(json['id'] ?? json['mark_id']),
      examId: parseId(json['exam_id'] ?? json['examId']),
      studentId: parseId(json['student_id'] ?? json['studentId']),
      subjectId: parseId(json['subject_id'] ?? json['subjectId']),
      marksObtained: parseId(json['marks_obtained'] ?? json['marksObtained'] ?? 0),
      maxMarks: parseId(json['max_marks'] ?? json['maxMarks'] ?? 100),
      teacherId: json['teacher_id'] != null || json['teacherId'] != null ? parseId(json['teacher_id'] ?? json['teacherId']) : null,
      grade: strOpt(json['grade']),
      createdAt: strOpt(json['created_at'] ?? json['createdAt']),
    );
  }
}

sealed class MarkResult<T> {}

class MarkSuccess<T> extends MarkResult<T> {
  final T data;
  MarkSuccess(this.data);
}

class MarkError extends MarkResult<Never> {
  final String message;
  final int? statusCode;
  MarkError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/marks';

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

Uri _listUrl({int? examId, int? studentId, int? classId, int? subjectId}) {
  final params = <String, String>{};
  if (examId != null && examId > 0) params['exam_id'] = examId.toString();
  if (studentId != null && studentId > 0) params['student_id'] = studentId.toString();
  if (classId != null && classId > 0) params['class_id'] = classId.toString();
  if (subjectId != null && subjectId > 0) params['subject_id'] = subjectId.toString();
  final uri = apiUrl(_base);
  return params.isEmpty ? uri : uri.replace(queryParameters: params);
}

class MarksService {
  MarksService._();
  static final MarksService _instance = MarksService._();
  factory MarksService() => _instance;

  /// GET /api/school-admin/marks?exam_id=&student_id=&class_id=&subject_id=
  Future<MarkResult<List<MarkModel>>> listMarks({int? examId, int? studentId, int? classId, int? subjectId}) async {
    try {
      final response = await _client.get(_listUrl(examId: examId, studentId: studentId, classId: classId, subjectId: subjectId));
      devLogResponse('MarksService.listMarks', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not load marks. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is List) list = data;
        else if (raw['marks'] is List) list = raw['marks'] as List<dynamic>;
        else if (raw['items'] is List) list = raw['items'] as List<dynamic>;
        else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) { found = value; break; }
          }
          if (found == null) return MarkError(_errorMessage(response) ?? 'Invalid response.');
          list = found;
        }
      } else {
        return MarkError('Invalid response from server.');
      }
      final marks = <MarkModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try { marks.add(MarkModel.fromJson(e)); } catch (_) {}
        }
      }
      return MarkSuccess(marks);
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.listMarks'));
    }
  }

  /// GET /api/school-admin/marks/{id}
  Future<MarkResult<MarkModel>> getMark(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('MarksService.getMark', response.statusCode, response.body);
      if (response.statusCode == 404) return MarkError('Marks entry not found.', 404);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not load marks entry.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['mark'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return MarkError('Invalid response from server.');
      }
      return MarkSuccess(MarkModel.fromJson(map));
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.getMark'));
    }
  }

  /// POST /api/school-admin/marks
  Future<MarkResult<MarkModel>> createMark(Map<String, dynamic> payload) async {
    try {
      final body = <String, dynamic>{
        'exam_id': payload['exam_id'] is int ? payload['exam_id'] as int : int.tryParse(payload['exam_id'].toString()) ?? 0,
        'student_id': payload['student_id'] is int ? payload['student_id'] as int : int.tryParse(payload['student_id'].toString()) ?? 0,
        'subject_id': payload['subject_id'] is int ? payload['subject_id'] as int : int.tryParse(payload['subject_id'].toString()) ?? 0,
        'marks_obtained': payload['marks_obtained'] is int ? payload['marks_obtained'] as int : int.tryParse(payload['marks_obtained'].toString()) ?? 0,
        'max_marks': payload['max_marks'] is int ? payload['max_marks'] as int : int.tryParse(payload['max_marks'].toString()) ?? 100,
        'teacher_id': payload['teacher_id'] is int ? payload['teacher_id'] as int : int.tryParse(payload['teacher_id'].toString()) ?? 0,
      };
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('MarksService.createMark', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return MarkError('Invalid response from server.');
        final m = raw as Map<String, dynamic>;
        final map = m['mark'] ?? m['data'] ?? m;
        if (map is! Map<String, dynamic>) return MarkError('Invalid response from server.');
        return MarkSuccess(MarkModel.fromJson(map));
      }
      if (response.statusCode == 400) return MarkError(_errorMessage(response) ?? 'Invalid data.', 400);
      return MarkError(_errorMessage(response) ?? 'Request failed.', response.statusCode);
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.createMark'));
    }
  }

  /// PATCH /api/school-admin/marks/{id}
  Future<MarkResult<MarkModel>> updateMark(int id, Map<String, dynamic> payload) async {
    try {
      final body = <String, dynamic>{};
      if (payload.containsKey('marks_obtained')) body['marks_obtained'] = payload['marks_obtained'] is int ? payload['marks_obtained'] as int : int.tryParse(payload['marks_obtained'].toString()) ?? 0;
      if (payload.containsKey('max_marks')) body['max_marks'] = payload['max_marks'] is int ? payload['max_marks'] as int : int.tryParse(payload['max_marks'].toString()) ?? 100;
      if (payload.containsKey('teacher_id')) body['teacher_id'] = payload['teacher_id'] is int ? payload['teacher_id'] as int : int.tryParse(payload['teacher_id'].toString()) ?? 0;
      if (body.isEmpty) return MarkError('No fields to update.');
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('MarksService.updateMark', response.statusCode, response.body);
      if (response.statusCode == 404) return MarkError('Marks entry not found.', 404);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not update.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['mark'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return MarkError('Invalid response from server.');
      }
      return MarkSuccess(MarkModel.fromJson(map));
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.updateMark'));
    }
  }

  /// DELETE /api/school-admin/marks/{id}
  Future<MarkResult<bool>> deleteMark(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('MarksService.deleteMark', response.statusCode, response.body);
      if (response.statusCode == 404) return MarkError('Marks entry not found.', 404);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not delete.', response.statusCode);
      }
      return MarkSuccess(true);
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.deleteMark'));
    }
  }
}
