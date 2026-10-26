import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/attendance/attendance_review_controller.dart';
import 'package:kobac/school_admin/attendance/attendance_review_view.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/school_admin/attendance/take_attendance_controller.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/attendance_review_service.dart';
import 'package:kobac/services/attendance_service.dart';

Map<String, dynamic> audit(
  int id, {
  String status = 'pending approval',
  String? reason = 'LATE_SERVER_RECEIPT',
  String? decision,
  String? note,
  String? receiptWindow,
}) => {
  'id': id,
  'schoolId': 7,
  'teacherId': 70,
  'userId': 9,
  'idempotencyKey': 'key-$id-000000000000',
  'payloadHash': 'h',
  'payload': {
    'class_id': 25,
    'timetable_id': 402,
    'academic_year_id': 2,
    'date': '2026-09-28',
    'recorded_at': '2026-09-28T05:10:00.000Z',
    'records': [
      {'student_id': 1001, 'status': 'PRESENT'},
      {'student_id': 1002, 'status': 'ABSENT'},
    ],
  },
  'lessonSnapshot': {
    'timetable_id': 402,
    'subject_id': 3,
    'day': 'MON',
    'start_time': '08:00:00',
    'end_time': '08:40:00',
    'receipt_window': ?receiptWindow,
  },
  'status': status,
  'reason': reason,
  'recordedAt': '2026-09-28T05:10:00.000Z',
  'receivedAt': '2026-09-28T09:00:00.000Z',
  'syncedAt': null,
  'decidedAt': null,
  'decidedByUserId': null,
  'decision': decision,
  'decisionNote': note,
};

/// In-memory School Admin backend for the review contract.
class ReviewApi {
  final requests = <http.Request>[];
  final rows = <Map<String, dynamic>>[audit(17)];
  int? listStatus;
  int? decisionStatus;
  String decisionBody = '';
  String outcomeOverride = '';
  bool attendanceExists = false;

  /// false = current backend (note optional on approve, required on reject);
  /// true = an outdated backend that answers 400 to note-free approvals.
  bool requireNote = false;
  Completer<void>? decisionGate;
  Completer<void>? listGate;
  Map<String, dynamic> policy = {
    'timezone': 'Africa/Mogadishu',
    'grace_minutes': 30,
  };
  int pageSize = 100;

  List<http.Request> where(String method, String pathEnd) => requests
      .where((r) => r.method == method && r.url.path.endsWith(pathEnd))
      .toList();

  Future<http.Response> call(http.Request r) async {
    requests.add(r);
    final p = r.url.path;
    if (p.endsWith('/school-admin/attendance/submissions') &&
        r.method == 'GET') {
      if (listGate != null) await listGate!.future;
      if (listStatus != null) return _json({'message': 'boom'}, listStatus!);
      final status = r.url.queryParameters['status'];
      final after = int.tryParse(r.url.queryParameters['after_id'] ?? '') ?? 0;
      final match = rows
          .where((x) => status == null || x['status'] == status)
          .where((x) => (x['id'] as int) > after)
          .toList();
      final page = match.take(pageSize).toList();
      return _json({
        'submissions': page,
        'next_after_id': page.length == pageSize ? page.last['id'] : null,
      });
    }
    final decide = RegExp(r'/submissions/(\d+)/decision$').firstMatch(p);
    if (decide != null && r.method == 'POST') {
      if (decisionGate != null) await decisionGate!.future;
      if (decisionStatus != null) {
        return _json({'message': 'refused'}, decisionStatus!);
      }
      final id = int.parse(decide[1]!);
      final body = jsonDecode(r.body) as Map;
      final note = body['note'];
      if ((requireNote || body['decision'] == 'reject') &&
          (note is! String || note.trim().isEmpty)) {
        return _json({
          'message':
              'decision (approve/reject) and note (1..1000 characters) are required',
        }, 400);
      }
      final row = rows.firstWhere((x) => x['id'] == id);
      final approve = body['decision'] == 'approve';
      final outcome = outcomeOverride.isNotEmpty
          ? outcomeOverride
          : approve
          ? (attendanceExists ? 'conflict' : 'accepted')
          : 'rejected';
      row
        ..['status'] = outcome
        ..['decision'] = body['decision']
        ..['decisionNote'] = body['note']
        ..['reason'] = outcome == 'conflict'
            ? 'ATTENDANCE_ALREADY_RECORDED'
            : (approve ? 'ADMIN_APPROVED' : 'ADMIN_REJECTED');
      return _json({
        'idempotency_key': row['idempotencyKey'],
        'submission_id': id,
        'outcome': outcome,
        'reason': row['reason'],
        'received_at': row['receivedAt'],
        'synced_at': null,
        'decision': body['decision'],
      });
    }
    if (p.endsWith('/school-admin/attendance/settings')) {
      if (r.method == 'PUT') {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        if ((body['grace_minutes'] as int) > 1440) {
          return _json({
            'message':
                'timezone and grace_minutes (integer 0..1440) are required',
          }, 400);
        }
        policy = body;
      }
      return _json(policy);
    }
    if (p.endsWith('/school-admin/attendance/register')) {
      return _json({
        'academic_year': {'id': 2, 'name': '2026-2027'},
        'class': {'id': 25, 'name': 'Form 3'},
        'date': '2026-09-28',
        'lesson': {
          'timetable_id': 402,
          'day': 'MON',
          'start_time': '08:00:00',
          'end_time': '08:40:00',
          'subject': {'id': 3, 'name': 'Mathematics'},
          'teacher': {'id': 70, 'full_name': 'Ahmed Yusuf'},
        },
        'attendance_recorded': attendanceExists,
        'summary': {},
        'students': [
          for (final s in [
            (1001, 'Amina Ali'),
            (1002, 'Bashir Omar'),
            (1003, 'Caho Nur'),
          ])
            {
              'student_id': s.$1,
              'student_name': s.$2,
              'emis_number': 'EMIS-${s.$1}',
              'enrolled': true,
              'status': attendanceExists ? 'PRESENT' : null,
            },
        ],
      });
    }
    if (p.endsWith('/school-admin/teachers')) {
      return _json({
        'teachers': [
          {
            'id': 70,
            'full_name': 'Ahmed Yusuf',
            'fullName': 'Ahmed Yusuf',
            'email': 'a@x.so',
          },
        ],
      });
    }
    if (p.endsWith('/school-admin/classes')) {
      return _json({
        'classes': [
          {'id': 25, 'name': 'Form 3'},
        ],
      });
    }
    if (p.endsWith('/school-admin/subjects')) {
      return _json({
        'subjects': [
          {'id': 3, 'name': 'Mathematics'},
        ],
      });
    }
    return _json({'message': 'Route not found'}, 404);
  }

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

Future<T> withApi<T>(ReviewApi api, Future<T> Function() body) =>
    http.runWithClient(body, () => MockClient(api.call));

void main() {
  group('AttendanceReviewService contract', () {
    test(
      'lists with backend status values and follows next_after_id',
      () async {
        final api = ReviewApi()
          ..pageSize = 2
          ..rows.addAll([audit(18), audit(19), audit(20, status: 'accepted')]);
        final res = await withApi(
          api,
          () => AttendanceReviewService().listAll(
            status: SubmissionStatus.pending,
          ),
        );
        final items =
            (res as AttendanceSuccess<List<AttendanceSubmissionAudit>>).data;
        expect(items.map((e) => e.id), [17, 18, 19]);
        final gets = api.where('GET', '/attendance/submissions');
        expect(gets.first.url.path, '/api/school-admin/attendance/submissions');
        expect(gets.map((r) => r.url.queryParameters['status']).toSet(), {
          'pending approval',
        });
        expect(gets.map((r) => r.url.queryParameters['after_id']), [
          null,
          '18',
        ]);

        final a = items.first;
        expect(a.teacherId, 70);
        expect(a.classId, 25);
        expect(a.timetableId, 402);
        expect(a.date, '2026-09-28');
        expect(a.subjectId, 3);
        expect(a.startTime, '08:00:00');
        expect(a.receivedAt, DateTime.utc(2026, 9, 28, 9));
        expect(a.presentCount, 1);
        expect(a.absentCount, 1);
        expect(a.isPending, isTrue);
      },
    );

    test(
      'decision sends exactly {decision, note} to the decision URL',
      () async {
        final api = ReviewApi();
        final res = await withApi(
          api,
          () => AttendanceReviewService().decide(
            submissionId: 17,
            decision: 'approve',
            note: '  Verified paper register  ',
          ),
        );
        final post = api.where('POST', '/decision').single;
        expect(
          post.url.path,
          '/api/school-admin/attendance/submissions/17/decision',
        );
        expect(post.headers['Content-Type'], startsWith('application/json'));
        expect(jsonDecode(post.body), {
          'decision': 'approve',
          'note': 'Verified paper register',
        });
        final outcome = (res as AttendanceSuccess<DecisionOutcome>).data;
        expect(outcome.succeededFor('approve'), isTrue);
      },
    );

    test('conflict outcome is not a successful approval', () {
      const o = DecisionOutcome(
        outcome: 'conflict',
        decision: 'approve',
        reason: 'SCHEDULE_CHANGED',
      );
      expect(o.succeededFor('approve'), isFalse);
      expect(
        const DecisionOutcome(
          outcome: 'already synced',
          decision: 'approve',
        ).succeededFor('approve'),
        isTrue,
      );
      expect(
        const DecisionOutcome(
          outcome: 'rejected',
          decision: 'reject',
        ).succeededFor('reject'),
        isTrue,
      );
      expect(
        const DecisionOutcome(
          outcome: 'accepted',
          decision: 'approve',
        ).succeededFor('reject'),
        isFalse,
      );
    });

    for (final (code, text) in [
      (401, 'session has expired'),
      (403, 'Only School Admins'),
      (404, 'not found for your school'),
      (409, 'already decided differently'),
      (422, 'refused'),
      (500, 'Nothing was changed'),
    ]) {
      test('HTTP $code on decision gives a clear message', () async {
        final api = ReviewApi()..decisionStatus = code;
        final res = await withApi(
          api,
          () => AttendanceReviewService().decide(
            submissionId: 17,
            decision: 'reject',
            note: 'x',
          ),
        );
        expect(res, isA<AttendanceError>());
        expect((res as AttendanceError).statusCode, code);
        expect(res.message, contains(text));
      });
    }

    test(
      'network failure on a decision is never reported as success',
      () async {
        final res = await http.runWithClient(
          () => AttendanceReviewService().decide(
            submissionId: 17,
            decision: 'approve',
            note: 'x',
          ),
          () => MockClient((_) async => throw http.ClientException('offline')),
        );
        expect(res, isA<AttendanceError>());
        expect((res as AttendanceError).message, contains('not confirmed'));
      },
    );

    test('policy GET/PUT use {timezone, grace_minutes}', () async {
      final api = ReviewApi();
      await withApi(api, () async {
        final got = await AttendanceReviewService().getPolicy();
        expect(
          (got as AttendanceSuccess<AttendancePolicy>).data.graceMinutes,
          30,
        );
        final put = await AttendanceReviewService().setPolicy(
          const AttendancePolicy(timezone: 'Africa/Nairobi', graceMinutes: 45),
        );
        expect(
          (put as AttendanceSuccess<AttendancePolicy>).data.graceMinutes,
          45,
        );
      });
      final put = api.where('PUT', '/attendance/settings').single;
      expect(put.url.path, '/api/school-admin/attendance/settings');
      expect(jsonDecode(put.body), {
        'timezone': 'Africa/Nairobi',
        'grace_minutes': 45,
      });
    });
  });

  group('AttendanceReviewController (legacy review)', () {
    test('lists only legacy pending submissions', () async {
      final api = ReviewApi()
        ..rows.addAll([
          audit(30, status: 'accepted', reason: null, receiptWindow: 'late'),
          audit(31, status: 'rejected', reason: 'ADMIN_REJECTED'),
          audit(32, reason: 'UNVERIFIABLE_SCHEDULE'),
        ]);
      final c = AttendanceReviewController();
      await withApi(api, () => c.load());
      expect(c.items.map((e) => e.id), [17, 32]);
      expect(c.pendingCount, 2);
      final statuses = api
          .where('GET', '/attendance/submissions')
          .map((r) => r.url.queryParameters['status'])
          .toSet();
      expect(statuses, {'pending approval'});
      c.dispose();
    });

    test('a decision is sent once even if requested repeatedly', () async {
      final api = ReviewApi()..decisionGate = Completer<void>();
      var reloadedReports = 0;
      final c = AttendanceReviewController(
        onAttendanceChanged: () => reloadedReports++,
      );
      await withApi(api, () async {
        await c.load();
        final a = c.items.single;
        final first = c.decide(a, approve: true);
        final second = await c.decide(a, approve: true);
        expect(second.success, isFalse);
        expect(c.deciding, contains(17));
        api.decisionGate!.complete();
        final result = await first;
        expect(result.success, isTrue);
      });
      expect(api.where('POST', '/decision'), hasLength(1));
      expect(reloadedReports, 1, reason: 'reports reload from the server');
      expect(c.items, isEmpty);
      expect(c.pendingCount, 0, reason: 'the Legacy tab can now hide');
      expect(
        api.rows.single['status'],
        'accepted',
        reason: 'history is kept on the server',
      );
      c.dispose();
    });

    test('approval never sends a note, even if one is passed', () async {
      final api = ReviewApi();
      final c = AttendanceReviewController();
      await withApi(api, () async {
        await c.load();
        final r = await c.decide(c.items.single, approve: true, note: 'x');
        expect(r.success, isTrue);
      });
      final body = jsonDecode(api.where('POST', '/decision').single.body);
      expect(body, {'decision': 'approve'});
      c.dispose();
    });

    test('rejection without a reason is refused locally', () async {
      final api = ReviewApi();
      final c = AttendanceReviewController();
      await withApi(api, () async {
        await c.load();
        final r = await c.decide(c.items.single, approve: false, note: '   ');
        expect(r.success, isFalse);
      });
      expect(api.where('POST', '/decision'), isEmpty);
      c.dispose();
    });

    test('approval conflict is a failure and does not reload reports', () async {
      final api = ReviewApi()..attendanceExists = true;
      var reloadedReports = 0;
      final c = AttendanceReviewController(
        onAttendanceChanged: () => reloadedReports++,
      );
      await withApi(api, () async {
        await c.load();
        final r = await c.decide(c.items.single, approve: true);
        expect(r.success, isFalse);
        expect(r.message, contains('already exists'));
      });
      expect(reloadedReports, 0);
      c.dispose();
    });

    test('500 keeps the submission pending for another attempt', () async {
      final api = ReviewApi()..decisionStatus = 500;
      final c = AttendanceReviewController();
      await withApi(api, () async {
        await c.load();
        final r = await c.decide(c.items.single, approve: true);
        expect(r.success, isFalse);
        expect(r.settled, isFalse);
      });
      expect(c.items.single.isPending, isTrue);
      c.dispose();
    });

    test('outdated server demanding a note: item stays pending', () async {
      final api = ReviewApi()..requireNote = true;
      final c = AttendanceReviewController();
      await withApi(api, () async {
        await c.load();
        final r = await c.decide(c.items.single, approve: true);
        expect(r.success, isFalse);
        expect(r.settled, isFalse);
        expect(r.message, contains('did not accept the approval'));
      });
      expect(
        jsonDecode(api.where('POST', '/decision').single.body),
        {'decision': 'approve'},
        reason: 'no note is ever invented',
      );
      c.dispose();
    });
  });

  group('Legacy Review UI', () {
    const sizes = {
      'Android 390x844': (Size(390, 844), false),
      'mobile PWA 360x640': (Size(360, 640), false),
      'tablet 768x1024': (Size(768, 1024), false),
      'desktop PWA 1280x800': (Size(1280, 800), true),
    };

    Future<void> pumpView(
      WidgetTester tester,
      AttendanceReviewController c,
      (Size, bool) size,
    ) async {
      tester.view.physicalSize = size.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AttendanceReviewView(controller: c, isDesktop: size.$2),
            ),
          ),
        ),
      );
    }

    Future<void> tapVisible(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    void expectNoSyncOrFilters() {
      expect(find.text('Sync'), findsNothing);
      expect(find.text('Sync Submissions'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Approve Attendance'), findsNothing);
      expect(find.textContaining('Pending Approval'), findsNothing);
      expect(find.textContaining('requires a note'), findsNothing);
    }

    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('$name: legacy item, detail and note-free approval', (
        tester,
      ) async {
        final api = ReviewApi()..listGate = Completer<void>();
        final c = AttendanceReviewController();
        await http.runWithClient(() async {
          await pumpView(tester, c, size);
          await tester.pump();
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          api.listGate!.complete();
          await tester.pumpAndSettle();

          expect(find.text('Legacy Review'), findsOneWidget);
          expect(find.text(kLegacyReviewIntro), findsOneWidget);
          expect(find.text('Mathematics · Form 3'), findsOneWidget);
          expect(find.text('Ahmed Yusuf'), findsOneWidget);
          expect(
            find.textContaining('2 students · 1 present · 1 absent'),
            findsOneWidget,
          );
          expect(find.textContaining('earlier rules'), findsWidgets);
          expect(find.text('LEGACY PENDING'), findsOneWidget);
          expectNoSyncOrFilters();

          await tapVisible(
            tester,
            find.byKey(const ValueKey('review-open-17')),
          );
          await tester.scrollUntilVisible(
            find.textContaining('Caho Nur'),
            200,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('submission-detail-17')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          expect(find.text('Amina Ali'), findsOneWidget);
          expect(find.text('Bashir Omar'), findsOneWidget);
          expect(find.textContaining('teacher device claim'), findsOneWidget);

          await tapVisible(
            tester,
            find.byKey(const ValueKey('review-approve')),
          );
          expect(find.text('Record this legacy submission?'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('approve-dialog')),
              matching: find.byType(TextField),
            ),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey('review-confirm')));
          await tester.pumpAndSettle();

          final posts = api.where('POST', '/decision');
          expect(posts, hasLength(1));
          expect(jsonDecode(posts.single.body), {'decision': 'approve'});
          expect(find.byType(TextField), findsNothing);
          expect(find.textContaining('now in the register'), findsOneWidget);
          expect(find.text('No legacy submissions waiting'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }, () => MockClient(api.call));
        c.dispose();
      });

      testWidgets('$name: rejection requires a reason', (tester) async {
        final api = ReviewApi();
        final c = AttendanceReviewController();
        await http.runWithClient(() async {
          await pumpView(tester, c, size);
          await tester.pumpAndSettle();
          await tapVisible(
            tester,
            find.byKey(const ValueKey('review-open-17')),
          );
          await tapVisible(tester, find.byKey(const ValueKey('review-reject')));
          await tester.tap(find.byKey(const ValueKey('review-confirm')));
          await tester.pumpAndSettle();
          expect(find.text('A rejection reason is required.'), findsOneWidget);
          await tester.enterText(
            find.byKey(const ValueKey('review-note')),
            'no',
          );
          await tester.tap(find.byKey(const ValueKey('review-confirm')));
          await tester.pumpAndSettle();
          expect(find.textContaining('meaningful reason'), findsOneWidget);
          expect(api.where('POST', '/decision'), isEmpty);
          await tester.enterText(
            find.byKey(const ValueKey('review-note')),
            'Wrong register',
          );
          await tester.tap(find.byKey(const ValueKey('review-confirm')));
          await tester.pumpAndSettle();
          final body = jsonDecode(api.where('POST', '/decision').single.body);
          expect(body, {'decision': 'reject', 'note': 'Wrong register'});
          expect(
            find.textContaining('Rejected. No attendance was recorded.'),
            findsOneWidget,
          );
          expect(
            api.rows.single['decisionNote'],
            'Wrong register',
            reason: 'reason preserved for the teacher and the audit',
          );
          expect(tester.takeException(), isNull);
        }, () => MockClient(api.call));
        c.dispose();
      });
    }

    testWidgets('repeated Approve clicks send one request', (tester) async {
      final api = ReviewApi()..decisionGate = Completer<void>();
      final c = AttendanceReviewController();
      await http.runWithClient(() async {
        await pumpView(tester, c, sizes.values.last);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('review-open-17')));
        await tapVisible(tester, find.byKey(const ValueKey('review-approve')));
        await tester.tap(find.byKey(const ValueKey('review-confirm')));
        await tester.pump(const Duration(seconds: 1));
        final approve = find.byKey(const ValueKey('review-approve'));
        expect(tester.widget<ElevatedButton>(approve).onPressed, isNull);
        await tester.tap(approve, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 1));
        expect(find.byKey(const ValueKey('approve-dialog')), findsNothing);
        api.decisionGate!.complete();
        await tester.pumpAndSettle();
        expect(api.where('POST', '/decision'), hasLength(1));
      }, () => MockClient(api.call));
      c.dispose();
    });

    testWidgets('Cancel sends nothing', (tester) async {
      final api = ReviewApi();
      final c = AttendanceReviewController();
      await http.runWithClient(() async {
        await pumpView(tester, c, sizes.values.first);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('review-open-17')));
        await tapVisible(tester, find.byKey(const ValueKey('review-approve')));
        await tester.tap(find.byKey(const ValueKey('review-cancel')));
        await tester.pumpAndSettle();
        expect(api.where('POST', '/decision'), isEmpty);
        expect(find.text('LEGACY PENDING'), findsOneWidget);
      }, () => MockClient(api.call));
      c.dispose();
    });

    testWidgets('empty list and list error with retry', (tester) async {
      final api = ReviewApi()..rows.clear();
      final c = AttendanceReviewController();
      await http.runWithClient(() async {
        await pumpView(tester, c, sizes.values.first);
        await tester.pumpAndSettle();
        expect(find.text('No legacy submissions waiting'), findsOneWidget);

        api.listStatus = 500;
        await tapVisible(tester, find.byKey(const ValueKey('review-refresh')));
        expect(find.text('Could not load submissions'), findsOneWidget);
        expect(find.textContaining('Nothing was changed'), findsOneWidget);
        api
          ..listStatus = null
          ..rows.add(audit(17));
        await tapVisible(tester, find.text('Retry').first);
        expect(find.text('Mathematics · Form 3'), findsOneWidget);
      }, () => MockClient(api.call));
      c.dispose();
    });

    testWidgets('403 list error explains School Admin access', (tester) async {
      final api = ReviewApi()..listStatus = 403;
      final c = AttendanceReviewController();
      await http.runWithClient(() async {
        await pumpView(tester, c, sizes.values.last);
        await tester.pumpAndSettle();
        expect(find.textContaining('Only School Admins'), findsOneWidget);
      }, () => MockClient(api.call));
      c.dispose();
    });

    testWidgets(
      'existing attendance warns before approval; conflict is not success',
      (tester) async {
        final api = ReviewApi()..attendanceExists = true;
        final c = AttendanceReviewController();
        await http.runWithClient(() async {
          await pumpView(tester, c, sizes.values.last);
          await tester.pumpAndSettle();
          await tapVisible(
            tester,
            find.byKey(const ValueKey('review-open-17')),
          );
          expect(
            find.textContaining('already exists in the register'),
            findsOneWidget,
          );
          await tapVisible(
            tester,
            find.byKey(const ValueKey('review-approve')),
          );
          await tester.tap(find.byKey(const ValueKey('review-confirm')));
          await tester.pumpAndSettle();
          expect(find.textContaining('Not approved'), findsOneWidget);
          expect(find.textContaining('now in the register'), findsNothing);
        }, () => MockClient(api.call));
        c.dispose();
      },
    );

    testWidgets('409 on decision is shown and the list refreshes', (
      tester,
    ) async {
      final api = ReviewApi()..decisionStatus = 409;
      final c = AttendanceReviewController();
      await http.runWithClient(() async {
        await pumpView(tester, c, sizes.values.first);
        await tester.pumpAndSettle();
        final before = api.where('GET', '/attendance/submissions').length;
        await tapVisible(tester, find.byKey(const ValueKey('review-open-17')));
        await tapVisible(tester, find.byKey(const ValueKey('review-reject')));
        await tester.enterText(
          find.byKey(const ValueKey('review-note')),
          'Duplicate lesson register',
        );
        await tester.tap(find.byKey(const ValueKey('review-confirm')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('already decided differently'),
          findsOneWidget,
        );
        expect(
          api.where('GET', '/attendance/submissions').length,
          greaterThan(before),
        );
      }, () => MockClient(api.call));
      c.dispose();
    });
  });

  group('Attendance screen navigation', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      TakeAttendanceController take,
      Size size,
      bool desktop,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<AcademicYearsProvider>.value(
          value: _Years(),
          // Desktop renders inside the web shell's Scaffold.
          child: MaterialApp(
            home: Scaffold(
              body: AdminAttendanceScreen(
                controller: take,
                desktopOverride: desktop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    const layouts = [
      ('phone', Size(390, 844), false),
      ('tablet', Size(768, 1024), false),
      ('desktop', Size(1280, 800), true),
    ];

    for (final (name, size, desktop) in layouts) {
      testWidgets('$name: no approval tab, badge or Sync without legacy items', (
        tester,
      ) async {
        final api = ReviewApi()..rows.clear();
        api.rows.add(
          audit(40, status: 'accepted', reason: null, receiptWindow: 'late'),
        );
        final take = TakeAttendanceController(
          now: () => DateTime(2026, 10, 5, 9),
        );
        await http.runWithClient(() async {
          await pumpScreen(tester, take, size, desktop);
          expect(
            find.byKey(const ValueKey('attendance-tab-review')),
            findsNothing,
          );
          expect(find.byKey(const ValueKey('review-badge')), findsNothing);
          expect(find.text('Sync'), findsNothing);
          expect(find.text('Sync Submissions'), findsNothing);
          expect(find.text('Legacy Review'), findsNothing);
          for (final tab in ['take', 'records', 'reports']) {
            expect(
              find.byKey(ValueKey('attendance-tab-$tab')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
        }, () => MockClient(api.call));
        take.dispose();
      });

      testWidgets('$name: Legacy Review tab while legacy items exist', (
        tester,
      ) async {
        final api = ReviewApi()..rows.add(audit(18));
        final take = TakeAttendanceController(
          now: () => DateTime(2026, 10, 5, 9),
        );
        await http.runWithClient(() async {
          await pumpScreen(tester, take, size, desktop);
          final tab = find.byKey(const ValueKey('attendance-tab-review'));
          expect(tab, findsOneWidget);
          expect(find.byKey(const ValueKey('review-badge')), findsNothing);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('submission-17')), findsOneWidget);
          expect(find.byKey(const ValueKey('submission-18')), findsOneWidget);
          expect(tester.takeException(), isNull);
        }, () => MockClient(api.call));
        take.dispose();
      });
    }

    testWidgets('a remembered Legacy tab never becomes the landing tab', (
      tester,
    ) async {
      final api = ReviewApi()..rows.clear();
      final take = TakeAttendanceController(now: () => DateTime(2026, 10, 5, 9))
        ..lastView = AdminAttendanceView.review.index;
      await http.runWithClient(() async {
        await pumpScreen(tester, take, const Size(390, 844), false);
        expect(
          find.byKey(const ValueKey('attendance-tab-review')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('attendance-review')), findsNothing);
        expect(take.lastView, AdminAttendanceView.take.index);
      }, () => MockClient(api.call));
      take.dispose();
    });

    testWidgets('attendance policy is reachable from the header', (
      tester,
    ) async {
      final api = ReviewApi()..rows.clear();
      final take = TakeAttendanceController(now: () => DateTime(2026, 10, 5, 9));
      await http.runWithClient(() async {
        await pumpScreen(tester, take, const Size(1280, 800), true);
        await tester.tap(find.byKey(const ValueKey('attendance-policy')));
        await tester.pumpAndSettle();
        expect(find.textContaining('accepted without approval'), findsOneWidget);
        expect(find.textContaining('Default: 30 minutes'), findsOneWidget);
        expect(find.widgetWithText(TextField, '30'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('policy-grace')),
          '2000',
        );
        await tester.tap(find.byKey(const ValueKey('policy-save')));
        await tester.pumpAndSettle();
        expect(find.textContaining('0 to 1440'), findsOneWidget);
        expect(api.where('PUT', '/settings'), isEmpty);

        await tester.enterText(find.byKey(const ValueKey('policy-grace')), '45');
        await tester.tap(find.byKey(const ValueKey('policy-save')));
        await tester.pumpAndSettle();
        expect(jsonDecode(api.where('PUT', '/settings').single.body), {
          'timezone': 'Africa/Mogadishu',
          'grace_minutes': 45,
        });
      }, () => MockClient(api.call));
      take.dispose();
    });
  });
}

class _Years extends AcademicYearsProvider {
  _Years() {
    final y = AcademicYear(
      id: 2,
      name: '2026-2027',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2027, 6, 30),
      isActive: true,
    );
    years = [y];
    activeYear = y;
  }
  @override
  Future<void> ensureLoaded() async {}
}
