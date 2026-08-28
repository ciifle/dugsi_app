import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/student/pages/student_total_page.dart';

void main() {
  test('ordinal formatting is display-only and handles teens', () {
    expect(formatOrdinalPosition(1), '1st');
    expect(formatOrdinalPosition(2), '2nd');
    expect(formatOrdinalPosition(3), '3rd');
    expect(formatOrdinalPosition(11), '11th');
    expect(formatOrdinalPosition(12), '12th');
    expect(formatOrdinalPosition(13), '13th');
    expect(formatOrdinalPosition(21), '21st');
  });
}
