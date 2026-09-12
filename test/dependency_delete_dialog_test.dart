import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/school_admin/widgets/dependency_delete_dialog.dart';
import 'package:kobac/services/delete_error_message.dart';

Future<void> openDialog(
  WidgetTester tester, {
  required DeleteItemKind kind,
  required Future<DependencyDeletePreview> Function() preview,
  required Future<String?> Function(LevelDeleteChoice?) delete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDependencyDeleteDialog(
              context,
              kind: kind,
              name: 'Test item',
              loadPreview: preview,
              confirmedDelete: delete,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
}

void main() {
  test(
    'existing class and level delete services sanitize database errors',
    () async {
      await http.runWithClient(
        () async {
          final schoolClass =
              await ClassesService().deleteClass(3) as ClassError;
          final level = await ExamHallService().deleteLevel(2) as HallError;
          expect(schoolClass.message, deleteFailureMessage);
          expect(level.message, deleteFailureMessage);
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message':
                  'Cannot delete or update a parent row: FOREIGN KEY CONSTRAINT',
            }),
            409,
          ),
        ),
      );
    },
  );
  test('database diagnostics never reach delete UI', () {
    for (final error in [
      'Cannot delete or update a parent row',
      'FOREIGN KEY',
      'CONSTRAINT fk_example',
      'SQL syntax error',
      'Unknown column foo',
      'ER_ROW_IS_REFERENCED_2',
      '<html>500</html>',
      'SequelizeDatabaseError',
    ]) {
      expect(safeDeleteError(error), deleteFailureMessage);
    }
    expect(
      safeDeleteError('Preview has changed. Please review again.'),
      'Preview has changed. Please review again.',
    );
  });

  testWidgets(
    'class waits for preview, displays supplied counts and prevents double delete',
    (tester) async {
      final preview = Completer<DependencyDeletePreview>();
      final deletion = Completer<String?>();
      var calls = 0;
      await openDialog(
        tester,
        kind: DeleteItemKind.schoolClass,
        preview: () => preview.future,
        delete: (_) {
          calls++;
          return deletion.future;
        },
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(calls, 0);
      preview.complete(
        const DependencyDeletePreview(
          impact: {'Student Enrollments': 35, 'Timetable Entries': 42},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('35'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Teacher Assignments'), findsNothing);
      await tester.tap(find.text('Delete Class'));
      await tester.pump();
      expect(calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      deletion.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Delete Class?'), findsNothing);
    },
  );

  testWidgets('level defaults to keeping classes', (tester) async {
    LevelDeleteChoice? selected;
    await openDialog(
      tester,
      kind: DeleteItemKind.level,
      preview: () async => const DependencyDeletePreview(
        impact: {'Classes': 3},
        containedClasses: 3,
        requiresClassAction: true,
        levelChoices: {
          LevelDeleteChoice.keepClasses,
          LevelDeleteChoice.deleteClasses,
        },
      ),
      delete: (choice) async {
        selected = choice;
        return null;
      },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Level'));
    await tester.pumpAndSettle();
    expect(selected, LevelDeleteChoice.keepClasses);
  });

  testWidgets(
    'an empty level (0 classes) never asks for a class-action choice and deletes immediately',
    (tester) async {
      LevelDeleteChoice? selected;
      var calls = 0;
      await openDialog(
        tester,
        kind: DeleteItemKind.level,
        preview: () async =>
            const DependencyDeletePreview(impact: {}, containedClasses: 0),
        delete: (choice) async {
          calls++;
          selected = choice;
          return null;
        },
      );
      await tester.pumpAndSettle();
      // No "what should happen to classes" prompt for an empty level.
      expect(find.text('Keep Classes'), findsNothing);
      expect(find.text('Delete Classes Too'), findsNothing);
      // Delete is already enabled — no extra choice required.
      final deleteButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(deleteButton.onPressed, isNotNull);
      await tester.tap(find.text('Delete Level'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(selected, isNull);
      expect(find.text('Delete Level?'), findsNothing);
    },
  );

  testWidgets(
    'deleting level classes requires a second confirmation and Back returns safely',
    (tester) async {
      var calls = 0;
      LevelDeleteChoice? selected;
      await openDialog(
        tester,
        kind: DeleteItemKind.level,
        preview: () async => const DependencyDeletePreview(
          impact: {'Classes': 3},
          containedClasses: 3,
          requiresClassAction: true,
          levelChoices: {
            LevelDeleteChoice.keepClasses,
            LevelDeleteChoice.deleteClasses,
          },
        ),
        delete: (choice) async {
          calls++;
          selected = choice;
          return null;
        },
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Delete Classes Too'));
      await tester.tap(find.text('Delete Classes Too'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(calls, 0);
      expect(find.text('3 Classes'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(calls, 0);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.text('Delete Level & Classes'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(selected, LevelDeleteChoice.deleteClasses);
    },
  );

  for (final width in [320.0, 1200.0]) {
    testWidgets(
      'academic year needs acknowledgment and shows active and master-data notices at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var calls = 0;
        await openDialog(
          tester,
          kind: DeleteItemKind.academicYear,
          preview: () async => const DependencyDeletePreview(
            impact: {'Exams': 12, 'Marks': 800},
            isActive: true,
          ),
          delete: (_) async {
            calls++;
            return null;
          },
        );
        await tester.pumpAndSettle();
        expect(find.text('ACTIVE ACADEMIC YEAR'), findsOneWidget);
        expect(find.text('The following will NOT be deleted:'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        for (final checkbox
            in find.byType(CheckboxListTile).evaluate().toList()) {
          final finder = find.byWidget(checkbox.widget);
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pump();
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Delete Academic Year'));
        await tester.pumpAndSettle();
        expect(calls, 1);
      },
    );
  }

  testWidgets('preview failure cannot delete and returned SQL stays hidden', (
    tester,
  ) async {
    var fail = true;
    var calls = 0;
    await openDialog(
      tester,
      kind: DeleteItemKind.schoolClass,
      preview: () async {
        if (fail) throw Exception('SQL');
        return const DependencyDeletePreview(impact: {});
      },
      delete: (_) async {
        calls++;
        return 'FOREIGN KEY CONSTRAINT';
      },
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    fail = false;
    await tester.tap(find.text('Retry Preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Class'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text(deleteFailureMessage), findsOneWidget);
    expect(find.text('FOREIGN KEY CONSTRAINT'), findsNothing);
  });

  testWidgets(
    'end-to-end: an empty level with can_delete:false from the real API is still deletable',
    (tester) async {
      var deleted = false;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showAdminDeletionFlow(
                      context,
                      kind: DeleteItemKind.level,
                      id: 5,
                      name: 'hyyjyyj',
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(find.text('Delete Level?'), findsOneWidget);
          expect(
            find.text('No classes are assigned to this level.'),
            findsOneWidget,
          );
          expect(find.text('Keep Classes'), findsNothing);
          expect(find.text('Delete Classes Too'), findsNothing);
          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Delete Level'),
          );
          expect(button.onPressed, isNotNull);
          expect(
            button.style?.backgroundColor?.resolve({}),
            const Color(0xFFB42318),
          );
          await tester.tap(find.text('Delete Level'));
          await tester.pumpAndSettle();
          expect(deleted, isTrue);
          expect(find.text('Delete Level?'), findsNothing);
        },
        () => MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'can_delete': false,
                'requires_confirmation': true,
                'level': {'id': 5, 'name': 'hyyjyyj'},
                'impact': {
                  'classes': 0,
                  'level_subject_period_requirements': 4,
                },
              }),
              200,
            );
          }
          deleted = true;
          expect(request.url.queryParameters, {
            'force': 'true',
            'class_action': 'detach',
          });
          return http.Response(jsonEncode({'deleted': true}), 200);
        }),
      );
    },
  );
}
