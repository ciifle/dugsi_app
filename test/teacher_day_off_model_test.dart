import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/teacher_day_off_service.dart';

void main() {
  group('TeacherDayOff', () {
    test('shared day helpers map labels and enum codes', () {
      expect(dayCodeToLabel('thu'), 'Thursday');
      expect(dayLabelToCode('Friday'), 'FRI');
      expect(dayLabelToCode('unknown'), isNull);
    });
    test('parses API payload and nested teacher', () {
      final value = TeacherDayOff.fromJson({
        'id': 7,
        'teacher_id': 12,
        'day': 'mon',
        'is_active': true,
        'teacher': {'id': 12, 'full_name': 'Amina Ali'},
      });
      expect(value.teacherId, 12);
      expect(value.day, 'MON');
      expect(value.dayLabel, 'Monday');
      expect(value.teacherName, 'Amina Ali');
      expect(value.isActive, isTrue);
    });

    test('supports camelCase and inactive numeric values', () {
      final value = TeacherDayOff.fromJson({
        'id': '8',
        'teacherId': '13',
        'day': 'FRI',
        'isActive': 0,
      });
      expect(value.teacherId, 13);
      expect(value.isActive, isFalse);
      expect(value.teacherName, 'Teacher #13');
    });
  });
}
