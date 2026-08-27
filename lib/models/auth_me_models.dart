import 'package:kobac/models/auth_user.dart';

// ==================== HELPERS ====================
int _parseId(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String? _strOpt(dynamic v) => v == null ? null : v.toString().trim();

class SchoolBranding {
  final int id;
  final String? name;
  final String? address;
  final String? location;
  final String? logoPath;
  final String? logoUrl;

  const SchoolBranding({
    required this.id,
    this.name,
    this.address,
    this.location,
    this.logoPath,
    this.logoUrl,
  });

  factory SchoolBranding.fromJson(Map<String, dynamic> json) => SchoolBranding(
    id: _parseId(json['id']),
    name: _strOpt(json['name']),
    address: _strOpt(json['address']),
    location: _strOpt(json['location']),
    logoPath: _strOpt(json['logo_path'] ?? json['logoPath']),
    logoUrl: _strOpt(json['logo_url'] ?? json['logoUrl']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'location': location,
    'logo_path': logoPath,
    'logo_url': logoUrl,
  };
}

class SchoolFeatures {
  final bool? feesEnabled;
  final bool? examsEnabled;

  const SchoolFeatures({this.feesEnabled, this.examsEnabled});

  factory SchoolFeatures.fromJson(Map<String, dynamic> json) => SchoolFeatures(
    feesEnabled: _boolOpt(json['feesEnabled'] ?? json['fees_enabled']),
    examsEnabled: _boolOpt(json['examsEnabled'] ?? json['exams_enabled']),
  );

  Map<String, dynamic> toJson() => {
    'feesEnabled': feesEnabled,
    'examsEnabled': examsEnabled,
  };
}

bool? _boolOpt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    if (value.toLowerCase() == 'true' || value == '1') return true;
    if (value.toLowerCase() == 'false' || value == '0') return false;
  }
  return null;
}

// ==================== ROLE PROFILES ====================

/// Teacher profile from GET /api/auth/me (profile when role == TEACHER).
class TeacherProfile {
  final int id;
  final int? userId;
  final int? schoolId;
  final String? fullName;
  final String? phone;
  final String? motherName;
  final String? graduatedUniversity;
  final String? gender;
  final String? address;
  final String? email;
  final String? createdAt;
  final String? updatedAt;

  TeacherProfile({
    required this.id,
    this.userId,
    this.schoolId,
    this.fullName,
    this.phone,
    this.motherName,
    this.graduatedUniversity,
    this.gender,
    this.address,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: _parseId(json['id']),
      userId: json['user_id'] != null
          ? _parseId(json['user_id'])
          : (json['userId'] != null ? _parseId(json['userId']) : null),
      schoolId: json['school_id'] != null
          ? _parseId(json['school_id'])
          : (json['schoolId'] != null ? _parseId(json['schoolId']) : null),
      fullName: _strOpt(
        json['full_name'] ??
            json['fullName'] ??
            json['name'] ??
            json['teacher_name'],
      ),
      phone: _strOpt(
        json['phone'] ??
            json['telephone'] ??
            json['mobile'] ??
            json['phone_number'],
      ),
      motherName: _strOpt(json['mother_name'] ?? json['motherName']),
      graduatedUniversity: _strOpt(
        json['graduated_university'] ??
            json['graduatedUniversity'] ??
            json['university'],
      ),
      gender: _strOpt(json['gender'] ?? json['sex']),
      address: _strOpt(json['address'] ?? json['location']),
      email: _strOpt(json['email']),
      createdAt: _strOpt(json['created_at'] ?? json['createdAt']),
      updatedAt: _strOpt(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

/// Student profile from GET /api/auth/me (profile when role == STUDENT).
/// Matches full API shape: studentName, motherName, birthDate, sex, telephone, Class, etc.
class StudentProfile {
  final int id;
  final int? userId;
  final int? schoolId;
  final int? classId;
  final String? emisNumber;
  final String? studentName;
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
  final Map<String, dynamic>? class_;

  StudentProfile({
    required this.id,
    this.userId,
    this.schoolId,
    this.classId,
    this.emisNumber,
    this.studentName,
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
    this.class_,
  });

  /// Phone/telephone from API.
  String? get phone => telephone;

  /// Class shift resolved from the nested class object, if the backend
  /// includes it — either a flat string or a nested `{id, name}` object.
  String get classShiftName {
    final shift = class_?['shift'];
    if (shift is Map) return (shift['name'] ?? '').toString().trim();
    if (shift is String) return shift.trim();
    return '';
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final c = json['class'] ?? json['Class'] ?? json['class_'];
    String? cn = _strOpt(json['className'] ?? json['class_name']);
    if ((cn?.isEmpty ?? true) && c is Map && c['name'] != null)
      cn = c['name'].toString();
    return StudentProfile(
      id: _parseId(json['id']),
      userId: json['user_id'] != null ? _parseId(json['user_id']) : null,
      schoolId: json['school_id'] != null ? _parseId(json['school_id']) : null,
      classId: json['class_id'] != null
          ? _parseId(json['class_id'])
          : (c is Map ? _parseId(c['id']) : null),
      emisNumber: _strOpt(json['emis_number'] ?? json['emisNumber']),
      studentName: _strOpt(
        json['student_name'] ?? json['studentName'] ?? json['name'],
      ),
      motherName: _strOpt(json['mother_name'] ?? json['motherName']),
      refugeeStatus: _strOpt(json['refugee_status'] ?? json['refugeeStatus']),
      orphanStatus: _strOpt(json['orphan_status'] ?? json['orphanStatus']),
      birthDate: _strOpt(json['birth_date'] ?? json['birthDate']),
      sex: _strOpt(json['sex'] ?? json['gender']),
      telephone: _strOpt(json['telephone'] ?? json['phone']),
      birthPlace: _strOpt(json['birth_place'] ?? json['birthPlace']),
      nationality: _strOpt(json['nationality']),
      studentState: _strOpt(json['student_state'] ?? json['studentState']),
      studentDistrict: _strOpt(
        json['student_district'] ?? json['studentDistrict'],
      ),
      studentVillage: _strOpt(
        json['student_village'] ?? json['studentVillage'],
      ),
      disabilityStatus: _strOpt(
        json['disability_status'] ?? json['disabilityStatus'],
      ),
      guardianName: _strOpt(json['guardian_name'] ?? json['guardianName']),
      schoolName: _strOpt(json['school_name'] ?? json['schoolName']),
      className: cn,
      age: json['age'] != null
          ? (json['age'] is int
                ? json['age'] as int
                : int.tryParse(json['age'].toString()) ?? null)
          : null,
      absenteeismStatus: _strOpt(
        json['absenteeism_status'] ?? json['absenteeismStatus'],
      ),
      createdAt: _strOpt(json['created_at'] ?? json['createdAt']),
      updatedAt: _strOpt(json['updated_at'] ?? json['updatedAt']),
      class_: c is Map<String, dynamic> ? c : null,
    );
  }
}

/// Parent profile from GET /api/auth/me (profile when role == PARENT).
class ParentProfile {
  final int id;
  final int? userId;
  final int? schoolId;
  final String? name;
  final String? email;
  final String? phone;
  final List<LinkedStudent> linkedStudents;

  ParentProfile({
    required this.id,
    this.userId,
    this.schoolId,
    this.name,
    this.email,
    this.phone,
    this.linkedStudents = const [],
  });

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    List<LinkedStudent> students = [];
    final list =
        json['linked_students'] ?? json['linkedStudents'] ?? json['students'];
    if (list is List) {
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          students.add(LinkedStudent.fromJson(e));
        }
      }
    }
    return ParentProfile(
      id: _parseId(json['id']),
      userId: json['user_id'] != null ? _parseId(json['user_id']) : null,
      schoolId: json['school_id'] != null ? _parseId(json['school_id']) : null,
      name: _strOpt(json['name']),
      email: _strOpt(json['email']),
      phone: _strOpt(json['phone']),
      linkedStudents: students,
    );
  }
}

class LinkedStudent {
  final int id;
  final String? name;
  final String? emisNumber;
  final String? className;

  LinkedStudent({required this.id, this.name, this.emisNumber, this.className});

  factory LinkedStudent.fromJson(Map<String, dynamic> json) {
    final c = json['class'] ?? json['Class'];
    String? cn;
    if (c is Map && c['name'] != null) cn = c['name'].toString();
    return LinkedStudent(
      id: _parseId(json['id'] ?? json['student_id']),
      name: _strOpt(
        json['name'] ?? json['student_name'] ?? json['studentName'],
      ),
      emisNumber: _strOpt(json['emis_number'] ?? json['emisNumber']),
      className: cn ?? _strOpt(json['class_name'] ?? json['className']),
    );
  }
}

/// School admin profile from GET /api/auth/me (may be null if backend only returns user).
class SchoolAdminProfile {
  final int id;
  final int? userId;
  final int? schoolId;
  final String? name;
  final String? email;

  SchoolAdminProfile({
    required this.id,
    this.userId,
    this.schoolId,
    this.name,
    this.email,
  });

  factory SchoolAdminProfile.fromJson(Map<String, dynamic> json) {
    return SchoolAdminProfile(
      id: _parseId(json['id']),
      userId: json['user_id'] != null ? _parseId(json['user_id']) : null,
      schoolId: json['school_id'] != null ? _parseId(json['school_id']) : null,
      name: _strOpt(json['name']),
      email: _strOpt(json['email']),
    );
  }
}

// ==================== AUTH ME RESPONSE ====================

/// Result of GET /api/auth/me: user + role-specific profile + optional school feature flags.
/// Backend should include feesEnabled (or school.fees_enabled) so the app can hide fees/payment UI when disabled.
class AuthMeResponse {
  final AuthUser user;
  final dynamic
  profile; // TeacherProfile | StudentProfile | ParentProfile | SchoolAdminProfile | null
  final SchoolBranding? school;
  final SchoolFeatures? schoolFeatures;

  /// When false, hide all fees/payment UI. When null (legacy), treat as true for backward compatibility.
  final bool? feesEnabled;

  AuthMeResponse({
    required this.user,
    this.profile,
    this.school,
    this.schoolFeatures,
    this.feesEnabled,
  });

  TeacherProfile? get teacherProfile =>
      profile is TeacherProfile ? profile as TeacherProfile : null;
  StudentProfile? get studentProfile =>
      profile is StudentProfile ? profile as StudentProfile : null;
  ParentProfile? get parentProfile =>
      profile is ParentProfile ? profile as ParentProfile : null;
  SchoolAdminProfile? get schoolAdminProfile =>
      profile is SchoolAdminProfile ? profile as SchoolAdminProfile : null;
}

/// Parse profile map by role. Never store password fields.
/// For TEACHER, accepts nested profile.teacher or profile.teacher_profile if present.
dynamic parseProfileByRole(String role, dynamic profileJson) {
  if (profileJson == null) return null;
  if (profileJson is! Map<String, dynamic>) return null;
  final roleUpper = role.toUpperCase();
  switch (roleUpper) {
    case 'TEACHER':
      {
        final map =
            profileJson['teacher'] ??
            profileJson['teacher_profile'] ??
            profileJson['data'] ??
            profileJson;
        if (map is Map<String, dynamic>) return TeacherProfile.fromJson(map);
        return TeacherProfile.fromJson(profileJson);
      }
    case 'STUDENT':
      return StudentProfile.fromJson(profileJson);
    case 'PARENT':
      return ParentProfile.fromJson(profileJson);
    case 'SCHOOL_ADMIN':
      return SchoolAdminProfile.fromJson(profileJson);
    default:
      return null;
  }
}
