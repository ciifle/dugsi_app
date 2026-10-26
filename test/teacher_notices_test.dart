import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/teacher_notices_service.dart';
import 'package:kobac/teacher/pages/notices_screen.dart';
import 'package:kobac/teacher/pages/teacher_drawer.dart';
import 'package:kobac/teacher/widgets/teacher_web_sidebar.dart';

Map<String, dynamic> notice(
  int id,
  String title,
  String created, {
  int school = 7,
}) => {
  'id': id,
  'schoolId': school,
  'title': title,
  'content': '$title — full content of notice $id.',
  'createdAt': created,
  'updatedAt': created,
};

/// GET /api/teacher/notices as the backend returns it: {notices: [...]},
/// id DESC, scoped to the token's school.
class NoticesApi {
  final requests = <http.Request>[];
  List<Map<String, dynamic>> notices = [
    notice(3, 'Exam timetable published', '2026-10-20T07:30:00.000Z'),
    notice(2, 'Staff meeting Thursday', '2026-10-18T09:00:00.000Z'),
  ];
  int status = 200;
  String? rawBody;
  Completer<void>? gate;

  Future<http.Response> call(http.Request r) async {
    requests.add(r);
    if (gate != null) await gate!.future;
    if (r.url.path != '/api/teacher/notices') {
      return http.Response('{"message":"Route not found"}', 404);
    }
    if (status != 200) return http.Response('{"message":"x"}', status);
    // Like Express: UTF-8 JSON. No charset header, to prove UTF-8 decoding.
    return http.Response.bytes(
      utf8.encode(rawBody ?? jsonEncode({'notices': notices})),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  setUp(() => ApiClient().setToken('teacher-jwt'));
  tearDown(() => ApiClient().setToken(null));

  group('TeacherNoticesService', () {
    test(
      'GETs /api/teacher/notices with the teacher token; newest first',
      () async {
        final api = NoticesApi()
          ..notices = [
            notice(1, 'Old', '2026-09-01T08:00:00.000Z'),
            notice(5, 'Newest', '2026-10-21T08:00:00.000Z'),
            notice(4, 'Middle', '2026-10-01T08:00:00.000Z'),
          ];
        final res = await http.runWithClient(
          () => TeacherNoticesService().list(schoolId: 7),
          () => MockClient(api.call),
        );
        final r = api.requests.single;
        expect(r.method, 'GET');
        expect(r.url, apiUrl('api/teacher/notices'));
        expect(r.headers['Authorization'], 'Bearer teacher-jwt');
        final list = (res as TeacherNoticesLoaded).notices;
        expect(list.map((n) => n.title), ['Newest', 'Middle', 'Old']);
        expect(list.first.content, contains('full content'));
        expect(list.first.createdAt, DateTime.utc(2026, 10, 21, 8));
      },
    );

    test('another school\'s notices are never returned', () async {
      final api = NoticesApi()
        ..notices = [
          notice(
            9,
            'Other school secret',
            '2026-10-22T08:00:00.000Z',
            school: 8,
          ),
          notice(3, 'Ours', '2026-10-20T08:00:00.000Z'),
        ];
      final res = await http.runWithClient(
        () => TeacherNoticesService().list(schoolId: 7),
        () => MockClient(api.call),
      );
      final loaded = res as TeacherNoticesLoaded;
      expect(loaded.notices.map((n) => n.title), ['Ours']);
      expect(loaded.foreignDropped, 1);
    });

    for (final (code, text) in [
      (401, 'session has expired'),
      (403, 'not allowed'),
      (404, 'not available'),
      (500, 'could not load'),
    ]) {
      test('HTTP $code is reported, not shown as empty', () async {
        final api = NoticesApi()..status = code;
        final res = await http.runWithClient(
          () => TeacherNoticesService().list(),
          () => MockClient(api.call),
        );
        expect(res, isA<TeacherNoticesFailed>());
        expect((res as TeacherNoticesFailed).message, contains(text));
      });
    }

    test('malformed body and network failure are errors', () async {
      final api = NoticesApi()..rawBody = '<html>proxy</html>';
      final bad = await http.runWithClient(
        () => TeacherNoticesService().list(),
        () => MockClient(api.call),
      );
      expect(bad, isA<TeacherNoticesFailed>());
      final offline = await http.runWithClient(
        () => TeacherNoticesService().list(),
        () => MockClient((_) async => throw http.ClientException('offline')),
      );
      expect((offline as TeacherNoticesFailed).message, contains('connection'));
    });
  });

  group('TeacherNoticesScreen', () {
    const sizes = {
      'Android 390x844': (Size(390, 844), false),
      'mobile PWA 360x640': (Size(360, 640), false),
      'desktop PWA 1280x800': (Size(1280, 800), true),
    };

    Future<void> pump(
      WidgetTester tester,
      (Size, bool) size, {
      Key? key,
    }) async {
      tester.view.physicalSize = size.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final screen = TeacherNoticesScreen(
        key: key,
        embedBodyOnly: size.$2,
        showAppBar: false,
        schoolId: 7,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
    }

    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('$name: loading, list, detail', (tester) async {
        final api = NoticesApi()..gate = Completer<void>();
        await http.runWithClient(() async {
          await pump(tester, size);
          await tester.pump();
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          api.gate!.complete();
          await tester.pumpAndSettle();

          expect(find.text('Exam timetable published'), findsOneWidget);
          expect(find.text('Staff meeting Thursday'), findsOneWidget);
          final first = tester.getTopLeft(
            find.text('Exam timetable published'),
          );
          final second = tester.getTopLeft(find.text('Staff meeting Thursday'));
          expect(first.dy, lessThan(second.dy), reason: 'newest first');

          await tester.tap(find.text('Exam timetable published'));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('notice-detail-3')), findsOneWidget);
          expect(find.textContaining('Published'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('notice-detail-3')),
              matching: find.text(
                'Exam timetable published — full content of notice 3.',
              ),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }, () => MockClient(api.call));
      });
    }

    testWidgets('empty state', (tester) async {
      final api = NoticesApi()..notices = [];
      await http.runWithClient(() async {
        await pump(tester, sizes.values.first);
        await tester.pumpAndSettle();
        expect(find.text('No notices yet'), findsOneWidget);
      }, () => MockClient(api.call));
    });

    testWidgets(
      'error with retry, then refresh shows a newly published notice',
      (tester) async {
        final api = NoticesApi()..status = 500;
        await http.runWithClient(() async {
          await pump(tester, sizes.values.last);
          await tester.pumpAndSettle();
          expect(find.textContaining('could not load notices'), findsOneWidget);
          api.status = 200;
          await tester.tap(find.text('Retry'));
          await tester.pumpAndSettle();
          expect(find.text('Exam timetable published'), findsOneWidget);

          api.notices = [
            notice(4, 'Holiday on Monday', '2026-10-24T07:00:00.000Z'),
            ...api.notices,
          ];
          await tester.tap(find.byKey(const ValueKey('notices-refresh')));
          await tester.pumpAndSettle();
          expect(find.text('Holiday on Monday'), findsOneWidget);
        }, () => MockClient(api.call));
      },
    );

    testWidgets('reopening the page loads notices again from the server', (
      tester,
    ) async {
      final api = NoticesApi();
      await http.runWithClient(() async {
        await pump(tester, sizes.values.first, key: const ValueKey('first'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        api.notices = [notice(6, 'Reopened', '2026-10-25T07:00:00.000Z')];
        await pump(tester, sizes.values.first, key: const ValueKey('second'));
        await tester.pumpAndSettle();
        expect(find.text('Reopened'), findsOneWidget);
        expect(api.requests, hasLength(2));
      }, () => MockClient(api.call));
    });

    testWidgets('other school notices are not displayed', (tester) async {
      final api = NoticesApi()
        ..notices = [
          notice(
            9,
            'Other school secret',
            '2026-10-22T08:00:00.000Z',
            school: 8,
          ),
          notice(3, 'Ours', '2026-10-20T08:00:00.000Z'),
        ];
      await http.runWithClient(() async {
        await pump(tester, sizes.values.first);
        await tester.pumpAndSettle();
        expect(find.text('Ours'), findsOneWidget);
        expect(find.text('Other school secret'), findsNothing);
      }, () => MockClient(api.call));
    });
  });

  group('Teacher navigation', () {
    testWidgets('desktop sidebar has a Notices entry', (tester) async {
      String? opened;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: TeacherWebSidebar(
                selectedPage: 'dashboard',
                onNavigate: (key, {arguments}) => opened = key,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Notices'));
      expect(opened, 'notices');
    });

    testWidgets('mobile drawer has a Notices entry', (tester) async {
      String? opened;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: TeacherDrawer(onNavigateRoot: (label) => opened = label),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final entry = find.text('Notices');
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(opened, 'Notices');
    });
  });
}
