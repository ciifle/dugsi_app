import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/delete_error_message.dart';

enum DeleteItemKind { schoolClass, level, academicYear }

enum LevelDeleteChoice { keepClasses, deleteClasses }

/// Lenient truthy parsing for backend flags that may arrive as a strict JSON
/// bool, or (depending on the exact serializer path) as 0/1 or "true"/"false".
bool _truthy(dynamic value) =>
    value == true || value == 1 || value.toString().toLowerCase() == 'true';

int? _optInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

class DependencyDeletePreview {
  final Map<String, int> impact;
  final Map<String, int> retainedImpact;
  final int? containedClasses;
  final bool isActive;
  final bool canDelete;

  /// Whether the admin must pick Keep Classes / Delete Classes Too before
  /// this level can be deleted. Read directly from the backend's
  /// `requires_class_action` flag when present; only inferred from the
  /// contained-class count when the backend omits that flag. A level with
  /// zero classes never requires this choice.
  final bool requiresClassAction;
  final Set<LevelDeleteChoice> levelChoices;
  final int? entityId;
  final String? name;
  const DependencyDeletePreview({
    required this.impact,
    this.retainedImpact = const {},
    this.containedClasses,
    this.isActive = false,
    this.canDelete = true,
    this.requiresClassAction = false,
    this.levelChoices = const {},
    this.entityId,
    this.name,
  });

  factory DependencyDeletePreview.fromJson(
    Map<String, dynamic> raw,
    DeleteItemKind kind,
    int expectedId,
  ) {
    final entityKey = switch (kind) {
      DeleteItemKind.schoolClass => 'class',
      DeleteItemKind.level => 'level',
      DeleteItemKind.academicYear => 'academic_year',
    };
    final entity = raw[entityKey];
    final counts = raw['impact'];
    if (entity is! Map || entity['id'] != expectedId || counts is! Map) {
      throw const FormatException('Invalid deletion preview');
    }
    final impact = <String, int>{};
    final retained = <String, int>{};
    const masterTables = {
      'students',
      'teachers',
      'classes',
      'subjects',
      'school_levels',
      'teacher_teaching_subjects',
      'class_subjects',
    };
    for (final entry in counts.entries) {
      if (entry.key is! String || entry.value is! int || entry.value < 0) {
        throw const FormatException('Invalid impact count');
      }
      final target =
          kind == DeleteItemKind.academicYear &&
              masterTables.contains(entry.key)
          ? retained
          : impact;
      final label = deletionImpactLabel(entry.key as String);
      target[target.containsKey(label) ? '$label (${entry.key})' : label] =
          entry.value as int;
    }
    final active = entity['is_active'];
    if (kind == DeleteItemKind.academicYear &&
        active != true &&
        active != false &&
        active != 0 &&
        active != 1) {
      throw const FormatException('Missing academic year active state');
    }
    final classCount = kind == DeleteItemKind.level
        ? _optInt(counts['classes'])
        : null;
    final requiresClassActionRaw = raw['requires_class_action'];
    final requiresClassAction = kind == DeleteItemKind.level
        ? (requiresClassActionRaw != null
              ? _truthy(requiresClassActionRaw)
              : (classCount ?? 0) > 0)
        : false;
    final canDeleteRaw = raw['can_delete'];
    final reportedCanDelete = canDeleteRaw == null
        ? true
        : _truthy(canDeleteRaw);
    // `requires_confirmation` is the NORMAL, expected state for any
    // deletable entity in this force-based safe-delete flow — the
    // confirmation dialog itself IS that confirmation, so it must never be
    // read as a block. An explicit `can_delete:false` only means "cannot
    // auto-delete without confirmation", not "cannot be deleted at all",
    // as long as a confirmation path (`requires_confirmation`) is offered.
    // A level with zero classes is additionally always deletable regardless
    // of unrelated leftover config (e.g. level_subject_period_requirements),
    // which the backend cleans up on its own.
    final requiresConfirmationRaw = raw['requires_confirmation'];
    final requiresConfirmation = requiresConfirmationRaw == null
        ? true
        : _truthy(requiresConfirmationRaw);
    final canDelete = kind == DeleteItemKind.level
        ? (reportedCanDelete || requiresConfirmation || (classCount ?? 0) == 0)
        : reportedCanDelete;
    return DependencyDeletePreview(
      entityId: expectedId,
      name: entity['name']?.toString(),
      impact: impact,
      retainedImpact: retained,
      canDelete: canDelete,
      isActive: active == true || active == 1,
      containedClasses: classCount,
      requiresClassAction: requiresClassAction,
      // These exact modes are defined in adminDeletion.controller/service and Swagger.
      levelChoices: kind == DeleteItemKind.level
          ? {LevelDeleteChoice.keepClasses, LevelDeleteChoice.deleteClasses}
          : {},
    );
  }
}

String deletionImpactLabel(String key) {
  const labels = {
    'student_enrollments': 'Student Enrollments',
    'class_subjects': 'Class Subjects',
    'teacher_class_subjects': 'Teacher Assignments',
    'teacher_assignments': 'Teacher Assignments',
    'timetables': 'Timetable Entries',
    'student_movements_from': 'Student Movement Records (From Class)',
    'student_movements_to': 'Student Movement Records (To Class)',
    'teacher_day_offs': 'Teacher Days Off',
    'school_working_days': 'Working Days',
    'level_subject_periods': 'Level Subject Period Requirements',
    'school_levels': 'Levels',
  };
  return labels[key] ??
      key
          .split('_')
          .map(
            (word) => word.isEmpty
                ? ''
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' ');
}

class AdminDeleteException implements Exception {
  final String message;
  final DependencyDeletePreview? preview;
  const AdminDeleteException(this.message, {this.preview});
}

/// Contract verified against backend adminDeletion.controller.js and Swagger.
/// Opt-in development logging excludes headers/tokens: --dart-define=DEBUG_ADMIN_DELETE=true.
class AdminDeletionService {
  final ApiClient _client = ApiClient();
  static const _debug = bool.fromEnvironment('DEBUG_ADMIN_DELETE');
  String _path(DeleteItemKind kind, int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    final collection = switch (kind) {
      DeleteItemKind.schoolClass => 'classes',
      DeleteItemKind.level => 'levels',
      DeleteItemKind.academicYear => 'academic-years',
    };
    return 'api/school-admin/$collection/$id';
  }

  Future<DependencyDeletePreview> preview(DeleteItemKind kind, int id) async {
    final url = apiUrl('${_path(kind, id)}/delete-preview');
    try {
      final response = await _client.get(url);
      _log('GET', url, response.statusCode, response.body);
      final raw = _decode(response.body);
      if (kind == DeleteItemKind.level) _logLevelPreviewRaw(id, raw);
      if (response.statusCode != 200) {
        throw AdminDeleteException(_message(raw, kind, response.statusCode));
      }
      final parsed = DependencyDeletePreview.fromJson(raw, kind, id);
      if (kind == DeleteItemKind.level) _logLevelPreviewParsed(parsed);
      return parsed;
    } on AdminDeleteException {
      rethrow;
    } catch (_) {
      throw const AdminDeleteException(
        'Unable to load deletion impact. Please try again.',
      );
    }
  }

  /// Diagnostic-only: the exact backend response behind the enable/disable
  /// decision, logged BEFORE parsing so a stuck-disabled Delete button can
  /// be root-caused from the real response even if parsing itself fails.
  /// Never logs headers/tokens.
  void _logLevelPreviewRaw(int id, Map<String, dynamic> raw) {
    if (!kDebugMode) return;
    debugPrint(
      '[LevelDeletePreview] levelId=$id full_response=$raw '
      'can_delete=${raw['can_delete']} '
      'requires_confirmation=${raw['requires_confirmation']} '
      'requires_class_action=${raw['requires_class_action']} '
      'impact=${raw['impact']}',
    );
  }

  void _logLevelPreviewParsed(DependencyDeletePreview parsed) {
    if (!kDebugMode) return;
    debugPrint(
      '[LevelDeletePreview] id=${parsed.entityId} name=${parsed.name} '
      'class_count=${parsed.containedClasses} '
      'canDelete(effective)=${parsed.canDelete} '
      'requiresClassAction(effective)=${parsed.requiresClassAction}',
    );
  }

  Future<Map<String, dynamic>> confirmedDelete(
    DeleteItemKind kind,
    DependencyDeletePreview preview, {
    required bool confirmed,
    bool confirmActive = false,
    LevelDeleteChoice? classChoice,
  }) async {
    if (!confirmed ||
        !preview.canDelete ||
        preview.entityId == null ||
        (kind == DeleteItemKind.academicYear &&
            preview.isActive &&
            !confirmActive) ||
        (kind == DeleteItemKind.level &&
            preview.requiresClassAction &&
            classChoice == null)) {
      throw const AdminDeleteException(
        'Please review the impact and explicitly confirm deletion.',
      );
    }
    final url = apiUrl(_path(kind, preview.entityId!)).replace(
      queryParameters: {
        'force': 'true',
        if (kind == DeleteItemKind.academicYear && preview.isActive)
          'confirm_active': 'true',
        if (kind == DeleteItemKind.level)
          'class_action': classChoice == LevelDeleteChoice.deleteClasses
              ? 'delete'
              : 'detach',
      },
    );
    try {
      final response = await _client.delete(url);
      _log('DELETE', url, response.statusCode, response.body);
      final raw = _decode(response.body);
      // Swagger defines 200 as unconditionally "Deletion completed" for this
      // endpoint; do not require a specific success-body field.
      if (response.statusCode == 200) return raw;
      DependencyDeletePreview? updated;
      if (raw['impact'] is Map) {
        try {
          updated = DependencyDeletePreview.fromJson(
            raw,
            kind,
            preview.entityId!,
          );
        } on FormatException {
          /* Fail closed on invalid conflict data. */
        }
      }
      throw AdminDeleteException(
        updated == null
            ? _message(raw, kind, response.statusCode)
            : 'Deletion needs confirmation again. Review the updated impact below.',
        preview: updated,
      );
    } on AdminDeleteException {
      rethrow;
    } catch (_) {
      throw AdminDeleteException(_fallback(kind));
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : {};
    } catch (_) {
      return {};
    }
  }

  String _fallback(DeleteItemKind kind) =>
      'Unable to delete this ${switch (kind) {
        DeleteItemKind.schoolClass => 'class',
        DeleteItemKind.level => 'level',
        DeleteItemKind.academicYear => 'academic year',
      }}. Please try again.';
  String _message(Map<String, dynamic> raw, DeleteItemKind kind, int status) {
    final safe = safeDeleteError(raw['message']);
    return status >= 500 || safe == deleteFailureMessage
        ? _fallback(kind)
        : safe;
  }

  void _log(String method, Uri url, int status, String body) {
    if (kDebugMode && _debug) {
      debugPrint('[AdminDelete] $method $url body=<none> status=$status');
      debugPrint('[AdminDelete] response=$body');
    }
  }
}
