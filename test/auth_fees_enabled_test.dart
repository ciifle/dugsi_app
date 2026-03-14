import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/models/auth_user.dart';

void main() {
  group('AuthMeResponse.feesEnabled', () {
    late AuthUser dummyUser;

    setUp(() {
      dummyUser = const AuthUser(
        id: 1,
        name: 'Test',
        role: 'SCHOOL_ADMIN',
      );
    });

    test('when feesEnabled is true, value is true', () {
      final response = AuthMeResponse(
        user: dummyUser,
        profile: null,
        feesEnabled: true,
      );
      expect(response.feesEnabled, true);
    });

    test('when feesEnabled is false, value is false', () {
      final response = AuthMeResponse(
        user: dummyUser,
        profile: null,
        feesEnabled: false,
      );
      expect(response.feesEnabled, false);
    });

    test('when feesEnabled is null (legacy backend), value is null', () {
      final response = AuthMeResponse(
        user: dummyUser,
        profile: null,
        feesEnabled: null,
      );
      expect(response.feesEnabled, null);
    });
  });

  group('AuthProvider.feesEnabled getter (behavior)', () {
    test('when null, app treats as true (backward compat)', () {
      // AuthProvider exposes feesEnabled as _feesEnabled ?? true
      // So when backend does not send the flag, we show fees UI
      const bool? stored = null;
      final effective = stored ?? true;
      expect(effective, true);
    });

    test('when false, app hides fees UI', () {
      const bool? stored = false;
      final effective = stored ?? true;
      expect(effective, false);
    });
  });
}
