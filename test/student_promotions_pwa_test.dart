import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String page;
  late String shell;

  setUpAll(() {
    page = File('lib/school_admin/pages/student_promotions_page.dart')
        .readAsStringSync();
    shell = File('lib/school_admin/widgets/web_admin_shell.dart')
        .readAsStringSync();
  });

  test('desktop shell owns the promotions title and subtitle', () {
    expect(shell, contains("return 'Student Promotions';"));
    expect(
      shell,
      contains(
        'Review eligible students, preview results, then process the promotion.',
      ),
    );
    expect(page, contains('if (!widget.embedBodyOnly)'));
  });

  test('desktop review uses initials and a readable data table', () {
    expect(page, contains('_initials(student.name)'));
    expect(page, contains("DataColumn(label: Text('Student'))"));
    expect(page, contains("DataColumn(label: Text('EMIS'))"));
    expect(page, contains("DataColumn(label: Text('Eligibility'))"));
  });

  test('selection and local filters invalidate stale preview state', () {
    expect(page, contains('Select all shown students'));
    expect(page, contains('Clear selection'));
    expect(page, contains("_resultFilter = 'all'"));
    expect(page, contains("_eligibilityFilter = 'all'"));
    expect(page, contains('_previewedRequest = null'));
  });
}
