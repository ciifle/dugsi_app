import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/pages/admin_class_details_screen.dart';

Map<String, dynamic> _classResponse(int studentCount) => {
  'class': {
    'id': 1,
    'name': 'Class 1 B',
    'studentCount': studentCount,
    'shift': {'id': 1, 'name': 'Morning'},
    'students': [
      for (var i = 1; i <= studentCount; i++)
        {'id': i, 'studentName': 'Student $i', 'emisNumber': 'E$i'},
    ],
  },
};

Future<void> _pumpClassDetails(
  WidgetTester tester, {
  required int studentCount,
  required double width,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final provider = AcademicYearsProvider();
  await http.runWithClient(
    () async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: AdminClassDetailsScreen(classId: 1, className: 'Class 1 B'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    },
    () => MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/active')) {
        return http.Response(
          jsonEncode({
            'academic_year': {'id': 7, 'name': '2026-2027', 'is_active': 1},
          }),
          200,
        );
      }
      if (path.endsWith('/academic-years')) {
        return http.Response(
          jsonEncode({
            'academic_years': [
              {'id': 7, 'name': '2026-2027', 'is_active': 1},
            ],
          }),
          200,
        );
      }
      if (path.contains('/classes/')) {
        return http.Response(jsonEncode(_classResponse(studentCount)), 200);
      }
      return http.Response(jsonEncode({}), 200);
    }),
  );
}

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets(
      'long class list scrolls as one continuous page at ${width}px, no overflow, all students reachable',
      (tester) async {
        await _pumpClassDetails(tester, studentCount: 60, width: width);

        // Page opens at the top: header/actions are visible immediately.
        expect(find.text('Class 1 B'), findsOneWidget);
        expect(find.text('View Rankings'), findsOneWidget);
        expect(find.text('Add student'), findsOneWidget);
        expect(find.text('Manage subjects'), findsOneWidget);
        expect(find.text('Print Class List'), findsOneWidget);
        expect(find.text('Print Class Marks'), findsOneWidget);
        expect(find.text('Move / Merge Students'), findsOneWidget);
        expect(find.text('60 students'), findsOneWidget);
        expect(find.text('Student 1'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // A single continuous scroll (the CustomScrollView) reaches the
        // last student — no nested/competing scroll region blocks it.
        await tester.scrollUntilVisible(
          find.text('Student 60'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Student 60'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty class shows a centered message without a stray inner scroll crash', (
    tester,
  ) async {
    await _pumpClassDetails(tester, studentCount: 0, width: 390);
    expect(find.text('View Rankings'), findsOneWidget);
    expect(find.textContaining('No students enrolled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
