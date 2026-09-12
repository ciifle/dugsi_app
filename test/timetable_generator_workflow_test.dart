import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/timetable_generator_service.dart';
import 'package:kobac/school_admin/widgets/timetable_generator_dialog.dart';

void main() {
  test('recognizes missing teacher days off in backend errors and flags', () {
    expect(
      timetableNeedsTeacherDaysOff({
        'issues': [
          {'code': 'TEACHER_DAY_OFFS_MISSING'},
        ],
      }),
      isTrue,
    );
    expect(
      timetableNeedsTeacherDaysOff({
        'data': {'teacher_day_offs_configured': false},
      }),
      isTrue,
    );
    expect(
      timetableNeedsTeacherDaysOff({
        'message': 'Teacher day offs configuration is insufficient.',
      }),
      isTrue,
    );
    expect(
      timetableNeedsTeacherDaysOff({'message': 'Teacher assignments missing.'}),
      isFalse,
    );
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets(
      'exact periods persist and wizard uses saved days off at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final requests = <http.Request>[];
        var periods = [1, 1, 1, 1];
        var missing = true;
        var openedDaysOff = false;
        final client = MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          Object data = {};
          if (path.endsWith('/levels'))
            data = {
              'levels': [
                {'id': 2, 'name': 'Sare'},
              ],
            };
          if (path.endsWith('/working-days'))
            data = {
              'days': ['MON', 'TUE', 'WED', 'THU', 'SAT', 'SUN'],
            };
          if (path.endsWith('/subjects')) {
            if (request.method == 'PUT') {
              final body = jsonDecode(request.body) as Map;
              periods = (body['subjects'] as List)
                  .map((s) => s['periods_per_week'] as int)
                  .toList();
            }
            data = {
              'subjects': [
                for (var i = 0; i < 4; i++)
                  {
                    'subject_id': i + 1,
                    'subject_name': [
                      'Islamic',
                      'Biology',
                      'Chemistry',
                      'Mathematics',
                    ][i],
                    'periods_per_week': periods[i],
                  },
              ],
            };
          }
          if (path.endsWith('/preview'))
            data = {
              'feasible': !missing,
              'issues': missing
                  ? [
                      {
                        'code': 'TEACHER_DAY_OFFS_MISSING',
                        'message': 'Teacher days off are not configured.',
                      },
                    ]
                  : [],
              'summary': {'required_periods': 16},
            };
          return http.Response(jsonEncode(data), 200);
        });
        await http.runWithClient(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showTimetableGeneratorDialog(
                      context,
                      years: const [
                        AcademicYear(id: 7, name: '2026-2027', isActive: true),
                      ],
                      initialAcademicYearId: 7,
                      onOpenTeacherDaysOff: () => openedDaysOff = true,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (width < 600) expect(find.text('Step 1 of 5'), findsOneWidget);
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Save Working Days'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(DropdownButtonFormField<int?>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sare').last);
          await tester.pumpAndSettle();
          final exact = ['5', '3', '3', '5'];
          for (var i = 0; i < 4; i++) {
            final input = find.byKey(ValueKey('subject-periods-${i + 1}'));
            await tester.ensureVisible(input);
            await tester.enterText(input, exact[i]);
            await tester.pump();
          }
          final first = find.byKey(const ValueKey('subject-periods-1'));
          await tester.ensureVisible(first);
          for (final invalid in ['-1', '1.5', 'abc']) {
            await tester.enterText(first, invalid);
            expect(tester.widget<TextFormField>(first).controller!.text, '5');
          }
          await tester.enterText(first, '');
          await tester.tap(find.text('Save Level Configuration'));
          await tester.pumpAndSettle();
          expect(
            requests.where(
              (r) => r.method == 'PUT' && r.url.path.endsWith('/subjects'),
            ),
            isEmpty,
          );
          await tester.ensureVisible(first);
          await tester.enterText(first, '5');
          await tester.tap(find.text('Save Level Configuration'));
          await tester.pumpAndSettle();
          expect(periods, [5, 3, 3, 5]);
          final reload = await TimetableGeneratorService().getLevelSubjects(
            2,
            7,
          );
          expect(
            (reload as GeneratorSuccess<List<LevelSubjectPeriod>>).data.map(
              (s) => s.periodsPerWeek,
            ),
            periods,
          );
          await tester.tap(find.text('Preview Timetable'));
          await tester.pumpAndSettle();
          expect(find.text('Manage Teacher Days Off'), findsOneWidget);
          expect(find.text('Random Teacher Days Off'), findsNothing);
          expect(
            requests.any((r) => r.url.path.contains('/day-offs/')),
            isFalse,
          );
          expect(tester.takeException(), isNull);
          if (width < 600) {
            await tester.ensureVisible(find.text('Manage Teacher Days Off'));
            await tester.tap(find.text('Manage Teacher Days Off'));
            await tester.pumpAndSettle();
            expect(openedDaysOff, isTrue);
          } else {
            missing = false;
            await tester.tap(find.text('Refresh Preview'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Continue to Generate'));
            await tester.pumpAndSettle();
            await tester.tap(
              find.widgetWithText(FilledButton, 'Generate Timetable'),
            );
            await tester.pumpAndSettle();
            final generated = requests.singleWhere(
              (r) => r.url.path.endsWith('/generate'),
            );
            expect(jsonDecode(generated.body), {
              'academic_year_id': 7,
              'level_id': 2,
              'replace_existing': false,
            });
          }
        }, () => client);
      },
    );
  }

  group('TimetableGeneratorPreview capacity parsing', () {
    test('extracts structured per-class shortages and hides raw JSON', () {
      final preview = TimetableGeneratorPreview.fromJson({
        'feasible': false,
        'summary': {'required_periods': 130, 'available_periods': 126},
        'issues': [
          {
            'class_name': 'Class 5 A',
            'required_periods': 44,
            'available_periods': 42,
          },
          {
            'class_name': 'Class 4 A',
            'required_periods': 43,
            'available_periods': 42,
          },
          {
            'class_name': 'Class 4 B',
            'required_periods': 43,
            'available_periods': 42,
          },
        ],
      });
      expect(preview.feasible, isFalse);
      // Backend reports infeasible purely on capacity, so Flutter must not
      // block generation — canGenerate stays true despite feasible:false.
      expect(preview.canGenerate, isTrue);
      expect(preview.capacityIssues, hasLength(3));
      expect(preview.capacityIssues[0].className, 'Class 5 A');
      expect(preview.capacityIssues[0].requested, 44);
      expect(preview.capacityIssues[0].available, 42);
      expect(preview.capacityIssues[0].unscheduled, 2);
      expect(preview.capacityIssues[1].unscheduled, 1);
      expect(preview.capacityIssues[2].unscheduled, 1);
      // Non-capacity-shaped issues remain in the plain message list.
      expect(preview.issues, isEmpty);
    });

    test('derives the shortage when the backend omits it explicitly', () {
      final issue = TimetableCapacityIssue.fromJson({
        'class_name': 'Class 6 A',
        'required_periods': 50,
        'available_periods': 42,
      });
      expect(issue.unscheduled, 8);
    });

    test(
      'prefers explicit scheduled_periods over available_periods for the shortfall',
      () {
        final issue = TimetableCapacityIssue.fromJson({
          'class_name': 'Class 6 A',
          'requested_periods': 44,
          'available_periods': 42,
          'scheduled_periods': 40,
        });
        // Hard constraints (e.g. a shared teacher) can push the actually
        // scheduled count below raw available capacity — the reported
        // shortfall must reflect that, not just requested - available.
        expect(issue.unscheduled, 4);
      },
    );

    test('maps known reason codes to fixed backend-accurate text', () {
      final capacity = TimetableCapacityIssue.fromJson({
        'class_name': 'Class 5 A',
        'requested_periods': 44,
        'available_periods': 42,
        'reason_code': 'CLASS_CAPACITY_EXCEEDED',
      });
      expect(
        capacity.reasonText,
        'This class has 42 physical weekly timetable slots.',
      );
      expect(capacity.reasonText, isNot(contains('teacher')));
      expect(capacity.reasonText, isNot(contains('conflict')));

      final dayOff = TimetableCapacityIssue.fromJson({
        'class_name': 'Class 4 A',
        'requested_periods': 5,
        'available_periods': 5,
        'reason_code': 'TEACHER_DAY_OFF',
      });
      expect(
        dayOff.reasonText,
        'Teacher unavailable because of a configured weekly day off.',
      );

      expect(
        reasonCodeMessage('TEACHER_TIME_CONFLICT'),
        'Teacher is already required by another class in the same slot.',
      );
      expect(
        reasonCodeMessage('CLASS_TIME_CONFLICT'),
        'Class already has another lesson in that slot.',
      );
      expect(
        reasonCodeMessage('NO_VALID_SHIFT_SLOT'),
        'No valid period remains in the class shift.',
      );
      expect(
        reasonCodeMessage('SOLVER_EXHAUSTED'),
        'Unable to fit all requested lessons within current constraints.',
      );
      expect(reasonCodeMessage('SOMETHING_UNKNOWN'), isNull);
    });

    test('parses subject-level results for the expandable breakdown', () {
      final issue = TimetableCapacityIssue.fromJson({
        'class_name': 'Class 5 A',
        'requested_periods': 11,
        'available_periods': 10,
        'subject_results': [
          {
            'subject_name': 'Mathematics',
            'requested': 6,
            'scheduled': 6,
            'unscheduled': 0,
          },
          {
            'subject_name': 'Islamic',
            'requested': 5,
            'scheduled': 4,
            'unscheduled': 1,
          },
        ],
      });
      expect(issue.subjectResults, hasLength(2));
      expect(issue.subjectResults[0].subjectName, 'Mathematics');
      expect(issue.subjectResults[0].hasUnscheduled, isFalse);
      expect(issue.subjectResults[1].subjectName, 'Islamic');
      expect(issue.subjectResults[1].unscheduled, 1);
      expect(issue.subjectResults[1].hasUnscheduled, isTrue);
    });

    test(
      'prefers the documented capacity_warnings field name over aliases',
      () {
        final preview = TimetableGeneratorPreview.fromJson({
          'feasible': true,
          'can_generate': true,
          'capacity_warnings': [
            {
              'class_name': 'Class 5 A',
              'requested_periods': 44,
              'available_periods': 42,
              'reason_code': 'CLASS_CAPACITY_EXCEEDED',
            },
          ],
        });
        expect(preview.capacityIssues, hasLength(1));
        expect(preview.capacityIssues[0].reasonCode, 'CLASS_CAPACITY_EXCEEDED');
      },
    );

    test(
      'derives capacity warnings from a full per-class breakdown when no summarized array is sent',
      () {
        final preview = TimetableGeneratorPreview.fromJson({
          'feasible': true,
          'can_generate': true,
          'classes': [
            {
              'class_name': 'Class 5 A',
              'requested_periods': 44,
              'available_periods': 42,
              'scheduled_periods': 42,
              'unscheduled_periods': 2,
              'capacity_warning': true,
            },
            {
              'class_name': 'Class 3 A',
              'requested_periods': 30,
              'available_periods': 42,
              'scheduled_periods': 30,
              'unscheduled_periods': 0,
              'capacity_warning': false,
            },
          ],
        });
        expect(preview.capacityIssues, hasLength(1));
        expect(preview.capacityIssues[0].className, 'Class 5 A');
      },
    );

    test('non-capacity issues stay as plain messages, not fake cards', () {
      final preview = TimetableGeneratorPreview.fromJson({
        'feasible': false,
        'issues': [
          {'message': 'No teacher is assigned to Mathematics for Class 5 A.'},
        ],
      });
      expect(preview.capacityIssues, isEmpty);
      expect(preview.issues, [
        'No teacher is assigned to Mathematics for Class 5 A.',
      ]);
      // A real (non-capacity) error blocks generation.
      expect(preview.canGenerate, isFalse);
    });

    test(
      'errors and capacity_issues are both read when the backend sends both at once',
      () {
        final preview = TimetableGeneratorPreview.fromJson({
          'feasible': false,
          'errors': [
            {'message': 'No working days are configured.'},
          ],
          'capacity_issues': [
            {
              'class_name': 'Class 5 A',
              'required_periods': 44,
              'available_periods': 42,
            },
          ],
        });
        // The `??` chain must never let capacity_issues silently disappear
        // just because errors is also present.
        expect(preview.issues, ['No working days are configured.']);
        expect(preview.capacityIssues, hasLength(1));
        // A real blocking error alongside the capacity warning still blocks.
        expect(preview.canGenerate, isFalse);
      },
    );

    test('an explicit can_generate field always wins over derived logic', () {
      final blockedDespiteNoIssues = TimetableGeneratorPreview.fromJson({
        'feasible': true,
        'can_generate': false,
      });
      expect(blockedDespiteNoIssues.canGenerate, isFalse);

      final allowedDespiteCapacityAndErrors =
          TimetableGeneratorPreview.fromJson({
            'feasible': false,
            'can_generate': true,
            'errors': [
              {'message': 'Some warning the backend still allows past.'},
            ],
          });
      expect(allowedDespiteCapacityAndErrors.canGenerate, isTrue);
    });

    for (final scenario in [
      (required: 44, available: 42, expectWarning: true),
      (required: 43, available: 42, expectWarning: true),
      (required: 42, available: 42, expectWarning: false),
      (required: 40, available: 42, expectWarning: false),
    ]) {
      test('required=${scenario.required} available=${scenario.available} → '
          'canGenerate=true, warning=${scenario.expectWarning}', () {
        final capacityShaped = scenario.required > scenario.available
            ? [
                {
                  'class_name': 'Class 5 A',
                  'required_periods': scenario.required,
                  'available_periods': scenario.available,
                },
              ]
            : <Map<String, dynamic>>[];
        final preview = TimetableGeneratorPreview.fromJson({
          'feasible': capacityShaped.isEmpty,
          'summary': {
            'required_periods': scenario.required,
            'available_periods': scenario.available,
          },
          'capacity_issues': capacityShaped,
        });
        expect(preview.canGenerate, isTrue);
        expect(preview.capacityIssues.isNotEmpty, scenario.expectWarning);
      });
    }
  });

  group('TimetableGenerationResult parsing', () {
    test('extracts unscheduled per-class counts after generation', () {
      final result = TimetableGenerationResult.fromJson({
        'unscheduled': [
          {
            'class_name': 'Class 5 A',
            'scheduled_periods': 42,
            'unscheduled_periods': 2,
          },
          {
            'class_name': 'Class 4 A',
            'scheduled_periods': 42,
            'unscheduled_periods': 1,
          },
          {
            'class_name': 'Class 3 A',
            'scheduled_periods': 30,
            'unscheduled_periods': 0,
          },
        ],
      });
      expect(result.unscheduled, hasLength(2));
      expect(result.unscheduled[0].className, 'Class 5 A');
      expect(result.unscheduled[0].scheduled, 42);
      expect(result.unscheduled[0].unscheduled, 2);
      // Totals must reflect the whole reported class list, not just the
      // filtered unscheduled subset.
      expect(result.totalScheduled, 42 + 42 + 30);
      expect(result.totalUnscheduled, 2 + 1 + 0);
    });

    test('empty when nothing went unscheduled', () {
      final result = TimetableGenerationResult.fromJson({'success': true});
      expect(result.unscheduled, isEmpty);
      expect(result.totalScheduled, 0);
    });

    test('prefers a full per-class breakdown over the partial fallback', () {
      final result = TimetableGenerationResult.fromJson({
        'classes': [
          {
            'class_name': 'Class 5 A',
            'requested_periods': 44,
            'scheduled_periods': 42,
            'unscheduled_periods': 2,
          },
          {
            'class_name': 'Class 3 A',
            'requested_periods': 30,
            'scheduled_periods': 30,
            'unscheduled_periods': 0,
          },
        ],
      });
      expect(result.classes, hasLength(2));
      expect(result.unscheduled, hasLength(1));
      expect(result.totalScheduled, 72);
    });
  });

  testWidgets(
    'Dhaxe Hoose case: four over-capacity classes show precise amber warnings, Generate stays enabled',
    (tester) async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/levels')) {
          return http.Response(
            jsonEncode({
              'levels': [
                {'id': 2, 'name': 'Dhaxe Hoose'},
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
                  'periods_per_week': 6,
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/preview')) {
          // Documented contract: over-capacity alone reports
          // feasible:true / can_generate:true with a top-level
          // capacity_warnings array — never a fatal condition.
          return http.Response(
            jsonEncode({
              'feasible': true,
              'can_generate': true,
              'errors': [],
              'capacity_warnings': [
                {
                  'class_name': 'Class 5 A',
                  'requested_periods': 44,
                  'available_periods': 42,
                  'scheduled_periods': 42,
                  'unscheduled_periods': 2,
                  'reason_code': 'CLASS_CAPACITY_EXCEEDED',
                  'subject_results': [
                    {
                      'subject_name': 'Mathematics',
                      'requested': 6,
                      'scheduled': 6,
                      'unscheduled': 0,
                    },
                    {
                      'subject_name': 'Islamic',
                      'requested': 5,
                      'scheduled': 4,
                      'unscheduled': 1,
                    },
                  ],
                },
                {
                  'class_name': 'Class 4 A',
                  'requested_periods': 43,
                  'available_periods': 42,
                  'scheduled_periods': 42,
                  'unscheduled_periods': 1,
                  'reason_code': 'CLASS_CAPACITY_EXCEEDED',
                },
                {
                  'class_name': 'Class 4 B',
                  'requested_periods': 43,
                  'available_periods': 42,
                  'scheduled_periods': 42,
                  'unscheduled_periods': 1,
                  'reason_code': 'CLASS_CAPACITY_EXCEEDED',
                },
                {
                  'class_name': 'Class 3 A',
                  'requested_periods': 43,
                  'available_periods': 42,
                  'scheduled_periods': 42,
                  'unscheduled_periods': 1,
                  'reason_code': 'CLASS_CAPACITY_EXCEEDED',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
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
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Working Days'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dhaxe Hoose').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Level Configuration'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preview Timetable'));
        await tester.pumpAndSettle();
        // Non-blocking warning framing, never a fatal-error state.
        expect(find.text('Ready to Generate'), findsOneWidget);
        expect(find.text('With capacity warnings'), findsOneWidget);
        expect(find.text('Timetable Cannot Be Generated Yet'), findsNothing);
        expect(find.text('Configuration needs attention'), findsNothing);
        expect(find.text('Capacity Warnings'), findsOneWidget);
        // The obsolete generic teacher/class-conflict message must never
        // appear for a pure capacity shortage.
        expect(find.textContaining('teacher or class conflict'), findsNothing);
        expect(find.textContaining('Requires 44 periods'), findsNothing);

        for (final className in [
          'Class 5 A',
          'Class 4 A',
          'Class 4 B',
          'Class 3 A',
        ]) {
          expect(find.text(className), findsOneWidget);
        }
        expect(find.text('Available timetable slots: 42'), findsNWidgets(4));
        expect(
          find.text(
            'Reason: This class has 42 physical weekly timetable slots.',
          ),
          findsNWidgets(4),
        );
        expect(find.text('2 unscheduled'), findsOneWidget);
        expect(find.text('1 unscheduled'), findsNWidgets(3));

        // Subject-level breakdown is expandable, not shown by default.
        expect(find.text('Mathematics'), findsNothing);
        await tester.ensureVisible(find.text('Subject details').first);
        await tester.tap(find.text('Subject details').first);
        await tester.pumpAndSettle();
        expect(find.text('Mathematics'), findsOneWidget);
        expect(find.text('Requested 6 • Scheduled 6'), findsOneWidget);
        expect(find.text('Islamic'), findsOneWidget);
        expect(
          find.text('Requested 5 • Scheduled 4 • Unscheduled 1'),
          findsOneWidget,
        );

        // Generate remains enabled — the only Continue button on this step.
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue to Generate'),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Back'))
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets(
    'a real blocking error (missing teacher assignment) disables Generate',
    (tester) async {
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
                  'subject_name': 'Arabic',
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
              'feasible': false,
              'errors': [
                {
                  'class_name': 'Class 5 A',
                  'subject_name': 'Arabic',
                  'message': 'No teacher is assigned to teach this subject.',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
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
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Working Days'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sare').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Level Configuration'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preview Timetable'));
        await tester.pumpAndSettle();
        expect(find.text('Timetable Cannot Be Generated Yet'), findsOneWidget);
        expect(find.text('Capacity Warning'), findsNothing);
        expect(
          find.text(
            'Class 5 A / Arabic: No teacher is assigned to teach this subject.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Back'))
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets(
    'switching levels clears the previous list before loading the new one, no leakage',
    (tester) async {
      final subjectsByLevel = {
        2: [
          {'subject_id': 1, 'subject_name': 'Jirdhis', 'periods_per_week': 4},
        ],
        3: [
          {'subject_id': 9, 'subject_name': 'Xisaab', 'periods_per_week': 6},
        ],
      };
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/levels')) {
          return http.Response(
            jsonEncode({
              'levels': [
                {'id': 2, 'name': 'Sare'},
                {'id': 3, 'name': 'Dhexe'},
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
          final levelId = int.parse(
            path.split('/')[path.split('/').length - 2],
          );
          return http.Response(
            jsonEncode({'subjects': subjectsByLevel[levelId] ?? []}),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
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
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Working Days'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sare').last);
        await tester.pumpAndSettle();
        expect(find.text('Jirdhis'), findsOneWidget);
        expect(find.text('Xisaab'), findsNothing);

        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dhexe').last);
        await tester.pumpAndSettle();
        // Sare's subject must be gone immediately, not lingering during load.
        expect(find.text('Jirdhis'), findsNothing);
        expect(find.text('Xisaab'), findsOneWidget);

        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sare').last);
        await tester.pumpAndSettle();
        expect(find.text('Jirdhis'), findsOneWidget);
        expect(find.text('Xisaab'), findsNothing);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  for (final scenario in [
    {'required': 40, 'available': 42, 'label': '2 free timetable slots'},
    {'required': 42, 'available': 42, 'label': null},
  ]) {
    testWidgets(
      'free/exact capacity preview never claims an error (required=${scenario['required']}, available=${scenario['available']})',
      (tester) async {
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
                    'subject_name': 'Arabic',
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
                'feasible': true,
                'summary': {
                  'required_periods': scenario['required'],
                  'available_periods': scenario['available'],
                },
              }),
              200,
            );
          }
          return http.Response(jsonEncode({}), 200);
        });
        await http.runWithClient(() async {
          await tester.pumpWidget(
            MaterialApp(
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
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Save Working Days'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(DropdownButtonFormField<int?>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sare').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Save Level Configuration'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Preview Timetable'));
          await tester.pumpAndSettle();
          expect(find.text('Ready to Generate'), findsOneWidget);
          expect(find.text('Timetable Cannot Be Generated Yet'), findsNothing);
          final label = scenario['label'];
          if (label != null) {
            expect(find.text(label as String), findsOneWidget);
          }
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Continue to Generate'),
                )
                .onPressed,
            isNotNull,
          );
          expect(tester.takeException(), isNull);
        }, () => client);
      },
    );
  }

  testWidgets(
    'Sare renders the full backend union with no local intersection filtering, and saves only those subjects',
    (tester) async {
      const sareSubjects = [
        'Arabic',
        'Biology',
        'Business',
        'Chemistry',
        'English',
        'Geography',
        'History',
        'Islamic',
        'Jirdhis',
        'Mathematics',
        'Physics',
        'Soomaali',
        'Technology',
      ];
      List<Map<String, dynamic>> currentSareSubjects() => [
        for (var i = 0; i < sareSubjects.length; i++)
          {
            'subject_id': i + 1,
            'subject_name': sareSubjects[i],
            'periods_per_week': 1,
          },
      ];
      var stored = currentSareSubjects();
      final putBodies = <Map<String, dynamic>>[];
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
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'days': ['MON', 'TUE', 'WED', 'THU', 'FRI'],
            }),
            200,
          );
        }
        if (path.endsWith('/subjects')) {
          if (request.method == 'PUT') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            putBodies.add(body);
            stored = (body['subjects'] as List)
                .map(
                  (s) => {
                    'subject_id': s['subject_id'],
                    'subject_name': sareSubjects[(s['subject_id'] as int) - 1],
                    'periods_per_week': s['periods_per_week'],
                  },
                )
                .toList();
          }
          return http.Response(jsonEncode({'subjects': stored}), 200);
        }
        return http.Response(jsonEncode({}), 200);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
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
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Working Days'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sare').last);
        await tester.pumpAndSettle();

        // The full 13-subject union renders — no "must exist in every class"
        // filtering. Jirdhis specifically must be present.
        for (final name in sareSubjects) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.text('Jirdhis'), findsOneWidget);

        await tester.tap(find.text('Save Level Configuration'));
        await tester.pumpAndSettle();

        // Exactly the 13 currently-returned subjects were submitted — none
        // dropped, none invented.
        final sent = (putBodies.single['subjects'] as List)
            .map((s) => s['subject_id'] as int)
            .toSet();
        expect(sent, Set<int>.from(List.generate(13, (i) => i + 1)));
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets(
    'generation with unscheduled periods shows an informational result dialog',
    (tester) async {
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
                  'subject_name': 'Arabic',
                  'periods_per_week': 44,
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/preview')) {
          return http.Response(
            jsonEncode({
              'feasible': false,
              'errors': [],
              'capacity_issues': [
                {
                  'class_name': 'Class 5 A',
                  'required_periods': 44,
                  'available_periods': 42,
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/generate')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'unscheduled': [
                {
                  'class_name': 'Class 5 A',
                  'scheduled_periods': 42,
                  'unscheduled_periods': 2,
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
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
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Working Days'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sare').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Level Configuration'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preview Timetable'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue to Generate'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Generate Timetable'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Timetable Generated'), findsOneWidget);
        expect(find.text('Class 5 A'), findsOneWidget);
        expect(find.text('42 scheduled'), findsOneWidget);
        expect(find.text('2 unscheduled'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );
}
