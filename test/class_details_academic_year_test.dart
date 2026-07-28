import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/classes_service.dart';

void main() {
  test('class details model preserves Students and filtered studentCount', () {
    final model = ClassModel.fromJson({
      'id': 17,
      'schoolId': '3',
      'name': 'Grade 2 A',
      'academicYear': {'id': 2, 'name': '2026-2027'},
      'studentCount': 1,
      'Students': [
        {
          'id': 301,
          'studentName': 'New One',
          'emisNumber': 'N1',
          'enrollmentId': 201,
          'enrollmentStatus': 'active',
        },
      ],
    });

    expect(model.studentCount, 1);
    expect(model.schoolId, 3);
    expect(model.students.single.id, 301);
    expect(model.students.single.enrollmentId, 201);
    expect(model.academicYear?.id, 2);
  });

  test(
    'class details request and page use selected academic_year_id and reload',
    () {
      final service = File(
        'lib/services/classes_service.dart',
      ).readAsStringSync();
      final screen = File(
        'lib/school_admin/pages/admin_class_details_screen.dart',
      ).readAsStringSync();

      expect(service, contains("'academic_year_id': '\$academicYearId'"));
      expect(screen, contains('Academic year'));
      expect(screen, contains('initialAcademicYearId'));
      expect(screen, contains('_academicYearId = value'));
      expect(screen, contains('await _loadStudents()'));
      expect(screen, contains('_studentCount = details.studentCount'));
      expect(screen, contains('_students = []'));
      expect(
        screen,
        contains('No students enrolled in this class for '),
      );
    },
  );
}
