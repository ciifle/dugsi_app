import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/student_service.dart';

void main() {
  test('StudentAcademicYearOption.fromJson parses nested and flat shapes', () {
    final nested = StudentAcademicYearOption.fromJson({
      'academic_year': {'id': 3, 'name': '2026-2027'},
      'is_current': true,
      'class': {'name': 'Grade 6 B'},
      'is_active': true,
      'enrollment_status': 'active',
      'results_released': true,
      'has_released_marks': true,
    });
    expect(nested.id, 3);
    expect(nested.name, '2026-2027');
    expect(nested.isCurrent, isTrue);
    expect(nested.historicalClassName, 'Grade 6 B');
    expect(nested.enrollmentStatus, 'active');
    expect(nested.resultsReleased, isTrue);
    expect(nested.isActive, isTrue);
    expect(nested.hasReleasedMarks, isTrue);

    final flat = StudentAcademicYearOption.fromJson({
      'id': 2,
      'name': '2025-2026',
      'isCurrent': false,
      'className': 'Grade 5 A',
    });
    expect(flat.id, 2);
    expect(flat.isCurrent, isFalse);
    expect(flat.historicalClassName, 'Grade 5 A');
    expect(flat.resultsReleased, isNull);
  });

  test('service methods target the documented student-scoped endpoints', () {
    final service = File(
      'lib/services/student_service.dart',
    ).readAsStringSync();

    expect(service, contains("apiUrl('\$_base/academic-years')"));
    expect(
      service,
      contains('Future<StudentResult<List<StudentAcademicYearOption>>>'),
    );
    expect(service, contains('listAcademicYears() async'));

    expect(service, contains("'\$_base/exams'"));
    expect(service, contains("'academic_year_id': '\$academicYearId'"));

    expect(service, contains("'\$_base/results/\$examId'"));

    expect(
      service,
      contains("params['academic_year_id'] = '\$academicYearId'"),
    );

    // Marks history contract is unconfirmed — must remain untouched.
    expect(
      service,
      contains('Future<StudentResult<List<StudentMarkModel>>> listMarks({'),
    );
    expect(service, contains('int? academicYearId,\n    int? examId,'));
    expect(
      service,
      contains("params['academic_year_id'] = academicYearId.toString()"),
    );
  });

  test('academic numeric parsing accepts strings and preserves decimals', () {
    final mark = StudentMarkModel.fromJson({
      'marks_obtained': '6.5',
      'max_marks': 10,
      'percentage': '65.0',
      'subject': {'name': 'Arabic'},
      'exam': {'name': 'Monthly Exam'},
    });
    expect(mark.marksObtained, 6.5);
    expect(mark.percentage, 65.0);

    final report = StudentResultReportModel.fromJson({
      'data': {
        'exam': {'id': 4, 'name': 'Final Exam'},
        'subjects': [
          {'percentage': 93, 'marks_obtained': '93.4', 'max_marks': 100},
          {'percentage': '88.5', 'marks_obtained': null, 'max_marks': null},
        ],
        'summary': {'percentage': '90.75', 'result': 'pass'},
      },
    });
    expect(report.summary?['percentage'], 90.75);
    expect(report.summary?['status'], 'pass');
    expect(report.summary?['position'], isNull);
    expect(report.results.first['percentage'], 93);
    expect(report.results.last['percentage'], 88.5);
    expect(report.results.last['marks_obtained'], isNull);
  });

  test('academic history page never computes pass/fail locally', () {
    final page = File(
      'lib/student/pages/academic_history_page.dart',
    ).readAsStringSync();
    expect(page, isNot(contains('>= 50')));
    expect(page, isNot(contains('.round()')));
    expect(page, contains("summary['status']"));
    expect(page, contains('listMarks(academicYearId: yearId)'));

    final resultsPage = File(
      'lib/student/pages/student_result.dart',
    ).readAsStringSync();
    expect(resultsPage, isNot(contains('passMark')));
    expect(resultsPage, isNot(contains('_examWeights')));
  });

  test(
    'entry points are wired into drawer, sidebar, and web shell exactly once each',
    () {
      final drawer = File(
        'lib/student/widgets/student_drawer.dart',
      ).readAsStringSync();
      final sidebar = File(
        'lib/student/widgets/student_web_sidebar.dart',
      ).readAsStringSync();
      final shell = File(
        'lib/student/widgets/student_web_shell.dart',
      ).readAsStringSync();

      expect('Academic History'.allMatches(drawer).length, 1);
      expect(drawer, contains('StudentAcademicHistoryPage()'));

      expect("pageKey: 'academicHistory'".allMatches(sidebar).length, 1);

      expect(shell, contains("case 'academicHistory':"));
      expect(
        shell,
        contains('StudentAcademicHistoryPage(embedBodyOnly: true)'),
      );

      // Student change password must stay out of the drawer/sidebar.
      expect(drawer, isNot(contains("Change Password")));
      expect(sidebar, isNot(contains("label: 'Change Password'")));
    },
  );
}
