import 'package:flutter_test/flutter_test.dart';

import 'package:kobac/utils/money_format.dart';

void main() {
  group('formatMoney', () {
    test('null returns em dash', () {
      expect(formatMoney(null), '—');
    });

    test('formats whole numbers with two decimals', () {
      expect(formatMoney(100), '100.00');
    });

    test('formats decimals without rounding artifacts', () {
      expect(formatMoney(80.5), '80.50');
    });

    test('formats large numbers with thousands separators', () {
      expect(formatMoney(12345.6), '12,345.60');
    });

    test('is tolerant of a numeric-String value (DECIMAL-as-string safety net)', () {
      expect(formatMoney('100.00'), '100.00');
    });

    test('returns em dash for a non-numeric String', () {
      expect(formatMoney('not-a-number'), '—');
    });
  });

  group('parseMoney', () {
    test('null defaults to 0', () {
      expect(parseMoney(null), 0);
    });

    test('parses a numeric string', () {
      expect(parseMoney('42.5'), 42.5);
    });

    test('passes through a num unchanged', () {
      expect(parseMoney(42), 42);
    });
  });
}
