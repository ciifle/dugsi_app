import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Attendance record model (school-admin scope).
class AttendanceModel {
  final int id;
  final int? studentId;
  final int? classId;
  final String? date;
  final String? status;
  final String? recordedAt;
  final String? createdAt;

  const AttendanceModel({
    required this.id,
    this.studentId,
    this.classId,
    this.date,
    this.status,
    this.recordedAt,
    this.createdAt,
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
  AttendanceError(this.message, [this.statusCode]);
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
}
