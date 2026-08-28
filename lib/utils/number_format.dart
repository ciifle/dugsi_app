/// Formats a backend numeric value for display without introducing
/// rounding artifacts (e.g. `73.26190476190476` -> `73.26`) or fabricating
/// a value when the backend hasn't provided one (`null` -> `'—'`).
String formatDecimal(num? value) {
  if (value == null) return '—';
  final v = value.toDouble();
  if (v % 1 == 0) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
