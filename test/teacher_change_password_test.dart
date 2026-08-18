import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String service;
  late String page;
  late String profile;
  late String shell;
  late String sidebar;
  late String drawer;

  setUpAll(() {
    service = File(
      'lib/services/academic_performance_service.dart',
    ).readAsStringSync();
    page = File(
      'lib/teacher/pages/change_password_page.dart',
    ).readAsStringSync();
    profile = File('lib/teacher/pages/teacher_profile.dart').readAsStringSync();
    shell = File(
      'lib/teacher/widgets/teacher_web_shell.dart',
    ).readAsStringSync();
    sidebar = File(
      'lib/teacher/widgets/teacher_web_sidebar.dart',
    ).readAsStringSync();
    drawer = File('lib/teacher/pages/teacher_drawer.dart').readAsStringSync();
  });

  test('changeTeacherPassword posts to the exact backend endpoint and body', () {
    expect(service, contains("'api/teacher/change-password'"));
    expect(service, contains('changeTeacherPassword'));
    expect(service, contains("'current_password': currentPassword"));
    expect(service, contains("'new_password': newPassword"));
    expect(service, contains("'confirm_password': confirmPassword"));
    // Must never send teacher_id/user_id/school_id — the JWT identifies the teacher.
    final methodStart = service.indexOf(
      'Future<PerformanceResult<void>> changeTeacherPassword',
    );
    final methodEnd = service.indexOf('_passwordRequest', methodStart) + 400;
    final methodSource = service.substring(
      methodStart,
      methodEnd.clamp(0, service.length),
    );
    expect(methodSource, isNot(contains('teacher_id')));
    expect(methodSource, isNot(contains('user_id')));
    expect(methodSource, isNot(contains('school_id')));

    // Existing admin/student password endpoints must remain untouched.
    expect(service, contains("'api/school-admin/change-password'"));
    expect(service, contains("'api/student/profile/change-password'"));
  });

  test(
    'teacher change password page reuses the shared form/validation pattern',
    () {
      expect(
        page,
        contains('AcademicPerformanceService().changeTeacherPassword'),
      );
      expect(page, contains('if (_loading) return;'));
      expect(page, contains('Passwords do not match'));
      expect(page, contains('_currentController.clear();'));
      expect(page, contains('_newController.clear();'));
      expect(page, contains('_confirmController.clear();'));
      // Embed-safe pop — same fix already applied to admin/student pages.
      expect(
        page,
        contains(
          'if (!widget.embedBodyOnly && Navigator.of(context).canPop())',
        ),
      );
      // Never log passwords.
      expect(page, isNot(contains('print(_current')));
      expect(page, isNot(contains('debugPrint(_current')));
    },
  );

  test(
    'teacher profile exposes Change Password on both mobile and desktop',
    () {
      expect(profile, contains('_ChangePasswordCard('));
      expect(profile, contains("'Change Password'"));
      expect(
        profile,
        contains("widget.onNavigateToPage?.call('changePassword')"),
      );
      // Placed alongside Logout, not standalone/duplicated elsewhere.
      expect(profile, contains('_openChangePassword(context)'));
    },
  );

  test('PWA shell routes changePassword to the embedded teacher page', () {
    expect(shell, contains("case 'changePassword':"));
    expect(shell, contains('TeacherChangePasswordPage(embedBodyOnly: true)'));
  });

  test(
    'Change Password is a visible drawer entry that reuses the existing page',
    () {
      expect(drawer, contains("label: 'Change Password'"));
      expect(drawer, contains("case 'Change Password':"));
      expect(drawer, contains('screen = const TeacherChangePasswordPage();'));
      // Reuses the same page class as Profile's entry point — no duplicate page.
      expect(profile, contains('const TeacherChangePasswordPage()'));
      // Messaging must remain disabled — not reintroduced by this change.
      expect(drawer, isNot(contains("'Messages'")));
    },
  );

  test('PWA sidebar is untouched by the drawer-only change', () {
    expect(sidebar, isNot(contains('Change Password')));
    expect(sidebar, isNot(contains("'messages'")));
  });
}
