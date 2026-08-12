import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/school_admin/pages/admin_students.dart';
import 'package:kobac/school_admin/pages/student_detail_screen.dart';
import 'package:kobac/school_admin/pages/admin_class_details_screen.dart';
import 'package:kobac/school_admin/pages/admin_marks_screen.dart';

void main() {
  test('student admin interfaces compile', () {
    expect(const AdminStudentsScreen(), isNotNull);
    expect(
      const StudentDetailPage(studentId: 1, initialAcademicYearId: 2),
      isNotNull,
    );
    expect(
      const AdminClassDetailsScreen(classId: 3, className: 'Form One'),
      isNotNull,
    );
    expect(const AdminMarksScreen(), isNotNull);
  });
}
