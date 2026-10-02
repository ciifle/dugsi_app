import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/auth_provider.dart';

import 'package:kobac/models/auth_me_models.dart';

// Mirrors test/auth_fees_enabled_test.dart's pattern: Finance navigation is
// gated by the SAME feesEnabled flag the legacy Fees section already uses
// (see plan's "Mismatch #1" — the backend maps payments_enabled to
// schoolFeatures.feesEnabled, not a separate financeEnabled flag).
void main() {
  group('Finance nav gating reuses SchoolFeatures.feesEnabled', () {
    test('feesEnabled true means Finance nav should be shown', () {
      final features = SchoolFeatures.fromJson({'feesEnabled': true});
      expect(features.feesEnabled, true);
    });

    test('feesEnabled false means Finance nav should be hidden', () {
      final features = SchoolFeatures.fromJson({'feesEnabled': false});
      expect(features.feesEnabled, false);
    });

    test('feesEnabled accepts snake_case fees_enabled from backend', () {
      final features = SchoolFeatures.fromJson({'fees_enabled': true});
      expect(features.feesEnabled, true);
    });

    test('missing authenticated feature fails closed', () {
      expect(AuthProvider().feesEnabled, false);
      expect(
        SchoolFeatures.fromJson({'payments_enabled': true}).feesEnabled,
        true,
      );
    });
  });
}
