import 'dart:convert';

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

int _mergeId(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
Map<String, dynamic>? _mergeMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;
List<dynamic> _mergeList(dynamic value) => value is List ? value : const [];

/// One destination group in a merge/move request: the students moving into
/// [targetClassId] out of the shared source class.
class ClassMergeMove {
  final int targetClassId;
  final List<int> studentIds;

  ClassMergeMove({required this.targetClassId, required List<int> studentIds})
    : studentIds = List<int>.unmodifiable(studentIds);

  Map<String, dynamic> toJson() => {
    'target_class_id': targetClassId,
    'student_ids': studentIds,
  };
}

/// Immutable snapshot sent to both preview and process.
class ClassMergeRequest {
  final int academicYearId;
  final int sourceClassId;
  final List<ClassMergeMove> moves;

  ClassMergeRequest({
    required this.academicYearId,
    required this.sourceClassId,
    required List<ClassMergeMove> moves,
  }) : moves = List<ClassMergeMove>.unmodifiable(moves);

  int get selectedCount =>
      moves.fold(0, (sum, move) => sum + move.studentIds.length);

  Map<String, dynamic> toJson() => {
    'academic_year_id': academicYearId,
    'source_class_id': sourceClassId,
    'moves': moves.map((m) => m.toJson()).toList(),
  };
}

/// A single student entry inside a preview's valid/invalid lists.
class ClassMergeStudentIssue {
  final int studentId;
  final String name;
  final String emis;
  final String? reason;

  const ClassMergeStudentIssue({
    required this.studentId,
    required this.name,
    required this.emis,
    this.reason,
  });

  factory ClassMergeStudentIssue.fromJson(Map<String, dynamic> json) {
    final student = _mergeMap(json['student']) ?? json;
    return ClassMergeStudentIssue(
      studentId: _mergeId(
        student['id'] ?? student['student_id'] ?? json['student_id'],
      ),
      name:
          (student['name'] ??
                  student['student_name'] ??
                  student['full_name'] ??
                  '')
              .toString()
              .trim(),
      emis:
          (student['emis_number'] ??
                  student['emisNumber'] ??
                  student['emis'] ??
                  '—')
              .toString(),
      reason: (json['reason'] ?? json['message'])?.toString(),
    );
  }
}

/// Per-destination-class rollup inside a preview response.
class ClassMergeTargetSummary {
  final int targetClassId;
  final String? targetClassName;
  final int count;

  const ClassMergeTargetSummary({
    required this.targetClassId,
    this.targetClassName,
    required this.count,
  });

  factory ClassMergeTargetSummary.fromJson(Map<String, dynamic> json) {
    final target = _mergeMap(json['target_class']) ?? _mergeMap(json['class']);
    return ClassMergeTargetSummary(
      targetClassId: _mergeId(
        json['target_class_id'] ?? json['class_id'] ?? target?['id'],
      ),
      targetClassName: (json['target_class_name'] ?? target?['name'])
          ?.toString(),
      count: _mergeId(json['count'] ?? json['student_count'] ?? json['total']),
    );
  }
}

/// Parsed defensively: unknown backend field shapes still surface via [raw]
/// so the UI can render exactly what the backend sent.
class ClassMergePreview {
  final bool canProcess;
  final int selectedCount;
  final List<ClassMergeStudentIssue> validStudents;
  final List<ClassMergeStudentIssue> invalidStudents;
  final List<ClassMergeTargetSummary> targetSummary;
  final String? message;
  final int? processedCount;
  final int? remainingSourceCount;
  final Map<String, dynamic> raw;

  const ClassMergePreview({
    required this.canProcess,
    required this.selectedCount,
    required this.validStudents,
    required this.invalidStudents,
    required this.targetSummary,
    this.message,
    this.processedCount,
    this.remainingSourceCount,
    this.raw = const {},
  });

  factory ClassMergePreview.fromJson(Map<String, dynamic> json) {
    final data = _mergeMap(json['data']) ?? json;

    List<ClassMergeStudentIssue> issues(dynamic value) => _mergeList(value)
        .whereType<Map>()
        .map(
          (e) => ClassMergeStudentIssue.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    List<ClassMergeTargetSummary> targets(dynamic value) => _mergeList(value)
        .whereType<Map>()
        .map(
          (e) => ClassMergeTargetSummary.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    return ClassMergePreview(
      canProcess: data['can_process'] == true,
      selectedCount: _mergeId(data['selected_count'] ?? data['selectedCount']),
      validStudents: issues(data['valid_students'] ?? data['validStudents']),
      invalidStudents: issues(
        data['invalid_students'] ?? data['invalidStudents'],
      ),
      targetSummary: targets(data['target_summary'] ?? data['targetSummary']),
      message: (data['message'] ?? json['message'])?.toString(),
      processedCount: data['processed_count'] == null
          ? null
          : _mergeId(data['processed_count']),
      remainingSourceCount: data['remaining_source_count'] == null
          ? null
          : _mergeId(data['remaining_source_count']),
      raw: data,
    );
  }
}

class ClassMergeHistoryEntry {
  final String studentName;
  final String emis;
  final String fromClassName;
  final String toClassName;
  final String academicYearName;
  final String movedBy;
  final String date;
  final String reason;

  const ClassMergeHistoryEntry({
    required this.studentName,
    required this.emis,
    required this.fromClassName,
    required this.toClassName,
    required this.academicYearName,
    required this.movedBy,
    required this.date,
    required this.reason,
  });

  factory ClassMergeHistoryEntry.fromJson(Map<String, dynamic> json) {
    final student = _mergeMap(json['student']) ?? json;
    return ClassMergeHistoryEntry(
      studentName: (student['name'] ?? student['student_name'] ?? '—')
          .toString(),
      emis: (student['emis_number'] ?? student['emis'] ?? '—').toString(),
      fromClassName:
          (json['from_class_name'] ??
                  _mergeMap(json['from_class'])?['name'] ??
                  '—')
              .toString(),
      toClassName:
          (json['to_class_name'] ?? _mergeMap(json['to_class'])?['name'] ?? '—')
              .toString(),
      academicYearName:
          (json['academic_year_name'] ??
                  _mergeMap(json['academic_year'])?['name'] ??
                  '—')
              .toString(),
      movedBy:
          (json['moved_by'] ?? _mergeMap(json['moved_by_user'])?['name'] ?? '—')
              .toString(),
      date: (json['moved_at'] ?? json['created_at'] ?? '—').toString(),
      reason: (json['reason'] ?? '—').toString(),
    );
  }
}

sealed class ClassMergeResult<T> {}

class ClassMergeSuccess<T> extends ClassMergeResult<T> {
  final T data;
  ClassMergeSuccess(this.data);
}

class ClassMergeError extends ClassMergeResult<Never> {
  final String message;
  final int? statusCode;
  final ClassMergePreview? validation;
  ClassMergeError(this.message, [this.statusCode, this.validation]);
}

class ClassMergeService {
  final ApiClient _client;
  ClassMergeService({ApiClient? client}) : _client = client ?? ApiClient();
  static const _base = 'api/school-admin/classes/merge';

  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _message(dynamic raw, String fallback) =>
      (_mergeMap(raw)?['message'] ?? _mergeMap(raw)?['error'] ?? fallback)
          .toString();

  Future<ClassMergeResult<ClassMergePreview>> preview(
    ClassMergeRequest request,
  ) => _submit('preview', request);

  Future<ClassMergeResult<ClassMergePreview>> process(
    ClassMergeRequest request,
  ) => _submit('process', request);

  Future<ClassMergeResult<ClassMergePreview>> _submit(
    String action,
    ClassMergeRequest request,
  ) async {
    try {
      final response = await _client.post(
        apiUrl('$_base/$action'),
        body: request.toJson(),
      );
      devLogResponse(
        'ClassMergeService.$action',
        response.statusCode,
        response.body,
      );
      final raw = _decode(response.body);
      final map = _mergeMap(raw);
      final preview = map == null ? null : ClassMergePreview.fromJson(map);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ClassMergeError(
          _message(raw, 'Could not $action the move.'),
          response.statusCode,
          preview,
        );
      }
      if (preview == null) {
        return ClassMergeError(
          'Invalid response from server. Please try again.',
        );
      }
      return ClassMergeSuccess(preview);
    } catch (e, st) {
      return ClassMergeError(
        userFriendlyMessage(e, st, 'ClassMergeService.$action'),
      );
    }
  }

  Future<ClassMergeResult<List<ClassMergeHistoryEntry>>> history({
    int? academicYearId,
    int? classId,
  }) async {
    try {
      final query = <String, String>{
        if (academicYearId != null) 'academic_year_id': '$academicYearId',
        if (classId != null) 'class_id': '$classId',
      };
      final uri = apiUrl(
        '$_base/history',
      ).replace(queryParameters: query.isEmpty ? null : query);
      final response = await _client.get(uri);
      devLogResponse(
        'ClassMergeService.history',
        response.statusCode,
        response.body,
      );
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return ClassMergeError(
          _message(raw, 'Could not load merge history.'),
          response.statusCode,
        );
      }
      List<dynamic> items;
      if (raw is List) {
        items = raw;
      } else {
        final root = _mergeMap(raw);
        final data = root?['data'];
        if (data is List) {
          items = data;
        } else {
          items = _mergeList(
            root?['history'] ?? root?['items'] ?? _mergeMap(data)?['history'],
          );
        }
      }
      return ClassMergeSuccess(
        items
            .whereType<Map>()
            .map(
              (e) =>
                  ClassMergeHistoryEntry.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
    } catch (e, st) {
      return ClassMergeError(
        userFriendlyMessage(e, st, 'ClassMergeService.history'),
      );
    }
  }
}
