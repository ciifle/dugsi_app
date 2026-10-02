import 'package:kobac/models/attendance_report.dart';

/// School Admin lesson attendance models.
///
/// Field names mirror the backend's shared lesson attendance service
/// (`attendance.service.js`: formatLesson / listClassLessons /
/// getLessonRegister / lessonSummary). Teacher and School Admin read and write
/// the same lesson attendance rows; teacher, subject, period and time always
/// come from the timetable lesson and are never sent by the client.

/// Statuses the lesson register PUT accepts. Historical rows may also carry
/// LATE (set through the single-record PATCH), which is displayed but never
/// sent through the register save.
const String kStatusPresent = 'PRESENT';
const String kStatusAbsent = 'ABSENT';
const String kStatusLate = 'LATE';
const List<String> kLessonRegisterStatuses = [kStatusPresent, kStatusAbsent];

int _int(dynamic v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  final parsed = _int(v);
  return parsed > 0 ? parsed : null;
}

String? _str(dynamic v) {
  if (v == null) return null;
  final text = v.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// "08:00:00" -> "8:00 AM". Falls back to the raw value when unparseable.
String formatLessonTime(String? value) {
  if (value == null || value.isEmpty) return '';
  final parts = value.split(':');
  final h = int.tryParse(parts.first);
  final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (h == null || m == null) return value;
  final suffix = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:${m.toString().padLeft(2, '0')} $suffix';
}

class LessonPeriod {
  final int? id;
  final String? name;
  final int? periodNumber;
  final String? shift;

  const LessonPeriod({this.id, this.name, this.periodNumber, this.shift});

  factory LessonPeriod.fromJson(Map<String, dynamic> json) => LessonPeriod(
    id: _intOrNull(json['id']),
    name: _str(json['name']),
    periodNumber: _intOrNull(json['period_number']),
    shift: _str(json['shift']),
  );

  /// "Period 1" — prefers the configured period name.
  String get label {
    if (name != null) return name!;
    if (periodNumber != null) return 'Period $periodNumber';
    return 'Period';
  }
}

/// One timetable lesson (GET /attendance/lessons item, or register.lesson).
class AttendanceLesson {
  final int timetableId;
  final String? day;
  final String? startTime;
  final String? endTime;
  final LessonPeriod? period;
  final int? subjectId;
  final String? subjectName;
  final int? teacherId;
  final String? teacherName;

  /// Only present on the lessons list.
  final bool attendanceRecorded;
  final int recordedCount;

  const AttendanceLesson({
    required this.timetableId,
    this.day,
    this.startTime,
    this.endTime,
    this.period,
    this.subjectId,
    this.subjectName,
    this.teacherId,
    this.teacherName,
    this.attendanceRecorded = false,
    this.recordedCount = 0,
  });

  factory AttendanceLesson.fromJson(Map<String, dynamic> json) {
    final period = _map(json['period']);
    final subject = _map(json['subject']);
    final teacher = _map(json['teacher']);
    final recorded = json['attendance_recorded'];
    return AttendanceLesson(
      timetableId: _int(json['timetable_id']),
      day: _str(json['day']),
      startTime: _str(json['start_time']),
      endTime: _str(json['end_time']),
      period: period == null ? null : LessonPeriod.fromJson(period),
      subjectId: _intOrNull(subject?['id']),
      subjectName: _str(subject?['name']),
      teacherId: _intOrNull(teacher?['id']),
      teacherName: _str(teacher?['full_name']),
      attendanceRecorded: recorded == true || recorded == 1,
      recordedCount: _int(json['recorded_count']),
    );
  }

  String get periodLabel => period?.label ?? 'Lesson';
  String get subjectLabel => subjectName ?? 'Subject not set';
  String get teacherLabel => teacherName ?? 'No teacher assigned';

  /// "8:00 AM – 8:40 AM"
  String get timeRange {
    final start = formatLessonTime(startTime);
    final end = formatLessonTime(endTime);
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start – $end';
  }
}

/// GET /api/school-admin/attendance/lessons response.
class AttendanceLessonsResult {
  final int? academicYearId;
  final String? academicYearName;
  final int? classId;
  final String? className;
  final String? date;
  final String? dayName;
  final List<AttendanceLesson> lessons;

  const AttendanceLessonsResult({
    this.academicYearId,
    this.academicYearName,
    this.classId,
    this.className,
    this.date,
    this.dayName,
    required this.lessons,
  });

  factory AttendanceLessonsResult.fromJson(Map<String, dynamic> json) {
    final year = _map(json['academic_year']);
    final cls = _map(json['class']);
    final lessons = json['lessons'] is List ? json['lessons'] as List : const [];
    return AttendanceLessonsResult(
      academicYearId: _intOrNull(year?['id']),
      academicYearName: _str(year?['name']),
      classId: _intOrNull(cls?['id']),
      className: _str(cls?['name']),
      date: _str(json['date']),
      dayName: _str(json['day_name']),
      lessons: lessons
          .whereType<Map>()
          .map((e) => AttendanceLesson.fromJson(Map<String, dynamic>.from(e)))
          .where((l) => l.timetableId > 0)
          .toList(),
    );
  }
}

class AttendanceAuditUser {
  final int? id;
  final String? name;
  final String? role;

  const AttendanceAuditUser({this.id, this.name, this.role});

  static AttendanceAuditUser? fromJson(dynamic raw) {
    final json = _map(raw);
    if (json == null) return null;
    return AttendanceAuditUser(
      id: _intOrNull(json['id']),
      name: _str(json['name']),
      role: _str(json['role']),
    );
  }
}

/// One register row: an enrolled student (or a historical non-enrolled row)
/// with the lesson's saved status, if any.
class RegisterStudent {
  final int studentId;
  final String? studentName;
  final String? emisNumber;
  final bool enrolled;
  final int? attendanceId;

  /// Saved backend status: PRESENT / ABSENT / LATE (historical) / null.
  final String? status;
  final AttendanceAuditUser? recordedBy;
  final AttendanceAuditUser? updatedBy;
  final String? updatedAt;

  const RegisterStudent({
    required this.studentId,
    this.studentName,
    this.emisNumber,
    this.enrolled = true,
    this.attendanceId,
    this.status,
    this.recordedBy,
    this.updatedBy,
    this.updatedAt,
  });

  factory RegisterStudent.fromJson(Map<String, dynamic> json) {
    final enrolled = json['enrolled'];
    return RegisterStudent(
      studentId: _int(json['student_id']),
      studentName: _str(json['student_name']),
      emisNumber: _str(json['emis_number']),
      enrolled: enrolled == null || enrolled == true || enrolled == 1,
      attendanceId: _intOrNull(json['attendance_id']),
      status: _str(json['status'])?.toUpperCase(),
      recordedBy: AttendanceAuditUser.fromJson(json['recorded_by']),
      updatedBy: AttendanceAuditUser.fromJson(json['updated_by']),
      updatedAt: _str(json['updated_at']),
    );
  }

  String get displayName => studentName ?? 'Student #$studentId';

  /// Rows the register PUT may change. Historical non-enrolled rows are
  /// rejected by the backend (STUDENT_NOT_ENROLLED), so they stay read-only.
  bool get editable => enrolled;
}

/// Backend-calculated register summary. Displayed as-is; never recomputed
/// as the authoritative value.
class RegisterSummary {
  final int totalStudents;
  final int recorded;
  final int notRecorded;
  final int present;
  final int absent;
  final int late;

  /// null when nothing has been recorded yet.
  final double? attendancePercentage;

  const RegisterSummary({
    this.totalStudents = 0,
    this.recorded = 0,
    this.notRecorded = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.attendancePercentage,
  });

  factory RegisterSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegisterSummary();
    final pct = json['attendance_percentage'];
    return RegisterSummary(
      totalStudents: _int(json['total_students']),
      recorded: _int(json['recorded']),
      notRecorded: _int(json['not_recorded']),
      present: _int(json['present']),
      absent: _int(json['absent']),
      late: _int(json['late']),
      attendancePercentage: pct is num
          ? pct.toDouble()
          : double.tryParse('${pct ?? ''}'),
    );
  }

  /// Fallback only for a response without `summary`; mirrors the backend's
  /// lessonSummary().
  factory RegisterSummary.fromStudents(List<RegisterStudent> students) {
    int count(String s) => students.where((x) => x.status == s).length;
    final recorded = students.where((x) => x.status != null).length;
    final present = count(kStatusPresent);
    return RegisterSummary(
      totalStudents: students.length,
      recorded: recorded,
      notRecorded: students.length - recorded,
      present: present,
      absent: count(kStatusAbsent),
      late: count(kStatusLate),
      attendancePercentage: recorded == 0
          ? null
          : (present / recorded * 10000).round() / 100,
    );
  }

  /// "84%" / "84.38%" / "—".
  String get percentageLabel => formatAttendancePercentage(attendancePercentage);
}

/// GET /api/school-admin/attendance/register response (also embedded as
/// `register` in the PUT response).
class LessonRegister {
  final int? academicYearId;
  final String? academicYearName;
  final int? classId;
  final String? className;
  final String? date;
  final String? dayName;
  final AttendanceLesson lesson;
  final bool attendanceRecorded;
  final RegisterSummary summary;
  final List<RegisterStudent> students;

  const LessonRegister({
    this.academicYearId,
    this.academicYearName,
    this.classId,
    this.className,
    this.date,
    this.dayName,
    required this.lesson,
    required this.attendanceRecorded,
    required this.summary,
    required this.students,
  });

  /// Returns null only when the body is not a register at all (no
  /// `students` array). A first-time register — every `status`,
  /// `attendance_id`, `recorded_by` and `updated_by` null — is valid, and so
  /// is an empty `students` array (no enrolled students).
  static LessonRegister? tryParse(dynamic raw) {
    final json = _map(raw);
    if (json == null || json['students'] is! List) return null;
    final year = _map(json['academic_year']);
    final cls = _map(json['class']);
    final lesson = _map(json['lesson']);
    final students = (json['students'] as List)
        .whereType<Map>()
        .map((e) => RegisterStudent.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.studentId > 0)
        .toList();
    final recorded = json['attendance_recorded'];
    final summary = _map(json['summary']);
    return LessonRegister(
      academicYearId: _intOrNull(year?['id']),
      academicYearName: _str(year?['name']),
      classId: _intOrNull(cls?['id']),
      className: _str(cls?['name']),
      date: _str(json['date']),
      dayName: _str(json['day_name']),
      // Missing lesson context: timetableId 0, the caller substitutes the
      // lesson it selected.
      lesson: lesson == null
          ? const AttendanceLesson(timetableId: 0)
          : AttendanceLesson.fromJson(lesson),
      attendanceRecorded: recorded == null
          ? students.any((s) => s.status != null)
          : recorded == true || recorded == 1,
      // The backend summary is authoritative; only derive one if absent.
      summary: summary == null
          ? RegisterSummary.fromStudents(students)
          : RegisterSummary.fromJson(summary),
      students: students,
    );
  }

  LessonRegister withLesson(AttendanceLesson value) => LessonRegister(
    academicYearId: academicYearId,
    academicYearName: academicYearName,
    classId: classId,
    className: className,
    date: date,
    dayName: dayName,
    lesson: value,
    attendanceRecorded: attendanceRecorded,
    summary: summary,
    students: students,
  );

  /// Students with a saved status (PRESENT / ABSENT / historical LATE).
  int get existingRecordCount => students.where((s) => s.status != null).length;
}

/// One `records[]` entry of the register PUT.
class RegisterRecord {
  final int studentId;
  final String status;
  const RegisterRecord(this.studentId, this.status);

  Map<String, dynamic> toJson() => {'student_id': studentId, 'status': status};
}

/// PUT /api/school-admin/attendance/register response.
class RegisterSaveResult {
  final int createdCount;
  final int updatedCount;
  final int unchangedCount;
  final LessonRegister? register;

  const RegisterSaveResult({
    this.createdCount = 0,
    this.updatedCount = 0,
    this.unchangedCount = 0,
    this.register,
  });

  factory RegisterSaveResult.fromJson(Map<String, dynamic> json) =>
      RegisterSaveResult(
        createdCount: _int(json['created_count']),
        updatedCount: _int(json['updated_count']),
        unchangedCount: _int(json['unchanged_count']),
        register: LessonRegister.tryParse(json['register']),
      );
}
