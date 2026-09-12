import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/widgets/timetable_print_dialog.dart';

http.Response _pdf() => http.Response.bytes(
  const [1, 2, 3],
  200,
  headers: const {'content-type': 'application/pdf'},
);

http.Response _year() => http.Response(
  jsonEncode({
    'academic_year': {'id': 7, 'name': '2026-2027', 'is_active': 1},
  }),
  200,
);

http.Response _years() => http.Response(
  jsonEncode({
    'academic_years': [
      {'id': 7, 'name': '2026-2027', 'is_active': 1},
    ],
  }),
  200,
);

http.Response _levels() => http.Response(
  jsonEncode({
    'levels': [
      {'id': 3, 'name': 'Sare'},
      {'id': 4, 'name': 'Dhaxe Hoose'},
    ],
  }),
  200,
);

Future<void> _openDialog(
  WidgetTester tester,
  AcademicYearsProvider provider,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTimetablePrintDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// `ElevatedButton.icon(...)` builds a private wrapper widget in this SDK,
/// not a plain `ElevatedButton`, so button lookups must go through the
/// visible label text and match any `ButtonStyleButton` ancestor instead of
/// an exact `ElevatedButton` type.
Finder _primaryButtonWithText(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

bool _isEnabled(WidgetTester tester, Finder finder) =>
    tester.widget<ButtonStyleButton>(finder).enabled;

void main() {
  testWidgets(
    'Classes by Level requires a level, sends academic_year_id + level_id, '
    'and labels the action by level name (Sare)',
    (tester) async {
      final requests = <http.Request>[];
      final provider = AcademicYearsProvider();
      await http.runWithClient(
        () async {
          await provider.ensureLoaded();
          await _openDialog(tester, provider);
          await tester.tap(find.text('Classes by Level'));
          await tester.pumpAndSettle();

          // No teacher selector and no shift selector in this mode.
          expect(find.text('Teacher *'), findsNothing);
          expect(find.text('Shift *'), findsNothing);
          expect(find.text('Morning'), findsNothing);
          expect(find.text('Afternoon'), findsNothing);
          expect(find.text('Level *'), findsOneWidget);
          expect(
            find.text(
              'Creates one A4 landscape weekly timetable containing all '
              'classes in the selected level.',
            ),
            findsOneWidget,
          );
          // Print is disabled until a level is chosen.
          expect(
            _isEnabled(tester, _primaryButtonWithText('Print Level Timetable')),
            isFalse,
          );

          await tester.tap(find.byType(DropdownButtonFormField<int?>).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sare').last);
          await tester.pumpAndSettle();
          final button = _primaryButtonWithText('Print Sare Timetable');
          expect(button, findsOneWidget);
          expect(_isEnabled(tester, button), isTrue);

          await tester.ensureVisible(find.text('Print Sare Timetable'));
          await tester.tap(find.text('Print Sare Timetable'));
          await tester.pumpAndSettle();

          final printRequest = requests.firstWhere(
            (r) => r.url.path.endsWith('/timetables/classes/print'),
          );
          expect(printRequest.url.queryParameters['academic_year_id'], '7');
          expect(printRequest.url.queryParameters['level_id'], '3');
          expect(
            printRequest.url.queryParameters.containsKey('shift'),
            isFalse,
          );
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          if (path.endsWith('/active')) return _year();
          if (path.endsWith('/academic-years')) return _years();
          if (path.endsWith('/teachers') &&
              !path.contains('/print') &&
              request.method == 'GET') {
            return http.Response(jsonEncode({'teachers': []}), 200);
          }
          if (path.endsWith('/levels')) return _levels();
          if (path.endsWith('/timetables/classes/print')) return _pdf();
          return http.Response(jsonEncode({}), 200);
        }),
      );
      provider.dispose();
    },
  );

  testWidgets(
    'Dhaxe Hoose level selection sends the matching level_id and only '
    'Dhaxe Hoose is requested (not Sare)',
    (tester) async {
      final requests = <http.Request>[];
      final provider = AcademicYearsProvider();
      await http.runWithClient(
        () async {
          await provider.ensureLoaded();
          await _openDialog(tester, provider);
          await tester.tap(find.text('Classes by Level'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(DropdownButtonFormField<int?>).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Dhaxe Hoose').last);
          await tester.pumpAndSettle();
          expect(
            _primaryButtonWithText('Print Dhaxe Hoose Timetable'),
            findsOneWidget,
          );
          await tester.ensureVisible(find.text('Print Dhaxe Hoose Timetable'));
          await tester.tap(find.text('Print Dhaxe Hoose Timetable'));
          await tester.pumpAndSettle();
          final printRequest = requests.firstWhere(
            (r) => r.url.path.endsWith('/timetables/classes/print'),
          );
          expect(printRequest.url.queryParameters['level_id'], '4');
        },
        () => MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          if (path.endsWith('/active')) return _year();
          if (path.endsWith('/academic-years')) return _years();
          if (path.endsWith('/teachers') && request.method == 'GET') {
            return http.Response(jsonEncode({'teachers': []}), 200);
          }
          if (path.endsWith('/levels')) return _levels();
          if (path.endsWith('/timetables/classes/print')) return _pdf();
          return http.Response(jsonEncode({}), 200);
        }),
      );
      provider.dispose();
    },
  );

  testWidgets(
    'an empty/no-timetable level shows a clean message instead of a raw 404',
    (tester) async {
      final provider = AcademicYearsProvider();
      await http.runWithClient(
        () async {
          await provider.ensureLoaded();
          await _openDialog(tester, provider);
          await tester.tap(find.text('Classes by Level'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(DropdownButtonFormField<int?>).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sare').last);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Print Sare Timetable'));
          await tester.tap(find.text('Print Sare Timetable'));
          await tester.pumpAndSettle();
          expect(
            find.text(
              'No timetable has been generated for Sare in the selected '
              'academic year.',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('404'), findsNothing);
        },
        () => MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/active')) return _year();
          if (path.endsWith('/academic-years')) return _years();
          if (path.endsWith('/teachers') && request.method == 'GET') {
            return http.Response(jsonEncode({'teachers': []}), 200);
          }
          if (path.endsWith('/levels')) return _levels();
          if (path.endsWith('/timetables/classes/print')) {
            // A bare 404 with no domain-specific backend message — the
            // client must fall back to its own clean, level-aware wording.
            return http.Response('', 404);
          }
          return http.Response(jsonEncode({}), 200);
        }),
      );
      provider.dispose();
    },
  );

  testWidgets(
    'One Teacher mode is unchanged: no shift/level param, existing label '
    'and request',
    (tester) async {
      final requests = <http.Request>[];
      final provider = AcademicYearsProvider();
      await http.runWithClient(
        () async {
          await provider.ensureLoaded();
          await _openDialog(tester, provider);
          // Teacher Timetable is selected by default.
          expect(find.text('Shift *'), findsNothing);
          expect(find.text('Level *'), findsNothing);
          expect(find.text('Teacher *'), findsOneWidget);
          expect(
            _isEnabled(
              tester,
              _primaryButtonWithText('Print Teacher Timetable'),
            ),
            isFalse,
          );

          await tester.tap(find.byType(DropdownButtonFormField<int?>).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Amina Ali').last);
          await tester.pumpAndSettle();
          final button = _primaryButtonWithText('Print Teacher Timetable');
          expect(button, findsOneWidget);
          expect(_isEnabled(tester, button), isTrue);

          await tester.tap(find.text('Print Teacher Timetable'));
          await tester.pumpAndSettle();
          final printRequest = requests.firstWhere(
            (r) => r.url.path.contains('/teachers/1/print'),
          );
          expect(
            printRequest.url.queryParameters.containsKey('shift_id'),
            isFalse,
          );
          expect(
            printRequest.url.queryParameters.containsKey('level_id'),
            isFalse,
          );
          expect(printRequest.url.queryParameters['academic_year_id'], '7');
        },
        () => MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          if (path.endsWith('/active')) return _year();
          if (path.endsWith('/academic-years')) return _years();
          if (path.endsWith('/teachers') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'teachers': [
                  {'id': 1, 'fullName': 'Amina Ali'},
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/levels')) return _levels();
          if (path.contains('/teachers/1/print')) return _pdf();
          return http.Response(jsonEncode({}), 200);
        }),
      );
      provider.dispose();
    },
  );
}
