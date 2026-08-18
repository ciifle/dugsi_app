import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/promotions_service.dart';

void main() {
  group(
    'passesPromotionThreshold uses >= 50.0 on the raw value, never rounded',
    () {
      final cases = <(double, bool)>[
        (25.83, false),
        (42.05, false),
        (44.26, false),
        (45.37, false),
        (45.89, false),
        (46.65, false),
        (49.9, false),
        (49.99, false),
        (50.0, true),
        (50.1, true),
        (51.1, true),
        (52.17, true),
        (54.4, true),
        (63.61, true),
        (74.72, true),
      ];

      for (final (percentage, expectedPass) in cases) {
        test('$percentage → ${expectedPass ? 'PASS' : 'FAIL'}', () {
          expect(passesPromotionThreshold(percentage), expectedPass);
        });
      }

      test('null percentage never passes', () {
        expect(passesPromotionThreshold(null), isFalse);
      });
    },
  );

  test(
    'formatPromotionPercentage never rounds a FAIL value up to the threshold',
    () {
      // 49.99 must never visually read as "50.0%" next to a FAIL badge.
      expect(formatPromotionPercentage(49.99), isNot(contains('50.0')));
      expect(formatPromotionPercentage(49.99), '49.99%');
      expect(formatPromotionPercentage(51.071428571428571), '51.07%');
      expect(formatPromotionPercentage(50.0), '50.00%');
      expect(formatPromotionPercentage(null), '—');
    },
  );

  test(
    'parsePromotionPercentage preserves decimal precision from any wire shape',
    () {
      expect(parsePromotionPercentage(51), 51.0);
      expect(parsePromotionPercentage(51.1), 51.1);
      expect(parsePromotionPercentage('51.1'), 51.1);
      expect(parsePromotionPercentage(null), isNull);
    },
  );

  test(
    'canPromoteByPercentageAndEligibility matches the required selection rules',
    () {
      // >=50 + eligible true -> selectable
      expect(canPromoteByPercentageAndEligibility(52.17, true), isTrue);
      // >=50 + eligible null -> selectable (backend contract allows null)
      expect(canPromoteByPercentageAndEligibility(52.17, null), isTrue);
      // >=50 + eligible false -> not selectable
      expect(canPromoteByPercentageAndEligibility(52.17, false), isFalse);
      // <50 -> never selectable regardless of eligibility flag
      expect(canPromoteByPercentageAndEligibility(46.65, true), isFalse);
      expect(canPromoteByPercentageAndEligibility(46.65, null), isFalse);
    },
  );

  test(
    'PromotionStudent.fromJson prefers final_* fields over legacy fields',
    () {
      final student = PromotionStudent.fromJson({
        'student': {'id': 12, 'name': 'Maryan Nuur', 'emis_number': '0419'},
        'final_percentage': 52.17,
        'percentage': 99.0,
        'final_status': 'PASS',
        'status': 'unknown',
        'promotion_eligible': true,
      });
      expect(student.percentage, 52.17);
      expect(student.status, 'PASS');
      expect(student.eligible, isTrue);
    },
  );

  test(
    'promotion page never re-derives percentage and uses the shared formatter/threshold',
    () {
      final page = File(
        'lib/school_admin/pages/student_promotions_page.dart',
      ).readAsStringSync();

      // No local recalculation of an annual percentage.
      expect(page, isNot(contains('.round()')));
      expect(page, isNot(contains('>= 40')));
      expect(page, isNot(contains('>=40')));

      // Display always goes through the shared, never-rounds-to-threshold formatter.
      expect(page, contains('formatPromotionPercentage(student.percentage)'));
      expect(page, contains('formatPromotionPercentage(s.percentage)'));
      expect(page, isNot(contains(r"'${student.percentage}%'")));
      expect(page, isNot(contains(r"'${s.percentage}%'")));

      // Selection/eligibility/badge all route through the shared service helpers.
      expect(page, contains('passesPromotionThreshold(student.percentage)'));
      expect(page, contains('canPromoteByPercentageAndEligibility('));
    },
  );

  test(
    'a dev-only mismatch log never overrides the numeric percentage badge',
    () {
      final page = File(
        'lib/school_admin/pages/student_promotions_page.dart',
      ).readAsStringSync();
      expect(page, contains('kDebugMode'));
      expect(page, contains('_logStatusMismatchIfAny'));
      // The logger must never be reachable in release builds' user-visible path
      // (it only calls debugPrint, guarded by kDebugMode, never setState on a
      // badge/result field).
      expect(page, contains('if (kDebugMode) {'));
    },
  );
}
