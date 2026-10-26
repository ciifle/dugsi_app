import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kobac/models/lesson_attendance.dart';
import 'package:kobac/services/attendance_review_service.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';

/// Result of an approve/reject attempt, for the UI to report.
class ReviewDecisionResult {
  final bool success;
  final String message;

  /// The submission is no longer pending (decided, missing, or conflict):
  /// the detail view should close.
  final bool settled;
  const ReviewDecisionResult(this.success, this.message, {this.settled = true});
}

/// Minimum length of a rejection reason, so the teacher gets an explanation.
const kMinRejectReasonLength = 5;

/// Legacy review: teacher submissions the server still holds as
/// `pending approval`.
///
/// New attendance, on time or late, is accepted by the server without
/// approval, so this is not part of the normal workflow. It only resolves
/// items the previous backend release queued (LATE_SERVER_RECEIPT) and
/// unverifiable lesson times. The Attendance screen shows it only while
/// [pendingCount] > 0.
class AttendanceReviewController extends ChangeNotifier {
  AttendanceReviewController({
    AttendanceReviewService? service,
    AttendanceService? attendance,
    this.onAttendanceChanged,
  }) : _service = service ?? AttendanceReviewService(),
       _attendance = attendance ?? AttendanceService();

  final AttendanceReviewService _service;
  final AttendanceService _attendance;

  /// Called after the server confirms an approval (attendance rows were
  /// created), so open reports reload from the server.
  final VoidCallback? onAttendanceChanged;

  List<AttendanceSubmissionAudit> items = const [];
  bool loading = false;
  String? error;
  int? errorStatus;

  /// Legacy submissions waiting for a decision; null until known.
  int? pendingCount;

  /// Submissions with a decision request in flight (duplicate guard).
  final Set<int> deciding = {};

  final Map<int, String> _teachers = {};
  final Map<int, String> _classes = {};
  final Map<int, String> _subjects = {};
  bool _namesRequested = false;
  int _token = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String teacherName(AttendanceSubmissionAudit a) =>
      _teachers[a.teacherId] ??
      (a.teacherId == null ? 'Unknown teacher' : 'Teacher #${a.teacherId}');
  String className(AttendanceSubmissionAudit a) =>
      _classes[a.classId] ??
      (a.classId == null ? 'Unknown class' : 'Class #${a.classId}');
  String subjectName(AttendanceSubmissionAudit a) =>
      _subjects[a.subjectId] ??
      (a.subjectId == null
          ? 'Subject not recorded'
          : 'Subject #${a.subjectId}');

  /// Reloads every legacy pending submission (oldest first).
  Future<void> load() async {
    final token = ++_token;
    loading = true;
    error = null;
    errorStatus = null;
    items = const [];
    _notify();
    unawaited(_loadNames());
    final res = await _service.listAll(status: SubmissionStatus.pending);
    if (token != _token) return;
    switch (res) {
      case AttendanceSuccess(:final data):
        items = data;
        pendingCount = data.length;
      case AttendanceError(:final message, :final statusCode):
        error = message;
        errorStatus = statusCode;
    }
    loading = false;
    _notify();
  }

  /// Quiet count used to decide whether the Legacy Review tab is shown.
  /// Failures leave the previous value (null hides the tab).
  Future<void> refreshPendingCount() async {
    final res = await _service.listAll(
      status: SubmissionStatus.pending,
      quiet: true,
    );
    if (res is AttendanceSuccess<List<AttendanceSubmissionAudit>>) {
      pendingCount = res.data.length;
      _notify();
    }
  }

  Future<void> _loadNames() async {
    if (_namesRequested) return;
    _namesRequested = true;
    // Names are a convenience; on failure rows fall back to ids.
    final results = await Future.wait([
      TeachersService().listTeachers(),
      ClassesService().listClasses(),
      SubjectsService().listSubjects(),
    ]);
    if (results[0] case TeacherSuccess<List<TeacherModel>>(:final data)) {
      for (final t in data) {
        _teachers[t.id] = t.fullName;
      }
    }
    if (results[1] case ClassSuccess<List<ClassModel>>(:final data)) {
      for (final c in data) {
        _classes[c.id] = c.name;
      }
    }
    if (results[2] case SubjectSuccess<List<SubjectModel>>(:final data)) {
      for (final s in data) {
        _subjects[s.id] = s.name;
      }
    }
    _notify();
  }

  /// Lesson register for names and current attendance (read-only).
  Future<AttendanceResult<LessonRegister>?> loadRegister(
    AttendanceSubmissionAudit a,
  ) async {
    if (!a.hasLesson) return null;
    final res = await _attendance.getRegister(
      academicYearId: a.academicYearId!,
      classId: a.classId!,
      date: a.date!,
      timetableId: a.timetableId!,
    );
    if (res case AttendanceSuccess(:final data)) {
      if (data.className != null) _classes[a.classId!] = data.className!;
      if (data.lesson.subjectName != null && a.subjectId != null) {
        _subjects[a.subjectId!] = data.lesson.subjectName!;
      }
    }
    return res;
  }

  /// Sends one decision for a legacy pending submission. Approvals never
  /// carry a note and need no input; [note] is the rejection reason.
  /// Concurrent calls for the same submission return immediately without a
  /// second request.
  Future<ReviewDecisionResult> decide(
    AttendanceSubmissionAudit a, {
    required bool approve,
    String note = '',
  }) async {
    if (deciding.contains(a.id)) {
      return const ReviewDecisionResult(
        false,
        'A decision for this submission is already being sent.',
        settled: false,
      );
    }
    final trimmed = approve ? '' : note.trim();
    if (trimmed.length > 1000) {
      return const ReviewDecisionResult(
        false,
        'The reason can be at most 1000 characters.',
        settled: false,
      );
    }
    if (!approve && trimmed.length < kMinRejectReasonLength) {
      return const ReviewDecisionResult(
        false,
        'Enter a meaningful rejection reason (at least '
        '$kMinRejectReasonLength characters).',
        settled: false,
      );
    }
    deciding.add(a.id);
    _notify();
    final decision = approve ? 'approve' : 'reject';
    final AttendanceResult<DecisionOutcome> res;
    try {
      res = await _service.decide(
        submissionId: a.id,
        decision: decision,
        note: trimmed,
      );
    } finally {
      deciding.remove(a.id);
      _notify();
    }
    final ReviewDecisionResult result;
    switch (res) {
      case AttendanceSuccess(:final data) when data.succeededFor(decision):
        result = ReviewDecisionResult(
          true,
          approve
              ? 'Approved. The attendance is now in the register.'
              : 'Rejected. No attendance was recorded.',
        );
        if (approve) onAttendanceChanged?.call();
      case AttendanceSuccess(:final data) when data.outcome == 'conflict':
        result = ReviewDecisionResult(
          false,
          'Not approved: ${submissionReasonText(data.reason)} The server '
          'marked it Conflict; nothing was recorded. Use Take Attendance to '
          'correct the register if needed.',
        );
      case AttendanceSuccess(:final data):
        result = ReviewDecisionResult(
          false,
          'The server returned "${data.outcome}" instead of the requested '
          'decision. Refresh to check its status.',
        );
      case AttendanceError e when approve && isNoteRequiredError(e):
        // Outdated server that predates note-free approval.
        result = const ReviewDecisionResult(
          false,
          'The server did not accept the approval. Nothing was changed. '
          'Please ask your system administrator to update the server.',
          settled: false,
        );
      case AttendanceError(:final message, :final statusCode):
        result = ReviewDecisionResult(
          false,
          message,
          // Network/5xx/400: still pending, allow another attempt.
          settled: statusCode == 404 || statusCode == 409,
        );
    }
    if (result.settled && errorStatus != 401) await load();
    return result;
  }

  // --- Attendance policy -----------------------------------------------------

  Future<AttendanceResult<AttendancePolicy>> loadPolicy() =>
      _service.getPolicy();

  Future<AttendanceResult<AttendancePolicy>> savePolicy(
    AttendancePolicy value,
  ) => _service.setPolicy(value);
}
