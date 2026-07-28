import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/promotions_service.dart';
import 'package:kobac/school_admin/pages/promotion_batch_details_page.dart';

void main() {
  group('AcademicYear', () {
    test('parses snake_case backend fields and numeric active state', () {
      final year = AcademicYear.fromJson({
        'id': '7',
        'name': '2026-2027',
        'start_date': '2026-09-01',
        'end_date': '2027-06-30',
        'is_active': 1,
      });

      expect(year.id, 7);
      expect(year.name, '2026-2027');
      expect(year.startDate, DateTime(2026, 9, 1));
      expect(year.endDate, DateTime(2027, 6, 30));
      expect(year.isActive, isTrue);
    });
  });

  group('PromotionPreview', () {
    test('preserves known and unknown validation categories', () {
      final preview = PromotionPreview.fromJson({
        'can_process': false,
        'valid_students': [
          {'student_id': 10, 'full_name': 'Amina Ali'},
        ],
        'result_unavailable_students': [
          {'student_id': 11, 'full_name': 'Yusuf Noor', 'reason': 'No marks'},
        ],
        'custom_backend_validation': [
          {'student_id': 12, 'full_name': 'Hodan Omar', 'reason': 'Locked'},
        ],
      });

      expect(preview.canProcess, isFalse);
      expect(preview.categories['valid_students'], hasLength(1));
      expect(
        preview.categories['result_unavailable_students']!.first.reason,
        'No marks',
      );
      expect(preview.categories['custom_backend_validation'], hasLength(1));
    });
  });

  group('Promotion requests', () {
    test('eligible-student query uses required source ID keys', () {
      final query = PromotionsService.studentQueryParameters(
        fromAcademicYearId: 1,
        classId: 19,
      );

      expect(query['from_academic_year_id'], '1');
      expect(query['class_id'], '19');
      expect(query, isNot(contains('academic_year_id')));
      expect(query, isNot(contains('from_class_id')));
    });

    test('preview/process snapshot contains numeric IDs, not labels', () {
      final request = PromotionRequest(
        fromAcademicYearId: 1,
        toAcademicYearId: 2,
        fromClassId: 19,
        toClassId: 17,
        decision: 'promoted',
        studentIds: [490, 491],
      );

      expect(request.toJson(), {
        'from_academic_year_id': 1,
        'to_academic_year_id': 2,
        'from_class_id': 19,
        'to_class_id': 17,
        'decision': 'promoted',
        'student_ids': [490, 491],
      });
      expect(request.studentIds, isA<List<int>>());
    });

    test('snapshot is immutable after preview construction', () {
      final selected = [490];
      final request = PromotionRequest(
        fromAcademicYearId: 1,
        fromClassId: 19,
        decision: 'graduated',
        studentIds: selected,
      );
      selected.add(491);

      expect(request.studentIds, [490]);
      expect(() => request.studentIds.add(492), throwsUnsupportedError);
    });
  });

  test('eligible students parse from the documented data array', () {
    final students = parsePromotionStudentsResponse({
      'success': true,
      'data': [
        {
          'student_id': '490',
          'student_name': 'Amina Ali',
          'emis_number': 'EMIS-490',
          'class_name': 'Grade 1 A',
          'final_percentage': '78.5',
          'result_status': 'PASS',
          'is_eligible': true,
        },
      ],
    });

    expect(students, hasLength(1));
    expect(students.single.id, 490);
    expect(students.single.name, 'Amina Ali');
    expect(students.single.emis, 'EMIS-490');
    expect(students.single.percentage, 78.5);
    expect(students.single.eligible, isTrue);
  });

  test('ExamModel parses academic year relation', () {
    final exam = ExamModel.fromJson({
      'id': 3,
      'name': 'Final',
      'academic_year': {'id': '7', 'name': '2026-2027'},
    });

    expect(exam.academicYearId, 7);
    expect(exam.academicYearName, '2026-2027');
  });

  group('Promotion history grouping', () {
    PromotionHistoryItem item(int id, String date) =>
        PromotionHistoryItem.fromJson({
          'id': id,
          'student_id': id,
          'student_name': 'Student $id',
          'from_academic_year_id': 1,
          'from_academic_year_name': '2025-2026',
          'to_academic_year_id': 2,
          'to_academic_year_name': '2026-2027',
          'from_class_id': 19,
          'from_class_name': 'Grade 1 A',
          'to_class_id': 17,
          'to_class_name': 'Grade 2 A',
          'decision': 'promoted',
          'processed_at': date,
        });

    test('individual student records form one presentation batch', () {
      final groups = groupPromotionHistory([
        item(490, '2026-07-28T14:48:45.000Z'),
        item(491, '2026-07-28T14:48:45.000Z'),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.studentCount, 2);
      expect(groups.single.first.fromClass, 'Grade 1 A');
      expect(groups.single.first.toYear, '2026-2027');
    });

    test('operations with different timestamps are not merged', () {
      final groups = groupPromotionHistory([
        item(490, '2026-07-28T14:48:45.000Z'),
        item(491, '2026-07-29T14:48:45.000Z'),
      ]);

      expect(groups, hasLength(2));
    });

    test('raw ISO timestamp is formatted for display', () {
      expect(
        formatPromotionDate('2026-07-28T14:48:45.000Z'),
        isNot(contains('T')),
      );
      expect(
        formatPromotionDate('2026-07-28T14:48:45.000Z'),
        contains('28 Jul 2026'),
      );
    });
  });
}
