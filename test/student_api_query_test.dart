import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/students_service.dart';

void main() {
  Map<String, dynamic> student(int id) => {
    'id': id,
    'studentName': 'Student $id',
    'emisNumber': 'EMIS-$id',
  };

  test('omits every unselected student filter', () {
    expect(buildStudentListQuery(), isEmpty);
    expect(
      buildStudentListQuery(
        enrollmentStatus: '',
        studentStatus: ' ',
        search: '',
      ),
      isEmpty,
    );
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
      'academic_year_id': '7',
      'class_id': '3',
      'enrollment_status': 'Enrolled',
      'student_status': 'Active',
      'search': 'Amina',
      'page': '2',
      'limit': '25',
    });
    expect(
      Uri(queryParameters: query).query,
      isNot(contains('student_status=1')),
    );
    expect(Uri(queryParameters: query).query, isNot(contains('search=search')));
  });

  test('ignores zero identifiers and invalid pagination', () {
    expect(
      buildStudentListQuery(academicYearId: 0, classId: 0, page: 0, limit: -1),
      isEmpty,
    );
  });

  test('dashboard count uses pagination total instead of 50 returned rows', () {
    final page = parseStudentPageResponse({
      'students': List.generate(50, (index) => student(index + 1)),
      'pagination': {'page': 1, 'limit': 50, 'total': 581},
    });

    expect(page, isNotNull);
    expect(page!.students, hasLength(50));
    expect(page.limit, 50);
    expect(page.total, 581);
    expect(page.total, isNot(page.students.length));
    expect(page.total, isNot(page.limit));
  });

  test('dashboard count preserves a total equal to the returned rows', () {
    final page = parseStudentPageResponse({
      'students': List.generate(12, (index) => student(index + 1)),
      'pagination': {'page': 1, 'limit': 50, 'total': 12},
    });

    expect(page, isNotNull);
    expect(page!.students, hasLength(12));
    expect(page.total, 12);
  });
}
