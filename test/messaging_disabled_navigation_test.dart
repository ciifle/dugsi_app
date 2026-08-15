import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('student mobile tabs are Home Attendance Performance Profile', () {
    final source = read('lib/student/pages/student_dashboard.dart');
    expect(source, contains('const AcademicPerformancePage()'));
    expect(source, contains("'label': 'Performance'"));
    expect(source, isNot(contains("'label': 'Messages'")));
    expect(source, isNot(contains('MessagesScreen(')));
  });

  test('admin mobile tabs are Dashboard Classes Profile', () {
    final source = read('lib/school_admin/pages/school_admin_screen.dart');
    expect(source, contains('0=Dashboard, 1=Classes, 2=Profile'));
    expect(source, contains('AdminClassesPage(embedBodyOnly: true)'));
    expect(source, contains('["Dashboard", "Classes", "Profile"]'));
    expect(source, isNot(contains('MessagesScreen(')));
  });

  test('active Flutter navigation has no messaging entry points', () {
    const paths = [
      'lib/student/widgets/student_drawer.dart',
      'lib/student/widgets/student_web_sidebar.dart',
      'lib/student/widgets/student_web_shell.dart',
      'lib/student/widgets/student_web_dashboard.dart',
      'lib/student/widgets/student_web_top_bar.dart',
      'lib/school_admin/widgets/web_admin_shell.dart',
      'lib/school_admin/widgets/web_dashboard.dart',
      'lib/school_admin/widgets/web_top_bar.dart',
      'lib/parent/Widget/parent_drawer.dart',
      'lib/teacher/pages/teacher_drawer.dart',
      'lib/teacher/widgets/teacher_web_sidebar.dart',
      'lib/teacher/widgets/teacher_web_shell.dart',
      'lib/teacher/pages/students_screen.dart',
    ];
    for (final path in paths) {
      final source = read(path);
      expect(source, isNot(contains('MessagesScreen(')), reason: path);
      expect(source, isNot(contains("pageKey: 'messages'")), reason: path);
      expect(source, isNot(contains("call('messages')")), reason: path);
    }
  });

  test('Class Merge keeps contracts, guards, and post-process refresh', () {
    final service = read('lib/services/class_merge_service.dart');
    final page = read('lib/school_admin/pages/class_merge_page.dart');
    expect(service, contains("_submit('preview', request)"));
    expect(service, contains("_submit('process', request)"));
    expect(service, contains("'\$_base/history'"));
    expect(page, contains('preview?.canProcess != true'));
    expect(page, contains('preview.canProcess && !_working'));
    expect(page, contains('yearId != _academicYearId'));
    expect(page, contains('classId != _sourceClassId'));
    expect(
      page,
      contains('Future.wait([_loadRoster(), _loadClasses(), _loadHistory()])'),
    );
  });
}
