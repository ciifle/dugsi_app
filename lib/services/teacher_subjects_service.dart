import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/subjects_service.dart';

class TeacherSubjectsConfig {
  final int teacherId;
  final List<SubjectModel> subjects;

  const TeacherSubjectsConfig({
    required this.teacherId,
    required this.subjects,
  });

  int get subjectCount => subjects.length;
  bool get requiresSubjectSelection => subjectCount > 1;
  SubjectModel? get inferredSubject =>
      subjectCount == 1 ? subjects.first : null;
}

sealed class TeacherSubjectsResult<T> {}

class TeacherSubjectsSuccess<T> extends TeacherSubjectsResult<T> {
  final T data;
  TeacherSubjectsSuccess(this.data);
}

class TeacherSubjectsError extends TeacherSubjectsResult<Never> {
  final String message;
  final int? statusCode;
  TeacherSubjectsError(this.message, [this.statusCode]);
}

class TeacherSubjectsService {
  TeacherSubjectsService._();
  static final TeacherSubjectsService _instance = TeacherSubjectsService._();
  factory TeacherSubjectsService() => _instance;

  final ApiClient _client = ApiClient();
  static const _base = 'api/school-admin/teachers';

  /// GET /api/school-admin/teachers/{teacherId}/subjects
  Future<TeacherSubjectsResult<TeacherSubjectsConfig>> getSubjects(
    int teacherId,
  ) async {
    try {
      final response = await _client.get(apiUrl('$_base/$teacherId/subjects'));
      devLogResponse(
        'TeacherSubjectsService.getSubjects',
        response.statusCode,
        response.body,
      );
      if (response.statusCode != 200) {
        return TeacherSubjectsError(
          _cleanError(response, fallback: 'Could not load teaching subjects.'),
          response.statusCode,
        );
      }
      final raw = _decode(response.body);
      final list = _subjectList(raw);
      final subjects = <SubjectModel>[];
      final seen = <int>{};
      for (final value in list) {
        if (value is! Map) continue;
        final row = Map<String, dynamic>.from(value);
        final nested = row['subject'] ?? row['Subject'];
        final map = nested is Map ? Map<String, dynamic>.from(nested) : row;
        final subject = SubjectModel.fromJson(map);
        if (subject.id > 0 && seen.add(subject.id)) subjects.add(subject);
      }
      return TeacherSubjectsSuccess(
        TeacherSubjectsConfig(teacherId: teacherId, subjects: subjects),
      );
    } catch (error, stack) {
      return TeacherSubjectsError(
        userFriendlyMessage(error, stack, 'TeacherSubjectsService.getSubjects'),
      );
    }
  }

  /// PUT /api/school-admin/teachers/{teacherId}/subjects
  /// Replaces the teacher's global teaching-subject configuration.
  Future<TeacherSubjectsResult<TeacherSubjectsConfig>> replaceSubjects(
    int teacherId,
    Iterable<int> subjectIds,
  ) async {
    try {
      final ids = subjectIds.toSet().toList()..sort();
      final response = await _client.put(
        apiUrl('$_base/$teacherId/subjects'),
        body: {'subject_ids': ids},
      );
      devLogResponse(
        'TeacherSubjectsService.replaceSubjects',
        response.statusCode,
        response.body,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        return TeacherSubjectsError(
          _cleanError(
            response,
            fallback: 'Could not update teaching subjects.',
          ),
          response.statusCode,
        );
      }
      return getSubjects(teacherId);
    } catch (error, stack) {
      return TeacherSubjectsError(
        userFriendlyMessage(
          error,
          stack,
          'TeacherSubjectsService.replaceSubjects',
        ),
      );
    }
  }
}

dynamic _decode(String body) {
  try {
    return body.isEmpty ? null : jsonDecode(body);
  } catch (_) {
    return null;
  }
}

List<dynamic> _subjectList(dynamic raw) {
  if (raw is List) return raw;
  if (raw is! Map) return const [];
  final data = raw['data'];
  if (data is List) return data;
  if (data is Map && data['subjects'] is List) return data['subjects'] as List;
  if (raw['subjects'] is List) return raw['subjects'] as List;
  if (raw['teacher_subjects'] is List) return raw['teacher_subjects'] as List;
  return const [];
}

String _cleanError(http.Response response, {required String fallback}) {
  final raw = _decode(response.body);
  final server = raw is Map ? raw['message'] ?? raw['error'] : null;
  final text = server?.toString().toLowerCase() ?? '';
  if (response.statusCode == 409 ||
      text.contains('active') ||
      text.contains('assignment') ||
      text.contains('in use')) {
    return 'This teaching subject is still used in active course assignments. Update those assignments first.';
  }
  if (response.statusCode == 404) return 'Teacher or subject was not found.';
  if (response.statusCode == 400 || response.statusCode == 422) {
    return 'The teaching-subject selection is invalid. Please review it and try again.';
  }
  return fallback;
}
