import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Teacher model matching API response (list/detail).
class TeacherModel {
  final int id;
  final int? userId;
  final int? schoolId;
  final String fullName;
  final String email;
  final String? phone;
  final String? motherName;
  final String? graduatedUniversity;
  final String? gender;
  final String? address;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? user;

  const TeacherModel({
    required this.id,
    this.userId,
    this.schoolId,
    required this.fullName,
    required this.email,
    this.phone,
    this.motherName,
    this.graduatedUniversity,
    this.gender,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    return TeacherModel(
      id: parseId(json['id']),
      userId: json['user_id'] != null ? parseId(json['user_id']) : null,
      schoolId: json['school_id'] != null ? parseId(json['school_id']) : null,
      fullName: str(json['fullName'] ?? json['full_name']),
      email: str(json['email']),
      phone: strOpt(json['phone']),
      motherName: strOpt(json['motherName'] ?? json['mother_name']),
      graduatedUniversity: strOpt(json['graduatedUniversity'] ?? json['graduated_university']),
      gender: strOpt(json['gender']),
      address: strOpt(json['address']),
      createdAt: strOpt(json['created_at']),
      updatedAt: strOpt(json['updated_at']),
      user: json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null,
    );
  }
}

/// Payload for creating a teacher (POST).
Map<String, dynamic> createTeacherPayload({
  required String fullName,
  required String email,
  required String phone,
  required String motherName,
  required String graduatedUniversity,
  required String gender,
  required String address,
  required String password,
}) {
  return {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'motherName': motherName,
    'graduatedUniversity': graduatedUniversity,
    'gender': gender,
    'address': address,
    'password': password,
  };
}

/// Payload for updating a teacher (PATCH). Only include non-null fields.
Map<String, dynamic> updateTeacherPayload({
  String? fullName,
  String? email,
  String? password,
  String? phone,
  String? motherName,
  String? graduatedUniversity,
  String? gender,
  String? address,
}) {
  final map = <String, dynamic>{};
  if (fullName != null) map['fullName'] = fullName;
  if (email != null) map['email'] = email;
  if (password != null && password.isNotEmpty) map['password'] = password;
  if (phone != null) map['phone'] = phone;
  if (motherName != null) map['motherName'] = motherName;
  if (graduatedUniversity != null) map['graduatedUniversity'] = graduatedUniversity;
  if (gender != null) map['gender'] = gender;
  if (address != null) map['address'] = address;
  return map;
}

/// Result of a teacher API call (success or error message).
sealed class TeacherResult<T> {}

class TeacherSuccess<T> extends TeacherResult<T> {
  final T data;
  TeacherSuccess(this.data);
}

class TeacherError extends TeacherResult<Never> {
  final String message;
  final int? statusCode;
  TeacherError(this.message, [this.statusCode]);
}

final _client = ApiClient();
final _base = 'api/school-admin/teachers';

/// Teachers CRUD service (uses authenticated API client).
class TeachersService {
  TeachersService._();
  static final TeachersService _instance = TeachersService._();
  factory TeachersService() => _instance;

  /// POST /api/school-admin/teachers
  Future<TeacherResult<TeacherModel>> createTeacher(Map<String, dynamic> body) async {
    try {
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('TeachersService.createTeacher', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final map = _parseJson(response.body);
        if (map == null || map is! Map) return TeacherError('Invalid response from server. Please try again.');
        final m = map as Map<String, dynamic>;
        final teacherMap = m['teacher'] ?? m;
        if (teacherMap is! Map<String, dynamic>) return TeacherError('Invalid response from server. Please try again.');
        return TeacherSuccess(TeacherModel.fromJson(teacherMap));
      }
      if (response.statusCode == 409) return TeacherError('Email already exists', 409);
      if (response.statusCode == 400) return TeacherError(_errorMessage(response) ?? 'Invalid data. Please check and try again.', 400);
      return TeacherError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeachersService.createTeacher'));
    }
  }

  /// GET /api/school-admin/teachers
  Future<TeacherResult<List<TeacherModel>>> listTeachers() async {
    try {
      final response = await _client.get(apiUrl(_base));
      devLogResponse('TeachersService.listTeachers', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load teachers. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['data'] is List) {
          list = raw['data'] as List<dynamic>;
        } else if (raw['teachers'] is List) {
          list = raw['teachers'] as List<dynamic>;
        } else {
          return TeacherError(_errorMessage(response) ?? 'Invalid response from server. Please try again.');
        }
      } else {
        return TeacherError('Invalid response from server. Please try again.');
      }
      final teachers = <TeacherModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            teachers.add(TeacherModel.fromJson(e));
          } catch (_) {
            // skip malformed item
          }
        }
      }
      return TeacherSuccess(teachers);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeachersService.listTeachers'));
    }
  }

  /// GET /api/school-admin/teachers/{id}
  Future<TeacherResult<TeacherModel>> getTeacher(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('TeachersService.getTeacher', response.statusCode, response.body);
      if (response.statusCode == 404) return TeacherError('Teacher not found.', 404);
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not load teacher. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['teacher'] as Map<String, dynamic>? ?? raw;
      } else {
        return TeacherError('Invalid response from server. Please try again.');
      }
      return TeacherSuccess(TeacherModel.fromJson(map));
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeachersService.getTeacher'));
    }
  }

  /// PATCH /api/school-admin/teachers/{id}
  Future<TeacherResult<TeacherModel>> updateTeacher(int id, Map<String, dynamic> body) async {
    try {
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('TeachersService.updateTeacher', response.statusCode, response.body);
      if (response.statusCode == 404) return TeacherError('Teacher not found.', 404);
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['teacher'] as Map<String, dynamic>? ?? raw;
      } else {
        return TeacherError('Invalid response from server. Please try again.');
      }
      return TeacherSuccess(TeacherModel.fromJson(map));
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeachersService.updateTeacher'));
    }
  }

  /// DELETE /api/school-admin/teachers/{id}
  Future<TeacherResult<bool>> deleteTeacher(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('TeachersService.deleteTeacher', response.statusCode, response.body);
      if (response.statusCode == 404) return TeacherError('Teacher not found.', 404);
      if (response.statusCode != 200) {
        return TeacherError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return TeacherSuccess(true);
    } catch (e, st) {
      return TeacherError(userFriendlyMessage(e, st, 'TeachersService.deleteTeacher'));
    }
  }
}

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
