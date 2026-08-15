import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String shell;
  late String sidebar;
  late String dashboard;
  late String performance;

  setUpAll(() {
    shell = File(
      'lib/student/widgets/student_web_shell.dart',
    ).readAsStringSync();
    sidebar = File(
      'lib/student/widgets/student_web_sidebar.dart',
    ).readAsStringSync();
    dashboard = File(
      'lib/student/widgets/student_web_dashboard.dart',
    ).readAsStringSync();
    performance = File(
      'lib/student/pages/academic_performance_page.dart',
    ).readAsStringSync();
  });

  test('student desktop shell preserves academic destinations', () {
    for (final route in [
      'timetable',
      'marks',
      'results',
      'attendance',
      'notices',
      'profile',
      'performance',
    ]) {
      expect(shell, contains("case '$route':"));
    }
    expect(shell, isNot(contains("case 'messages':")));
    expect(shell, isNot(contains("case 'newMessage':")));
    expect(shell, isNot(contains("case 'chat':")));
  });

  test('sidebar has identity and fixed logout but no change password item', () {
    expect(sidebar, contains('class _StudentIdentityCard'));
    expect(sidebar, contains('Sign out of your account'));
    expect(sidebar, contains('Academic Performance'));
    expect(sidebar, isNot(contains("label: 'Change Password'")));
    expect(sidebar, contains('context.read<AuthProvider>().logout()'));
  });

  test('dashboard includes performance and next class feature cards', () {
    expect(dashboard, contains("title: 'Academic Performance'"));
    expect(dashboard, contains("title: 'Next Class'"));
    expect(dashboard, contains('Performance not available yet'));
    expect(dashboard, contains('No more classes today.'));
    expect(dashboard, contains("_navigate('performance')"));
    expect(dashboard, contains("_navigate('timetable')"));
  });

  test(
    'embedded performance relies on shell header and preserves decimals',
    () {
      expect(shell, contains('AcademicPerformancePage(embedBodyOnly: true)'));
      expect(performance, contains('if (!widget.embedBodyOnly)'));
      expect(performance, contains("'\${data.percentage}%'"));
      expect(performance, isNot(contains('percentage.toStringAsFixed')));
    },
  );
}
