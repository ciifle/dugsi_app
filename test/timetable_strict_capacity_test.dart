import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/school_admin/widgets/timetable_generator_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:kobac/services/timetable_generator_service.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> readiness(int requested, int available) => {
  'class_name': 'Class 8',
  'requested_periods': requested,
  'available_slots': available,
  'difference': available - requested,
  'status': requested == available
      ? 'COMPLETE'
      : requested < available
      ? 'UNDER_ALLOCATED'
      : 'OVER_ALLOCATED',
  'ready_to_generate': requested == available,
};

Future<void> select(WidgetTester tester, String label) async {
  final dropdown = find.byType(DropdownButtonFormField<int?>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> openSubjects(WidgetTester tester, String shift) async {
  await tap(tester, 'Open');
  await tap(tester, 'Continue');
  await select(tester, shift);
  await tap(tester, 'Save Working Days');
  await select(tester, 'Sare');
}

Future<void> mount(WidgetTester tester, {ValueChanged<bool?>? onResult}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ShiftsProvider(),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showTimetableGeneratorDialog(
                  context,
                  years: const [
                    AcademicYear(id: 7, name: '2026-2027', isActive: true),
                    AcademicYear(id: 8, name: '2027-2028', isActive: false),
                  ],
                  initialAcademicYearId: 7,
                );
                onResult?.call(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

http.Response json(Object value, [int code = 200]) =>
    http.Response(jsonEncode(value), code);

http.Response? setup(http.Request request) {
  final path = request.url.path;
  if (path.endsWith('/levels'))
    return json({
      'levels': [
        {'id': 2, 'name': 'Sare'},
      ],
    });
  if (path.endsWith('/shifts'))
    return json({
      'shifts': [
        {'id': 1, 'name': 'Morning'},
        {'id': 2, 'name': 'Afternoon'},
      ],
    });
  if (path.endsWith('/working-days')) {
    final body = request.method == 'PUT'
        ? jsonDecode(request.body) as Map
        : request.url.queryParameters;
    final morning = body['shift_id'].toString() == '1';
    return json({
      'days': ['SAT', 'SUN', 'MON', 'TUE', 'WED', if (morning) 'THU'],
    });
  }
  if (path.endsWith('/subjects'))
    return json({
      'subjects': [
        {'subject_id': 1, 'subject_name': 'Biology', 'periods_per_week': 3},
      ],
    });
  return null;
}

void main() {
  testWidgets(
    'backend generation rejection invalidates preview without a bypass',
    (tester) async {
      var calls = 0;
      const diagnostic =
          'Class 8 - Science has 3 requested weekly periods but no teacher assignment exists.';
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/preview')) {
          return json({
            'classes': [readiness(42, 42)],
          });
        }
        if (request.url.path.endsWith('/generate')) {
          calls++;
          return json({'message': diagnostic}, 409);
        }
        return setup(request) ?? json({});
      });
      await http.runWithClient(() async {
        await mount(tester);
        await openSubjects(tester, 'Morning');
        final field = find.byKey(const ValueKey('subject-periods-1'));
        await tester.ensureVisible(field);
        await tester.enterText(field, '3');
        await tester.pump();
        await tap(tester, 'Save Level Configuration');
        await tap(tester, 'Continue to Generate');
        await tester.tap(
          find.widgetWithText(FilledButton, 'Generate Timetable'),
        );
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(find.text(diagnostic), findsOneWidget);
        expect(find.text('Replace Existing Timetable'), findsNothing);
        expect(find.text('Timetable generated successfully.'), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue'),
              )
              .onPressed,
          isNull,
        );
        await tap(tester, 'Back to Fix');
        expect(tester.widget<TextFormField>(field).controller!.text, '3');
      }, () => client);
    },
  );

  test('all class diagnostics and backend blockers must allow generation', () {
    final complete = readiness(42, 42);
    for (final blocker in <Map<String, dynamic>>[
      {'ready_to_generate': false},
      {'can_generate': false},
      {'blocking': true},
      {'status': 'UNKNOWN'},
      {'status': 'UNDER_ALLOCATED'},
      {'requested_periods': 41},
      {'available_slots': null},
      {'difference': 1},
      {
        'missing_requirements': ['Science'],
      },
      {
        'missing_teacher_assignments': ['Science requires a teacher.'],
      },
      {'expected_unscheduled_periods': 1},
    ]) {
      expect(
        TimetableGeneratorPreview.fromJson({
          'can_generate': true,
          'classes': [
            complete,
            {...complete, ...blocker},
          ],
        }).canGenerate,
        isFalse,
        reason: '$blocker',
      );
    }
    for (final blocker in <Map<String, dynamic>>[
      {'can_generate': false},
      {'ready_to_generate': false},
      {'feasible': false},
      {
        'errors': ['Teacher unavailable'],
      },
    ]) {
      expect(
        TimetableGeneratorPreview.fromJson({
          'classes': [complete],
          ...blocker,
        }).canGenerate,
        isFalse,
      );
    }
    // Mixed shifts/curricula use each class's backend capacity, not the level union sum.
    expect(
      TimetableGeneratorPreview.fromJson({
        'classes': [complete, readiness(35, 35)],
      }).canGenerate,
      isTrue,
    );
  });

  for (final width in [320.0, 1200.0]) {
    for (final scenario in [
      (shift: 'Morning', requested: 42, available: 42),
      (shift: 'Morning', requested: 41, available: 42),
      (shift: 'Afternoon', requested: 35, available: 35),
      (shift: 'Afternoon', requested: 34, available: 35),
      (shift: 'Afternoon', requested: 36, available: 35),
    ]) {
      testWidgets(
        '${scenario.shift} ${scenario.requested}/${scenario.available} at $width',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 850));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          var generated = false;
          bool? dialogResult;
          final client = MockClient((request) async {
            if (request.url.path.endsWith('/preview'))
              return json({
                'classes': [readiness(scenario.requested, scenario.available)],
              });
            if (request.url.path.endsWith('/generate')) {
              generated = true;
              return json({'success': true, 'unscheduled': []});
            }
            return setup(request) ?? json({});
          });
          await http.runWithClient(() async {
            await mount(tester, onResult: (value) => dialogResult = value);
            await openSubjects(tester, scenario.shift);
            final field = find.byKey(const ValueKey('subject-periods-1'));
            expect(
              tester.widget<TextFormField>(field).controller!.text,
              isEmpty,
            );
            await tester.ensureVisible(field);
            // This is a union requirement, not a locally computed class total.
            await tester.enterText(field, '3');
            await tester.pump();
            await tap(tester, 'Save Level Configuration');
            final complete = scenario.requested == scenario.available;
            expect(
              find.text(
                complete
                    ? 'COMPLETE'
                    : scenario.requested < scenario.available
                    ? 'UNDER ALLOCATED'
                    : 'OVER ALLOCATED',
              ),
              findsOneWidget,
            );
            if (complete) {
              await tap(tester, 'Continue to Generate');
              await tester.tap(
                find.widgetWithText(FilledButton, 'Generate Timetable'),
              );
              await tester.pumpAndSettle();
              expect(generated, isTrue);
              expect(dialogResult, isTrue);
              expect(
                find.text('Timetable generated successfully.'),
                findsOneWidget,
              );
            } else {
              expect(
                tester
                    .widget<FilledButton>(
                      find.widgetWithText(FilledButton, 'Continue'),
                    )
                    .onPressed,
                isNull,
              );
              expect(generated, isFalse);
              expect(find.text('Generate Anyway'), findsNothing);
              await tap(tester, 'Back to Fix');
              expect(tester.widget<TextFormField>(field).controller!.text, '3');
            }
            expect(tester.takeException(), isNull);
          }, () => client);
        },
      );
    }

    testWidgets(
      'save failure retains entries; year and new session reset at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 850));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var failSave = true;
        var previews = 0;
        final client = MockClient((request) async {
          if (request.url.path.endsWith('/subjects') &&
              request.method == 'PUT' &&
              failSave) {
            return json({'message': 'Configuration was not saved.'}, 422);
          }
          if (request.url.path.endsWith('/preview')) {
            previews++;
            return json({
              'classes': [readiness(41, 42)],
            });
          }
          return setup(request) ?? json({});
        });
        await http.runWithClient(() async {
          await mount(tester);
          await openSubjects(tester, 'Morning');
          final field = find.byKey(const ValueKey('subject-periods-1'));
          await tester.ensureVisible(field);
          await tester.enterText(field, '9');
          await tester.pump();
          await tap(tester, 'Save Level Configuration');
          expect(tester.widget<TextFormField>(field).controller!.text, '9');
          expect(previews, 0);
          failSave = false;
          await tap(tester, 'Save Level Configuration');
          expect(previews, 1);
          await tap(tester, 'Back to Fix');
          expect(tester.widget<TextFormField>(field).controller!.text, '9');
          await tap(tester, 'Back');
          await tap(tester, 'Back');
          await select(tester, '2027-2028');
          await tap(tester, 'Continue');
          await select(tester, 'Morning');
          await tap(tester, 'Save Working Days');
          await select(tester, 'Sare');
          expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);
          await tester.ensureVisible(field);
          await tester.enterText(field, '8');
          await tester.pump();
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();
          await openSubjects(tester, 'Morning');
          expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Save Level Configuration'),
                )
                .onPressed,
            isNull,
          );
          expect(tester.takeException(), isNull);
        }, () => client);
      },
    );
  }
}
