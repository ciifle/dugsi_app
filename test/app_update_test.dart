import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kobac/services/app_update/app_update_service.dart';
import 'package:kobac/services/teacher_attendance_sync.dart';
import 'package:kobac/shared/widgets/app_update_banner.dart';

/// Stands in for the browser: [announce] = a new service worker took over,
/// [applied] counts page reloads.
class FakeUpdates implements AppUpdatePlatform {
  VoidCallback? _ready;
  int applied = 0;
  int checks = 0;
  void announce() => _ready?.call();

  @override
  void start(VoidCallback onUpdateReady) => _ready = onUpdateReady;
  @override
  Future<void> check() async => checks++;
  @override
  void apply() => applied++;
  @override
  void stop() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    AppUpdateService service,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            AppUpdateBanner(service: service, child: child!),
        home: const Scaffold(body: Text('Attendance')),
      ),
    );
  }

  for (final (name, size) in [
    ('phone', Size(360, 640)),
    ('tablet', Size(768, 1024)),
    ('desktop', Size(1440, 900)),
  ]) {
    testWidgets('$name: prompt appears only when a new version is ready', (
      tester,
    ) async {
      final platform = FakeUpdates();
      final service = AppUpdateService(platform: platform)..start();
      await pump(tester, service, size);
      expect(find.byKey(const ValueKey('app-update-banner')), findsNothing);

      platform.announce();
      await tester.pump();
      expect(find.byKey(const ValueKey('app-update-banner')), findsOneWidget);
      expect(find.textContaining('A new version of Dugsi'), findsOneWidget);
      expect(find.textContaining('unsent attendance stays'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('app-update-reload')));
      await tester.pump();
      expect(platform.applied, 1);
      expect(tester.takeException(), isNull);
      service.dispose();
    });
  }

  testWidgets('Later hides the prompt for this page load', (tester) async {
    final platform = FakeUpdates();
    final service = AppUpdateService(platform: platform)..start();
    await pump(tester, service, const Size(390, 844));
    platform
      ..announce()
      ..announce();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('app-update-later')));
    await tester.pump();
    expect(find.byKey(const ValueKey('app-update-banner')), findsNothing);
    expect(platform.applied, 0);
    service.dispose();
  });

  test('Android/VM build never reports a web update', () async {
    final service = AppUpdateService()..start();
    await service.check();
    expect(service.updateReady, isFalse);
    service.apply(); // no-op off the web
    service.dispose();
  });

  testWidgets('applying an update keeps the offline attendance queue', (
    tester,
  ) async {
    const entryKey = 'teacher_attendance_v1_7_9_entry_queuedkey0000000001';
    final entry = jsonEncode({
      'v': 2,
      'lesson': '25|2026-09-28|08:00|3',
      'label': 'Math · Class 25 · 08:00',
      'captured_at': '2026-09-28T05:30:00.000Z',
      'state': 'pendingSync',
      'payload': {
        'idempotency_key': 'queuedkey0000000001',
        'academic_year_id': 2,
        'class_id': 25,
        'timetable_id': 402,
        'date': '2026-09-28',
        'recorded_at': '2026-09-28T05:30:00.000Z',
        'records': [
          {'student_id': 2501, 'status': 'PRESENT'},
        ],
      },
    });
    SharedPreferences.setMockInitialValues({entryKey: entry});
    final platform = FakeUpdates();
    final service = AppUpdateService(platform: platform)..start();
    await pump(tester, service, const Size(390, 844));
    platform.announce();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('app-update-reload')));
    await tester.pump();
    expect(platform.applied, 1);

    // After the reload the same teacher still has the unsent record.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(entryKey), entry);
    final sync = TeacherAttendanceSync(
      schoolId: 7,
      userId: 9,
      token: () => 'jwt',
    );
    await tester.runAsync(() => sync.initialize(automatic: false));
    expect(sync.entries.single.key, 'queuedkey0000000001');
    expect(sync.entries.single.state, SubmissionState.pendingSync);
    expect(sync.pendingCount, 1);
    sync.dispose();
    service.dispose();
  });

  test('web update code never clears storage, caches or workers', () {
    final source = File(
      'lib/services/app_update/app_update_platform_web.dart',
    ).readAsStringSync();
    // Strip comments: only executable code matters.
    final code = source
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    for (final forbidden in [
      'unregister',
      'caches',
      'localStorage',
      'sessionStorage',
      'indexedDB',
      'deleteDatabase',
      'clear(',
    ]) {
      expect(code, isNot(contains(forbidden)), reason: forbidden);
    }
    expect(code, contains('location.reload()'));
  });

  test('server rules revalidate the files that pick the build', () {
    final rules = File('web/.htaccess').readAsStringSync();
    for (final file in [
      r'index\.html',
      r'flutter_service_worker\.js',
      r'flutter_bootstrap\.js',
      r'main\.dart\.js',
      r'version\.json',
    ]) {
      expect(rules, contains(file));
    }
    expect(rules, contains('no-cache'));
  });
}
