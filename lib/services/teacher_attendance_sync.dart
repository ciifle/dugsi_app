import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Statuses accepted by POST /api/teacher/attendance/sync. The backend
/// contract (attendance-offline-sync.md) allows PRESENT and ABSENT only.
const attendanceStatuses = ['PRESENT', 'ABSENT'];

/// Local lifecycle of one queued submission; [label] is shown to teachers.
///
/// New attendance (including late) is accepted by the server without
/// approval. [adminReview] only holds what the server still reports as
/// `pending approval`: submissions queued for review by the previous backend
/// release (LATE_SERVER_RECEIPT) and unverifiable lesson times.
enum SubmissionState {
  savedOffline('Saved Offline'),
  pendingSync('Pending Sync'),
  syncing('Syncing'),
  synced('Synchronized'),
  adminReview('Pending Review'),
  failed('Sync Failed');

  const SubmissionState(this.label);
  final String label;

  static SubmissionState parse(Object? value) {
    for (final s in values) {
      if (s.name == value || s.label == value) return s;
    }
    // Legacy labels from earlier offline builds.
    if (value == 'Synced') return synced;
    if (value == 'Pending Admin Approval' ||
        value == 'Requires Admin Review') {
      return adminReview;
    }
    if (value == 'Conflict') return failed;
    return pendingSync;
  }
}

/// Result of the most recent contact with the API. Drives the banner.
enum SyncHealth {
  unknown,
  online,
  offline,
  authRequired,
  accessDenied,
  serverError,

  /// HTTP 404: the server reached does not provide the route (e.g. an older
  /// backend deployment). Records were not seen by the server; keep them.
  endpointMissing,
}

/// Thrown for conditions the UI shows as a message (never as "Bad state").
class AttendanceSyncException implements Exception {
  const AttendanceSyncException(this.message, [this.health, this.statusCode]);
  final String message;
  final SyncHealth? health;
  final int? statusCode;
  @override
  String toString() => message;
}

/// Mirrors the POST /attendance/sync item validation so the app never sends
/// a payload the server can only reject. Returns readable problems.
List<String> contractProblems(Map<String, dynamic> payload) {
  final problems = <String>[];
  bool positive(Object? v) => v is int && v > 0;
  if (!RegExp(
    r'^[A-Za-z0-9_-]{16,100}$',
  ).hasMatch('${payload['idempotency_key']}')) {
    problems.add('invalid record ID');
  }
  final recorded = payload['recorded_at'];
  if (recorded != null &&
      !(recorded is String &&
          recorded.length <= 40 &&
          RegExp(
            r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,3})?(?:Z|[+-]\d\d:\d\d)$',
          ).hasMatch(recorded))) {
    problems.add('capture time in an unsupported format');
  }
  for (final field in ['class_id', 'timetable_id', 'academic_year_id']) {
    if (!positive(payload[field])) problems.add('missing $field');
  }
  if (!RegExp(r'^\d{4}-\d\d-\d\d$').hasMatch('${payload['date']}')) {
    problems.add('invalid date');
  }
  final records = payload['records'];
  if (records is! List || records.isEmpty || records.length > 1000) {
    problems.add('no student marks');
  } else {
    final ids = <Object?>{};
    for (final r in records) {
      if (r is! Map ||
          !positive(r['student_id']) ||
          !ids.add(r['student_id'])) {
        problems.add('invalid or repeated student');
        break;
      }
    }
    if (records.any(
      (r) => r is Map && !attendanceStatuses.contains(r['status']),
    )) {
      problems.add('a status other than Present/Absent (e.g. Late)');
    }
  }
  return problems;
}

/// One immutable submission plus its mutable local sync metadata.
class AttendanceSubmission {
  AttendanceSubmission({
    required this.payload,
    required this.lessonKey,
    required this.label,
    required this.capturedAt,
    this.state = SubmissionState.savedOffline,
    this.outcome,
    this.reason,
    this.detail,
    this.decisionNote,
    this.submissionId,
    this.receivedAt,
    this.syncedAt,
    this.attempts = 0,
    this.legacy = false,
    this.replacedBy,
  });

  /// Exactly what is sent; never changed after the first local save.
  final Map<String, dynamic> payload;
  final String lessonKey;
  final String label;

  /// Device clock at capture. Not proof of timeliness; the server decides.
  final DateTime capturedAt;
  SubmissionState state;

  /// Last server outcome (accepted, pending approval, rejected, conflict...).
  String? outcome;

  /// Server reason code (e.g. LESSON_NOT_STARTED) or a local failure message.
  String? reason;

  /// Server's free-text message accompanying a rejection.
  String? detail;
  String? decisionNote;
  int? submissionId;

  /// Server receipt time reported by the API.
  DateTime? receivedAt;
  DateTime? syncedAt;
  int attempts;

  /// Saved by an app version before the v2 record format.
  final bool legacy;

  /// Key of the corrected copy that superseded this record, if any.
  String? replacedBy;

  String get key => payload['idempotency_key'] as String;
  String get date => '${payload['date']}';

  List<String> get problems => contractProblems(payload);

  /// Never sent: either it can't satisfy the contract or it was superseded.
  bool get sendable => replacedBy == null && problems.isEmpty;

  /// Status shown to teachers. Server rejections and conflicts are told
  /// apart; other failures (request refused, unsendable) stay "Sync Failed".
  String get statusLabel {
    if (replacedBy != null) return 'Replaced';
    if (state == SubmissionState.failed) {
      if (outcome == 'rejected') return 'Rejected';
      if (outcome == 'conflict') return 'Conflict';
    }
    return state.label;
  }

  /// Rejected or conflicting on the server; retrying the same key cannot help.
  bool get serverFinal =>
      state == SubmissionState.failed &&
      (outcome == 'rejected' || outcome == 'conflict');

  /// Whether this record stops the same lesson being saved again. A server
  /// rejection created no attendance, and unsendable/replaced records are
  /// never sent, so none of those block.
  bool get blocksLesson =>
      outcome != 'rejected' && replacedBy == null && problems.isEmpty;

  /// Takes the stored sync metadata (possibly written by another tab).
  void absorb(AttendanceSubmission other) {
    state = other.state;
    outcome = other.outcome;
    reason = other.reason;
    detail = other.detail;
    decisionNote = other.decisionNote;
    submissionId = other.submissionId;
    receivedAt = other.receivedAt;
    syncedAt = other.syncedAt;
    attempts = other.attempts;
    replacedBy = other.replacedBy;
  }

  Map<String, dynamic> toJson() => {
    'v': 2,
    'legacy': legacy,
    'lesson': lessonKey,
    'label': label,
    'captured_at': capturedAt.toIso8601String(),
    'state': state.name,
    'outcome': outcome,
    'reason': reason,
    'detail': detail,
    'decision_note': decisionNote,
    'submission_id': submissionId,
    'received_at': receivedAt?.toIso8601String(),
    'synced_at': syncedAt?.toIso8601String(),
    'attempts': attempts,
    'replaced_by': replacedBy,
    'payload': payload,
  };

  factory AttendanceSubmission.fromJson(Map<String, dynamic> json) {
    final payload = Map<String, dynamic>.from(json['payload'] as Map);
    var state = SubmissionState.parse(json['state'] ?? json['status']);
    String? outcome = json['outcome'] as String?;
    if (outcome == null && json['terminal'] == true) {
      outcome = json['status'] == 'Conflict' ? 'conflict' : 'rejected';
    }
    // A process killed mid-request leaves "syncing"; it was never confirmed.
    if (state == SubmissionState.syncing) state = SubmissionState.pendingSync;
    var reason = json['reason']?.toString();
    final entry = AttendanceSubmission(
      payload: payload,
      lessonKey: json['lesson'] as String,
      label: json['label'] as String? ?? 'Class ${payload['class_id']}',
      capturedAt:
          DateTime.tryParse(
            '${json['captured_at'] ?? payload['recorded_at']}',
          ) ??
          DateTime.now().toUtc(),
      state: state,
      outcome: outcome,
      reason: reason,
      detail: json['detail']?.toString(),
      decisionNote: json['decision_note']?.toString(),
      submissionId: json['submission_id'] as int?,
      receivedAt: DateTime.tryParse('${json['received_at']}'),
      syncedAt: DateTime.tryParse('${json['synced_at']}'),
      attempts: json['attempts'] as int? ?? 0,
      legacy: json['v'] == null || json['legacy'] == true,
      replacedBy: json['replaced_by'] as String?,
    );
    // Unsendable queued records are held for the teacher, never auto-sent
    // and never deleted.
    if (entry.problems.isNotEmpty &&
        (state == SubmissionState.savedOffline ||
            state == SubmissionState.pendingSync)) {
      entry
        ..state = SubmissionState.failed
        ..outcome = null
        ..reason = 'LEGACY_FORMAT';
    }
    return entry;
  }
}

/// Advisory estimate of where "now" falls relative to a lesson.
enum LessonTiming { early, open, late, unknown }

/// Fixed-offset (no daylight saving) zones the app can evaluate without a
/// timezone database. Others yield [LessonTiming.unknown].
const _fixedOffsets = {
  'Africa/Mogadishu': 180,
  'Africa/Nairobi': 180,
  'Africa/Addis_Ababa': 180,
  'Africa/Djibouti': 180,
  'Africa/Asmara': 180,
  'Africa/Dar_es_Salaam': 180,
  'Africa/Kampala': 180,
  'Indian/Comoro': 180,
  'Asia/Aden': 180,
  'Asia/Riyadh': 180,
  'Asia/Qatar': 180,
  'Asia/Kuwait': 180,
  'Asia/Bahrain': 180,
  'Asia/Dubai': 240,
  'Asia/Muscat': 240,
  'UTC': 0,
  'Etc/UTC': 0,
};

/// Plain-language explanation of a record's state for teachers.
String describeSubmission(AttendanceSubmission e) {
  if (e.replacedBy != null) {
    return 'Replaced by a corrected copy (same marks). This one was never '
        'recorded on the server.';
  }
  if (e.reason == 'LEGACY_FORMAT') {
    final fixable = e.problems.every((p) => p.startsWith('capture time'));
    return 'Saved by an earlier app version with ${e.problems.join(', ')}, '
        'which the server cannot accept. It has not been sent. '
        '${fixable ? 'Tap Resubmit to send a corrected copy with the same marks.' : 'Remove it and take attendance for this lesson again.'}';
  }
  final note = e.decisionNote?.trim();
  final text = switch (e.reason) {
    null => null,
    'LATE_SERVER_RECEIPT' =>
      'Sent under the earlier rules, which held late attendance for School '
          'Admin review. It stays pending until a School Admin decides. New '
          'attendance no longer needs approval.',
    'UNVERIFIABLE_SCHEDULE' =>
      'The server could not verify the lesson time, so a School Admin must review it.',
    'ADMIN_APPROVED' => 'Approved by School Admin.',
    'ADMIN_REJECTED' =>
      'Rejected by School Admin. Nothing was recorded for this lesson.',
    'LESSON_NOT_STARTED' =>
      'The server received this before the lesson started, so it was not '
          'recorded. After the lesson starts, tap Resubmit to send the same marks.',
    'ATTENDANCE_ALREADY_RECORDED' =>
      'Attendance for this lesson was already recorded (by you, another '
          'device or a School Admin). Nothing was changed.',
    'IDEMPOTENCY_KEY_REUSED' =>
      'The server holds a different record with the same ID. Nothing was '
          'changed; contact your School Admin.',
    'STUDENT_NOT_ENROLLED' =>
      'Some students are no longer enrolled in this class. Tap Sync Now to '
          'refresh the class list, then take attendance again.',
    'LESSON_DAY_MISMATCH' =>
      'The date does not fall on this lesson\'s weekday. Take attendance again with the correct date.',
    'FUTURE_ATTENDANCE_DATE' =>
      'The date is in the future by the school\'s calendar.',
    'DATE_OUTSIDE_ACADEMIC_YEAR' =>
      'The date is outside the current academic year.',
    'LESSON_NOT_FOUND' =>
      'This lesson is no longer in the timetable. Tap Sync Now to refresh.',
    'LESSON_NOT_ASSIGNED' =>
      'You are no longer assigned to this lesson. Contact your School Admin.',
    'INVALID_LESSON_SCOPE' =>
      'The lesson\'s subject or period is not set up for your school. Contact your School Admin.',
    'IDENTITY_MISMATCH' =>
      'This record belongs to a different teacher account and was not recorded.',
    'SCHEDULE_CHANGED' =>
      'The timetable changed before approval, so nothing was recorded. Contact your School Admin.',
    'AUTHORIZATION_OR_ENROLLMENT_CHANGED' =>
      'Your assignment or the class list changed before approval, so nothing was recorded.',
    'INVALID_SUBMISSION' || 'VALIDATION_FAILED' =>
      'The server could not accept this record'
          '${e.detail == null || e.detail!.isEmpty ? '.' : ': ${e.detail}.'}',
    _ =>
      RegExp(r'^[A-Z_]+$').hasMatch(e.reason!)
          ? 'Not recorded (${e.reason!.toLowerCase().replaceAll('_', ' ')})'
                '${e.detail == null ? '' : ': ${e.detail}'}.'
          : e.reason,
  };
  if (note != null && note.isNotEmpty) {
    return '${text ?? ''} Admin note: "$note"'.trim();
  }
  return text ??
      (e.outcome == 'conflict' ? 'Conflicts with existing attendance.' : '');
}

/// Offline-first attendance for one teacher account (school + user).
///
/// Everything is stored in SharedPreferences (SharedPreferences on Android,
/// localStorage on mobile/desktop PWA) under a prefix scoped to the owner, so
/// one teacher's cache and queue are never visible to another account. Each
/// submission has its own key, so concurrent tabs cannot overwrite each other.
class TeacherAttendanceSync extends ChangeNotifier with WidgetsBindingObserver {
  static Future<TeacherAttendanceSync>? _active;
  static String? _activeOwner;

  /// The worker for the signed-in teacher, or null when none is signed in.
  static Future<TeacherAttendanceSync>? get current => _active;

  static Future<TeacherAttendanceSync> forTeacher({
    required int schoolId,
    required int userId,
    required String? Function() token,
  }) {
    final owner = ownerKey(schoolId, userId);
    if (_activeOwner == owner && _active != null) return _active!;
    final previous = _active;
    _activeOwner = owner;
    _active = () async {
      if (previous != null) {
        try {
          (await previous).dispose();
        } catch (_) {}
      }
      final sync = TeacherAttendanceSync(
        schoolId: schoolId,
        userId: userId,
        token: token,
      );
      await sync.initialize();
      return sync;
    }();
    return _active!;
  }

  static void stopWorker() {
    final old = _active;
    _active = null;
    _activeOwner = null;
    if (old != null) {
      unawaited(old.then((value) => value.dispose(), onError: (_) {}));
    }
  }

  /// On explicit logout: remove the downloaded schedule and rosters (shared
  /// devices) but keep every queued submission until the server confirms it.
  static Future<void> clearDownloadedData(int schoolId, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${_prefixFor(ownerKey(schoolId, userId))}cache_';
    for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await prefs.remove(key);
    }
  }

  static String ownerKey(int schoolId, int userId) => '${schoolId}_$userId';
  static String _prefixFor(String owner) => 'teacher_attendance_v1_${owner}_';
  static final String _tabId = _randomHex(8);
  static String _randomHex(int bytes) {
    final random = Random.secure();
    return List.generate(
      bytes,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  TeacherAttendanceSync({
    required this.schoolId,
    required this.userId,
    required this.token,
    http.Client? client,
    Stream<Object?>? connectivityChanges,
    DateTime Function()? clock,
  }) : client = client ?? http.Client(),
       _connectivityChanges = connectivityChanges,
       _now = clock ?? DateTime.now;

  final int schoolId;
  final int userId;
  final String? Function() token;
  final http.Client client;
  final Stream<Object?>? _connectivityChanges;
  final DateTime Function() _now;

  late SharedPreferences prefs;
  final List<AttendanceSubmission> entries = [];
  Map<String, dynamic>? dashboard;
  Map<String, dynamic>? settings;
  DateTime? cachedAt;
  SyncHealth health = SyncHealth.unknown;

  /// Human-readable detail for [health]; never raw exception text.
  String? message;

  bool _closed = false;
  bool _automatic = false;
  Future<void>? _running;
  bool _rerun = false;
  int _failures = 0;
  DateTime? _nextAutoAttempt;
  DateTime? _lastDecisionPoll;
  String? _rejectedToken;
  Timer? _timer;
  StreamSubscription<Object?>? _connectivity;

  static const _requestTimeout = Duration(seconds: 20);
  static const _staleAfter = Duration(minutes: 10);
  static const _decisionPollEvery = Duration(minutes: 5);
  static const _leaseFor = Duration(seconds: 60);
  static const _keepSyncedFor = Duration(days: 30);

  String get owner => ownerKey(schoolId, userId);
  String get prefix => _prefixFor(owner);
  bool get busy => _running != null;
  bool get hasSchedule => dashboard != null;

  /// Failed records not yet replaced: the teacher must act on these.
  int get attentionCount => entries
      .where((e) => e.state == SubmissionState.failed && e.replacedBy == null)
      .length;

  int get pendingCount => entries
      .where(
        (e) =>
            e.state == SubmissionState.savedOffline ||
            e.state == SubmissionState.pendingSync ||
            e.state == SubmissionState.syncing,
      )
      .length;

  Future<void> initialize({bool automatic = true}) async {
    prefs = await SharedPreferences.getInstance();
    _loadCache();
    await reload();
    _automatic = automatic;
    if (!automatic) return;
    WidgetsBinding.instance.addObserver(this);
    try {
      _connectivity =
          (_connectivityChanges ?? Connectivity().onConnectivityChanged).listen(
            (result) {
              // Only a hint: the API request itself decides reachability.
              if (result is List && result.contains(ConnectivityResult.none)) {
                return;
              }
              wake();
            },
            onError: (_) {},
          );
    } catch (_) {}
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => sync());
    unawaited(sync());
  }

  /// Connectivity returned, the app resumed or the session changed.
  void wake() {
    _nextAutoAttempt = null;
    unawaited(sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) wake();
  }

  void _changed() {
    if (!_closed) notifyListeners();
  }

  // ---------------------------------------------------------------- cache

  Map<String, dynamic>? _read(String key) {
    final raw = prefs.getString('${prefix}cache_$key');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Map<String, dynamic> value) async {
    if (_closed) return; // signed out while a download was in flight
    await _setString('${prefix}cache_$key', jsonEncode(value));
  }

  Future<void> _setString(String key, String value) async {
    bool ok;
    try {
      ok = await prefs.setString(key, value);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      throw const AttendanceSyncException(
        'This device could not store attendance (storage full or blocked, '
        'e.g. private browsing). Nothing was sent.',
      );
    }
  }

  void _loadCache() {
    final snapshot = _read('snapshot');
    dashboard = snapshot?['dashboard'] == null
        ? null
        : Map<String, dynamic>.from(snapshot!['dashboard'] as Map);
    settings = snapshot?['settings'] == null
        ? null
        : Map<String, dynamic>.from(snapshot!['settings'] as Map);
    cachedAt = DateTime.tryParse('${snapshot?['saved_at']}');
  }

  dynamic get academicYearId => dashboard?['academicYear']?['id'];

  /// Classes the server listed as assigned in the last downloaded dashboard.
  Set<int> get assignedClassIds {
    final ids = <int>{};
    for (final c in dashboard?['assignedClasses'] as List? ?? const []) {
      final id = c is Map ? c['id'] : null;
      if (id is int && id > 0) ids.add(id);
    }
    for (final a in dashboard?['assignments'] as List? ?? const []) {
      if (a is! Map) continue;
      final id = a['classId'] ?? a['class_id'] ?? a['class']?['id'];
      if (id is int && id > 0) ids.add(id);
    }
    return ids;
  }

  List<Map<String, dynamic>> get lessons => [
    for (final t in dashboard?['timetables'] as List? ?? const [])
      if (t is Map) Map<String, dynamic>.from(t),
  ];

  static int? lessonClassId(Map lesson) =>
      (lesson['classId'] ?? lesson['class_id'] ?? lesson['class']?['id'])
          as int?;

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static String weekdayCode(DateTime date) => _weekdays[date.weekday - 1];

  /// Cached scheduled lessons for [classId] that fall on [date]'s weekday.
  List<Map<String, dynamic>> lessonsFor(int classId, DateTime date) {
    final day = weekdayCode(date);
    return lessons
        .where(
          (l) =>
              lessonClassId(l) == classId &&
              '${l['day']}'.toUpperCase().startsWith(day),
        )
        .toList();
  }

  /// Cached enrolled students, or null if the roster was never downloaded.
  List<Map<String, dynamic>>? rosterFor(int classId) {
    if (!assignedClassIds.contains(classId)) return null;
    final cached = _read('roster_${academicYearId}_$classId');
    final students = cached?['students'];
    if (students is! List) return null;
    return [
      for (final s in students)
        if (s is Map) Map<String, dynamic>.from(s),
    ];
  }

  /// Downloads dashboard, policy and every assigned roster. On failure the
  /// previous cache stays usable.
  Future<void> refreshCache() async {
    final raw = await _request('GET', 'dashboard');
    final data = Map<String, dynamic>.from((raw['data'] ?? raw) as Map);
    final teacherSchool = data['teacher'] is Map
        ? data['teacher']['schoolId']
        : null;
    if (teacherSchool != null && '$teacherSchool' != '$schoolId') {
      throw const AttendanceSyncException(
        'The server returned a schedule for a different school. Sign in again.',
        SyncHealth.accessDenied,
      );
    }
    final year = data['academicYear'] is Map
        ? data['academicYear']['id']
        : null;
    if (year == null) {
      throw const AttendanceSyncException(
        'The school has no active academic year. Contact your School Admin.',
      );
    }
    Map<String, dynamic>? policy = settings;
    try {
      policy = await _request('GET', settingsEndpoint);
    } on AttendanceSyncException catch (e) {
      // Policy is informational; a missing endpoint must not block rosters.
      if (e.health != null &&
          e.health != SyncHealth.serverError &&
          e.health != SyncHealth.endpointMissing) {
        rethrow;
      }
    }

    final previousYear = academicYearId;
    final saved = _now().toUtc();
    await _write('snapshot', {
      'saved_at': saved.toIso8601String(),
      'dashboard': data,
      'settings': policy,
    });
    dashboard = data;
    settings = policy;
    cachedAt = saved;
    final assigned = assignedClassIds;
    // Drop rosters for classes or years no longer assigned.
    for (final key in prefs.getKeys().toList()) {
      final match = RegExp(
        '^${RegExp.escape(prefix)}cache_roster_(.+)_(\\d+)\$',
      ).firstMatch(key);
      if (match == null) continue;
      if (match[1] != '$year' ||
          !assigned.contains(int.parse(match[2]!)) ||
          previousYear != year) {
        await prefs.remove(key);
      }
    }
    _changed();
    for (final classId in assigned) {
      try {
        final roster = await _request(
          'GET',
          'classes/$classId/students?academic_year_id=$year',
        );
        await _write('roster_${year}_$classId', {
          'students': roster['students'] ?? const [],
          'saved_at': saved.toIso8601String(),
        });
      } on AttendanceSyncException catch (e) {
        if (e.statusCode == 403 || e.statusCode == 404) {
          await prefs.remove('${prefix}cache_roster_${year}_$classId');
          continue;
        }
        rethrow;
      }
      _changed();
    }
  }

  // ---------------------------------------------------------------- queue

  List<AttendanceSubmission> _stored() {
    final loaded = <AttendanceSubmission>[];
    for (final key in prefs.getKeys().where(
      (k) => k.startsWith('${prefix}entry_'),
    )) {
      try {
        loaded.add(
          AttendanceSubmission.fromJson(
            Map<String, dynamic>.from(jsonDecode(prefs.getString(key)!) as Map),
          ),
        );
      } catch (_) {}
    }
    return loaded;
  }

  /// Re-reads the queue from storage (picks up other tabs' saves). Not called
  /// while a run is active, so in-flight objects are never replaced.
  Future<void> reload() async {
    try {
      await prefs.reload();
    } catch (_) {}
    // Keep object identity per key so held references stay current.
    final known = {for (final e in entries) e.key: e};
    final loaded = <AttendanceSubmission>[];
    for (final fresh in _stored()) {
      final mine = known[fresh.key];
      loaded.add(mine == null ? fresh : (mine..absorb(fresh)));
    }
    loaded.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    entries
      ..clear()
      ..addAll(loaded);
    _changed();
  }

  Future<void> _persist(AttendanceSubmission entry) async {
    await _setString('${prefix}entry_${entry.key}', jsonEncode(entry.toJson()));
    _changed();
  }

  /// Validates against the cached schedule/roster and stores the submission
  /// on the device before anything is sent.
  Future<AttendanceSubmission> save({
    required int lessonId,
    required DateTime date,
    required List<Map<String, dynamic>> records,
  }) async {
    if (dashboard == null) {
      throw const AttendanceSyncException(
        'Your lesson schedule is not on this device yet. Connect to the '
        'internet and tap Sync Now to download it.',
      );
    }
    final lesson = lessons.where((l) => l['id'] == lessonId).firstOrNull;
    final classId = lesson == null ? null : lessonClassId(lesson);
    if (lesson == null ||
        classId == null ||
        !assignedClassIds.contains(classId)) {
      throw const AttendanceSyncException(
        'This lesson is not in your downloaded schedule. Sync Now to refresh it.',
      );
    }
    final day = DateTime(date.year, date.month, date.day);
    final today = _now();
    if (day.isAfter(DateTime(today.year, today.month, today.day))) {
      throw const AttendanceSyncException(
        'Attendance cannot be saved for a future date.',
      );
    }
    if (!'${lesson['day']}'.toUpperCase().startsWith(weekdayCode(day))) {
      throw AttendanceSyncException(
        'This lesson is scheduled on ${lesson['day']}. Choose a matching date.',
      );
    }
    // Attendance is for lessons that have begun. Late saves (after the end
    // and grace period) are allowed; the server decides how to file them.
    if (lessonTiming(lesson, day).timing == LessonTiming.early) {
      throw const AttendanceSyncException(
        'This lesson has not started yet. Attendance can be saved once it '
        'begins.',
      );
    }
    final roster = rosterFor(classId);
    if (roster == null) {
      throw const AttendanceSyncException(
        'The student list for this class is not on this device. Connect and '
        'tap Sync Now.',
      );
    }
    final enrolled = roster.map((s) => s['id']).toSet();
    final ids = records.map((r) => r['student_id']).toSet();
    if (records.isEmpty ||
        records.length > 1000 ||
        ids.length != records.length ||
        !enrolled.containsAll(ids) ||
        records.any((r) => !attendanceStatuses.contains(r['status']))) {
      throw const AttendanceSyncException(
        'Mark Present or Absent for each enrolled student (up to 1000).',
      );
    }
    final dateText =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final start = lesson['startTime'] ?? lesson['start_time'];
    final subject =
        lesson['subjectId'] ?? lesson['subject_id'] ?? lesson['subject']?['id'];
    // Server lesson key: school, class, date, start time, subject.
    final logical = '$classId|$dateText|$start|$subject';
    try {
      await prefs.reload();
    } catch (_) {}
    // A server rejection created no attendance, so a corrected save is allowed;
    // anything else (queued, accepted, under review, conflict) blocks a copy.
    final existing = [
      ...entries,
      ..._stored(),
    ].where((e) => e.lessonKey == logical && e.blocksLesson);
    if (existing.isNotEmpty) {
      throw AttendanceSyncException(
        'Attendance for this lesson is already saved '
        '(${existing.first.state.label}). It cannot be saved twice.',
      );
    }
    final teacher = dashboard!['teacher'];
    // The API accepts at most millisecond precision; native Dart prints
    // microseconds, which the server would reject.
    final now = DateTime.fromMillisecondsSinceEpoch(
      _now().millisecondsSinceEpoch,
      isUtc: true,
    );
    final entry = AttendanceSubmission(
      lessonKey: logical,
      label:
          '${lesson['subjectName'] ?? lesson['subject']?['name'] ?? 'Lesson'} · '
          '${lesson['className'] ?? lesson['class']?['name'] ?? 'Class $classId'} · '
          '$start',
      capturedAt: now,
      payload: {
        'idempotency_key': _randomHex(24),
        'school_id': schoolId,
        if (teacher is Map && teacher['id'] is int) 'teacher_id': teacher['id'],
        'academic_year_id': academicYearId,
        'class_id': classId,
        'timetable_id': lessonId,
        'date': dateText,
        'recorded_at': now.toIso8601String(),
        'records': [
          for (final r in records)
            {'student_id': r['student_id'], 'status': r['status']},
        ],
      },
    );
    await _persist(entry); // Must complete before any network request.
    entries.insert(0, entry);
    _changed();
    if (_automatic) wake();
    return entry;
  }

  /// Removes a failed submission after the teacher has acknowledged it.
  Future<void> dismiss(AttendanceSubmission entry) async {
    if (entry.state != SubmissionState.failed) return;
    await prefs.remove('${prefix}entry_${entry.key}');
    entries.remove(entry);
    _changed();
  }

  /// Server rejections a corrected copy (new key, same marks) can fix. Any
  /// other rejection needs new attendance or a School Admin.
  static const _resubmittable = {
    'LESSON_NOT_STARTED',
    'INVALID_SUBMISSION',
    'VALIDATION_FAILED',
  };

  Map<String, dynamic> _correctedPayload(AttendanceSubmission e, String key) {
    final teacher = dashboard?['teacher'];
    return {
      ...e.payload,
      'idempotency_key': key,
      'school_id': e.payload['school_id'] ?? schoolId,
      if (e.payload['teacher_id'] == null &&
          teacher is Map &&
          teacher['id'] is int)
        'teacher_id': teacher['id'],
      // Original capture time, at the precision the server accepts.
      'recorded_at': _millis(e.capturedAt).toIso8601String(),
      'records': [
        for (final r in e.payload['records'] as List? ?? const [])
          if (r is Map) {'student_id': r['student_id'], 'status': r['status']},
      ],
    };
  }

  /// Whether [e] can be replaced by a corrected copy without risking a
  /// duplicate: it was never recorded, the copy would be valid, and nothing
  /// else on this device covers the same lesson.
  bool canResubmit(AttendanceSubmission e) {
    if (e.replacedBy != null || e.state != SubmissionState.failed) return false;
    final eligible = e.reason == 'LEGACY_FORMAT'
        ? e.outcome == null
        : e.outcome == 'rejected' && _resubmittable.contains(e.reason);
    if (!eligible) return false;
    if (contractProblems(_correctedPayload(e, 'x' * 16)).isNotEmpty) {
      return false;
    }
    return !entries.any(
      (o) => !identical(o, e) && o.lessonKey == e.lessonKey && o.blocksLesson,
    );
  }

  /// Creates the corrected copy and marks [e] as replaced (kept, not deleted).
  Future<AttendanceSubmission> resubmit(AttendanceSubmission e) async {
    await reload(); // another tab may have resubmitted already
    if (!canResubmit(e)) {
      throw const AttendanceSyncException(
        'This record cannot be resubmitted: attendance for the lesson is '
        'already saved on this device or the server must decide.',
      );
    }
    final copy = AttendanceSubmission(
      payload: _correctedPayload(e, _randomHex(24)),
      lessonKey: e.lessonKey,
      label: e.label,
      capturedAt: e.capturedAt,
    );
    await _persist(copy); // copy first: a crash here leaves both, not neither
    e.replacedBy = copy.key;
    await _persist(e);
    entries.insert(0, copy);
    _changed();
    if (_automatic) wake();
    return copy;
  }

  static DateTime _millis(DateTime t) => DateTime.fromMillisecondsSinceEpoch(
    t.millisecondsSinceEpoch,
    isUtc: true,
  );

  /// Estimate of [lesson] timing on [date] in the school timezone, using this
  /// device's clock. Only [LessonTiming.early] blocks saving; the server
  /// decides everything else with its own receipt time.
  ({LessonTiming timing, String? message}) lessonTiming(
    Map lesson,
    DateTime date,
  ) {
    const unknown = (timing: LessonTiming.unknown, message: null);
    final tz = settings?['timezone'];
    final offset = _fixedOffsets[tz];
    final grace = settings?['grace_minutes'];
    if (offset == null || grace is! int) return unknown;
    final shift = lesson['period'] is Map ? lesson['period']['shift'] : null;
    int? minutesOf(Object? time) {
      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch('$time');
      if (m == null) return null;
      var h = int.parse(m[1]!);
      if (shift == 'AFTERNOON' && h < 12) h += 12; // same rule as the server
      return h * 60 + int.parse(m[2]!);
    }

    final start = minutesOf(lesson['startTime'] ?? lesson['start_time']);
    var end = minutesOf(lesson['endTime'] ?? lesson['end_time']);
    if (start == null || end == null || start == end) return unknown;
    if (end < start) end += 1440;
    // School wall-clock time expressed as a UTC DateTime.
    final schoolNow = _now().toUtc().add(Duration(minutes: offset));
    final day = DateTime.utc(date.year, date.month, date.day);
    final begins = day.add(Duration(minutes: start));
    final closes = day.add(Duration(minutes: end + grace));
    String hm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (schoolNow.isBefore(begins)) {
      return (
        timing: LessonTiming.early,
        message:
            'This lesson has not started yet: it starts at ${hm(begins)} ($tz) '
            'and it is about ${hm(schoolNow)} there by this device\'s clock. '
            'Attendance can be saved once the lesson begins.',
      );
    }
    if (schoolNow.isAfter(closes)) {
      return (
        timing: LessonTiming.late,
        message:
            'This lesson has ended. Attendance can be submitted after the '
            'lesson. Offline records will synchronize when internet is '
            'available.',
      );
    }
    return (timing: LessonTiming.open, message: null);
  }

  // ---------------------------------------------------------------- network

  /// Teacher routes, relative to `<API_URL>/api/teacher/` (backend contract
  /// sms-backend/docs/attendance-offline-sync.md).
  static const teacherBase = 'api/teacher/';

  /// POST only: offline submission batch.
  static const syncEndpoint = 'attendance/sync';

  /// GET only: the teacher's own submission history / admin decisions.
  static const historyEndpoint = 'attendance/submissions';
  static const settingsEndpoint = 'attendance/settings';

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    // Submissions are only ever POSTed to the sync route; history is GET only.
    if ((method == 'POST') != (path == syncEndpoint)) {
      throw ArgumentError('$method is not allowed for $path');
    }
    final jwt = token();
    if (jwt == null || jwt.isEmpty) {
      throw const AttendanceSyncException(
        'Sign in again to send saved attendance. It stays on this device.',
        SyncHealth.authRequired,
      );
    }
    final uri = apiUrl('$teacherBase$path');
    final headers = {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
    final http.Response response;
    try {
      response =
          await (method == 'GET'
                  ? client.get(uri, headers: headers)
                  : client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(_requestTimeout);
    } catch (e) {
      if (e is Error) rethrow;
      // DNS failure, refused socket, TLS, timeout, browser fetch failure.
      throw const AttendanceSyncException(
        'No connection to the Dugsi server.',
        SyncHealth.offline,
      );
    }
    final code = response.statusCode;
    if (code == 401) {
      _rejectedToken = jwt;
      throw const AttendanceSyncException(
        'Your session expired. Sign in again; saved attendance stays on this device.',
        SyncHealth.authRequired,
        401,
      );
    }
    if (code == 403) {
      throw const AttendanceSyncException(
        'Access denied for this teacher account. Contact your School Admin.',
        SyncHealth.accessDenied,
        403,
      );
    }
    if (code == 404) {
      throw const AttendanceSyncException(
        'Attendance sync is not available on the Dugsi server yet. Saved '
        'attendance stays on this device and is retried automatically.',
        SyncHealth.endpointMissing,
        404,
      );
    }
    if (code >= 500 || code == 408 || code == 429) {
      throw AttendanceSyncException(
        'The Dugsi server is temporarily unavailable. Saved attendance stays '
        'on this device and is retried automatically.',
        SyncHealth.serverError,
        code,
      );
    }
    if (code != 200) {
      throw AttendanceSyncException(
        'The server refused the request ($code${_serverMessage(response)}).',
        null,
        code,
      );
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      // Captive portals and proxies answer 200 with HTML: not the API.
      throw const AttendanceSyncException(
        'The network is connected but the Dugsi server is not reachable.',
        SyncHealth.offline,
      );
    }
  }

  static String _serverMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final text = body is Map ? (body['message'] ?? body['error']) : null;
      return text == null ? '' : ': $text';
    } catch (_) {
      return '';
    }
  }

  // ---------------------------------------------------------------- sync

  /// Sends due submissions, refreshes review decisions and the cache.
  /// Concurrent calls share one run; a call during a run schedules another.
  Future<void> sync({bool manual = false}) {
    if (_closed) return Future.value();
    if (_running != null) {
      _rerun = true;
      return _running!;
    }
    final run = _syncOnce(manual);
    _running = run;
    _changed();
    return run.whenComplete(() {
      _running = null;
      _changed();
      if (_rerun && !_closed) {
        _rerun = false;
        unawaited(sync());
      }
    });
  }

  Future<void> _syncOnce(bool manual) async {
    if (!manual) {
      final jwt = token();
      if (jwt == null || jwt == _rejectedToken) return;
      final next = _nextAutoAttempt;
      if (next != null && _now().isBefore(next)) return;
      // Read-only check first, so idle ticks never write storage or call the API.
      await reload();
      final stale =
          cachedAt == null || _now().difference(cachedAt!) > _staleAfter;
      if (pendingCount == 0 && !_decisionsDue && !stale) return;
    }
    if (!await _acquireLease()) return;
    try {
      await reload();
      await _sendDue(manual);
      await _refreshDecisions(manual);
      final stale =
          cachedAt == null || _now().difference(cachedAt!) > _staleAfter;
      if (manual || stale) await refreshCache();
      health = SyncHealth.online;
      message = null;
      _failures = 0;
      _nextAutoAttempt = null;
      await _pruneSynced();
    } on AttendanceSyncException catch (e) {
      health = e.health ?? SyncHealth.serverError;
      message = e.message;
      if (health != SyncHealth.authRequired) {
        _failures++;
        _nextAutoAttempt = _now().add(
          Duration(seconds: min(600, 30 * (1 << min(_failures - 1, 5)))),
        );
      }
    } finally {
      await _releaseLease();
    }
  }

  Future<void> _sendDue(bool manual) async {
    final due = entries
        .where(
          (e) =>
              e.sendable &&
              (e.state == SubmissionState.savedOffline ||
                  e.state == SubmissionState.pendingSync ||
                  (manual &&
                      e.state == SubmissionState.failed &&
                      !e.serverFinal)),
        )
        .toList()
        .reversed // oldest first
        .toList();
    // Contract allows 1..50 per batch; keep requests small for weak links.
    var i = 0;
    while (i < due.length) {
      final batch = <AttendanceSubmission>[];
      var records = 0;
      while (i < due.length && batch.length < 10) {
        final n = (due[i].payload['records'] as List).length;
        if (batch.isNotEmpty && records + n > 3000) break;
        batch.add(due[i++]);
        records += n;
      }
      await _sendBatch(batch);
    }
  }

  Future<void> _sendBatch(List<AttendanceSubmission> batch) async {
    await _renewLease();
    for (final e in batch) {
      e.state = SubmissionState.syncing;
      e.attempts++;
    }
    _changed();
    Map<String, dynamic> response;
    try {
      response = await _request(
        'POST',
        syncEndpoint,
        body: {'submissions': batch.map((e) => e.payload).toList()},
      );
    } on AttendanceSyncException catch (e) {
      if (e.health == null && batch.length > 1) {
        // Batch-level 4xx: isolate the offending item.
        for (final b in batch) {
          b.state = SubmissionState.pendingSync;
        }
        for (final b in batch) {
          await _sendBatch([b]);
        }
        return;
      }
      for (final b in batch) {
        if (e.health == null) {
          b.state = SubmissionState.failed;
          b.outcome = null;
          b.reason = e.message;
          b.detail = null;
        } else {
          b.state = SubmissionState.pendingSync;
        }
        await _persist(b);
      }
      if (e.health != null) rethrow; // offline/auth/server: stop this run
      return;
    }
    final results = <String, Map>{
      for (final r in response['results'] as List? ?? const [])
        if (r is Map && r['idempotency_key'] is String)
          r['idempotency_key'] as String: r,
    };
    for (final e in batch) {
      final result = results[e.key];
      if (result == null) {
        e.state = SubmissionState.pendingSync; // no receipt: retry same key
      } else {
        _applyOutcome(
          e,
          '${result['outcome']}',
          result['reason']?.toString(),
          result['received_at'],
          syncedAt: result['synced_at'],
          detail: result['message']?.toString(),
        );
        e.submissionId = result['submission_id'] as int? ?? e.submissionId;
      }
      await _persist(e);
    }
  }

  void _applyOutcome(
    AttendanceSubmission e,
    String outcome,
    String? reason,
    Object? receivedAt, {
    Object? syncedAt,
    String? detail,
    String? decisionNote,
  }) {
    e.outcome = outcome;
    e.reason = reason == null || reason.isEmpty ? null : reason;
    e.detail = detail;
    e.decisionNote = decisionNote ?? e.decisionNote;
    e.receivedAt = DateTime.tryParse('${receivedAt ?? ''}') ?? e.receivedAt;
    switch (outcome) {
      // Only an explicit receipt means the attendance is stored; late
      // receipts come back `accepted` too and need no approval.
      case 'accepted':
      case 'already synced':
        e.state = SubmissionState.synced;
        e.syncedAt ??=
            DateTime.tryParse('${syncedAt ?? ''}') ?? _now().toUtc();
      // Historical LATE_SERVER_RECEIPT or UNVERIFIABLE_SCHEDULE: not stored yet.
      case 'pending approval':
        e.state = SubmissionState.adminReview;
      case 'rejected':
      case 'conflict':
        e.state = SubmissionState.failed;
      default:
        e.state = SubmissionState.pendingSync;
        e.outcome = null;
    }
  }

  /// Polls the teacher audit list only while something is still pending
  /// review on the server (historical or unverifiable submissions).
  bool get _decisionsDue =>
      entries.any((e) => e.state == SubmissionState.adminReview) &&
      (_lastDecisionPoll == null ||
          _now().difference(_lastDecisionPoll!) >= _decisionPollEvery);

  Future<void> _refreshDecisions(bool manual) async {
    if (!manual && !_decisionsDue) return;
    final waiting = {
      for (final e in entries)
        if (e.state == SubmissionState.adminReview) e.key: e,
    };
    if (waiting.isEmpty) return;
    _lastDecisionPoll = _now();
    final ids = waiting.values.map((e) => e.submissionId).toList();
    int? cursor;
    if (!ids.contains(null)) {
      final first = ids.whereType<int>().reduce(min);
      cursor = first > 1 ? first - 1 : null;
    }
    for (var page = 0; page < 50 && waiting.isNotEmpty; page++) {
      final audit = await _request(
        'GET',
        '$historyEndpoint${cursor == null ? '' : '?after_id=$cursor'}',
      );
      for (final raw in audit['submissions'] as List? ?? const []) {
        if (raw is! Map) continue;
        final e = waiting[raw['idempotencyKey'] ?? raw['idempotency_key']];
        if (e == null || raw['status'] == 'pending approval') continue;
        _applyOutcome(
          e,
          '${raw['status']}',
          raw['reason']?.toString(),
          raw['receivedAt'] ?? raw['received_at'],
          syncedAt: raw['syncedAt'] ?? raw['synced_at'],
          decisionNote: (raw['decisionNote'] ?? raw['decision_note'])
              ?.toString(),
        );
        waiting.remove(e.key);
        await _persist(e);
      }
      final next = audit['next_after_id'];
      if (next is! int) break;
      cursor = next;
    }
  }

  Future<void> _pruneSynced() async {
    final cutoff = _now().toUtc().subtract(_keepSyncedFor);
    for (final e in entries.toList()) {
      if (e.state == SubmissionState.synced &&
          e.syncedAt != null &&
          e.syncedAt!.isBefore(cutoff)) {
        await prefs.remove('${prefix}entry_${e.key}');
        entries.remove(e);
      }
    }
  }

  // Best-effort lease so two PWA tabs do not send at the same time. Server
  // idempotency keys remain the real duplicate guard.
  String get _leaseKey => '${prefix}lease';

  Future<bool> _acquireLease() async {
    try {
      await prefs.reload();
    } catch (_) {}
    final parts = (prefs.getString(_leaseKey) ?? '').split('|');
    if (parts.length == 2 &&
        parts[0] != _tabId &&
        (int.tryParse(parts[1]) ?? 0) > _now().millisecondsSinceEpoch) {
      return false;
    }
    await _renewLease();
    return true;
  }

  Future<void> _renewLease() async {
    try {
      await prefs.setString(
        _leaseKey,
        '$_tabId|${_now().add(_leaseFor).millisecondsSinceEpoch}',
      );
    } catch (_) {}
  }

  Future<void> _releaseLease() async {
    try {
      if ((prefs.getString(_leaseKey) ?? '').startsWith('$_tabId|')) {
        await prefs.remove(_leaseKey);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    _connectivity?.cancel();
    if (_automatic) WidgetsBinding.instance.removeObserver(this);
    client.close();
    super.dispose();
  }
}
