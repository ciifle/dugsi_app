import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext, InheritedWidget;
import 'package:flutter/material.dart' show DateUtils;

import 'package:kobac/models/lesson_attendance.dart';
import 'package:kobac/school_admin/attendance/attendance_reports_controller.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/attendance_diagnostics.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/pdf_file_result.dart';

String attendanceYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class AttendanceLoadError {
  final String message;
  final String? code;
  final int? statusCode;
  const AttendanceLoadError(this.message, {this.code, this.statusCode});

  factory AttendanceLoadError.from(AttendanceError e) =>
      AttendanceLoadError(e.message, code: e.code, statusCode: e.statusCode);
}

/// Outcome of [TakeAttendanceController.save]. `null` from save() means the
/// call was ignored (a save is already running).
class AttendanceSaveOutcome {
  final bool success;
  final String message;
  const AttendanceSaveOutcome.success(this.message) : success = true;
  const AttendanceSaveOutcome.failure(this.message) : success = false;
}

typedef ClassesLoader =
    Future<ClassResult<List<ClassModel>>> Function(int academicYearId);

/// State for School Admin "Take Attendance":
///   Academic Year -> Date -> Class -> Lesson -> Register.
///
/// Changing an upstream selection always invalidates everything below it.
/// Local marks live in one [ValueNotifier] per student so a tap rebuilds only
/// that row; [marksVersion] ticks on every mark change for the save bar and
/// the unsaved-changes guard. Nothing is sent to the backend until [save].
class TakeAttendanceController extends ChangeNotifier {
  TakeAttendanceController({
    AttendanceService? service,
    ClassesLoader? loadClasses,
    DateTime Function()? now,
    AttendanceReportsController? reports,
  }) : _service = service ?? AttendanceService(),
       _loadClassesFn =
           loadClasses ??
           ((id) => ClassesService().listClasses(academicYearId: id)),
       _now = now ?? DateTime.now {
    date = today;
    this.reports =
        reports ??
        AttendanceReportsController(
          service: _service,
          loadClasses: _loadClassesFn,
          now: _now,
        );
  }

  /// Attendance > Reports state; part of the same session so every
  /// platform (and a breakpoint change) sees the same report.
  late final AttendanceReportsController reports;

  final AttendanceService _service;
  final ClassesLoader _loadClassesFn;
  final DateTime Function() _now;
  bool _disposed = false;

  // Tokens discard responses that arrive after their selection changed.
  int _classesToken = 0;
  int _lessonsToken = 0;
  int _registerToken = 0;

  DateTime get today => DateUtils.dateOnly(_now());

  // --- Academic year ------------------------------------------------------
  List<AcademicYear> years = const [];
  int? yearId;

  AcademicYear? get selectedYear {
    for (final y in years) {
      if (y.id == yearId) return y;
    }
    return null;
  }

  // --- Date ---------------------------------------------------------------
  late DateTime date;
  String get dateYmd => attendanceYmd(date);

  /// Latest selectable date: today, or the year's end if it already ended.
  DateTime get lastDate {
    final end = selectedYear?.endDate;
    if (end != null) {
      final e = DateUtils.dateOnly(end);
      if (e.isBefore(today)) return e;
    }
    return today;
  }

  DateTime get firstDate {
    final start = selectedYear?.startDate;
    final first = start == null ? DateTime(2000) : DateUtils.dateOnly(start);
    // A year that has not started yet: keep the picker usable; the backend
    // still rejects the future date with a clear message.
    return first.isAfter(lastDate) ? lastDate : first;
  }

  DateTime _clampDate(DateTime d) {
    final day = DateUtils.dateOnly(d);
    if (day.isAfter(lastDate)) return lastDate;
    if (day.isBefore(firstDate)) return firstDate;
    return day;
  }

  // --- Class --------------------------------------------------------------
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

  // --- Lessons ------------------------------------------------------------
  List<AttendanceLesson> lessons = const [];
  bool lessonsLoading = false;
  bool lessonsLoaded = false;
  AttendanceLoadError? lessonsError;
  String? lessonsDayName;
  int? timetableId;

  AttendanceLesson? get selectedLesson {
    for (final l in lessons) {
      if (l.timetableId == timetableId) return l;
    }
    return null;
  }

  // --- Register -----------------------------------------------------------
  LessonRegister? register;
  bool registerLoading = false;
  AttendanceLoadError? registerError;
  final Map<int, ValueNotifier<String?>> _marks = {};
  final ValueNotifier<int> marksVersion = ValueNotifier<int>(0);

  bool saving = false;
  bool downloadingPdf = false;

  /// Which tab (0 Take, 1 Records, 2 Reports) the Admin last used, so a
  /// breakpoint change reopens the same one.
  int lastView = 0;

  /// Print is offered only once the backend says this lesson has attendance.
  bool get canPrint => register?.attendanceRecorded == true;

  // --- Lifecycle ----------------------------------------------------------

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final n in _marks.values) {
      n.dispose();
    }
    marksVersion.dispose();
    reports.dispose();
    super.dispose();
  }

  /// Supplies the academic years from the shared [AcademicYearsProvider].
  /// Selects the active year (or the first year) when none is selected yet.
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

  // --- Selection (callers confirm unsaved changes first) ------------------

  void selectYear(int id) {
    yearId = id;
    date = _clampDate(date);
    _clearLessons();
    classes = const [];
    _notify();
    loadClasses();
  }

  void selectDate(DateTime value) {
    date = _clampDate(value);
    _clearLessons();
    _notify();
    if (classId != null) loadLessons();
  }

  void selectClass(int? id) {
    classId = id;
    _clearLessons();
    _notify();
    if (id != null) loadLessons();
  }

  void selectLesson(int id) {
    timetableId = id;
    _clearRegister();
    _notify();
    loadRegister();
  }

  void _clearLessons() {
    _lessonsToken++;
    lessons = const [];
    lessonsLoaded = false;
    lessonsLoading = false;
    lessonsError = null;
    lessonsDayName = null;
    timetableId = null;
    _clearRegister();
  }

  void _clearRegister() {
    _registerToken++;
    register = null;
    registerLoading = false;
    registerError = null;
    _resetMarks(const []);
  }

  // --- Loading ------------------------------------------------------------

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
      // Keep the class only if it exists in this year.
      if (classId != null && !classes.any((c) => c.id == classId)) {
        classId = null;
      }
    } else {
      classes = const [];
      classId = null;
      classesError = (result as ClassError).message;
    }
    _notify();
    if (classId != null) loadLessons();
  }

  /// [keepSelection] refreshes recorded/not-taken flags after a save without
  /// dropping the open register.
  Future<void> loadLessons({bool keepSelection = false}) async {
    final year = yearId, cls = classId;
    if (year == null || cls == null) return;
    final token = ++_lessonsToken;
    if (!keepSelection) {
      timetableId = null;
      _clearRegister();
      lessons = const [];
      lessonsLoaded = false;
    }
    lessonsLoading = true;
    lessonsError = null;
    _notify();
    final result = await _service.listLessons(
      academicYearId: year,
      classId: cls,
      date: dateYmd,
    );
    if (_disposed || token != _lessonsToken) return;
    lessonsLoading = false;
    if (result is AttendanceSuccess<AttendanceLessonsResult>) {
      lessons = result.data.lessons;
      lessonsDayName = result.data.dayName;
      lessonsLoaded = true;
      if (timetableId != null &&
          !lessons.any((l) => l.timetableId == timetableId)) {
        timetableId = null;
        _clearRegister();
      }
    } else {
      lessonsError = AttendanceLoadError.from(result as AttendanceError);
      if (!keepSelection) lessons = const [];
    }
    _notify();
  }

  Future<void> loadRegister() async {
    final year = yearId, cls = classId, lesson = timetableId;
    if (year == null || cls == null || lesson == null) return;
    final token = ++_registerToken;
    registerLoading = true;
    registerError = null;
    _notify();
    final selected = selectedLesson;
    attendanceLog('[ADMIN ATTENDANCE] Loading register', {
      'academic_year_id': year,
      'class_id': cls,
      'class_name': selectedClass?.name,
      'date': dateYmd,
      'timetable_id': lesson,
      // Shown so a mix-up with the timetable id is obvious in the log.
      'lesson': selected == null
          ? null
          : '${selected.periodLabel} (period_id ${selected.period?.id}), '
                '${selected.subjectLabel} (subject_id ${selected.subjectId}), '
                '${selected.teacherLabel} (teacher_id ${selected.teacherId})',
    });
    final result = await _service.getRegister(
      academicYearId: year,
      classId: cls,
      date: dateYmd,
      timetableId: lesson,
    );
    if (_disposed || token != _registerToken) return;
    registerLoading = false;
    if (result is AttendanceSuccess<LessonRegister>) {
      _applyRegister(result.data);
      final r = register!;
      attendanceLog('[ADMIN ATTENDANCE] WORKING', {
        'status': 'Register loaded successfully.',
        'Class': r.className ?? selectedClass?.name,
        'Lesson':
            '${r.lesson.periodLabel} · ${r.lesson.subjectLabel} · '
            '${r.lesson.teacherLabel} (timetable_id $lesson)',
        'Date': dateYmd,
        'Students': r.students.length,
        'Existing attendance records': r.existingRecordCount,
        'Unmarked students': r.students.length - r.existingRecordCount,
      });
    } else {
      register = null;
      _resetMarks(const []);
      registerError = AttendanceLoadError.from(result as AttendanceError);
    }
    _notify();
  }

  void _applyRegister(LessonRegister value) {
    final selected = selectedLesson;
    register = value.lesson.timetableId == 0 && selected != null
        ? value.withLesson(selected)
        : value;
    registerError = null;
    _resetMarks(value.students);
  }

  // --- Local marks --------------------------------------------------------

  /// Local marks start from the backend's saved status (PRESENT, ABSENT,
  /// historical LATE, or null = not yet marked). Nothing is defaulted.
  void _resetMarks(List<RegisterStudent> students) {
    final old = _marks.values.toList();
    _marks.clear();
    for (final s in students) {
      _marks[s.studentId] = ValueNotifier<String?>(s.status);
    }
    // Rows built for the previous register may still be listening this frame.
    _disposeLater(old);
    if (!_disposed) marksVersion.value++;
  }

  static final ValueNotifier<String?> _noMark = ValueNotifier<String?>(null);

  ValueListenable<String?> markFor(int studentId) =>
      _marks[studentId] ?? _noMark;

  String? currentMark(int studentId) => _marks[studentId]?.value;

  List<RegisterStudent> get students => register?.students ?? const [];

  void setMark(int studentId, String status) {
    if (saving || !kLessonRegisterStatuses.contains(status)) return;
    final student = _studentById(studentId);
    final mark = _marks[studentId];
    if (student == null || !student.editable || mark == null) return;
    if (mark.value == status) return;
    mark.value = status;
    marksVersion.value++;
  }

  /// Marks every editable student PRESENT locally. Students whose current
  /// value is historical LATE are left alone: changing LATE needs an explicit
  /// per-student choice. Nothing is saved.
  void markAllPresent() {
    if (saving) return;
    var changed = false;
    for (final s in students) {
      final mark = _marks[s.studentId];
      if (!s.editable || mark == null) continue;
      if (mark.value == kStatusLate || mark.value == kStatusPresent) continue;
      mark.value = kStatusPresent;
      changed = true;
    }
    if (changed) marksVersion.value++;
  }

  /// Clears every unsaved mark: students go back to their saved status, so
  /// students without saved attendance become "not marked" again.
  void clearAll() {
    if (saving) return;
    var changed = false;
    for (final s in students) {
      final mark = _marks[s.studentId];
      if (mark == null || mark.value == s.status) continue;
      mark.value = s.status;
      changed = true;
    }
    if (changed) marksVersion.value++;
  }

  RegisterStudent? _studentById(int id) {
    for (final s in students) {
      if (s.studentId == id) return s;
    }
    return null;
  }

  /// Records the PUT will send: only PRESENT/ABSENT values the Admin changed.
  /// Unchanged rows (including historical LATE) and unmarked students are
  /// omitted, which the backend leaves untouched.
  List<RegisterRecord> get pendingRecords {
    final out = <RegisterRecord>[];
    for (final s in students) {
      final local = _marks[s.studentId]?.value;
      if (!s.editable || local == null || local == s.status) continue;
      if (!kLessonRegisterStatuses.contains(local)) continue;
      out.add(RegisterRecord(s.studentId, local));
    }
    return out;
  }

  bool get hasUnsavedChanges => pendingRecords.isNotEmpty;

  /// Enrolled students that will still have no attendance after saving.
  int get unmarkedCount => students
      .where((s) => s.editable && _marks[s.studentId]?.value == null)
      .length;

  // --- Save / PDF ---------------------------------------------------------

  Future<AttendanceSaveOutcome?> save() async {
    if (saving) return null;
    final year = yearId, cls = classId, lesson = timetableId;
    final current = register;
    if (year == null || cls == null || lesson == null || current == null) {
      return const AttendanceSaveOutcome.failure(
        'Select a lesson before taking attendance.',
      );
    }
    final records = pendingRecords;
    if (records.isEmpty) {
      return const AttendanceSaveOutcome.failure(
        'Mark at least one student as Present or Absent before saving.',
      );
    }
    final firstTime = !current.attendanceRecorded;
    saving = true;
    _notify();
    final result = await _service.saveRegister(
      academicYearId: year,
      classId: cls,
      date: dateYmd,
      timetableId: lesson,
      records: records,
    );
    if (_disposed) return null;
    if (result is AttendanceError) {
      saving = false;
      _notify();
      return AttendanceSaveOutcome.failure(result.message);
    }
    final saved = (result as AttendanceSuccess<RegisterSaveResult>).data;
    // The PUT response carries the freshly re-read backend register; fall
    // back to a GET if it is missing.
    if (saved.register != null) {
      _registerToken++;
      _applyRegister(saved.register!);
      saving = false;
      _notify();
    } else {
      saving = false;
      await loadRegister();
    }
    if (_disposed) return null;
    loadLessons(keepSelection: true);
    return AttendanceSaveOutcome.success(
      firstTime
          ? 'Attendance saved successfully.'
          : 'Attendance changes saved successfully.',
    );
  }

  /// Backend-generated register PDF. `null` when a download is already
  /// running or no lesson is open.
  Future<AttendanceResult<PdfFileResult>?> downloadPdf() async {
    final year = yearId, cls = classId, lesson = timetableId;
    if (downloadingPdf || year == null || cls == null || lesson == null) {
      return null;
    }
    downloadingPdf = true;
    _notify();
    try {
      return await _service.printRegister(
        academicYearId: year,
        classId: cls,
        date: dateYmd,
        timetableId: lesson,
      );
    } finally {
      downloadingPdf = false;
      _notify();
    }
  }

  /// Fallback when the response has no Content-Disposition file name.
  String get pdfFallbackFilename {
    final lesson = register?.lesson ?? selectedLesson;
    String slug(String? v) => (v ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final parts = [
      'attendance',
      slug(register?.className ?? selectedClass?.name),
      dateYmd,
      slug(lesson?.subjectName),
    ].where((p) => p.isNotEmpty);
    return '${parts.join('-')}.pdf';
  }
}

/// Session-scoped Attendance state for the School Admin area.
///
/// Provided by `SchoolAdminScreen` ABOVE its mobile/desktop layout switch, so
/// Android, phone-width PWA and desktop PWA all drive the same controller and
/// crossing the breakpoint keeps the selected year/date/class/lesson and
/// unsaved marks. Screens opened outside the scope create their own.
class AttendanceSessionScope extends InheritedWidget {
  final TakeAttendanceController controller;

  const AttendanceSessionScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static TakeAttendanceController? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<AttendanceSessionScope>()
      ?.controller;

  @override
  bool updateShouldNotify(AttendanceSessionScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Disposes replaced mark notifiers after the current frame so rows still
/// subscribed during this rebuild never touch a disposed notifier.
void _disposeLater(List<ValueNotifier<String?>> notifiers) {
  if (notifiers.isEmpty) return;
  Future<void>.delayed(Duration.zero, () {
    for (final n in notifiers) {
      n.dispose();
    }
  });
}
