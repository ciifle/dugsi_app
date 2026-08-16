import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String mobileDashboard;
  late String webDashboard;

  setUpAll(() {
    mobileDashboard = File(
      'lib/school_admin/pages/school_admin_screen.dart',
    ).readAsStringSync();
    webDashboard = File(
      'lib/school_admin/widgets/web_dashboard.dart',
    ).readAsStringSync();
  });

  test('mobile and PWA use the shared student pagination total', () {
    for (final dashboard in [mobileDashboard, webDashboard]) {
      expect(dashboard, contains('StudentsService().listStudentPage()'));
      expect(dashboard, contains('StudentSuccess<StudentPage>'));
      expect(dashboard, contains('.data.total'));
      expect(dashboard, isNot(contains('StudentSuccess<List<StudentModel>>')));
    }
  });

  test('other dashboard counters retain their existing service contracts', () {
    for (final dashboard in [mobileDashboard, webDashboard]) {
      expect(dashboard, contains('TeachersService().listTeachers()'));
      expect(dashboard, contains('SubjectsService().listSubjects()'));
      expect(dashboard, contains('ClassesService().listClasses()'));
      expect(dashboard, contains('TeacherSuccess<List<TeacherModel>>'));
      expect(dashboard, contains('SubjectSuccess<List<SubjectModel>>'));
      expect(dashboard, contains('ClassSuccess<List<ClassModel>>'));
    }
  });

  test('PWA keeps its loading state until count requests complete', () {
    final loadStart = webDashboard.indexOf('Future<void> _loadData()');
    final requests = webDashboard.indexOf('final futures = await Future.wait');
    final loadingComplete = webDashboard.indexOf('_loading = false;', requests);

    expect(loadStart, greaterThanOrEqualTo(0));
    expect(requests, greaterThan(loadStart));
    expect(loadingComplete, greaterThan(requests));
  });
}
