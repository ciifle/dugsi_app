import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Class-Subject model (curriculum source of truth).
/// Represents (class_id, subject_id, school_id, is_exam_subject) relationship.
/// Note: Backend may not have an 'id' column for class_subjects table.
class ClassSubjectModel {
  final int? id; // Nullable because backend may not provide this
  final int classId;
  final int subjectId;
  final int schoolId;

  /// Subject display name, when the class-subjects endpoint includes it
  /// (flat `name`/`subject_name` or a nested `subject` object) — this list
  /// is the only source for the normal Class Subjects page, so it must not
  /// depend on a separate full-catalog fetch to show a readable name.
  final String subjectName;

  /// Whether this class subject participates in exams/grading. `true`
  /// (exam subject) is the backend default when the field is absent, so a
  /// legacy row without the field is treated as an exam subject rather than
  /// silently excluded.
  final bool isExamSubject;

  const ClassSubjectModel({
    this.id,
    required this.classId,
    required this.subjectId,
    required this.schoolId,
    this.subjectName = '',
    this.isExamSubject = true,
  });

  /// [contextClassId] is the class ID the row was fetched under (i.e. the
  /// `{classId}` in `GET classes/{classId}/subjects`). Nested-list endpoints
  /// commonly omit the parent id from each row since it's already implied
  /// by the URL — without this fallback, a row missing `class_id` would
  /// silently parse to `classId: 0`, and a PATCH built from that would hit
  /// `classes/0/subjects/{id}` and 404 as "Class subject not found."
  factory ClassSubjectModel.fromJson(
    Map<String, dynamic> json, {
    int? contextClassId,
  }) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool parseExamFlag(dynamic v) {
      if (v == null) return true;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return true;
    }

    final nestedSubject = json['subject'] ?? json['Subject'];
    String name = (json['name'] ?? json['subject_name'] ?? json['subjectName'] ?? '')
        .toString()
        .trim();
    if (name.isEmpty && nestedSubject is Map) {
      name = (nestedSubject['name'] ?? '').toString().trim();
    }

    final parsedClassId = parseId(json['class_id'] ?? json['classId']);
    final resolvedClassId = parsedClassId > 0
        ? parsedClassId
        : (contextClassId ?? 0);

    // Confirmed live against GET classes/{classId}/subjects: rows come back
    // flat as `{id, name, is_exam_subject}` with NO `subject_id` key at all
    // — `id` here IS the subject's id (verified against production DB:
    // Farshaxan subject_id=56 <-> row `{id: 56, name: "Farshaxan", ...}`).
    // Without this fallback, subjectId silently parsed to 0 and every PATCH
    // hit `classes/{classId}/subjects/0`, which the backend correctly
    // 404'd as "Subject not assigned to this class".
    final subjectId = parseId(
      json['subject_id'] ??
          json['subjectId'] ??
          (nestedSubject is Map ? nestedSubject['id'] : null) ??
          json['id'],
    );

    return ClassSubjectModel(
      id: json.containsKey('id') ? parseId(json['id']) : null, // Only set if present
      classId: resolvedClassId,
      subjectId: subjectId,
      schoolId: parseId(json['school_id'] ?? json['schoolId']),
      subjectName: name,
      isExamSubject: parseExamFlag(
        json['is_exam_subject'] ?? json['isExamSubject'],
      ),
    );
  }

  ClassSubjectModel copyWith({bool? isExamSubject}) => ClassSubjectModel(
    id: id,
    classId: classId,
    subjectId: subjectId,
    schoolId: schoolId,
    subjectName: subjectName,
    isExamSubject: isExamSubject ?? this.isExamSubject,
  );
}

/// Result of [ClassSubjectsService.addSubjectsToClass]: the freshly reloaded
/// class-subject list plus the names of any subjects whose Non-Exam status
/// could not be saved (a clean partial-failure signal — the subjects
/// themselves were still assigned).
class AddSubjectsOutcome {
  final List<ClassSubjectModel> classSubjects;
  final List<String> failedSubjectNames;
  const AddSubjectsOutcome({
    required this.classSubjects,
    required this.failedSubjectNames,
  });
}

sealed class ClassSubjectResult<T> {}

class ClassSubjectSuccess<T> extends ClassSubjectResult<T> {
  final T data;
  ClassSubjectSuccess(this.data);
}

class ClassSubjectError extends ClassSubjectResult<Never> {
  final String message;
  final int? statusCode;
  ClassSubjectError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/classes';

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

class ClassSubjectsService {
  ClassSubjectsService._();
  static final ClassSubjectsService _instance = ClassSubjectsService._();
  factory ClassSubjectsService() => _instance;

  /// GET /api/school-admin/classes/{class_id}/subjects
  Future<ClassSubjectResult<List<ClassSubjectModel>>> listClassSubjects({
    int? classId,
    int? subjectId,
  }) async {
    try {
      if (classId != null && classId > 0) {
        final response = await _client.get(apiUrl('$_base/$classId/subjects'));
        devLogResponse('ClassSubjectsService.listClassSubjects', response.statusCode, response.body);
        
        if (response.statusCode != 200) {
          return ClassSubjectError(_errorMessage(response) ?? 'Could not load class subjects. Please try again.', response.statusCode);
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
            list = data['class_subjects'] as List<dynamic>? ?? 
                     data['items'] as List<dynamic>? ?? 
                     data['data'] as List<dynamic>? ?? [];
          } else if (raw['class_subjects'] is List) {
            list = raw['class_subjects'] as List<dynamic>;
          } else if (raw['items'] is List) {
            list = raw['items'] as List<dynamic>;
          } else {
            List<dynamic>? found;
            for (final value in raw.values) {
              if (value is List) { found = value; break; }
            }
            if (found == null) return ClassSubjectError('Invalid response from server. Please try again.');
            list = found;
          }
        } else {
          return ClassSubjectError('Invalid response from server. Please try again.');
        }
        
        final classSubjects = <ClassSubjectModel>[];
        for (final e in list) {
          if (e is Map<String, dynamic>) {
            try {
              final cs = ClassSubjectModel.fromJson(e, contextClassId: classId);
              classSubjects.add(cs);
              print(
                'CLASS SUBJECT ROW\n'
                '  classId: ${cs.classId}\n'
                '  subjectId: ${cs.subjectId}\n'
                '  subjectName: ${cs.subjectName}\n'
                '  isExamSubject: ${cs.isExamSubject}\n'
                '  raw json: $e',
              );
            } catch (_) {}
          }
        }
        return ClassSubjectSuccess(classSubjects);
      }

      // Fallback to old endpoint if no classId provided
      final params = <String, String>{};
      if (subjectId != null && subjectId > 0) params['subject_id'] = subjectId.toString();
      
      final uri = params.isEmpty ? apiUrl('api/school-admin/class-subjects') : apiUrl('api/school-admin/class-subjects').replace(queryParameters: params);
      final response = await _client.get(uri);
      devLogResponse('ClassSubjectsService.listClassSubjects', response.statusCode, response.body);
      
      if (response.statusCode != 200) {
        return ClassSubjectError(_errorMessage(response) ?? 'Could not load class subjects. Please try again.', response.statusCode);
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
          list = data['class_subjects'] as List<dynamic>? ?? 
                   data['items'] as List<dynamic>? ?? 
                   data['data'] as List<dynamic>? ?? [];
        } else if (raw['class_subjects'] is List) {
          list = raw['class_subjects'] as List<dynamic>;
        } else if (raw['items'] is List) {
          list = raw['items'] as List<dynamic>;
        } else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) { found = value; break; }
          }
          if (found == null) return ClassSubjectError('Invalid response from server. Please try again.');
          list = found;
        }
      } else {
        return ClassSubjectError('Invalid response from server. Please try again.');
      }
      
      final classSubjects = <ClassSubjectModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            classSubjects.add(ClassSubjectModel.fromJson(e));
          } catch (_) {}
        }
      }
      return ClassSubjectSuccess(classSubjects);
    } catch (e, st) {
      return ClassSubjectError(userFriendlyMessage(e, st, 'ClassSubjectsService.listClassSubjects'));
    }
  }

  /// POST /api/school-admin/classes/{class_id}/subjects
  /// Body: { "subject_ids": [1, 2, 3] }
  ///
  /// The backend's bulk-assign endpoint only accepts a flat `subject_ids`
  /// array of subject IDs — it validates with "subject_ids array is
  /// required" and does not accept a per-item `is_exam_subject` on this
  /// call. Newly assigned subjects come back as exam subjects by default;
  /// callers that need a subject marked Non-Exam must follow up with
  /// [updateExamSubjectStatus] for that row after this call succeeds (see
  /// the Add Subjects dialog for the two-step orchestration).
  Future<ClassSubjectResult<List<ClassSubjectModel>>> assignClassSubjects({
    required int classId,
    required List<int> subjectIds,
  }) async {
    try {
      if (classId <= 0) {
        return ClassSubjectError('Class ID is required for subject assignment');
      }
      final body = <String, dynamic>{'subject_ids': subjectIds};

      final response = await _client.post(apiUrl('$_base/$classId/subjects'), body: body);
      devLogResponse('ClassSubjectsService.assignClassSubjects', response.statusCode, response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = _parseJson(response.body);
        List<dynamic> list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map<String, dynamic>) {
          final data = raw['data'];
          list = (data is List ? data : null) ??
              (raw['class_subjects'] as List<dynamic>?) ??
              (raw['subjects'] as List<dynamic>?) ??
              const [];
        } else {
          list = const [];
        }
        final result = <ClassSubjectModel>[];
        for (final e in list) {
          if (e is Map<String, dynamic>) {
            try {
              result.add(ClassSubjectModel.fromJson(e));
            } catch (_) {}
          }
        }
        return ClassSubjectSuccess(result);
      }
      if (response.statusCode == 400) {
        // Never surface raw validation internals (e.g. "subject_ids array is
        // required") — those are for debug logs only.
        return ClassSubjectError(
          'Could not assign the selected subjects. Please try again.',
          400,
        );
      }
      return ClassSubjectError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return ClassSubjectError(userFriendlyMessage(e, st, 'ClassSubjectsService.assignClassSubjects'));
    }
  }

  /// Adds [selections] (newly chosen, currently-unassigned subjects) to
  /// [classId] using the backend's real two-step contract: bulk-assign the
  /// plain subject IDs first, then PATCH the exam status (by class_id +
  /// subject_id) for any subject the admin marked Non-Exam — newly assigned
  /// subjects default to Exam, so Exam-selected rows need no follow-up call.
  /// Always reloads the class's subject list from the server afterward
  /// rather than trusting local state. A failed exam-status PATCH does not
  /// undo the assignment — it is reported back as
  /// [AddSubjectsOutcome.failedSubjectNames] so the caller can show a clean
  /// partial-failure message.
  Future<ClassSubjectResult<AddSubjectsOutcome>> addSubjectsToClass({
    required int classId,
    required List<({int subjectId, String subjectName, bool isExamSubject})>
    selections,
  }) async {
    if (selections.isEmpty) {
      return ClassSubjectError('Select at least one subject to add.');
    }

    final assignResult = await assignClassSubjects(
      classId: classId,
      subjectIds: selections.map((s) => s.subjectId).toList(),
    );
    if (assignResult is ClassSubjectError) return assignResult;

    final nonExamSelections = selections.where((s) => !s.isExamSubject).toList();
    final failedNames = <String>[];
    for (final s in nonExamSelections) {
      final patchResult = await updateExamSubjectStatus(
        classId: classId,
        subjectId: s.subjectId,
        isExamSubject: false,
      );
      if (patchResult is ClassSubjectError) failedNames.add(s.subjectName);
    }

    final afterAssign = await listClassSubjects(classId: classId);
    if (afterAssign is ClassSubjectError) return afterAssign;
    final current = (afterAssign as ClassSubjectSuccess<List<ClassSubjectModel>>).data;

    return ClassSubjectSuccess(
      AddSubjectsOutcome(classSubjects: current, failedSubjectNames: failedNames),
    );
  }

  /// PATCH /api/school-admin/classes/{classId}/subjects/{subjectId}
  /// Body: { "is_exam_subject": true|false }
  /// Updates the exam-subject flag for one existing class-subject
  /// relationship in place, addressed by its actual class_id + subject_id —
  /// the relationship itself is never deleted/recreated, and this never
  /// touches the same subject in any other class.
  Future<ClassSubjectResult<ClassSubjectModel>> updateExamSubjectStatus({
    required int classId,
    required int subjectId,
    required bool isExamSubject,
  }) async {
    try {
      final url = apiUrl('$_base/$classId/subjects/$subjectId');
      final body = {'is_exam_subject': isExamSubject};
      print(
        'PATCH CLASS SUBJECT TYPE\n'
        '  URL: $url\n'
        '  BODY: $body\n'
        '  classId: $classId\n'
        '  subjectId: $subjectId',
      );
      final response = await _client.patch(url, body: body);
      devLogResponse('ClassSubjectsService.updateExamSubjectStatus', response.statusCode, response.body);

      if (response.statusCode == 404) {
        return ClassSubjectError('Class subject not found.', 404);
      }
      if (response.statusCode != 200) {
        return ClassSubjectError(_errorMessage(response) ?? 'Could not update subject type. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic>? map;
      if (raw is Map<String, dynamic>) {
        final nested = raw['class_subject'] ?? raw['data'] ?? raw;
        if (nested is Map<String, dynamic>) map = nested;
      }
      if (map == null) {
        // Backend returned no usable body — trust the requested value.
        return ClassSubjectSuccess(
          ClassSubjectModel(
            classId: classId,
            subjectId: subjectId,
            schoolId: 0,
            isExamSubject: isExamSubject,
          ),
        );
      }
      return ClassSubjectSuccess(ClassSubjectModel.fromJson(map));
    } catch (e, st) {
      return ClassSubjectError(userFriendlyMessage(e, st, 'ClassSubjectsService.updateExamSubjectStatus'));
    }
  }

  /// DELETE /api/school-admin/classes/{class_id}/subjects/{subject_id}
  Future<ClassSubjectResult<bool>> deleteClassSubject(int classId, int subjectId) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$classId/subjects/$subjectId'));
      devLogResponse('ClassSubjectsService.deleteClassSubject', response.statusCode, response.body);
      
      if (response.statusCode == 404) return ClassSubjectError('Class subject not found.', 404);
      if (response.statusCode != 200) {
        return ClassSubjectError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      
      return ClassSubjectSuccess(true);
    } catch (e, st) {
      return ClassSubjectError(userFriendlyMessage(e, st, 'ClassSubjectsService.deleteClassSubject'));
    }
  }

  /// Legacy delete method for backward compatibility - uses classId and subjectId from model
  Future<ClassSubjectResult<bool>> deleteClassSubjectById(int id) async {
    return ClassSubjectError('deleteClassSubjectById is deprecated. Use deleteClassSubject(classId, subjectId) instead.');
  }
}
