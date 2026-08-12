import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/pdf_file_result.dart';

void main() {
  test('class list sends only supported parameters', () {
    final query = buildClassStudentListQuery(
      academicYearId: 8,
      includeContact: true,
      includeAddress: false,
      download: true,
    );
    expect(query, {
      'academic_year_id': '8',
      'include_contact': 'true',
      'include_address': 'false',
      'download': 'true',
    });
    expect(query, isNot(contains('order_by')));
    expect(query, isNot(contains('exam_id')));
    expect(query, isNot(contains('include_marks')));
  });

  test('class marks single sends exam and all exams omits it', () {
    final single = buildClassMarksReportQuery(
      academicYearId: 8,
      examScope: 'single',
      examId: 12,
      orderBy: 'marks_high_to_low',
      download: false,
    );
    expect(single['exam_scope'], 'single');
    expect(single['exam_id'], '12');
    expect(single['order_by'], 'marks_high_to_low');

    final all = buildClassMarksReportQuery(
      academicYearId: 8,
      examScope: 'all',
      examId: 12,
      orderBy: 'position_asc',
      download: true,
    );
    expect(all['exam_scope'], 'all');
    expect(all, isNot(contains('exam_id')));
  });

  test('class marks validates scope, exam, and backend order values', () {
    expect(
      () => buildClassMarksReportQuery(
        academicYearId: 8,
        examScope: 'single',
        orderBy: 'alphabetical_asc',
        download: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => buildClassMarksReportQuery(
        academicYearId: 8,
        examScope: 'all',
        orderBy: 'performance_high_to_low',
        download: false,
      ),
      throwsArgumentError,
    );
  });

  test('shared PDF response validates type and extracts server filename', () {
    final valid = http.Response.bytes(
      [1, 2, 3],
      200,
      headers: {
        'content-type': 'application/pdf; charset=binary',
        'content-disposition': "attachment; filename*=UTF-8''Class%20List.pdf",
      },
    );
    final result = pdfFileResultFromResponse(valid);
    expect(result?.bytes, [1, 2, 3]);
    expect(result?.filename, 'Class List.pdf');

    expect(
      pdfFileResultFromResponse(
        http.Response(
          '{"message":"failed"}',
          500,
          headers: {'content-type': 'application/json'},
        ),
      ),
      isNull,
    );
  });

  test('class list form is alphabetical-only and defaults contact fields', () {
    final form = File(
      'lib/school_admin/widgets/class_roster_print_dialog.dart',
    ).readAsStringSync();
    expect(form, contains('_includeContact = true'));
    expect(form, contains('_includeAddress = true'));
    expect(form, contains('Preview Class List'));
    expect(form, contains('Download Class List'));
    expect(form, isNot(contains('Student Order')));
    expect(form, isNot(contains('Include Marks')));
    expect(form, isNot(contains('Exam *')));
  });

  test('class marks form owns scope and stale exam state', () {
    final form = File(
      'lib/school_admin/widgets/class_marks_print_dialog.dart',
    ).readAsStringSync();
    expect(form, contains("_examScope = 'single'"));
    expect(form, contains("_orderBy = 'alphabetical_asc'"));
    expect(form, contains("if (_examScope == 'single')"));
    expect(form, contains("if (scope == 'single')"));
    expect(form, contains('_examId = null'));
    expect(form, contains('Preview Marks Report'));
    expect(form, contains('Download Marks Report'));
  });

  test('class and marks pages expose separate shared actions', () {
    final details = File(
      'lib/school_admin/pages/admin_class_details_screen.dart',
    ).readAsStringSync();
    final marks = File(
      'lib/school_admin/pages/admin_marks_screen.dart',
    ).readAsStringSync();
    expect(details, contains('Print Class List'));
    expect(details, contains('Print Class Marks'));
    expect(details, isNot(contains('Print class letter')));
    expect(marks, contains('showClassMarksPrintDialog'));
    expect(marks, contains('Select a class to print marks'));
  });
}
