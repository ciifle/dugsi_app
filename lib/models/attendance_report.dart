/// School Admin attendance report models.
///
/// Field names mirror the backend's attendanceReport.service.js
/// (getClassAttendanceReport / getStudentAttendanceReport). Every figure is
/// the backend's: Flutter never recomputes counts or percentages. Lessons
/// that were never recorded are simply absent from the data; they are never
/// shown as ABSENT.

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

double? _double(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.trim());

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// Backend percentage as sent (e.g. 80, 84.38); "—" when null/blank —
/// never "0%" for a student/class with nothing recorded.
String formatAttendancePercentage(double? value) {
  if (value == null) return '—';
  if (value == value.roundToDouble()) return '${value.toStringAsFixed(0)}%';
  var text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '$text%';
}

/// Counts shared by both report types (backend summaryFields()).
class AttendanceCounts {
  final int recordedSessions;
  final int present;
  final int absent;
  final int late;
  final int other;
  final double? percentage;

  const AttendanceCounts({
    this.recordedSessions = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.other = 0,
    this.percentage,
  });

  factory AttendanceCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AttendanceCounts();
    return AttendanceCounts(
      recordedSessions: _int(json['recorded_sessions']),
      present: _int(json['present_count']),
      absent: _int(json['absent_count']),
      late: _int(json['late_count']),
      other: _int(json['other_count']),
      percentage: _double(json['attendance_percentage']),
    );
  }

  String get percentageLabel => formatAttendancePercentage(percentage);
}

class ReportPeriod {
  final String? startDate;
  final String? endDate;
  const ReportPeriod({this.startDate, this.endDate});

  factory ReportPeriod.fromJson(Map<String, dynamic>? json) => ReportPeriod(
    startDate: _str(json?['start_date']),
    endDate: _str(json?['end_date']),
  );

  String get label => '${startDate ?? '—'} to ${endDate ?? '—'}';
}

// --- Class report -----------------------------------------------------------

class ClassReportStudent {
  final int studentId;
  final String? studentName;
  final String? emisNumber;
  final String? enrollmentStatus;
  final AttendanceCounts counts;

  const ClassReportStudent({
    required this.studentId,
    this.studentName,
    this.emisNumber,
    this.enrollmentStatus,
    this.counts = const AttendanceCounts(),
  });

  factory ClassReportStudent.fromJson(Map<String, dynamic> json) =>
      ClassReportStudent(
        studentId: _int(json['student_id']),
        studentName: _str(json['student_name']),
        emisNumber: _str(json['emis_number']),
        enrollmentStatus: _str(json['enrollment_status']),
        counts: AttendanceCounts.fromJson(json),
      );

  String get displayName => studentName ?? 'Student #$studentId';
}

class ClassReportSummary {
  final int totalStudents;
  final int studentsWithRecords;
  final int studentsWithoutRecords;
  final int lessonsRecorded;
  final int daysWithAttendance;
  final String? firstRecordedDate;
  final String? lastRecordedDate;
  final AttendanceCounts counts;

  const ClassReportSummary({
    this.totalStudents = 0,
    this.studentsWithRecords = 0,
    this.studentsWithoutRecords = 0,
    this.lessonsRecorded = 0,
    this.daysWithAttendance = 0,
    this.firstRecordedDate,
    this.lastRecordedDate,
    this.counts = const AttendanceCounts(),
  });

  factory ClassReportSummary.fromJson(Map<String, dynamic>? json) =>
      ClassReportSummary(
        totalStudents: _int(json?['total_students']),
        studentsWithRecords: _int(json?['students_with_records']),
        studentsWithoutRecords: _int(json?['students_without_records']),
        lessonsRecorded: _int(json?['lessons_recorded']),
        daysWithAttendance: _int(json?['days_with_attendance']),
        firstRecordedDate: _str(json?['first_recorded_date']),
        lastRecordedDate: _str(json?['last_recorded_date']),
        counts: AttendanceCounts.fromJson(json),
      );
}

/// GET /api/school-admin/attendance/reports/class
class ClassAttendanceReport {
  final int? academicYearId;
  final String? academicYearName;
  final int? classId;
  final String? className;
  final ReportPeriod period;
  final ClassReportSummary summary;
  final bool hasAttendance;
  final String? message;
  final List<ClassReportStudent> students;

  const ClassAttendanceReport({
    this.academicYearId,
    this.academicYearName,
    this.classId,
    this.className,
    this.period = const ReportPeriod(),
    this.summary = const ClassReportSummary(),
    this.hasAttendance = false,
    this.message,
    this.students = const [],
  });

  /// Null when the body is not a class report (no `students` array).
  static ClassAttendanceReport? tryParse(dynamic raw) {
    final json = _map(raw);
    if (json == null || json['students'] is! List) return null;
    final year = _map(json['academic_year']);
    final cls = _map(json['class']);
    final students = (json['students'] as List)
        .whereType<Map>()
        .map((e) => ClassReportStudent.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.studentId > 0)
        .toList();
    final summary = ClassReportSummary.fromJson(_map(json['summary']));
    final has = json['has_attendance'];
    return ClassAttendanceReport(
      academicYearId: _intOrNull(year?['id']),
      academicYearName: _str(year?['name']),
      classId: _intOrNull(cls?['id']),
      className: _str(cls?['name']),
      period: ReportPeriod.fromJson(_map(json['period'])),
      summary: summary,
      hasAttendance: has == null
          ? summary.counts.recordedSessions > 0
          : has == true || has == 1,
      message: _str(json['message']),
      students: students,
    );
  }
}

// --- Student report ---------------------------------------------------------

class StudentHistoryEntry {
  final int? attendanceId;
  final String? date;
  final String? time;
  final String? period;
  final String? subjectName;
  final String? teacherName;
  final String? className;

  /// PRESENT / ABSENT / LATE (or another legacy value) as recorded.
  final String? status;

  const StudentHistoryEntry({
    this.attendanceId,
    this.date,
    this.time,
    this.period,
    this.subjectName,
    this.teacherName,
    this.className,
    this.status,
  });

  factory StudentHistoryEntry.fromJson(Map<String, dynamic> json) =>
      StudentHistoryEntry(
        attendanceId: _intOrNull(json['attendance_id']),
        date: _str(json['date']),
        time: _str(json['time']),
        period: _str(json['period']),
        subjectName: _str(_map(json['subject'])?['name']),
        teacherName: _str(_map(json['teacher'])?['full_name']),
        className: _str(_map(json['class'])?['name']),
        status: _str(json['status'])?.toUpperCase(),
      );
}

/// GET /api/school-admin/attendance/reports/student/:studentId
class StudentAttendanceReport {
  final int? academicYearId;
  final String? academicYearName;
  final int studentId;
  final String? studentName;
  final String? emisNumber;
  final String? className;
  final String? enrollmentStatus;
  final ReportPeriod period;
  final AttendanceCounts counts;
  final int subjectsRecorded;
  final int daysWithAttendance;
  final bool hasAttendance;
  final String? message;

  /// In backend order (date, then time).
  final List<StudentHistoryEntry> history;

  const StudentAttendanceReport({
    this.academicYearId,
    this.academicYearName,
    required this.studentId,
    this.studentName,
    this.emisNumber,
    this.className,
    this.enrollmentStatus,
    this.period = const ReportPeriod(),
    this.counts = const AttendanceCounts(),
    this.subjectsRecorded = 0,
    this.daysWithAttendance = 0,
    this.hasAttendance = false,
    this.message,
    this.history = const [],
  });

  /// Null when the body is not a student report (no `student` / `history`).
  static StudentAttendanceReport? tryParse(dynamic raw) {
    final json = _map(raw);
    final student = _map(json?['student']);
    if (json == null || student == null || json['history'] is! List) {
      return null;
    }
    final year = _map(json['academic_year']);
    final enrollment = _map(json['enrollment']);
    final summary = _map(json['summary']);
    final counts = AttendanceCounts.fromJson(summary);
    final has = json['has_attendance'];
    return StudentAttendanceReport(
      academicYearId: _intOrNull(year?['id']),
      academicYearName: _str(year?['name']),
      studentId: _int(student['id']),
      studentName: _str(student['name']),
      emisNumber: _str(student['emis_number']),
      className: _str(enrollment?['class_name']),
      enrollmentStatus: _str(enrollment?['status']),
      period: ReportPeriod.fromJson(_map(json['period'])),
      counts: counts,
      subjectsRecorded: _int(summary?['subjects_recorded']),
      daysWithAttendance: _int(summary?['days_with_attendance']),
      hasAttendance: has == null
          ? counts.recordedSessions > 0
          : has == true || has == 1,
      message: _str(json['message']),
      history: (json['history'] as List)
          .whereType<Map>()
          .map((e) => StudentHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
