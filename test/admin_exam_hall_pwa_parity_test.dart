import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/models/exam_hall_models.dart';

void main() {
  test('desktop shell routes every exam hall destination to shared pages', () {
    final shell = File(
      'lib/school_admin/widgets/web_admin_shell.dart',
    ).readAsStringSync();

    expect(shell, contains("case 'shifts':"));
    expect(shell, contains('ShiftsPage(embedBodyOnly: true)'));
    expect(shell, contains("case 'examHalls':"));
    expect(shell, contains('ExamHallsPage(embedBodyOnly: true)'));
    expect(shell, contains("case 'hallAllocation':"));
    expect(shell, contains('HallAllocationPage('));
    expect(shell, contains("case 'hallReports':"));
    expect(shell, contains('HallReportsPage(embedBodyOnly: true)'));
    expect(shell, contains("case 'passCards':"));
    expect(shell, contains('ExamPassCardsPage(embedBodyOnly: true)'));
  });

  test('desktop sidebar groups and feature-gates exam hall navigation', () {
    final sidebar = File(
      'lib/school_admin/widgets/web_sidebar.dart',
    ).readAsStringSync();

    expect(sidebar, contains("title: 'Classes'"));
    expect(sidebar, contains("title: 'Levels'"));
    expect(sidebar, contains("title: 'Shifts'"));
    expect(sidebar, contains("title: 'Examinations'"));
    expect(sidebar, contains('if (examsEnabled) ...['));
    expect(sidebar, contains("title: 'Exam Halls'"));
    expect(sidebar, contains("title: 'Hall Allocation'"));
    expect(sidebar, contains("title: 'Hall Report'"));
    expect(sidebar, contains("title: 'Exam Pass Cards'"));
  });

  test('backend report and history fields are preserved for web tables', () {
    final report = ExamHallReportRow.fromJson({
      'id': 7,
      'student_name': 'Student',
      'level_name': 'Secondary',
      'shift_name': 'Afternoon',
    });
    final batch = ExamHallAllocationBatch.fromJson({
      'id': 4,
      'student_count': 20,
      'unallocated_count': 3,
    });

    expect(report.levelName, 'Secondary');
    expect(report.shiftName, 'Afternoon');
    expect(batch.studentCount, 20);
    expect(batch.unallocatedCount, 3);
  });

  test('PWA uses shared PDF and API layers without web-specific services', () {
    final page = File(
      'lib/school_admin/pages/exam_hall_management_pages.dart',
    ).readAsStringSync();
    final webPdf = File(
      'lib/utils/student_pdf_handler_web.dart',
    ).readAsStringSync();

    expect(page, contains('ExamHallService()'));
    expect(page, isNot(contains('webExamHallApi')));
    expect(page, isNot(contains('mobileExamHallApi')));
    expect(webPdf, contains("html.Blob([bytes], 'application/pdf')"));
    expect(webPdf, contains('createObjectUrlFromBlob'));
    expect(webPdf, contains('revokeObjectUrl'));
  });
}
