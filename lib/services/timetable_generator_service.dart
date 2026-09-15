import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
  // Null means "not yet configured" — distinct from an admin-entered 0.
  // Never defaulted to 0 by this model; only ever set from an actual
  // saved backend value or explicit admin input.
  int? periodsPerWeek;

  LevelSubjectPeriod({
    required this.subjectId,
    required this.subjectName,
    this.periodsPerWeek,
  });

  factory LevelSubjectPeriod.fromJson(Map<String, dynamic> json) {
    final subject = _map(json['subject'] ?? json['Subject']);
    return LevelSubjectPeriod(
      subjectId: _int(json['subject_id'] ?? json['subjectId'] ?? subject['id']),
      subjectName: _text(
        json['subject_name'] ?? json['subjectName'] ?? subject['name'],
      ),
      periodsPerWeek: _optInt(
        json['periods_per_week'] ??
            json['periodsPerWeek'] ??
            json['weekly_periods'] ??
            json['periods'],
      ),
    );
  }
}

/// A single shift's working-day configuration. The backend stores Morning
/// and Afternoon working days as fully independent records keyed by
/// `shift_id` — this model always carries the `shift_id`/`shift_name` the
/// response was tied to, so callers can defensively verify a response
/// actually belongs to the shift they requested before applying it.
class WorkingDaysConfig {
  final int? academicYearId;
  final int? shiftId;
  final String? shiftName;
  final List<String> days;

  const WorkingDaysConfig({
    this.academicYearId,
    this.shiftId,
    this.shiftName,
    required this.days,
  });

  factory WorkingDaysConfig.fromJson(Map<String, dynamic> raw) {
    final data = _map(raw['data']);
    final shiftName = (raw['shift_name'] ?? data['shift_name'])?.toString();
    return WorkingDaysConfig(
      academicYearId: _optInt(
        raw['academic_year_id'] ?? data['academic_year_id'],
      ),
      shiftId: _optInt(raw['shift_id'] ?? data['shift_id']),
      shiftName: shiftName != null && shiftName.trim().isNotEmpty
          ? shiftName.trim()
          : null,
      days: _list(
        raw['days'] ??
            raw['working_days'] ??
            raw['workingDays'] ??
            data['days'] ??
            data['working_days'],
      ).map((day) => day.toString().toUpperCase()).toList(),
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
  // Whole-school, permissive-policy reason codes (all warnings, never
  // blockers) — additive aliases alongside the codes above.
  'NO_TEACHER_ASSIGNMENT': 'No teacher assigned',
  'NO_CLASS_SLOT': 'No class slot available',
  'CAPACITY_LIMIT': 'Class capacity reached',
  'SOLVER_LIMIT': 'Solver could not place all requested lessons',
};

String? reasonCodeMessage(String? code) {
  if (code == null || code.isEmpty) return null;
  return timetableReasonMessages[code.toUpperCase()];
}

/// Last-resort humanization for a reason code the fixed map above doesn't
/// recognize yet — turns `SOME_NEW_CODE` into "Some new code" rather than
/// ever showing the raw SCREAMING_SNAKE_CASE enum string to an admin.
String humanizeReasonCode(String code) {
  final words = code.toLowerCase().split('_').where((w) => w.isNotEmpty);
  if (words.isEmpty) return code;
  final text = words.join(' ');
  return text[0].toUpperCase() + text.substring(1);
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

/// Per-class readiness status under the complete-timetable-mode contract.
/// `notConfigured` is a class with no saved weekly subject-period
/// requirements yet (class-based generation: every class configures its
/// own periods independently). `unknown` covers any unrecognized/future
/// backend value — treated as not ready, never silently assumed COMPLETE.
enum TimetableClassStatus {
  complete,
  underAllocated,
  overAllocated,
  notConfigured,
  unknown,
}

/// Shared status parsing for every endpoint that reports a per-class
/// status string. The class-configuration summary/subjects endpoints use
/// `READY`; the whole-school preview endpoint uses `COMPLETE` — both mean
/// the same thing and map to [TimetableClassStatus.complete].
TimetableClassStatus? _parseClassStatus(dynamic value) {
  final statusText = _text(value).toUpperCase();
  if (statusText.isEmpty) return null;
  return switch (statusText) {
    'COMPLETE' || 'READY' => TimetableClassStatus.complete,
    'UNDER_ALLOCATED' => TimetableClassStatus.underAllocated,
    'OVER_ALLOCATED' => TimetableClassStatus.overAllocated,
    'NOT_CONFIGURED' => TimetableClassStatus.notConfigured,
    _ => TimetableClassStatus.unknown,
  };
}

/// A single class's readiness diagnostic from the new preview contract:
/// requested_periods/available_slots/difference/status/ready_to_generate,
/// plus which subjects still need a period requirement or a teacher. This
/// is additive alongside [TimetableCapacityIssue] — older backend
/// responses without these fields simply produce an entry with null
/// status/readyToGenerate, so parsing never crashes during a rollout.
class TimetableClassReadiness {
  final int? classId;
  final String className;
  final int? shiftId;
  final int? requestedPeriods;
  final int? availableSlots;
  final int? difference;
  final TimetableClassStatus? status;
  final bool? readyToGenerate;
  // Explicit backend blockers remain authoritative alongside exact capacity.
  final bool? blocking;
  final bool? canGenerateClass;
  final int? expectedUnscheduledPeriods;
  final List<String> missingRequirements;
  final List<String> missingTeacherAssignments;
  // A backend-supplied explanatory message for this class's status, when
  // present — preferred over any locally-composed wording.
  final String? message;
  // Whole-school permissive-policy fields: how many of this class's
  // requested periods the solver actually placed, versus left unscheduled
  // — distinct from `availableSlots` (raw capacity) and from
  // `expectedUnscheduledPeriods` (an older/alternate field name some
  // responses use for the same idea). Under the permissive policy an
  // unscheduled count here is a WARNING, never a blocker.
  final int? scheduled;
  final int? unscheduled;
  final String? reasonCode;
  final List<TimetableSubjectResult> subjectResults;

  const TimetableClassReadiness({
    this.classId,
    required this.className,
    this.shiftId,
    this.requestedPeriods,
    this.availableSlots,
    this.difference,
    this.status,
    this.readyToGenerate,
    this.blocking,
    this.canGenerateClass,
    this.expectedUnscheduledPeriods,
    this.missingRequirements = const [],
    this.missingTeacherAssignments = const [],
    this.message,
    this.scheduled,
    this.unscheduled,
    this.reasonCode,
    this.subjectResults = const [],
  });

  /// The effective "could not be scheduled" count, preferring the explicit
  /// `unscheduled` field and falling back to `expectedUnscheduledPeriods`
  /// (an older/alternate name for the same idea) — never both added
  /// together.
  int? get effectiveUnscheduled => unscheduled ?? expectedUnscheduledPeriods;

  /// Backend reason code mapped to fixed, friendly text; falls back to a
  /// humanized version of the raw code, then to the backend's own message,
  /// so an admin never sees a raw SCREAMING_SNAKE_CASE enum string.
  String? get reasonText {
    final mapped = reasonCodeMessage(reasonCode);
    if (mapped != null) return mapped;
    if (reasonCode != null && reasonCode!.isNotEmpty) {
      return humanizeReasonCode(reasonCode!);
    }
    return message;
  }

  /// True when the backend actually reported this class under the new
  /// contract (status or ready_to_generate present) rather than only the
  /// older capacity-warning shape.
  bool get hasReadinessContract => status != null || readyToGenerate != null;

  /// Strict backend capacity contract: every class must explicitly be complete.
  bool get isReady =>
      status == TimetableClassStatus.complete &&
      readyToGenerate != false &&
      blocking != true &&
      canGenerateClass != false &&
      requestedPeriods != null &&
      availableSlots != null &&
      requestedPeriods! >= 0 &&
      availableSlots! >= 0 &&
      requestedPeriods == availableSlots &&
      (difference == null || difference == 0) &&
      (expectedUnscheduledPeriods == null || expectedUnscheduledPeriods == 0) &&
      missingRequirements.isEmpty &&
      missingTeacherAssignments.isEmpty;

  bool get isBlocking => !isReady;
  bool get isCapacityWarning =>
      status == TimetableClassStatus.underAllocated ||
      status == TimetableClassStatus.overAllocated;

  factory TimetableClassReadiness.fromJson(Map<String, dynamic> json) {
    final classField = json['class'];
    final requested = _optInt(
      json['requested_periods'] ??
          json['requestedPeriods'] ??
          json['required_periods'],
    );
    final available = _optInt(
      json['available_slots'] ??
          json['availableSlots'] ??
          json['available_periods'] ??
          json['availablePeriods'],
    );
    // Backend convention (confirmed by example: requested=26, available=42
    // → difference=16): positive means free/unused slots (under-allocated),
    // negative means a shortfall (over-allocated) — i.e. available minus
    // requested, never the reverse.
    final difference =
        _optInt(json['difference'] ?? json['differencePeriods']) ??
        (requested != null && available != null ? available - requested : null);
    final status = _parseClassStatus(json['status']);
    final readyRaw = json['ready_to_generate'] ?? json['readyToGenerate'];
    final blockingRaw = json['blocking'];
    final classCanGenerateRaw = json['can_generate'] ?? json['canGenerate'];
    return TimetableClassReadiness(
      classId: _optInt(
        json['class_id'] ??
            json['classId'] ??
            (classField is Map ? classField['id'] : null),
      ),
      className: _text(
        json['class_name'] ??
            json['className'] ??
            (classField is Map ? classField['name'] : classField),
      ),
      shiftId: _optInt(json['shift_id'] ?? json['shiftId']),
      requestedPeriods: requested,
      availableSlots: available,
      difference: difference,
      status: status,
      readyToGenerate: readyRaw == null ? null : _asBool(readyRaw),
      blocking: blockingRaw == null ? null : _asBool(blockingRaw),
      canGenerateClass: classCanGenerateRaw == null
          ? null
          : _asBool(classCanGenerateRaw),
      expectedUnscheduledPeriods: _optInt(
        json['expected_unscheduled_periods'] ??
            json['expectedUnscheduledPeriods'],
      ),
      missingRequirements: _extractDiagnosticMessages(
        json['missing_requirements'] ?? json['missingRequirements'],
      ),
      missingTeacherAssignments: _extractDiagnosticMessages(
        json['missing_teacher_assignments'] ??
            json['missingTeacherAssignments'],
      ),
      message: () {
        final text = _text(json['message'] ?? json['status_message']);
        return text.isEmpty ? null : text;
      }(),
      scheduled: _optInt(json['scheduled_periods'] ?? json['scheduledPeriods'] ?? json['scheduled']),
      unscheduled: _optInt(
        json['unscheduled_periods'] ?? json['unscheduledPeriods'] ?? json['unscheduled'],
      ),
      reasonCode: () {
        final text = _text(json['reason_code'] ?? json['reasonCode'] ?? json['code']);
        return text.isEmpty ? null : text;
      }(),
      subjectResults: _list(json['subject_results'] ?? json['subjectResults'])
          .whereType<Map>()
          .map((v) => TimetableSubjectResult.fromJson(_map(v)))
          .toList(),
    );
  }
}

/// Defensively reads a mixed list of plain subject-name strings or
/// `{subject_name/subject, teacher, message}`-shaped objects into clean,
/// backend-worded display strings — never a raw JSON dump.
List<String> _extractDiagnosticMessages(dynamic value) => _list(value)
    .map((entry) {
      if (entry is String) return entry.trim();
      if (entry is Map) {
        final map = _map(entry);
        final message = _text(map['message'] ?? map['error']);
        if (message.isNotEmpty) return message;
        final subjectField = map['subject'];
        final subjectName = _text(
          map['subject_name'] ??
              map['subjectName'] ??
              (subjectField is Map ? subjectField['name'] : subjectField),
        );
        if (subjectName.isNotEmpty) return subjectName;
      }
      final text = entry?.toString().trim() ?? '';
      return text;
    })
    .where((text) => text.isNotEmpty)
    .toList();

class TimetableGeneratorPreview {
  final bool feasible;
  final bool canGenerate;
  final Map<String, dynamic> summary;
  final List<String> issues;
  final List<TimetableCapacityIssue> capacityIssues;
  final List<TimetableClassReadiness> classResults;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> raw;

  TimetableGeneratorPreview({
    required this.feasible,
    required this.canGenerate,
    required this.summary,
    required this.issues,
    required this.capacityIssues,
    this.classResults = const [],
    required this.rows,
    required this.raw,
  });

  /// Whether per-class readiness is present. Legacy responses remain readable
  /// but cannot authorize strict generation.
  bool get hasReadinessContract =>
      classResults.any((c) => c.hasReadinessContract);

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
    // Preserve backend blockers alongside the per-class capacity diagnostics.
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
      remainingIssues.addAll(
        _list(source['issues'] ?? source['validation_errors']),
      );
    }
    final canGenerateField =
        source['can_generate'] ??
        source['canGenerate'] ??
        source['ready_to_generate'] ??
        raw['can_generate'];
    final classResults = classRows
        .whereType<Map>()
        .map((v) => TimetableClassReadiness.fromJson(_map(v)))
        .toList();
    final hasReadinessContract = classResults.any(
      (c) => c.hasReadinessContract,
    );
    return TimetableGeneratorPreview(
      feasible: _asBool(feasibleValue),
      canGenerate:
          hasReadinessContract &&
          classResults.isNotEmpty &&
          classResults.every((c) => c.isReady) &&
          remainingIssues.isEmpty &&
          capacityIssues.isEmpty &&
          (feasibleValue == null || _asBool(feasibleValue)) &&
          (source['ready_to_generate'] == null ||
              _asBool(source['ready_to_generate'])) &&
          (canGenerateField == null || _asBool(canGenerateField)),
      summary: _map(source['summary'] ?? raw['summary']),
      issues: _toMessages(remainingIssues),
      capacityIssues: capacityIssues,
      classResults: classResults,
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

/// One row from the dedicated class-configuration summary list
/// (`GET timetable-config/classes?academic_year_id=`). Every field —
/// including capacity and working-day count — is backend-reported; never
/// computed or assumed locally (a school's shifts can have any working-day
/// count or periods-per-day).
class ClassTimetableSummary {
  final int classId;
  final String className;
  final int? levelId;
  final String? levelName;
  final int? shiftId;
  final String? shiftName;
  final int? workingDayCount;
  final int? periodsPerDay;
  final int? availableSlots;
  final int? configuredPeriods;
  final int? difference;
  final TimetableClassStatus? status;
  // Not part of the documented example response; read defensively so the
  // Configure-Classes card can show a subject count only when the backend
  // actually provides one — never guessed or fetched per-class up front.
  final int? subjectCount;

  const ClassTimetableSummary({
    required this.classId,
    required this.className,
    this.levelId,
    this.levelName,
    this.shiftId,
    this.shiftName,
    this.workingDayCount,
    this.periodsPerDay,
    this.availableSlots,
    this.configuredPeriods,
    this.difference,
    this.status,
    this.subjectCount,
  });

  factory ClassTimetableSummary.fromJson(Map<String, dynamic> json) {
    String? optText(dynamic value) {
      final text = _text(value);
      return text.isEmpty ? null : text;
    }

    return ClassTimetableSummary(
      classId: _int(json['class_id'] ?? json['classId'] ?? json['id']),
      className: _text(
        json['class_name'] ?? json['className'] ?? json['name'],
      ),
      levelId: _optInt(json['level_id'] ?? json['levelId']),
      levelName: optText(json['level_name'] ?? json['levelName']),
      shiftId: _optInt(json['shift_id'] ?? json['shiftId']),
      shiftName: optText(json['shift_name'] ?? json['shiftName']),
      workingDayCount: _optInt(
        json['working_day_count'] ?? json['workingDayCount'],
      ),
      periodsPerDay: _optInt(json['periods_per_day'] ?? json['periodsPerDay']),
      availableSlots: _optInt(
        json['available_slots'] ?? json['availableSlots'],
      ),
      configuredPeriods: _optInt(
        json['configured_periods'] ?? json['configuredPeriods'],
      ),
      difference: _optInt(json['difference']),
      status: _parseClassStatus(json['status']),
      subjectCount: _optInt(
        json['subject_count'] ??
            json['subjectCount'] ??
            json['subjects_count'] ??
            json['total_subjects'],
      ),
    );
  }
}

/// Full response for a single class's subject/period configuration —
/// `GET`/`PUT timetable-config/classes/{classId}/subjects`. Carries the
/// backend's own capacity/configured/status alongside the subject list so
/// the editor header reflects the authoritative saved state, never a
/// locally recomputed guess.
class ClassSubjectConfig {
  final int? classId;
  final String? className;
  final int? shiftId;
  final String? shiftName;
  final int? availableSlots;
  final int? configuredPeriods;
  final int? difference;
  final TimetableClassStatus? status;
  final List<LevelSubjectPeriod> subjects;

  const ClassSubjectConfig({
    this.classId,
    this.className,
    this.shiftId,
    this.shiftName,
    this.availableSlots,
    this.configuredPeriods,
    this.difference,
    this.status,
    required this.subjects,
  });

  factory ClassSubjectConfig.fromJson(Map<String, dynamic> raw) {
    final data = _map(raw['data']);
    final source = data.isNotEmpty ? data : raw;
    String? optText(dynamic value) {
      final text = _text(value);
      return text.isEmpty ? null : text;
    }

    return ClassSubjectConfig(
      classId: _optInt(source['class_id'] ?? source['classId']),
      className: optText(source['class_name'] ?? source['className']),
      shiftId: _optInt(source['shift_id'] ?? source['shiftId']),
      shiftName: optText(source['shift_name'] ?? source['shiftName']),
      availableSlots: _optInt(
        source['available_slots'] ?? source['availableSlots'],
      ),
      configuredPeriods: _optInt(
        source['configured_periods'] ?? source['configuredPeriods'],
      ),
      difference: _optInt(source['difference']),
      status: _parseClassStatus(source['status']),
      subjects: _list(source['subjects'])
          .whereType<Map>()
          .map((v) => LevelSubjectPeriod.fromJson(_map(v)))
          .toList(),
    );
  }
}

/// Whole-school preview — `POST timetable-generator/school/preview`.
///
/// Final permissive backend policy: `can_generate` is the single source of
/// truth for whether Generate may proceed. Under-/over-allocated classes,
/// missing period requirements, missing teacher assignments and
/// unscheduled lessons are all warnings the backend still allows through —
/// they must never independently disable generation. `feasible` and
/// `ready_to_generate` are kept as separate informational flags (useful
/// for explaining *why* the backend blocked generation when it does), but
/// they are never ANDed into the gating decision themselves.
class SchoolTimetablePreview {
  final bool feasible;
  final bool canGenerateFlag;
  final bool readyToGenerateFlag;
  final List<TimetableClassReadiness> classes;
  final List<String> errors;
  // Aggregate lesson counts across the whole school, when the backend
  // reports them at the top level; otherwise summed from the per-class
  // breakdown as a fallback (never independently invented).
  final int? totalRequested;
  final int? totalScheduled;
  final int? totalUnscheduled;
  final Map<String, dynamic> raw;

  const SchoolTimetablePreview({
    required this.feasible,
    required this.canGenerateFlag,
    required this.readyToGenerateFlag,
    required this.classes,
    required this.errors,
    this.totalRequested,
    this.totalScheduled,
    this.totalUnscheduled,
    required this.raw,
  });

  /// The one and only generation gate: the backend's own `can_generate`.
  /// Warnings (capacity, missing requirements/teachers, unscheduled
  /// lessons) never disable this locally.
  bool get canGenerate => canGenerateFlag;

  /// True when at least one class carries a warning worth surfacing on
  /// the Review School screen, even though generation is still allowed.
  bool get hasWarnings =>
      (totalUnscheduled ?? 0) > 0 ||
      classes.any(
        (c) =>
            c.status == TimetableClassStatus.underAllocated ||
            c.status == TimetableClassStatus.overAllocated ||
            c.missingRequirements.isNotEmpty ||
            c.missingTeacherAssignments.isNotEmpty ||
            (c.effectiveUnscheduled ?? 0) > 0,
      );

  factory SchoolTimetablePreview.fromJson(Map<String, dynamic> raw) {
    final data = _map(raw['data']);
    final source = data.isNotEmpty ? data : raw;
    final classes = _list(source['classes'])
        .whereType<Map>()
        .map((v) => TimetableClassReadiness.fromJson(_map(v)))
        .toList();
    int? sumOf(int? Function(TimetableClassReadiness) pick) {
      if (classes.isEmpty) return null;
      var sawAny = false;
      var total = 0;
      for (final c in classes) {
        final value = pick(c);
        if (value == null) continue;
        sawAny = true;
        total += value;
      }
      return sawAny ? total : null;
    }

    final totalRequested =
        _optInt(
          source['requested_periods'] ??
              source['requested_rows'] ??
              source['total_requested'],
        ) ??
        sumOf((c) => c.requestedPeriods);
    final totalScheduled =
        _optInt(
          source['scheduled_periods'] ??
              source['scheduled_rows'] ??
              source['total_scheduled'],
        ) ??
        sumOf((c) => c.scheduled);
    final totalUnscheduled =
        _optInt(
          source['unscheduled_periods'] ??
              source['unscheduled_rows'] ??
              source['total_unscheduled'],
        ) ??
        sumOf((c) => c.effectiveUnscheduled);
    return SchoolTimetablePreview(
      feasible: _asBool(source['feasible']),
      canGenerateFlag: _asBool(
        source['can_generate'] ?? source['canGenerate'],
      ),
      readyToGenerateFlag: _asBool(
        source['ready_to_generate'] ?? source['readyToGenerate'],
      ),
      classes: classes,
      errors: _toMessages(_list(source['errors'])),
      totalRequested: totalRequested,
      totalScheduled: totalScheduled,
      totalUnscheduled: totalUnscheduled,
      raw: raw,
    );
  }
}

/// Result of `POST timetable-generator/school/generate` (success 201).
class SchoolGenerationResult {
  final int? generatedCount;
  final int? generatedRows;
  final int? requestedRows;
  final int? unscheduledRows;
  final Map<String, dynamic> raw;

  const SchoolGenerationResult({
    this.generatedCount,
    this.generatedRows,
    this.requestedRows,
    this.unscheduledRows,
    required this.raw,
  });

  bool get hasUnscheduled => (unscheduledRows ?? 0) > 0;

  factory SchoolGenerationResult.fromJson(Map<String, dynamic> raw) {
    final data = _map(raw['data']);
    final source = data.isNotEmpty ? data : raw;
    return SchoolGenerationResult(
      generatedCount: _optInt(source['generated_count']),
      generatedRows: _optInt(source['generated_rows']),
      requestedRows: _optInt(source['requested_rows']),
      unscheduledRows: _optInt(source['unscheduled_rows']),
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

  /// GET /api/school-admin/timetable-config/working-days
  ///     ?academic_year_id=&shift_id=
  /// Working days are shift-specific: Morning and Afternoon are independent
  /// records, so `shift_id` is required on every request — never omitted,
  /// never guessed from a display label.
  Future<GeneratorResult<WorkingDaysConfig>> getWorkingDays({
    required int academicYearId,
    required int shiftId,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[WorkingDays] GET academicYearId=$academicYearId shiftId=$shiftId',
      );
    }
    return _get(
      '$_config/working-days?academic_year_id=$academicYearId&shift_id=$shiftId',
      WorkingDaysConfig.fromJson,
      'Could not load working days for this shift.',
    );
  }

  /// PUT /api/school-admin/timetable-config/working-days
  /// Body: { academic_year_id, shift_id, days }. Saving one shift's days
  /// never touches the other shift's record — there is no PATCH route.
  Future<GeneratorResult<WorkingDaysConfig>> saveWorkingDays({
    required int academicYearId,
    required int shiftId,
    required Iterable<String> days,
  }) async {
    final normalizedDays = days.map((day) => day.toUpperCase()).toList();
    final body = <String, dynamic>{
      'academic_year_id': academicYearId,
      'shift_id': shiftId,
      'days': normalizedDays,
    };
    if (kDebugMode) {
      debugPrint(
        '[WorkingDays] PUT academicYearId=$academicYearId '
        'shiftId=$shiftId days=$normalizedDays',
      );
    }
    return _put(
      '$_config/working-days',
      body,
      WorkingDaysConfig.fromJson,
      'Could not save working days.',
    );
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

  /// GET /api/school-admin/timetable-config/classes?academic_year_id=
  /// The dedicated class-configuration summary list: every class's own
  /// backend-reported capacity, configured periods and status. This is the
  /// only source for Step 2 (Configure Classes) — nothing here is derived
  /// or recalculated locally.
  ///
  /// TEMPORARY DIAGNOSTIC LOGGING: this method is written out longhand
  /// (rather than delegating to the shared `_get` helper) so every stage —
  /// the exact request URL, the raw HTTP status/body, and separately any
  /// parsing failure — is logged under the `[TIMETABLE]` tag. A failed
  /// request/parse is NEVER turned into an empty success list here: it
  /// always comes back as a `GeneratorError` so the UI can tell "genuinely
  /// zero classes" apart from "the request failed".
  Future<GeneratorResult<List<ClassTimetableSummary>>> getClassSummaries({
    required int academicYearId,
  }) async {
    final path = '$_config/classes?academic_year_id=$academicYearId';
    final url = apiUrl(path);
    if (kDebugMode) {
      debugPrint('[TIMETABLE] Loading class summaries');
      debugPrint('[TIMETABLE] academic_year_id: $academicYearId');
      debugPrint('[TIMETABLE] request URL: $url');
    }

    final http.Response response;
    try {
      response = await _client.get(url);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[TIMETABLE] REQUEST FAILED');
        debugPrint('[TIMETABLE] status: (none — request never returned)');
        debugPrint('[TIMETABLE] response body: (none)');
        debugPrint('[TIMETABLE] exception: $error');
        debugPrint('[TIMETABLE] stack trace: $stack');
      }
      return GeneratorError(userFriendlyMessage(error, stack, path));
    }

    if (kDebugMode) {
      debugPrint('[TIMETABLE] HTTP status: ${response.statusCode}');
      debugPrint('[TIMETABLE] raw response: ${response.body}');
    }

    final raw = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      const fallback = 'Could not load the class configuration summary.';
      final friendly = _error(raw, fallback);
      // Surface the backend's own message in debug builds even when it
      // "looks raw" (e.g. a SQL error) — that is exactly what we need to
      // see to find the real cause. Never shown to production users.
      final backendMessage = _text(
        raw['message'] ?? raw['error'] ?? _map(raw['data'])['message'],
      );
      final displayMessage =
          (kDebugMode &&
              backendMessage.isNotEmpty &&
              backendMessage != friendly)
          ? '$friendly\nServer: $backendMessage'
          : friendly;
      return GeneratorError(displayMessage, response.statusCode, raw);
    }

    try {
      final classes = _list(raw['classes'] ?? _map(raw['data'])['classes'])
          .whereType<Map>()
          .map((v) => ClassTimetableSummary.fromJson(_map(v)))
          .toList();
      if (kDebugMode) {
        debugPrint('[TIMETABLE] parsed ${classes.length} class(es)');
      }
      return GeneratorSuccess(classes);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[TIMETABLE] PARSING FAILED');
        debugPrint('[TIMETABLE] raw response: ${response.body}');
        debugPrint('[TIMETABLE] parsing exception: $error');
        debugPrint('[TIMETABLE] stack trace: $stack');
      }
      return GeneratorError(
        'Could not load the class configuration summary.',
      );
    }
  }

  /// GET /api/school-admin/timetable-config/classes/{classId}/subjects
  /// Class-configured generation: each class's own weekly subject-period
  /// requirements come only from that class's own class_subjects — never
  /// merged with a level union or another class's subjects. A `null`
  /// `periods_per_week` means not-yet-configured and must render as an
  /// empty field, never a default of 0.
  Future<GeneratorResult<ClassSubjectConfig>> getClassSubjects(
    int classId,
    int yearId,
  ) async {
    final result = await _get(
      '$_config/classes/$classId/subjects?academic_year_id=$yearId',
      ClassSubjectConfig.fromJson,
      'Unable to load this class\'s timetable configuration. Please try again.',
    );
    if (kDebugMode && result is GeneratorSuccess<ClassSubjectConfig>) {
      debugPrint(
        '[ClassSubjects] classId=$classId yearId=$yearId '
        'count=${result.data.subjects.length}',
      );
      debugPrint(
        '[ClassSubjects] subjects=${result.data.subjects.map((s) => '${s.subjectId}:${s.subjectName}:${s.periodsPerWeek}').toList()}',
      );
    }
    return result;
  }

  /// PUT /api/school-admin/timetable-config/classes/{classId}/subjects
  Future<GeneratorResult<ClassSubjectConfig>> saveClassSubjects(
    int classId,
    int yearId,
    List<LevelSubjectPeriod> subjects,
  ) => _put(
    '$_config/classes/$classId/subjects',
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
    (raw) {
      final parsed = ClassSubjectConfig.fromJson(raw);
      // Some backends ack a PUT without echoing the full subject list —
      // fall back to what was just saved so the caller always has it.
      return parsed.subjects.isNotEmpty
          ? parsed
          : ClassSubjectConfig(
              classId: parsed.classId ?? classId,
              className: parsed.className,
              shiftId: parsed.shiftId,
              shiftName: parsed.shiftName,
              availableSlots: parsed.availableSlots,
              configuredPeriods: parsed.configuredPeriods,
              difference: parsed.difference,
              status: parsed.status,
              subjects: subjects,
            );
    },
    'Could not save this class\'s weekly subject periods.',
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

  /// POST /api/school-admin/timetable-generator/preview
  /// Omitting `level_id` previews the WHOLE SCHOOL in one run (the primary
  /// generation mode: cross-level teacher conflicts are resolved together).
  /// Passing `levelId` keeps the old single-level preview available for any
  /// other caller that still needs it — never used by the new class-based
  /// wizard.
  Future<GeneratorResult<TimetableGeneratorPreview>> previewTimetable({
    required int academicYearId,
    int? levelId,
  }) => _post(
    '$_generator/preview',
    {
      'academic_year_id': academicYearId,
      if (levelId != null) 'level_id': levelId,
    },
    TimetableGeneratorPreview.fromJson,
    'Could not preview the timetable.',
  );

  /// POST /api/school-admin/timetable-generator/generate
  /// Omitting `level_id` generates the WHOLE SCHOOL in a single solve.
  Future<GeneratorResult<TimetableGenerationResult>> generateTimetable({
    required int academicYearId,
    int? levelId,
    bool replaceExisting = false,
  }) => _post(
    '$_generator/generate',
    {
      'academic_year_id': academicYearId,
      if (levelId != null) 'level_id': levelId,
      'replace_existing': replaceExisting,
    },
    TimetableGenerationResult.fromJson,
    'Could not generate the timetable.',
  );

  /// POST /api/school-admin/timetable-generator/school/preview
  /// The dedicated whole-school preview endpoint used by the primary,
  /// class-configured generator — always previews every class together;
  /// never sends level_id.
  Future<GeneratorResult<SchoolTimetablePreview>> previewSchoolTimetable({
    required int academicYearId,
  }) => _post(
    '$_generator/school/preview',
    {'academic_year_id': academicYearId},
    SchoolTimetablePreview.fromJson,
    'Could not preview the whole-school timetable.',
  );

  /// POST /api/school-admin/timetable-generator/school/generate
  /// The dedicated whole-school generate endpoint. Success is HTTP 201.
  Future<GeneratorResult<SchoolGenerationResult>> generateSchoolTimetable({
    required int academicYearId,
    bool replaceExisting = false,
  }) => _post(
    '$_generator/school/generate',
    {
      'academic_year_id': academicYearId,
      'replace_existing': replaceExisting,
    },
    SchoolGenerationResult.fromJson,
    'Could not generate the whole-school timetable.',
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
