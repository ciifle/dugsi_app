import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/class_merge_service.dart';

void main() {
  test('ClassMergeRequest.toJson matches the exact backend payload shape', () {
    final request = ClassMergeRequest(
      academicYearId: 2,
      sourceClassId: 13,
      moves: [
        ClassMergeMove(targetClassId: 11, studentIds: [101, 102, 103]),
        ClassMergeMove(targetClassId: 12, studentIds: [104, 105]),
      ],
    );

    expect(request.toJson(), {
      'academic_year_id': 2,
      'source_class_id': 13,
      'moves': [
        {
          'target_class_id': 11,
          'student_ids': [101, 102, 103],
        },
        {
          'target_class_id': 12,
          'student_ids': [104, 105],
        },
      ],
    });
    expect(request.selectedCount, 5);
  });

  test('ClassMergeRequest never sends school_id', () {
    final request = ClassMergeRequest(
      academicYearId: 1,
      sourceClassId: 1,
      moves: [
        ClassMergeMove(targetClassId: 2, studentIds: [1]),
      ],
    );
    expect(request.toJson().containsKey('school_id'), isFalse);
  });

  test(
    'single-destination UI sends every selected student in one move group',
    () {
      final selectedIds = <int>[101, 102, 103, 103].toSet();
      final request = ClassMergeRequest(
        academicYearId: 2,
        sourceClassId: 13,
        moves: [
          ClassMergeMove(targetClassId: 11, studentIds: selectedIds.toList()),
        ],
      );

      final moves = request.toJson()['moves'] as List<dynamic>;
      expect(moves, hasLength(1));
      expect(moves.single['target_class_id'], 11);
      expect(moves.single['student_ids'], [101, 102, 103]);
    },
  );

  test(
    'ClassMergePreview.fromJson parses valid/invalid/target summary and can_process',
    () {
      final preview = ClassMergePreview.fromJson({
        'can_process': true,
        'selected_count': 5,
        'valid_students': [
          {
            'student': {'id': 101, 'name': 'A', 'emis_number': 'E1'},
          },
        ],
        'invalid_students': [
          {
            'student': {'id': 999, 'name': 'B', 'emis_number': 'E2'},
            'reason': 'Already moved',
          },
        ],
        'target_summary': [
          {'target_class_id': 11, 'target_class_name': 'Grade 5 A', 'count': 3},
          {'target_class_id': 12, 'target_class_name': 'Grade 5 B', 'count': 2},
        ],
      });

      expect(preview.canProcess, isTrue);
      expect(preview.selectedCount, 5);
      expect(preview.validStudents.single.studentId, 101);
      expect(preview.invalidStudents.single.reason, 'Already moved');
      expect(preview.targetSummary.length, 2);
      expect(preview.targetSummary.first.count, 3);
    },
  );

  test(
    'ClassMergePreview.canProcess defaults to false when backend omits it',
    () {
      final preview = ClassMergePreview.fromJson({
        'invalid_students': [
          {
            'student': {'id': 1, 'name': 'X'},
          },
        ],
      });
      expect(preview.canProcess, isFalse);
    },
  );

  test('class merge page and shell wiring is present', () {
    final page = File(
      'lib/school_admin/pages/class_merge_page.dart',
    ).readAsStringSync();
    final details = File(
      'lib/school_admin/pages/admin_class_details_screen.dart',
    ).readAsStringSync();
    final shell = File(
      'lib/school_admin/widgets/web_admin_shell.dart',
    ).readAsStringSync();
    final drawer = File(
      'lib/school_admin/widgets/drawer_widget.dart',
    ).readAsStringSync();
    final sidebar = File(
      'lib/school_admin/widgets/web_sidebar.dart',
    ).readAsStringSync();

    expect(page, contains('Select all shown'));
    expect(page, contains('Clear selection'));
    expect(page, contains('int? _destinationClassId'));
    expect(page, contains("'Destination Class'"));
    expect(page, contains('c.id != _sourceClassId'));
    expect(page, contains('targetClassId: destinationId'));
    expect(page, contains('studentIds: _selected.toSet().toList()'));
    expect(page, isNot(contains('Map<int, int> _destinations')));
    expect(page, isNot(contains("DataColumn(label: Text('Destination'))")));
    expect(page, isNot(contains("'Destination class',")));
    expect(page, contains('preview.canProcess && !_working'));
    expect(page, contains('? _confirmAndProcess'));
    expect(page, contains(': null,'));
    expect(
      page,
      contains(
        'This moves the selected students within the same academic year.',
      ),
    );
    expect(
      page,
      contains(
        'Historical marks, attendance, and promotions remain unchanged.',
      ),
    );

    expect(details, contains('Move / Merge Students'));
    expect(details, contains("'classMerge'"));

    expect(shell, contains("case 'classMerge':"));
    expect(shell, contains('ClassMergePage('));
    expect(shell, contains("_selectedArguments is Map<String, dynamic>"));
    expect(shell, contains("classId: args['classId'] as int?"));
    expect(drawer, contains("label: 'Class Merge'"));
    expect(drawer, contains('const ClassMergePage()'));
    expect(sidebar, contains("title: 'Class Merge'"));
    expect(sidebar, contains("_navigateToPage('classMerge')"));
    expect(sidebar, contains("widget.selectedPage == 'classMerge'"));
    expect(sidebar, contains('selected: isActive'));
    expect(shell, contains("case 'classes':"));
    expect(shell, contains("case 'promotions':"));
    expect(shell, contains('StudentPromotionsPage(embedBodyOnly: true)'));
    expect(page, contains("Tab(text: 'History')"));
    expect(
      RegExp(
        "DataColumn\\(label: Text\\('Academic Year'\\)\\)",
      ).allMatches(page),
      hasLength(1),
    );
  });

  test('promotion selection is backend-eligible and never locally rounded', () {
    final page = File(
      'lib/school_admin/pages/student_promotions_page.dart',
    ).readAsStringSync();
    expect(page, contains('passesPromotionThreshold(student.percentage)'));
    expect(page, contains('.where(_canSelect)'));
    expect(
      page,
      contains('Not eligible for promotion: below the 50% threshold.'),
    );
    expect(page, contains('final status = _resultKey(student)'));
    expect(page, contains('_statusBadge(status)'));
    expect(page, isNot(contains('.round()')));
    expect(page, contains('passesPromotionThreshold(student.percentage)'));
    expect(page, isNot(contains('>= 40')));
  });
}
