import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/widgets/school_timetable_generator_dialog.dart';

/// Regression coverage for the class-configured, school-wide generator:
/// each class configures its own subjects/periods independently (never a
/// level union), capacity is whatever the backend reports per class (never
/// hardcoded), and school-wide preview/generate always use the dedicated
/// /school/preview and /school/generate endpoints with no level_id.
void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSchoolTimetableGeneratorDialog(
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
  }

  // Reopens the generator on the SAME already-pumped screen (no second
  // pumpWidget) — simulates the admin closing the wizard and tapping
  // "Generate Timetable" again, which must load everything fresh.
  Future<void> reopenDialog(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  // Class 8 (Sare, Morning, capacity 42) has 2 subjects of its own.
  // Form One (Sare, Morning, capacity 42) has a DIFFERENT 3 subjects.
  // Class 1 A (Hoose, Afternoon, capacity 35) has its own single subject.
  final classSubjects = <int, List<Map<String, dynamic>>>{
    1: [
      {'subject_id': 10, 'subject_name': 'Arabic'},
      {'subject_id': 11, 'subject_name': 'Science'},
    ],
    2: [
      {'subject_id': 20, 'subject_name': 'History'},
      {'subject_id': 21, 'subject_name': 'Geography'},
      {'subject_id': 22, 'subject_name': 'Islamic'},
    ],
    3: [
      {'subject_id': 30, 'subject_name': 'Mathematics'},
    ],
  };
  final capacities = <int, int>{1: 42, 2: 42, 3: 35};
  final savedPeriods = <int, Map<int, int>>{1: {}, 2: {}, 3: {}};

  int totalFor(int classId) =>
      savedPeriods[classId]!.values.fold(0, (a, b) => a + b);

  String statusFor(int classId) {
    final total = totalFor(classId);
    final capacity = capacities[classId]!;
    if (total == 0) return 'NOT_CONFIGURED';
    if (total == capacity) return 'READY';
    if (total > capacity) return 'OVER_ALLOCATED';
    return 'UNDER_ALLOCATED';
  }

  Map<String, dynamic> classSummaryRow(
    int classId,
    String className,
    int levelId,
    String levelName,
    int shiftId,
    String shiftName,
  ) {
    final capacity = capacities[classId]!;
    final total = totalFor(classId);
    return {
      'class_id': classId,
      'class_name': className,
      'level_id': levelId,
      'level_name': levelName,
      'shift_id': shiftId,
      'shift_name': shiftName,
      'working_day_count': shiftId == 1 ? 6 : 5,
      'periods_per_day': 7,
      'available_slots': capacity,
      'configured_periods': total,
      'difference': capacity - total,
      'status': statusFor(classId),
      'subject_count': classSubjects[classId]!.length,
    };
  }

  MockClient buildClient() => MockClient((request) async {
    final path = request.url.path;
    final classSubjectsMatch = RegExp(
      r'/classes/(\d+)/subjects$',
    ).firstMatch(path);
    if (classSubjectsMatch != null) {
      final classId = int.parse(classSubjectsMatch.group(1)!);
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        for (final entry in (body['subjects'] as List)) {
          savedPeriods[classId]![entry['subject_id'] as int] =
              entry['periods_per_week'] as int;
        }
      }
      return http.Response(
        jsonEncode({
          'class_id': classId,
          'shift_id': classId == 3 ? 2 : 1,
          'shift_name': classId == 3 ? 'Afternoon' : 'Morning',
          'available_slots': capacities[classId],
          'configured_periods': totalFor(classId),
          'difference': capacities[classId]! - totalFor(classId),
          'status': statusFor(classId),
          'subjects': classSubjects[classId]!
              .map(
                (s) => {
                  ...s,
                  'periods_per_week': savedPeriods[classId]!.containsKey(
                    s['subject_id'],
                  )
                      ? savedPeriods[classId]![s['subject_id']]
                      : null,
                },
              )
              .toList(),
        }),
        200,
      );
    }
    if (path.endsWith('/timetable-config/classes') &&
        request.method == 'GET') {
      return http.Response(
        jsonEncode({
          'academic_year_id': 7,
          'classes': [
            classSummaryRow(1, 'Class 8', 1, 'Sare', 1, 'Morning'),
            classSummaryRow(2, 'Form One', 1, 'Sare', 1, 'Morning'),
            classSummaryRow(3, 'Class 1 A', 2, 'Hoose', 2, 'Afternoon'),
          ],
        }),
        200,
      );
    }
    if (path.endsWith('/working-days')) {
      final shiftId = int.parse(request.url.queryParameters['shift_id']!);
      return http.Response(
        jsonEncode({
          'shift_id': shiftId,
          'days': shiftId == 1
              ? ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU']
              : ['SAT', 'SUN', 'MON', 'TUE', 'WED'],
        }),
        200,
      );
    }
    if (path.endsWith('/school/preview')) {
      final rows = [1, 2, 3].map((id) {
        final names = {1: 'Class 8', 2: 'Form One', 3: 'Class 1 A'};
        final shiftIds = {1: 1, 2: 1, 3: 2};
        final capacity = capacities[id]!;
        final total = totalFor(id);
        final status = total == capacity
            ? 'COMPLETE'
            : (total > capacity ? 'OVER_ALLOCATED' : 'UNDER_ALLOCATED');
        return {
          'class_id': id,
          'class_name': names[id],
          'shift_id': shiftIds[id],
          'requested_periods': total,
          'available_slots': capacity,
          'difference': capacity - total,
          'status': status,
          'missing_requirements': <String>[],
          'missing_teacher_assignments': <String>[],
        };
      }).toList();
      final allReady = rows.every((r) => r['status'] == 'COMPLETE');
      return http.Response(
        jsonEncode({
          'feasible': true,
          'can_generate': allReady,
          'ready_to_generate': allReady,
          'classes': rows,
          'errors': <String>[],
        }),
        200,
      );
    }
    if (path.endsWith('/school/generate')) {
      return http.Response(
        jsonEncode({
          'generated_count': 3,
          'generated_rows': totalFor(1) + totalFor(2) + totalFor(3),
          'requested_rows': totalFor(1) + totalFor(2) + totalFor(3),
          'unscheduled_rows': 0,
        }),
        201,
      );
    }
    return http.Response(jsonEncode({}), 200);
  });

  testWidgets(
    'class list shows real backend capacity per class (42/42/35, never '
    'hardcoded) and each class opens only its own subjects',
    (tester) async {
      savedPeriods[1]!.clear();
      savedPeriods[2]!.clear();
      savedPeriods[3]!.clear();
      await http.runWithClient(() async {
        await openDialog(tester);

        // Class list renders with backend-reported capacity, not any
        // locally-assumed value.
        expect(find.text('Class 8'), findsOneWidget);
        expect(find.text('Form One'), findsOneWidget);
        expect(find.text('Class 1 A'), findsOneWidget);
        expect(find.textContaining('42 Weekly Slots'), findsNWidgets(2));
        expect(find.textContaining('35 Weekly Slots'), findsOneWidget);
        expect(find.text('NOT CONFIGURED'), findsNWidgets(3));

        // Open Class 8's editor — must show only Arabic/Science, never
        // Form One's History/Geography/Islamic.
        final configureButton = find
            .widgetWithText(OutlinedButton, 'Configure')
            .first;
        await tester.ensureVisible(configureButton);
        await tester.tap(configureButton);
        await tester.pumpAndSettle();
        expect(find.text('Arabic'), findsOneWidget);
        expect(find.text('Science'), findsOneWidget);
        expect(find.text('History'), findsNothing);
        expect(find.text('Weekly Capacity'), findsOneWidget);
        expect(find.text('42'), findsWidgets);

        // Fields start empty (new configuration) — null must never render
        // as 0/1/2/3.
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('class-subject-periods-10')),
              )
              .controller!
              .text,
          '',
        );

        await tester.enterText(
          find.byKey(const ValueKey('class-subject-periods-10')),
          '21',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('class-subject-periods-11')),
          '21',
        );
        await tester.pump();
        await tester.tap(find.text('Save Class Configuration'));
        await tester.pumpAndSettle();

        // Back on the class list — Class 8's configured total refreshed
        // from the backend, not a locally-guessed value.
        expect(find.text('Configure Classes'), findsNWidgets(2));
        expect(find.textContaining('Configured: 42'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => buildClient());
    },
  );

  testWidgets(
    'reopening a configured class pre-fills its saved values (only for '
    'this exact class-based endpoint, never a level fallback)',
    (tester) async {
      savedPeriods[1]!
        ..clear()
        ..addAll({10: 21, 11: 21});
      savedPeriods[2]!.clear();
      savedPeriods[3]!.clear();
      await http.runWithClient(() async {
        await openDialog(tester);
        final editButton = find.widgetWithText(OutlinedButton, 'Edit').first;
        await tester.ensureVisible(editButton);
        await tester.tap(editButton);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('class-subject-periods-10')),
              )
              .controller!
              .text,
          '21',
        );

        // Close this class and open a different one — its numbers must
        // never leak in.
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();
        final otherConfigureButton = find
            .widgetWithText(OutlinedButton, 'Configure')
            .first;
        await tester.ensureVisible(otherConfigureButton);
        await tester.tap(otherConfigureButton);
        await tester.pumpAndSettle();
        expect(find.text('History'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('class-subject-periods-20')),
              )
              .controller!
              .text,
          '',
        );
      }, () => buildClient());
    },
  );

  testWidgets(
    'Review School: not ready until every class hits exact capacity, and '
    'shows backend diagnostics for the blocking class',
    (tester) async {
      savedPeriods[1]!
        ..clear()
        ..addAll({10: 21, 11: 21});
      savedPeriods[2]!.clear();
      savedPeriods[3]!
        ..clear()
        ..addAll({30: 35});
      await http.runWithClient(() async {
        await openDialog(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Review School'));
        await tester.pumpAndSettle();

        // Form One has no configured periods yet — blocking.
        expect(find.text('Form One'), findsWidgets);
        expect(find.text('UNDER ALLOCATED'), findsWidgets);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue to Generate'),
              )
              .onPressed,
          isNull,
        );
      }, () => buildClient());
    },
  );

  testWidgets(
    'Generate becomes enabled once the school-wide preview reports every '
    'class ready, and calls the dedicated /school/generate endpoint with '
    'no level_id',
    (tester) async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/timetable-config/classes') &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'academic_year_id': 7,
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'level_id': 1,
                  'level_name': 'Sare',
                  'shift_id': 1,
                  'shift_name': 'Morning',
                  'working_day_count': 6,
                  'periods_per_day': 7,
                  'available_slots': 42,
                  'configured_periods': 42,
                  'difference': 0,
                  'status': 'READY',
                  'subject_count': 1,
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'days': ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'],
            }),
            200,
          );
        }
        if (path.endsWith('/school/preview')) {
          return http.Response(
            jsonEncode({
              'feasible': true,
              'can_generate': true,
              'ready_to_generate': true,
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'requested_periods': 42,
                  'available_slots': 42,
                  'difference': 0,
                  'status': 'COMPLETE',
                  'missing_requirements': <String>[],
                  'missing_teacher_assignments': <String>[],
                },
              ],
              'errors': <String>[],
            }),
            200,
          );
        }
        if (path.endsWith('/school/generate')) {
          return http.Response(
            jsonEncode({
              'generated_count': 1,
              'generated_rows': 42,
              'requested_rows': 42,
              'unscheduled_rows': 0,
            }),
            201,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(() async {
        await openDialog(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Review School'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'All classes are ready — the whole school can be generated with no warnings.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Continue to Generate'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Generate Whole School Timetable'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Timetable Generated'), findsOneWidget);
        expect(find.text('No FREE periods.'), findsOneWidget);

        final generateRequest = requests.firstWhere(
          (r) => r.url.path.endsWith('/school/generate'),
        );
        final body = jsonDecode(generateRequest.body) as Map<String, dynamic>;
        expect(body.containsKey('level_id'), isFalse);
        expect(body['academic_year_id'], 7);
        expect(body['replace_existing'], false);

        final previewRequest = requests.firstWhere(
          (r) => r.url.path.endsWith('/school/preview'),
        );
        final previewBody =
            jsonDecode(previewRequest.body) as Map<String, dynamic>;
        expect(previewBody.containsKey('level_id'), isFalse);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets(
    'Generate handles TIMETABLE_EXISTS by asking for confirmation before '
    'resending with replace_existing: true',
    (tester) async {
      final requests = <http.Request>[];
      var replaceConfirmed = false;
      final client = MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/timetable-config/classes') &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'academic_year_id': 7,
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'level_id': 1,
                  'level_name': 'Sare',
                  'shift_id': 1,
                  'shift_name': 'Morning',
                  'available_slots': 42,
                  'configured_periods': 42,
                  'difference': 0,
                  'status': 'READY',
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'days': ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'],
            }),
            200,
          );
        }
        if (path.endsWith('/school/preview')) {
          return http.Response(
            jsonEncode({
              'feasible': true,
              'can_generate': true,
              'ready_to_generate': true,
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'requested_periods': 42,
                  'available_slots': 42,
                  'difference': 0,
                  'status': 'COMPLETE',
                },
              ],
              'errors': <String>[],
            }),
            200,
          );
        }
        if (path.endsWith('/school/generate')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['replace_existing'] != true) {
            return http.Response(
              jsonEncode({
                'message': 'Timetable rows already exist for this academic year',
                'code': 'TIMETABLE_EXISTS',
              }),
              409,
            );
          }
          replaceConfirmed = true;
          return http.Response(
            jsonEncode({
              'generated_count': 1,
              'generated_rows': 42,
              'requested_rows': 42,
              'unscheduled_rows': 0,
            }),
            201,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(() async {
        await openDialog(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Review School'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue to Generate'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Generate Whole School Timetable'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Replace existing timetable?'), findsOneWidget);
        await tester.tap(find.text('Replace & Generate'));
        await tester.pumpAndSettle();

        expect(replaceConfirmed, isTrue);
        expect(find.text('Timetable Generated'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets(
    'a failed class-summary load is shown as a real error, never silently '
    'treated as "zero classes"',
    (tester) async {
      final failingClient = MockClient((request) async {
        if (request.url.path.endsWith('/timetable-config/classes') &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'message':
                  'SQLSTATE[42S02]: Base table or view not found: class_subject_period_requirements',
            }),
            500,
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
                  onPressed: () => showSchoolTimetableGeneratorDialog(
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

        // The real error must be visible...
        expect(
          find.textContaining('Could not load the class configuration summary.'),
          findsOneWidget,
        );
        // ...including the raw backend message for debugging...
        expect(
          find.textContaining('SQLSTATE[42S02]'),
          findsOneWidget,
        );
        // ...and it must NEVER be presented as "genuinely zero classes".
        expect(
          find.text('No classes found for this academic year yet.'),
          findsNothing,
        );
      }, () => failingClient);
    },
  );

  testWidgets(
    'removed subject disappears from the class editor immediately — never '
    'cached from a previous open',
    (tester) async {
      classSubjects[1] = [
        {'subject_id': 10, 'subject_name': 'Arabic'},
        {'subject_id': 11, 'subject_name': 'Science'},
      ];
      savedPeriods[1]!
        ..clear()
        ..addAll({10: 21, 11: 21});
      savedPeriods[2]!.clear();
      savedPeriods[3]!.clear();

      await http.runWithClient(() async {
        await openDialog(tester);
        final editButton = find.widgetWithText(OutlinedButton, 'Edit').first;
        await tester.ensureVisible(editButton);
        await tester.tap(editButton);
        await tester.pumpAndSettle();
        expect(find.text('Science'), findsOneWidget);

        // Close the class editor, then close the whole generator wizard —
        // both close icons are still on screen at this point.
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();

        // Admin removes Science from Class 8's class_subjects outside the
        // wizard (class management). The stale saved period for Science
        // must never resurface either.
        classSubjects[1] = [
          {'subject_id': 10, 'subject_name': 'Arabic'},
        ];
        savedPeriods[1] = {10: 21};

        // Reopen the generator from the same screen — a brand-new dialog
        // instance must always reload fresh from the backend.
        await reopenDialog(tester);
        final editButton2 = find.widgetWithText(OutlinedButton, 'Edit').first;
        await tester.ensureVisible(editButton2);
        await tester.tap(editButton2);
        await tester.pumpAndSettle();
        expect(find.text('Arabic'), findsOneWidget);
        expect(find.text('Science'), findsNothing);
        expect(
          find.byKey(const ValueKey('class-subject-periods-11')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }, () => buildClient());

      // Restore the shared fixture for any test that might run after this.
      classSubjects[1] = [
        {'subject_id': 10, 'subject_name': 'Arabic'},
        {'subject_id': 11, 'subject_name': 'Science'},
      ];
    },
  );

  testWidgets(
    'added subject appears in the class editor with an empty field — '
    'never a default 0/1/2/3',
    (tester) async {
      classSubjects[1] = [
        {'subject_id': 10, 'subject_name': 'Arabic'},
      ];
      savedPeriods[1] = {10: 21};
      savedPeriods[2]!.clear();
      savedPeriods[3]!.clear();

      await http.runWithClient(() async {
        await openDialog(tester);
        // Close the wizard without opening the editor this time.
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();

        // Admin adds a brand-new subject to Class 8's class_subjects.
        classSubjects[1] = [
          {'subject_id': 10, 'subject_name': 'Arabic'},
          {'subject_id': 12, 'subject_name': 'Geometry'},
        ];

        await reopenDialog(tester);
        final editButton = find.widgetWithText(OutlinedButton, 'Edit').first;
        await tester.ensureVisible(editButton);
        await tester.tap(editButton);
        await tester.pumpAndSettle();
        expect(find.text('Geometry'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('class-subject-periods-12')),
              )
              .controller!
              .text,
          '',
        );
        expect(tester.takeException(), isNull);
      }, () => buildClient());

      // Restore the shared fixture.
      classSubjects[1] = [
        {'subject_id': 10, 'subject_name': 'Arabic'},
        {'subject_id': 11, 'subject_name': 'Science'},
      ];
    },
  );

  testWidgets(
    'partial generation: warnings shown, Continue enabled, Generate Anyway '
    'confirmation required, generation still succeeds',
    (tester) async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/timetable-config/classes') &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'shift_name': 'Morning',
                  'available_slots': 42,
                  'configured_periods': 42,
                  'difference': 0,
                  'status': 'READY',
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'days': ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'],
            }),
            200,
          );
        }
        if (path.endsWith('/school/preview')) {
          // can_generate is the sole gate: even though scheduling is
          // incomplete (requested 693 / scheduled 658 / unscheduled 35)
          // and this class itself has 2 unscheduled lessons, the backend
          // still allows generation.
          return http.Response(
            jsonEncode({
              'feasible': true,
              'can_generate': true,
              'ready_to_generate': false,
              'requested_periods': 693,
              'scheduled_periods': 658,
              'unscheduled_periods': 35,
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'requested_periods': 42,
                  'available_slots': 42,
                  'difference': 0,
                  'status': 'COMPLETE',
                  'scheduled_periods': 40,
                  'unscheduled_periods': 2,
                  'reason_code': 'TEACHER_TIME_CONFLICT',
                },
              ],
              'errors': <String>[],
            }),
            200,
          );
        }
        if (path.endsWith('/school/generate')) {
          return http.Response(
            jsonEncode({
              'generated_count': 1,
              'generated_rows': 658,
              'requested_rows': 693,
              'unscheduled_rows': 35,
            }),
            201,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(() async {
        await openDialog(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Review School'));
        await tester.pumpAndSettle();

        // Warnings are visible...
        expect(find.textContaining('could not be scheduled'), findsWidgets);
        // ...but Continue to Generate stays enabled — can_generate is the
        // only gate, never the presence of warnings.
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue to Generate'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.text('Continue to Generate'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Generate Whole School Timetable'),
        );
        await tester.pumpAndSettle();

        // Warnings exist, so a confirmation is required before generating.
        expect(find.text('Generate timetable with warnings?'), findsOneWidget);
        await tester.tap(find.text('Generate Anyway'));
        await tester.pumpAndSettle();

        // A partial result is still shown as SUCCESS, never as a failure.
        expect(find.text('Timetable Generated'), findsOneWidget);
        expect(find.textContaining('could not be placed'), findsOneWidget);

        final generateRequest = requests.firstWhere(
          (r) => r.url.path.endsWith('/school/generate'),
        );
        final body = jsonDecode(generateRequest.body) as Map<String, dynamic>;
        expect(body.containsKey('level_id'), isFalse);
        expect(body['replace_existing'], false);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets(
    'complete generation (no unscheduled lessons) shows normal success with '
    'no warnings confirmation',
    (tester) async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/timetable-config/classes') &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'shift_name': 'Morning',
                  'available_slots': 42,
                  'configured_periods': 42,
                  'difference': 0,
                  'status': 'READY',
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'days': ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'],
            }),
            200,
          );
        }
        if (path.endsWith('/school/preview')) {
          return http.Response(
            jsonEncode({
              'feasible': true,
              'can_generate': true,
              'ready_to_generate': true,
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'requested_periods': 42,
                  'available_slots': 42,
                  'difference': 0,
                  'status': 'COMPLETE',
                  'scheduled_periods': 42,
                  'unscheduled_periods': 0,
                },
              ],
              'errors': <String>[],
            }),
            200,
          );
        }
        if (path.endsWith('/school/generate')) {
          return http.Response(
            jsonEncode({
              'generated_count': 1,
              'generated_rows': 42,
              'requested_rows': 42,
              'unscheduled_rows': 0,
            }),
            201,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(() async {
        await openDialog(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Review School'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue to Generate'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Generate Whole School Timetable'),
        );
        await tester.pumpAndSettle();

        // No warnings exist, so generation proceeds without a confirmation.
        expect(find.text('Generate timetable with warnings?'), findsNothing);
        expect(find.text('Timetable Generated'), findsOneWidget);
        expect(find.text('No FREE periods.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );

  testWidgets(
    'a genuine backend block (can_generate=false) disables Generate and '
    'shows the exact backend reason in a red blocking state',
    (tester) async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/timetable-config/classes') &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'shift_name': 'Morning',
                  'available_slots': 42,
                  'configured_periods': 0,
                  'difference': 42,
                  'status': 'NOT_CONFIGURED',
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/working-days')) {
          return http.Response(
            jsonEncode({
              'days': ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'],
            }),
            200,
          );
        }
        if (path.endsWith('/school/preview')) {
          return http.Response(
            jsonEncode({
              'feasible': false,
              'can_generate': false,
              'ready_to_generate': false,
              'classes': [
                {
                  'class_id': 1,
                  'class_name': 'Class 8',
                  'shift_id': 1,
                  'status': 'NOT_CONFIGURED',
                },
              ],
              'errors': ['No class has any configured periods yet.'],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(() async {
        await openDialog(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Review School'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('No class has any configured periods yet.'),
          findsWidgets,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Continue to Generate'),
              )
              .onPressed,
          isNull,
        );
      }, () => client);
    },
  );
}
