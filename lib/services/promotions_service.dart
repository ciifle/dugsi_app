import 'dart:convert';

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

int _promotionId(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
Map<String, dynamic>? _promotionMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;
List<dynamic> _promotionList(dynamic value) => value is List ? value : const [];

double? parsePromotionPercentage(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool passesPromotionThreshold(num? percentage) =>
    percentage != null && percentage.toDouble() >= 50.0;

String promotionResultLabel(num? percentage) {
  if (percentage == null) return 'No Result';
  return passesPromotionThreshold(percentage) ? 'Pass' : 'Fail';
}

bool canPromoteByPercentageAndEligibility(
  num? percentage,
  bool? backendEligible, {
  bool? resultAvailable,
}) =>
    resultAvailable != false &&
    passesPromotionThreshold(percentage) &&
    (backendEligible ?? true);

/// Friendly fallback text for a backend `unavailable_reason` code, used only
/// when the backend doesn't also send a ready-to-display
/// `unavailable_message`. New/unknown codes fall back to a generic message
/// rather than exposing the raw machine code to the user.
String friendlyUnavailableMessage(String? reasonCode) {
  switch (reasonCode) {
    case 'NO_RELEASED_MARKS':
      return 'No released marks are available for this academic year.';
    case 'NO_MARKS':
      return 'No marks were recorded for this academic year.';
    case 'MISSING_EXAM_WEIGHT':
      return 'One or more exams are missing a valid weight.';
    case 'NO_ENROLLMENT':
      return 'No enrollment was found for this academic year.';
    case 'ZERO_MAXIMUM':
      return 'The exam maximum marks total to zero, so a result cannot be computed.';
    case 'INCOMPLETE_RESULTS':
      return 'Results for this academic year are incomplete.';
    default:
      return 'A result is not available for this student for this academic year.';
  }
}

/// The best available human-readable explanation for why a student's
/// result is unavailable: prefers the backend's own message, then falls
/// back to a friendly mapping of `unavailable_reason`, then a generic
/// message. Never exposes a raw machine-only code directly to the user.
String promotionUnavailableMessage(PromotionStudent student) {
  final message = student.unavailableMessage?.trim();
  if (message != null && message.isNotEmpty) return message;
  return friendlyUnavailableMessage(student.unavailableReason);
}

/// Display-only formatter — never used for the pass/fail comparison itself
/// (that always uses the raw [passesPromotionThreshold] value). Fixed to two
/// decimal places so a value like 49.99 never visually rounds up to "50.0",
/// which would look inconsistent with a FAIL badge.
String formatPromotionPercentage(num? percentage) =>
    percentage == null ? '—' : '${percentage.toStringAsFixed(2)}%';

bool? parseNullablePromotionBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

List<PromotionStudent> parsePromotionStudentsResponse(dynamic raw) {
  List<dynamic> items = const [];
  if (raw is List) {
    items = raw;
  } else {
    final root = _promotionMap(raw);
    if (root?['data'] is List) {
      items = root!['data'] as List<dynamic>;
    } else {
      final data = _promotionMap(root?['data']);
      items = _promotionList(
        root?['students'] ??
            data?['students'] ??
            root?['items'] ??
            data?['items'],
      );
    }
  }
  return items
      .whereType<Map>()
      .map((item) => PromotionStudent.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

class PromotionStudent {
  final int id;
  final String name;
  final String emis;
  final String? className;
  final double? percentage;
  final double? finalObtained;
  final double? finalMaximum;
  final String? grade;
  final String? status;
  final String? reason;
  final bool? eligible;
  final bool? resultAvailable;
  final String? unavailableReason;
  final String? unavailableMessage;

  const PromotionStudent({
    required this.id,
    required this.name,
    required this.emis,
    this.className,
    this.percentage,
    this.finalObtained,
    this.finalMaximum,
    this.grade,
    this.status,
    this.reason,
    this.eligible,
    this.resultAvailable,
    this.unavailableReason,
    this.unavailableMessage,
  });

  factory PromotionStudent.fromJson(Map<String, dynamic> json) {
    final student = _promotionMap(json['student']) ?? json;
    return PromotionStudent(
      id: _promotionId(student['id'] ?? student['student_id']),
      name:
          (student['name'] ??
                  student['student_name'] ??
                  student['studentName'] ??
                  student['full_name'] ??
                  '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}')
              .toString()
              .trim(),
      emis:
          (student['emis_number'] ??
                  student['emisNumber'] ??
                  student['emis'] ??
                  student['student_number'] ??
                  student['student_id'] ??
                  '—')
              .toString(),
      className:
          (json['class_name'] ??
                  _promotionMap(json['class'])?['name'] ??
                  student['class_name'])
              ?.toString(),
      percentage: parsePromotionPercentage(
        json['final_percentage'] ??
            student['final_percentage'] ??
            json['percentage'] ??
            student['percentage'],
      ),
      finalObtained: parsePromotionPercentage(
        json['final_obtained'] ?? student['final_obtained'],
      ),
      finalMaximum: parsePromotionPercentage(
        json['final_maximum'] ?? student['final_maximum'],
      ),
      grade:
          (json['letter_grade'] ??
                  student['letter_grade'] ??
                  json['grade'] ??
                  student['grade'])
              ?.toString(),
      status:
          (json['final_status'] ??
                  student['final_status'] ??
                  json['result_status'] ??
                  student['result_status'] ??
                  json['status'] ??
                  student['status'])
              ?.toString(),
      reason:
          (json['reason'] ??
                  student['reason'] ??
                  json['message'] ??
                  student['message'])
              ?.toString(),
      eligible: parseNullablePromotionBool(
        json['promotion_eligible'] ??
            student['promotion_eligible'] ??
            json['is_eligible'] ??
            student['is_eligible'] ??
            json['eligible'] ??
            student['eligible'],
      ),
      resultAvailable: parseNullablePromotionBool(
        json['result_available'] ??
            student['result_available'] ??
            json['resultAvailable'] ??
            student['resultAvailable'],
      ),
      unavailableReason:
          (json['unavailable_reason'] ?? student['unavailable_reason'])
              ?.toString(),
      unavailableMessage:
          (json['unavailable_message'] ?? student['unavailable_message'])
              ?.toString(),
    );
  }
}

class PromotionPreview {
  final bool canProcess;
  final Map<String, List<PromotionStudent>> categories;
  final String? message;

  const PromotionPreview({
    required this.canProcess,
    required this.categories,
    this.message,
  });

  factory PromotionPreview.fromJson(Map<String, dynamic> json) {
    final data = _promotionMap(json['data']) ?? json;
    final categories = <String, List<PromotionStudent>>{};
    for (final entry in data.entries) {
      if (entry.value is List) {
        categories[entry.key] = _promotionList(entry.value)
            .whereType<Map>()
            .map((e) => PromotionStudent.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return PromotionPreview(
      canProcess: data['can_process'] == true,
      categories: categories,
      message: (data['message'] ?? json['message'])?.toString(),
    );
  }
}

/// Immutable snapshot used by both preview and process.
class PromotionRequest {
  final int fromAcademicYearId;
  final int? toAcademicYearId;
  final int fromClassId;
  final int? toClassId;
  final String decision;
  final List<int> studentIds;
  final String? notes;

  PromotionRequest({
    required this.fromAcademicYearId,
    this.toAcademicYearId,
    required this.fromClassId,
    this.toClassId,
    required this.decision,
    required List<int> studentIds,
    this.notes,
  }) : studentIds = List<int>.unmodifiable(studentIds);

  Map<String, dynamic> toJson() => {
    'from_academic_year_id': fromAcademicYearId,
    if (toAcademicYearId != null) 'to_academic_year_id': toAcademicYearId,
    'from_class_id': fromClassId,
    if (toClassId != null) 'to_class_id': toClassId,
    'decision': decision,
    'student_ids': studentIds,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

class PromotionHistoryItem {
  final int id;
  final String? batchId;
  final PromotionStudent student;
  final int? fromAcademicYearId;
  final int? toAcademicYearId;
  final int? fromClassId;
  final int? toClassId;
  final String decision;
  final String fromYear;
  final String toYear;
  final String fromClass;
  final String toClass;
  final String date;
  final String notes;

  PromotionHistoryItem.fromJson(Map<String, dynamic> json)
    : id = _promotionId(json['id'] ?? json['promotion_id']),
      batchId = (json['batch_id'] ?? json['promotion_batch_id'])?.toString(),
      student = PromotionStudent.fromJson(
        _promotionMap(json['student']) ?? json,
      ),
      fromAcademicYearId = _promotionNullableId(
        json['from_academic_year_id'] ??
            _promotionMap(json['from_academic_year'])?['id'],
      ),
      toAcademicYearId = _promotionNullableId(
        json['to_academic_year_id'] ??
            _promotionMap(json['to_academic_year'])?['id'],
      ),
      fromClassId = _promotionNullableId(
        json['from_class_id'] ?? _promotionMap(json['from_class'])?['id'],
      ),
      toClassId = _promotionNullableId(
        json['to_class_id'] ?? _promotionMap(json['to_class'])?['id'],
      ),
      decision = (json['decision'] ?? '—').toString(),
      fromYear =
          (json['from_academic_year_name'] ??
                  _promotionMap(json['from_academic_year'])?['name'] ??
                  '—')
              .toString(),
      toYear =
          (json['to_academic_year_name'] ??
                  _promotionMap(json['to_academic_year'])?['name'] ??
                  '—')
              .toString(),
      fromClass =
          (json['from_class_name'] ??
                  _promotionMap(json['from_class'])?['name'] ??
                  '—')
              .toString(),
      toClass =
          (json['to_class_name'] ??
                  _promotionMap(json['to_class'])?['name'] ??
                  '—')
              .toString(),
      date = (json['processed_at'] ?? json['created_at'] ?? '—').toString(),
      notes = (json['notes'] ?? '—').toString();
}

int? _promotionNullableId(dynamic value) {
  final parsed = _promotionId(value);
  return parsed > 0 ? parsed : null;
}

sealed class PromotionResult<T> {}

class PromotionSuccess<T> extends PromotionResult<T> {
  final T data;
  PromotionSuccess(this.data);
}

class PromotionError extends PromotionResult<Never> {
  final String message;
  final int? statusCode;
  final PromotionPreview? validation;
  PromotionError(this.message, [this.statusCode, this.validation]);
}

class PromotionsService {
  final ApiClient _client;
  PromotionsService({ApiClient? client}) : _client = client ?? ApiClient();
  static const _base = 'api/school-admin/promotions';

  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _message(dynamic raw, String fallback) =>
      (_promotionMap(raw)?['message'] ??
              _promotionMap(raw)?['error'] ??
              fallback)
          .toString();

  List<dynamic> _items(dynamic raw, String key) {
    if (raw is List) return raw;
    final root = _promotionMap(raw);
    if (root?['data'] is List) return root!['data'] as List<dynamic>;
    final data = _promotionMap(root?['data']);
    return _promotionList(
      root?[key] ?? root?['items'] ?? data?[key] ?? data?['items'],
    );
  }

  static Map<String, String> studentQueryParameters({
    required int fromAcademicYearId,
    required int classId,
  }) => {
    'from_academic_year_id': '$fromAcademicYearId',
    'class_id': '$classId',
  };

  Future<PromotionResult<List<PromotionStudent>>> students({
    required int fromAcademicYearId,
    required int classId,
  }) async {
    try {
      final uri = apiUrl('$_base/students').replace(
        queryParameters: studentQueryParameters(
          fromAcademicYearId: fromAcademicYearId,
          classId: classId,
        ),
      );
      final response = await _client.get(uri);
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return PromotionError(
          _message(raw, 'Could not load eligible students.'),
          response.statusCode,
        );
      }
      return PromotionSuccess(parsePromotionStudentsResponse(raw));
    } catch (e, st) {
      return PromotionError(
        userFriendlyMessage(e, st, 'PromotionsService.students'),
      );
    }
  }

  Future<PromotionResult<PromotionPreview>> preview(PromotionRequest request) =>
      _previewRequest('preview', request.toJson());

  Future<PromotionResult<PromotionPreview>> process(PromotionRequest request) =>
      _previewRequest('process', request.toJson());

  Future<PromotionResult<PromotionPreview>> _previewRequest(
    String action,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(apiUrl('$_base/$action'), body: body);
      final raw = _decode(response.body);
      final map = _promotionMap(raw);
      final validation = map == null ? null : PromotionPreview.fromJson(map);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return PromotionError(
          _message(raw, 'Could not $action promotion.'),
          response.statusCode,
          validation,
        );
      }
      return PromotionSuccess(
        validation ?? const PromotionPreview(canProcess: true, categories: {}),
      );
    } catch (e, st) {
      return PromotionError(
        userFriendlyMessage(e, st, 'PromotionsService.$action'),
      );
    }
  }

  Future<PromotionResult<List<PromotionHistoryItem>>> history({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final uri = apiUrl(
        '$_base/history',
      ).replace(queryParameters: {'page': '$page', 'limit': '$limit'});
      final response = await _client.get(uri);
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return PromotionError(
          _message(raw, 'Could not load promotion history.'),
          response.statusCode,
        );
      }
      return PromotionSuccess(
        _items(raw, 'promotions')
            .whereType<Map>()
            .map(
              (e) =>
                  PromotionHistoryItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
    } catch (e, st) {
      return PromotionError(
        userFriendlyMessage(e, st, 'PromotionsService.history'),
      );
    }
  }

  Future<PromotionResult<List<PromotionHistoryItem>>> studentHistory(
    int id,
  ) async {
    try {
      final response = await _client.get(apiUrl('$_base/student/$id'));
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return PromotionError(
          _message(raw, 'Could not load student academic history.'),
          response.statusCode,
        );
      }
      return PromotionSuccess(
        _items(raw, 'promotions')
            .whereType<Map>()
            .map(
              (e) =>
                  PromotionHistoryItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
    } catch (e, st) {
      return PromotionError(
        userFriendlyMessage(e, st, 'PromotionsService.studentHistory'),
      );
    }
  }
}
