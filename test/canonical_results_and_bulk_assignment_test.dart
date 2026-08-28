import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/services/student_service.dart';

void main() {
  test('student report preserves canonical backend result fields', () {
    final report = StudentResultReportModel.fromJson({
      'summary': {
        'final_percentage': 87.55,
        'max_marks': 100,
        'grade': 'A-',
        'position': 3,
        'class_size': 42,
        'status': 'PASS',
      },
      'results': [
        {'marks_obtained': 42, 'max_marks': 50},
      ],
    });
    expect(report.finalPercentage, 87.55);
    expect(report.finalMaxMarks, 100);
    expect(report.grade, 'A-');
    expect(report.position, 3);
    expect(report.classSize, 42);
    expect(report.results.single['max_marks'], 50);
  });

  test('academic performance prefers canonical fields', () {
    final value = StudentAcademicPerformance.fromJson({
      'performance': {
        'final_percentage': 73.25,
        'max_marks': 100,
        'grade': 'B-',
        'position': 4,
        'class_size': 31,
      },
    });
    expect(value.finalPercentage, 73.25);
    expect(value.grade, 'B-');
    expect(value.position, 4);
    expect(value.totalStudents, 31);
  });
}
