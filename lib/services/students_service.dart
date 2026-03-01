import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Student model matching API response (list/detail).
/// Supports both camelCase (emisNumber, studentName) and snake_case from API.
class StudentModel {
  final int id;
  final int? userId;
  final int? schoolId;
  final int? classId;
  final String emisNumber;
  final String studentName;
  final String? motherName;
  final String? refugeeStatus;
  final String? orphanStatus;
  final String? birthDate;
  final String? sex;
  final String? telephone;
  final String? birthPlace;
  final String? nationality;
  final String? studentState;
  final String? studentDistrict;
  final String? studentVillage;
  final String? disabilityStatus;
  final String? guardianName;
  final String? schoolName;
  final String? className;
  final int? age;
  final String? absenteeismStatus;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? class_;

  const StudentModel({
    required this.id,
    this.userId,
    this.schoolId,
    this.classId,
    required this.emisNumber,
    required this.studentName,
    this.motherName,
    this.refugeeStatus,
    this.orphanStatus,
    this.birthDate,
    this.sex,
    this.telephone,
    this.birthPlace,
    this.nationality,
    this.studentState,
    this.studentDistrict,
    this.studentVillage,
    this.disabilityStatus,
    this.guardianName,
    this.schoolName,
    this.className,
    this.age,
    this.absenteeismStatus,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.class_,
  });

  /// Class display name: Class.name or className
  String get classDisplayName {
    if (class_ != null && class_!['name'] != null) return class_!['name'].toString();
    return className ?? '—';
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    int? intOpt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }
    return StudentModel(
      id: parseId(json['id']),
      userId: json['user_id'] != null ? parseId(json['user_id']) : null,
      schoolId: json['school_id'] != null ? parseId(json['school_id']) : null,
      classId: json['class_id'] != null ? intOpt(json['class_id']) : null,
      emisNumber: str(json['emisNumber'] ?? json['emis_number']),
      studentName: str(json['studentName'] ?? json['student_name']),
      motherName: strOpt(json['motherName'] ?? json['mother_name']),
      refugeeStatus: strOpt(json['refugeeStatus'] ?? json['refugee_status']),
      orphanStatus: strOpt(json['orphanStatus'] ?? json['orphan_status']),
      birthDate: strOpt(json['birthDate'] ?? json['birth_date']),
      sex: strOpt(json['sex']),
      telephone: strOpt(json['telephone']),
      birthPlace: strOpt(json['birthPlace'] ?? json['birth_place']),
      nationality: strOpt(json['nationality']),
      studentState: strOpt(json['studentState'] ?? json['student_state']),
      studentDistrict: strOpt(json['studentDistrict'] ?? json['student_district']),
      studentVillage: strOpt(json['studentVillage'] ?? json['student_village']),
      disabilityStatus: strOpt(json['disabilityStatus'] ?? json['disability_status']),
      guardianName: strOpt(json['guardianName'] ?? json['guardian_name']),
      schoolName: strOpt(json['schoolName'] ?? json['school_name']),
      className: strOpt(json['className'] ?? json['class_name']),
      age: intOpt(json['age']),
      absenteeismStatus: strOpt(json['absenteeismStatus'] ?? json['absenteeism_status']),
      createdAt: strOpt(json['created_at']),
      updatedAt: strOpt(json['updated_at']),
      user: json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null,
      // API may send "Class" (capital C) or "class"
      class_: _parseClassMap(json),
    );
  }

  static Map<String, dynamic>? _parseClassMap(Map<String, dynamic> json) {
    final c = json['Class'] ?? json['class'];
    if (c is Map) return Map<String, dynamic>.from(c);
    return null;
  }
}

/// Payload for creating a student (POST). Exact API keys.
Map<String, dynamic> createStudentPayload({
  required String emisNumber,
  required String studentName,
  required String motherName,
  required String refugeeStatus,
  required String orphanStatus,
  required String birthDate,
  required String sex,
  required String telephone,
  required String birthPlace,
  required String nationality,
  required String studentState,
  required String studentDistrict,
  required String studentVillage,
  required String disabilityStatus,
  required String guardianName,
  required String schoolName,
  required String className,
  required int age,
  required String absenteeismStatus,
  required String password,
}) {
  return {
    'emisNumber': emisNumber,
    'studentName': studentName,
    'motherName': motherName,
    'refugeeStatus': refugeeStatus,
    'orphanStatus': orphanStatus,
    'birthDate': birthDate,
    'sex': sex,
    'telephone': telephone,
    'birthPlace': birthPlace,
    'nationality': nationality,
    'studentState': studentState,
    'studentDistrict': studentDistrict,
    'studentVillage': studentVillage,
    'disabilityStatus': disabilityStatus,
    'guardianName': guardianName,
    'schoolName': schoolName,
    'className': className,
    'age': age,
    'absenteeismStatus': absenteeismStatus,
    'password': password,
  };
}

/// Payload for updating a student (PATCH). Only include non-null fields.
Map<String, dynamic> updateStudentPayload({
  String? emisNumber,
  String? studentName,
  String? motherName,
  String? refugeeStatus,
  String? orphanStatus,
  String? birthDate,
  String? sex,
  String? telephone,
  String? birthPlace,
  String? nationality,
  String? studentState,
  String? studentDistrict,
  String? studentVillage,
  String? disabilityStatus,
  String? guardianName,
  String? schoolName,
  String? className,
  int? age,
  String? absenteeismStatus,
  String? password,
  int? class_id,
}) {
  final map = <String, dynamic>{};
  if (emisNumber != null) map['emisNumber'] = emisNumber;
  if (studentName != null) map['studentName'] = studentName;
  if (motherName != null) map['motherName'] = motherName;
  if (refugeeStatus != null) map['refugeeStatus'] = refugeeStatus;
  if (orphanStatus != null) map['orphanStatus'] = orphanStatus;
  if (birthDate != null) map['birthDate'] = birthDate;
  if (sex != null) map['sex'] = sex;
  if (telephone != null) map['telephone'] = telephone;
  if (birthPlace != null) map['birthPlace'] = birthPlace;
  if (nationality != null) map['nationality'] = nationality;
  if (studentState != null) map['studentState'] = studentState;
  if (studentDistrict != null) map['studentDistrict'] = studentDistrict;
  if (studentVillage != null) map['studentVillage'] = studentVillage;
  if (disabilityStatus != null) map['disabilityStatus'] = disabilityStatus;
  if (guardianName != null) map['guardianName'] = guardianName;
  if (schoolName != null) map['schoolName'] = schoolName;
  if (className != null) map['className'] = className;
  if (age != null) map['age'] = age;
  if (absenteeismStatus != null) map['absenteeismStatus'] = absenteeismStatus;
  if (password != null && password.isNotEmpty) map['password'] = password;
  if (class_id != null) map['class_id'] = class_id;
  return map;
}

sealed class StudentResult<T> {}

class StudentSuccess<T> extends StudentResult<T> {
  final T data;
  StudentSuccess(this.data);
}

class StudentError extends StudentResult<Never> {
  final String message;
  final int? statusCode;
  StudentError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/students';

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

class StudentsService {
  StudentsService._();
  static final StudentsService _instance = StudentsService._();
  factory StudentsService() => _instance;

  Future<StudentResult<StudentModel>> createStudent(Map<String, dynamic> body) async {
    try {
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('StudentsService.createStudent', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return StudentError('Invalid response from server. Please try again.');
        final m = raw as Map<String, dynamic>;
        final studentMap = m['student'] ?? m;
        if (studentMap is! Map<String, dynamic>) return StudentError('Invalid response from server. Please try again.');
        return StudentSuccess(StudentModel.fromJson(studentMap));
      }
      if (response.statusCode == 409) return StudentError('Registration number already exists', 409);
      if (response.statusCode == 400) return StudentError(_errorMessage(response) ?? 'Invalid data. Please check and try again.', 400);
      return StudentError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentsService.createStudent'));
    }
  }

  /// List students, optionally filtered by class. Uses GET .../students?class_id=X when [classId] is set.
  Future<StudentResult<List<StudentModel>>> listStudents({int? classId}) async {
    try {
      var url = apiUrl(_base);
      if (classId != null) {
        url = url.replace(queryParameters: {'class_id': classId.toString()});
      }
      final response = await _client.get(url);
      devLogResponse('StudentsService.listStudents', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load students. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['data'] is List) {
          list = raw['data'] as List<dynamic>;
        } else if (raw['students'] is List) {
          list = raw['students'] as List<dynamic>;
        } else {
          return StudentError(_errorMessage(response) ?? 'Invalid response from server. Please try again.');
        }
      } else {
        return StudentError('Invalid response from server. Please try again.');
      }
      final students = <StudentModel>[];
      for (final e in list) {
        if (e is! Map) continue;
        final map = e as Map;
        // API may return flat object or wrapped as { "student": { ... } }
        final flat = map['student'] is Map ? Map<String, dynamic>.from(map['student'] as Map) : Map<String, dynamic>.from(map);
        try {
          students.add(StudentModel.fromJson(flat));
        } catch (_) {}
      }
      return StudentSuccess(students);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentsService.listStudents'));
    }
  }

  Future<StudentResult<StudentModel>> getStudent(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('StudentsService.getStudent', response.statusCode, response.body);
      if (response.statusCode == 404) return StudentError('Student not found.', 404);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not load student. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = Map<String, dynamic>.from(raw['student'] as Map? ?? raw);
        // Include Class/class and School/school from response (API may use capital letters)
        final classObj = raw['Class'] ?? raw['class'];
        if (classObj is Map) map['class'] = classObj;
        final schoolObj = raw['School'] ?? raw['school'];
        if (schoolObj is Map) {
          final school = schoolObj as Map;
          if (school['name'] != null) {
            map['schoolName'] ??= school['name'].toString();
            map['school_name'] ??= school['name'].toString();
          }
        }
      } else {
        return StudentError('Invalid response from server. Please try again.');
      }
      return StudentSuccess(StudentModel.fromJson(map));
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentsService.getStudent'));
    }
  }

  Future<StudentResult<StudentModel>> updateStudent(int id, Map<String, dynamic> body) async {
    try {
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('StudentsService.updateStudent', response.statusCode, response.body);
      if (response.statusCode == 404) return StudentError('Student not found.', 404);
      if (response.statusCode == 409) return StudentError('Registration number already exists', 409);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['student'] as Map<String, dynamic>? ?? raw;
      } else {
        return StudentError('Invalid response from server. Please try again.');
      }
      return StudentSuccess(StudentModel.fromJson(map));
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentsService.updateStudent'));
    }
  }

  Future<StudentResult<bool>> deleteStudent(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('StudentsService.deleteStudent', response.statusCode, response.body);
      if (response.statusCode == 404) return StudentError('Student not found.', 404);
      if (response.statusCode != 200) {
        return StudentError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return StudentSuccess(true);
    } catch (e, st) {
      return StudentError(userFriendlyMessage(e, st, 'StudentsService.deleteStudent'));
    }
  }
}
