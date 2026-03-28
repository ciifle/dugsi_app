import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Class-Subject model (curriculum source of truth).
/// Represents (class_id, subject_id, school_id) relationship.
/// Note: Backend may not have an 'id' column for class_subjects table.
class ClassSubjectModel {
  final int? id; // Nullable because backend may not provide this
  final int classId;
  final int subjectId;
  final int schoolId;

  const ClassSubjectModel({
    this.id,
    required this.classId,
    required this.subjectId,
    required this.schoolId,
  });

  factory ClassSubjectModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    
    return ClassSubjectModel(
      id: json.containsKey('id') ? parseId(json['id']) : null, // Only set if present
      classId: parseId(json['class_id'] ?? json['classId']),
      subjectId: parseId(json['subject_id'] ?? json['subjectId']),
      schoolId: parseId(json['school_id'] ?? json['schoolId']),
    );
  }
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
              classSubjects.add(ClassSubjectModel.fromJson(e));
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

  /// POST /api/school-admin/classes/{class_id}/subjects  Body: { "subject_ids": [1,2,3] }
  Future<ClassSubjectResult<ClassSubjectModel>> createClassSubject(Map<String, dynamic> data) async {
    try {
      int toInt(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
      
      // Extract class_id from data or use default
      final classId = toInt(data['class_id'] ?? data['classId']);
      if (classId <= 0) {
        return ClassSubjectError('Class ID is required for subject assignment');
      }
      
      final body = <String, dynamic>{
        'subject_ids': data['subject_ids'] ?? data['subjectIds'] ?? [],
      };
      
      final response = await _client.post(apiUrl('$_base/$classId/subjects'), body: body);
      devLogResponse('ClassSubjectsService.createClassSubject', response.statusCode, response.body);
      
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return ClassSubjectError('Invalid response from server. Please try again.');
        final m = raw as Map<String, dynamic>;
        final classSubjectMap = m['class_subject'] ?? m['data'] ?? m;
        if (classSubjectMap is! Map<String, dynamic>) return ClassSubjectError('Invalid response from server. Please try again.');
        return ClassSubjectSuccess(ClassSubjectModel.fromJson(classSubjectMap));
      }
      if (response.statusCode == 400) return ClassSubjectError(_errorMessage(response) ?? 'Invalid data. Please try again.', 400);
      return ClassSubjectError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return ClassSubjectError(userFriendlyMessage(e, st, 'ClassSubjectsService.createClassSubject'));
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
