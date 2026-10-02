import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:kobac/models/attendance_report.dart';
import 'package:kobac/school_admin/attendance/attendance_reports_controller.dart';
import 'package:kobac/school_admin/attendance/attendance_reports_view.dart';
import 'package:kobac/school_admin/attendance/take_attendance_controller.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/attendance_diagnostics.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/pdf_file_result.dart';

import 'admin_attendance_take_test.dart' show AttendanceFixture;

// ---------------------------------------------------------------------------
// Backend report fixtures shaped exactly like attendanceReport.service.js.
// ---------------------------------------------------------------------------

http.Response _json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _pdf(String name) => http.Response.bytes(
  utf8.encode('%PDF-1.4 report'),
  200,
  headers: {
    'content-type': 'application/pdf',
    'content-disposition': 'attachment; filename="$name"',
  },
);

Map<String, Object?> _counts(int rec, int p, int a, int l, num? pct) => {
  'recorded_sessions': rec,
  'present_count': p,
  'absent_count': a,
  'late_count': l,
  'other_count': 0,
  'attendance_percentage': pct,
};

class ReportsFixture extends AttendanceFixture {
  bool classNoData = false;
  bool studentNoData = false;
  bool enrollmentMissing = false;
  Map<String, Object?>? reportError;

  Map<String, Object?> classReport(Map<String, String> q) => {
    'report_type': 'class',
    'academic_year': {'id': 2, 'name': '2026-2027'},
    'class': {'id': 25, 'name': 'Form 3'},
    'period': {'start_date': q['start_date'], 'end_date': q['end_date']},
    'summary': {
      'total_students': 2,
      'students_with_records': classNoData ? 0 : 1,
      'students_without_records': classNoData ? 2 : 1,
      'lessons_recorded': classNoData ? 0 : 10,
      'days_with_attendance': classNoData ? 0 : 5,
      'first_recorded_date': classNoData ? null : '2026-09-07',
      'last_recorded_date': classNoData ? null : '2026-09-30',
      ...classNoData ? _counts(0, 0, 0, 0, null) : _counts(10, 8, 1, 1, 80),
    },
    'has_attendance': !classNoData,
    'message': classNoData ? 'No attendance was recorded during this period.' : null,
    'students': [
      {
        'student_id': 1001,
        'student_name': 'Ahmed Ali',
        'emis_number': 'EMIS001',
        'enrollment_status': 'active',
        ...classNoData ? _counts(0, 0, 0, 0, null) : _counts(10, 8, 1, 1, 80),
      },
      {
        'student_id': 1002,
        'student_name': 'Bashir Omar',
        'emis_number': 'EMIS002',
        'enrollment_status': 'active',
        ..._counts(0, 0, 0, 0, null),
      },
    ],
  };

  Map<String, Object?> studentReport(Map<String, String> q) {
    Map<String, Object?> h(int id, String date, String time, String period,
            String subject, String teacher, String status) =>
        {
          'attendance_id': id,
          'date': date,
          'time': time,
          'period': period,
          'subject': {'id': id, 'name': subject},
          'teacher': {'id': id, 'full_name': teacher},
          'class': {'id': 25, 'name': 'Form 3'},
          'status': status,
        };
    final history = studentNoData
        ? <Object>[]
        : [
            h(1, '2026-09-07', '08:00:00', 'Period 1', 'Mathematics', 'Ahmed Yusuf', 'PRESENT'),
            h(2, '2026-09-07', '08:40:00', 'Period 2', 'English', 'Mohamed Ali', 'ABSENT'),
            h(3, '2026-09-08', '09:20:00', 'Period 3', 'Science', 'Hodan Farah', 'LATE'),
            h(4, '2026-09-09', '08:00:00', 'Period 1', 'Mathematics', 'Ahmed Yusuf', 'PRESENT'),
          ];
    return {
      'report_type': 'student',
      'academic_year': {'id': 2, 'name': '2026-2027'},
      'student': {'id': 1002, 'name': 'Bashir Omar', 'emis_number': 'EMIS002'},
      'enrollment': {'class_id': 25, 'class_name': 'Form 3', 'status': 'active'},
      'period': {'start_date': q['start_date'], 'end_date': q['end_date']},
      'summary': {
        ...studentNoData ? _counts(0, 0, 0, 0, null) : _counts(4, 2, 1, 1, 50),
        'subjects_recorded': studentNoData ? 0 : 3,
        'days_with_attendance': studentNoData ? 0 : 3,
      },
      'has_attendance': !studentNoData,
      'message': studentNoData ? 'No attendance was recorded during this period.' : null,
      'history': history,
    };
  }

  @override
  Future<http.Response> call(http.Request r) async {
    final path = r.url.path;
    final q = r.url.queryParameters;
    if (path.contains('/attendance/reports/')) {
      requests.add(r);
      if (reportError != null) return _json(reportError!, 400);
      if (path.endsWith('/reports/class')) return _json(classReport(q));
      if (path.endsWith('/reports/class/print')) {
        return _pdf('class-attendance-form-3-${q['start_date']}-${q['end_date']}.pdf');
      }
      if (enrollmentMissing) {
        return _json({
          'message': 'Student enrollment not found for this academic year',
          'code': 'ENROLLMENT_NOT_FOUND',
        }, 404);
      }
      if (path.endsWith('/print')) return _pdf('student-attendance-bashir-omar.pdf');
      return _json(studentReport(q));
    }
    if (path.endsWith('/school-admin/students')) {
      requests.add(r);
      final s = (q['search'] ?? '').toLowerCase();
      final all = [
        {'id': 1001, 'studentName': 'Ahmed Ali', 'emisNumber': 'EMIS001', 'className': 'Form 3'},
        {'id': 1002, 'studentName': 'Bashir Omar', 'emisNumber': 'EMIS002', 'className': 'Form 3'},
      ];
      final hits = all
          .where((e) =>
              '${e['studentName']}'.toLowerCase().contains(s) ||
              '${e['emisNumber']}'.toLowerCase().contains(s))
          .toList();
      return _json({'students': hits, 'total': hits.length});
    }
    return super.call(r);
  }
}

// ---------------------------------------------------------------------------

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

DateTime _now() => DateTime(2026, 10, 5, 9);

TakeAttendanceController _session() => TakeAttendanceController(now: _now);

Future<T> _with<T>(ReportsFixture f, Future<T> Function() body) =>
    http.runWithClient(body, () => MockClient(f.call));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpReports(
  WidgetTester tester,
  TakeAttendanceController c, {
  required Size size,
  required bool desktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AcademicYearsProvider>.value(
    value: _Years(),
    child: MaterialApp(
      home: Scaffold(
        body: AdminAttendanceScreen(
          controller: c,
          embedBodyOnly: desktop,
          desktopOverride: desktop,
          initialView: AdminAttendanceView.reports,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _chooseReportClass(WidgetTester tester) async {
  await _tap(tester, find.byType(DropdownButtonFormField<int>).at(1));
  await tester.tap(find.text('Form 3').last);
  await tester.pumpAndSettle();
}

Finder _chip(String prefix, String label, String value) => find.descendant(
  of: find.byKey(ValueKey('$prefix-$label')),
  matching: find.text(value),
);

void main() {
  late List<String> logs;
  setUp(() {
    logs = [];
    attendanceLogSink = logs.add;
    attendanceDiagnosticsEnabled = true;
  });
  tearDown(() {
    attendanceLogSink = (m) => debugPrint(m, wrapWidth: 1024);
    attendanceDiagnosticsEnabled = kDebugMode;
    ApiClient().setToken(null);
  });

  group('models', () {
    test('class report parses backend fields; null % is "—", never 0%', () {
      final r = ClassAttendanceReport.tryParse(
        ReportsFixture().classReport({'start_date': '2026-09-01', 'end_date': '2026-09-30'}),
      )!;
      expect(r.className, 'Form 3');
      expect(r.period.label, '2026-09-01 to 2026-09-30');
      expect(r.summary.counts.recordedSessions, 10);
      expect(r.summary.counts.percentageLabel, '80%');
      final a = r.students.first.counts, b = r.students.last.counts;
      expect([a.recordedSessions, a.present, a.absent, a.late], [10, 8, 1, 1]);
      expect(a.percentageLabel, '80%');
      expect([b.recordedSessions, b.present, b.absent, b.late], [0, 0, 0, 0]);
      expect(b.percentage, isNull);
      expect(b.percentageLabel, '—');
      expect(formatAttendancePercentage(84.38), '84.38%');
      expect(formatAttendancePercentage(66.7), '66.7%');
      expect(ClassAttendanceReport.tryParse({'success': true}), isNull);
    });

    test('student report keeps backend history order and LATE status', () {
      final r = StudentAttendanceReport.tryParse(
        ReportsFixture().studentReport({'start_date': '2026-09-01', 'end_date': '2026-09-30'}),
      )!;
      expect(r.studentName, 'Bashir Omar');
      expect(r.className, 'Form 3');
      expect(r.history.map((h) => h.date), ['2026-09-07', '2026-09-07', '2026-09-08', '2026-09-09']);
      expect(r.history.map((h) => h.status), ['PRESENT', 'ABSENT', 'LATE', 'PRESENT']);
      expect(r.history.map((h) => h.teacherName).toSet(), hasLength(3));
      expect(r.counts.percentageLabel, '50%');
    });
  });

  group('controller + service', () {
    test('class report: exact query, no school_id; PDF uses the shown filters', () async {
      final f = ReportsFixture();
      final c = _session();
      final rep = c.reports;
      AttendanceResult<PdfFileResult>? pdf;
      await _with(f, () async {
        rep.setYears([_year], _year);
        await rep.loadClasses();
        expect(rep.startYmd, '2026-10-01', reason: 'This Month default');
        expect(rep.endYmd, '2026-10-05');
        rep.selectClass(25);
        await rep.loadClassReport();
        pdf = await rep.downloadClassPdf();
      });
      final get = f.where('GET', '/reports/class').single;
      expect(get.url.queryParameters, {
        'academic_year_id': '2',
        'class_id': '25',
        'start_date': '2026-10-01',
        'end_date': '2026-10-05',
      });
      final print = f.where('GET', '/reports/class/print').single;
      expect(print.url.queryParameters, get.url.queryParameters, reason: 'preview == PDF');
      expect(print.headers['Accept'], 'application/pdf');
      final file = (pdf as AttendanceSuccess<PdfFileResult>).data;
      expect(file.filename, 'class-attendance-form-3-2026-10-01-2026-10-05.pdf');
      expect(logs.join('\n'), contains('[ADMIN ATTENDANCE REPORT]\nType: class'));
      expect(logs.join('\n'), contains('[ADMIN ATTENDANCE REPORT] WORKING\nType: class\nRecords: 10'));
      c.dispose();
    });

    test('changing a filter clears the preview so PDF can never mismatch', () async {
      final f = ReportsFixture();
      final c = _session();
      final rep = c.reports;
      await _with(f, () async {
        rep.setYears([_year], _year);
        await rep.loadClasses();
        rep.selectClass(25);
        await rep.loadClassReport();
        expect(rep.classReport, isNotNull);
        rep.setStartDate(DateTime(2026, 9, 15));
        expect(rep.classReport, isNull);
        expect(await rep.downloadClassPdf(), isNull);
      });
      expect(f.where('GET', '/reports/class/print'), isEmpty);
      c.dispose();
    });

    test('date validation: start after end blocks the request; presets', () async {
      final f = ReportsFixture();
      final c = _session();
      final rep = c.reports;
      await _with(f, () async {
        rep.setYears([_year], _year);
        await rep.loadClasses();
        rep.selectClass(25);
        rep.setStartDate(DateTime(2026, 10, 5));
        rep.setEndDate(DateTime(2026, 10, 1));
        expect(rep.dateError, 'The start date must be on or before the end date.');
        expect(rep.canViewClassReport, isFalse);
        await rep.loadClassReport();
        expect(f.where('GET', '/reports/class'), isEmpty);
        rep.applyPreset(ReportDatePreset.academicYear);
        expect([rep.startYmd, rep.endYmd], ['2026-09-01', '2027-06-30']);
        rep.applyPreset(ReportDatePreset.thisMonth);
        expect([rep.startYmd, rep.endYmd], ['2026-10-01', '2026-10-05']);
      });
      c.dispose();
    });

    test('student report: search by EMIS, exact query, ENROLLMENT_NOT_FOUND message', () async {
      final f = ReportsFixture();
      final c = _session();
      final rep = c.reports;
      await _with(f, () async {
        rep.setYears([_year], _year);
        await rep.searchStudents('emis002');
        expect(rep.searchResults.map((s) => s.name), ['Bashir Omar']);
        expect(f.where('GET', '/school-admin/students').last.url.queryParameters,
            containsPair('search', 'emis002'));
        rep.selectStudent(rep.searchResults.single);
        await rep.loadStudentReport();
        expect(rep.studentReport!.history, hasLength(4));
        f.enrollmentMissing = true;
        await rep.loadStudentReport();
      });
      final get = f.where('GET', '/reports/student/1002').first;
      expect(get.url.queryParameters, {
        'academic_year_id': '2',
        'start_date': '2026-10-01',
        'end_date': '2026-10-05',
      });
      expect(rep.studentReportError!.message,
          'This student was not enrolled in the selected academic year.');
      expect(rep.studentReportError!.message.contains('{'), isFalse);
      expect(logs.join('\n'), contains('[ADMIN ATTENDANCE REPORT ERROR]'));
      expect(logs.join('\n'), contains('Code: ENROLLMENT_NOT_FOUND'));
      c.dispose();
    });

    test('date range outside the academic year shows the backend explanation', () async {
      final f = ReportsFixture()
        ..reportError = {
          'message': 'The date range must be within the academic year (2026-09-01 to 2027-06-30)',
          'code': 'DATE_RANGE_OUTSIDE_ACADEMIC_YEAR',
        };
      final c = _session();
      await _with(f, () async {
        c.reports.setYears([_year], _year);
        await c.reports.loadClasses();
        c.reports.selectClass(25);
        await c.reports.loadClassReport();
      });
      expect(c.reports.classReportError!.message,
          'The date range must be within the academic year (2026-09-01 to 2027-06-30)');
      c.dispose();
    });

    test('repeated PDF taps download once', () async {
      final f = ReportsFixture();
      final c = _session();
      await _with(f, () async {
        final rep = c.reports;
        rep.setYears([_year], _year);
        await rep.loadClasses();
        rep.selectClass(25);
        await rep.loadClassReport();
        final first = rep.downloadClassPdf();
        expect(rep.classPdfBusy, isTrue);
        expect(await rep.downloadClassPdf(), isNull);
        await first;
      });
      expect(f.where('GET', '/reports/class/print'), hasLength(1));
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Widgets on phone (Android + mobile web) and desktop web widths.
  // -------------------------------------------------------------------------

  const layouts = [
    ('mobile 360x640', Size(360, 640), false),
    ('mobile 360x800', Size(360, 800), false),
    ('mobile 390x844', Size(390, 844), false),
    ('mobile 412x915', Size(412, 915), false),
    ('desktop 1024', Size(1024, 768), true),
    ('desktop 1280', Size(1280, 800), true),
    ('desktop 1366', Size(1366, 768), true),
    ('desktop 1440', Size(1440, 900), true),
    ('desktop 1920', Size(1920, 1080), true),
  ];

  for (final (name, size, desktop) in layouts) {
    testWidgets('$name: class report preview, values, PDF', (tester) async {
      final f = ReportsFixture();
      final c = _session();
      await _with(f, () async {
        await _pumpReports(tester, c, size: size, desktop: desktop);
        expect(find.byKey(const ValueKey('attendance-tab-reports')), findsOneWidget);
        expect(find.text('Class Attendance', skipOffstage: false), findsOneWidget);
        await _chooseReportClass(tester);
        await _tap(tester, find.byKey(const ValueKey('report-view')));

        expect(find.text('CLASS ATTENDANCE REPORT'), findsOneWidget);
        expect(find.text('2026-10-01 to 2026-10-05'), findsOneWidget);
        expect(_chip('class-summary', 'Students', '2'), findsOneWidget);
        expect(_chip('class-summary', 'Recorded', '10'), findsOneWidget);
        expect(_chip('class-summary', 'Present', '8'), findsOneWidget);
        expect(_chip('class-summary', 'Absent', '1'), findsOneWidget);
        expect(_chip('class-summary', 'Late', '1'), findsOneWidget);
        expect(_chip('class-summary', 'Attendance', '80%'), findsOneWidget);

        final a = find.byKey(const ValueKey('class-report-row-1001'));
        final b = find.byKey(const ValueKey('class-report-row-1002'));
        expect(find.descendant(of: a, matching: find.text('80%')), findsOneWidget);
        expect(find.descendant(of: a, matching: find.text('10')), findsOneWidget);
        expect(find.descendant(of: b, matching: find.text('—')), findsOneWidget,
            reason: 'blank percentage is shown as —');
        expect(find.descendant(of: b, matching: find.text('0%')), findsNothing);
        expect(find.text('Attendance %'), desktop ? findsOneWidget : findsNothing,
            reason: 'table on desktop, cards on phones');

        await _tap(tester, find.byKey(const ValueKey('class-report-pdf')));
        expect(f.where('GET', '/reports/class/print'), hasLength(1));
        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollable), findsOneWidget, reason: 'one scroll area');
      });
      c.dispose();
    });

    testWidgets('$name: student report search, history, PDF', (tester) async {
      final f = ReportsFixture();
      final c = _session();
      await _with(f, () async {
        await _pumpReports(tester, c, size: size, desktop: desktop);
        await _tap(tester, find.byKey(const ValueKey('report-type-student')));
        await tester.enterText(find.byKey(const ValueKey('report-student-search')), 'Bashir');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(const ValueKey('report-student-1002')));
        expect(find.byKey(const ValueKey('report-student-selected')), findsOneWidget);
        await _tap(tester, find.byKey(const ValueKey('report-view')));

        expect(find.text('STUDENT ATTENDANCE REPORT'), findsOneWidget);
        expect(find.text('EMIS002'), findsWidgets);
        expect(_chip('student-summary', 'Recorded Sessions', '4'), findsOneWidget);
        expect(_chip('student-summary', 'Attendance', '50%'), findsOneWidget);
        expect(find.text('Attendance History (4)'), findsOneWidget);
        for (final s in ['Mathematics', 'English', 'Science']) {
          expect(find.text(s), findsWidgets);
        }
        expect(find.text('Late'), findsWidgets);
        expect(find.text('Absent'), findsWidgets);
        // Backend order is preserved.
        final y0 = tester.getTopLeft(find.byKey(const ValueKey('history-row-0'))).dy;
        final y3 = tester.getTopLeft(find.byKey(const ValueKey('history-row-3'))).dy;
        expect(y0, lessThan(y3));

        await _tap(tester, find.byKey(const ValueKey('student-report-pdf')));
        expect(f.where('GET', '/reports/student/1002/print'), hasLength(1));
        expect(tester.takeException(), isNull);
      });
      c.dispose();
    });
  }

  testWidgets('NO-DATA class: loads, zero recorded, no false absence, PDF available', (tester) async {
    final f = ReportsFixture()..classNoData = true;
    final c = _session();
    await _with(f, () async {
      await _pumpReports(tester, c, size: const Size(390, 844), desktop: false);
      await _chooseReportClass(tester);
      await _tap(tester, find.byKey(const ValueKey('report-view')));
      expect(find.byKey(const ValueKey('class-report-error')), findsNothing);
      expect(find.text('No attendance was recorded during this period.'), findsOneWidget);
      expect(_chip('class-summary', 'Absent', '0'), findsOneWidget);
      expect(_chip('class-summary', 'Attendance', '—'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
      expect(find.byKey(const ValueKey('class-report-row-1001')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('class-report-pdf')));
      expect(f.where('GET', '/reports/class/print'), hasLength(1));
    });
    c.dispose();
  });

  testWidgets('NO-DATA student: zero summary, no history, PDF available', (tester) async {
    final f = ReportsFixture()..studentNoData = true;
    final c = _session();
    await _with(f, () async {
      await _pumpReports(tester, c, size: const Size(1440, 900), desktop: true);
      await _tap(tester, find.byKey(const ValueKey('report-type-student')));
      await tester.enterText(find.byKey(const ValueKey('report-student-search')), 'EMIS002');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('report-student-1002')));
      await _tap(tester, find.byKey(const ValueKey('report-view')));
      expect(find.byKey(const ValueKey('student-report-error')), findsNothing);
      expect(find.text('No attendance was recorded for this student during this period.'), findsOneWidget);
      expect(_chip('student-summary', 'Recorded Sessions', '0'), findsOneWidget);
      expect(_chip('student-summary', 'Attendance', '—'), findsOneWidget);
      expect(find.text('Attendance History (0)'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('student-report-pdf')));
      expect(f.where('GET', '/reports/student/1002/print'), hasLength(1));
    });
    c.dispose();
  });

  testWidgets('ENROLLMENT_NOT_FOUND shows a clean message with Retry', (tester) async {
    final f = ReportsFixture()..enrollmentMissing = true;
    final c = _session();
    await _with(f, () async {
      await _pumpReports(tester, c, size: const Size(390, 844), desktop: false);
      await _tap(tester, find.byKey(const ValueKey('report-type-student')));
      await tester.enterText(find.byKey(const ValueKey('report-student-search')), 'Bashir');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('report-student-1002')));
      await _tap(tester, find.byKey(const ValueKey('report-view')));
      expect(find.text('This student was not enrolled in the selected academic year.'), findsOneWidget);
      expect(find.textContaining('ENROLLMENT_NOT_FOUND'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });
    c.dispose();
  });

  testWidgets('start after end shows a validation message and disables View Report', (tester) async {
    final f = ReportsFixture();
    final c = _session();
    await _with(f, () async {
      await _pumpReports(tester, c, size: const Size(390, 844), desktop: false);
      await _chooseReportClass(tester);
      c.reports.setStartDate(DateTime(2026, 10, 5));
      c.reports.setEndDate(DateTime(2026, 10, 2));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-date-error')), findsOneWidget);
      final view = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('report-view')),
      );
      expect(view.onPressed, isNull);
    });
    c.dispose();
  });

  testWidgets('mode toggle fits 360px with short labels; desktop shows full labels', (tester) async {
    final f = ReportsFixture();
    final c = _session();
    await _with(f, () async {
      await _pumpReports(tester, c, size: const Size(360, 640), desktop: false);
      for (final l in ['Take', 'Records', 'Reports']) {
        expect(find.descendant(
          of: find.byKey(const ValueKey('attendance-modes')),
          matching: find.text(l),
        ), findsOneWidget);
      }
      expect(tester.getSize(find.byKey(const ValueKey('attendance-modes'))).width,
          lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    });
    final c2 = _session();
    await _with(f, () async {
      await _pumpReports(tester, c2, size: const Size(1280, 800), desktop: true);
      for (final l in ['Take Attendance', 'Attendance Records', 'Reports']) {
        expect(find.descendant(
          of: find.byKey(const ValueKey('attendance-modes')),
          matching: find.text(l),
        ), findsOneWidget);
      }
    });
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    c2.dispose();
  });

  testWidgets('Reports state survives switching tabs (shared session)', (tester) async {
    final f = ReportsFixture();
    final c = _session();
    await _with(f, () async {
      await _pumpReports(tester, c, size: const Size(390, 844), desktop: false);
      await _chooseReportClass(tester);
      await _tap(tester, find.byKey(const ValueKey('report-view')));
      await _tap(tester, find.byKey(const ValueKey('attendance-tab-take')));
      expect(find.byType(AttendanceReportsView), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('attendance-tab-reports')));
      expect(find.text('CLASS ATTENDANCE REPORT'), findsOneWidget);
      expect(f.where('GET', '/reports/class'), hasLength(1));
    });
    c.dispose();
  });
}
