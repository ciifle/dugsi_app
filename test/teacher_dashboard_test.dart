import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/teacher_service.dart';

void main() {
  group('TeacherAssignmentModel', () {
    test('classDisplayName returns Unassigned when classId is 0', () {
      final a = TeacherAssignmentModel(
        id: 1,
        class_: {'id': 0, 'name': ''},
        subject: {'id': 1, 'name': 'Math'},
      );
      expect(a.classDisplayName, 'Unassigned');
    });

    test('classDisplayName returns Unassigned when className is empty', () {
      final a = TeacherAssignmentModel(
        id: 1,
        class_: {'id': 0, 'name': ''},
        subject: {'id': 1, 'name': 'Math'},
      );
      expect(a.classId, 0);
      expect(a.classDisplayName, 'Unassigned');
    });

    test('classDisplayName returns class name when present', () {
      final a = TeacherAssignmentModel(
        id: 1,
        class_: {'id': 5, 'name': 'Grade 6A'},
        subject: {'id': 1, 'name': 'Math'},
      );
      expect(a.classDisplayName, 'Grade 6A');
    });

    test('fromJson parses nested class and subject', () {
      final json = {
        'id': 10,
        'class': {'id': 2, 'name': 'Grade 8B'},
        'subject': {'id': 3, 'name': 'Science'},
      };
      final a = TeacherAssignmentModel.fromJson(json);
      expect(a.classDisplayName, 'Grade 8B');
      expect(a.subjectName, 'Science');
    });

    test('fromJson flat class_id/class_name yields classDisplayName Unassigned when missing', () {
      final json = {
        'id': 10,
        'class_id': null,
        'class_name': null,
        'subject_id': 1,
        'subject_name': 'Art',
      };
      final a = TeacherAssignmentModel.fromJson(json);
      expect(a.classDisplayName, 'Unassigned');
    });
  });

  group('TeacherDashboardModel.fromJson', () {
    test('parses assignedClasses, assignments, timetables', () {
      final json = {
        'assignedClasses': [
          {'id': 1, 'name': 'Grade 6A'},
          {'id': 2, 'name': 'Grade 8B'},
        ],
        'assignments': [
          {'id': 1, 'class': {'id': 1, 'name': 'Grade 6A'}, 'subject': {'id': 1, 'name': 'Mathematics'}},
        ],
        'timetables': [
          {
            'id': 1,
            'day': 'Sunday',
            'start_time': '08:00',
            'end_time': '09:00',
            'class': {'id': 1, 'name': 'Grade 6A'},
            'subject': {'id': 1, 'name': 'Mathematics'},
          },
        ],
      };
      final d = TeacherDashboardModel.fromJson(json);
      expect(d.assignedClasses.length, 2);
      expect(d.assignedClasses[0].displayName, 'Grade 6A');
      expect(d.assignments.length, 1);
      expect(d.assignments.first.classDisplayName, 'Grade 6A');
      expect(d.timetables.length, 1);
      expect(d.timetables.first.classDisplayName, 'Grade 6A');
      expect(d.timetables.first.subjectDisplayName, 'Mathematics');
    });

    test('timetable with missing class shows Unassigned', () {
      final json = {
        'assignedClasses': [],
        'assignments': [],
        'timetables': [
          {'id': 1, 'day': 'Mon', 'start_time': '08:00', 'end_time': '09:00', 'class_id': 0, 'subject_name': 'Math'},
        ],
      };
      final d = TeacherDashboardModel.fromJson(json);
      expect(d.timetables.length, 1);
      expect(d.timetables.first.classDisplayName, 'Unassigned');
    });
  });

  group('TeacherAssignedClassModel', () {
    test('displayName returns Unassigned when id is 0', () {
      final c = TeacherAssignedClassModel.fromJson({'id': 0, 'name': ''});
      expect(c.displayName, 'Unassigned');
    });
  });
}
