import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/school_admin/pages/exam_hall_management_pages.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';

void main() {
  group('ExamHallService level contract', () {
    test('createLevel POSTs only the documented name field', () async {
      http.Request? sent;
      await http.runWithClient(
        () async {
          final result = await ExamHallService().createLevel('Primary');
          expect(result, isA<HallSuccess<SchoolLevel>>());
        },
        () => MockClient((request) async {
          sent = request;
          expect(request.method, 'POST');
          expect(request.url.path, endsWith('/api/school-admin/levels'));
          expect(jsonDecode(request.body), {'name': 'Primary'});
          return http.Response(
            jsonEncode({
              'level': {'id': 9, 'name': 'Primary'},
            }),
            201,
          );
        }),
      );
      expect(sent, isNotNull);
    });

    test('assignClasses PATCHes the bulk level-classes endpoint', () async {
      await http.runWithClient(
        () async {
          final result = await ExamHallService().assignClasses(3, [10, 11]);
          expect(result, isA<HallSuccess<bool>>());
        },
        () => MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(
            request.url.path,
            endsWith('/api/school-admin/levels/3/classes'),
          );
          expect(jsonDecode(request.body), {
            'class_ids': [10, 11],
          });
          return http.Response(jsonEncode({}), 200);
        }),
      );
    });

    test('assignClassLevel PATCHes the single-class level endpoint', () async {
      await http.runWithClient(
        () async {
          final result = await ExamHallService().assignClassLevel(10, 3);
          expect(result, isA<HallSuccess<bool>>());
        },
        () => MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(
            request.url.path,
            endsWith('/api/school-admin/classes/10/level'),
          );
          expect(jsonDecode(request.body), {'level_id': 3});
          return http.Response(jsonEncode({}), 200);
        }),
      );
    });
  });

  testWidgets(
    'Levels page: no dead Edit action on existing levels; Assign Classes and Delete work',
    (tester) async {
      final requests = <http.Request>[];
      var assigned = false;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: LevelsPage())),
          );
          await tester.pumpAndSettle();
          expect(find.text('Hoose'), findsOneWidget);
          expect(find.text('5 Classes'), findsOneWidget);
          // The per-card Edit action must not exist — there is no backend
          // route to update an existing level's metadata.
          expect(find.text('Edit'), findsNothing);
          expect(find.text('Assign Classes'), findsOneWidget);
          expect(find.text('Delete'), findsOneWidget);

          await tester.tap(find.text('Assign Classes'));
          await tester.pumpAndSettle();
          expect(find.text('Assign Classes · Hoose'), findsOneWidget);
          // Class 1 A is already assigned to Hoose and must be preselected.
          final preselected = tester.widget<CheckboxListTile>(
            find.ancestor(
              of: find.text('Class 1 A'),
              matching: find.byType(CheckboxListTile),
            ),
          );
          expect(preselected.value, isTrue);
          final notSelected = tester.widget<CheckboxListTile>(
            find.ancestor(
              of: find.text('Class 2 A'),
              matching: find.byType(CheckboxListTile),
            ),
          );
          expect(notSelected.value, isFalse);

          await tester.tap(find.text('Class 2 A'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Assign Classes'));
          await tester.pumpAndSettle();
          expect(find.text('Classes assigned.'), findsOneWidget);
          expect(assigned, isTrue);
        },
        () => MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          if (path.endsWith('/levels') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'levels': [
                  {
                    'id': 1,
                    'name': 'Hoose',
                    'sort_order': 1,
                    'is_active': true,
                    'class_count': 5,
                  },
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/classes') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'classes': [
                  {'id': 1, 'name': 'Class 1 A', 'level_id': 1},
                  {'id': 2, 'name': 'Class 2 A', 'level_id': null},
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/levels/1/classes') && request.method == 'PATCH') {
            assigned = true;
            expect(jsonDecode(request.body), {
              'class_ids': [1, 2],
            });
            return http.Response(jsonEncode({}), 200);
          }
          return http.Response(jsonEncode({}), 200);
        }),
      );
    },
  );

  testWidgets('Levels page Add Level dialog sends only the name field', (
    tester,
  ) async {
    var created = false;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: LevelsPage())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Level'));
        await tester.pumpAndSettle();
        expect(find.text('Sort Order'), findsNothing);
        expect(find.text('Active status'), findsNothing);
        await tester.enterText(find.byType(TextField), 'Sare');
        await tester.tap(find.text('Create Level'));
        await tester.pumpAndSettle();
        expect(created, isTrue);
        expect(find.text('Level created.'), findsOneWidget);
      },
      () => MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/levels') && request.method == 'GET') {
          return http.Response(jsonEncode({'levels': []}), 200);
        }
        if (path.endsWith('/levels') && request.method == 'POST') {
          created = true;
          expect(jsonDecode(request.body), {'name': 'Sare'});
          return http.Response(
            jsonEncode({
              'level': {'id': 2, 'name': 'Sare'},
            }),
            201,
          );
        }
        return http.Response(jsonEncode({}), 200);
      }),
    );
  });

  testWidgets(
    'Edit Class dialog preselects the current level and updates it via the single-class endpoint',
    (tester) async {
      var levelUpdated = false;
      var nameUpdated = false;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: AdminClassesPage())),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.edit_outlined).first);
          await tester.pumpAndSettle();
          expect(find.text('Edit Class'), findsOneWidget);
          expect(find.text('Hoose'), findsOneWidget);

          await tester.tap(find.byType(DropdownButtonFormField<int?>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Dhexe').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          expect(nameUpdated, isTrue);
          expect(levelUpdated, isTrue);
        },
        () => MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/classes') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'classes': [
                  {
                    'id': 1,
                    'name': 'Class 1 A',
                    'level_id': 1,
                    'level_name': 'Hoose',
                  },
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/levels') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'levels': [
                  {'id': 1, 'name': 'Hoose'},
                  {'id': 2, 'name': 'Dhexe'},
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/classes/1') && request.method == 'PATCH') {
            nameUpdated = true;
            return http.Response(jsonEncode({}), 200);
          }
          if (path.endsWith('/classes/1/level') && request.method == 'PATCH') {
            levelUpdated = true;
            expect(jsonDecode(request.body), {'level_id': 2});
            return http.Response(jsonEncode({}), 200);
          }
          return http.Response(jsonEncode({}), 200);
        }),
      );
    },
  );
}
