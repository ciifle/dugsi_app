import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:kobac/models/lesson_attendance.dart';
import 'package:kobac/school_admin/attendance/take_attendance_controller.dart';
import 'package:kobac/school_admin/attendance/take_attendance_view.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/school_admin/widgets/admin_leave_guard.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/attendance_diagnostics.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/pdf_file_result.dart';

// ---------------------------------------------------------------------------
// Fake backend mirroring attendance.service.js (upsert, partial save,
// summary, recorded flags, error envelope {message, code}).
// ---------------------------------------------------------------------------

http.Response _json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

const _students = [
  {'id': 1001, 'name': 'Abdi Ali', 'emis': 'EMIS-1001'},
  {'id': 1002, 'name': 'Bashir Omar', 'emis': 'EMIS-1002'},
  {'id': 1003, 'name': 'Caaliya Noor', 'emis': null},
];

Map<String, dynamic> _lesson(int id) => {
  401: {
    'timetable_id': 401,
    'day': 'MON',
    'start_time': '08:00:00',
    'end_time': '08:40:00',
    'period': {'id': 1, 'name': 'Period 1', 'period_number': 1, 'shift': 'MORNING'},
    'subject': {'id': 6, 'name': 'English'},
    'teacher': {'id': 12, 'full_name': 'Mohamed Ali'},
  },
  402: {
    'timetable_id': 402,
    'day': 'MON',
    'start_time': '08:40:00',
    'end_time': '09:20:00',
    'period': {'id': 2, 'name': 'Period 2', 'period_number': 2, 'shift': 'MORNING'},
    'subject': {'id': 5, 'name': 'Mathematics'},
    'teacher': {'id': 11, 'full_name': 'Ahmed Yusuf'},
  },
}[id]!;

class AttendanceFixture {
  final requests = <http.Request>[];

  /// timetable id -> student id -> status. 402 already has historical rows.
  final store = <int, Map<int, String>>{
    402: {1001: 'PRESENT', 1002: 'LATE'},
  };
  bool noLessons = false;
  bool noStudents = false;

  /// 3 = the named fixture students; anything else generates a class.
  int studentCount = 3;

  /// Replaces the GET register response (500s, malformed bodies, ...).
  http.Response Function(http.Request)? registerOverride;

  List<Map<String, Object?>> get studentRows => studentCount == 3
      ? _students
      : [
          for (var i = 1; i <= studentCount; i++)
            {
              'id': 5000 + i,
              'name': 'Student ${i.toString().padLeft(2, '0')}',
              'emis': 'EMIS-${5000 + i}',
            },
        ];
  Map<String, dynamic>? lessonsError;
  int lessonsErrorStatus = 400;
  Map<String, dynamic>? saveError;
  Completer<void>? saveGate;
  Completer<void>? printGate;
  int printStatus = 200;

  List<http.Request> where(String method, String suffix) => requests
      .where((r) => r.method == method && r.url.path.endsWith(suffix))
      .toList();

  Map<String, dynamic> register(int tid) {
    final rows = store[tid] ?? const {};
    final students = noStudents
        ? const <Map<String, dynamic>>[]
        : [
            for (final s in studentRows)
              {
                'student_id': s['id'],
                'student_name': s['name'],
                'emis_number': s['emis'],
                'enrolled': true,
                'attendance_id': rows[s['id']] == null ? null : 7000 + (s['id'] as int),
                'status': rows[s['id']],
                'recorded_by': null,
                'updated_by': null,
                'updated_at': null,
              },
          ];
    int count(String st) => students.where((s) => s['status'] == st).length;
    final recorded = students.where((s) => s['status'] != null).length;
    final present = count('PRESENT');
    return {
      'academic_year': {'id': 2, 'name': '2026-2027'},
      'class': {'id': 25, 'name': 'Form 3'},
      'date': '2026-10-05',
      'day': 'MON',
      'day_name': 'Monday',
      'lesson': _lesson(tid),
      'attendance_recorded': rows.isNotEmpty,
      'summary': {
        'total_students': students.length,
        'recorded': recorded,
        'not_recorded': students.length - recorded,
        'present': present,
        'absent': count('ABSENT'),
        'late': count('LATE'),
        'attendance_percentage': recorded == 0
            ? null
            : (present / recorded * 10000).round() / 100,
      },
      'students': students,
    };
  }

  Future<http.Response> call(http.Request r) async {
    requests.add(r);
    final path = r.url.path;
    final q = r.url.queryParameters;
    if (path.endsWith('/school-admin/classes')) {
      final year = q['academic_year_id'];
      return _json({
        'classes': [
          if (year != '1') {'id': 25, 'name': 'Form 3'},
          {'id': 26, 'name': 'Form 4'},
        ],
      });
    }
    if (path.endsWith('/attendance/lessons')) {
      if (lessonsError != null) return _json(lessonsError!, lessonsErrorStatus);
      return _json({
        'academic_year': {'id': 2, 'name': '2026-2027'},
        'class': {'id': 25, 'name': 'Form 3'},
        'date': q['date'],
        'day': 'MON',
        'day_name': 'Monday',
        'lessons': noLessons
            ? []
            : [
                for (final tid in [401, 402])
                  {
                    ..._lesson(tid),
                    'attendance_recorded': (store[tid] ?? {}).isNotEmpty,
                    'recorded_count': (store[tid] ?? {}).length,
                  },
              ],
      });
    }
    if (path.endsWith('/attendance/register/print')) {
      if (printGate != null) await printGate!.future;
      if (printStatus == 404) {
        return _json({
          'message': 'No attendance has been recorded for this lesson on this date.',
          'code': 'ATTENDANCE_NOT_RECORDED',
        }, 404);
      }
      return http.Response.bytes(
        utf8.encode('%PDF-1.4 attendance'),
        200,
        headers: {
          'content-type': 'application/pdf',
          'content-disposition':
              'attachment; filename="attendance-form-3-2026-10-05-mathematics-p2.pdf"',
        },
      );
    }
    if (path.endsWith('/attendance/register') && r.method == 'GET') {
      if (registerOverride != null) return registerOverride!(r);
      return _json(register(int.parse(q['timetable_id']!)));
    }
    if (path.endsWith('/attendance/register') && r.method == 'PUT') {
      if (saveGate != null) await saveGate!.future;
      if (saveError != null) return _json(saveError!, 400);
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final tid = body['timetable_id'] as int;
      final rows = store.putIfAbsent(tid, () => {});
      var created = 0, updated = 0;
      for (final rec in (body['records'] as List).cast<Map>()) {
        final id = rec['student_id'] as int;
        if (rows.containsKey(id)) {
          updated++;
        } else {
          created++;
        }
        rows[id] = rec['status'] as String;
      }
      return _json({
        'message': 'Lesson attendance saved',
        'created_count': created,
        'updated_count': updated,
        'unchanged_count': 0,
        'register': register(tid),
      });
    }
    // Existing records list / single edit / delete.
    if (path.endsWith('/school-admin/attendance') && r.method == 'GET') {
      return _json({
        'attendance': [
          {
            'id': 9,
            'studentId': 1002,
            'studentName': 'Bashir Omar',
            'emisNumber': 'EMIS-1002',
            'teacherName': 'Ahmed Yusuf',
            'classId': 25,
            'className': 'Form 3',
            'subjectName': 'Mathematics',
            'date': '2026-10-05',
            'time': '08:40:00',
            'period': '2',
            'status': 'LATE',
          },
        ],
      });
    }
    if (path.endsWith('/school-admin/attendance/9') && r.method == 'PATCH') {
      return _json({'attendance': {'id': 9, 'status': jsonDecode(r.body)['status']}});
    }
    if (path.endsWith('/school-admin/attendance/9') && r.method == 'DELETE') {
      return _json({'message': 'Attendance deleted'});
    }
    return _json({'message': 'Route not found'}, 404);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _activeYear = AcademicYear(
  id: 2,
  name: '2026-2027',
  startDate: DateTime(2026, 9, 1),
  endDate: DateTime(2027, 6, 30),
  isActive: true,
);
final _pastYear = AcademicYear(
  id: 1,
  name: '2025-2026',
  startDate: DateTime(2025, 9, 1),
  endDate: DateTime(2026, 6, 30),
  isActive: false,
);

class _Years extends AcademicYearsProvider {
  _Years() {
    years = [_activeYear, _pastYear];
    activeYear = _activeYear;
  }
  @override
  Future<void> ensureLoaded() async {}
}

/// Monday 2026-10-05 in the active year.
DateTime _monday() => DateTime(2026, 10, 5, 9, 0);

TakeAttendanceController _controller() => TakeAttendanceController(now: _monday);

Future<T> _with<T>(AttendanceFixture f, Future<T> Function() body) =>
    http.runWithClient(body, () => MockClient(f.call));

Future<void> _openRegister(TakeAttendanceController c, int tid) async {
  c.setYears([_activeYear, _pastYear], _activeYear);
  await c.loadClasses();
  c.selectClass(25);
  await c.loadLessons();
  c.selectLesson(tid);
  await c.loadRegister();
}

Future<void> _pumpScreen(
  WidgetTester tester,
  TakeAttendanceController c, {
  Size size = const Size(390, 844),
  bool pushed = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final screen = AdminAttendanceScreen(controller: c);
  await tester.pumpWidget(
    ChangeNotifierProvider<AcademicYearsProvider>.value(
      value: _Years(),
      child: MaterialApp(
        home: pushed
            ? Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => screen),
                      ),
                      child: const Text('Open Attendance'),
                    ),
                  ),
                ),
              )
            : screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (pushed) {
    await tester.tap(find.text('Open Attendance'));
    await tester.pumpAndSettle();
  }
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

Finder _lessonCard(int tid) => find.byKey(ValueKey('lesson-$tid'));

/// Whether "Print Lesson Attendance" can be pressed right now.
bool _printEnabled(WidgetTester tester) {
  final button = find.descendant(
    of: find.byKey(const ValueKey('attendance-print')),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(button.first).onPressed != null;
}

// ---------------------------------------------------------------------------

void main() {
  group('models', () {
    test('lesson and register parse the backend contract exactly', () {
      final f = AttendanceFixture();
      final reg = LessonRegister.tryParse(f.register(402))!;
      expect(reg.lesson.timetableId, 402);
      expect(reg.lesson.subjectName, 'Mathematics');
      expect(reg.lesson.teacherName, 'Ahmed Yusuf');
      expect(reg.lesson.periodLabel, 'Period 2');
      expect(reg.lesson.timeRange, '8:40 AM – 9:20 AM');
      expect(reg.attendanceRecorded, isTrue);
      expect(reg.students.map((s) => s.status), ['PRESENT', 'LATE', null]);
      expect(reg.students.last.emisNumber, isNull);
      expect(reg.summary.totalStudents, 3);
      expect(reg.summary.late, 1);
      expect(reg.summary.attendancePercentage, 50);
      expect(reg.summary.percentageLabel, '50%');
      expect(const RegisterSummary(attendancePercentage: 84.38).percentageLabel, '84.38%');
      expect(const RegisterSummary().percentageLabel, '—');
    });

    test('records list reads backend names and EMIS (no "Unknown" fallback)', () {
      final m = AttendanceModel.fromJson({
        'id': 9,
        'studentName': 'Bashir Omar',
        'emisNumber': 'EMIS-1002',
        'teacherName': 'Ahmed Yusuf',
        'status': 'LATE',
      });
      expect(m.studentName, 'Bashir Omar');
      expect(m.emisNumber, 'EMIS-1002');
      expect(m.teacherName, 'Ahmed Yusuf');
    });

    test('error codes map to friendly messages; raw text never leaks', () {
      expect(
        lessonAttendanceErrorMessage(code: 'LESSON_SELECTION_REQUIRED', fallback: 'x'),
        'Select a lesson before taking attendance.',
      );
      expect(
        lessonAttendanceErrorMessage(code: 'ATTENDANCE_NOT_RECORDED', statusCode: 404, fallback: 'x'),
        'No attendance has been recorded for this lesson yet.',
      );
      expect(
        lessonAttendanceErrorMessage(code: 'FUTURE_ATTENDANCE_DATE', fallback: 'x'),
        contains('future date'),
      );
      expect(
        lessonAttendanceErrorMessage(code: 'DATE_OUTSIDE_ACADEMIC_YEAR', fallback: 'x'),
        contains('outside the selected academic year'),
      );
      expect(
        lessonAttendanceErrorMessage(statusCode: 403, fallback: 'x'),
        contains('permission'),
      );
      expect(
        lessonAttendanceErrorMessage(
          statusCode: 400,
          backendMessage: 'ER_BAD_FIELD SQL syntax near ...',
          fallback: 'Could not save.',
        ),
        'Could not save.',
      );
      expect(
        lessonAttendanceErrorMessage(statusCode: 500, backendMessage: 'boom', fallback: 'x'),
        'The server could not complete this request. Please try again in a moment.',
      );
      expect(
        lessonAttendanceErrorMessage(code: 'LESSON_NOT_FOUND', statusCode: 404, fallback: 'x'),
        'The selected timetable lesson could not be found.',
      );
      expect(
        lessonAttendanceErrorMessage(
          statusCode: 400,
          backendMessage: "Unknown column 'Attendance.recordedByUserId' in 'field list'",
          fallback: 'Could not load.',
        ),
        'Could not load.',
      );
    });
  });

  group('leave guard', () {
    test('registered check can veto shell navigation; unregister clears it', () async {
      Future<bool> stay() async => false;
      AdminLeaveGuard.register(stay);
      expect(await AdminLeaveGuard.confirmLeave(), isFalse);
      AdminLeaveGuard.unregister(stay);
      expect(await AdminLeaveGuard.confirmLeave(), isTrue);
    });
  });

  group('filters', () {
    test('active academic year is selected by default and loads its classes', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        c.setYears([_pastYear, _activeYear], _activeYear);
        await c.loadClasses();
      });
      expect(c.yearId, 2);
      expect(c.dateYmd, '2026-10-05', reason: 'defaults to today');
      expect(f.where('GET', '/classes').last.url.queryParameters['academic_year_id'], '2');
      expect(c.classes.map((e) => e.name), ['Form 3', 'Form 4']);
      c.dispose();
    });

    test('changing year clamps the date, drops an incompatible class and resets lesson/register', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 402);
        expect(c.register, isNotNull);
        c.selectYear(1);
        expect(c.timetableId, isNull);
        expect(c.register, isNull);
        expect(c.lessons, isEmpty);
        await c.loadClasses();
      });
      expect(c.dateYmd, '2026-06-30', reason: 'past year ended: last valid date');
      expect(c.lastDate, DateTime(2026, 6, 30));
      expect(c.classId, isNull, reason: 'Form 3 does not exist in 2025-2026');
      c.dispose();
    });

    test('date picker range never allows future dates', () {
      final c = _controller();
      c.setYears([_activeYear], _activeYear);
      expect(c.lastDate, DateTime(2026, 10, 5));
      expect(c.firstDate, DateTime(2026, 9, 1));
      c.selectDate(DateTime(2026, 12, 25));
      expect(c.dateYmd, '2026-10-05');
      c.dispose();
    });

    test('changing date or class invalidates lesson and register then reloads lessons', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 402);
        c.selectDate(DateTime(2026, 9, 28));
        expect(c.timetableId, isNull);
        expect(c.register, isNull);
        await c.loadLessons();
        expect(f.where('GET', '/attendance/lessons').last.url.queryParameters, {
          'academic_year_id': '2',
          'class_id': '25',
          'date': '2026-09-28',
        });
        c.selectLesson(401);
        await c.loadRegister();
        c.selectClass(26);
        expect(c.timetableId, isNull);
        expect(c.register, isNull);
      });
      c.dispose();
    });
  });

  group('lessons', () {
    test('multiple lessons with Recorded / Not Taken flags', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        c.setYears([_activeYear], _activeYear);
        await c.loadClasses();
        c.selectClass(25);
        await c.loadLessons();
      });
      expect(c.lessons.map((l) => l.timetableId), [401, 402]);
      expect(c.lessons.first.attendanceRecorded, isFalse);
      expect(c.lessons.last.attendanceRecorded, isTrue);
      expect(c.lessons.last.recordedCount, 2);
      expect(c.lessonsDayName, 'Monday');
      c.dispose();
    });

    test('no lessons and backend errors are distinct states', () async {
      final f = AttendanceFixture()..noLessons = true;
      final c = _controller();
      await _with(f, () async {
        c.setYears([_activeYear], _activeYear);
        await c.loadClasses();
        c.selectClass(25);
        await c.loadLessons();
        expect(c.lessonsLoaded, isTrue);
        expect(c.lessons, isEmpty);
        expect(c.lessonsError, isNull);
        f.lessonsError = {
          'message': 'Attendance cannot be recorded for a future date',
          'code': 'FUTURE_ATTENDANCE_DATE',
        };
        await c.loadLessons();
      });
      expect(c.lessonsError!.code, 'FUTURE_ATTENDANCE_DATE');
      expect(c.lessonsError!.message, contains('future date'));
      c.dispose();
    });
  });

  group('register and marks', () {
    test('existing statuses load as-is; unmarked stays null; historical LATE kept', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () => _openRegister(c, 402));
      expect(f.where('GET', '/attendance/register').last.url.queryParameters, {
        'academic_year_id': '2',
        'class_id': '25',
        'date': '2026-10-05',
        'timetable_id': '402',
      });
      expect(c.currentMark(1001), 'PRESENT');
      expect(c.currentMark(1002), 'LATE');
      expect(c.currentMark(1003), isNull);
      expect(c.hasUnsavedChanges, isFalse);
      expect(c.canPrint, isTrue);
      c.dispose();
    });

    test('Mark All Present is local only, skips historical LATE; Clear All reverts', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () => _openRegister(c, 402));
      final before = f.requests.length;
      c.markAllPresent();
      expect(c.currentMark(1002), 'LATE');
      expect(c.currentMark(1003), 'PRESENT');
      expect(c.pendingRecords.map((r) => r.toJson()), [
        {'student_id': 1003, 'status': 'PRESENT'},
      ]);
      expect(f.requests.length, before, reason: 'nothing saved');
      c.clearAll();
      expect(c.currentMark(1003), isNull);
      expect(c.currentMark(1001), 'PRESENT');
      expect(c.hasUnsavedChanges, isFalse);
      c.dispose();
    });

    test('LATE can never be set locally through the register', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () => _openRegister(c, 401));
      c.setMark(1001, 'LATE');
      expect(c.currentMark(1001), isNull);
      c.dispose();
    });
  });

  group('save', () {
    test('first attendance: one PUT with exact contract, reloads register and lessons', () async {
      final f = AttendanceFixture();
      final c = _controller();
      AttendanceSaveOutcome? outcome;
      await _with(f, () async {
        await _openRegister(c, 401);
        expect(c.register!.attendanceRecorded, isFalse);
        c.setMark(1001, 'PRESENT');
        c.setMark(1002, 'ABSENT');
        final lessonsBefore = f.where('GET', '/attendance/lessons').length;
        outcome = await c.save();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(f.where('GET', '/attendance/lessons').length, lessonsBefore + 1);
      });
      final puts = f.where('PUT', '/attendance/register');
      expect(puts, hasLength(1));
      final body = jsonDecode(puts.single.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'academic_year_id', 'class_id', 'date', 'timetable_id', 'records'});
      expect(body['academic_year_id'], 2);
      expect(body['class_id'], 25);
      expect(body['date'], '2026-10-05');
      expect(body['timetable_id'], 401);
      expect(body['records'], [
        {'student_id': 1001, 'status': 'PRESENT'},
        {'student_id': 1002, 'status': 'ABSENT'},
      ], reason: 'unmarked 1003 omitted, never auto-ABSENT');
      for (final forbidden in ['teacherId', 'subjectId', 'period', 'time', 'schoolId', 'school_id']) {
        expect(body.containsKey(forbidden), isFalse);
      }
      expect(outcome!.success, isTrue);
      expect(outcome!.message, 'Attendance saved successfully.');
      expect(c.register!.attendanceRecorded, isTrue);
      expect(c.register!.summary.present, 1);
      expect(c.register!.summary.notRecorded, 1);
      expect(c.hasUnsavedChanges, isFalse);
      expect(c.currentMark(1002), 'ABSENT');
      expect(c.lessons.firstWhere((l) => l.timetableId == 401).attendanceRecorded, isTrue);
      expect(c.timetableId, 401, reason: 'selection kept after save');
      c.dispose();
    });

    test('edit existing: only changes sent; unchanged historical LATE is preserved', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 402);
        c.setMark(1001, 'ABSENT');
        final outcome = await c.save();
        expect(outcome!.message, 'Attendance changes saved successfully.');
      });
      final body = jsonDecode(f.where('PUT', '/attendance/register').single.body);
      expect(body['records'], [
        {'student_id': 1001, 'status': 'ABSENT'},
      ]);
      expect(f.store[402]![1002], 'LATE', reason: 'LATE never sent, never converted');
      expect(c.currentMark(1002), 'LATE');
      c.dispose();
    });

    test('changing a historical LATE explicitly sends PRESENT/ABSENT', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 402);
        c.setMark(1002, 'PRESENT');
        await c.save();
      });
      final body = jsonDecode(f.where('PUT', '/attendance/register').single.body);
      expect(body['records'], [
        {'student_id': 1002, 'status': 'PRESENT'},
      ]);
      c.dispose();
    });

    test('double submit sends exactly one PUT and shows saving state', () async {
      final f = AttendanceFixture()..saveGate = Completer<void>();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 401);
        c.setMark(1001, 'PRESENT');
        final first = c.save();
        expect(c.saving, isTrue);
        expect(await c.save(), isNull);
        c.setMark(1002, 'ABSENT');
        expect(c.currentMark(1002), isNull, reason: 'marks locked while saving');
        f.saveGate!.complete();
        expect((await first)!.success, isTrue);
      });
      expect(f.where('PUT', '/attendance/register'), hasLength(1));
      expect(c.saving, isFalse);
      c.dispose();
    });

    test('validation: nothing changed means no request', () async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 401);
        final outcome = await c.save();
        expect(outcome!.success, isFalse);
        expect(outcome.message, contains('Mark at least one student'));
      });
      expect(f.where('PUT', '/attendance/register'), isEmpty);
      c.dispose();
    });

    test('backend error keeps local marks and shows a friendly message', () async {
      final f = AttendanceFixture()
        ..saveError = {
          'message': 'Attendance date is outside the selected academic year',
          'code': 'DATE_OUTSIDE_ACADEMIC_YEAR',
        };
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 401);
        c.setMark(1001, 'PRESENT');
        final outcome = await c.save();
        expect(outcome!.success, isFalse);
        expect(outcome.message, contains('outside the selected academic year'));
      });
      expect(c.hasUnsavedChanges, isTrue);
      expect(c.currentMark(1001), 'PRESENT');
      c.dispose();
    });
  });

  group('pdf', () {
    test('binary PDF with Content-Disposition filename and exact query', () async {
      final f = AttendanceFixture();
      final c = _controller();
      late AttendanceResult<PdfFileResult>? result;
      await _with(f, () async {
        await _openRegister(c, 402);
        result = await c.downloadPdf();
      });
      final file = (result as AttendanceSuccess<PdfFileResult>).data;
      expect(file.filename, 'attendance-form-3-2026-10-05-mathematics-p2.pdf');
      expect(utf8.decode(file.bytes), startsWith('%PDF'));
      final req = f.where('GET', '/attendance/register/print').single;
      expect(req.url.queryParameters, {
        'academic_year_id': '2',
        'class_id': '25',
        'date': '2026-10-05',
        'timetable_id': '402',
      });
      expect(req.headers['Accept'], 'application/pdf');
      expect(c.pdfFallbackFilename, 'attendance-form-3-2026-10-05-mathematics.pdf');
      c.dispose();
    });

    test('404 ATTENDANCE_NOT_RECORDED is a friendly message, not JSON', () async {
      final f = AttendanceFixture()..printStatus = 404;
      final c = _controller();
      AttendanceResult<PdfFileResult>? result;
      await _with(f, () async {
        await _openRegister(c, 402);
        result = await c.downloadPdf();
      });
      final error = result as AttendanceError;
      expect(error.code, 'ATTENDANCE_NOT_RECORDED');
      expect(error.message, 'No attendance has been recorded for this lesson yet.');
      expect(error.message.contains('{'), isFalse);
      c.dispose();
    });

    test('repeated taps while downloading are ignored', () async {
      final f = AttendanceFixture()..printGate = Completer<void>();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 402);
        final first = c.downloadPdf();
        expect(c.downloadingPdf, isTrue);
        expect(await c.downloadPdf(), isNull);
        f.printGate!.complete();
        expect(await first, isA<AttendanceSuccess<PdfFileResult>>());
      });
      expect(f.where('GET', '/attendance/register/print'), hasLength(1));
      expect(c.downloadingPdf, isFalse);
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Widgets
  // -------------------------------------------------------------------------

  group('widgets', () {
    testWidgets('mobile flow: lessons, Not Taken register, Mark All Present, save', (tester) async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        expect(find.text('Attendance'), findsOneWidget);
        expect(find.text(kAttendanceSubtitle), findsOneWidget);
        expect(find.text('2026-2027 (Active)'), findsOneWidget);
        expect(find.text('Select a class and date to view timetable lessons.'), findsOneWidget);

        await _chooseClass(tester, 'Form 3');
        expect(_lessonCard(401), findsOneWidget);
        expect(_lessonCard(402), findsOneWidget);
        expect(find.text('Not Taken'), findsOneWidget);
        expect(find.text('Recorded'), findsOneWidget);
        expect(find.text('Mohamed Ali'), findsOneWidget);
        expect(find.text('8:00 AM – 8:40 AM'), findsOneWidget);

        await _tap(tester, _lessonCard(401));
        expect(find.byKey(const ValueKey('attendance-not-taken')), findsOneWidget);
        expect(find.text('Attendance has not been taken for this lesson yet.'), findsOneWidget);
        expect(find.text('Not marked'), findsNWidgets(3));
        // Visible but disabled, with the reason, until attendance is saved.
        expect(_printEnabled(tester), isFalse, reason: 'nothing recorded yet');
        expect(find.byKey(const ValueKey('attendance-print-reason')), findsOneWidget);

        await _tap(tester, find.byKey(const ValueKey('attendance-mark-all-present')));
        expect(f.where('PUT', '/attendance/register'), isEmpty);
        expect(find.text('3 unsaved changes'), findsOneWidget);

        await _tap(tester, find.byKey(const ValueKey('mark-absent-1003')));
        await _tap(tester, find.byKey(const ValueKey('attendance-save')));
        expect(f.where('PUT', '/attendance/register'), hasLength(1));
        expect(find.text('Attendance saved successfully.'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
        expect(find.text('Not Taken'), findsNothing);
        expect(find.byKey(const ValueKey('attendance-print')), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('summary chips show backend values', (tester) async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(402));
        Finder chip(String label, String value) => find.descendant(
          of: find.byKey(ValueKey('summary-$label')),
          matching: find.text(value),
        );
        expect(chip('Total Students', '3'), findsOneWidget);
        expect(chip('Present', '1'), findsOneWidget);
        expect(chip('Absent', '0'), findsOneWidget);
        expect(chip('Late', '1'), findsOneWidget);
        expect(chip('Recorded', '2'), findsOneWidget);
        expect(chip('Attendance', '50%'), findsOneWidget);
        expect(find.text('Late (recorded earlier)'), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('unsaved changes: changing lesson and class asks first', (tester) async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        await _tap(tester, find.byKey(const ValueKey('mark-present-1001')));

        await _tap(tester, _lessonCard(402));
        expect(find.text('Unsaved Attendance'), findsOneWidget);
        await _tap(tester, find.text('Continue Editing'));
        expect(c.timetableId, 401);
        expect(c.currentMark(1001), 'PRESENT');

        await _chooseClass(tester, 'Form 4');
        expect(find.text('Unsaved Attendance'), findsOneWidget);
        await _tap(tester, find.text('Continue Editing'));
        expect(c.classId, 25);

        await _tap(tester, _lessonCard(402));
        await _tap(tester, find.text('Discard'));
        expect(c.timetableId, 402);
        expect(c.hasUnsavedChanges, isFalse);
      });
      c.dispose();
    });

    testWidgets('unsaved changes: changing date asks first', (tester) async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        await _tap(tester, find.byKey(const ValueKey('mark-present-1001')));

        await _tap(tester, find.byKey(const ValueKey('attendance-date')));
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Unsaved Attendance'), findsOneWidget);
        await _tap(tester, find.text('Discard'));
        expect(c.dateYmd, '2026-10-01');
        expect(c.timetableId, isNull);
      });
      c.dispose();
    });

    testWidgets('leaving the page with unsaved changes asks first', (tester) async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c, pushed: true);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        await _tap(tester, find.byKey(const ValueKey('mark-present-1001')));

        await _tap(tester, find.byTooltip('Back'));
        expect(find.text('Unsaved Attendance'), findsOneWidget);
        await _tap(tester, find.text('Continue Editing'));
        expect(find.byType(AdminAttendanceScreen), findsOneWidget);

        await _tap(tester, find.byTooltip('Back'));
        await _tap(tester, find.text('Discard'));
        expect(find.byType(AdminAttendanceScreen), findsNothing);
        expect(find.text('Open Attendance'), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('empty states are distinct: no lessons / no students', (tester) async {
      final f = AttendanceFixture()..noLessons = true;
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        expect(find.text('No timetable lessons were found for this class on this date.'), findsOneWidget);
        f
          ..noLessons = false
          ..noStudents = true;
        c.selectDate(DateTime(2026, 10, 1));
        await tester.pumpAndSettle();
        await _tap(tester, _lessonCard(401));
        expect(find.text('No enrolled students were found for this class.'), findsOneWidget);
        expect(find.text('Attendance has not been taken for this lesson yet.'), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('lesson load error shows a friendly message with Retry', (tester) async {
      final f = AttendanceFixture()
        ..lessonsError = {'message': 'Lesson not found', 'code': 'LESSON_SELECTION_REQUIRED'};
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        expect(find.text('Select a lesson before taking attendance.'), findsOneWidget);
        f.lessonsError = null;
        await _tap(tester, find.text('Retry'));
        expect(_lessonCard(401), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('print: loading state, repeated taps ignored, 404 message', (tester) async {
      final f = AttendanceFixture()
        ..printGate = Completer<void>()
        ..printStatus = 404;
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(402));
        final print = find.byKey(const ValueKey('attendance-print'));
        await tester.ensureVisible(print);
        await tester.tap(print);
        await tester.pump();
        expect(find.text('Preparing PDF…'), findsOneWidget);
        await tester.tap(print, warnIfMissed: false);
        await tester.pump();
        f.printGate!.complete();
        await tester.pumpAndSettle();
        expect(f.where('GET', '/attendance/register/print'), hasLength(1));
        expect(find.text('No attendance has been recorded for this lesson yet.'), findsOneWidget);
        expect(find.text('Print Lesson Attendance'), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('save button shows saving state and blocks double taps', (tester) async {
      final f = AttendanceFixture()..saveGate = Completer<void>();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(402));
        await _tap(tester, find.byKey(const ValueKey('attendance-mark-all-present')));
        await _tap(tester, find.byKey(const ValueKey('mark-absent-1001')));
        final save = find.byKey(const ValueKey('attendance-save'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        expect(find.text('Saving…'), findsOneWidget);
        await tester.tap(save, warnIfMissed: false);
        await tester.pump();
        f.saveGate!.complete();
        await tester.pumpAndSettle();
        expect(f.where('PUT', '/attendance/register'), hasLength(1));
        expect(find.text('Attendance changes saved successfully.'), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('partial register asks before saving with unmarked students', (tester) async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        await _tap(tester, find.byKey(const ValueKey('mark-present-1001')));
        await _tap(tester, find.byKey(const ValueKey('attendance-save')));
        expect(find.text('Some students are not marked'), findsOneWidget);
        await _tap(tester, find.text('Keep Marking'));
        expect(f.where('PUT', '/attendance/register'), isEmpty);
        await _tap(tester, find.byKey(const ValueKey('attendance-save')));
        await _tap(tester, find.text('Save Anyway'));
        final body = jsonDecode(f.where('PUT', '/attendance/register').single.body);
        expect(body['records'], [
          {'student_id': 1001, 'status': 'PRESENT'},
        ]);
      });
      c.dispose();
    });

    for (final size in const [Size(360, 640), Size(360, 800), Size(390, 844), Size(412, 915)]) {
      testWidgets('no overflow with a loaded register at $size', (tester) async {
        final f = AttendanceFixture();
        final c = _controller();
        await _with(f, () async {
          await _pumpScreen(tester, c, size: size);
          await _chooseClass(tester, 'Form 3');
          await _tap(tester, _lessonCard(402));
          expect(tester.takeException(), isNull);
          // Title, filters and register all live in one scroll area.
          final scroll = find.byKey(const ValueKey('attendance-scroll'));
          expect(find.descendant(of: scroll, matching: find.text(kAttendanceSubtitle)), findsOneWidget);
          expect(find.descendant(of: scroll, matching: find.byKey(const ValueKey('attendance-save'))), findsOneWidget);
          await tester.drag(scroll, const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
        c.dispose();
      });
    }

    testWidgets('desktop register table: No. | EMIS | Student | Present | Absent', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _openRegister(c, 402);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TakeAttendanceView(controller: c, isDesktop: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final h in ['No.', 'EMIS', 'Student Name', 'Present', 'Absent']) {
          expect(find.text(h), findsWidgets);
        }
        expect(find.text('EMIS-1001'), findsOneWidget);
        expect(find.text('—'), findsWidgets, reason: 'missing EMIS shown as dash');
        expect(find.text('Late (recorded earlier)'), findsOneWidget);
        await _tap(tester, find.byKey(const ValueKey('mark-absent-1002')));
        expect(c.currentMark(1002), 'ABSENT');
        expect(find.text('Unsaved change'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      c.dispose();
    });

    testWidgets('Attendance Records keeps list, single-row edit (incl. LATE) and delete', (tester) async {
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _tap(tester, find.byKey(const ValueKey('attendance-tab-records')));
        expect(find.text('Bashir Omar'), findsOneWidget);
        expect(find.textContaining('EMIS: EMIS-1002 · LATE'), findsOneWidget);
        expect(find.text('Unknown'), findsNothing);
        expect(f.where('GET', '/school-admin/students'), isEmpty,
            reason: 'EMIS comes from the attendance response');

        await _tap(tester, find.byTooltip('Edit Status'));
        expect(find.text('Update Attendance'), findsOneWidget);
        await _tap(tester, find.text('Save'));
        final patch = f.where('PATCH', '/school-admin/attendance/9').single;
        expect(jsonDecode(patch.body), {'status': 'LATE'});

        await _tap(tester, find.byTooltip('Delete'));
        await _tap(tester, find.text('Delete'));
        expect(f.where('DELETE', '/school-admin/attendance/9'), hasLength(1));

        await _tap(tester, find.byKey(const ValueKey('attendance-tab-take')));
        expect(find.text('Select a class and date to view timetable lessons.'), findsOneWidget);
      });
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Register loading reliability + diagnostics
  // -------------------------------------------------------------------------

  group('register loading', () {
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

    String allLogs() => logs.join('\n');

    testWidgets('FIRST-TIME: Not Taken lesson loads every enrolled student unmarked', (tester) async {
      final f = AttendanceFixture()..studentCount = 30;
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));

        final req = f.where('GET', '/attendance/register').single;
        expect(req.url.queryParameters, {
          'academic_year_id': '2',
          'class_id': '25',
          'date': '2026-10-05',
          'timetable_id': '401',
        });
        // Not the period (1), subject (6) or teacher (12) id.
        expect(req.url.queryParameters['timetable_id'], isNot(anyOf('1', '6', '12')));

        expect(find.byKey(const ValueKey('register-error')), findsNothing);
        expect(find.textContaining('Something went wrong'), findsNothing);
        expect(find.text('Students (30)'), findsOneWidget);
        expect(find.text('Not marked'), findsNWidgets(30));
        expect(c.students.every((s) => c.currentMark(s.studentId) == null), isTrue);
        expect(find.text('Attendance has not been taken for this lesson yet.'), findsOneWidget);
        expect(_printEnabled(tester), isFalse,
            reason: 'CASE E: PDF unavailable until recorded');
        expect(find.byKey(const ValueKey('attendance-print-reason')), findsOneWidget);

        final save = find.byKey(const ValueKey('attendance-save'));
        expect(tester.widget<FilledButton>(save).onPressed, isNull,
            reason: 'nothing marked yet');
        await _tap(tester, find.byKey(const ValueKey('mark-present-5001')));
        await _tap(tester, find.byKey(const ValueKey('mark-absent-5002')));
        expect(c.currentMark(5001), 'PRESENT');
        expect(c.currentMark(5002), 'ABSENT');
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      });
      expect(
        logs.where((l) => l.startsWith('[ADMIN ATTENDANCE] Loading register')),
        hasLength(1),
        reason: 'one register load logs exactly once',
      );
      expect(logs.where((l) => l.startsWith('[ADMIN ATTENDANCE] WORKING')), hasLength(1));
      expect(allLogs(), contains('timetable_id: 401'));
      expect(allLogs(), contains('[ADMIN ATTENDANCE REQUEST]'));
      expect(allLogs(), contains('[ADMIN ATTENDANCE RESPONSE]'));
      expect(allLogs(), contains('[ADMIN ATTENDANCE] WORKING'));
      expect(allLogs(), contains('Students: 30'));
      expect(allLogs(), contains('Existing attendance records: 0'));
      expect(allLogs(), contains('Unmarked students: 30'));
      expect(allLogs(), isNot(contains('[ADMIN ATTENDANCE ERROR]')));
      c.dispose();
    });

    testWidgets('CASE B: 30 students, Mark All Present, 3 Absent, one save, reload shows 27/3', (tester) async {
      final f = AttendanceFixture()..studentCount = 30;
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        await _tap(tester, find.byKey(const ValueKey('attendance-mark-all-present')));
        for (final id in [5001, 5002, 5003]) {
          await _tap(tester, find.byKey(ValueKey('mark-absent-$id')));
        }
        expect(find.text('30 unsaved changes'), findsOneWidget);
        await _tap(tester, find.byKey(const ValueKey('attendance-save')));
        expect(find.text('Some students are not marked'), findsNothing);
        expect(f.where('PUT', '/attendance/register'), hasLength(1));
        final records = jsonDecode(f.where('PUT', '/attendance/register').single.body)['records'] as List;
        expect(records, hasLength(30));
        expect(records.where((r) => r['status'] == 'ABSENT'), hasLength(3));

        Finder chip(String label, String value) => find.descendant(
          of: find.byKey(ValueKey('summary-$label')),
          matching: find.text(value),
        );
        expect(chip('Present', '27'), findsOneWidget);
        expect(chip('Absent', '3'), findsOneWidget);
        expect(chip('Attendance', '90%'), findsOneWidget);

        // Fresh GET from the backend shows the same saved state.
        final gets = f.where('GET', '/attendance/register').length;
        await c.loadRegister();
        await tester.pumpAndSettle();
        expect(f.where('GET', '/attendance/register').length, gets + 1);
        expect(chip('Present', '27'), findsOneWidget);
        expect(chip('Absent', '3'), findsOneWidget);
        expect(c.currentMark(5002), 'ABSENT');
        expect(c.currentMark(5030), 'PRESENT');
        expect(find.byKey(const ValueKey('attendance-print')), findsOneWidget,
            reason: 'CASE D: PDF available once recorded');
      });
      c.dispose();
    });

    testWidgets('EXISTING: PRESENT/ABSENT/LATE load, edit one, reload shows update', (tester) async {
      final f = AttendanceFixture();
      f.store[402]![1003] = 'ABSENT';
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(402));
        expect(find.byKey(const ValueKey('register-error')), findsNothing);
        expect(c.currentMark(1001), 'PRESENT');
        expect(c.currentMark(1002), 'LATE');
        expect(c.currentMark(1003), 'ABSENT');
        expect(find.text('Late (recorded earlier)'), findsOneWidget);
        final present = tester.widget<Semantics>(find.descendant(
          of: find.byKey(const ValueKey('mark-present-1001')),
          matching: find.byType(Semantics),
        ).first);
        expect(present.properties.selected, isTrue);
        Finder chip(String label, String value) => find.descendant(
          of: find.byKey(ValueKey('summary-$label')),
          matching: find.text(value),
        );
        expect(chip('Present', '1'), findsOneWidget);
        expect(chip('Absent', '1'), findsOneWidget);
        expect(chip('Late', '1'), findsOneWidget);

        await _tap(tester, find.byKey(const ValueKey('mark-present-1003')));
        await _tap(tester, find.byKey(const ValueKey('attendance-save')));
        expect(find.text('Attendance changes saved successfully.'), findsOneWidget);
        await c.loadRegister();
        await tester.pumpAndSettle();
        expect(c.currentMark(1003), 'PRESENT');
        expect(c.currentMark(1002), 'LATE');
        expect(chip('Present', '2'), findsOneWidget);
        expect(find.byKey(const ValueKey('attendance-print')), findsOneWidget);
      });
      c.dispose();
    });

    testWidgets('ZERO STUDENTS: valid lesson shows the no-enrolled-students state, not an error', (tester) async {
      final f = AttendanceFixture()..noStudents = true;
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        expect(find.text('No enrolled students were found for this class.'), findsOneWidget);
        expect(find.byKey(const ValueKey('register-error')), findsNothing);
        expect(find.textContaining('Something went wrong'), findsNothing);
      });
      expect(allLogs(), contains('Students: 0'));
      c.dispose();
    });

    testWidgets('HTTP 500: friendly message + Retry; terminal gets status/body; Retry keeps selection', (tester) async {
      const serverBody =
          '{"message":"Unknown column \'Attendance.recordedByUserId\' in \'field list\'"}';
      final f = AttendanceFixture()
        ..registerOverride = (_) => http.Response(serverBody, 500,
            headers: {'content-type': 'application/json'});
      ApiClient().setToken('super-secret-token');
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));

        expect(find.byKey(const ValueKey('register-error')), findsOneWidget);
        expect(find.text('The server could not complete this request. Please try again in a moment.'), findsOneWidget);
        expect(find.textContaining('Unknown column'), findsNothing, reason: 'no raw server detail for users');

        f.registerOverride = null;
        await _tap(tester, find.text('Retry'));
        expect(find.byKey(const ValueKey('register-error')), findsNothing);
        expect(find.text('Students (3)'), findsOneWidget);
        expect(c.timetableId, 401);
        expect(c.classId, 25);
        expect(c.dateYmd, '2026-10-05');
        final gets = f.where('GET', '/attendance/register');
        expect(gets, hasLength(2));
        expect(gets[1].url.queryParameters, gets[0].url.queryParameters,
            reason: 'Retry repeats the same request');
      });
      final out = allLogs();
      expect(out, contains('[ADMIN ATTENDANCE ERROR]'));
      expect(out, contains('Operation: loadRegister'));
      expect(out, contains('HTTP: 500'));
      expect(out, contains("Unknown column 'Attendance.recordedByUserId'"));
      expect(out, contains('Endpoint: GET /api/school-admin/attendance/register'));
      expect(out, contains('timetable_id: 401'));
      expect(out, isNot(contains('super-secret-token')));
      expect(out, isNot(contains('Authorization')));
      c.dispose();
    });

    testWidgets('MALFORMED 200: no crash, Retry, parse diagnostics', (tester) async {
      final f = AttendanceFixture()
        ..registerOverride = (_) => http.Response('<html>proxy error</html>', 200);
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('register-error')), findsOneWidget);
        expect(find.text('The server sent an unexpected response. Please try again.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        f.registerOverride = (_) => _json({'success': true, 'unexpected': 1});
        await _tap(tester, find.text('Retry'));
        expect(find.byKey(const ValueKey('register-error')), findsOneWidget);
      });
      expect(allLogs(), contains('Operation: loadRegister (parse)'));
      expect(allLogs(), contains('Code: INVALID_RESPONSE'));
      expect(allLogs(), contains('<html>proxy error</html>'));
      c.dispose();
    });

    testWidgets('404 LESSON_NOT_FOUND has its own message', (tester) async {
      final f = AttendanceFixture()
        ..registerOverride = (_) => _json({
              'message': 'Lesson not found for this class and academic year',
              'code': 'LESSON_NOT_FOUND',
            }, 404);
      final c = _controller();
      await _with(f, () async {
        await _pumpScreen(tester, c);
        await _chooseClass(tester, 'Form 3');
        await _tap(tester, _lessonCard(401));
        expect(find.text('The selected timetable lesson could not be found.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
      expect(allLogs(), contains('Code: LESSON_NOT_FOUND'));
      c.dispose();
    });

    test('nullable first-time fields and wrapped/partial responses parse', () {
      final reg = LessonRegister.tryParse({
        'attendance_recorded': false,
        'students': [
          {
            'student_id': '77',
            'student_name': 'Ayaan Farah',
            'emis_number': null,
            'enrolled': true,
            'attendance_id': null,
            'status': null,
            'recorded_by': null,
            'updated_by': null,
            'updated_at': null,
          },
          {'student_id': 78, 'student_name': 'Hodan', 'status': 'late'},
        ],
      })!;
      expect(reg.students.first.studentId, 77);
      expect(reg.students.first.status, isNull);
      expect(reg.students.first.emisNumber, isNull);
      expect(reg.students.last.status, 'LATE');
      expect(reg.lesson.timetableId, 0, reason: 'missing lesson context tolerated');
      expect(reg.summary.totalStudents, 2, reason: 'derived only when summary missing');
      expect(reg.summary.late, 1);
      expect(LessonRegister.tryParse({'success': true}), isNull);
      expect(LessonRegister.tryParse(null), isNull);
    });

    test('date is the local calendar day in YYYY-MM-DD (late evening stays the same day)', () async {
      final f = AttendanceFixture();
      final c = TakeAttendanceController(now: () => DateTime(2026, 10, 2, 23, 59));
      await _with(f, () async {
        c.setYears([_activeYear], _activeYear);
        await c.loadClasses();
        c.selectClass(25);
        await c.loadLessons();
      });
      expect(c.dateYmd, '2026-10-02');
      expect(f.where('GET', '/attendance/lessons').last.url.queryParameters['date'], '2026-10-02');
      expect(attendanceYmd(DateTime(2026, 1, 5)), '2026-01-05');
      c.dispose();
    });

    test('release-mode switch: nothing is logged when diagnostics are disabled', () async {
      attendanceDiagnosticsEnabled = false;
      final f = AttendanceFixture();
      final c = _controller();
      await _with(f, () => _openRegister(c, 401));
      expect(logs, isEmpty);
      c.dispose();
    });

    test('secret-looking JSON fields are redacted in logged bodies', () {
      expect(
        safeAttendanceBody('{"token":"abc","password":"p","student_name":"Ali"}'),
        '{"token":"***","password":"***","student_name":"Ali"}',
      );
    });
  });
}
