import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/school_admin/widgets/student_print_dialog.dart';
import 'package:kobac/school_admin/widgets/student_academic_report_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('PWA Student Information year dropdown opens and enables actions', (tester) async {
    final provider = AcademicYearsProvider();
    provider.years = const [AcademicYear(id: 7, name: '2026/27', isActive: true)];
    provider.activeYear = provider.years.first;
    const student = StudentModel(id: 4, emisNumber: 'E-4', studentName: 'Amina');

    await tester.pumpWidget(
      ChangeNotifierProvider<AcademicYearsProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: const MediaQueryData(size: Size(1280, 800)),
              child: ElevatedButton(
                onPressed: () => showStudentPrintDialog(context, student: student),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    expect(dropdown.onChanged, isNotNull);
    await tester.tap(find.text('2026/27'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026/27').last);
    await tester.pumpAndSettle();
    expect(find.text('2026/27'), findsWidgets);

    final preview = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Preview PDF'),
    );
    final downloadFinder = find.ancestor(
      of: find.text('Download PDF'),
      matching: find.byWidgetPredicate((widget) => widget is ElevatedButton),
    );
    final download = tester.widget<ElevatedButton>(downloadFinder);
    expect(preview.onPressed, isNotNull);
    expect(download.onPressed, isNotNull);
  });

  testWidgets('PWA All Exams hides exam and enables report actions', (tester) async {
    final provider = AcademicYearsProvider();
    provider.years = const [AcademicYear(id: 7, name: '2026/27', isActive: true)];
    provider.activeYear = provider.years.first;
    const student = StudentModel(id: 4, emisNumber: 'E-4', studentName: 'Amina');
    await tester.pumpWidget(
      ChangeNotifierProvider<AcademicYearsProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: const MediaQueryData(size: Size(1280, 800)),
              child: ElevatedButton(
                onPressed: () => showStudentAcademicReportDialog(context, student: student),
                child: const Text('Open report'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Exams'));
    await tester.pumpAndSettle();

    expect(find.text('Exam *'), findsNothing);
    final preview = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Preview Report'),
    );
    final downloadFinder = find.ancestor(
      of: find.text('Download Report'),
      matching: find.byWidgetPredicate((widget) => widget is ElevatedButton),
    );
    expect(preview.onPressed, isNotNull);
    expect(tester.widget<ElevatedButton>(downloadFinder).onPressed, isNotNull);
  });

  test('desktop dialogs inject provider and retain local state', () {
    for (final path in [
      'lib/school_admin/widgets/student_print_dialog.dart',
      'lib/school_admin/widgets/student_academic_report_dialog.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('ChangeNotifierProvider<AcademicYearsProvider>.value'));
      expect(source, contains('isPwaDialog: true'));
      expect(source, isNot(contains('AbsorbPointer')));
      expect(source, isNot(contains('IgnorePointer')));
      expect(source, isNot(contains('Positioned.fill')));
    }
  });
}
