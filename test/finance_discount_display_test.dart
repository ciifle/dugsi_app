import 'package:flutter_test/flutter_test.dart';

import 'package:kobac/finance/models/student_discount.dart';

void main() {
  group('StudentDiscount.isFullyFree', () {
    test('true at exactly 100%', () {
      final d = StudentDiscount.fromJson({
        'student_id': 1,
        'student_name': 'Student B',
        'class_id': 1,
        'class_name': '1A',
        'academic_year_id': 2,
        'configured': true,
        'discount_percentage': 100,
        'is_active': true,
        'base_amount': 100.0,
        'discount_amount': 100.0,
        'effective_amount': 0.0,
      });
      expect(d.isFullyFree, true);
      expect(d.effectiveAmount, 0.0);
    });

    test('false below 100%, e.g. 20%', () {
      final d = StudentDiscount.fromJson({
        'student_id': 1,
        'student_name': 'Student A',
        'class_id': 1,
        'class_name': '1A',
        'academic_year_id': 2,
        'configured': true,
        'discount_percentage': 20,
        'is_active': true,
        'base_amount': 100.0,
        'discount_amount': 20.0,
        'effective_amount': 80.0,
      });
      expect(d.isFullyFree, false);
      expect(d.effectiveAmount, 80.0);
    });

    test('false when not configured (no discount at all)', () {
      final d = StudentDiscount.fromJson({
        'student_id': 1,
        'student_name': 'Student C',
        'class_id': 1,
        'class_name': '1A',
        'academic_year_id': 2,
        'configured': false,
        'discount_percentage': null,
        'is_active': null,
        'base_amount': null,
        'discount_amount': null,
        'effective_amount': null,
      });
      expect(d.isFullyFree, false);
      expect(d.configured, false);
      expect(d.baseAmount, isNull);
    });

    test('preview fields are null (never 0) when the class has no configured fee', () {
      final d = StudentDiscount.fromJson({
        'student_id': 1,
        'student_name': 'Student D',
        'class_id': 1,
        'class_name': '1A',
        'academic_year_id': 2,
        'configured': false,
        'base_amount': null,
        'discount_amount': null,
        'effective_amount': null,
      });
      expect(d.baseAmount, isNull);
      expect(d.discountAmount, isNull);
      expect(d.effectiveAmount, isNull);
    });
  });
}
