import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String service;
  late String screen;

  setUpAll(() {
    service = File('lib/services/timetables_service.dart').readAsStringSync();
    screen = File(
      'lib/school_admin/pages/admin_timetable_screen.dart',
    ).readAsStringSync();
  });

  test('deleteTimetablesForYear hits the exact backend endpoint', () {
    expect(
      service,
      contains("apiUrl('\$_base/academic-year/\$academicYearId')"),
    );
    expect(
      service,
      contains('Future<TimetableResult<int?>> deleteTimetablesForYear'),
    );
    // Existing single-slot delete path must remain untouched.
    expect(
      service,
      contains("Future<TimetableResult<bool>> deleteTimetable(int id)"),
    );
    expect(service, contains("apiUrl('\$_base/\$id')"));
  });

  test(
    'timetable screen exposes an explicit Delete Year Timetables action',
    () {
      expect(screen, contains('Delete Year Timetables'));
      expect(screen, contains('_openDeleteYearTimetablesDialog'));
      // Not a bare/casual icon-only button — must be paired with a text label.
      expect(screen, contains("label: const Text('Delete Year Timetables')"));
    },
  );

  test('confirmation dialog uses the required destructive copy', () {
    expect(screen, contains('Clear Academic Year Timetable?'));
    expect(
      screen,
      contains('This will delete only the timetable entries for'),
    );
    expect(screen, contains('It will NOT delete:'));
    expect(screen, contains("child: const Text('Clear Timetable')"));
    expect(
      screen,
      contains(
        'This is the active academic year. Clearing its '
        'timetable is allowed and will not deactivate the year.',
      ),
    );
    expect(screen, contains('_yearId == null'));
  });

  test(
    'no frontend restriction blocks clearing the active year\'s timetable',
    () {
      // The confirm button is enabled purely on year selection — there is no
      // isActive-based gate (e.g. "activate another year first").
      expect(screen, isNot(contains('Activate another')));
      expect(screen, isNot(contains('deactivate the year first')));
      expect(screen, isNot(contains('inactive academic year')));
    },
  );
}
