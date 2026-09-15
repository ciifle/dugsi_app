import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:kobac/school_admin/widgets/timetable_generator_dialog.dart';
import 'package:provider/provider.dart';

/// Regression coverage for the complete-timetable-mode contract:
/// - period-entry fields must start empty (never a synthesized 0) unless a
///   backend value was actually saved, and blank fields block Save.
/// - preview must render the new per-class status/ready_to_generate
///   diagnostics, and Generate must follow ready_to_generate exactly.
void main() {
  // Everything from pumpWidget through the final assertion must run inside
  // the SAME http.runWithClient zone — once that call returns, subsequent
  // HTTP calls fall back to a real (blocked-in-tests) client, so this
  // helper is called *from inside* each test's own runWithClient callback,
  // never wrapping its own separate zone.
  Future<void> openToSubjectsStep(
    WidgetTester tester, {
    String shiftLabel = 'Morning',
  }) async {
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
    await tester.tap(find.text(shiftLabel).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Working Days'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sare').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'every field starts empty even when the backend already has a saved '
    'periods_per_week — new-generation Step 3 always ignores it — blank '
    'field blocks save, and an explicitly-typed 0 is preserved',
    (tester) async {
      final putBodies = <Map<String, dynamic>>[];
      final subjectsResponse = {
        'subjects': [
          // Arabic and Jirdhis both have a SAVED backend value already —
          // Step 3 must still show them empty; it is never an edit screen.
          {'subject_id': 1, 'subject_name': 'Arabic', 'periods_per_week': 5},
          // No periods_per_week key at all: genuinely unconfigured.
          {'subject_id': 2, 'subject_name': 'Science'},
          {'subject_id': 3, 'subject_name': 'Jirdhis', 'periods_per_week': 0},
        ],
      };
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/levels')) {
          return http.Response(
            jsonEncode({
              'levels': [
                {'id': 2, 'name': 'Sare'},
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/shifts')) {
          return http.Response(
            jsonEncode({
              'shifts': [
                {'id': 1, 'name': 'Morning'},
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'shift_id': 1,
              'days': ['MON', 'TUE', 'WED', 'THU', 'FRI'],
            }),
            200,
          );
        }
        if (path.endsWith('/subjects')) {
          if (request.method == 'PUT') {
            putBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          }
          return http.Response(jsonEncode(subjectsResponse), 200);
        }
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(() async {
        await openToSubjectsStep(tester);

        // ALL three fields start empty, regardless of Arabic/Jirdhis
        // already having a saved backend value.
        final arabicField = find.byKey(const ValueKey('subject-periods-1'));
        final scienceField = find.byKey(const ValueKey('subject-periods-2'));
        final jirdhisField = find.byKey(const ValueKey('subject-periods-3'));
        expect(tester.widget<TextFormField>(arabicField).controller!.text, '');
        expect(tester.widget<TextFormField>(scienceField).controller!.text, '');
        expect(tester.widget<TextFormField>(jirdhisField).controller!.text, '');

        // Blank inputs leave Save visible but disabled.
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save Level Configuration'),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Save Level Configuration'));
        await tester.pumpAndSettle();
        expect(putBodies, isEmpty);

        // Admin retypes every value manually, including re-entering
        // Arabic's previously-saved 5 and Jirdhis's previously-saved 0 —
        // explicit 0 must be sent as 0, never omitted or silently changed.
        // Continue becomes enabled only once every field is valid.
        await tester.ensureVisible(arabicField);
        await tester.enterText(arabicField, '5');
        await tester.pump();
        await tester.ensureVisible(scienceField);
        await tester.enterText(scienceField, '3');
        await tester.pump();
        await tester.ensureVisible(jirdhisField);
        await tester.enterText(jirdhisField, '0');
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save Level Configuration'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.text('Save Level Configuration'));
        await tester.pumpAndSettle();
        expect(putBodies, hasLength(1));
        final sent = (putBodies.single['subjects'] as List)
            .cast<Map<String, dynamic>>();
        final bySubject = {for (final s in sent) s['subject_id'] as int: s};
        expect(bySubject[1]!['periods_per_week'], 5);
        expect(bySubject[2]!['periods_per_week'], 3);
        expect(bySubject[3]!['periods_per_week'], 0);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets('switching levels never leaks previously typed period values', (
    tester,
  ) async {
    final byLevel = {
      2: [
        {'subject_id': 1, 'subject_name': 'Jirdhis'},
      ],
      3: [
        {'subject_id': 9, 'subject_name': 'Xisaab'},
      ],
    };
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/levels')) {
        return http.Response(
          jsonEncode({
            'levels': [
              {'id': 2, 'name': 'Sare'},
              {'id': 3, 'name': 'Hoose'},
            ],
          }),
          200,
        );
      }
      if (path.endsWith('/shifts')) {
        return http.Response(
          jsonEncode({
            'shifts': [
              {'id': 1, 'name': 'Morning'},
            ],
          }),
          200,
        );
      }
      if (path.endsWith('/working-days')) {
        return http.Response(
          jsonEncode({
            'days': ['MON', 'TUE', 'WED', 'THU', 'FRI'],
          }),
          200,
        );
      }
      if (path.endsWith('/subjects')) {
        final levelId = int.parse(path.split('/')[path.split('/').length - 2]);
        return http.Response(
          jsonEncode({'subjects': byLevel[levelId] ?? []}),
          200,
        );
      }
      return http.Response(jsonEncode({}), 200);
    });

    await http.runWithClient(() async {
      await openToSubjectsStep(tester);
      // Sare shows Jirdhis (subject_id 1); type a value for it.
      final sareField = find.byKey(const ValueKey('subject-periods-1'));
      await tester.ensureVisible(sareField);
      await tester.enterText(sareField, '4');
      expect(tester.widget<TextFormField>(sareField).controller!.text, '4');

      // Switch to Hoose (subject_id 9, Xisaab) — must start empty, not '4'.
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int?>));
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoose').last);
      await tester.pumpAndSettle();
      expect(find.text('Xisaab'), findsOneWidget);
      expect(find.text('Jirdhis'), findsNothing);
      final hooseField = find.byKey(const ValueKey('subject-periods-9'));
      expect(tester.widget<TextFormField>(hooseField).controller!.text, '');

      // Switch back to Sare — the '4' typed earlier must not reappear;
      // it was never saved, so the reloaded field is empty again.
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int?>));
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sare').last);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(sareField).controller!.text, '');
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets(
    'preview renders per-class COMPLETE/UNDER_ALLOCATED status, missing '
    'requirements and missing teacher assignments, and Generate follows '
    'ready_to_generate strictly',
    (tester) async {
      var allReady = false;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/levels')) {
          return http.Response(
            jsonEncode({
              'levels': [
                {'id': 2, 'name': 'Sare'},
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/shifts')) {
          return http.Response(
            jsonEncode({
              'shifts': [
                {'id': 1, 'name': 'Morning'},
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'days': ['MON', 'TUE', 'WED', 'THU', 'FRI'],
            }),
            200,
          );
        }
        if (path.endsWith('/subjects')) {
          return http.Response(
            jsonEncode({
              'subjects': [
                {
                  'subject_id': 1,
                  'subject_name': 'Mathematics',
                  'periods_per_week': 5,
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/preview')) {
          return http.Response(
            jsonEncode({
              'classes': allReady
                  ? [
                      {
                        'class_id': 7,
                        'class_name': 'Class 8',
                        'shift_id': 1,
                        'requested_periods': 42,
                        'available_slots': 42,
                        'difference': 0,
                        'status': 'COMPLETE',
                        'ready_to_generate': true,
                        'missing_requirements': [],
                        'missing_teacher_assignments': [],
                      },
                      {
                        'class_id': 8,
                        'class_name': 'Form One',
                        'shift_id': 1,
                        'requested_periods': 42,
                        'available_slots': 42,
                        'difference': 0,
                        'status': 'COMPLETE',
                        'ready_to_generate': true,
                        'missing_requirements': [],
                        'missing_teacher_assignments': [],
                      },
                    ]
                  : [
                      {
                        'class_id': 7,
                        'class_name': 'Class 8',
                        'shift_id': 1,
                        'requested_periods': 42,
                        'available_slots': 42,
                        'difference': 0,
                        'status': 'COMPLETE',
                        'ready_to_generate': true,
                        'missing_requirements': [],
                        'missing_teacher_assignments': [],
                      },
                      {
                        'class_id': 8,
                        'class_name': 'Form One',
                        'shift_id': 1,
                        'requested_periods': 24,
                        'available_slots': 42,
                        'difference': 18,
                        'status': 'UNDER_ALLOCATED',
                        'ready_to_generate': false,
                        'missing_requirements': ['Science', 'Jirdhis'],
                        'missing_teacher_assignments': [
                          'Form One - Science has 3 requested weekly periods '
                              'but no teacher assignment exists.',
                        ],
                      },
                    ],
            }),
            200,
          );
        }
        if (path.endsWith('/generate')) {
          return http.Response(
            jsonEncode({'success': true, 'unscheduled': []}),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(() async {
        await openToSubjectsStep(tester);
        final mathField = find.byKey(const ValueKey('subject-periods-1'));
        await tester.ensureVisible(mathField);
        await tester.enterText(mathField, '5');
        await tester.pump();
        await tester.ensureVisible(find.text('Save Level Configuration'));
        await tester.tap(find.text('Save Level Configuration'));
        await tester.pumpAndSettle();
        // Preview loads automatically on reaching the Review step — no
        // manual "Preview Timetable" tap should be required.
        expect(find.text('Preview Timetable'), findsNothing);
        expect(find.text('Refresh Preview'), findsOneWidget);

        expect(find.text('Class 8'), findsOneWidget);
        expect(find.text('Form One'), findsOneWidget);
        expect(find.text('COMPLETE'), findsOneWidget);
        // Form One is UNDER_ALLOCATED *and* has a missing requirement/
        // missing teacher assignment — the missing items are genuine
        // blockers, so the badge highlights BLOCKED alongside the
        // capacity correction.
        expect(find.text('UNDER ALLOCATED'), findsNothing);
        expect(find.text('BLOCKED'), findsOneWidget);
        expect(
          find.text('Add 18 more periods to fill this class timetable.'),
          findsOneWidget,
        );
        expect(find.text('Missing Period Requirements'), findsOneWidget);
        expect(find.text('• Science'), findsOneWidget);
        expect(find.text('• Jirdhis'), findsOneWidget);
        expect(find.text('Teacher Assignment Required'), findsOneWidget);
        expect(
          find.text(
            '• Form One - Science has 3 requested weekly periods but no '
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

        // Not all classes ready — Continue to Generate must stay disabled.
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue'),
              )
              .onPressed,
          isNull,
        );

        // Fix the configuration and refresh: all classes now ready.
        allReady = true;
        await tester.ensureVisible(find.text('Refresh Preview'));
        await tester.tap(find.text('Refresh Preview'));
        await tester.pumpAndSettle();
        expect(find.text('All classes are ready to generate.'), findsOneWidget);
        expect(find.text('UNDER ALLOCATED'), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue to Generate'),
              )
              .onPressed,
          isNotNull,
        );

        // Continue into the Generate step and trigger the real
        // TimetableGeneratorService.generateTimetable call — no local
        // calculation, and the dialog only closes after a real success.
        await tester.tap(find.text('Continue to Generate'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Generate Timetable'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(
          find.widgetWithText(FilledButton, 'Generate Timetable'),
        );
        await tester.pumpAndSettle();

        // Success: dialog closes and the "generated" flag reaches the
        // caller so the timetable page can refresh.
        expect(find.byType(FilledButton), findsNothing);
        expect(find.text('Timetable Generated'), findsNothing);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );
}
