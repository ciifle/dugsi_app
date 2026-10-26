import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/attendance_diagnostics.dart';
import 'package:kobac/services/attendance_service.dart'
    show AttendanceResult, AttendanceSuccess, AttendanceError;

/// School Admin view of teacher offline attendance submissions.
///
/// Valid new attendance, including late receipts, is accepted by the server
/// without approval and goes straight to the register and reports. Only
/// `pending approval` items need a decision: those queued by the previous
/// backend release (LATE_SERVER_RECEIPT) and unverifiable lesson times.
///
/// Contract (sms-backend docs/attendance-offline-sync.md, Swagger
/// AttendanceSubmissionAudit / AttendanceSyncOutcome):
///  * GET  /api/school-admin/attendance/submissions?status=&after_id=
///      -> {submissions: [audit], next_after_id: int|null}; 100 per page,
///         ascending id, own school only.
///  * POST /api/school-admin/attendance/submissions/{id}/decision
///      body {decision: approve|reject, note?}; note is optional for approve
///      and required (1..1000 chars, trimmed) for reject. The app sends a
///      note only with rejections.
///      -> outcome {submission_id, outcome, reason, decision, ...}
///  * GET/PUT /api/school-admin/attendance/settings {timezone, grace_minutes}
const _base = 'api/school-admin/attendance';

/// Backend `status` values for the `status` query parameter.
abstract final class SubmissionStatus {
  static const pending = 'pending approval';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const conflict = 'conflict';
}

int? _int(Object? v) => v is int ? v : (v is String ? int.tryParse(v) : null);
String? _str(Object? v) {
  final s = v?.toString().trim();
  return s == null || s.isEmpty ? null : s;
}

DateTime? _time(Object? v) => v == null ? null : DateTime.tryParse('$v');
Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

/// One student status inside a submission payload.
class SubmittedMark {
  final int studentId;
  final String status;
  const SubmittedMark(this.studentId, this.status);
}

/// GET .../attendance/submissions item (AttendanceSubmissionAudit).
class AttendanceSubmissionAudit {
  final int id;
  final int? teacherId;
  final int? userId;
  final String status;
  final String? reason;

  /// Device capture claim from the teacher app (untrusted).
  final String? recordedAt;

  /// Server receipt time: what timeliness decisions are based on.
  final DateTime? receivedAt;
  final DateTime? syncedAt;
  final DateTime? decidedAt;
  final int? decidedByUserId;
  final String? decision;
  final String? decisionNote;

  // Canonical payload.
  final int? classId;
  final int? timetableId;
  final int? academicYearId;
  final String? date;
  final List<SubmittedMark> marks;

  // Lesson snapshot (empty for submissions rejected before validation).
  final int? subjectId;
  final String? day;
  final String? startTime;
  final String? endTime;
  final String? shift;

  /// `open` or `late` for accepted receipts (lessonSnapshot.receipt_window).
  final String? receiptWindow;

  const AttendanceSubmissionAudit({
    required this.id,
    required this.status,
    this.teacherId,
    this.userId,
    this.reason,
    this.recordedAt,
    this.receivedAt,
    this.syncedAt,
    this.decidedAt,
    this.decidedByUserId,
    this.decision,
    this.decisionNote,
    this.classId,
    this.timetableId,
    this.academicYearId,
    this.date,
    this.marks = const [],
    this.subjectId,
    this.day,
    this.startTime,
    this.endTime,
    this.shift,
    this.receiptWindow,
  });

  /// Null when the item is not an audit object (no positive id / status).
  static AttendanceSubmissionAudit? tryParse(Object? raw) {
    final j = _map(raw);
    final id = _int(j['id']);
    final status = _str(j['status']);
    if (id == null || id <= 0 || status == null) return null;
    final payload = _map(j['payload']);
    final snap = _map(j['lessonSnapshot'] ?? j['lesson_snapshot']);
    final marks = <SubmittedMark>[
      for (final r in payload['records'] as List? ?? const [])
        if (r is Map &&
            _int(r['student_id']) != null &&
            _str(r['status']) != null)
          SubmittedMark(
            _int(r['student_id'])!,
            _str(r['status'])!.toUpperCase(),
          ),
    ];
    return AttendanceSubmissionAudit(
      id: id,
      status: status,
      teacherId: _int(j['teacherId'] ?? j['teacher_id']),
      userId: _int(j['userId'] ?? j['user_id']),
      reason: _str(j['reason']),
      recordedAt: _str(j['recordedAt'] ?? j['recorded_at']),
      receivedAt: _time(j['receivedAt'] ?? j['received_at']),
      syncedAt: _time(j['syncedAt'] ?? j['synced_at']),
      decidedAt: _time(j['decidedAt'] ?? j['decided_at']),
      decidedByUserId: _int(j['decidedByUserId'] ?? j['decided_by_user_id']),
      decision: _str(j['decision']),
      decisionNote: _str(j['decisionNote'] ?? j['decision_note']),
      classId: _int(payload['class_id']),
      timetableId: _int(payload['timetable_id']),
      academicYearId: _int(payload['academic_year_id']),
      date: _str(payload['date']),
      marks: marks,
      subjectId: _int(snap['subject_id']),
      day: _str(snap['day']),
      startTime: _str(snap['start_time']),
      endTime: _str(snap['end_time']),
      shift: _str(snap['shift']),
      receiptWindow: _str(snap['receipt_window']),
    );
  }

  bool get isPending => status == SubmissionStatus.pending;  int get presentCount => marks.where((m) => m.status == 'PRESENT').length;
  int get absentCount => marks.where((m) => m.status == 'ABSENT').length;

  /// Enough identifiers to load the lesson register for names.
  bool get hasLesson =>
      classId != null &&
      timetableId != null &&
      academicYearId != null &&
      date != null;
}

/// One page of GET .../attendance/submissions.
class SubmissionPage {
  final List<AttendanceSubmissionAudit> items;
  final int? nextAfterId;
  const SubmissionPage(this.items, this.nextAfterId);
}

/// POST .../decision response (AttendanceSyncOutcome).
class DecisionOutcome {
  final int? submissionId;
  final String outcome;
  final String? reason;
  final String? decision;
  const DecisionOutcome({
    required this.outcome,
    this.submissionId,
    this.reason,
    this.decision,
  });

  /// The server recorded the requested decision. A `conflict` (schedule or
  /// enrolment changed, attendance already exists) is NOT a success.
  bool succeededFor(String requested) => requested == 'approve'
      ? (outcome == 'accepted' || outcome == 'already synced') &&
            decision == 'approve'
      : outcome == 'rejected' && decision == 'reject';
}

/// GET/PUT .../attendance/settings.
class AttendancePolicy {
  final String timezone;
  final int graceMinutes;
  const AttendancePolicy({required this.timezone, required this.graceMinutes});

  static const defaults = AttendancePolicy(
    timezone: 'Africa/Mogadishu',
    graceMinutes: 30,
  );

  static AttendancePolicy? tryParse(Object? raw) {
    final j = _map(raw);
    final tz = _str(j['timezone']);
    final grace = _int(j['grace_minutes']);
    if (tz == null || grace == null) return null;
    return AttendancePolicy(timezone: tz, graceMinutes: grace);
  }

  Map<String, Object> toJson() => {
    'timezone': timezone,
    'grace_minutes': graceMinutes,
  };
}

/// Plain-language text for submission reason codes.
String submissionReasonText(String? reason) => switch (reason) {
  null => '',
  'LATE_SERVER_RECEIPT' =>
    'Received by the server after the lesson end + grace period, under the '
        'earlier rules that held late attendance for review. New late '
        'attendance is accepted automatically.',
  'UNVERIFIABLE_SCHEDULE' =>
    'The lesson time could not be verified (e.g. invalid or ambiguous times).',
  'ADMIN_APPROVED' => 'Approved by a School Admin.',
  'ADMIN_REJECTED' => 'Rejected by a School Admin.',
  'ATTENDANCE_ALREADY_RECORDED' =>
    'Attendance for this lesson already exists, so nothing was changed.',
  'SCHEDULE_CHANGED' =>
    'The timetable lesson changed after the teacher submitted.',
  'AUTHORIZATION_OR_ENROLLMENT_CHANGED' =>
    'The teacher assignment or class enrolment changed after submission.',
  'LESSON_NOT_ASSIGNED' =>
    'The teacher is no longer assigned to this class and subject.',
  'STUDENT_NOT_ENROLLED' =>
    'Some students are no longer enrolled in this class.',
  'LESSON_NOT_STARTED' => 'Sent before the lesson started.',
  'LESSON_NOT_FOUND' => 'The timetable lesson no longer exists.',
  'LESSON_DAY_MISMATCH' => 'The date does not match the lesson weekday.',
  'FUTURE_ATTENDANCE_DATE' => 'The date was in the future.',
  'DATE_OUTSIDE_ACADEMIC_YEAR' => 'The date is outside the academic year.',
  'IDEMPOTENCY_KEY_REUSED' =>
    'The device reused a record ID with different data.',
  'IDENTITY_MISMATCH' => 'Submitted under a different teacher identity.',
  'INVALID_LESSON_SCOPE' =>
    'The lesson subject or period does not belong to this school.',
  'INVALID_SUBMISSION' ||
  'VALIDATION_FAILED' => 'The submission was invalid and was not recorded.',
  _ => reason.replaceAll('_', ' ').toLowerCase(),
};

class AttendanceReviewService {
  AttendanceReviewService({ApiClient? client})
    : _client = client ?? ApiClient();
  final ApiClient _client;

  static const _pageSafetyLimit = 50;

  /// One page. [status] must be a [SubmissionStatus] value or null (all).
  Future<AttendanceResult<SubmissionPage>> listPage({
    String? status,
    int? afterId,
    bool quiet = false,
  }) async {
    const op = 'listSubmissions';
    final url = apiUrl('$_base/submissions').replace(
      queryParameters: {
        if (status != null) 'status': status,
        if (afterId != null && afterId > 0) 'after_id': '$afterId',
      },
    );
    final res = await _send(
      op,
      'GET',
      url,
      () => _client.get(url),
      quiet: quiet,
    );
    if (res is! AttendanceSuccess<Object?>) return res as AttendanceError;
    final body = _map(res.data);
    if (body['submissions'] is! List) return _invalid(op, url);
    final items = [
      for (final raw in body['submissions'] as List)
        ?AttendanceSubmissionAudit.tryParse(raw),
    ];
    return AttendanceSuccess(
      SubmissionPage(items, _int(body['next_after_id'])),
    );
  }

  /// Every page for [status] (for the review queue, which must be complete).
  Future<AttendanceResult<List<AttendanceSubmissionAudit>>> listAll({
    String? status,
    bool quiet = false,
  }) async {
    final all = <AttendanceSubmissionAudit>[];
    int? cursor;
    for (var i = 0; i < _pageSafetyLimit; i++) {
      final page = await listPage(
        status: status,
        afterId: cursor,
        quiet: quiet,
      );
      if (page is AttendanceError) return page;
      final data = (page as AttendanceSuccess<SubmissionPage>).data;
      all.addAll(data.items);
      if (data.nextAfterId == null || data.nextAfterId == cursor) break;
      cursor = data.nextAfterId;
    }
    return AttendanceSuccess(all);
  }

  /// Sends `{decision}` plus `note` only when one was entered (rejection
  /// reasons); approvals are sent without a note and no text is ever
  /// invented. An outdated server that demands a note answers 400
  /// ([isNoteRequiredError]).
  Future<AttendanceResult<DecisionOutcome>> decide({
    required int submissionId,
    required String decision,
    String note = '',
  }) async {
    const op = 'decideSubmission';
    assert(decision == 'approve' || decision == 'reject');
    final url = apiUrl('$_base/submissions/$submissionId/decision');
    final trimmed = note.trim();
    final body = <String, Object?>{
      'decision': decision,
      if (trimmed.isNotEmpty) 'note': trimmed,
    };
    final res = await _send(
      op,
      'POST',
      url,
      () => _client.post(url, body: body),
      body: body,
    );
    if (res is! AttendanceSuccess<Object?>) return res as AttendanceError;
    final j = _map(res.data);
    final outcome = _str(j['outcome']);
    if (outcome == null) return _invalid(op, url);
    return AttendanceSuccess(
      DecisionOutcome(
        outcome: outcome,
        submissionId: _int(j['submission_id']),
        reason: _str(j['reason']),
        decision: _str(j['decision']),
      ),
    );
  }

  Future<AttendanceResult<AttendancePolicy>> getPolicy() async {
    const op = 'getAttendancePolicy';
    final url = apiUrl('$_base/settings');
    final res = await _send(op, 'GET', url, () => _client.get(url));
    if (res is! AttendanceSuccess<Object?>) return res as AttendanceError;
    final policy = AttendancePolicy.tryParse(res.data);
    return policy == null ? _invalid(op, url) : AttendanceSuccess(policy);
  }

  Future<AttendanceResult<AttendancePolicy>> setPolicy(
    AttendancePolicy value,
  ) async {
    const op = 'setAttendancePolicy';
    final url = apiUrl('$_base/settings');
    final body = value.toJson();
    final res = await _send(
      op,
      'PUT',
      url,
      () => _client.put(url, body: body),
      body: body,
    );
    if (res is! AttendanceSuccess<Object?>) return res as AttendanceError;
    final policy = AttendancePolicy.tryParse(res.data);
    return policy == null ? _invalid(op, url) : AttendanceSuccess(policy);
  }

  // ---------------------------------------------------------------------------

  Future<AttendanceResult<Object?>> _send(
    String op,
    String method,
    Uri url,
    Future<http.Response> Function() call, {
    Map<String, Object?>? body,
    bool quiet = false,
  }) async {
    // Background badge counts must not spam the error log.
    void log(void Function() write) {
      if (!quiet) write();
    }

    log(() => logAttendanceRequest(op, method, url, body: body));
    final http.Response response;
    try {
      response = await call();
    } catch (e, st) {
      log(
        () => logAttendanceError(
          operation: op,
          endpoint: "$method ${url.path}",
          exception: e,
          stackTrace: st,
        ),
      );
      return AttendanceError(
        method == 'GET'
            ? 'Could not reach the server. Check the connection and try again.'
            : 'Could not reach the server, so the change was not confirmed. '
                  'Refresh to check its current status.',
      );
    }
    log(() => logAttendanceResponse(op, response.statusCode, response.body));
    Object? json;
    try {
      json = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {}
    if (response.statusCode == 200) {
      if (json == null) return _invalid(op, url);
      return AttendanceSuccess(json);
    }
    final map = _map(json);
    final code = _str(map['code']);
    final message = _str(map["message"]);
    log(
      () => logAttendanceError(
        operation: op,
        endpoint: "$method ${url.path}",
        parameters: url.queryParameters,
        status: response.statusCode,
        code: code,
        message: message,
        responseBody: response.body,
      ),
    );
    return AttendanceError(
      reviewErrorMessage(response.statusCode, message, method: method),
      response.statusCode,
      code,
    );
  }

  AttendanceError _invalid(String op, Uri url) {
    logAttendanceError(operation: '$op (parse)', endpoint: url.path);
    return AttendanceError(
      'The server sent an unexpected response. Please try again.',
      200,
      'INVALID_RESPONSE',
    );
  }
}

/// Backends before note-free approval answer an approval without a note with
/// 400 "decision (approve/reject) and note (1..1000 characters) are
/// required". The current backend accepts it; this only recognises an
/// outdated server.
bool isNoteRequiredError(AttendanceError e) =>
    e.statusCode == 400 && e.message.toLowerCase().contains('note');

/// User-facing text for review/settings HTTP failures.
String reviewErrorMessage(
  int status,
  String? backendMessage, {
  String method = 'GET',
}) {
  final text = backendMessage ?? '';
  final safe =
      text.isNotEmpty &&
      text.length <= 200 &&
      !RegExp(
        r'sql|sequelize|stack|<html|er_|\.js',
        caseSensitive: false,
      ).hasMatch(text);
  return switch (status) {
    400 || 422 =>
      safe
          ? text
          : 'The server did not accept this request. Check the values and try again.',
    401 => 'Your session has expired. Please sign in again.',
    403 => 'Only School Admins of this school can review attendance.',
    404 =>
      method == 'GET'
          ? 'Attendance review is not available on this server yet.'
          : 'This submission was not found for your school. It may have been removed.',
    409 =>
      'This submission was already decided differently. The list has been refreshed.',
    429 => 'Too many requests. Wait a moment and try again.',
    >= 500 =>
      'The server could not complete this request. Nothing was changed; please try again.',
    _ => safe ? text : 'Request failed ($status). Please try again.',
  };
}
