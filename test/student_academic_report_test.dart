import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/students_service.dart';

void main() {
  test('academic report query uses exact backend contract', () {
    expect(
      buildAcademicReportQuery(
        academicYearId: 12,
        examScope: 'single',
        examId: 34,
        includeAttendance: true,
        download: false,
      ),
      {
        'academic_year_id': '12',
        'exam_scope': 'single',
        'exam_id': '34',
        'include_attendance': 'true',
        'download': 'false',
      },
    );
  });

  test('all-exams query omits exam_id', () {
    final query = buildAcademicReportQuery(
      academicYearId: 12,
      examScope: 'all',
      examId: 34,
      includeAttendance: false,
      download: true,
    );
    expect(query['exam_scope'], 'all');
    expect(query.containsKey('exam_id'), isFalse);
  });

  test('single scope requires a valid exam and invalid scopes are blocked', () {
    expect(
      () => buildAcademicReportQuery(
        academicYearId: 12,
        examScope: 'single',
        includeAttendance: true,
        download: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => buildAcademicReportQuery(
        academicYearId: 12,
        examScope: 'invalid',
        includeAttendance: true,
        download: false,
      ),
      throwsArgumentError,
    );
  });

  test('information and academic report actions remain separate', () {
    final source = File(
      'lib/school_admin/pages/student_detail_screen.dart',
    ).readAsStringSync();
    expect(source, contains('Print Student Information'));
    expect(source, contains('Print Academic Report'));
    expect(source, contains('showStudentPrintDialog'));
    expect(source, contains('showStudentAcademicReportDialog'));
  });

  test(
    'report service uses authenticated byte request path and validates PDF',
    () {
      final source = File(
        'lib/services/students_service.dart',
      ).readAsStringSync();
      final shared = File(
        'lib/services/pdf_file_result.dart',
      ).readAsStringSync();
      expect(source, contains("'\$_base/\$studentId/report-card'"));
      expect(source, contains("'Accept': 'application/pdf'"));
      expect(source, contains('pdfFileResultFromResponse(response)'));
      expect(shared, contains('response.bodyBytes'));
      expect(shared, contains("contains('application/pdf')"));
      expect(shared, contains("response.headers['content-disposition']"));
    },
  );

  test('form clears exam when academic year changes', () {
    final source = File(
      'lib/school_admin/widgets/student_academic_report_dialog.dart',
    ).readAsStringSync();
    expect(source, contains('_examId = null'));
    expect(source, contains('listExams(academicYearId: yearId)'));
    expect(source, contains("No exams found for this academic year."));
    expect(source, contains('_includeAttendance = true'));
    expect(source, contains("_examScope = 'single'"));
    expect(source, contains("if (scope == 'all') _exams = const []"));
    expect(source, contains("_examScope == 'all'"));
    expect(source, contains('Grand Overall Summary'));
    expect(source, contains('student and guardian details'));
    expect(source, contains('detailed attendance summary'));
  });

  test('PDF handlers and Student Information printing remain shared', () {
    final dialog = File(
      'lib/school_admin/widgets/student_academic_report_dialog.dart',
    ).readAsStringSync();
    final mobile = File(
      'lib/utils/student_pdf_handler_mobile.dart',
    ).readAsStringSync();
    final web = File(
      'lib/utils/student_pdf_handler_web.dart',
    ).readAsStringSync();
    final information = File(
      'lib/school_admin/widgets/student_print_dialog.dart',
    ).readAsStringSync();

    expect(dialog, contains('previewStudentPdf(document.bytes, filename)'));
    expect(dialog, contains('savePdfWithFeedback'));
    expect(mobile, contains('Printing.layoutPdf'));
    expect(mobile, isNot(contains('Printing.sharePdf')));
    expect(web, contains("html.Blob([bytes], 'application/pdf')"));
    expect(web, contains('html.window.open'));
    expect(web, contains('html.AnchorElement'));
    expect(web, contains('html.Url.revokeObjectUrl'));
    expect(information, contains('getStudentPrintPdf'));
  });

  test('Flutter does not calculate the Grand Overall Summary', () {
    final dialog = File(
      'lib/school_admin/widgets/student_academic_report_dialog.dart',
    ).readAsStringSync();
    expect(dialog, isNot(contains('grandTotal')));
    expect(dialog, isNot(contains('overallPercentage')));
    expect(dialog, isNot(contains('overallGrade')));
  });
}
