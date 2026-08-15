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
    expect(screen, contains('Delete Academic Year Timetables?'));
    expect(screen, contains('Classes, students, subjects, marks, and'));
    expect(screen, contains('attendance are NOT being deleted.'));
    expect(screen, contains("child: const Text('Delete Timetables')"));
    expect(screen, contains('_yearId == null'));
  });
}
