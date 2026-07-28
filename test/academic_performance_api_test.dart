import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/academic_performance_service.dart';

void main() {
  test('student academic performance parses nullable position and subjects', () {
    final model = StudentAcademicPerformance.fromJson({
      'data': {
        'student': {'name': 'Student Name'},
        'academic_year': {'id': '2', 'name': '2026-2027'},
        'class': {'id': 17, 'name': 'Grade 2 A'},
        'performance': {
          'total_marks': 80,
          'maximum_marks': '100',
          'percentage': '80.5',
          'letter_grade': 'A',
          'result_status': 'pass',
          'class_position': null,
          'total_students_in_class': '35',
        },
        'subjects': [
          {
            'subject_name': 'Mathematics',
            'marks_obtained': 80,
            'maximum_marks': 100,
            'percentage': 80,
            'letter_grade': 'A',
            'result_status': 'pass',
          },
        ],
      },
    });

    expect(model.position, isNull);
    expect(model.totalStudents, 35);
    expect(model.subjects.single.name, 'Mathematics');
    expect(model.percentage, 80.5);
  });

  test('rankings preserve backend positions including ties', () {
    final response = ClassRankingResponse.fromJson({
      'data': {
        'students': [
          {'position': 1, 'student_id': 1, 'student_name': 'A'},
          {'position': 1, 'student_id': 2, 'student_name': 'B'},
        ],
        'summary': {},
      },
    });

    expect(response.students.map((item) => item.position), [1, 1]);
  });

  test('service uses exact contracts and never sends identity in password body', () {
    final source = File(
      'lib/services/academic_performance_service.dart',
    ).readAsStringSync();

    expect(source, contains('api/student/profile/change-password'));
    expect(source, contains("'current_password': currentPassword"));
    expect(source, contains('api/student/academic-performance'));
    expect(source, contains('student-rankings'));
    expect(source, contains('analytics/top-students'));
    expect(source, contains("'limit': '\$limit'"));
    expect(source, isNot(contains("'student_id':")));
    expect(source, isNot(contains("'school_id':")));
  });
}
