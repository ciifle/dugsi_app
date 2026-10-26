import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kobac/services/teacher_attendance_sync.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = TeacherAttendanceSync.weekdayCode(DateTime.now());
  var online = true;
  var outcome = 'accepted';
  String? reason;
  final client = MockClient((request) async {
    if (!online) throw http.ClientException('Failed host lookup');
    final path = request.url.path;
    if (path.endsWith('/dashboard')) {
      return http.Response(
        jsonEncode({
          'teacher': {'id': 70, 'schoolId': 7},
          'assignedClasses': [
            {'id': 25, 'name': 'Class A'},
          ],
          'assignments': [
            {'id': 1, 'class_id': 25, 'class_name': 'Class A', 'subject_id': 3},
          ],
          'timetables': [
            {
              'id': 402,
              'classId': 25,
              'subjectId': 3,
              'day': today,
              'startTime': '08:00',
              'endTime': '09:00',
              'subjectName': 'Math',
            },
          ],
          'academicYear': {'id': 2},
        }),
        200,
      );
    }
    if (path.endsWith('/attendance/sync')) {
      final submissions = jsonDecode(request.body)['submissions'] as List;
      return http.Response(
        jsonEncode({
          'results': [
            for (final s in submissions)
              {
                'idempotency_key': s['idempotency_key'],
                'submission_id': 1,
                'outcome': outcome,
                'reason': reason,
              },
          ],
        }),
        200,
      );
    }
    if (path.endsWith('/attendance/settings')) {
      return http.Response(
        jsonEncode({'timezone': 'Africa/Mogadishu', 'grace_minutes': 30}),
        200,
      );
    }
    return http.Response(
      jsonEncode({
        'students': [
          {'id': 1001, 'name': 'Amina', 'emis_number': 'S1'},
        ],
      }),
      200,
    );
  });

  Future<TeacherAttendanceSync> controller({required bool cached}) async {
    online = true;
    outcome = 'accepted';
    reason = null;
    final sync = TeacherAttendanceSync(
      schoolId: 7,
      userId: 9,
      token: () => 'jwt',
      client: client,
    );
    await sync.initialize(automatic: false);
    if (cached) await sync.refreshCache();
    return sync;
  }

  Future<void> pump(
    WidgetTester tester,
    TeacherAttendanceSync sync,
    bool desktop,
  ) async {
    tester.view.physicalSize = desktop
        ? const Size(1440, 1000)
        : const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeacherAttendanceScreen(
            controller: sync,
            embedBodyOnly: desktop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = find.byIcon(Icons.save_rounded);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(save, 300, scrollable: list);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.runAsync(() => Future.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sync Now'),
      -300,
      scrollable: list,
    );
  }

  for (final desktop in [false, true]) {
    final layout = desktop ? 'desktop PWA' : 'Android/mobile PWA';

    testWidgets('offline save from cached lesson at $layout width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final sync = await tester.runAsync(() => controller(cached: true));
      await pump(tester, sync!, desktop);
      expect(find.textContaining('Grace period: 30 minutes'), findsOneWidget);
      expect(find.textContaining('no approval needed'), findsOneWidget);
      expect(find.textContaining('Admin Review'), findsNothing);
      expect(find.text('Sync Now'), findsOneWidget);
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.textContaining('Amina'),
        200,
        scrollable: list,
      );
      await tester.scrollUntilVisible(
        find.text('Sync Now'),
        -200,
        scrollable: list,
      );
      // The single lesson for today is preselected; nothing blocks saving.
      expect(find.textContaining('Math'), findsWidgets);
      expect(find.text('Select the scheduled lesson.'), findsNothing);

      online = false;
      await tapSave(tester);
      expect(find.text('Saved Offline'), findsOneWidget);
      expect(find.textContaining('Saved on this device'), findsOneWidget);

      await tester.runAsync(() => sync.sync(manual: true));
      await tester.pumpAndSettle();
      expect(find.text('Pending Sync'), findsOneWidget);
      expect(find.text('1 pending sync'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Offline.'), findsOneWidget);
      online = true;
      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      // The tap's sync runs in the test zone; let it progress frame by frame.
      for (var i = 0; i < 20 && sync.busy; i++) {
        await tester.runAsync(() => Future.delayed(Duration.zero));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(sync.busy, isFalse);
      expect(find.text('All attendance sent'), findsOneWidget);
      expect(find.text('Synchronized'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Bad state'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      sync.dispose();
    });

    testWidgets('HTTP 200 conflict is shown as Conflict at $layout width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final sync = await tester.runAsync(() => controller(cached: true));
      outcome = 'conflict';
      reason = 'ATTENDANCE_ALREADY_RECORDED';
      await pump(tester, sync!, desktop);
      await tapSave(tester);
      await tester.runAsync(() => sync.sync(manual: true));
      await tester.pumpAndSettle();
      expect(find.text('Conflict'), findsOneWidget);
      expect(find.text('Synchronized'), findsNothing);
      expect(find.text('All attendance sent'), findsNothing);
      expect(find.textContaining('already recorded'), findsOneWidget);
      expect(find.textContaining('Admin Review'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      sync.dispose();
    });

    testWidgets('no cached schedule explains recovery at $layout width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final sync = await tester.runAsync(() => controller(cached: false));
      await pump(tester, sync!, desktop);
      expect(
        find.textContaining('No lesson schedule is stored on this device'),
        findsOneWidget,
      );
      expect(find.textContaining('tap Sync Now'), findsWidgets);
      await tapSave(tester);
      expect(sync.entries, isEmpty, reason: 'save is disabled');
      expect(find.textContaining('Bad state'), findsNothing);

      // Recovery: Sync Now while online downloads the schedule.
      await tester.runAsync(() => sync.sync(manual: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('Amina'), findsOneWidget);
      expect(find.textContaining('No lesson schedule'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      sync.dispose();
    });
  }
}
