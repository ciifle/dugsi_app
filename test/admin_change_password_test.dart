import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String service;
  late String page;
  late String profile;
  late String shell;

  setUpAll(() {
    service = File(
      'lib/services/academic_performance_service.dart',
    ).readAsStringSync();
    page = File(
      'lib/school_admin/pages/change_password_page.dart',
    ).readAsStringSync();
    profile = File(
      'lib/school_admin/pages/admin_profile.dart',
    ).readAsStringSync();
    shell = File(
      'lib/school_admin/widgets/web_admin_shell.dart',
    ).readAsStringSync();
  });

  test('changeAdminPassword posts to the exact admin endpoint', () {
    expect(service, contains("'api/school-admin/change-password'"));
    expect(service, contains('method: \'POST\''));
    expect(service, contains("'current_password': currentPassword"));
    expect(service, contains("'new_password': newPassword"));
    expect(service, contains("'confirm_password': confirmPassword"));
    // Existing student/reset endpoints must remain untouched.
    expect(service, contains("'api/student/profile/change-password'"));
    expect(
      service,
      contains("'api/school-admin/students/\$studentId/reset-password'"),
    );
  });

  test(
    'admin change password page uses the real backend service, not the local stub',
    () {
      expect(
        page,
        contains('AcademicPerformanceService().changeAdminPassword'),
      );
      expect(page, isNot(contains('LocalAuthService')));
      expect(page, contains('if (_loading) return;'));
      expect(page, contains('_currentController.clear();'));
      expect(page, contains('_newController.clear();'));
      expect(page, contains('_confirmController.clear();'));
    },
  );

  test(
    'PWA profile exposes a Change Password action wired through the shell',
    () {
      expect(profile, contains("label: 'Change Password'"));
      expect(
        profile,
        contains("widget.onNavigateToPage?.call('changePassword')"),
      );
      expect(shell, contains("case 'changePassword':"));
      expect(shell, contains('ChangePasswordPage(embedBodyOnly: true)'));
    },
  );
}
