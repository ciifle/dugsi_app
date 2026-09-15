import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:kobac/school_admin/widgets/timetable_generator_dialog.dart';
import 'package:provider/provider.dart';

/// Regression coverage for the shift-specific working-days contract:
/// GET/PUT /api/school-admin/timetable-config/working-days now require
/// shift_id, and Morning/Afternoon must be fully isolated — saving one must
/// never overwrite, leak into, or be confused with the other.
void main() {
  testWidgets('Morning and Afternoon working days load and save independently, '
      'with no stale data leaking between them', (tester) async {
    final requests = <http.Request>[];
    // Independent, per-shift backend-side storage (simulating the real
    // isolated records) — the test asserts saving one never touches
    // the other's stored value.
    final storedByShift = <int, List<String>>{
      1: ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'], // Morning
      2: ['SAT', 'SUN', 'MON', 'TUE', 'WED'], // Afternoon
    };
    final client = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (path.endsWith('/academic-years')) {
        return http.Response(
          jsonEncode({
            'academic_years': [
              {'id': 2, 'name': '2026-2027', 'is_active': 1},
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
              {'id': 2, 'name': 'Afternoon'},
            ],
          }),
          200,
        );
      }
      if (path.endsWith('/working-days')) {
        if (request.method == 'GET') {
          final shiftId = int.parse(request.url.queryParameters['shift_id']!);
          expect(request.url.queryParameters['academic_year_id'], '2');
          return http.Response(
            jsonEncode({
              'academic_year_id': 2,
              'shift_id': shiftId,
              'shift_name': shiftId == 1 ? 'Morning' : 'Afternoon',
              'days': storedByShift[shiftId],
            }),
            200,
          );
        }
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['academic_year_id'], 2);
          final shiftId = body['shift_id'] as int;
          final days = (body['days'] as List).cast<String>();
          storedByShift[shiftId] = days;
          return http.Response(
            jsonEncode({
              'academic_year_id': 2,
              'shift_id': shiftId,
              'shift_name': shiftId == 1 ? 'Morning' : 'Afternoon',
              'days': days,
            }),
            200,
          );
        }
      }
      if (path.endsWith('/levels')) {
        return http.Response(jsonEncode({'levels': []}), 200);
      }
      return http.Response(jsonEncode({}), 200);
    });

    await http.runWithClient(() async {
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
                      AcademicYear(id: 2, name: '2026-2027', isActive: true),
                    ],
                    initialAcademicYearId: 2,
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

      // --- Select Morning: expect its exact GET and exact chip state ---
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning').last);
      await tester.pumpAndSettle();

      final morningGet = requests.lastWhere(
        (r) => r.method == 'GET' && r.url.path.endsWith('/working-days'),
      );
      expect(morningGet.url.queryParameters, {
        'academic_year_id': '2',
        'shift_id': '1',
      });
      expect(find.widgetWithText(FilterChip, 'SAT'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'SAT'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'FRI'))
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'THU'))
            .selected,
        isTrue,
      );

      // Deselect THU for Morning and save — must send shift_id=1.
      await tester.tap(find.widgetWithText(FilterChip, 'THU'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Working Days'));
      await tester.pumpAndSettle();

      final morningPut = requests.lastWhere(
        (r) => r.method == 'PUT' && r.url.path.endsWith('/working-days'),
      );
      final morningBody = jsonDecode(morningPut.body) as Map<String, dynamic>;
      expect(morningBody['academic_year_id'], 2);
      expect(morningBody['shift_id'], 1);
      expect((morningBody['days'] as List).cast<String>().toSet(), {
        'SAT',
        'SUN',
        'MON',
        'TUE',
        'WED',
      });
      // The isolated backend-side store for Afternoon must be untouched.
      expect(storedByShift[2], ['SAT', 'SUN', 'MON', 'TUE', 'WED']);

      // Go back to Working Days step to switch shifts.
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // --- Switch to Afternoon: must reload, never show Morning's chips ---
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Afternoon').last);
      await tester.pumpAndSettle();

      final afternoonGet = requests.lastWhere(
        (r) => r.method == 'GET' && r.url.path.endsWith('/working-days'),
      );
      expect(afternoonGet.url.queryParameters, {
        'academic_year_id': '2',
        'shift_id': '2',
      });
      // Afternoon's own (unmodified) days — THU/FRI both unselected,
      // proving Morning's edit never leaked into Afternoon's state.
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'THU'))
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'FRI'))
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'WED'))
            .selected,
        isTrue,
      );

      // Save Afternoon unchanged — must never touch Morning's stored value.
      await tester.tap(find.text('Save Working Days'));
      await tester.pumpAndSettle();
      final afternoonPut = requests.lastWhere(
        (r) => r.method == 'PUT' && r.url.path.endsWith('/working-days'),
      );
      expect(jsonDecode(afternoonPut.body)['shift_id'], 2);
      expect(storedByShift[1]!.toSet(), {'SAT', 'SUN', 'MON', 'TUE', 'WED'});

      // --- Return to Morning: its edited config must have persisted ---
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'THU'))
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'WED'))
            .selected,
        isTrue,
      );

      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
