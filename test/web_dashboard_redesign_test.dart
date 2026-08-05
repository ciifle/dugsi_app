import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String dashboard;
  late String analytics;

  setUpAll(() {
    dashboard = File('lib/school_admin/widgets/web_dashboard.dart')
        .readAsStringSync();
    analytics = File('lib/school_admin/widgets/dashboard_analytics.dart')
        .readAsStringSync();
  });

  test('dashboard preserves live count services and navigation callbacks', () {
    expect(dashboard, contains('StudentsService().listStudents()'));
    expect(dashboard, contains('TeachersService().listTeachers()'));
    expect(dashboard, contains('ClassesService().listClasses()'));
    expect(dashboard, contains("_navigateToPage('students'"));
    expect(dashboard, contains("_navigateToPage('academicYears'"));
  });

  test('premium dashboard sections are present', () {
    expect(dashboard, contains('DashboardAnalyticsSection'));
    expect(dashboard, contains('DashboardUpdatesSection'));
    expect(dashboard, contains('Manage Year'));
    expect(analytics, contains('Attendance Trend'));
    expect(analytics, contains('Students Distribution'));
    expect(analytics, contains('Attendance Percentage'));
    expect(analytics, contains('Monthly Admissions'));
    expect(analytics, contains('Recent Activity'));
    expect(analytics, contains('Upcoming Events'));
  });

  test('analytics uses responsive grids without new packages', () {
    expect(analytics, contains('constraints.maxWidth >= 980'));
    expect(analytics, contains('constraints.maxWidth >= 680'));
    expect(analytics, contains('CustomPainter'));
  });
}
