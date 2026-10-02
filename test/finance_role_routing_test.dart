import 'package:flutter_test/flutter_test.dart';

import 'package:kobac/models/auth_user.dart';
import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/models/dummy_user.dart';

void main() {
  group('FINANCE role mapping', () {
    test('roleFromApiString maps FINANCE to UserRole.finance', () {
      expect(roleFromApiString('FINANCE'), UserRole.finance);
    });

    test('roleFromApiString is case-insensitive for FINANCE', () {
      expect(roleFromApiString('finance'), UserRole.finance);
    });

    test('roleToUiString maps UserRole.finance to finance', () {
      expect(roleToUiString(UserRole.finance), 'finance');
    });

    test('AuthUser.fromJson with role FINANCE resolves userRole to finance', () {
      final user = AuthUser.fromJson({
        'id': 5,
        'name': 'Finance Person',
        'email': 'finance@example.com',
        'role': 'FINANCE',
        'school_id': 1,
      });
      expect(user.userRole, UserRole.finance);
    });

    test('unrecognized role still falls back to student (pre-existing behavior)', () {
      expect(roleFromApiString('SOMETHING_ELSE'), UserRole.student);
    });
  });

  group('FinanceProfile parsing', () {
    test('parseProfileByRole builds a FinanceProfile for role FINANCE', () {
      final profile = parseProfileByRole('FINANCE', {
        'id': 7,
        'user_id': 42,
        'school_id': 3,
        'name': 'Finance Person',
        'email': 'finance@example.com',
      });
      expect(profile, isA<FinanceProfile>());
      final financeProfile = profile as FinanceProfile;
      expect(financeProfile.id, 7);
      expect(financeProfile.schoolId, 3);
      expect(financeProfile.name, 'Finance Person');
    });

    test('AuthMeResponse.financeProfile getter only matches FinanceProfile', () {
      final response = AuthMeResponse(
        user: const AuthUser(id: 1, name: 'x', role: 'FINANCE'),
        profile: FinanceProfile(id: 1, name: 'x', email: 'x@example.com'),
      );
      expect(response.financeProfile, isNotNull);
      expect(response.teacherProfile, isNull);
    });
  });
}
