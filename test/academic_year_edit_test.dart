import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/pages/academic_years_page.dart';

Future<void> _pumpYearsPage(
  WidgetTester tester,
  AcademicYearsProvider provider,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(body: AcademicYearsPage(embedBodyOnly: true)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('service.update PATCHes only name/start_date/end_date', () async {
    await http.runWithClient(
      () async {
        final result = await AcademicYearsService().update(
          id: 7,
          name: '2026-2027',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2027, 6, 30),
        );
        expect(result, isA<AcademicYearSuccess<AcademicYear>>());
      },
      () => MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.path,
          endsWith('/api/school-admin/academic-years/7'),
        );
        expect(jsonDecode(request.body), {
          'name': '2026-2027',
          'start_date': '2026-09-01',
          'end_date': '2027-06-30',
        });
        return http.Response(
          jsonEncode({
            'academic_year': {
              'id': 7,
              'name': '2026-2027',
              'start_date': '2026-09-01',
              'end_date': '2027-06-30',
              'is_active': 1,
            },
          }),
          200,
        );
      }),
    );
  });

  test('raw backend diagnostics never surface as the update error', () async {
    await http.runWithClient(
      () async {
        final result = await AcademicYearsService().update(
          id: 7,
          name: '2026-2027',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2027, 6, 30),
        );
        expect(result, isA<AcademicYearError>());
        expect(
          (result as AcademicYearError).message,
          'Could not update academic year.',
        );
      },
      () => MockClient(
        (request) async => http.Response(
          jsonEncode({
            'message': 'Cannot update: FOREIGN KEY CONSTRAINT fails',
          }),
          500,
        ),
      ),
    );
  });

  for (final active in [false, true]) {
    testWidgets(
      'editing a year prefills current values, PATCHes, and keeps active state unchanged (active=$active)',
      (tester) async {
        var updated = false;
        var updatedBody = <String, dynamic>{};
        final provider = AcademicYearsProvider();
        await http.runWithClient(
          () async {
            await provider.ensureLoaded();
            await _pumpYearsPage(tester, provider);
            expect(find.text('2026-2027'), findsOneWidget);

            await tester.tap(find.text('Edit'));
            await tester.pumpAndSettle();
            expect(find.text('Edit Academic Year'), findsOneWidget);
            expect(
              find.text('Update the academic year name and dates.'),
              findsOneWidget,
            );
            // Prefilled with the current name and dates.
            expect(
              tester
                  .widget<TextFormField>(find.byType(TextFormField))
                  .controller!
                  .text,
              '2026-2027',
            );
            expect(find.text('01 Sep 2026'), findsOneWidget);
            expect(find.text('30 Jun 2027'), findsOneWidget);

            await tester.enterText(
              find.byType(TextFormField),
              '2026-2027 (Revised)',
            );
            await tester.tap(find.text('Save Changes'));
            await tester.pumpAndSettle();

            expect(updated, isTrue);
            expect(updatedBody['name'], '2026-2027 (Revised)');
            expect(
              find.text('Academic year updated successfully.'),
              findsOneWidget,
            );
            // The card reflects the new name and the same active state.
            expect(find.text('2026-2027 (Revised)'), findsOneWidget);
            expect(find.text(active ? 'Active' : 'Inactive'), findsOneWidget);
            expect(provider.years.single.id, 7);
          },
          () => MockClient((request) async {
            final path = request.url.path;
            final year = {
              'id': 7,
              'name': updated ? '2026-2027 (Revised)' : '2026-2027',
              'start_date': '2026-09-01',
              'end_date': '2027-06-30',
              'is_active': active ? 1 : 0,
            };
            if (request.method == 'PATCH' &&
                path.endsWith('/academic-years/7')) {
              updated = true;
              updatedBody = jsonDecode(request.body) as Map<String, dynamic>;
              // is_active must never be sent — the backend must not be told
              // to change activation state as a side effect of editing.
              expect(updatedBody.containsKey('is_active'), isFalse);
              return http.Response(jsonEncode({'academic_year': year}), 200);
            }
            if (path.endsWith('/active')) {
              return active
                  ? http.Response(jsonEncode({'academic_year': year}), 200)
                  : http.Response(jsonEncode({'message': 'none'}), 404);
            }
            return http.Response(
              jsonEncode({
                'academic_years': [year],
              }),
              200,
            );
          }),
        );
        provider.dispose();
      },
    );
  }

  testWidgets(
    'name is required to save an edit, matching the create-dialog validator',
    (tester) async {
      var patched = false;
      final provider = AcademicYearsProvider();
      await http.runWithClient(
        () async {
          await provider.ensureLoaded();
          await _pumpYearsPage(tester, provider);
          await tester.tap(find.text('Edit'));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(TextFormField), '   ');
          await tester.tap(find.text('Save Changes'));
          await tester.pumpAndSettle();

          expect(find.text('Name is required'), findsOneWidget);
          expect(patched, isFalse);
          // The dialog stays open so the admin can fix it.
          expect(find.text('Edit Academic Year'), findsOneWidget);
        },
        () => MockClient((request) async {
          if (request.method == 'PATCH') patched = true;
          final year = {
            'id': 7,
            'name': '2026-2027',
            'start_date': '2026-09-01',
            'end_date': '2027-06-30',
            'is_active': 1,
          };
          if (request.url.path.endsWith('/active')) {
            return http.Response(jsonEncode({'academic_year': year}), 200);
          }
          return http.Response(
            jsonEncode({
              'academic_years': [year],
            }),
            200,
          );
        }),
      );
      provider.dispose();
    },
  );
}
