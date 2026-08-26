import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/exam_hall_service.dart';

void main() {
  group('Exam Hall models parse safe backend shapes', () {
    test('live halls envelope parses a non-empty list', () {
      final items = parseExamHallListResponse({
        'halls': [
          {'id': '7', 'name': 'Hall 1', 'capacity': '40', 'status': 'ACTIVE'},
        ],
      });
      final hall = ExamHall.fromJson(
        Map<String, dynamic>.from(items.single as Map),
      );
      expect((hall.name, hall.capacity, hall.isActive), ('Hall 1', 40, true));
    });

    test('empty halls envelope remains a genuine empty result', () {
      expect(parseExamHallListResponse({'halls': <dynamic>[]}), isEmpty);
    });

    test('malformed successful hall response is not treated as empty', () {
      expect(
        () => parseExamHallListResponse({'message': 'ok'}),
        throwsFormatException,
      );
    });

    test('ACTIVE and INACTIVE statuses map to the correct badge state', () {
      expect(ExamHall.fromJson({'status': 'ACTIVE'}).isActive, isTrue);
      expect(ExamHall.fromJson({'status': 'INACTIVE'}).isActive, isFalse);
    });

    test(
      'decimal string capacities remain usable in random selection totals',
      () {
        final halls = [
          ExamHall.fromJson({'id': '1', 'capacity': '30.0'}),
          ExamHall.fromJson({'id': 2, 'capacity': 35.0}),
        ];
        expect(halls.fold<int>(0, (total, hall) => total + hall.capacity), 65);
      },
    );

    test('student list top-level id is the allocation student primary key', () {
      final student = ExamHallAllocationStudent.fromJson({
        'id': '19',
        'studentName': 'Maryan Nuur',
      });
      expect(student.studentId, 19);
    });

    test(
      'manual preview payload contains unique positive integer student IDs',
      () {
        final payload = buildManualAllocationPayload(
          academicYearId: 1,
          levelId: 2,
          classId: 3,
          examId: 4,
          hallId: 5,
          selectedStudentIds: {11, 12, 13, 14, 15},
        );
        expect(payload['student_ids'], <int>[11, 12, 13, 14, 15]);
        expect(
          (payload['student_ids'] as List).every((id) => id is int && id > 0),
          isTrue,
        );
      },
    );

    test('invalid manual student IDs are blocked before the API request', () {
      expect(
        () => buildManualAllocationPayload(
          academicYearId: 1,
          levelId: 2,
          classId: 3,
          examId: 4,
          hallId: 5,
          selectedStudentIds: {0, 12},
        ),
        throwsArgumentError,
      );
    });

    test(
      'random preview payload uses positive integer hall and class lists',
      () {
        final payload = buildRandomAllocationPayload(
          academicYearId: 1,
          levelId: 2,
          examId: 3,
          classId: 4,
          selectedHallIds: {8, 7},
        );
        expect(payload['hall_ids'], <int>[7, 8]);
        expect(payload['class_ids'], <int>[4]);
      },
    );

    test('level and hall accept string numbers and nullable fields', () {
      final level = SchoolLevel.fromJson({
        'id': '2',
        'name': 'Dhexe',
        'class_count': '8',
        'is_active': 1,
      });
      final hall = ExamHall.fromJson({
        'hall_id': '3',
        'hall_name': 'Hall 2',
        'capacity': '45',
        'status': 'active',
      });
      expect((level.id, level.classCount, level.isActive), (2, 8, true));
      expect((hall.id, hall.capacity, hall.isActive), (3, 45, true));
    });

    test('manual preview preserves backend authority', () {
      final preview = ExamHallAllocationPreview.fromJson({
        'selected': 15,
        'valid': 14,
        'invalid': 1,
        'can_process': false,
        'students': [
          {'student_id': 8, 'valid': false, 'reason': 'Hall full'},
        ],
      });
      expect(preview.canProcess, isFalse);
      expect(preview.students.single.reason, 'Hall full');
    });

    test('manual preview parses backend count field names', () {
      final preview = ExamHallAllocationPreview.fromJson({
        'selected_count': '10',
        'valid_count': 9,
        'invalid_count': '1',
        'hall_capacity': '30.0',
        'can_process': true,
      });
      expect((preview.selected, preview.valid, preview.invalid), (10, 9, 1));
      expect(preview.totalCapacity, 30);
      expect(preview.canProcess, isTrue);
    });

    test('random preview reads capacity summary without local reshuffle', () {
      final preview = ExamHallAllocationPreview.fromJson({
        'summary': {
          'total_students': '95',
          'total_capacity': 90,
          'allocatable': 90,
          'unallocated': 5,
        },
        'can_process': false,
      });
      expect(
        (preview.totalStudents, preview.totalCapacity, preview.unallocated),
        (95, 90, 5),
      );
    });

    test('backend-approved partial random allocation remains processable', () {
      final preview = ExamHallAllocationPreview.fromJson({
        'total_students': 211,
        'total_capacity': 30,
        'available_capacity': 30,
        'allocatable_count': 30,
        'unallocated_count': 181,
        'can_process': true,
        'preview_token': 'preview-30',
        'allocation_plan': {'batch': 1},
      });
      expect(preview.availableCapacity, 30);
      expect(preview.allocatable, 30);
      expect(preview.unallocated, 181);
      expect(preview.previewToken, 'preview-30');
      expect(preview.allocationPlan, {'batch': 1});
      expect(
        canProcessAllocationPreview(
          preview: preview,
          isRandom: true,
          previewIsCurrent: true,
        ),
        isTrue,
      );
    });

    test('preview envelope preserves the exact allocation plan object', () {
      final plan = [
        {
          'hall_id': 7,
          'students': [11, 12],
        },
      ];
      final preview = parseAllocationPreviewResponse({
        'preview': {'allocatable_count': 2, 'can_process': true},
        'allocation_plan': plan,
      });
      expect(identical(preview.allocationPlan, plan), isTrue);
    });

    test('preview parser accepts data and nested-preview plan locations', () {
      final dataPlan = {'source': 'data'};
      final nestedPlan = {'source': 'preview'};
      expect(
        identical(
          parseAllocationPreviewResponse({
            'data': {'can_process': true, 'allocation_plan': dataPlan},
          }).allocationPlan,
          dataPlan,
        ),
        isTrue,
      );
      expect(
        identical(
          parseAllocationPreviewResponse({
            'preview': {'can_process': true, 'allocation_plan': nestedPlan},
          }).allocationPlan,
          nestedPlan,
        ),
        isTrue,
      );
    });

    test('random process remains disabled when preview omitted its plan', () {
      const preview = ExamHallAllocationPreview(
        allocatable: 30,
        canProcess: true,
      );
      expect(
        canProcessAllocationPreview(
          preview: preview,
          isRandom: true,
          previewIsCurrent: true,
        ),
        isFalse,
      );
    });

    test('random process sends the unchanged preview allocation plan', () {
      final plan = {
        'halls': [
          {
            'hall_id': 7,
            'student_ids': [11, 12],
          },
        ],
      };
      final payload = buildRandomProcessPayload(
        previewRequest: {
          'academic_year_id': 1,
          'level_id': 2,
          'exam_id': 3,
          'hall_ids': [7],
        },
        allocationPlan: plan,
      );
      expect(identical(payload['allocation_plan'], plan), isTrue);
      expect(payload['hall_ids'], [7]);
    });

    test('random process is disabled after preview inputs change', () {
      const preview = ExamHallAllocationPreview(
        allocatable: 30,
        unallocated: 181,
        canProcess: true,
      );
      expect(
        canProcessAllocationPreview(
          preview: preview,
          isRandom: true,
          previewIsCurrent: false,
        ),
        isFalse,
      );
    });

    test('backend-approved manual preview does not require random counts', () {
      const preview = ExamHallAllocationPreview(
        selected: 8,
        valid: 8,
        canProcess: true,
      );
      expect(
        canProcessAllocationPreview(
          preview: preview,
          isRandom: false,
          previewIsCurrent: true,
        ),
        isTrue,
      );
    });

    test('admin pass card parses IDs and nullable display fields safely', () {
      final pass = AdminExamPassCard.fromJson({
        'allocation_id': '101',
        'student_id': 12,
        'student_name': 'Maryan Nuur',
        'emis_number': 158,
        'class_name': 'Grade 6 A',
        'exam_name': 'Final',
        'hall_name': 'Hall 2',
        'seat_number': 17,
      });
      expect(pass.allocationId, 101);
      expect(pass.studentName, 'Maryan Nuur');
      expect(pass.emis, '158');
      expect(pass.shift, isEmpty);
    });

    test('admin pass list parses envelopes and rejects malformed success', () {
      expect(
        parseExamPassListResponse({
          'passes': [
            {'allocation_id': 101},
          ],
        }),
        hasLength(1),
      );
      expect(
        parseExamPassListResponse({
          'data': [
            {'allocation_id': 102},
          ],
        }),
        hasLength(1),
      );
      expect(
        () => parseExamPassListResponse({'message': 'ok'}),
        throwsFormatException,
      );
    });

    test('admin pass filters use only selected backend query names', () {
      expect(
        buildExamPassFilters(
          academicYearId: 1,
          examId: 2,
          hallId: 3,
          levelId: 4,
          classId: 5,
          shift: 'morning',
        ),
        {
          'academic_year_id': '1',
          'exam_id': '2',
          'hall_id': '3',
          'level_id': '4',
          'class_id': '5',
          'shift': 'morning',
        },
      );
    });

    test(
      'selected pass print payload contains sorted allocation integer IDs',
      () {
        final payload = buildSelectedPassPrintPayload({103, 101, 102});
        expect(payload, {
          'allocation_ids': <int>[101, 102, 103],
        });
        expect(
          (payload['allocation_ids'] as List).every(
            (id) => id is int && id > 0,
          ),
          isTrue,
        );
      },
    );

    test('individual pass print path uses the allocation ID', () {
      expect(
        individualExamPassPrintPath(101),
        'api/school-admin/exam-halls/passes/101/print',
      );
      expect(() => individualExamPassPrintPath(0), throwsArgumentError);
    });

    test('select all derives only positive loaded allocation IDs', () {
      final loaded = [
        const AdminExamPassCard(allocationId: 101, studentId: 1),
        const AdminExamPassCard(allocationId: 102, studentId: 1),
        const AdminExamPassCard(allocationId: 0, studentId: 9),
      ];
      final selected = selectLoadedPassAllocationIds(loaded);
      expect(selected, {101, 102});
      selected.clear();
      expect(selected, isEmpty);
    });
  });
}
