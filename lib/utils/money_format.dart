import 'package:intl/intl.dart';

final NumberFormat _moneyFormat = NumberFormat('#,##0.00');

/// Formats a backend money value for display: always 2 decimals, comma
/// thousands separator, '—' for null. Tolerant of num or numeric-String
/// input since some endpoints may still hand back a DECIMAL string.
String formatMoney(dynamic value) {
  if (value == null) return '—';
  final num? n = value is num ? value : num.tryParse(value.toString());
  if (n == null) return '—';
  return _moneyFormat.format(n);
}

/// Parses a possibly-string numeric value into a num, defaulting to 0 when
/// absent/unparsable. Use for backend fields that are contractually numbers
/// but should never throw if a DECIMAL ever arrives as a string.
num parseMoney(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}
