import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/attendance/take_attendance_controller.dart';
import 'package:kobac/school_admin/attendance/take_attendance_view.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/school_admin/pages/school_admin_screen.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/web_admin_shell.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/auth_provider.dart';

import 'admin_attendance_take_test.dart' show AttendanceFixture;

/// One School Admin Attendance feature, three presentations:
///   A. Android/mobile app layout
///   B. Flutter Web at phone width (same responsive branch as A)
///   C. Flutter Web desktop inside the admin shell
/// Every flow below runs unchanged on each of them.

final _year = AcademicYear(
  id: 2,
  name: '2026-2027',
  startDate: DateTime(2026, 9, 1),
  endDate: DateTime(2027, 6, 30),
  isActive: true,
);

class _Years extends AcademicYearsProvider {
  _Years() {
    years = [_year];
    activeYear = _year;
  }
  @override
  Future<void> ensureLoaded() async {}
}

TakeAttendanceController _controller() =>
    TakeAttendanceController(now: () => DateTime(2026, 10, 5, 9));

class _Platform {
  final String name;
  final Size size;
  final bool desktop;
  const _Platform(this.name, this.size, this.desktop);
}

const _platforms = [
  _Platform('A. Android app 390x844', Size(390, 844), false),
  _Platform('B. mobile web 360x640', Size(360, 640), false),
  _Platform('B. mobile web 360x800', Size(360, 800), false),
  _Platform('B. mobile web 412x915', Size(412, 915), false),
  _Platform('tablet web 800x1000', Size(800, 1000), false),
  _Platform('C. desktop 1024', Size(1024, 768), true),
  _Platform('C. desktop 1280', Size(1280, 800), true),
  _Platform('C. desktop 1366', Size(1366, 768), true),
  _Platform('C. desktop 1440', Size(1440, 900), true),
  _Platform('C. desktop 1920', Size(1920, 1080), true),
];

/// Desktop pages render inside a shell-sized frame (fixed 260px sidebar +
/// 64px top bar) so widths match the real content area.
Widget _frame(_Platform p, Widget screen) {
  final body = p.desktop
      ? Row(
          children: [
            const SizedBox(width: 260, key: ValueKey('fake-sidebar')),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 64, key: ValueKey('fake-topbar')),
                  Expanded(child: screen),
                ],
              ),
            ),
          ],
        )
      : screen;
  return ChangeNotifierProvider<AcademicYearsProvider>.value(
    value: _Years(),
    child: MaterialApp(home: Scaffold(body: body)),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _chooseClass(WidgetTester tester, String name) async {
  await _tap(tester, find.byType(DropdownButtonFormField<int>).at(1));
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final p in _platforms) {
    testWidgets('${p.name}: same Attendance flows 1-7', (tester) async {
      tester.view.physicalSize = p.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final f = AttendanceFixture();
      final c = _controller();
      await http.runWithClient(() async {
        await tester.pumpWidget(_frame(
          p,
          AdminAttendanceScreen(
            controller: c,
            embedBodyOnly: p.desktop,
            desktopOverride: p.desktop,
          ),
        ));
        await tester.pumpAndSettle();

        // Same header + two functions everywhere; never the legacy page.
        expect(find.byKey(const ValueKey('attendance-title')), findsOneWidget);
        expect(find.text(kAttendanceSubtitle), findsOneWidget);
        expect(find.byKey(const ValueKey('attendance-tab-take')), findsOneWidget);
        expect(find.byKey(const ValueKey('attendance-tab-records')), findsOneWidget);
        expect(find.text('Academic Year'), findsOneWidget);
        expect(find.text('Select a class and date to view timetable lessons.'), findsOneWidget);
        expect(find.textContaining('No attendance records for this date'), findsNothing);

        // FLOW 1: year/date/class -> lessons.
        await _chooseClass(tester, 'Form 3');
        expect(find.byKey(const ValueKey('lesson-401')), findsOneWidget);
        expect(find.byKey(const ValueKey('lesson-402')), findsOneWidget);
        expect(find.text('Not Taken'), findsOneWidget);
        expect(find.text('Recorded'), findsOneWidget);

        // FLOW 2: Not Taken lesson -> students load unmarked, no error.
        await _tap(tester, find.byKey(const ValueKey('lesson-401')));
        expect(find.byKey(const ValueKey('register-error')), findsNothing);
        expect(find.text('Not marked'), findsNWidgets(3));
        // Desktop: table; phone: cards. Same controls either way.
        expect(find.text('Student Name'), p.desktop ? findsOneWidget : findsNothing);
        expect(find.byType(AdminTableHeader), p.desktop ? findsOneWidget : findsNothing);

        // FLOW 3: Mark All Present -> some Absent -> Save once.
        await _tap(tester, find.byKey(const ValueKey('attendance-mark-all-present')));
        await _tap(tester, find.byKey(const ValueKey('mark-absent-1001')));
        await _tap(tester, find.byKey(const ValueKey('mark-absent-1003')));
        await _tap(tester, find.byKey(const ValueKey('attendance-save')));
        expect(f.where('PUT', '/attendance/register'), hasLength(1));
        expect(find.text('Attendance saved successfully.'), findsOneWidget);
        Finder chip(String label, String value) => find.descendant(
          of: find.byKey(ValueKey('summary-$label')),
          matching: find.text(value),
        );
        for (final label in ['Total Students', 'Recorded', 'Present', 'Absent', 'Late', 'Attendance']) {
          expect(find.byKey(ValueKey('summary-$label')), findsOneWidget);
        }
        expect(chip('Present', '1'), findsOneWidget);
        expect(chip('Absent', '2'), findsOneWidget);

        // FLOW 4: reload the now-Recorded lesson -> statuses persist.
        await c.loadRegister();
        await tester.pumpAndSettle();
        expect(c.currentMark(1001), 'ABSENT');
        expect(c.currentMark(1002), 'PRESENT');
        expect(find.text('Not Taken'), findsNothing);

        // FLOW 5: edit one -> save -> reload.
        await _tap(tester, find.byKey(const ValueKey('mark-present-1001')));
        await _tap(tester, find.byKey(const ValueKey('attendance-save')));
        expect(find.text('Attendance changes saved successfully.'), findsOneWidget);
        expect(
          jsonDecode(f.where('PUT', '/attendance/register').last.body)['records'],
          [
            {'student_id': 1001, 'status': 'PRESENT'},
          ],
        );
        await c.loadRegister();
        await tester.pumpAndSettle();
        expect(c.currentMark(1001), 'PRESENT');

        // FLOW 6: PDF reachable and requested once.
        final print = find.byKey(const ValueKey('attendance-print'));
        expect(print, findsOneWidget);
        await _tap(tester, print);
        expect(f.where('GET', '/attendance/register/print'), hasLength(1));

        // FLOW 7: Attendance Records still works; Take state survives.
        await _tap(tester, find.byKey(const ValueKey('attendance-tab-records')));
        expect(find.text('Bashir Omar'), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);
        await _tap(tester, find.byKey(const ValueKey('attendance-tab-take')));
        expect(c.timetableId, 401);
        expect(find.byKey(const ValueKey('attendance-lesson-info')), findsOneWidget);

        // One scroll area holds title, filters, lessons, register and Save.
        final scroll = find.byKey(const ValueKey('attendance-scroll'));
        expect(scroll, findsOneWidget);
        for (final key in ['attendance-title', 'lesson-401', 'attendance-save']) {
          expect(find.descendant(of: scroll, matching: find.byKey(ValueKey(key))), findsOneWidget);
        }
        expect(find.byType(Scrollable), findsOneWidget, reason: 'no nested vertical scroll');
        await tester.drag(scroll, const Offset(0, -4000));
        await tester.pumpAndSettle();
        if (p.desktop) {
          // Shell chrome is outside the page scroll and never moves.
          expect(tester.getTopLeft(find.byKey(const ValueKey('fake-topbar'))).dy, 0);
          expect(tester.getTopLeft(find.byKey(const ValueKey('fake-sidebar'))).dx, 0);
        }
        expect(tester.takeException(), isNull);
      }, () => MockClient(f.call));
      c.dispose();
    });
  }

  testWidgets('crossing the breakpoint keeps the same Attendance session state', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = AttendanceFixture();
    final session = _controller();
    final desktop = ValueNotifier<bool>(true);
    await http.runWithClient(() async {
      // Mirrors SchoolAdminScreen: one scope above two unrelated subtrees.
      await tester.pumpWidget(ChangeNotifierProvider<AcademicYearsProvider>.value(
        value: _Years(),
        child: MaterialApp(
          home: AttendanceSessionScope(
            controller: session,
            child: ValueListenableBuilder<bool>(
              valueListenable: desktop,
              builder: (_, isDesktop, _) => isDesktop
                  ? Scaffold(
                      key: const ValueKey('desktop-shell'),
                      body: AdminAttendanceScreen(embedBodyOnly: true, desktopOverride: true),
                    )
                  : const Scaffold(
                      key: ValueKey('mobile-shell'),
                      body: AdminAttendanceScreen(desktopOverride: false),
                    ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await _chooseClass(tester, 'Form 3');
      await _tap(tester, find.byKey(const ValueKey('lesson-402')));
      await _tap(tester, find.byKey(const ValueKey('mark-absent-1001')));
      expect(find.text('Student Name'), findsOneWidget);

      desktop.value = false; // resize to phone width
      await tester.pumpAndSettle();
      expect(find.text('Student Name'), findsNothing, reason: 'mobile presentation');
      expect(session.classId, 25);
      expect(session.timetableId, 402);
      expect(session.currentMark(1001), 'ABSENT', reason: 'unsaved mark kept');
      expect(find.byKey(const ValueKey('attendance-lesson-info')), findsOneWidget);
      expect(find.text('Unsaved change'), findsOneWidget);

      desktop.value = true; // and back
      await tester.pumpAndSettle();
      expect(find.text('Student Name'), findsOneWidget);
      expect(session.currentMark(1001), 'ABSENT');
      expect(f.where('GET', '/attendance/register'), hasLength(1),
          reason: 'no reload, no reset when the layout switches');
    }, () => MockClient(f.call));
    desktop.dispose();
    session.dispose();
  });

  testWidgets('desktop sidebar "Student Attendance" opens the updated feature', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = AttendanceFixture();
    await http.runWithClient(() async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<AcademicYearsProvider>.value(value: _Years()),
        ],
        child: const MaterialApp(home: WebAdminShell()),
      ));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Attendance').first);
      await _tap(tester, find.text('Student Attendance'));
      expect(find.byType(AdminAttendanceScreen), findsOneWidget);
      expect(find.byType(TakeAttendanceView), findsOneWidget);
      expect(find.byKey(const ValueKey('attendance-tab-records')), findsOneWidget);
      expect(find.textContaining('No attendance records for this date'), findsNothing);
    }, () => MockClient(f.call));
  });

  testWidgets('SchoolAdminScreen provides one Attendance session above the layout switch', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = AttendanceFixture();
    await http.runWithClient(() async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<AcademicYearsProvider>.value(value: _Years()),
        ],
        child: const MaterialApp(home: SchoolAdminScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(AttendanceSessionScope), findsOneWidget);
    }, () => MockClient(f.call));
  });
}
