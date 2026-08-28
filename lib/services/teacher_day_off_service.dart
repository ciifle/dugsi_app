import 'dart:convert';

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

const teacherDayLabels = <String, String>{
  'MON': 'Monday',
  'TUE': 'Tuesday',
  'WED': 'Wednesday',
  'THU': 'Thursday',
  'FRI': 'Friday',
  'SAT': 'Saturday',
  'SUN': 'Sunday',
};

String dayCodeToLabel(String code) =>
    teacherDayLabels[code.toUpperCase()] ?? code.toUpperCase();

String? dayLabelToCode(String label) {
  final normalized = label.trim().toLowerCase();
  for (final entry in teacherDayLabels.entries) {
    if (entry.value.toLowerCase() == normalized) return entry.key;
  }
  return null;
}

class TeacherDayOffTeacher {
  final int id;
  final String fullName;

  const TeacherDayOffTeacher({required this.id, required this.fullName});

  factory TeacherDayOffTeacher.fromJson(Map<String, dynamic> json) =>
      TeacherDayOffTeacher(
        id: _id(json['id'] ?? json['teacher_id']),
        fullName: _text(json['fullName'] ?? json['full_name'] ?? json['name']),
      );
}

class TeacherDayOff {
  final int id;
  final int teacherId;
  final String day;
  final bool isActive;
  final TeacherDayOffTeacher? teacher;

  const TeacherDayOff({
    required this.id,
    required this.teacherId,
    required this.day,
    required this.isActive,
    this.teacher,
  });

  String get dayLabel => teacherDayLabels[day] ?? day;
  String get teacherName => teacher?.fullName ?? 'Teacher #$teacherId';

  factory TeacherDayOff.fromJson(Map<String, dynamic> json) {
    final rawTeacher = json['teacher'] ?? json['Teacher'];
    final teacher = rawTeacher is Map
        ? TeacherDayOffTeacher.fromJson(Map<String, dynamic>.from(rawTeacher))
        : null;
    return TeacherDayOff(
      id: _id(json['id']),
      teacherId: _id(json['teacher_id'] ?? json['teacherId'] ?? teacher?.id),
      day: _text(json['day']).toUpperCase(),
      isActive: _bool(json['is_active'] ?? json['isActive'] ?? json['active']),
      teacher: teacher,
    );
  }
}

sealed class TeacherDayOffResult<T> {}

class TeacherDayOffSuccess<T> extends TeacherDayOffResult<T> {
  final T data;
  TeacherDayOffSuccess(this.data);
}

class TeacherDayOffError extends TeacherDayOffResult<Never> {
  final String message;
  final int? statusCode;
  TeacherDayOffError(this.message, [this.statusCode]);
}

class TeacherDayOffBulkResponse {
  final int createdCount;
  final List<TeacherDayOff> records;
  const TeacherDayOffBulkResponse({
    required this.createdCount,
    required this.records,
  });
}

class TeacherDayOffService {
  TeacherDayOffService._();
  static final TeacherDayOffService _instance = TeacherDayOffService._();
  factory TeacherDayOffService() => _instance;

  static const _base = 'api/school-admin/teacher-day-offs';
  final ApiClient _client = ApiClient();
  List<TeacherDayOff> _cache = const [];

  List<TeacherDayOff> get cached => List.unmodifiable(_cache);

  bool isTeacherOff(int teacherId, String day) => _cache.any(
    (item) =>
        item.isActive &&
        item.teacherId == teacherId &&
        item.day == day.toUpperCase(),
  );

  Future<TeacherDayOffResult<List<TeacherDayOff>>> list() async {
    try {
      final response = await _client.get(apiUrl(_base));
      if (response.statusCode != 200) return _error(response);
      final raw = _json(response.body);
      final list = raw is List
          ? raw
          : raw is Map
          ? (raw['teacher_day_offs'] ?? raw['day_offs'] ?? raw['data'])
          : null;
      final values = list is List
          ? list
                .whereType<Map>()
                .map(
                  (item) =>
                      TeacherDayOff.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <TeacherDayOff>[];
      _cache = values;
      return TeacherDayOffSuccess(values);
    } catch (error, stackTrace) {
      return TeacherDayOffError(
        userFriendlyMessage(error, stackTrace, 'TeacherDayOffService.list'),
      );
    }
  }

  Future<TeacherDayOffResult<TeacherDayOff>> get(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      if (response.statusCode != 200) return _error(response);
      return TeacherDayOffSuccess(_one(_json(response.body)));
    } catch (error, stackTrace) {
      return TeacherDayOffError(
        userFriendlyMessage(error, stackTrace, 'TeacherDayOffService.get'),
      );
    }
  }

  Future<TeacherDayOffResult<TeacherDayOff>> create({
    required int teacherId,
    required String day,
    bool isActive = true,
  }) => _write(null, {
    'teacher_id': teacherId,
    'day': day,
    'is_active': isActive,
  });

  Future<TeacherDayOffResult<TeacherDayOffBulkResponse>> createBulk({
    required int teacherId,
    required List<String> days,
  }) async {
    final normalized = days.map((day) => day.toUpperCase()).toSet().toList();
    if (normalized.isEmpty) {
      return TeacherDayOffError('Select at least one day off.', 400);
    }
    try {
      final response = await _client.post(
        apiUrl('$_base/bulk'),
        body: {'teacher_id': teacherId, 'days': normalized},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _error(response);
      }
      final raw = _json(response.body);
      final map = raw is Map ? raw : const {};
      final rawRecords =
          map['teacher_day_offs'] ?? map['day_offs'] ?? map['data'];
      final records = rawRecords is List
          ? rawRecords
                .whereType<Map>()
                .map(
                  (item) =>
                      TeacherDayOff.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <TeacherDayOff>[];
      final createdCount = _id(
        map['created_count'] ?? map['createdCount'] ?? records.length,
      );
      await list();
      return TeacherDayOffSuccess(
        TeacherDayOffBulkResponse(createdCount: createdCount, records: records),
      );
    } catch (error, stackTrace) {
      return TeacherDayOffError(
        userFriendlyMessage(
          error,
          stackTrace,
          'TeacherDayOffService.createBulk',
        ),
      );
    }
  }

  Future<TeacherDayOffResult<TeacherDayOff>> update(
    int id, {
    required int teacherId,
    required String day,
    required bool isActive,
  }) =>
      _write(id, {'teacher_id': teacherId, 'day': day, 'is_active': isActive});

  Future<TeacherDayOffResult<TeacherDayOff>> _write(
    int? id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = id == null
          ? await _client.post(apiUrl(_base), body: body)
          : await _client.patch(apiUrl('$_base/$id'), body: body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _error(response);
      }
      final item = _one(_json(response.body));
      await list();
      return TeacherDayOffSuccess(item);
    } catch (error, stackTrace) {
      return TeacherDayOffError(
        userFriendlyMessage(error, stackTrace, 'TeacherDayOffService.write'),
      );
    }
  }

  Future<TeacherDayOffResult<bool>> delete(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _error(response);
      }
      await list();
      return TeacherDayOffSuccess(true);
    } catch (error, stackTrace) {
      return TeacherDayOffError(
        userFriendlyMessage(error, stackTrace, 'TeacherDayOffService.delete'),
      );
    }
  }

  TeacherDayOff _one(dynamic raw) {
    final value = raw is Map
        ? raw['teacher_day_off'] ?? raw['day_off'] ?? raw['data'] ?? raw
        : null;
    return TeacherDayOff.fromJson(Map<String, dynamic>.from(value as Map));
  }

  TeacherDayOffError _error(dynamic response) {
    final raw = _json(response.body);
    var message = raw is Map ? _text(raw['message'] ?? raw['error']) : '';
    if (raw is Map && raw['conflicting_days'] is List) {
      final labels = (raw['conflicting_days'] as List)
          .map((day) => dayCodeToLabel('$day'))
          .toList();
      if (labels.isNotEmpty && message.isEmpty) {
        message =
            'Timetable lessons conflict on ${_joinLabels(labels)}. Reschedule them before marking these days off.';
      }
    }
    return TeacherDayOffError(
      message.isEmpty ? 'Could not update teacher day off.' : message,
      response.statusCode as int?,
    );
  }
}

String _joinLabels(List<String> labels) {
  if (labels.length == 1) return labels.first;
  if (labels.length == 2) return '${labels.first} and ${labels.last}';
  return '${labels.take(labels.length - 1).join(', ')}, and ${labels.last}';
}

dynamic _json(String body) {
  try {
    return body.isEmpty ? null : jsonDecode(body);
  } catch (_) {
    return null;
  }
}

int _id(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
String _text(dynamic value) => value?.toString().trim() ?? '';
bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String)
    return !{'false', '0', 'inactive'}.contains(value.toLowerCase());
  return true;
}
