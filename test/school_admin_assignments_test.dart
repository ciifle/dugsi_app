import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';

void main() {
  group('AssignmentModel.fromJson (PATCH response shape)', () {
    test('parses assignment with Teacher, Class, Subject (capitalized)', () {
      final json = {
        'id': 5,
        'teacherId': 2,
        'classId': 3,
        'subjectId': 1,
        'teacher_id': 2,
        'class_id': 3,
        'subject_id': 1,
        'Teacher': {'id': 2, 'fullName': 'Jane Doe', 'email': 'jane@school.com'},
        'Class': {'id': 3, 'name': 'Grade 10A'},
        'Subject': {'id': 1, 'name': 'Mathematics'},
      };
      final a = AssignmentModel.fromJson(json);
      expect(a.id, 5);
      expect(a.teacherId, 2);
      expect(a.teacherName, 'Jane Doe');
      expect(a.classId, 3);
      expect(a.className, 'Grade 10A');
      expect(a.subjectId, 1);
      expect(a.subjectName, 'Mathematics');
    });

    test('parses assignment with lowercase teacher, class, subject', () {
      final json = {
        'id': 1,
        'teacher': {'id': 10, 'fullName': 'John Smith', 'email': 'john@school.com'},
        'class': {'id': 5, 'name': 'Grade 8B'},
        'subject': {'id': 2, 'name': 'Science'},
      };
      final a = AssignmentModel.fromJson(json);
      expect(a.id, 1);
      expect(a.teacherId, 10);
      expect(a.teacherName, 'John Smith');
      expect(a.classId, 5);
      expect(a.className, 'Grade 8B');
      expect(a.subjectId, 2);
      expect(a.subjectName, 'Science');
    });
  });
}
