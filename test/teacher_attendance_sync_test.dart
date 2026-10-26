import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/teacher_attendance_sync.dart';

/// 2026-09-28 is a Monday.
final monday = DateTime(2026, 9, 28);
DateTime clock() => DateTime(2026, 9, 28, 8, 30, 15, 123, 456);

Map<String, dynamic> lesson(int id, int classId, {String start = '08:00'}) => {
  'id': id,
  'day': 'MON',
  'startTime': start,
  'endTime': '09:00',
  'classId': classId,
  'subjectId': 3,
  'subjectName': 'Math',
  'className': 'Class $classId',
};

/// In-memory stand-in for the attendance API contract.
class FakeApi {
  FakeApi({this.schoolId = 7, this.teacherId = 70});
  final int schoolId;
  final int teacherId;
  bool online = true;
  bool captivePortal = false;
  int? forcedStatus;
  bool dropNextResponse = false;
  String Function(Map submission) outcomeFor = (_) => 'accepted';
  String? Function(Map submission) reasonFor = (_) => null;
  String timezone = 'Africa/Mogadishu';
  http.Response? Function(Map body)? rawSyncResponse;

  /// Status returned only for POSTs (GETs behave normally).
  int? postStatus;
  String postBody = '{}';
  final List<
    ({String method, Uri url, Map<String, String> headers, String body})
  >
  log = [];
  final List<Map> posts = [];
  final List<Uri> gets = [];
  final Map<String, Map<String, dynamic>> stored = {};
  final List<Map<String, dynamic>> timetables = [lesson(402, 25)];
  Completer<void>? holdPost;

  late final MockClient client = MockClient((request) async {
    log.add((
      method: request.method,
      url: request.url,
      headers: request.headers,
      body: request.body,
    ));
    if (!online) throw http.ClientException('Failed host lookup: api.dugsi.so');
    if (captivePortal) return http.Response('<html>Login to Wi-Fi</html>', 200);
    if (forcedStatus != null) return http.Response('{}', forcedStatus!);
    if (postStatus != null && request.method == 'POST') {
      return http.Response(postBody, postStatus!);
    }
    expect(request.headers['Authorization'], startsWith('Bearer '));
    final path = request.url.path;
    if (request.method == 'GET') {
      gets.add(request.url);
      if (path.endsWith('/dashboard')) {
        return _json({
          'teacher': {'id': teacherId, 'schoolId': schoolId},
          'assignedClasses': [
            {'id': 25, 'name': 'Class 25'},
            {'id': 26, 'name': 'Class 26'},
          ],
          'assignments': [
            {'id': 1, 'classId': 25, 'subjectId': 3},
            {'id': 2, 'classId': 26, 'subjectId': 3},
          ],
          'timetables': timetables,
          'academicYear': {'id': 2, 'name': '2026'},
        });
      }
      if (path.endsWith('/attendance/settings')) {
        return _json({'timezone': timezone, 'grace_minutes': 30});
      }
      if (path.contains('/classes/')) {
        final classId = int.parse(path.split('/')[4]);
        return _json({
          'students': [
            {'id': classId * 100 + 1, 'name': 'Amina'},
            {'id': classId * 100 + 2, 'name': 'Bashir'},
          ],
        });
      }
      if (path.endsWith('/attendance/submissions')) {
        final after = int.tryParse(
          request.url.queryParameters['after_id'] ?? '',
        );
        final rows = stored.values
            .where((r) => after == null || (r['id'] as int) > after)
            .toList();
        return _json({'submissions': rows, 'next_after_id': null});
      }
    }
    expect(path, '/api/teacher/attendance/sync');
    final submissions = (jsonDecode(request.body)['submissions'] as List)
        .cast<Map>();
    posts.add({'body': request.body, 'count': submissions.length});
    if (holdPost != null) await holdPost!.future;
    final raw = rawSyncResponse?.call(jsonDecode(request.body) as Map);
    if (raw != null) return raw;
    final results = [];
    for (final s in submissions) {
      final key = s['idempotency_key'] as String;
      final previous = stored[key];
      if (previous != null) {
        results.add({
          'idempotency_key': key,
          'submission_id': previous['id'],
          'outcome': previous['status'] == 'accepted'
              ? 'already synced'
              : previous['status'],
          'reason': previous['reason'],
        });
        continue;
      }
      final outcome = outcomeFor(s);
      // Current backend: late receipts are accepted; only unverifiable
      // schedules are held as `pending approval`.
      final row = {
        'id': stored.length + 40,
        'idempotencyKey': key,
        'status': outcome,
        'reason': outcome == 'pending approval'
            ? 'UNVERIFIABLE_SCHEDULE'
            : reasonFor(s),
        'receivedAt': '2026-09-28T07:00:00.000Z',
        'syncedAt': outcome == 'accepted' ? '2026-09-28T07:00:00.120Z' : null,
      };
      stored[key] = row;
      results.add({
        'idempotency_key': key,
        'submission_id': row['id'],
        'outcome': outcome,
        'reason': row['reason'],
        'received_at': row['receivedAt'],
        'synced_at': row['syncedAt'],
      });
    }
    if (dropNextResponse) {
      dropNextResponse = false;
      throw http.ClientException('Connection reset after commit');
    }
    return _json({'results': results});
  });

  int get syncPosts => posts.length;
  int get auditGets =>
      gets.where((u) => u.path.endsWith('/attendance/submissions')).length;

  static http.Response _json(Object body) =>
      http.Response(jsonEncode(body), 200);
}

List<Map<String, dynamic>> marks(int classId) => [
  {'student_id': classId * 100 + 1, 'status': 'PRESENT'},
  {'student_id': classId * 100 + 2, 'status': 'ABSENT'},
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<TeacherAttendanceSync> open(
    FakeApi api, {
    int schoolId = 7,
    int userId = 9,
    String? Function()? token,
    DateTime Function()? at,
  }) async {
    final sync = TeacherAttendanceSync(
      schoolId: schoolId,
      userId: userId,
      token: token ?? () => 'jwt',
      client: api.client,
      clock: at ?? clock,
    );
    await sync.initialize(automatic: false);
    return sync;
  }

  Future<TeacherAttendanceSync> openCached(FakeApi api) async {
    final sync = await open(api);
    await sync.refreshCache();
    return sync;
  }

  test('online submission is accepted with a contract-valid payload', () async {
    final api = FakeApi();
    final sync = await openCached(api);
    expect(sync.settings!['grace_minutes'], 30);
    final entry = await sync.save(
      lessonId: 402,
      date: monday,
      records: marks(25),
    );
    expect(entry.state, SubmissionState.savedOffline);
    await sync.sync();
    expect(entry.state, SubmissionState.synced);
    final sent = jsonDecode(api.posts.single['body'])['submissions'][0];
    expect(
      sent['idempotency_key'],
      matches(RegExp(r'^[A-Za-z0-9_-]{16,100}$')),
    );
    expect(sent['school_id'], 7);
    expect(sent['teacher_id'], 70);
    expect(sent['class_id'], 25);
    expect(sent['timetable_id'], 402);
    expect(sent['academic_year_id'], 2);
    expect(sent['date'], '2026-09-28');
    // Backend regex allows at most millisecond precision.
    expect(
      sent['recorded_at'],
      matches(
        RegExp(
          r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,3})?(?:Z|[+-]\d\d:\d\d)$',
        ),
      ),
    );
    expect(sent['records'], marks(25));
    expect(api.auditGets, 0, reason: 'nothing awaits review');
    final requests = api.gets.length + api.posts.length;
    await sync.sync(); // idle automatic tick
    expect(api.gets.length + api.posts.length, requests);
    sync.dispose();
  });

  test(
    'offline save uses cached lesson and students without UI errors',
    () async {
      final api = FakeApi();
      final sync = await openCached(api);
      api.online = false;
      final entry = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      await sync.sync(manual: true);
      expect(entry.state, SubmissionState.pendingSync);
      expect(sync.health, SyncHealth.offline);
      expect(sync.message, isNot(contains('Exception')));
      expect(sync.message, isNot(contains('Bad state')));
      expect(api.auditGets, 0);
      api.online = true;
      await sync.sync(manual: true);
      expect(entry.state, SubmissionState.synced);
      expect(sync.health, SyncHealth.online);
      sync.dispose();
    },
  );

  test('cache and queue survive app restart / PWA reload', () async {
    final api = FakeApi();
    final first = await openCached(api);
    api.online = false;
    final saved = await first.save(
      lessonId: 402,
      date: monday,
      records: marks(25),
    );
    first.dispose();

    // A new instance reads the same persistent store, like a cold start.
    final restarted = await open(api);
    expect(restarted.hasSchedule, isTrue);
    expect(restarted.settings!['timezone'], 'Africa/Mogadishu');
    expect(restarted.lessonsFor(26, monday), isEmpty);
    expect(restarted.lessonsFor(25, monday).single['id'], 402);
    expect(restarted.rosterFor(26)!.length, 2);
    expect(restarted.entries.single.key, saved.key);
    expect(
      jsonEncode(restarted.entries.single.payload),
      jsonEncode(saved.payload),
    );
    // Taking another lesson offline after the restart still works.
    api.timetables.add(lesson(403, 26, start: '09:00'));
    await expectLater(
      restarted.save(lessonId: 403, date: monday, records: marks(26)),
      throwsA(isA<AttendanceSyncException>()),
      reason: 'lesson 403 was never cached; it must not be fabricated',
    );
    api.online = true;
    await restarted.sync(manual: true);
    expect(restarted.entries.single.state, SubmissionState.synced);
    final second = await restarted.save(
      lessonId: 403,
      date: monday,
      records: marks(26),
    );
    expect(second.state, SubmissionState.savedOffline);
    restarted.dispose();
  });

  test(
    'no cached schedule gives a recoverable message, not Bad state',
    () async {
      final api = FakeApi()..online = false;
      final sync = await open(api);
      expect(sync.hasSchedule, isFalse);
      await expectLater(
        sync.save(lessonId: 402, date: monday, records: marks(25)),
        throwsA(
          isA<AttendanceSyncException>().having(
            (e) => e.message,
            'message',
            contains('Sync Now'),
          ),
        ),
      );
      expect(sync.entries, isEmpty);
      await sync.sync(manual: true);
      expect(sync.health, SyncHealth.offline);
      api.online = true;
      await sync.sync(manual: true);
      expect(sync.hasSchedule, isTrue);
      sync.dispose();
    },
  );

  test(
    'rejects wrong weekday, future date, unenrolled students and LATE',
    () async {
      final api = FakeApi();
      final sync = await openCached(api);
      Future<void> rejects(DateTime date, List<Map<String, dynamic>> r) =>
          expectLater(
            sync.save(lessonId: 402, date: date, records: r),
            throwsA(isA<AttendanceSyncException>()),
          );
      await rejects(monday.add(const Duration(days: 1)), marks(25));
      await rejects(monday.add(const Duration(days: 7)), marks(25));
      await rejects(monday, marks(26));
      await rejects(monday, [
        {'student_id': 2501, 'status': 'LATE'},
      ]);
      expect(sync.entries, isEmpty);
      sync.dispose();
    },
  );

  test('connection lost after commit retries the same key and body', () async {
    final api = FakeApi();
    final sync = await openCached(api);
    await sync.save(lessonId: 402, date: monday, records: marks(25));
    api.dropNextResponse = true;
    await sync.sync();
    expect(sync.entries.single.state, SubmissionState.pendingSync);
    expect(sync.health, SyncHealth.offline);
    await sync.sync(manual: true);
    expect(sync.entries.single.state, SubmissionState.synced);
    expect(sync.entries.single.outcome, 'already synced');
    expect(api.posts[0]['body'], api.posts[1]['body']);
    expect(api.stored, hasLength(1));
    sync.dispose();
  });

  test(
    'concurrent sync calls share one request; lesson cannot be saved twice',
    () async {
      final api = FakeApi()..holdPost = Completer<void>();
      final sync = await openCached(api);
      await sync.save(lessonId: 402, date: monday, records: marks(25));
      final a = sync.sync();
      final b = sync.sync(manual: true);
      await pumpEventQueue();
      expect(sync.entries.single.state, SubmissionState.syncing);
      // Saving during a run is allowed, but not for the same lesson.
      await expectLater(
        sync.save(lessonId: 402, date: monday, records: marks(25)),
        throwsA(isA<AttendanceSyncException>()),
      );
      api.holdPost!.complete();
      await Future.wait([a, b]);
      await pumpEventQueue();
      expect(api.syncPosts, 1);
      expect(sync.entries.single.state, SubmissionState.synced);
      sync.dispose();
    },
  );

  test('second tab holding the lease does not send concurrently', () async {
    final api = FakeApi();
    final sync = await openCached(api);
    await sync.save(lessonId: 402, date: monday, records: marks(25));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${sync.prefix}lease',
      'othertab|${clock().add(const Duration(minutes: 1)).millisecondsSinceEpoch}',
    );
    await sync.sync(manual: true);
    expect(api.syncPosts, 0);
    await prefs.remove('${sync.prefix}lease');
    await sync.sync(manual: true);
    expect(api.syncPosts, 1);
    sync.dispose();
  });

  test('expired session keeps the queue and resumes after sign-in', () async {
    final api = FakeApi();
    var jwt = 'old';
    final sync = await open(api, token: () => jwt);
    await sync.refreshCache();
    final entry = await sync.save(
      lessonId: 402,
      date: monday,
      records: marks(25),
    );
    final payload = jsonEncode(entry.payload);
    api.forcedStatus = 401;
    await sync.sync(manual: true);
    expect(sync.health, SyncHealth.authRequired);
    expect(entry.state, SubmissionState.pendingSync);
    api.forcedStatus = null;
    await sync.sync(); // automatic retry with the rejected token is skipped
    expect(api.syncPosts, 0);
    jwt = 'new';
    sync.wake();
    await pumpEventQueue();
    await (sync.busy ? sync.sync() : Future.value());
    expect(entry.state, SubmissionState.synced);
    expect(jsonEncode(entry.payload), payload);
    sync.dispose();
  });

  test('unverifiable schedule is held for review; approval is picked up', () async {
    final api = FakeApi()..outcomeFor = (_) => 'pending approval';
    final sync = await openCached(api);
    final entry = await sync.save(
      lessonId: 402,
      date: monday,
      records: marks(25),
    );
    final captured = entry.capturedAt;
    await sync.sync();
    expect(entry.state, SubmissionState.adminReview);
    expect(entry.statusLabel, 'Pending Review');
    expect(entry.syncedAt, isNull, reason: 'HTTP 200 alone is not stored');
    expect(entry.reason, 'UNVERIFIABLE_SCHEDULE');
    expect(entry.receivedAt, DateTime.utc(2026, 9, 28, 7));
    expect(entry.capturedAt, captured, reason: 'device time is never replaced');
    await sync.sync(manual: true);
    expect(entry.state, SubmissionState.adminReview);
    expect(api.syncPosts, 1, reason: 'review items are not re-posted');
    final audit = api.gets.lastWhere(
      (u) => u.path.endsWith('/attendance/submissions'),
    );
    expect(audit.queryParameters['after_id'], '${entry.submissionId! - 1}');

    api.stored[entry.key]!
      ..['status'] = 'accepted'
      ..['reason'] = 'ADMIN_APPROVED'
      ..['decisionNote'] = 'Paper register verified';
    await sync.sync(manual: true);
    expect(entry.state, SubmissionState.synced);
    expect(entry.reason, 'ADMIN_APPROVED');
    expect(entry.decisionNote, 'Paper register verified');
    expect(describeSubmission(entry), contains('Paper register verified'));
    sync.dispose();
  });

  test('admin rejection after review is shown as Rejected with the reason', () async {
    final api = FakeApi()..outcomeFor = (_) => 'pending approval';
    final sync = await openCached(api);
    final entry = await sync.save(
      lessonId: 402,
      date: monday,
      records: marks(25),
    );
    await sync.sync();
    api.stored[entry.key]!
      ..['status'] = 'rejected'
      ..['reason'] = 'ADMIN_REJECTED'
      ..['decisionNote'] = 'Wrong class register submitted';
    await sync.sync(manual: true);
    expect(entry.state, SubmissionState.failed);
    expect(entry.statusLabel, 'Rejected');
    expect(entry.serverFinal, isTrue);
    expect(
      describeSubmission(entry),
      contains('Wrong class register submitted'),
    );
    sync.dispose();
  });

  test('late receipt is accepted immediately without review', () async {
    final api = FakeApi();
    // 14:00 in Mogadishu: long after the 09:00 end + 30 min grace.
    final sync = await open(api, at: () => DateTime.utc(2026, 9, 28, 11));
    await sync.refreshCache();
    final entry = await sync.save(
      lessonId: 402,
      date: monday,
      records: marks(25),
    );
    await sync.sync();
    expect(entry.state, SubmissionState.synced);
    expect(entry.statusLabel, 'Synchronized');
    expect(entry.reason, isNull);
    expect(
      entry.syncedAt,
      DateTime.utc(2026, 9, 28, 7, 0, 0, 120),
      reason: 'server synced_at confirms persistence',
    );
    expect(describeSubmission(entry), isNot(contains('Admin')));
    expect(api.auditGets, 0, reason: 'nothing awaits a decision');
    sync.dispose();
  });

  test('offline capture during the lesson syncs late and is accepted', () async {
    final api = FakeApi();
    // 08:30 in Mogadishu, during the 08:00-09:00 lesson.
    var now = DateTime.utc(2026, 9, 28, 5, 30);
    final sync = await open(api, at: () => now);
    await sync.refreshCache();
    api.online = false;
    final entry = await sync.save(
      lessonId: 402,
      date: monday,
      records: marks(25),
    );
    await sync.sync(manual: true);
    expect(entry.state, SubmissionState.pendingSync);
    expect(entry.statusLabel, 'Pending Sync');
    // Reconnects the next day, long after end + grace.
    now = DateTime.utc(2026, 9, 29, 6);
    api.online = true;
    await sync.sync(manual: true);
    expect(entry.state, SubmissionState.synced);
    expect(api.syncPosts, 1);
    expect(api.auditGets, 0);
    final sent = jsonDecode(api.posts.single['body'])['submissions'][0];
    expect(sent['recorded_at'], '2026-09-28T05:30:00.000Z');
    expect(sent['date'], '2026-09-28');
    sync.dispose();
  });

  test('historical LATE_SERVER_RECEIPT stays pending until decided', () async {
    final api = FakeApi();
    const key = 'histkey000000000000001';
    final payload = {
      'idempotency_key': key,
      'school_id': 7,
      'teacher_id': 70,
      'academic_year_id': 2,
      'class_id': 25,
      'timetable_id': 402,
      'date': '2026-09-21',
      'recorded_at': '2026-09-21T05:30:00.000Z',
      'records': marks(25),
    };
    // Queued for review by the previous backend release and app build.
    SharedPreferences.setMockInitialValues({
      'teacher_attendance_v1_7_9_entry_$key': jsonEncode({
        'v': 2,
        'lesson': '25|2026-09-21|08:00|3',
        'label': 'Math · Class 25 · 08:00',
        'captured_at': '2026-09-21T05:30:00.000Z',
        'state': 'adminReview',
        'outcome': 'pending approval',
        'reason': 'LATE_SERVER_RECEIPT',
        'submission_id': 12,
        'payload': payload,
      }),
    });
    api.stored[key] = {
      'id': 12,
      'idempotencyKey': key,
      'status': 'pending approval',
      'reason': 'LATE_SERVER_RECEIPT',
    };
    final sync = await openCached(api);
    final entry = sync.entries.single;
    expect(entry.state, SubmissionState.adminReview);
    expect(entry.statusLabel, 'Pending Review');
    expect(describeSubmission(entry), contains('earlier rules'));
    expect(describeSubmission(entry), contains('no longer needs approval'));
    expect(sync.pendingCount, 0, reason: 'not counted as unsynced');
    await sync.sync(manual: true);
    expect(api.syncPosts, 0, reason: 'pending items are never re-posted');
    expect(entry.state, SubmissionState.adminReview);

    // School Admin approves without a note.
    api.stored[key]!
      ..['status'] = 'accepted'
      ..['reason'] = 'ADMIN_APPROVED'
      ..['decisionNote'] = null
      ..['syncedAt'] = '2026-09-29T07:00:00.000Z';
    await sync.sync(manual: true);
    expect(entry.state, SubmissionState.synced);
    expect(entry.syncedAt, DateTime.utc(2026, 9, 29, 7));
    expect(describeSubmission(entry), 'Approved by School Admin.');
    sync.dispose();
  });

  test('HTTP 200 rejected / conflict never shows Synchronized', () async {
    for (final (outcome, reason, label) in [
      ('rejected', 'STUDENT_NOT_ENROLLED', 'Rejected'),
      ('conflict', 'ATTENDANCE_ALREADY_RECORDED', 'Conflict'),
      ('conflict', 'IDEMPOTENCY_KEY_REUSED', 'Conflict'),
    ]) {
      SharedPreferences.setMockInitialValues({});
      final api = FakeApi()
        ..outcomeFor = ((_) => outcome)
        ..reasonFor = ((_) => reason);
      final sync = await openCached(api);
      final entry = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      await sync.sync();
      expect(entry.state, SubmissionState.failed, reason: reason);
      expect(entry.statusLabel, label, reason: reason);
      expect(entry.syncedAt, isNull);
      expect(entry.serverFinal, isTrue);
      expect(sync.attentionCount, 1);
      await sync.sync(manual: true);
      expect(api.syncPosts, 1, reason: 'the same key cannot succeed');
      sync.dispose();
    }
  });

  test('legacy "Requires Admin Review" label still parses', () {
    expect(
      SubmissionState.parse('Requires Admin Review'),
      SubmissionState.adminReview,
    );
    expect(SubmissionState.parse('adminReview'), SubmissionState.adminReview);
  });

  test('multiple queued submissions are sent in one ordered batch', () async {
    final api = FakeApi();
    api.timetables.addAll([
      lesson(403, 26, start: '09:00'),
      lesson(404, 25, start: '10:00'),
    ]);
    final sync = await openCached(api);
    api.online = false;
    await sync.save(lessonId: 402, date: monday, records: marks(25));
    await sync.save(lessonId: 403, date: monday, records: marks(26));
    await sync.save(
      lessonId: 402,
      date: monday.subtract(const Duration(days: 7)),
      records: marks(25),
    );
    await sync.sync(manual: true);
    expect(sync.pendingCount, 3);
    api.online = true;
    await sync.sync(manual: true);
    expect(api.posts.single['count'], 3);
    expect(
      sync.entries.every((e) => e.state == SubmissionState.synced),
      isTrue,
    );
    final dates = (jsonDecode(api.posts.single['body'])['submissions'] as List)
        .map((s) => s['date'])
        .toList();
    expect(dates, containsAll(['2026-09-28', '2026-09-21']));
    expect(api.stored, hasLength(3));
    sync.dispose();
  });

  test(
    'logout clears downloads but keeps the queue; other teachers see nothing',
    () async {
      final api = FakeApi();
      final teacherA = await openCached(api);
      api.online = false;
      await teacherA.save(lessonId: 402, date: monday, records: marks(25));
      teacherA.dispose();
      await TeacherAttendanceSync.clearDownloadedData(7, 9);

      final teacherB = await open(api, userId: 10);
      expect(teacherB.entries, isEmpty);
      expect(teacherB.hasSchedule, isFalse);
      teacherB.dispose();

      final otherSchool = await open(api, schoolId: 8, userId: 9);
      expect(otherSchool.entries, isEmpty);
      otherSchool.dispose();

      final again = await open(api);
      expect(again.hasSchedule, isFalse);
      expect(again.entries, hasLength(1));
      api.online = true;
      await again.sync(manual: true);
      expect(again.entries.single.state, SubmissionState.synced);
      again.dispose();
    },
  );

  test('dashboard for another school is never cached', () async {
    final api = FakeApi(schoolId: 99);
    final sync = await open(api);
    await expectLater(
      sync.refreshCache(),
      throwsA(isA<AttendanceSyncException>()),
    );
    expect(sync.hasSchedule, isFalse);
    sync.dispose();
  });

  test(
    'server errors retry identically; rejection is kept, never retried',
    () async {
      final api = FakeApi();
      final sync = await openCached(api);
      final entry = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      api.forcedStatus = 500;
      await sync.sync(manual: true);
      expect(entry.state, SubmissionState.pendingSync);
      expect(sync.health, SyncHealth.serverError);
      expect(sync.message, contains('temporarily unavailable'));
      expect(sync.message, isNot(contains('500')));
      api.forcedStatus = null;
      api.outcomeFor = (_) => 'rejected';
      await sync.sync(manual: true);
      expect(entry.state, SubmissionState.failed);
      expect(entry.serverFinal, isTrue);
      final posts = api.syncPosts;
      await sync.sync(manual: true);
      expect(api.syncPosts, posts, reason: 'server-final items are not resent');

      // Survives restart; a corrected save gets a new key; dismissing is explicit.
      sync.dispose();
      final restarted = await open(api);
      expect(restarted.entries.single.state, SubmissionState.failed);
      api.outcomeFor = (_) => 'accepted';
      final retry = await restarted.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      expect(retry.key, isNot(entry.key));
      await restarted.dismiss(
        restarted.entries.firstWhere((e) => e.key == entry.key),
      );
      expect(restarted.entries.single.key, retry.key);
      restarted.dispose();
    },
  );

  test('conflict blocks re-saving the same lesson', () async {
    final api = FakeApi()..outcomeFor = (_) => 'conflict';
    final sync = await openCached(api);
    await sync.save(lessonId: 402, date: monday, records: marks(25));
    await sync.sync();
    expect(sync.entries.single.state, SubmissionState.failed);
    await expectLater(
      sync.save(lessonId: 402, date: monday, records: marks(25)),
      throwsA(isA<AttendanceSyncException>()),
    );
    sync.dispose();
  });

  test(
    'connected Wi-Fi without API (captive portal) counts as offline',
    () async {
      final api = FakeApi();
      final sync = await openCached(api);
      final entry = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      api.captivePortal = true;
      await sync.sync(manual: true);
      expect(sync.health, SyncHealth.offline);
      expect(entry.state, SubmissionState.pendingSync);
      sync.dispose();
    },
  );

  test('connectivity event triggers sync but the request decides', () async {
    final api = FakeApi();
    final events = StreamController<Object?>();
    final sync = TeacherAttendanceSync(
      schoolId: 7,
      userId: 9,
      token: () => 'jwt',
      client: api.client,
      clock: clock,
      connectivityChanges: events.stream,
    );
    api.online = false;
    await sync.initialize();
    await pumpEventQueue();
    expect(sync.health, SyncHealth.offline);
    api.online = true;
    events.add(const ['wifi']);
    await pumpEventQueue();
    while (sync.busy) {
      await sync.sync();
      await pumpEventQueue();
    }
    expect(sync.hasSchedule, isTrue);
    sync.dispose();
    await events.close();
  });

  test('legacy queue entries from the first offline build are kept', () async {
    SharedPreferences.setMockInitialValues({
      'teacher_attendance_v1_7_9_entry_abcdefabcdefabcdef': jsonEncode({
        'lesson': '25|2026-09-28|08:00|3',
        'status': 'Saved Offline',
        'payload': {
          'idempotency_key': 'abcdefabcdefabcdef',
          'academic_year_id': 2,
          'class_id': 25,
          'timetable_id': 402,
          'date': '2026-09-28',
          'recorded_at': '2026-09-28T05:00:00.000Z',
          'records': marks(25),
        },
      }),
    });
    final api = FakeApi();
    final sync = await open(api);
    expect(sync.entries.single.state, SubmissionState.savedOffline);
    await sync.sync(manual: true);
    expect(sync.entries.single.state, SubmissionState.synced);
    sync.dispose();
  });

  group('hardening', () {
    Map<String, dynamic> legacyEntry({
      required String recordedAt,
      String status = 'Pending Sync',
      List<Map<String, dynamic>>? records,
    }) => {
      'lesson': '25|2026-09-28|08:00|3',
      'status': status,
      'payload': {
        'idempotency_key': 'legacykey0000000001',
        'academic_year_id': 2,
        'class_id': 25,
        'timetable_id': 402,
        'date': '2026-09-28',
        'recorded_at': recordedAt,
        'records': records ?? marks(25),
      },
    };

    test('lesson timing estimate uses school timezone and shift', () async {
      final api = FakeApi();
      api.timetables.add({
        ...lesson(405, 25, start: '02:00'),
        'endTime': '03:00',
        'period': {'shift': 'AFTERNOON'},
      });
      // Mogadishu is UTC+3. Lesson 402 runs 08:00-09:00, grace 30 min.
      Future<LessonTiming> at(DateTime utc, int lessonId) async {
        final sync = await open(api, at: () => utc);
        await sync.refreshCache();
        final l = sync.lessons.firstWhere((l) => l['id'] == lessonId);
        final timing = sync.lessonTiming(l, monday).timing;
        sync.dispose();
        return timing;
      }

      expect(
        await at(DateTime.utc(2026, 9, 28, 4, 50), 402),
        LessonTiming.early,
      );
      expect(
        await at(DateTime.utc(2026, 9, 28, 5, 30), 402),
        LessonTiming.open,
      );
      expect(
        await at(DateTime.utc(2026, 9, 28, 6, 30), 402),
        LessonTiming.open,
      );
      expect(
        await at(DateTime.utc(2026, 9, 28, 6, 31), 402),
        LessonTiming.late,
      );
      // AFTERNOON "02:00" is 14:00, as on the server.
      expect(
        await at(DateTime.utc(2026, 9, 28, 10, 0), 405),
        LessonTiming.early,
      );
      api.timezone = 'Europe/London'; // has DST: no estimate, no warning
      expect(
        await at(DateTime.utc(2026, 9, 28, 4, 50), 402),
        LessonTiming.unknown,
      );
    });

    test('a lesson that has not started cannot be saved', () async {
      final api = FakeApi();
      // 07:50 in Mogadishu; lesson 402 starts at 08:00.
      final sync = await open(api, at: () => DateTime.utc(2026, 9, 28, 4, 50));
      await sync.refreshCache();
      expect(
        sync.lessonTiming(sync.lessons.single, monday).timing,
        LessonTiming.early,
      );
      await expectLater(
        sync.save(lessonId: 402, date: monday, records: marks(25)),
        throwsA(
          isA<AttendanceSyncException>().having(
            (e) => e.message,
            'message',
            contains('has not started yet'),
          ),
        ),
      );
      expect(sync.entries, isEmpty);
      expect(api.syncPosts, 0);
      sync.dispose();
    });

    test('late lesson saves without approval wording and syncs', () async {
      final api = FakeApi();
      // 11:00 in Mogadishu: long after 09:00 end + 30 min grace.
      final sync = await open(api, at: () => DateTime.utc(2026, 9, 28, 8, 0));
      await sync.refreshCache();
      final timing = sync.lessonTiming(sync.lessons.single, monday);
      expect(timing.timing, LessonTiming.late);
      expect(timing.message, isNot(contains('Admin')));
      expect(timing.message, contains('can be submitted after the lesson'));
      final entry = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      await sync.sync();
      expect(entry.state, SubmissionState.synced);
      expect(entry.state.label, 'Synchronized');
      sync.dispose();
    });

    test(
      'server-side "not started" rejection can be resubmitted',
      () async {
        // Device clock says the lesson is open, but the server disagrees
        // (e.g. a skewed device clock).
        final api = FakeApi()
          ..outcomeFor = ((_) => 'rejected')
          ..reasonFor = ((_) => 'LESSON_NOT_STARTED');
        final sync = await open(
          api,
          at: () => DateTime.utc(2026, 9, 28, 5, 10),
        );
        await sync.refreshCache();
        final first = await sync.save(
          lessonId: 402,
          date: monday,
          records: marks(25),
        );
        await sync.sync();
        expect(first.state, SubmissionState.failed);
        expect(first.reason, 'LESSON_NOT_STARTED');
        expect(
          describeSubmission(first),
          contains('before the lesson started'),
        );
        expect(sync.canResubmit(first), isTrue);

        api.outcomeFor = (_) => 'accepted';
        final copy = await sync.resubmit(first);
        expect(copy.key, isNot(first.key));
        expect(copy.payload['records'], first.payload['records']);
        expect(copy.capturedAt, first.capturedAt);
        expect(first.replacedBy, copy.key);
        expect(sync.canResubmit(first), isFalse, reason: 'only one copy');
        await expectLater(
          sync.save(lessonId: 402, date: monday, records: marks(25)),
          throwsA(isA<AttendanceSyncException>()),
        );
        await sync.sync(manual: true);
        expect(copy.state, SubmissionState.synced);
        expect(
          sync.entries,
          hasLength(2),
          reason: 'original kept, not deleted',
        );
        expect(sync.attentionCount, 0);
        sync.dispose();
      },
    );

    test('rejections are explained in plain language', () async {
      for (final code in [
        'ATTENDANCE_ALREADY_RECORDED',
        'STUDENT_NOT_ENROLLED',
        'ADMIN_REJECTED',
        'LESSON_NOT_ASSIGNED',
        'IDENTITY_MISMATCH',
      ]) {
        final e = AttendanceSubmission(
          payload: {'idempotency_key': 'k' * 20},
          lessonKey: 'x',
          label: 'Math',
          capturedAt: DateTime.utc(2026),
          state: SubmissionState.failed,
          outcome: 'rejected',
          reason: code,
          decisionNote: code == 'ADMIN_REJECTED' ? 'Wrong register' : null,
        );
        final text = describeSubmission(e);
        expect(text, isNot(contains('_')), reason: text);
        if (code == 'ADMIN_REJECTED') {
          expect(text, contains('Wrong register'));
        }
      }
      final invalid = AttendanceSubmission(
        payload: {'idempotency_key': 'k' * 20},
        lessonKey: 'x',
        label: 'Math',
        capturedAt: DateTime.utc(2026),
        state: SubmissionState.failed,
        outcome: 'rejected',
        reason: 'INVALID_SUBMISSION',
        detail: 'recorded_at must be an ISO timestamp with timezone',
      );
      expect(describeSubmission(invalid), contains('recorded_at must be'));
    });

    test('unfixable rejection is kept and cannot be resubmitted', () async {
      final api = FakeApi()
        ..outcomeFor = ((_) => 'rejected')
        ..reasonFor = ((_) => 'STUDENT_NOT_ENROLLED');
      final sync = await openCached(api);
      final e = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      await sync.sync();
      expect(e.reason, 'STUDENT_NOT_ENROLLED');
      expect(sync.canResubmit(e), isFalse);
      expect(sync.attentionCount, 1);
      await expectLater(
        sync.resubmit(e),
        throwsA(isA<AttendanceSyncException>()),
      );
      sync.dispose();
    });

    test(
      'legacy record in an invalid format is held and replaceable',
      () async {
        SharedPreferences.setMockInitialValues({
          // Android builds before the fix wrote microseconds.
          'teacher_attendance_v1_7_9_entry_legacykey0000000001': jsonEncode(
            legacyEntry(recordedAt: '2026-09-28T05:00:00.123456Z'),
          ),
        });
        final api = FakeApi();
        final sync = await open(api);
        final old = sync.entries.single;
        expect(old.legacy, isTrue);
        expect(old.state, SubmissionState.failed);
        expect(old.reason, 'LEGACY_FORMAT');
        expect(describeSubmission(old), contains('earlier app version'));
        await sync.sync(manual: true);
        expect(api.syncPosts, 0, reason: 'never sent in a rejected format');
        expect(sync.entries, hasLength(1), reason: 'never silently deleted');

        expect(sync.canResubmit(old), isTrue);
        final copy = await sync.resubmit(old);
        await sync.sync(manual: true);
        final sent = jsonDecode(api.posts.single['body'])['submissions'][0];
        expect(sent['idempotency_key'], copy.key);
        expect(sent['recorded_at'], '2026-09-28T05:00:00.123Z');
        expect(sent['records'], marks(25));
        expect(copy.state, SubmissionState.synced);
        expect(old.replacedBy, copy.key);

        sync.dispose();
        final again = await open(api);
        final restored = again.entries.firstWhere((e) => e.key == old.key);
        expect(restored.replacedBy, copy.key);
        expect(again.canResubmit(restored), isFalse);
        again.dispose();
      },
    );

    test(
      'legacy record with LATE is not replaceable and does not block',
      () async {
        SharedPreferences.setMockInitialValues({
          'teacher_attendance_v1_7_9_entry_legacykey0000000001': jsonEncode(
            legacyEntry(
              recordedAt: '2026-09-28T05:00:00.000Z',
              records: [
                {'student_id': 2501, 'status': 'LATE'},
              ],
            ),
          ),
        });
        final api = FakeApi();
        final sync = await openCached(api);
        final old = sync.entries.single;
        expect(old.state, SubmissionState.failed);
        expect(sync.canResubmit(old), isFalse);
        expect(
          describeSubmission(old),
          contains('take attendance for this lesson again'),
        );
        final fresh = await sync.save(
          lessonId: 402,
          date: monday,
          records: marks(25),
        );
        await sync.sync(manual: true);
        expect(fresh.state, SubmissionState.synced);
        expect(api.syncPosts, 1);
        sync.dispose();
      },
    );

    test(
      'valid legacy pending record is retried with its original key',
      () async {
        SharedPreferences.setMockInitialValues({
          'teacher_attendance_v1_7_9_entry_legacykey0000000001': jsonEncode(
            legacyEntry(recordedAt: '2026-09-28T05:00:00.000Z'),
          ),
        });
        final api = FakeApi();
        final sync = await open(api);
        expect(sync.entries.single.state, SubmissionState.pendingSync);
        await sync.sync(manual: true);
        final sent = jsonDecode(api.posts.single['body'])['submissions'][0];
        expect(sent['idempotency_key'], 'legacykey0000000001');
        expect(sync.entries.single.state, SubmissionState.synced);
        sync.dispose();
      },
    );

    test('never Synced without a matching accepted receipt', () async {
      String keyOf(Map b) => b['submissions'][0]['idempotency_key'] as String;
      final responses = <http.Response Function(Map)>[
        (_) => http.Response('{"results":[]}', 200),
        (_) => http.Response(
          jsonEncode({
            'results': [
              {'idempotency_key': 'someone-else-key-01', 'outcome': 'accepted'},
            ],
          }),
          200,
        ),
        (b) => http.Response(
          jsonEncode({
            'results': [
              {'idempotency_key': keyOf(b)},
            ],
          }),
          200,
        ),
        (b) => http.Response(
          jsonEncode({
            'results': [
              {'idempotency_key': keyOf(b), 'outcome': 'queued'},
            ],
          }),
          200,
        ),
        (_) => http.Response('{"ok":true}', 200),
        (_) => http.Response('not json', 200),
        (_) => http.Response('{}', 502),
      ];
      final api = FakeApi();
      final sync = await openCached(api);
      final e = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      for (final r in responses) {
        api.rawSyncResponse = r;
        await sync.sync(manual: true);
        expect(e.state, SubmissionState.pendingSync);
      }
      api.rawSyncResponse = null;
      await sync.sync(manual: true);
      expect(e.state, SubmissionState.synced);
      final keys = api.posts
          .map((p) => keyOf(jsonDecode(p['body'] as String) as Map))
          .toSet();
      expect(keys, {e.key}, reason: 'every retry reused the same key');
      sync.dispose();
    });

    test(
      'record left "syncing" by a killed app is resent after restart',
      () async {
        final api = FakeApi();
        final first = await openCached(api);
        final e = await first.save(
          lessonId: 402,
          date: monday,
          records: marks(25),
        );
        first.dispose();
        final prefs = await SharedPreferences.getInstance();
        final key = '${first.prefix}entry_${e.key}';
        final stored =
            jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
        await prefs.setString(key, jsonEncode({...stored, 'state': 'syncing'}));

        final restarted = await open(api);
        expect(restarted.entries.single.state, SubmissionState.pendingSync);
        expect(restarted.pendingCount, 1);
        await restarted.sync(manual: true);
        expect(restarted.entries.single.state, SubmissionState.synced);
        restarted.dispose();
      },
    );
  });

  group('endpoint contract', () {
    Future<void> autoRetry(TeacherAttendanceSync s) async {
      s.wake(); // what a connectivity change / app resume does
      await pumpEventQueue();
      while (s.busy) {
        await pumpEventQueue();
      }
    }

    test('submissions POST only to /api/teacher/attendance/sync', () async {
      final api = FakeApi()..outcomeFor = (_) => 'pending approval';
      final sync = await openCached(api);
      await sync.save(lessonId: 402, date: monday, records: marks(25));
      await sync.sync(manual: true); // POST, then history GET
      await sync.sync(manual: true); // history GET again

      final posts = api.log.where((r) => r.method == 'POST').toList();
      expect(posts, hasLength(1));
      expect(posts.single.url, apiUrl('api/teacher/attendance/sync'));
      expect(posts.single.url.path, '/api/teacher/attendance/sync');
      expect(posts.single.url.query, isEmpty);

      final history = api.log
          .where((r) => r.url.path == '/api/teacher/attendance/submissions')
          .toList();
      expect(history, isNotEmpty, reason: 'review status is polled');
      expect(history.map((r) => r.method).toSet(), {'GET'});
      expect(
        api.log.where(
          (r) => r.method != 'GET' && r.url.path.contains('submissions'),
        ),
        isEmpty,
        reason: 'the history URL is never used for POST',
      );
      for (final r in api.log) {
        expect(r.url.path, startsWith('/api/teacher/'));
        expect(r.url.path, isNot(contains('/api/api')));
        expect(r.url.path, isNot(contains('//')));
      }
      expect(TeacherAttendanceSync.syncEndpoint, 'attendance/sync');
      expect(TeacherAttendanceSync.historyEndpoint, 'attendance/submissions');
      sync.dispose();
    });

    test(
      'POST body has only contract fields and Bearer JSON headers',
      () async {
        final api = FakeApi();
        final sync = await openCached(api);
        await sync.save(lessonId: 402, date: monday, records: marks(25));
        await sync.sync(manual: true);
        final post = api.log.singleWhere((r) => r.method == 'POST');
        expect(post.headers['Authorization'], 'Bearer jwt');
        expect(post.headers['Content-Type'], startsWith('application/json'));
        final body = jsonDecode(post.body) as Map;
        expect(body.keys, ['submissions']);
        final item = (body['submissions'] as List).single as Map;
        const allowed = {
          'idempotency_key',
          'class_id',
          'timetable_id',
          'academic_year_id',
          'date',
          'school_id',
          'teacher_id',
          'recorded_at',
          'records',
        };
        expect(allowed.containsAll(item.keys), isTrue, reason: '${item.keys}');
        for (final required in [
          'idempotency_key',
          'class_id',
          'timetable_id',
          'academic_year_id',
          'date',
          'records',
        ]) {
          expect(item.containsKey(required), isTrue, reason: required);
        }
        for (final r in item['records'] as List) {
          expect((r as Map).keys.toSet(), {'student_id', 'status'});
          expect(['PRESENT', 'ABSENT'], contains(r['status']));
        }
        sync.dispose();
      },
    );

    // code, state after failure, retried automatically, banner health
    for (final c in [
      (404, SubmissionState.pendingSync, true, SyncHealth.endpointMissing),
      (401, SubmissionState.pendingSync, false, SyncHealth.authRequired),
      (403, SubmissionState.pendingSync, true, SyncHealth.accessDenied),
      (409, SubmissionState.failed, false, SyncHealth.online),
      (422, SubmissionState.failed, false, SyncHealth.online),
      (429, SubmissionState.pendingSync, true, SyncHealth.serverError),
      (500, SubmissionState.pendingSync, true, SyncHealth.serverError),
    ]) {
      final (code, state, transient, health) = c;
      test(
        'HTTP $code on sync: ${transient ? 'kept and retried' : 'kept, no automatic retry'}',
        () async {
          final api = FakeApi()
            ..postStatus = code
            ..postBody = '{"message":"server said $code"}';
          final sync = await openCached(api);
          final e = await sync.save(
            lessonId: 402,
            date: monday,
            records: marks(25),
          );
          final payload = jsonEncode(e.payload);
          await sync.sync();
          expect(api.log.where((r) => r.method == 'POST'), hasLength(1));
          expect(e.state, state);
          expect(sync.health, health);
          expect(sync.entries, hasLength(1));
          expect(jsonEncode(e.payload), payload, reason: 'payload untouched');
          if (code == 409 || code == 422) {
            expect(describeSubmission(e), contains('server said $code'));
          }

          api.postStatus = null; // server recovers
          await autoRetry(sync);
          final posts = api.log.where((r) => r.method == 'POST').length;
          expect(posts, transient ? 2 : 1);
          expect(
            e.state,
            transient ? SubmissionState.synced : state,
            reason: 'permanent failures wait for the teacher',
          );
          if (!transient) {
            await sync.sync(manual: true); // Retry / Sync Now
            expect(e.state, SubmissionState.synced);
          }
          final keys = api.posts
              .map((p) => jsonDecode(p['body'] as String)['submissions'][0])
              .map((s) => s['idempotency_key'])
              .toSet();
          expect(keys, {e.key}, reason: 'same key on every retry');
          sync.dispose();
        },
      );
    }

    test('404 leaves queued records intact across restart', () async {
      final api = FakeApi()..postStatus = 404;
      final sync = await openCached(api);
      api.online = false;
      final a = await sync.save(
        lessonId: 402,
        date: monday,
        records: marks(25),
      );
      api.online = true;
      await sync.sync(manual: true);
      expect(sync.health, SyncHealth.endpointMissing);
      expect(sync.pendingCount, 1);
      expect(sync.attentionCount, 0);
      expect(sync.message, contains('stays on this device'));
      expect(sync.message, isNot(contains('/api/')));
      expect(sync.message, isNot(contains('404')));
      sync.dispose();
      final restarted = await open(api);
      expect(restarted.entries.single.key, a.key);
      expect(restarted.entries.single.state, SubmissionState.pendingSync);
      restarted.dispose();
    });

    test('pressing Sync Now repeatedly sends each record once', () async {
      final api = FakeApi()..holdPost = Completer<void>();
      final sync = await openCached(api);
      await sync.save(lessonId: 402, date: monday, records: marks(25));
      final presses = [for (var i = 0; i < 5; i++) sync.sync(manual: true)];
      await pumpEventQueue();
      api.holdPost!.complete();
      await Future.wait(presses);
      while (sync.busy) {
        await pumpEventQueue();
      }
      for (var i = 0; i < 3; i++) {
        await sync.sync(manual: true);
      }
      expect(api.log.where((r) => r.method == 'POST'), hasLength(1));
      expect(sync.entries.single.state, SubmissionState.synced);
      sync.dispose();
    });
  });
}
