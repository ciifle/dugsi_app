import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:kobac/school_admin/widgets/timetable_generator_dialog.dart';
import 'package:provider/provider.dart';

/// Strict capacity mismatches and missing assignments block generation.
void main() {
  Future<void> openReadyForPreview(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ShiftsProvider>(
        create: (_) => ShiftsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTimetableGeneratorDialog(
                  context,
                  years: const [
                    AcademicYear(id: 7, name: '2026-2027', isActive: true),
                  ],
                  initialAcademicYearId: 7,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Working Days'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sare').last);
    await tester.pumpAndSettle();
    // Step 3 always starts empty now — type a value into every visible
    // field before saving, exactly as an admin would.
    final periodField = find.byKey(const ValueKey('subject-periods-1'));
    await tester.ensureVisible(periodField);
    await tester.enterText(periodField, '5');
    await tester.pump();
    await tester.ensureVisible(find.text('Save Level Configuration'));
    await tester.tap(find.text('Save Level Configuration'));
    await tester.pumpAndSettle();
  }

  http.Response _levelsResponse() => http.Response(
    jsonEncode({
      'levels': [
        {'id': 2, 'name': 'Sare'},
      ],
    }),
    200,
  );
  http.Response _shiftsResponse() => http.Response(
    jsonEncode({
      'shifts': [
        {'id': 1, 'name': 'Morning'},
      ],
    }),
    200,
  );
  http.Response _workingDaysResponse() => http.Response(
    jsonEncode({
      'days': ['MON', 'TUE', 'WED', 'THU', 'FRI'],
    }),
    200,
  );
  http.Response _subjectsResponse() => http.Response(
    jsonEncode({
      'subjects': [
        {'subject_id': 1, 'subject_name': 'Mathematics', 'periods_per_week': 5},
      ],
    }),
    200,
  );

  testWidgets('all under-allocated classes block generation', (tester) async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/levels')) return _levelsResponse();
      if (path.endsWith('/shifts')) return _shiftsResponse();
      if (path.endsWith('/working-days')) return _workingDaysResponse();
      if (path.endsWith('/subjects')) return _subjectsResponse();
      if (path.endsWith('/preview')) {
        return http.Response(
          jsonEncode({
            'classes': [
              {
                'class_id': 1,
                'class_name': 'Form Two',
                'requested_periods': 37,
                'available_slots': 42,
                'difference': 5,
                'status': 'UNDER_ALLOCATED',
                'blocking': false,
                'can_generate': true,
                'missing_requirements': [],
                'missing_teacher_assignments': [],
              },
              {
                'class_id': 2,
                'class_name': 'Form One',
                'requested_periods': 37,
                'available_slots': 42,
                'difference': 5,
                'status': 'UNDER_ALLOCATED',
                'blocking': false,
                'can_generate': true,
                'missing_requirements': [],
                'missing_teacher_assignments': [],
              },
              {
                'class_id': 3,
                'class_name': 'Class 8',
                'requested_periods': 26,
                'available_slots': 42,
                'difference': 16,
                'status': 'UNDER_ALLOCATED',
                'blocking': false,
                'can_generate': true,
                'missing_requirements': [],
                'missing_teacher_assignments': [],
              },
            ],
          }),
          200,
        );
      }
      return http.Response(jsonEncode({}), 200);
    });

    await http.runWithClient(() async {
      await openReadyForPreview(tester);

      expect(find.text('Form Two'), findsOneWidget);
      expect(find.text('Form One'), findsOneWidget);
      expect(find.text('Class 8'), findsOneWidget);
      expect(find.text('UNDER ALLOCATED'), findsNWidgets(3));
      expect(find.text('BLOCKED'), findsNothing);
      expect(
        find.text('Add 16 more periods to fill this class timetable.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Each class must exactly fill its weekly timetable. Fix the blocking issues before generating.',
        ),
        findsOneWidget,
      );

      // Warning-only — Continue to Generate must stay enabled.
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets('over-allocation blocks generation without a bypass', (
    tester,
  ) async {
    var generateCalled = false;
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/levels')) return _levelsResponse();
      if (path.endsWith('/shifts')) return _shiftsResponse();
      if (path.endsWith('/working-days')) return _workingDaysResponse();
      if (path.endsWith('/subjects')) return _subjectsResponse();
      if (path.endsWith('/preview')) {
        return http.Response(
          jsonEncode({
            'classes': [
              {
                'class_id': 1,
                'class_name': 'Class 8',
                'requested_periods': 44,
                'available_slots': 42,
                'difference': -2,
                'expected_unscheduled_periods': 2,
                'status': 'OVER_ALLOCATED',
                'blocking': false,
                'can_generate': true,
                'missing_requirements': [],
                'missing_teacher_assignments': [],
              },
            ],
          }),
          200,
        );
      }
      if (path.endsWith('/generate')) {
        generateCalled = true;
        return http.Response(
          jsonEncode({'success': true, 'unscheduled': []}),
          200,
        );
      }
      return http.Response(jsonEncode({}), 200);
    });

    await http.runWithClient(() async {
      await openReadyForPreview(tester);

      expect(find.text('OVER ALLOCATED'), findsOneWidget);
      expect(find.text('BLOCKED'), findsNothing);
      expect(find.text('Reduce the configured periods by 2.'), findsOneWidget);

      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      expect(find.text('Generate Anyway'), findsNothing);
      expect(generateCalled, isFalse);
      await tester.tap(find.text('Back to Fix'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('subject-periods-1')),
            )
            .controller!
            .text,
        '5',
      );
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets('a missing teacher assignment is a real blocker: red BLOCKED card, '
      'Generate disabled', (tester) async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/levels')) return _levelsResponse();
      if (path.endsWith('/shifts')) return _shiftsResponse();
      if (path.endsWith('/working-days')) return _workingDaysResponse();
      if (path.endsWith('/subjects')) return _subjectsResponse();
      if (path.endsWith('/preview')) {
        return http.Response(
          jsonEncode({
            'classes': [
              {
                'class_id': 1,
                'class_name': 'Class 8',
                'requested_periods': 42,
                'available_slots': 42,
                'difference': 0,
                'status': 'COMPLETE',
                'blocking': true,
                'can_generate': false,
                'missing_requirements': [],
                'missing_teacher_assignments': [
                  'Class 8 - Science has 3 requested weekly periods but '
                      'no teacher assignment exists.',
                ],
              },
            ],
          }),
          200,
        );
      }
      return http.Response(jsonEncode({}), 200);
    });

    await http.runWithClient(() async {
      await openReadyForPreview(tester);

      expect(find.text('BLOCKED'), findsOneWidget);
      expect(find.text('COMPLETE'), findsNothing);
      expect(find.text('Teacher Assignment Required'), findsOneWidget);
      expect(
        find.text(
          '• Class 8 - Science has 3 requested weekly periods but no '
          'teacher assignment exists.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Each class must exactly fill its weekly timetable. Fix the blocking issues before generating.',
        ),
        findsOneWidget,
      );

      // A real blocker — Continue to Generate must be disabled.
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
