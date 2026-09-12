import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/admin_deletion_service.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';
import 'package:kobac/school_admin/pages/academic_years_page.dart';
import 'package:kobac/school_admin/widgets/dependency_delete_dialog.dart';

Map<String, dynamic> previewJson(
  String kind, {
  bool active = false,
  bool empty = false,
}) => {
  'can_delete': true,
  'requires_confirmation': true,
  kind: {
    'id': 2,
    'name': kind == 'class' ? 'Class 1 A' : '2026-2027',
    if (kind == 'academic_year') 'is_active': active ? 1 : 0,
  },
  'impact': empty
      ? <String, int>{}
      : kind == 'class'
      ? {
          'student_enrollments': 35,
          'class_subjects': 5,
          'timetables': 42,
          'student_movements_from': 4,
        }
      : kind == 'level'
      ? {'classes': 3, 'level_subject_periods': 13}
      : {'exams': 12, 'marks': 800, 'teacher_day_offs': 4},
  'warnings': [],
};

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  test(
    'parser preserves actual counts, unknown categories, and distinguishes retained master records',
    () {
      final raw = previewJson('academic_year');
      raw['impact'] = Map<String, dynamic>.from(raw['impact'] as Map)
        ..addAll({'custom_year_records': 9, 'students': 6});
      final preview = DependencyDeletePreview.fromJson(
        raw,
        DeleteItemKind.academicYear,
        2,
      );
      expect(preview.impact['Custom Year Records'], 9);
      expect(preview.impact.containsKey('Students'), isFalse);
      expect(preview.retainedImpact['Students'], 6);
      expect(preview.impact.containsKey('Student Enrollments'), isFalse);
      expect(
        () => DependencyDeletePreview.fromJson(
          {'impact': {}},
          DeleteItemKind.schoolClass,
          2,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'confirmed requests match controller query flags and carry no JSON confirmation body',
    () async {
      final requests = <http.Request>[];
      await http.runWithClient(
        () async {
          final service = AdminDeletionService();
          for (final kind in DeleteItemKind.values) {
            final preview = await service.preview(kind, 2);
            await expectLater(
              service.confirmedDelete(kind, preview, confirmed: false),
              throwsA(isA<AdminDeleteException>()),
            );
            if (kind == DeleteItemKind.academicYear) {
              await expectLater(
                service.confirmedDelete(kind, preview, confirmed: true),
                throwsA(isA<AdminDeleteException>()),
              );
            }
            await service.confirmedDelete(
              kind,
              preview,
              confirmed: true,
              confirmActive: true,
              classChoice: LevelDeleteChoice.keepClasses,
            );
            if (kind == DeleteItemKind.level) {
              await service.confirmedDelete(
                kind,
                preview,
                confirmed: true,
                classChoice: LevelDeleteChoice.deleteClasses,
              );
            }
          }
        },
        () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            final kind = request.url.path.contains('/academic-years/')
                ? 'academic_year'
                : request.url.path.contains('/levels/')
                ? 'level'
                : 'class';
            expect(request.url.path.endsWith('/2/delete-preview'), isTrue);
            expect(request.url.query, isEmpty);
            return jsonResponse(previewJson(kind, active: true));
          }
          expect(request.body, isEmpty);
          return jsonResponse({'deleted': true});
        }),
      );
      final deletes = requests.where((r) => r.method == 'DELETE').toList();
      expect(deletes, hasLength(4));
      expect(deletes[0].url.path, '/api/school-admin/classes/2');
      expect(deletes[0].url.queryParameters, {'force': 'true'});
      expect(deletes[1].url.queryParameters, {
        'force': 'true',
        'class_action': 'detach',
      });
      expect(deletes[2].url.queryParameters, {
        'force': 'true',
        'class_action': 'delete',
      });
      expect(deletes[3].url.path, '/api/school-admin/academic-years/2');
      expect(deletes[3].url.queryParameters, {
        'force': 'true',
        'confirm_active': 'true',
      });
    },
  );

  for (final empty in [false, true]) {
    testWidgets(
      'class page previews then confirms and refreshes, empty=$empty',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var deleted = false;
        final calls = <String>[];
        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              const MaterialApp(home: AdminClassesPage()),
            );
            await tester.pumpAndSettle();
            expect(find.text('Class 1 A'), findsOneWidget);
            final button = find.text('Delete').evaluate().isNotEmpty
                ? find.text('Delete')
                : find.byTooltip('Delete');
            await tester.ensureVisible(button.first);
            await tester.tap(button.first);
            await tester.pumpAndSettle();
            expect(find.text('Delete Class?'), findsOneWidget);
            expect(deleted, isFalse);
            if (!empty) {
              expect(find.text('Student Enrollments'), findsOneWidget);
              expect(find.text('35'), findsOneWidget);
            }
            await tester.tap(find.text('Delete Class'));
            await tester.pumpAndSettle();
            expect(deleted, isTrue);
            expect(find.text('Class 1 A'), findsNothing);
            expect(find.text('Class deleted successfully.'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
          () => MockClient((request) async {
            calls.add('${request.method} ${request.url.path}');
            if (request.url.path.endsWith('/delete-preview'))
              return jsonResponse(previewJson('class', empty: empty));
            if (request.method == 'DELETE') {
              expect(
                calls[calls.length - 2],
                'GET /api/school-admin/classes/2/delete-preview',
              );
              expect(request.url.queryParameters, {'force': 'true'});
              deleted = true;
              return jsonResponse({
                'deleted': true,
                'message': 'Class deleted',
              });
            }
            return jsonResponse({
              'classes': deleted
                  ? []
                  : [
                      {'id': 2, 'name': 'Class 1 A', 'studentCount': 35},
                    ],
            });
          }),
        );
      },
    );
  }

  for (final active in [false, true]) {
    for (final width in [320.0, 1200.0]) {
      testWidgets(
        'year card exposes Delete and sends exact confirmation, active=$active width=$width',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          var deleted = false;
          var previews = 0;
          final provider = AcademicYearsProvider();
          await http.runWithClient(
            () async {
              await provider.ensureLoaded();
              await tester.pumpWidget(
                ChangeNotifierProvider.value(
                  value: provider,
                  child: MaterialApp(
                    home: Scaffold(
                      body: AcademicYearsPage(embedBodyOnly: width > 600),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(find.text('Delete'), findsOneWidget);
              expect(
                find.text('Activate'),
                active ? findsNothing : findsOneWidget,
              );
              await tester.tap(find.text('Delete'));
              await tester.pumpAndSettle();
              expect(previews, 1);
              expect(deleted, isFalse);
              expect(find.text('Delete Academic Year?'), findsOneWidget);
              expect(
                find.text('ACTIVE ACADEMIC YEAR'),
                active ? findsOneWidget : findsNothing,
              );
              expect(
                find.text('The following will NOT be deleted:'),
                findsOneWidget,
              );
              final finalButton = find.widgetWithText(
                FilledButton,
                'Delete Academic Year',
              );
              expect(
                tester.widget<FilledButton>(finalButton).onPressed,
                isNull,
              );
              final checkboxes = find
                  .byType(CheckboxListTile)
                  .evaluate()
                  .toList();
              for (final checkbox in checkboxes) {
                final finder = find.byWidget(checkbox.widget);
                await tester.ensureVisible(finder);
                await tester.tap(finder);
                await tester.pump();
              }
              expect(tester.takeException(), isNull);
              await tester.tap(finalButton);
              await tester.pumpAndSettle();
              expect(deleted, isTrue);
              expect(provider.years, isEmpty);
              expect(provider.activeYear, isNull);
              expect(provider.retainedYearId(2), isNull);
              expect(find.text('2026-2027'), findsNothing);
              expect(
                find.text('Academic year deleted successfully.'),
                findsOneWidget,
              );
            },
            () => MockClient((request) async {
              if (request.url.path.endsWith('/delete-preview')) {
                previews++;
                return jsonResponse(
                  previewJson('academic_year', active: active, empty: !active),
                );
              }
              if (request.method == 'DELETE') {
                expect(request.url.path, '/api/school-admin/academic-years/2');
                expect(request.url.queryParameters, {
                  'force': 'true',
                  if (active) 'confirm_active': 'true',
                });
                expect(request.body, isEmpty);
                deleted = true;
                return jsonResponse({
                  'deleted': true,
                  'active_year_remaining': false,
                });
              }
              final year = {
                'id': 2,
                'name': '2026-2027',
                'is_active': active ? 1 : 0,
              };
              if (request.url.path.endsWith('/active'))
                return active && !deleted
                    ? jsonResponse({'academic_year': year})
                    : jsonResponse({'message': 'No active year'}, 404);
              return jsonResponse({
                'academic_years': deleted ? [] : [year],
              });
            }),
          );
          provider.dispose();
        },
      );
    }
  }

  testWidgets(
    'active-state conflict updates preview and requires fresh approval without automatic retry',
    (tester) async {
      var deletes = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showAdminDeletionFlow(
                      context,
                      kind: DeleteItemKind.academicYear,
                      id: 2,
                      name: '2026-2027',
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(CheckboxListTile));
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pump();
          await tester.tap(find.text('Delete Academic Year'));
          await tester.pumpAndSettle();
          expect(deletes, 1);
          expect(find.text('ACTIVE ACADEMIC YEAR'), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Delete Academic Year'),
                )
                .onPressed,
            isNull,
          );
          for (final checkbox
              in find.byType(CheckboxListTile).evaluate().toList()) {
            final finder = find.byWidget(checkbox.widget);
            await tester.ensureVisible(finder);
            await tester.tap(finder);
            await tester.pump();
          }
          await tester.tap(find.text('Delete Academic Year'));
          await tester.pumpAndSettle();
          expect(deletes, 2);
        },
        () => MockClient((request) async {
          if (request.method == 'GET')
            return jsonResponse(previewJson('academic_year'));
          deletes++;
          if (deletes == 1)
            return jsonResponse({
              ...previewJson('academic_year', active: true),
              'requires_active_confirmation': true,
              'message':
                  'Deleting the active academic year requires confirm_active=true',
            }, 409);
          expect(request.url.queryParameters, {
            'force': 'true',
            'confirm_active': 'true',
          });
          return jsonResponse({'deleted': true});
        }),
      );
    },
  );

  test(
    'in-flight year responses cannot resurrect a deleted year or invent an active replacement',
    () async {
      final response = Completer<http.Response>();
      final provider = AcademicYearsProvider();
      await http.runWithClient(
        () async {
          final refresh = provider.refresh();
          provider.removeDeletedYear(2);
          response.complete(
            jsonResponse({
              'academic_years': [
                {'id': 2, 'name': 'Deleted', 'is_active': 1},
              ],
            }),
          );
          await refresh;
          expect(provider.years, isEmpty);
          expect(provider.activeYear, isNull);
          expect(provider.retainedYearId(2), isNull);
          expect(provider.retainedYearId(8), 8);
        },
        () => MockClient(
          (request) async => request.url.path.endsWith('/active')
              ? jsonResponse({
                  'academic_year': {'id': 2, 'name': 'Deleted', 'is_active': 1},
                })
              : response.future,
        ),
      );
      provider.dispose();
    },
  );

  test(
    'empty level delete sends class_action=detach without requiring a UI choice',
    () async {
      final requests = <http.Request>[];
      await http.runWithClient(
        () async {
          final service = AdminDeletionService();
          final preview = await service.preview(DeleteItemKind.level, 4);
          expect(preview.containedClasses, 0);
          await service.confirmedDelete(
            DeleteItemKind.level,
            preview,
            confirmed: true,
          );
        },
        () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return jsonResponse({
              'can_delete': true,
              'requires_confirmation': true,
              'level': {'id': 4, 'name': 'Empty Level'},
              'impact': {'classes': 0},
            });
          }
          return jsonResponse({'deleted': true});
        }),
      );
      final delete = requests.singleWhere((r) => r.method == 'DELETE');
      expect(delete.url.queryParameters, {
        'force': 'true',
        'class_action': 'detach',
      });
    },
  );

  test(
    'an empty level stays deletable even when can_delete is false and unrelated '
    'config (e.g. level_subject_period_requirements) is nonzero',
    () async {
      final requests = <http.Request>[];
      late DependencyDeletePreview preview;
      await http.runWithClient(
        () async {
          final service = AdminDeletionService();
          preview = await service.preview(DeleteItemKind.level, 5);
          expect(preview.containedClasses, 0);
          expect(preview.requiresClassAction, isFalse);
          // The real-world case that motivated this fix: can_delete:false,
          // but requires_confirmation:true (this dialog IS the
          // confirmation) and zero classes — must still be deletable.
          expect(preview.canDelete, isTrue);
          await service.confirmedDelete(
            DeleteItemKind.level,
            preview,
            confirmed: true,
          );
        },
        () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return jsonResponse({
              'can_delete': false,
              'requires_confirmation': true,
              'level': {'id': 5, 'name': 'hyyjyyj'},
              'impact': {'classes': 0, 'level_subject_period_requirements': 4},
            });
          }
          return jsonResponse({'deleted': true});
        }),
      );
      final delete = requests.singleWhere((r) => r.method == 'DELETE');
      expect(delete.url.queryParameters, {
        'force': 'true',
        'class_action': 'detach',
      });
    },
  );
}
