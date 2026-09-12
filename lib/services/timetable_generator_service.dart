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
  final Map<String, dynamic> details;
  GeneratorError(this.message, [this.statusCode, this.details = const {}]);
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

bool _asBool(dynamic value) => value == true || value == 1 || value == 'true';

/// Backend reason codes mapped to fixed, friendly explanations. Per the
/// documented contract, class-capacity shortage (CLASS_CAPACITY_EXCEEDED) is
/// never a blocking condition; the others describe why a specific lesson
/// couldn't be placed and may appear either on a capacity-warning row or a
/// hard-blocking error entry, depending on severity.
const Map<String, String> timetableReasonMessages = {
  'CLASS_CAPACITY_EXCEEDED':
      'This class has fewer physical weekly timetable slots than requested.',
  'TEACHER_DAY_OFF':
      'Teacher unavailable because of a configured weekly day off.',
  'TEACHER_TIME_CONFLICT':
      'Teacher is already required by another class in the same slot.',
  'CLASS_TIME_CONFLICT': 'Class already has another lesson in that slot.',
  'NO_VALID_SHIFT_SLOT': 'No valid period remains in the class shift.',
  'SOLVER_EXHAUSTED':
      'Unable to fit all requested lessons within current constraints.',
};

String? reasonCodeMessage(String? code) {
  if (code == null || code.isEmpty) return null;
  return timetableReasonMessages[code.toUpperCase()];
}

/// One subject's requested-vs-scheduled outcome within a class, from the
/// backend's per-class subject_results breakdown.
class TimetableSubjectResult {
  final String subjectName;
  final int? requested;
  final int? scheduled;
  final int? unscheduled;

  const TimetableSubjectResult({
    required this.subjectName,
    this.requested,
    this.scheduled,
    this.unscheduled,
  });

  bool get hasUnscheduled => (unscheduled ?? 0) > 0;

  factory TimetableSubjectResult.fromJson(Map<String, dynamic> json) {
    final subjectField = json['subject'];
    return TimetableSubjectResult(
      subjectName: _text(
        json['subject_name'] ??
            json['subjectName'] ??
            (subjectField is Map ? subjectField['name'] : subjectField),
      ),
      requested: _optInt(
        json['requested'] ??
            json['requested_periods'] ??
            json['requestedPeriods'],
      ),
      scheduled: _optInt(
        json['scheduled'] ??
            json['scheduled_periods'] ??
            json['scheduledPeriods'],
      ),
      unscheduled: _optInt(
        json['unscheduled'] ??
            json['unscheduled_periods'] ??
            json['unscheduledPeriods'],
      ),
    );
  }
}

/// A single class's capacity-warning row from the backend preview, per the
/// documented contract: requested_periods, available_periods,
/// maximum_schedulable_periods, scheduled_periods, unscheduled_periods,
/// capacity_warning, and a subject_results breakdown. Aliases are accepted
/// since no formal response schema is published for this endpoint.
class TimetableCapacityIssue {
  final String className;
  final int? requested;
  final int? available;
  final int? maxSchedulable;
  final int? scheduled;
  final int? unscheduled;
  final String? reasonCode;
  final String? message;
  final List<TimetableSubjectResult> subjectResults;

  const TimetableCapacityIssue({
    required this.className,
    this.requested,
    this.available,
    this.maxSchedulable,
    this.scheduled,
    this.unscheduled,
    this.reasonCode,
    this.message,
    this.subjectResults = const [],
  });

  /// True only when the backend actually reported both sides of the
  /// shortage — never inferred or computed locally beyond arithmetic on the
  /// backend-provided numbers themselves.
  bool get isCapacityShaped => requested != null && available != null;

  /// The exact backend reason where known, falling back to its own message,
  /// then to a generic capacity explanation. Never a locally-invented claim
  /// about *why* (e.g. never says "teacher conflict" for a capacity row).
  String get reasonText {
    final code = reasonCode?.toUpperCase();
    if (code == 'CLASS_CAPACITY_EXCEEDED' && available != null) {
      return 'This class has $available physical weekly timetable slots.';
    }
    final mapped = reasonCodeMessage(reasonCode);
    if (mapped != null) return mapped;
    if (message != null && message!.isNotEmpty) return message!;
    return 'This class has fewer physical weekly timetable slots than requested.';
  }

  factory TimetableCapacityIssue.fromJson(Map<String, dynamic> json) {
    final requested = _optInt(
      json['requested_periods'] ??
          json['requestedPeriods'] ??
          json['required_periods'] ??
          json['required'],
    );
    final available = _optInt(
      json['available_periods'] ??
          json['availablePeriods'] ??
          json['available'] ??
          json['capacity'],
    );
    final maxSchedulable = _optInt(
      json['maximum_schedulable_periods'] ??
          json['maximumSchedulablePeriods'] ??
          json['max_schedulable_periods'],
    );
    final scheduled = _optInt(
      json['scheduled_periods'] ??
          json['scheduledPeriods'] ??
          json['scheduled'],
    );
    var unscheduled = _optInt(
      json['unscheduled_periods'] ??
          json['unscheduledPeriods'] ??
          json['unscheduled'] ??
          json['additional_slots_needed'] ??
          json['shortfall'],
    );
    if (unscheduled == null && requested != null && scheduled != null) {
      unscheduled = requested - scheduled;
    } else if (unscheduled == null && requested != null && available != null) {
      unscheduled = requested - available;
    }
    final classField = json['class'];
    final code = _text(
      json['reason_code'] ?? json['reasonCode'] ?? json['code'],
    );
    final msg = _text(json['message'] ?? json['error'] ?? json['reason']);
    return TimetableCapacityIssue(
      className: _text(
        json['class_name'] ??
            json['className'] ??
            (classField is Map ? classField['name'] : classField),
      ),
      requested: requested,
      available: available,
      maxSchedulable: maxSchedulable,
      scheduled: scheduled,
      unscheduled: unscheduled,
      reasonCode: code.isEmpty ? null : code,
      message: msg.isEmpty ? null : msg,
      subjectResults: _list(json['subject_results'] ?? json['subjectResults'])
          .whereType<Map>()
          .map((v) => TimetableSubjectResult.fromJson(_map(v)))
          .toList(),
    );
  }
}

class TimetableGeneratorPreview {
  final bool feasible;
  final bool canGenerate;
  final Map<String, dynamic> summary;
  final List<String> issues;
  final List<TimetableCapacityIssue> capacityIssues;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> raw;

  TimetableGeneratorPreview({
    required this.feasible,
    required this.canGenerate,
    required this.summary,
    required this.issues,
    required this.capacityIssues,
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
    final feasibleValue = source['feasible'];
    final rows = _list(
      source['timetable'] ??
          source['rows'] ??
          source['slots'] ??
          source['schedule'],
    );
    // Real, hard-blocking structural errors only: missing teacher
    // assignment, a class with no valid shift periods, no working days
    // configured, or a teacher whose day-offs cover every working day.
    // Capacity shortfalls are never reported here per the documented
    // contract.
    final errorValues = _list(
      source['errors'] ?? source['blocking_errors'] ?? source['blockingErrors'],
    );
    // Full per-class breakdown (requested/available/scheduled/unscheduled +
    // subject_results), when the backend reports every class rather than
    // only the ones with a shortage.
    final classRows = _list(
      source['classes'] ?? source['class_results'] ?? source['results'],
    );
    // The documented summarized array of just the over-capacity classes.
    final capacityWarningValues = _list(
      source['capacity_warnings'] ??
          source['capacity_issues'] ??
          source['class_capacity'],
    );
    final capacityIssues = <TimetableCapacityIssue>[];
    if (capacityWarningValues.isNotEmpty) {
      capacityIssues.addAll(
        capacityWarningValues.whereType<Map>().map(
          (v) => TimetableCapacityIssue.fromJson(_map(v)),
        ),
      );
    } else {
      for (final row in classRows.whereType<Map>()) {
        final map = _map(row);
        final flagged =
            map['capacity_warning'] == true || map['capacityWarning'] == true;
        final issue = TimetableCapacityIssue.fromJson(map);
        if (flagged ||
            (issue.isCapacityShaped && (issue.unscheduled ?? 0) > 0)) {
          capacityIssues.add(issue);
        }
      }
    }
    // Backward-compatible fallback for responses that don't split errors
    // from capacity data into their own arrays — split a single combined
    // `issues`/`warnings` list by shape instead.
    final remainingIssues = <dynamic>[];
    if (errorValues.isEmpty &&
        capacityWarningValues.isEmpty &&
        classRows.isEmpty) {
      final looseValues = _list(
        source['issues'] ?? source['warnings'] ?? source['validation_errors'],
      );
      for (final value in looseValues) {
        final issue = value is Map
            ? TimetableCapacityIssue.fromJson(_map(value))
            : null;
        if (issue != null && issue.isCapacityShaped) {
          capacityIssues.add(issue);
        } else {
          remainingIssues.add(value);
        }
      }
    } else {
      remainingIssues.addAll(errorValues);
    }
    final canGenerateField =
        source['can_generate'] ?? source['canGenerate'] ?? raw['can_generate'];
    return TimetableGeneratorPreview(
      feasible: _asBool(feasibleValue),
      // The backend can report feasible:false purely because a requested
      // total exceeds capacity while still allowing generation to proceed
      // with a best-effort schedule. Flutter must not re-derive infeasible
      // from the raw numbers — only from whether a real (non-capacity)
      // blocking issue was reported, or an explicit can_generate flag.
      canGenerate: canGenerateField != null
          ? _asBool(canGenerateField)
          : remainingIssues.isEmpty,
      summary: _map(source['summary'] ?? raw['summary']),
      issues: _toMessages(remainingIssues),
      capacityIssues: capacityIssues,
      rows: rows.whereType<Map>().map((v) => _map(v)).toList(),
      raw: raw,
    );
  }
}

/// One class's outcome after generation — how many of its requested weekly
/// periods were actually scheduled. Field names follow the same documented
/// per-class shape as the preview response.
class TimetableScheduleSummary {
  final String className;
  final int? requested;
  final int? scheduled;
  final int? unscheduled;

  const TimetableScheduleSummary({
    required this.className,
    this.requested,
    this.scheduled,
    this.unscheduled,
  });

  bool get hasUnscheduled => (unscheduled ?? 0) > 0;

  factory TimetableScheduleSummary.fromJson(Map<String, dynamic> json) {
    final classField = json['class'];
    return TimetableScheduleSummary(
      className: _text(
        json['class_name'] ??
            json['className'] ??
            (classField is Map ? classField['name'] : classField),
      ),
      requested: _optInt(
        json['requested_periods'] ??
            json['requestedPeriods'] ??
            json['required_periods'] ??
            json['required'],
      ),
      scheduled: _optInt(
        json['scheduled_periods'] ??
            json['scheduledPeriods'] ??
            json['scheduled'],
      ),
      unscheduled: _optInt(
        json['unscheduled_periods'] ??
            json['unscheduledPeriods'] ??
            json['unscheduled'] ??
            json['additional_slots_needed'] ??
            json['shortfall'],
      ),
    );
  }
}

class TimetableGenerationResult {
  final Map<String, dynamic> raw;

  /// Every class the backend reported, when a full breakdown was returned;
  /// otherwise just the classes it flagged with unscheduled periods.
  final List<TimetableScheduleSummary> classes;
  final List<TimetableScheduleSummary> unscheduled;

  const TimetableGenerationResult({
    required this.raw,
    required this.classes,
    required this.unscheduled,
  });

  /// Best-effort totals from whatever class list the backend returned. If
  /// only the affected subset was reported (rather than every class),
  /// these totals cover only that subset — never independently computed.
  int get totalScheduled =>
      classes.fold(0, (sum, c) => sum + (c.scheduled ?? 0));
  int get totalUnscheduled =>
      classes.fold(0, (sum, c) => sum + (c.unscheduled ?? 0));

  factory TimetableGenerationResult.fromJson(Map<String, dynamic> raw) {
    final data = _map(raw['data']);
    final fullValues = _list(
      raw['classes'] ??
          raw['class_results'] ??
          raw['results'] ??
          data['classes'] ??
          data['class_results'] ??
          data['results'],
    );
    final partialValues = fullValues.isEmpty
        ? _list(
            raw['unscheduled'] ??
                raw['unscheduled_periods'] ??
                raw['capacity_warnings'] ??
                raw['capacity_issues'] ??
                data['unscheduled'] ??
                data['capacity_warnings'],
          )
        : const [];
    final classes = (fullValues.isNotEmpty ? fullValues : partialValues)
        .whereType<Map>()
        .map((v) => TimetableScheduleSummary.fromJson(_map(v)))
        .toList();
    return TimetableGenerationResult(
      raw: raw,
      classes: classes,
      unscheduled: classes.where((c) => c.hasUnscheduled).toList(),
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
  ) async {
    final result = await _get(
      '$_config/levels/$levelId/subjects?academic_year_id=$yearId',
      (raw) =>
          _list(raw['subjects'] ?? _map(raw['data'])['subjects'] ?? raw['data'])
              .whereType<Map>()
              .map((v) => LevelSubjectPeriod.fromJson(_map(v)))
              .toList(),
      'Unable to load timetable configuration. Please try again.',
    );
    // Temporary diagnostic to confirm the client renders exactly the
    // backend's union of subjects for the level — never token/header data.
    if (kDebugMode && result is GeneratorSuccess<List<LevelSubjectPeriod>>) {
      debugPrint(
        '[LevelSubjects] levelId=$levelId yearId=$yearId '
        'count=${result.data.length}',
      );
      debugPrint(
        '[LevelSubjects] subjects=${result.data.map((s) => '${s.subjectId}:${s.subjectName}').toList()}',
      );
    }
    return result;
  }

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

  Future<GeneratorResult<TimetableGenerationResult>> generateTimetable({
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
    TimetableGenerationResult.fromJson,
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
        return GeneratorError(_error(raw, fallback), response.statusCode, raw);
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
        return GeneratorError(_error(raw, fallback), response.statusCode, raw);
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
        return GeneratorError(_error(raw, fallback), response.statusCode, raw);
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
int? _optInt(dynamic value) => value == null
    ? null
    : (value is num ? value.toInt() : int.tryParse(value.toString()));
String _text(dynamic value) => value?.toString().trim() ?? '';

List<String> _toMessages(List<dynamic> values) => values
    .map((value) {
      if (value is Map) {
        final map = _map(value);
        final prefix = [
          map['class_name'],
          map['subject_name'],
        ].where((v) => _text(v).isNotEmpty).map(_text).join(' / ');
        // Prefer the exact backend reason code's fixed message over any raw
        // free-text message, so blocking issues never render a generic or
        // stale phrase when a precise reason is known.
        final code = _text(
          map['reason_code'] ?? map['reasonCode'] ?? map['code'],
        );
        final message =
            reasonCodeMessage(code) ??
            _text(map['message'] ?? map['error'] ?? map['reason']);
        return prefix.isEmpty ? message : '$prefix: $message';
      }
      return _text(value);
    })
    .where((value) => value.isNotEmpty)
    .toList();

List<String> _messages(Map<String, dynamic> raw) {
  final values =
      raw['errors'] ??
      raw['issues'] ??
      raw['warnings'] ??
      raw['validation_errors'];
  if (values is List) return _toMessages(values);
  return const [];
}

String _error(Map<String, dynamic> raw, String fallback) {
  final message = _text(
    raw['message'] ?? raw['error'] ?? _map(raw['data'])['message'],
  );
  final lower = message.toLowerCase();
  final looksRaw =
      lower.contains('sql') ||
      lower.contains('<html') ||
      lower.contains('constraint') ||
      lower.contains('foreign key') ||
      lower.contains('stack trace') ||
      lower.contains('sqlstate') ||
      lower.contains('unknown column') ||
      RegExp(r'er_[a-z_]+').hasMatch(lower);
  if (message.isEmpty || looksRaw) return fallback;
  return message;
}

/// Recognize backend configuration issues without generating teacher days off.
bool timetableNeedsTeacherDaysOff(Map<String, dynamic> raw) {
  bool missing(String value) {
    final text = value.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    return (text.contains('day off') || text.contains('days off')) &&
        (text.contains('missing') ||
            text.contains('not configured') ||
            text.contains('insufficient') ||
            text.contains('not set') ||
            text.contains('required'));
  }

  bool visit(dynamic value) {
    if (value is String) return missing(value);
    if (value is List) return value.any(visit);
    if (value is Map) {
      return value.entries.any(
        (entry) =>
            (missing(entry.key.toString()) && entry.value == true) ||
            (entry.key.toString() == 'teacher_day_offs_configured' &&
                entry.value == false) ||
            visit(entry.value),
      );
    }
    return false;
  }

  return visit(raw);
}
