import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile student actions use the required order and layout', () {
    final source = File(
      'lib/school_admin/pages/student_detail_screen.dart',
    ).readAsStringSync();
    final mobileStart = source.indexOf('Widget _buildMobileActions');
    final desktopStart = source.indexOf('Widget _buildDesktopActions');
    final mobile = source.substring(mobileStart, desktopStart);

    final reset = mobile.indexOf("label: 'Reset Password'");
    final academic = mobile.indexOf("label: 'Print Academic Report'");
    final information = mobile.indexOf("label: 'Print Student Information'");
    final edit = mobile.indexOf("label: 'Edit'");
    final delete = mobile.indexOf("label: 'Delete'");

    expect(reset, greaterThanOrEqualTo(0));
    expect(reset, lessThan(academic));
    expect(academic, lessThan(information));
    expect(information, lessThan(edit));
    expect(edit, lessThan(delete));
    expect(mobile, contains('Row('));
    expect(mobile, contains('const SizedBox(width: 14)'));
  });

  test('mobile action component keeps labels on one line', () {
    final source = File(
      'lib/school_admin/pages/student_detail_screen.dart',
    ).readAsStringSync();
    expect(source, contains('height: 54'));
    expect(source, contains('maxLines: 1'));
    expect(source, contains('softWrap: false'));
    expect(source, contains('BoxFit.scaleDown'));
    expect(source, contains('MediaQuery.paddingOf(context).bottom'));
  });

  test('existing handlers and desktop responsive branch remain present', () {
    final source = File(
      'lib/school_admin/pages/student_detail_screen.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('showResetStudentPasswordDialog(context, student)'),
    );
    expect(source, contains('showStudentAcademicReportDialog('));
    expect(source, contains('showStudentPrintDialog('));
    expect(source, contains("onNavigateToPage!('editStudent'"));
    expect(source, contains('_confirmDelete(context, student)'));
    expect(source, contains('if (isDesktopWebAdminLayout(context))'));
  });
}
