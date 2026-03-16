import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/periods_service.dart';

/// Timetable slot model (school-admin scope).
/// API fields: id, class_id, subject_id, teacher_id, day, start_time, end_time, period_id, period
class TimetableSlotModel {
  final int id;
  final int classId;
  final int subjectId;
  final int teacherId;
  final String day;
  final String startTime;
  final String endTime;
  final int? periodId;
  final PeriodModel? period;

  const TimetableSlotModel({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.periodId,
    this.period,
  });

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    int? pid = parseId(json['period_id'] ?? json['periodId']);
    if (pid == 0) pid = null;
    
    PeriodModel? periodMod;
    final pObj = json['period'] ?? json['Period'];
    if (pObj is Map<String, dynamic>) {
      periodMod = PeriodModel.fromJson(pObj);
      if (pid == null && periodMod.id > 0) pid = periodMod.id;
    }

    return TimetableSlotModel(
      id: parseId(json['id'] ?? json['timetable_id']),
      classId: parseId(json['class_id'] ?? json['classId']),
      subjectId: parseId(json['subject_id'] ?? json['subjectId']),
      teacherId: parseId(json['teacher_id'] ?? json['teacherId']),
      day: str(json['day'] ?? 'MON').toUpperCase(),
      startTime: TimetableSlotModel.normalizeTime(str(json['start_time'] ?? json['startTime'] ?? periodMod?.startTime ?? '')),
      endTime: TimetableSlotModel.normalizeTime(str(json['end_time'] ?? json['endTime'] ?? periodMod?.endTime ?? '')),
      periodId: pid,
      period: periodMod,
    );
  }

  static String normalizeTime(String t) {
    if (t.isEmpty) return '00:00:00';
    final parts = t.trim().split(':');
    if (parts.length == 1) return '${parts[0].padLeft(2, '0')}:00:00';
    if (parts.length == 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
    if (parts.length >= 3) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:${parts[2].padLeft(2, '0')}';
    return t;
  }
}

sealed class TimetableResult<T> {}

class TimetableSuccess<T> extends TimetableResult<T> {
  final T data;
  TimetableSuccess(this.data);
}

class TimetableError extends TimetableResult<Never> {
  final String message;
  final int? statusCode;
  TimetableError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/timetables';

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

Uri _listUrl(int? classId) {
  final uri = apiUrl(_base);
  if (classId != null && classId > 0) {
    return uri.replace(queryParameters: {'class_id': classId.toString()});
  }
  return uri;
}

class TimetablesService {
  TimetablesService._();
  static final TimetablesService _instance = TimetablesService._();
  factory TimetablesService() => _instance;

  /// GET /api/school-admin/timetables?class_id=<id optional>
  Future<TimetableResult<List<TimetableSlotModel>>> listTimetables({int? classId}) async {
    try {
      final response = await _client.get(_listUrl(classId));
      devLogResponse('TimetablesService.listTimetables', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return TimetableError(_errorMessage(response) ?? 'Could not load timetable. Please try again.', response.statusCode);
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
          list = data['timetables'] as List<dynamic>? ?? data['items'] as List<dynamic>? ?? [];
        } else if (raw['timetables'] is List) {
          list = raw['timetables'] as List<dynamic>;
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
          if (found == null) return TimetableError(_errorMessage(response) ?? 'Invalid response from server. Please try again.');
          list = found;
        }
      } else {
        return TimetableError('Invalid response from server. Please try again.');
      }
      final slots = <TimetableSlotModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            slots.add(TimetableSlotModel.fromJson(e));
          } catch (_) {}
        }
      }
      return TimetableSuccess(slots);
    } catch (e, st) {
      return TimetableError(userFriendlyMessage(e, st, 'TimetablesService.listTimetables'));
    }
  }

  /// GET /api/school-admin/timetables/{id}
  Future<TimetableResult<TimetableSlotModel>> getTimetable(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('TimetablesService.getTimetable', response.statusCode, response.body);
      if (response.statusCode == 404) return TimetableError('Timetable slot not found.', 404);
      if (response.statusCode != 200) {
        return TimetableError(_errorMessage(response) ?? 'Could not load slot. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['timetable'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return TimetableError('Invalid response from server. Please try again.');
      }
      return TimetableSuccess(TimetableSlotModel.fromJson(map));
    } catch (e, st) {
      return TimetableError(userFriendlyMessage(e, st, 'TimetablesService.getTimetable'));
    }
  }

  /// POST /api/school-admin/timetables
  /// Body: class_id, subject_id, teacher_id, day, period_id (do NOT send id, start_time, end_time)
  Future<TimetableResult<TimetableSlotModel>> createTimetableSlot(Map<String, dynamic> payload) async {
    try {
      final body = <String, dynamic>{
        'class_id': payload['class_id'] is int ? payload['class_id'] as int : int.tryParse(payload['class_id'].toString()) ?? 0,
        'subject_id': payload['subject_id'] is int ? payload['subject_id'] as int : int.tryParse(payload['subject_id'].toString()) ?? 0,
        'teacher_id': payload['teacher_id'] is int ? payload['teacher_id'] as int : int.tryParse(payload['teacher_id'].toString()) ?? 0,
        'day': (payload['day'] as String? ?? '').toString().toUpperCase(),
      };
      
      if (payload['period_id'] != null) {
        body['period_id'] = payload['period_id'] is int ? payload['period_id'] as int : int.tryParse(payload['period_id'].toString()) ?? 0;
      }
      
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('TimetablesService.createTimetableSlot', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return TimetableError('Invalid response from server. Please try again.');
        final m = raw as Map<String, dynamic>;
        final slotMap = m['timetable'] ?? m['data'] ?? m;
        if (slotMap is! Map<String, dynamic>) return TimetableError('Invalid response from server. Please try again.');
        return TimetableSuccess(TimetableSlotModel.fromJson(slotMap));
      }
      if (response.statusCode == 409) return TimetableError('This teacher or class already has a timetable in that period.', 409);
      if (response.statusCode == 400) return TimetableError(_errorMessage(response) ?? 'Invalid data. Please try again.', 400);
      return TimetableError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return TimetableError(userFriendlyMessage(e, st, 'TimetablesService.createTimetableSlot'));
    }
  }

  /// PATCH /api/school-admin/timetables/{id}
  Future<TimetableResult<TimetableSlotModel>> updateTimetable(int id, Map<String, dynamic> payload) async {
    try {
      final body = <String, dynamic>{};
      if (payload.containsKey('day')) body['day'] = (payload['day'] as String? ?? '').toString().toUpperCase();
      if (payload.containsKey('period_id')) body['period_id'] = payload['period_id'] is int ? payload['period_id'] as int : int.tryParse(payload['period_id'].toString()) ?? 0;
      if (payload.containsKey('class_id')) body['class_id'] = payload['class_id'] is int ? payload['class_id'] as int : int.tryParse(payload['class_id'].toString()) ?? 0;
      if (payload.containsKey('subject_id')) body['subject_id'] = payload['subject_id'] is int ? payload['subject_id'] as int : int.tryParse(payload['subject_id'].toString()) ?? 0;
      if (payload.containsKey('teacher_id')) body['teacher_id'] = payload['teacher_id'] is int ? payload['teacher_id'] as int : int.tryParse(payload['teacher_id'].toString()) ?? 0;
      if (body.isEmpty) return TimetableError('No fields to update.');
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('TimetablesService.updateTimetable', response.statusCode, response.body);
      if (response.statusCode == 404) return TimetableError('Timetable slot not found.', 404);
      if (response.statusCode == 409) return TimetableError('This teacher or class already has a timetable in that period.', 409);
      if (response.statusCode != 200) {
        return TimetableError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['timetable'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return TimetableError('Invalid response from server. Please try again.');
      }
      return TimetableSuccess(TimetableSlotModel.fromJson(map));
    } catch (e, st) {
      return TimetableError(userFriendlyMessage(e, st, 'TimetablesService.updateTimetable'));
    }
  }

  /// DELETE /api/school-admin/timetables/{id}
  Future<TimetableResult<bool>> deleteTimetable(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('TimetablesService.deleteTimetable', response.statusCode, response.body);
      if (response.statusCode == 404) return TimetableError('Timetable slot not found.', 404);
      if (response.statusCode != 200) {
        return TimetableError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return TimetableSuccess(true);
    } catch (e, st) {
      return TimetableError(userFriendlyMessage(e, st, 'TimetablesService.deleteTimetable'));
    }
  }
}
