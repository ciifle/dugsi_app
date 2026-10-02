import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/finance/pages/class_fees_page.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';
import 'package:kobac/finance/pages/fee_ledger_page.dart';
import 'package:kobac/finance/pages/payment_history_page.dart';
import 'package:kobac/finance/pages/student_discounts_page.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:provider/provider.dart';

import 'finance_workflows_test.dart'
    show FinanceFixture, feeJson, jsonResponse, pumpPage, adminBase;

/// Realistic Android phones with a typical on-screen keyboard (Gboard is
/// roughly 300-360 logical px tall).
const _phones = <String, ({Size size, double keyboard})>{
  '360x640': (size: Size(360, 640), keyboard: 300),
  '360x800': (size: Size(360, 800), keyboard: 300),
  '390x844': (size: Size(390, 844), keyboard: 340),
  '412x915': (size: Size(412, 915), keyboard: 360),
};

void _phone(WidgetTester tester, Size size, {double keyboard = 0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

/// Opens/closes the simulated keyboard the way Android does: insets change
/// while the focused field stays put.
Future<void> _keyboard(WidgetTester tester, double height) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<http.Response> Function(http.Request) _handler(
  FinanceFixture fixture, {
  int feeCount = 1,
  int? searchStatus,
  bool emptySearch = false,
}) => (request) async {
  if (request.url.path == '/api/finance/students') {
    if (searchStatus != null)
      return jsonResponse({'message': 'Server error'}, searchStatus);
    if (emptySearch) {
      return jsonResponse({
        'academicYear': {'id': 2, 'name': '2026-2027'},
        'students': [],
        'pagination': {'page': 1, 'limit': 100, 'total': 0},
      });
    }
    return jsonResponse({
      'academic_year': {'id': 2, 'name': '2026-2027'},
      'students': [
        for (var i = 0; i < feeCount; i++)
          {
            ...feeJson,
            'id': 100 + i,
            'student_id': i == 0 ? 7 : 200 + i,
            'student_name': i == 0 ? 'Amina Hassan' : 'Amina Student $i',
            'emis_number': 'EMIS-$i',
          },
      ],
      'pagination': {'page': 1, 'limit': 100, 'total': feeCount},
    });
  }
  return fixture.call(request);
};

Future<Widget> _financeHome(AuthProvider auth) async {
  expect(
    await auth.loginWithIdentifier('cashier@example.test', 'test-password'),
    isNull,
  );
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(home: roleToHome(auth.user)),
  );
}

/// FINANCE login -> drawer -> Student Discounts -> Add Discount (opens the
/// Select Student modal).
Future<void> _openStudentSelector(
  WidgetTester tester,
  FinanceFixture fixture,
) async {
  final auth = AuthProvider();
  await tester.pumpWidget(await _financeHome(auth));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.menu_rounded));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Student Discounts'),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    find.text('No discounts configured'),
    findsNothing,
  ); // the fixture has one
  await tester.tap(find.text('Add Discount'));
  await tester.pumpAndSettle();
  expect(find.text('Select Student'), findsOneWidget);
}

Finder _inModal(Finder f) =>
    find.descendant(of: find.byType(AdminFeatureDialog), matching: f);

bool pendingSearch = false;

void main() {
  setUp(() {
    pendingSearch = false;
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient().setToken('test-token');
  });
  tearDown(() => ApiClient().setToken(null));

  for (final entry in _phones.entries) {
    final phone = entry.value;
    group('Select Student with the keyboard open at ${entry.key}', () {
      testWidgets(
        'FINANCE flow: search, results, select - no overflow, keyboard closes',
        (tester) async {
          _phone(tester, phone.size);
          final fixture = FinanceFixture()..role = 'FINANCE';
          await http.runWithClient(() async {
            await _openStudentSelector(tester, fixture);
            expect(
              find.text('Search by name or EMIS to find a student.'),
              findsOneWidget,
            );

            // Focus the search field; the keyboard opens.
            await tester.tap(find.byType(TextField));
            await tester.pumpAndSettle();
            await _keyboard(tester, phone.keyboard);
            expect(tester.takeException(), isNull);

            await tester.enterText(find.byType(TextField), 'Amina');
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(_inModal(find.text('Amina Hassan')), findsOneWidget);
            expect(find.text('EMIS-0 · Grade 6 A'), findsOneWidget);

            // Header, search field and close button all sit above the keyboard.
            final visible = phone.size.height - phone.keyboard;
            for (final f in [
              find.text('Select Student'),
              find.byType(TextField),
              find.byIcon(Icons.close_rounded),
            ]) {
              expect(
                tester.getRect(f).bottom,
                lessThanOrEqualTo(visible),
                reason: f.toString(),
              );
              expect(tester.getRect(f).top, greaterThanOrEqualTo(0));
            }
            final dialog = tester.getRect(
              find.descendant(
                of: find.byType(AdminFeatureDialog),
                matching: find.byType(FormCard),
              ),
            );
            expect(dialog.bottom, lessThanOrEqualTo(visible));

            // Selecting closes the modal, drops the keyboard and continues. (On the
            // shortest phone the result sits in the scroll area, so scroll to it.)
            await tester.ensureVisible(_inModal(find.text('Amina Hassan')));
            await tester.pumpAndSettle();
            await tester.tap(_inModal(find.text('Amina Hassan')));
            await _keyboard(tester, 0);
            expect(find.text('Select Student'), findsNothing);
            expect(
              FocusManager.instance.primaryFocus?.hasPrimaryFocus == true &&
                  FocusManager.instance.primaryFocus?.context?.widget
                      is EditableText,
              isFalse,
            );
            expect(
              find.text('Student Discount'),
              findsOneWidget,
            ); // discount editor for the picked student
            expect(
              fixture.requests.any(
                (r) => r.url.path == '/api/finance/student-discounts/7',
              ),
              isTrue,
            );
            expect(tester.takeException(), isNull);
          }, () => MockClient(_handler(fixture)));
        },
      );

      testWidgets(
        'many results scroll inside the modal instead of overflowing',
        (tester) async {
          _phone(tester, phone.size);
          final fixture = FinanceFixture()..role = 'FINANCE';
          await http.runWithClient(() async {
            await _openStudentSelector(tester, fixture);
            await tester.tap(find.byType(TextField));
            await _keyboard(tester, phone.keyboard);
            await tester.enterText(find.byType(TextField), 'Amina');
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(_inModal(find.text('Amina Hassan')), findsOneWidget);
            // The last result is off-screen until scrolled...
            expect(find.text('Amina Student 14').hitTestable(), findsNothing);
            await tester.dragUntilVisible(
              find.text('Amina Student 14'),
              find.descendant(
                of: find.byType(AdminFeatureDialog),
                matching: find.byType(SingleChildScrollView),
              ),
              const Offset(0, -120),
            );
            expect(tester.takeException(), isNull);
            // ...while the pinned search field never moves out of view.
            expect(tester.getRect(find.byType(TextField)).top, greaterThan(0));
            expect(
              find.byIcon(Icons.close_rounded).hitTestable(),
              findsOneWidget,
            );
          }, () => MockClient(_handler(fixture, feeCount: 15)));
        },
      );

      testWidgets('the close button is reachable and dismisses the keyboard', (
        tester,
      ) async {
        _phone(tester, phone.size);
        final fixture = FinanceFixture()..role = 'FINANCE';
        await http.runWithClient(() async {
          await _openStudentSelector(tester, fixture);
          await tester.tap(find.byType(TextField));
          await _keyboard(tester, phone.keyboard);
          await tester.tap(find.byIcon(Icons.close_rounded));
          await _keyboard(tester, 0);
          expect(find.text('Select Student'), findsNothing);
          expect(tester.takeException(), isNull);
        }, () => MockClient(fixture.call));
      });
    });
  }

  group('Select Student states fit with the keyboard open (390x844)', () {
    Future<void> openWith(WidgetTester tester, FinanceFixture fixture) async {
      _phone(tester, const Size(390, 844));
      await _openStudentSelector(tester, fixture);
      await tester.tap(find.byType(TextField));
      await _keyboard(tester, 340);
      await tester.enterText(find.byType(TextField), 'zz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets('no results', (tester) async {
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await openWith(tester, fixture);
        expect(find.text('No students found.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => MockClient(_handler(fixture, emptySearch: true)));
    });

    testWidgets('API error with Retry', (tester) async {
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await openWith(tester, fixture);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.textContaining('Exception'), findsNothing);
        expect(tester.takeException(), isNull);
      }, () => MockClient(_handler(fixture, searchStatus: 500)));
    });

    testWidgets('loading', (tester) async {
      final fixture = FinanceFixture()..role = 'FINANCE';
      final pending = Completer<http.Response>();
      await http.runWithClient(
        () async {
          _phone(tester, const Size(390, 844));
          await _openStudentSelector(tester, fixture);
          pendingSearch = true;
          await tester.tap(find.byType(TextField));
          await _keyboard(tester, 340);
          await tester.enterText(find.byType(TextField), 'Amina');
          await tester.pump(
            const Duration(milliseconds: 300),
          ); // debounce fired, request pending
          expect(find.byType(CircularProgressIndicator), findsWidgets);
          expect(tester.takeException(), isNull);
          pending.complete(
            jsonResponse({
              'students': [],
              'pagination': {'page': 1, 'limit': 100, 'total': 0},
            }),
          );
          await tester.pumpAndSettle();
        },
        () => MockClient((r) async {
          if (pendingSearch && r.url.path == '/api/finance/students')
            return pending.future;
          return fixture.call(r);
        }),
      );
    });
  });

  group('the rest of Finance survives the keyboard', () {
    for (final entry in _phones.entries) {
      final phone = entry.value;

      testWidgets('page filters/search with keyboard at ${entry.key}', (
        tester,
      ) async {
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          for (final page in <Widget>[
            const StudentDiscountsPage(
              basePath: adminBase,
              embedBodyOnly: true,
            ),
            const FeeLedgerPage(basePath: adminBase, embedBodyOnly: true),
            const PaymentHistoryPage(basePath: adminBase, embedBodyOnly: true),
            const ClassFeesPage(basePath: adminBase, embedBodyOnly: true),
          ]) {
            _phone(tester, phone.size);
            await pumpPage(tester, page);
            final filters = find.text('Search & filters');
            FocusNode? focused;
            if (filters.evaluate().isNotEmpty) {
              await tester.tap(filters);
              await tester.pumpAndSettle();
              final field = find.byType(TextField);
              if (field.evaluate().isNotEmpty) {
                await tester.ensureVisible(field.last);
                await tester.pumpAndSettle();
                await tester.tap(field.last);
                await tester.pump();
                focused = tester
                    .widget<EditableText>(
                      find.descendant(
                        of: field.last,
                        matching: find.byType(EditableText),
                      ),
                    )
                    .focusNode;
              }
            }
            await _keyboard(tester, phone.keyboard);
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.runtimeType} at ${entry.key}',
            );
            // The filter/search field must be the same, still-focused field -
            // not a fresh one remounted by the keyboard opening.
            if (focused != null) {
              expect(
                focused.hasFocus,
                isTrue,
                reason: '${page.runtimeType} at ${entry.key} lost focus',
              );
            }
            await tester.pumpWidget(const SizedBox());
          }
        }, () => MockClient(fixture.call));
      });

      testWidgets('Collect Payment form fields with keyboard at ${entry.key}', (
        tester,
      ) async {
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          _phone(tester, phone.size);
          await pumpPage(
            tester,
            const CollectPaymentPage(
              basePath: adminBase,
              embedBodyOnly: true,
              initial: {'studentId': 7, 'feeId': 12, 'academicYearId': 2},
            ),
          );
          for (final index in [0, 1, 2]) {
            await tester.ensureVisible(find.byType(TextField).at(index));
            await tester.tap(find.byType(TextField).at(index));
            await _keyboard(tester, phone.keyboard);
            expect(
              tester.takeException(),
              isNull,
              reason: 'field $index at ${entry.key}',
            );
          }
          await tester.enterText(find.byType(TextField).at(2), 'x' * 600);
          await tester.pumpAndSettle();
          expect(
            find.text('500 / 500'),
            findsOneWidget,
          ); // capped at the storage limit
        }, () => MockClient(fixture.call));
      });

      testWidgets('editor dialogs with keyboard at ${entry.key}', (
        tester,
      ) async {
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          _phone(tester, phone.size);
          await pumpPage(
            tester,
            const ClassFeesPage(basePath: adminBase, embedBodyOnly: true),
          );
          await tester.tap(
            find.byWidgetPredicate((w) => w is OutlinedButton).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(TextField).first);
          await _keyboard(tester, phone.keyboard);
          expect(tester.takeException(), isNull);
          final visible = phone.size.height - phone.keyboard;
          expect(
            tester
                .getRect(
                  find.descendant(
                    of: find.byType(AdminFeatureDialog),
                    matching: find.byType(FormCard),
                  ),
                )
                .bottom,
            lessThanOrEqualTo(visible),
          );
          expect(
            find.byIcon(Icons.close_rounded).hitTestable(),
            findsOneWidget,
          );
        }, () => MockClient(fixture.call));
      });
    }
  });

  testWidgets(
    'the mobile shell drops its bottom navigation while the keyboard is open',
    (tester) async {
      _phone(tester, const Size(390, 844));
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(AuthProvider()));
        await tester.pumpAndSettle();
        expect(find.byType(FinanceBottomNav), findsOneWidget);
        await _keyboard(tester, 340);
        expect(find.byType(FinanceBottomNav), findsNothing);
        expect(tester.takeException(), isNull);
        await _keyboard(tester, 0);
        expect(find.byType(FinanceBottomNav), findsOneWidget);
      }, () => MockClient(fixture.call));
    },
  );
}
