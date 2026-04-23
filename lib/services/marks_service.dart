import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

// Conditional export for web vs mobile
export '../utils/download_helper_stub.dart'
    if (dart.library.html) '../utils/download_helper_web.dart';

import '../utils/download_helper.dart';

// Import TimeoutException from dart:async
import 'dart:async';

final _client = ApiClient();
const _base = 'api/school-admin/marks';

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

/// Marks entry model (school-admin scope).
/// Now includes nested objects: exam, subject, teacher, class, student.
class MarkModel {
  final int id;
  final int examId;
  final int studentId;
  final int subjectId;
  final int marksObtained;
  final int maxMarks;
  final int? teacherId;
  final String? grade;
  final String? createdAt;
  final String? status;
  final String? releasedAt;
  final String? releasedBy;
  
  // Nested objects for better UI
  final Map<String, dynamic>? exam;
  final Map<String, dynamic>? subject;
  final Map<String, dynamic>? teacher;
  final Map<String, dynamic>? classData;
  final Map<String, dynamic>? student;

  const MarkModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    required this.marksObtained,
    required this.maxMarks,
    this.teacherId,
    this.grade,
    this.createdAt,
    this.status,
    this.releasedAt,
    this.releasedBy,
    this.exam,
    this.subject,
    this.teacher,
    this.classData,
    this.student,
  });

  factory MarkModel.fromJson(Map<String, dynamic> json) {
    // Backend may wrap the mark in a nested 'mark' or 'data' object.
    final Map<String, dynamic> m = json['mark'] is Map<String, dynamic>
        ? json['mark'] as Map<String, dynamic>
        : json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    debugPrint('[MarkModel] Raw JSON keys: ${json.keys.toList()}');
    debugPrint('[MarkModel] Parsed object keys: ${m.keys.toList()}');

    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    /// Parse numeric value from backend (int, double, or string). Only use fallback when value is truly missing.
    int parseMarksNum(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return fallback;
        return int.tryParse(s) ?? double.tryParse(s)?.round() ?? fallback;
      }
      return fallback;
    }

    String? nameFrom(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isNotEmpty ? v : null;
      if (v is Map && v['name'] != null) return v['name'].toString();
      if (v is Map && v['studentName'] != null) return v['studentName'].toString();
      if (v is Map && v['fullName'] != null) return v['fullName'].toString();
      return null;
    }

    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();

    // Support all common backend key variants; do not default to 0 when a value exists under another key.
    final obtainedRaw = m['marks_obtained'] ?? m['marksObtained'] ?? m['obtained'] ?? m['score'] ?? m['obtained_marks'];
    final maxRaw = m['max_marks'] ?? m['maxMarks'] ?? m['max'] ?? m['total_marks'] ?? m['totalMarks'] ?? m['out_of'];
    
    // Extract nested objects with debug logging
    final student = m['student'] ?? m['Student'];
    final exam = m['exam'] ?? m['Exam'];
    final subject = m['subject'] ?? m['Subject'];
    final classObj = m['class'] ?? m['Class'];
    final teacher = m['teacher'] ?? m['Teacher'];
    
    debugPrint('[MarkModel] Raw exam object: $exam');
    debugPrint('[MarkModel] Raw teacher object: $teacher');

    return MarkModel(
      id: parseId(m['id'] ?? m['mark_id']),
      examId: parseId(m['exam_id'] ?? m['examId']),
      studentId: parseId(m['student_id'] ?? m['studentId']),
      subjectId: parseId(m['subject_id'] ?? m['subjectId']),
      marksObtained: parseMarksNum(obtainedRaw, 0),
      maxMarks: parseMarksNum(maxRaw, 100),
      teacherId: m['teacher_id'] != null || m['teacherId'] != null ? parseId(m['teacher_id'] ?? m['teacherId']) : null,
      grade: m['grade'] != null ? m['grade'].toString() : null,
      createdAt: m['created_at'] != null ? m['created_at'].toString() : null,
      status: strOpt(m['status']),
      releasedAt: strOpt(m['released_at'] ?? m['releasedAt']),
      releasedBy: strOpt(m['released_by'] ?? m['releasedBy']),
      
      // Nested objects
      exam: exam is Map<String, dynamic> ? exam : null,
      subject: subject is Map<String, dynamic> ? subject : null,
      teacher: teacher is Map<String, dynamic> ? teacher : null,
      classData: classObj is Map<String, dynamic> ? classObj : null,
      student: student is Map<String, dynamic> ? student : null,
    );
  }

  // Backward compatibility getters
  String? get studentName {
    final name = student?['studentName'] ?? student?['name'];
    debugPrint('[MarkModel] studentName: $name (student object: $student)');
    return name;
  }
  
  String? get examName {
    final name = exam?['name'] ?? exam?['examName'];
    debugPrint('[MarkModel] examName: $name (exam object: $exam)');
    return name;
  }
  
  String? get subjectName {
    final name = subject?['subjectName'] ?? subject?['name'];
    debugPrint('[MarkModel] subjectName: $name (subject object: $subject)');
    return name;
  }
  
  String? get teacherName {
    final name = teacher?['teacherName'] ?? teacher?['fullName'] ?? teacher?['name'];
    debugPrint('[MarkModel] teacherName: $name (teacher object: $teacher)');
    return name;
  }
  
  String? get className {
    final name = classData?['className'] ?? classData?['name'];
    debugPrint('[MarkModel] className: $name (class object: $classData)');
    return name;
  }
}

sealed class MarkResult<T> {}

class MarkSuccess<T> extends MarkResult<T> {
  final T data;
  MarkSuccess(this.data);
}

class MarkError extends MarkResult<Never> {
  final String message;
  final int? statusCode;
  MarkError(this.message, [this.statusCode]);
}

class MarksService {
  MarksService._();
  static final MarksService _instance = MarksService._();
  factory MarksService() => _instance;

  /// GET /api/school-admin/marks?exam_id=&student_id=&class_id=&subject_id=
  Future<MarkResult<List<MarkModel>>> listMarks({int? examId, int? studentId, int? classId, int? subjectId}) async {
    try {
      final response = await _client.get(_listUrl(examId: examId, studentId: studentId, classId: classId, subjectId: subjectId));
      devLogResponse('MarksService.listMarks', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not load marks. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is List) list = data;
        else if (raw['marks'] is List) list = raw['marks'] as List<dynamic>;
        else if (raw['items'] is List) list = raw['items'] as List<dynamic>;
        else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) { found = value; break; }
          }
          if (found == null) return MarkError(_errorMessage(response) ?? 'Invalid response.');
          list = found;
        }
      } else {
        return MarkError('Invalid response from server.');
      }
      final marks = <MarkModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            marks.add(MarkModel.fromJson(e));
          } catch (_) {}
        }
      }
      return MarkSuccess(marks);
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.listMarks'));
    }
  }

  Uri _listUrl({int? examId, int? studentId, int? classId, int? subjectId}) {
    final params = <String, String>{};// Add the following line of code after this line
    if (examId != null && examId > 0) params['exam_id'] = examId.toString();
    if (studentId != null && studentId > 0) params['student_id'] = studentId.toString();
    if (classId != null && classId > 0) params['class_id'] = classId.toString();
    if (subjectId != null && subjectId > 0) params['subject_id'] = subjectId.toString();
    final uri = apiUrl(_base);
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  /// GET /api/school-admin/marks/{id}
  Future<MarkResult<MarkModel>> getMark(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('MarksService.getMark', response.statusCode, response.body);
      if (response.statusCode == 404) return MarkError('Marks entry not found.', 404);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not load marks entry.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['mark'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return MarkError('Invalid response from server.');
      }
      return MarkSuccess(MarkModel.fromJson(map));
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.getMark'));
    }
  }

  /// POST /api/school-admin/marks. Do not send grade — backend calculates it.
  Future<MarkResult<MarkModel>> createMark(Map<String, dynamic> payload) async {
    try {
      int toInt(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
      final body = <String, dynamic>{
        'exam_id': toInt(payload['exam_id']),
        'student_id': toInt(payload['student_id']),
        'subject_id': toInt(payload['subject_id']),
        'marks_obtained': toInt(payload['marks_obtained']),
        'max_marks': toInt(payload['max_marks']),
      };
      final tid = toInt(payload['teacher_id']);
      if (tid > 0) body['teacher_id'] = tid;
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('MarksService.createMark', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return MarkError('Invalid response from server.');
        final m = raw as Map<String, dynamic>;
        final map = m['mark'] ?? m['data'] ?? m;
        if (map is! Map<String, dynamic>) return MarkError('Invalid response from server.');
        return MarkSuccess(MarkModel.fromJson(map));
      }
      if (response.statusCode == 400) return MarkError(_errorMessage(response) ?? 'Invalid data.', 400);
      return MarkError(_errorMessage(response) ?? 'Request failed.', response.statusCode);
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.createMark'));
    }
  }

  /// PATCH /api/school-admin/marks/{id}
  Future<MarkResult<MarkModel>> updateMark(int id, Map<String, dynamic> payload) async {
    try {
      final body = <String, dynamic>{};
      if (payload.containsKey('marks_obtained')) body['marks_obtained'] = payload['marks_obtained'] is int ? payload['marks_obtained'] as int : int.tryParse(payload['marks_obtained'].toString()) ?? 0;
      if (payload.containsKey('max_marks')) body['max_marks'] = payload['max_marks'] is int ? payload['max_marks'] as int : int.tryParse(payload['max_marks'].toString()) ?? 100;
      if (payload.containsKey('teacher_id')) body['teacher_id'] = payload['teacher_id'] is int ? payload['teacher_id'] as int : int.tryParse(payload['teacher_id'].toString()) ?? 0;
      if (body.isEmpty) return MarkError('No fields to update.');
      
      debugPrint('[Admin Marks PATCH] URL: ${apiUrl('$_base/$id')}');
      debugPrint('[Admin Marks PATCH] Body: ${jsonEncode(body)}');
      
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      
      debugPrint('[Admin Marks PATCH] Response Status: ${response.statusCode}');
      debugPrint('[Admin Marks PATCH] Response Body: ${response.body}');
      
      if (response.statusCode == 404) return MarkError('Marks entry not found.', 404);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not update.', response.statusCode);
      }
      
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['mark'] is Map<String, dynamic> ? raw['mark'] as Map<String, dynamic> : raw;
      } else {
        return MarkError('Invalid response from server.');
      }
      
      debugPrint('[Admin Marks PATCH] Parsed exam name: ${map['exam']?['name']}');
      
      return MarkSuccess(MarkModel.fromJson(map));
    } catch (e, st) {
      debugPrint('[Admin Marks PATCH] Exception: $e');
      debugPrint('[Admin Marks PATCH] Stack Trace: $st');
      return MarkError(userFriendlyMessage(e, st, 'MarksService.updateMark'));
    }
  }

  /// DELETE /api/school-admin/marks/{id}
  Future<MarkResult<bool>> deleteMark(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('MarksService.deleteMark', response.statusCode, response.body);
      if (response.statusCode == 404) return MarkError('Marks entry not found.', 404);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not delete.', response.statusCode);
      }
      return MarkSuccess(true);
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.deleteMark'));
    }
  }

  /// PATCH /api/school-admin/marks/bulk-teacher
  /// Body: { class_id, subject_id, teacher_id, exam_id }
  Future<MarkResult<bool>> bulkUpdateTeacher({
    required int classId,
    required int subjectId,
    required int teacherId,
    required int examId,
  }) async {
    try {
      final body = {
        'class_id': classId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'exam_id': examId,
      };
      final response = await _client.patch(apiUrl('$_base/bulk-teacher'), body: body);
      devLogResponse('MarksService.bulkUpdateTeacher', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return MarkError(_errorMessage(response) ?? 'Could not update teacher.', response.statusCode);
      }
      return MarkSuccess(true);
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.bulkUpdateTeacher'));
    }
  }

  /// POST /api/admin/marks/release
  Future<MarkResult<Map<String, dynamic>>> releaseMarks({
    required int classId,
    required int examId,
    required int subjectId,
  }) async {
    try {
      final body = {
        'class_id': classId,
        'exam_id': examId,
        'subject_id': subjectId,
      };
      // Use $_base/release which resolves to api/school-admin/marks/release
      final response = await _client.post(apiUrl('$_base/release'), body: body);
      devLogResponse('MarksService.releaseMarks', response.statusCode, response.body);
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        return MarkError(_errorMessage(response) ?? 'Could not release marks.', response.statusCode);
      }
      
      final raw = _parseJson(response.body);
      if (raw is Map<String, dynamic>) {
        return MarkSuccess(raw);
      }
      return MarkSuccess({'message': 'Marks released successfully'});
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.releaseMarks'));
    }
  }

  /// POST /api/school-admin/marks/release/class
  Future<MarkResult<Map<String, dynamic>>> releaseClassMarks({
    required int classId,
    required int examId,
  }) async {
    try {
      final body = {
        'class_id': classId,
        'exam_id': examId,
      };
      final response = await _client.post(apiUrl('$_base/release/class'), body: body);
      devLogResponse('MarksService.releaseClassMarks', response.statusCode, response.body);
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        return MarkError(_errorMessage(response) ?? 'Could not release class marks.', response.statusCode);
      }
      
      final raw = _parseJson(response.body);
      if (raw is Map<String, dynamic>) {
        return MarkSuccess(raw);
      }
      return MarkSuccess({'message': 'Class marks released successfully'});
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.releaseClassMarks'));
    }
  }

  /// POST /api/school-admin/marks/release/classes
  Future<MarkResult<Map<String, dynamic>>> releaseClassesMarks({
    required List<int> classIds,
    required int examId,
  }) async {
    try {
      final body = {
        'class_ids': classIds,
        'exam_id': examId,
      };
      final response = await _client.post(apiUrl('$_base/release/classes'), body: body);
      devLogResponse('MarksService.releaseClassesMarks', response.statusCode, response.body);
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        return MarkError(_errorMessage(response) ?? 'Could not release classes marks.', response.statusCode);
      }
      
      final raw = _parseJson(response.body);
      if (raw is Map<String, dynamic>) {
        return MarkSuccess(raw);
      }
      return MarkSuccess({'message': 'Classes marks released successfully'});
    } catch (e, st) {
      return MarkError(userFriendlyMessage(e, st, 'MarksService.releaseClassesMarks'));
    }
  }

  /// GET /api/school-admin/marks/export?class_id={id}&exam_id={id}
  /// Returns Excel file for download
  Future<MarkResult<String>> exportMarks({
    required int classId,
    required int examId,
  }) async {
    try {
      final uri = apiUrl('$_base/export').replace(queryParameters: {
        'class_id': classId.toString(),
        'exam_id': examId.toString(),
      });
      
      print('DEBUG: Export URL: $uri');
      print('DEBUG: Selected class_id: $classId, exam_id: $examId');
      
      final response = await _client.get(uri);
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body length: ${response.bodyBytes.length} bytes');
      print('DEBUG: Content-Type: ${response.headers['content-type']}');
      print('DEBUG: Content-Disposition: ${response.headers['content-disposition']}');
      
      if (response.statusCode != 200) {
        print('DEBUG: Export failed with status ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');
        return MarkError(_errorMessage(response) ?? 'Could not export marks.', response.statusCode);
      }

      // Validate that we received binary data
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        print('DEBUG: Empty response bytes received');
        return MarkError('Export failed: Empty file received from server.');
      }

      print('DEBUG: Received ${bytes.length} bytes of data');

      // Extract filename from Content-Disposition header
      String? filename;
      final contentDisposition = response.headers['content-disposition'];
      if (contentDisposition != null && contentDisposition.isNotEmpty) {
        // Parse Content-Disposition header: "attachment; filename=\"6A_Term_1_Final_Results.xlsx\""
        final regex = RegExp(r'filename="?([^"]+)"?');
        final match = regex.firstMatch(contentDisposition);
        if (match != null) {
          filename = match.group(1);
          print('DEBUG: Extracted filename from header: $filename');
        } else {
          print('DEBUG: Could not parse filename from Content-Disposition: $contentDisposition');
        }
      }
      
      // Fallback to generated filename if header parsing fails
      if (filename == null || filename.isEmpty) {
        filename = 'class_${classId}_exam_${examId}_results.xlsx';
      }

      // Handle download differently for web vs mobile
      if (kIsWeb) {
        // Web download using extracted filename
        print('DEBUG: Web download triggered for filename: $filename');
        downloadFile(bytes, filename);
        return MarkSuccess('Web download initiated: $filename');
      } else {
        // Mobile download using FilePicker with extracted filename
        print('DEBUG: Opening file picker for save dialog');
        
        final result = await FilePicker.platform.saveFile(
          fileName: filename,
          bytes: Uint8List.fromList(bytes),
          type: FileType.custom,
        );

        if (result != null && result.isNotEmpty) {
          final savedPath = result;
          print('DEBUG: User selected save path: $savedPath');
          
          // Verify file was saved
          final file = File(savedPath!);
          if (await file.exists()) {
            final fileSize = await file.length();
            print('DEBUG: File saved successfully, size: $fileSize bytes');
            
            if (fileSize > 0) {
              print('DEBUG: Export completed successfully');
              return MarkSuccess(savedPath!);
            } else {
              print('DEBUG: Error - saved file is empty');
              return MarkError('Could not save the Excel file. Please try again.');
            }
          } else {
            print('DEBUG: Error - file does not exist after save');
            return MarkError('Could not save the Excel file. Please try again.');
          }
        } else {
          print('DEBUG: User cancelled file picker');
          // User cancelled - return success but no file path
          return MarkError('USER_CANCELLED');
        }
      }

    } catch (e, st) {
      print('DEBUG: Exception in exportMarks: $e');
      print('DEBUG: Stack trace: $st');
      return MarkError('Could not save the Excel file. Please try again.');
    }
  }
}
