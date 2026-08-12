import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard defers provider notifications until after build', () {
    final source = File('lib/school_admin/widgets/web_dashboard.dart').readAsStringSync();
    expect(source, contains('WidgetsBinding.instance.addPostFrameCallback'));
    expect(source, contains('if (_initialized) return'));
    expect(source, contains("context.read<AcademicYearsProvider>().ensureLoaded()"));
    expect(
      source,
      isNot(contains(
        'super.didChangeDependencies();\n    context.read<AcademicYearsProvider>().ensureLoaded();',
      )),
    );
  });
}
