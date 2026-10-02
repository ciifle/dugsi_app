import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/school_admin/pages/admin_timetable_screen.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:provider/provider.dart';

const _year = {'id': 7, 'name': '2026-2027', 'is_active': true};

Future<http.Response> _api(http.Request request) async {
  final path = request.url.path;
  Object body = <String, dynamic>{};
  if (path.endsWith('/academic-years/active')) {
    body = {'academic_year': _year};
  } else if (path.endsWith('/academic-years')) {
    body = {
      'academic_years': [_year],
    };
  } else if (path.endsWith('/levels')) {
    body = {
      'levels': [
        {'id': 3, 'name': 'Sare'},
      ],
    };
  } else if (path.endsWith('/teachers')) {
    body = {
      'teachers': [
        {'id': 1, 'fullName': 'Teacher Example'},
      ],
    };
  } else if (path.endsWith('/timetables') ||
      path.endsWith('/classes') ||
      path.endsWith('/subjects') ||
      path.endsWith('/shifts')) {
    body = {'timetables': [], 'classes': [], 'subjects': [], 'shifts': []};
  }
  return http.Response(jsonEncode(body), 200);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    testWidgets(
      'Timetable page has one Export Timetable action that opens the unified dialog at ${size.width.toInt()}px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        await http.runWithClient(() async {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => AuthProvider()),
                ChangeNotifierProvider(create: (_) => AcademicYearsProvider()),
                ChangeNotifierProvider(create: (_) => ShiftsProvider()),
              ],
              child: const MaterialApp(home: AdminTimetableScreen()),
            ),
          );
          await tester.pumpAndSettle();

          // Exactly one export entry point; the old print/PDF/Excel variants are gone.
          expect(find.text('Export Timetable'), findsOneWidget);
          for (final old in [
            'Print Timetable',
            'Export Timetable (Excel)',
            'Print PDF',
            'Download Excel',
          ]) {
            expect(find.text(old), findsNothing);
          }

          await tester.ensureVisible(find.text('Export Timetable'));
          await tester.tap(find.text('Export Timetable'));
          await tester.pumpAndSettle();

          expect(find.byType(Dialog), findsOneWidget);
          expect(find.text('Timetable Type'), findsOneWidget);
          expect(find.text('File Format'), findsOneWidget);
          expect(find.text('Class Timetable'), findsOneWidget);
          expect(find.text('Teacher Timetable'), findsOneWidget);
          // The page's already-selected academic year is carried into the dialog.
          expect(find.text('2026-2027'), findsWidgets);
          expect(tester.takeException(), isNull);
        }, () => MockClient(_api));
      },
    );
  }
}
