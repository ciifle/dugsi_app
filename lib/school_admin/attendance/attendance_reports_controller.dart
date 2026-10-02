import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

import 'package:kobac/models/attendance_report.dart';
import 'package:kobac/school_admin/attendance/take_attendance_controller.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/services/students_service.dart';

enum AttendanceReportType { classReport, student }

enum ReportDatePreset { thisMonth, academicYear }

typedef StudentSearcher =
    Future<StudentResult<StudentPage>> Function(int academicYearId, String query);

/// A student picked from search (only what the report UI needs).
class ReportStudentOption {
  final int id;
  final String name;
  final String? emisNumber;
  final String? className;
  const ReportStudentOption({
    required this.id,
    required this.name,
    this.emisNumber,
    this.className,
  });
}

/// The exact filters a loaded report was produced with. The PDF download
/// always reuses these, so preview and PDF can never disagree.
class ReportFilters {
  final int academicYearId;
  final int? classId;
  final int? studentId;
  final String startDate;
  final String endDate;
  const ReportFilters({
    required this.academicYearId,
    this.classId,
    this.studentId,
    required this.startDate,
    required this.endDate,
  });
}

/// State for Attendance > Reports (Class / Student), shared by every
/// platform through the Attendance session. Changing any filter clears the
/// shown report so what is on screen always matches the filters.
class AttendanceReportsController extends ChangeNotifier {
  AttendanceReportsController({
    AttendanceService? service,
    ClassesLoader? loadClasses,
    StudentSearcher? searchStudents,
    DateTime Function()? now,
  }) : _service = service ?? AttendanceService(),
       _loadClassesFn =
           loadClasses ??
           ((id) => ClassesService().listClasses(academicYearId: id)),
       _searchFn =
           searchStudents ??
           ((year, q) => StudentsService().listStudentPage(
             academicYearId: year,
             search: q,
             page: 1,
             limit: 20,
           )),
       _now = now ?? DateTime.now {
    _resetDates();
  }

  final AttendanceService _service;
  final ClassesLoader _loadClassesFn;
  final StudentSearcher _searchFn;
  final DateTime Function() _now;
  bool _disposed = false;
  int _classesToken = 0, _classReportToken = 0;
  int _searchToken = 0, _studentReportToken = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  DateTime get today => DateUtils.dateOnly(_now());

  AttendanceReportType type = AttendanceReportType.classReport;

  void setType(AttendanceReportType value) {
    if (type == value) return;
    type = value;
    _notify();
  }

  // --- Academic year + dates ------------------------------------------------

  List<AcademicYear> years = const [];
  int? yearId;

  AcademicYear? get selectedYear {
    for (final y in years) {
      if (y.id == yearId) return y;
    }
    return null;
  }

  DateTime get firstDate {
    final s = selectedYear?.startDate;
    return s == null ? DateTime(2000) : DateUtils.dateOnly(s);
  }

  /// The backend accepts any range inside the academic year.
  DateTime get lastDate {
    final e = selectedYear?.endDate;
    final last = e == null ? today : DateUtils.dateOnly(e);
    return last.isBefore(firstDate) ? firstDate : last;
  }

  late DateTime startDate;
  late DateTime endDate;

  String get startYmd => attendanceYmd(startDate);
  String get endYmd => attendanceYmd(endDate);

  DateTime _clamp(DateTime d) {
    final day = DateUtils.dateOnly(d);
    if (day.isBefore(firstDate)) return firstDate;
    if (day.isAfter(lastDate)) return lastDate;
    return day;
  }

  /// Default: this month up to today, kept inside the academic year.
  void _resetDates() {
    final anchor = _clamp(today);
    startDate = _clamp(DateTime(anchor.year, anchor.month, 1));
    endDate = anchor;
  }

  /// Local validation; the backend also checks the academic-year range.
  String? get dateError => startDate.isAfter(endDate)
      ? 'The start date must be on or before the end date.'
      : null;

  void setYears(List<AcademicYear> value, AcademicYear? active) {
    years = value;
    if (yearId != null && years.any((y) => y.id == yearId)) {
      _notify();
      return;
    }
    final initial = active != null && years.any((y) => y.id == active.id)
        ? active.id
        : (years.isEmpty ? null : years.first.id);
    if (initial == null) {
      _notify();
      return;
    }
    selectYear(initial);
  }

  void selectYear(int id) {
    yearId = id;
    _resetDates();
    classes = const [];
    // Search results and enrollments are year specific.
    _clearStudentSearch();
    selectedStudent = null;
    _clearReports();
    _notify();
    loadClasses();
  }

  void setStartDate(DateTime d) {
    startDate = _clamp(d);
    _clearReports();
    _notify();
  }

  void setEndDate(DateTime d) {
    endDate = _clamp(d);
    _clearReports();
    _notify();
  }

  void applyPreset(ReportDatePreset preset) {
    switch (preset) {
      case ReportDatePreset.thisMonth:
        _resetDates();
      case ReportDatePreset.academicYear:
        startDate = firstDate;
        endDate = lastDate;
    }
    _clearReports();
    _notify();
  }

  void _clearReports() {
    _classReportToken++;
    _studentReportToken++;
    classReport = null;
    classReportError = null;
    classReportLoading = false;
    _classShown = null;
    studentReport = null;
    studentReportError = null;
    studentReportLoading = false;
    _studentShown = null;
  }

  // --- Class report ---------------------------------------------------------

  List<ClassModel> classes = const [];
  bool classesLoading = false;
  String? classesError;
  int? classId;

  ClassModel? get selectedClass {
    for (final c in classes) {
      if (c.id == classId) return c;
    }
    return null;
  }

  ClassAttendanceReport? classReport;
  bool classReportLoading = false;
  AttendanceLoadError? classReportError;
  bool classPdfBusy = false;
  ReportFilters? _classShown;

  Future<void> loadClasses() async {
    final year = yearId;
    if (year == null) return;
    final token = ++_classesToken;
    classesLoading = true;
    classesError = null;
    _notify();
    final result = await _loadClassesFn(year);
    if (_disposed || token != _classesToken) return;
    classesLoading = false;
    if (result is ClassSuccess<List<ClassModel>>) {
      classes = result.data;
      if (classId != null && !classes.any((c) => c.id == classId)) {
        classId = null;
      }
    } else {
      classes = const [];
      classId = null;
      classesError = (result as ClassError).message;
    }
    _notify();
  }

  void selectClass(int? id) {
    if (id == classId) return;
    classId = id;
    _clearReports();
    _notify();
  }

  bool get canViewClassReport =>
      yearId != null && classId != null && dateError == null;

  Future<void> loadClassReport() async {
    final year = yearId, cls = classId;
    if (year == null || cls == null || dateError != null) return;
    final filters = ReportFilters(
      academicYearId: year,
      classId: cls,
      startDate: startYmd,
      endDate: endYmd,
    );
    final token = ++_classReportToken;
    classReportLoading = true;
    classReportError = null;
    _notify();
    final result = await _service.getClassReport(
      academicYearId: year,
      classId: cls,
      startDate: filters.startDate,
      endDate: filters.endDate,
    );
    if (_disposed || token != _classReportToken) return;
    classReportLoading = false;
    if (result is AttendanceSuccess<ClassAttendanceReport>) {
      classReport = result.data;
      _classShown = filters;
    } else {
      classReport = null;
      _classShown = null;
      classReportError = AttendanceLoadError.from(result as AttendanceError);
    }
    _notify();
  }

  /// Class PDF for exactly the filters of the report on screen. `null` when
  /// a download is running or no report is shown.
  Future<AttendanceResult<PdfFileResult>?> downloadClassPdf() async {
    final f = _classShown;
    if (classPdfBusy || f == null || f.classId == null) return null;
    classPdfBusy = true;
    _notify();
    try {
      return await _service.printClassReport(
        academicYearId: f.academicYearId,
        classId: f.classId!,
        startDate: f.startDate,
        endDate: f.endDate,
      );
    } finally {
      classPdfBusy = false;
      _notify();
    }
  }

  // --- Student report -------------------------------------------------------

  String searchQuery = '';
  List<ReportStudentOption> searchResults = const [];
  bool searchLoading = false;
  String? searchError;
  ReportStudentOption? selectedStudent;

  StudentAttendanceReport? studentReport;
  bool studentReportLoading = false;
  AttendanceLoadError? studentReportError;
  bool studentPdfBusy = false;
  ReportFilters? _studentShown;

  void _clearStudentSearch() {
    _searchToken++;
    searchQuery = '';
    searchResults = const [];
    searchLoading = false;
    searchError = null;
  }

  /// Server-side search (name or EMIS) scoped to the academic year.
  Future<void> searchStudents(String query) async {
    final year = yearId;
    final q = query.trim();
    searchQuery = query;
    final token = ++_searchToken;
    if (year == null || q.isEmpty) {
      searchResults = const [];
      searchLoading = false;
      searchError = null;
      _notify();
      return;
    }
    searchLoading = true;
    searchError = null;
    _notify();
    final result = await _searchFn(year, q);
    if (_disposed || token != _searchToken) return;
    searchLoading = false;
    if (result is StudentSuccess<StudentPage>) {
      searchResults = [
        for (final s in result.data.students)
          ReportStudentOption(
            id: s.id,
            name: s.studentName,
            emisNumber: s.emisNumber.trim().isEmpty ? null : s.emisNumber,
            className: s.classDisplayName == '—' ? null : s.classDisplayName,
          ),
      ];
    } else {
      searchResults = const [];
      searchError = 'Could not search students. Please try again.';
    }
    _notify();
  }

  void selectStudent(ReportStudentOption student) {
    selectedStudent = student;
    _clearStudentSearch();
    _clearReports();
    _notify();
  }

  void clearStudent() {
    selectedStudent = null;
    _clearReports();
    _notify();
  }

  bool get canViewStudentReport =>
      yearId != null && selectedStudent != null && dateError == null;

  Future<void> loadStudentReport() async {
    final year = yearId, student = selectedStudent;
    if (year == null || student == null || dateError != null) return;
    final filters = ReportFilters(
      academicYearId: year,
      studentId: student.id,
      startDate: startYmd,
      endDate: endYmd,
    );
    final token = ++_studentReportToken;
    studentReportLoading = true;
    studentReportError = null;
    _notify();
    final result = await _service.getStudentReport(
      studentId: student.id,
      academicYearId: year,
      startDate: filters.startDate,
      endDate: filters.endDate,
    );
    if (_disposed || token != _studentReportToken) return;
    studentReportLoading = false;
    if (result is AttendanceSuccess<StudentAttendanceReport>) {
      studentReport = result.data;
      _studentShown = filters;
    } else {
      studentReport = null;
      _studentShown = null;
      studentReportError = AttendanceLoadError.from(result as AttendanceError);
    }
    _notify();
  }

  Future<AttendanceResult<PdfFileResult>?> downloadStudentPdf() async {
    final f = _studentShown;
    if (studentPdfBusy || f == null || f.studentId == null) return null;
    studentPdfBusy = true;
    _notify();
    try {
      return await _service.printStudentReport(
        studentId: f.studentId!,
        academicYearId: f.academicYearId,
        startDate: f.startDate,
        endDate: f.endDate,
      );
    } finally {
      studentPdfBusy = false;
      _notify();
    }
  }

  // --- Fallback file names (when Content-Disposition is missing) -----------

  static String _slug(String? v) => (v ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  String get classPdfFallbackFilename {
    final f = _classShown;
    final parts = [
      'class-attendance',
      _slug(classReport?.className ?? selectedClass?.name),
      f?.startDate ?? startYmd,
      f?.endDate ?? endYmd,
    ].where((p) => p.isNotEmpty);
    return '${parts.join('-')}.pdf';
  }

  String get studentPdfFallbackFilename {
    final f = _studentShown;
    final parts = [
      'student-attendance',
      _slug(studentReport?.studentName ?? selectedStudent?.name),
      f?.startDate ?? startYmd,
      f?.endDate ?? endYmd,
    ].where((p) => p.isNotEmpty);
    return '${parts.join('-')}.pdf';
  }
}
