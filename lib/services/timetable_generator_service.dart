import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

sealed class GeneratorResult<T> {}

class GeneratorSuccess<T> extends GeneratorResult<T> {
  final T data;
  GeneratorSuccess(this.data);
}

class GeneratorError extends GeneratorResult<Never> {
  final String message;
  final int? statusCode;
  GeneratorError(this.message, [this.statusCode]);
}

class LevelSubjectPeriod {
  final int subjectId;
  final String subjectName;
  int periodsPerWeek;

  LevelSubjectPeriod({
    required this.subjectId,
    required this.subjectName,
    required this.periodsPerWeek,
  });

  factory LevelSubjectPeriod.fromJson(Map<String, dynamic> json) {
    final subject = _map(json['subject'] ?? json['Subject']);
    return LevelSubjectPeriod(
      subjectId: _int(json['subject_id'] ?? json['subjectId'] ?? subject['id']),
      subjectName: _text(
        json['subject_name'] ?? json['subjectName'] ?? subject['name'],
      ),
      periodsPerWeek: _int(
        json['periods_per_week'] ??
            json['periodsPerWeek'] ??
            json['weekly_periods'] ??
            json['periods'],
      ),
    );
  }
}

class DayOffPreview {
  final List<Map<String, dynamic>> teachers;
  final List<String> warnings;
  final Map<String, dynamic> raw;

  DayOffPreview({
    required this.teachers,
    required this.warnings,
    required this.raw,
  });

  factory DayOffPreview.fromJson(Map<String, dynamic> raw) {
    final data = _map(raw['data']);
    final values = _list(
      raw['teachers'] ??
          raw['day_offs'] ??
          raw['preview'] ??
          data['teachers'] ??
          data['day_offs'] ??
          data['preview'],
    );
    return DayOffPreview(
      teachers: values.whereType<Map>().map((v) => _map(v)).toList(),
      warnings: _messages(raw),
      raw: raw,
    );
  }
}

class TimetableGeneratorPreview {
  final bool feasible;
  final Map<String, dynamic> summary;
  final List<String> issues;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> raw;

  TimetableGeneratorPreview({
    required this.feasible,
    required this.summary,
    required this.issues,
    required this.rows,
    required this.raw,
  });

  factory TimetableGeneratorPreview.fromJson(Map<String, dynamic> raw) {
    final data = _map(raw['data']);
    final preview = _map(raw['preview'] ?? data['preview']);
    final source = preview.isNotEmpty
        ? preview
        : data.isNotEmpty
        ? data
        : raw;
    final feasibleValue =
        source['feasible'] ?? source['can_generate'] ?? source['canGenerate'];
    final rows = _list(
      source['timetable'] ??
          source['rows'] ??
          source['slots'] ??
          source['schedule'],
    );
    return TimetableGeneratorPreview(
      feasible:
          feasibleValue == true ||
          feasibleValue == 1 ||
          feasibleValue == 'true',
      summary: _map(source['summary'] ?? raw['summary']),
      issues: _messages(source),
      rows: rows.whereType<Map>().map((v) => _map(v)).toList(),
      raw: raw,
    );
  }
}

class TimetableGeneratorService {
  TimetableGeneratorService._();
  static final TimetableGeneratorService _instance =
      TimetableGeneratorService._();
  factory TimetableGeneratorService() => _instance;

  final ApiClient _client = ApiClient();
  static const _config = 'api/school-admin/timetable-config';
  static const _generator = 'api/school-admin/timetable-generator';

  Future<GeneratorResult<List<String>>> getWorkingDays(int yearId) async =>
      _get(
        '$_config/working-days?academic_year_id=$yearId',
        (raw) {
          final data = _map(raw['data']);
          return _list(
            raw['days'] ??
                raw['working_days'] ??
                raw['workingDays'] ??
                data['days'] ??
                data['working_days'],
          ).map((day) => day.toString().toUpperCase()).toList();
        },
        'Could not load working days.',
      );

  Future<GeneratorResult<List<String>>> saveWorkingDays(
    int yearId,
    Iterable<String> days,
  ) async {
    final normalizedDays = days.map((day) => day.toUpperCase()).toList();
    final body = <String, dynamic>{
      'academic_year_id': yearId,
      'days': normalizedDays,
    };
    if (kDebugMode) {
      debugPrint('[WorkingDays] academicYearId = $yearId');
      debugPrint('[WorkingDays] selectedDays = $normalizedDays');
      debugPrint(
        '[WorkingDays] selectedDays.length = ${normalizedDays.length}',
      );
      debugPrint('[WorkingDays] request body = $body');
    }
    return _put('$_config/working-days', body, (raw) {
      final data = _map(raw['data']);
      return _list(
        raw['days'] ??
            raw['working_days'] ??
            raw['workingDays'] ??
            data['days'] ??
            data['working_days'],
      ).map((day) => day.toString().toUpperCase()).toList();
    }, 'Could not save working days.');
  }

  Future<GeneratorResult<List<LevelSubjectPeriod>>> getLevelSubjects(
    int levelId,
    int yearId,
  ) async => _get(
    '$_config/levels/$levelId/subjects?academic_year_id=$yearId',
    (raw) =>
        _list(raw['subjects'] ?? _map(raw['data'])['subjects'] ?? raw['data'])
            .whereType<Map>()
            .map((v) => LevelSubjectPeriod.fromJson(_map(v)))
            .toList(),
    'Could not load weekly subject periods.',
  );

  Future<GeneratorResult<List<LevelSubjectPeriod>>> saveLevelSubjects(
    int levelId,
    int yearId,
    List<LevelSubjectPeriod> subjects,
  ) async => _put(
    '$_config/levels/$levelId/subjects',
    {
      'academic_year_id': yearId,
      'subjects': subjects
          .map(
            (subject) => {
              'subject_id': subject.subjectId,
              'periods_per_week': subject.periodsPerWeek,
            },
          )
          .toList(),
    },
    (_) => subjects,
    'Could not save weekly subject periods.',
  );

  Future<GeneratorResult<DayOffPreview>> previewDayOffs({
    required int academicYearId,
    required int levelId,
    required int daysOffPerTeacher,
  }) => _post(
    '$_generator/day-offs/preview',
    {
      'academic_year_id': academicYearId,
      'level_id': levelId,
      'days_off_per_teacher': daysOffPerTeacher,
    },
    DayOffPreview.fromJson,
    'Could not preview random teacher days off.',
  );

  Future<GeneratorResult<Map<String, dynamic>>> generateDayOffs({
    required int academicYearId,
    required int levelId,
    required int daysOffPerTeacher,
  }) => _post(
    '$_generator/day-offs/generate',
    {
      'academic_year_id': academicYearId,
      'level_id': levelId,
      'days_off_per_teacher': daysOffPerTeacher,
    },
    (raw) => raw,
    'Could not apply random teacher days off.',
  );

  Future<GeneratorResult<TimetableGeneratorPreview>> previewTimetable({
    required int academicYearId,
    required int levelId,
  }) => _post(
    '$_generator/preview',
    {'academic_year_id': academicYearId, 'level_id': levelId},
    TimetableGeneratorPreview.fromJson,
    'Could not preview the timetable.',
  );

  Future<GeneratorResult<Map<String, dynamic>>> generateTimetable({
    required int academicYearId,
    required int levelId,
    bool replaceExisting = false,
  }) => _post(
    '$_generator/generate',
    {
      'academic_year_id': academicYearId,
      'level_id': levelId,
      'replace_existing': replaceExisting,
    },
    (raw) => raw,
    'Could not generate the timetable.',
  );

  Future<GeneratorResult<T>> _get<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
    String fallback,
  ) async {
    try {
      final response = await _client.get(apiUrl(path));
      final raw = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GeneratorError(_error(raw, fallback), response.statusCode);
      }
      return GeneratorSuccess(parse(raw));
    } catch (error, stack) {
      return GeneratorError(userFriendlyMessage(error, stack, path));
    }
  }

  Future<GeneratorResult<T>> _put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse,
    String fallback,
  ) async {
    try {
      final response = await _client.put(apiUrl(path), body: body);
      final raw = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GeneratorError(_error(raw, fallback), response.statusCode);
      }
      return GeneratorSuccess(parse(raw));
    } catch (error, stack) {
      return GeneratorError(userFriendlyMessage(error, stack, path));
    }
  }

  Future<GeneratorResult<T>> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse,
    String fallback,
  ) async {
    try {
      final response = await _client.post(apiUrl(path), body: body);
      final raw = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GeneratorError(_error(raw, fallback), response.statusCode);
      }
      return GeneratorSuccess(parse(raw));
    } catch (error, stack) {
      return GeneratorError(userFriendlyMessage(error, stack, path));
    }
  }
}

Map<String, dynamic> _decode(String body) {
  try {
    final value = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  } catch (_) {
    return {};
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<dynamic> _list(dynamic value) => value is List ? value : const [];
int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
String _text(dynamic value) => value?.toString().trim() ?? '';

List<String> _messages(Map<String, dynamic> raw) {
  final values =
      raw['errors'] ??
      raw['issues'] ??
      raw['warnings'] ??
      raw['validation_errors'];
  if (values is List) {
    return values
        .map((value) {
          if (value is Map) {
            final map = _map(value);
            final prefix = [
              map['class_name'],
              map['subject_name'],
            ].where((v) => _text(v).isNotEmpty).map(_text).join(' / ');
            final message = _text(
              map['message'] ?? map['error'] ?? map['reason'],
            );
            return prefix.isEmpty ? message : '$prefix: $message';
          }
          return _text(value);
        })
        .where((value) => value.isNotEmpty)
        .toList();
  }
  return const [];
}

String _error(Map<String, dynamic> raw, String fallback) {
  final message = _text(
    raw['message'] ?? raw['error'] ?? _map(raw['data'])['message'],
  );
  if (message.isEmpty ||
      message.toLowerCase().contains('sql') ||
      message.toLowerCase().contains('<html'))
    return fallback;
  return message;
}
