import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Exam model (school-admin scope).
/// POST /api/school-admin/exams requires: name, date, exam_type, weight.
/// Backend may include className, subjectName for display (from class_subjects).
class ExamModel {
  final int id;
  final String name;
  final String? date;
  final String? examType;
  final double? weight;
  final String? className;
  final String? subjectName;

  const ExamModel({
    required this.id,
    required this.name,
    this.date,
    this.examType,
    this.weight,
    this.className,
    this.subjectName,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    
    return ExamModel(
      id: parseId(json['id'] ?? json['exam_id']),
      name: str(json['name'] ?? json['exam_name'] ?? json['examName']),
      date: strOpt(json['date']),
      examType: strOpt(json['exam_type']),
      weight: json['weight'] != null ? (json['weight'] is num ? json['weight'].toDouble() : double.tryParse(json['weight'].toString())) : null,
      className: strOpt(json['class_name'] ?? json['className'] ?? json['class'] is Map ? (json['class'] as Map)['name'] : null),
      subjectName: strOpt(json['subject_name'] ?? json['subjectName'] ?? json['subject'] is Map ? (json['subject'] as Map)['name'] : null),
    );
  }
}

sealed class ExamResult<T> {}

class ExamSuccess<T> extends ExamResult<T> {
  final T data;
  ExamSuccess(this.data);
}

class ExamError extends ExamResult<Never> {
  final String message;
  final int? statusCode;
  ExamError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/exams';

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

class ExamsService {
  ExamsService._();
  static final ExamsService _instance = ExamsService._();
  factory ExamsService() => _instance;

  /// POST /api/school-admin/exams  Body: { name, date, exam_type, weight }
  Future<ExamResult<ExamModel>> createExam(Map<String, dynamic> data) async {
    try {
      int toInt(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
      double? toDouble(dynamic v) => v == null ? null : (v is double ? v : double.tryParse(v.toString()));
      
      final body = <String, dynamic>{
        'name': data['name']?.toString().trim() ?? '',
        'date': data['date']?.toString().trim() ?? '',
        'exam_type': data['exam_type']?.toString().trim(),
        'weight': toDouble(data['weight']),
      };
      
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('ExamsService.createExam', response.statusCode, response.body);
      
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map<String, dynamic>) return ExamError('Invalid response from server. Please try again.');
        return ExamSuccess(ExamModel.fromJson(raw));
      }
      if (response.statusCode == 400) return ExamError(_errorMessage(response) ?? 'Invalid data. Please try again.', 400);
      return ExamError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return ExamError(userFriendlyMessage(e, st, 'ExamsService.createExam'));
    }
  }

  /// GET /api/school-admin/exams
  Future<ExamResult<List<ExamModel>>> listExams() async {
    try {
      final response = await _client.get(apiUrl(_base));
      devLogResponse('ExamsService.listExams', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return ExamError(_errorMessage(response) ?? 'Could not load exams. Please try again.', response.statusCode);
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
          list = data['exams'] as List<dynamic>? ?? data['items'] as List<dynamic>? ?? [];
        } else if (raw['exams'] is List) {
          list = raw['exams'] as List<dynamic>;
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
          if (found == null) return ExamError(_errorMessage(response) ?? 'Invalid response from server. Please try again.');
          list = found;
        }
      } else {
        return ExamError('Invalid response from server. Please try again.');
      }
      final exams = <ExamModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            exams.add(ExamModel.fromJson(e));
          } catch (_) {}
        }
      }
      return ExamSuccess(exams);
    } catch (e, st) {
      return ExamError(userFriendlyMessage(e, st, 'ExamsService.listExams'));
    }
  }

  /// GET /api/school-admin/exams/{id}
  Future<ExamResult<ExamModel>> getExam(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('ExamsService.getExam', response.statusCode, response.body);
      if (response.statusCode == 404) return ExamError('Exam not found.', 404);
      if (response.statusCode != 200) {
        return ExamError(_errorMessage(response) ?? 'Could not load exam. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['exam'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return ExamError('Invalid response from server. Please try again.');
      }
      return ExamSuccess(ExamModel.fromJson(map));
    } catch (e, st) {
      return ExamError(userFriendlyMessage(e, st, 'ExamsService.getExam'));
    }
  }

  /// PATCH /api/school-admin/exams/{id}  Body: same as create — name, date, exam_type, weight
  Future<ExamResult<ExamModel>> updateExam(int id, Map<String, dynamic> data) async {
    try {
      double? toDouble(dynamic v) => v == null ? null : (v is double ? v : double.tryParse(v.toString()));
      
      final body = <String, dynamic>{
        'name': data['name'] is String ? data['name'] as String : data['name'].toString(),
        'date': data['date'] is String ? data['date'] as String : data['date']?.toString() ?? '',
        'exam_type': data['exam_type']?.toString(),
        'weight': toDouble(data['weight']),
      };
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('ExamsService.updateExam', response.statusCode, response.body);
      if (response.statusCode == 404) return ExamError('Exam not found.', 404);
      if (response.statusCode != 200) {
        return ExamError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['exam'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return ExamError('Invalid response from server. Please try again.');
      }
      return ExamSuccess(ExamModel.fromJson(map));
    } catch (e, st) {
      return ExamError(userFriendlyMessage(e, st, 'ExamsService.updateExam'));
    }
  }

  /// DELETE /api/school-admin/exams/{id}
  Future<ExamResult<bool>> deleteExam(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('ExamsService.deleteExam', response.statusCode, response.body);
      if (response.statusCode == 404) return ExamError('Exam not found.', 404);
      if (response.statusCode != 200) {
        return ExamError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return ExamSuccess(true);
    } catch (e, st) {
      return ExamError(userFriendlyMessage(e, st, 'ExamsService.deleteExam'));
    }
  }
}
