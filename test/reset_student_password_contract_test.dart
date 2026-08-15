import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Locks the already-working admin "reset student password" integration
/// (PATCH api/school-admin/students/{studentId}/reset-password) so future
/// changes don't silently regress it. No production code changes were made
/// for this feature — it was already fully wired.
void main() {
  late String service;
  late String dialog;
  late String detail;

  setUpAll(() {
    service = File(
      'lib/services/academic_performance_service.dart',
    ).readAsStringSync();
    dialog = File(
      'lib/school_admin/widgets/reset_student_password_dialog.dart',
    ).readAsStringSync();
    detail = File(
      'lib/school_admin/pages/student_detail_screen.dart',
    ).readAsStringSync();
  });

  test(
    'resetStudentPassword uses the exact backend endpoint and never sends a current password',
    () {
      expect(
        service,
        contains("'api/school-admin/students/\$studentId/reset-password'"),
      );
      expect(service, contains("'new_password': newPassword"));
      expect(service, contains("'confirm_password': confirmPassword"));
      // This is an admin-initiated reset — must never require/send the student's current password.
      final resetMethodStart = service.indexOf(
        'Future<PerformanceResult<void>> resetStudentPassword',
      );
      final nextMethodStart = service.indexOf(
        'Future<PerformanceResult<void>>',
        resetMethodStart + 1,
      );
      final resetMethodSource = service.substring(
        resetMethodStart,
        nextMethodStart,
      );
      expect(resetMethodSource, isNot(contains('current_password')));
    },
  );

  test(
    'dialog validates match, guards duplicate submits, clears fields, and shows student identity',
    () {
      expect(dialog, contains('widget.student.studentName'));
      expect(dialog, contains('widget.student.emisNumber'));
      expect(dialog, contains('Passwords do not match.'));
      expect(dialog, contains('if (_submitting) return;'));
      expect(dialog, contains('_newPassword.clear();'));
      expect(dialog, contains('_confirmPassword.clear();'));
    },
  );

  test(
    'student detail screen exposes Reset Password on both mobile and desktop actions',
    () {
      expect(detail, contains('_resetPassword(context)'));
      expect(
        detail,
        contains('showResetStudentPasswordDialog(context, student)'),
      );
    },
  );
}
