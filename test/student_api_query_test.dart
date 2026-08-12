import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/students_service.dart';

void main() {
  test('omits every unselected student filter', () {
    expect(buildStudentListQuery(), isEmpty);
    expect(buildStudentListQuery(enrollmentStatus: '', studentStatus: ' ', search: ''), isEmpty);
  });

  test('uses only supported selected filters and pagination', () {
    final query = buildStudentListQuery(
      academicYearId: 7,
      classId: 3,
      enrollmentStatus: 'Enrolled',
      studentStatus: 'Active',
      search: 'Amina',
      page: 2,
      limit: 25,
    );
    expect(query, {
      'academic_year_id': '7', 'class_id': '3',
      'enrollment_status': 'Enrolled', 'student_status': 'Active',
      'search': 'Amina', 'page': '2', 'limit': '25',
    });
    expect(Uri(queryParameters: query).query, isNot(contains('student_status=1')));
    expect(Uri(queryParameters: query).query, isNot(contains('search=search')));
  });

  test('ignores zero identifiers and invalid pagination', () {
    expect(buildStudentListQuery(academicYearId: 0, classId: 0, page: 0, limit: -1), isEmpty);
  });
}
