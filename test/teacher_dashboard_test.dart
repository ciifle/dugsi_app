import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/teacher_service.dart';

void main() {
  group('TeacherTimetableEntryModel', () {
    test('fromJson parses nested period and shift', () {
      final json = {
        'id': 1,
        'day': 'Monday',
        'class': {'id': 1, 'name': 'Grade 6A'},
        'subject': {'id': 1, 'name': 'Math'},
        'period': {
          'id': 10,
          'name': 'Period 1',
          'period_number': 1,
          'shift': 'MORNING',
          'start_time': '08:00:00',
          'end_time': '08:45:00',
        },
      };
      final t = TeacherTimetableEntryModel.fromJson(json);
      expect(t.periodId, 10);
      expect(t.period?.name, 'Period 1');
      expect(t.period?.shift, 'MORNING');
      expect(t.startTime, '08:00');
      expect(t.endTime, '08:45');
    });

    test('fromJson falls back to top-level start_time/end_time if period missing', () {
      final json = {
        'id': 2,
        'day': 'Tuesday',
        'start_time': '09:00',
        'end_time': '10:00',
        'class': {'id': 2, 'name': 'Grade 7B'},
        'subject': {'id': 2, 'name': 'Science'},
      };
      final t = TeacherTimetableEntryModel.fromJson(json);
      expect(t.period, isNull);
      expect(t.startTime, '09:00');
      expect(t.endTime, '10:00');
    });

    test('fromJson handles lowercase afternoon shift correctly', () {
      final json = {
        'id': 3,
        'day': 'Wednesday',
        'period': {
          'id': 11,
          'name': 'Period 5',
          'period_number': 5,
          'shift': 'afternoon',
        },
      };
      final t = TeacherTimetableEntryModel.fromJson(json);
      expect(t.period?.shift, 'afternoon');
    });

    test('fromJson handles exact API response format with capitalized Period, Class, Subject', () {
      final json = {
        "id": 38,
        "classId": 1,
        "subjectId": 1,
        "teacherId": 4,
        "periodId": 1,
        "day": "MON",
        "startTime": "08:00:00",
        "endTime": "08:45:00",
        "Class": {
          "id": 1,
          "name": "6A"
        },
        "Subject": {
          "id": 1,
          "name": "MATH"
        },
        "Period": {
          "id": 1,
          "name": "PERIOD 1",
          "periodNumber": 1,
          "shift": "MORNING",
          "startTime": "08:00:00",
          "endTime": "08:45:00"
        }
      };
      final t = TeacherTimetableEntryModel.fromJson(json);
      expect(t.id, 38);
      expect(t.className, '6A');
      expect(t.subjectName, 'MATH');
      expect(t.periodId, 1);
      expect(t.period?.name, 'PERIOD 1');
      expect(t.period?.shift, 'MORNING');
      expect(t.startTime, '08:00');
      expect(t.endTime, '08:45');
    });
  });

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

    test('assignment display format Subject — Class from class and subject names', () {
      final a = TeacherAssignmentModel(
        id: 1,
        class_: {'id': 5, 'name': 'Grade 6A'},
        subject: {'id': 1, 'name': 'Math'},
      );
      expect(a.subjectName, 'Math');
      expect(a.classDisplayName, 'Grade 6A');
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

    test('when assignedClasses is empty but assignments exist, derives assignedClasses from assignments', () {
      final json = {
        'assignedClasses': [],
        'assignments': [
          {'id': 1, 'class': {'id': 10, 'name': 'Grade 10A'}, 'subject': {'id': 1, 'name': 'Math'}},
          {'id': 2, 'class': {'id': 20, 'name': 'Grade 10B'}, 'subject': {'id': 2, 'name': 'Science'}},
        ],
        'timetables': [],
      };
      final d = TeacherDashboardModel.fromJson(json);
      expect(d.assignments.length, 2);
      expect(d.assignedClasses.length, 2);
      expect(d.assignedClasses.map((c) => c.id).toList(), [10, 20]);
      expect(d.assignedClasses.map((c) => c.displayName).toList(), ['Grade 10A', 'Grade 10B']);
    });

    test('derived assignedClasses deduplicates by classId', () {
      final json = {
        'assignedClasses': [],
        'assignments': [
          {'id': 1, 'class': {'id': 5, 'name': 'Grade 5'}, 'subject': {'id': 1, 'name': 'Math'}},
          {'id': 2, 'class': {'id': 5, 'name': 'Grade 5'}, 'subject': {'id': 2, 'name': 'Science'}},
        ],
        'timetables': [],
      };
      final d = TeacherDashboardModel.fromJson(json);
      expect(d.assignedClasses.length, 1);
      expect(d.assignedClasses.first.id, 5);
      expect(d.assignedClasses.first.displayName, 'Grade 5');
    });

    test('parses snake_case keys assigned_classes and timetable', () {
      final json = {
        'assigned_classes': [
          {'id': 1, 'name': 'Class A'},
        ],
        'assignments': [],
        'timetable': [
          {'id': 1, 'day': 'Monday', 'startTime': '09:00', 'endTime': '10:00', 'classId': 1, 'className': 'Class A', 'subjectId': 1, 'subjectName': 'Math'},
        ],
      };
      final d = TeacherDashboardModel.fromJson(json);
      expect(d.assignedClasses.length, 1);
      expect(d.assignedClasses.first.displayName, 'Class A');
      expect(d.timetables.length, 1);
      expect(d.timetables.first.classDisplayName, 'Class A');
      expect(d.timetables.first.subjectDisplayName, 'Math');
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

  group('TeacherResult 403 handling', () {
    test('TeacherError with statusCode 403 indicates teacher profile or permission issue', () {
      final err = TeacherError('Teacher profile not found. Contact school admin.', 403);
      expect(err.statusCode, 403);
      expect(err.message, contains('Teacher'));
    });
  });

  group('TeacherAssignedClassModel', () {
    test('displayName returns Unassigned when id is 0', () {
      final c = TeacherAssignedClassModel.fromJson({'id': 0, 'name': ''});
      expect(c.displayName, 'Unassigned');
    });
  });
}
