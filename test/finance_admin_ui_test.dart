import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'student_finance_test.dart' show FeatureAuth;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/finance/pages/class_fees_page.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';
import 'package:kobac/finance/pages/fee_ledger_page.dart';
import 'package:kobac/finance/pages/finance_admin_mobile_menu_page.dart';
import 'package:kobac/finance/pages/finance_dashboard_page.dart';
import 'package:kobac/finance/pages/finance_users_page.dart';
import 'package:kobac/finance/pages/generate_fees_page.dart';
import 'package:kobac/finance/pages/payment_history_page.dart';
import 'package:kobac/finance/pages/student_discounts_page.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

import 'finance_workflows_test.dart'
    show FinanceFixture, adminBase, jsonResponse, pumpPage;

void _size(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _inDialog(Finder finder) =>
    find.descendant(of: find.byType(AdminFeatureDialog), matching: finder);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient().setToken('test-token');
  });
  tearDown(() => ApiClient().setToken(null));

  group('AdminPaginationBar', () {
    Widget bar({int page = 1, int total = 24, ValueChanged<int>? onChanged}) =>
        MaterialApp(
          home: Scaffold(
            body: AdminPaginationBar(
              page: page,
              pageSize: 10,
              total: total,
              singular: 'user',
              plural: 'users',
              onPageChanged: onChanged,
            ),
          ),
        );

    testWidgets('shows a range with correct grammar and numbered pages', (
      tester,
    ) async {
      await tester.pumpWidget(bar(onChanged: (_) {}));
      expect(find.text('Showing 1–10 of 24 users'), findsOneWidget);
      for (final n in ['1', '2', '3']) {
        expect(find.text(n), findsOneWidget);
      }
      await tester.pumpWidget(bar(page: 3, onChanged: (_) {}));
      expect(find.text('Showing 21–24 of 24 users'), findsOneWidget);
      await tester.pumpWidget(bar(total: 1, onChanged: (_) {}));
      expect(find.text('Showing 1 of 1 user'), findsOneWidget);
      await tester.pumpWidget(bar(total: 0, onChanged: (_) {}));
      expect(find.textContaining('Showing'), findsNothing);
    });

    testWidgets('changes pages and is inert while loading', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(bar(onChanged: pages.add));
      await tester.tap(find.text('2'));
      await tester.tap(find.byTooltip('Next page'));
      expect(pages, [2, 2]);
      pages.clear();
      await tester.pumpWidget(bar());
      await tester.tap(find.text('2'), warnIfMissed: false);
      expect(pages, isEmpty);
    });

    testWidgets('long lists collapse with an ellipsis', (tester) async {
      await tester.pumpWidget(bar(page: 5, total: 200, onChanged: (_) {}));
      expect(find.text('…'), findsWidgets);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });

  for (final width in [390.0, 1280.0]) {
    final mobile = width < 720;
    group('Finance Users at ${width.toInt()}px', () {
      testWidgets('uses the Admin list layout with pagination and one title', (
        tester,
      ) async {
        _size(tester, width);
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          await pumpPage(tester, const FinanceUsersPage());
          expect(find.byType(AppBar), findsNothing);
          expect(find.text('Finance Users'), findsOneWidget);
          expect(
            find.text(
              "Manage staff who can access the school's finance module.",
            ),
            findsOneWidget,
          );
          expect(find.text('Add Finance User'), findsOneWidget);
          expect(find.text('Cashier'), findsOneWidget);
          expect(find.text('cashier@example.test'), findsOneWidget);
          expect(find.text('Showing 1 of 1 user'), findsOneWidget);
          expect(find.textContaining('Page 1'), findsNothing);
          expect(find.text('?'), findsNothing);
          if (mobile) {
            expect(find.byType(FinanceRecordCard), findsOneWidget);
            expect(find.text('Created: '), findsOneWidget);
            expect(find.text('19/09/2026'), findsOneWidget);
          } else {
            expect(find.byType(AdminTableCard), findsOneWidget);
            expect(find.text('Created'), findsOneWidget);
          }
          expect(find.byType(FinanceActionMenu), findsOneWidget);
          expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
          expect(tester.takeException(), isNull);
        }, () => MockClient(fixture.call));
      });

      testWidgets('Add Finance User dialog uses the Admin form system', (
        tester,
      ) async {
        _size(tester, width);
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          await pumpPage(tester, const FinanceUsersPage(embedBodyOnly: true));
          await tester.tap(find.text('Add Finance User'));
          await tester.pumpAndSettle();
          expect(find.byType(AdminFeatureDialog), findsOneWidget);
          expect(_inDialog(find.text('Add Finance User')), findsOneWidget);
          expect(
            find.byType(Input3D),
            findsNWidgets(4),
          ); // name, email + 2 password (wrapped)
          expect(find.byType(PasswordInput3D), findsNWidgets(2));
          for (final label in [
            'Name',
            'Email',
            'Password',
            'Confirm Password',
          ]) {
            expect(_inDialog(find.text(label)), findsWidgets);
          }
          expect(_inDialog(find.text('Cancel')), findsOneWidget);
          expect(_inDialog(find.text('Save User')), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Mismatched passwords never reach the API.
          final fields = find.byType(TextField);
          await tester.enterText(fields.at(0), 'New Cashier');
          await tester.enterText(fields.at(1), 'new@example.test');
          await tester.enterText(fields.at(2), 'password-one');
          await tester.enterText(fields.at(3), 'password-two');
          await tester.tap(_inDialog(find.text('Save User')));
          await tester.pumpAndSettle();
          expect(fixture.requests.where((r) => r.method == 'POST'), isEmpty);
          expect(find.text('Passwords do not match'), findsWidgets);

          await tester.enterText(fields.at(3), 'password-one');
          await tester.tap(_inDialog(find.text('Save User')));
          await tester.pumpAndSettle();
          final post = fixture.requests.singleWhere((r) => r.method == 'POST');
          expect(jsonDecode(post.body), {
            'name': 'New Cashier',
            'email': 'new@example.test',
            'password': 'password-one',
          });
          expect(find.byType(AdminFeatureDialog), findsNothing);
        }, () => MockClient(fixture.call));
      });

      testWidgets('delete asks first and hides the raw backend code', (
        tester,
      ) async {
        _size(tester, width);
        final fixture = FinanceFixture()
          ..deleteError = 'FINANCE_USER_HAS_PAYMENT_HISTORY';
        await http.runWithClient(() async {
          await pumpPage(tester, const FinanceUsersPage(embedBodyOnly: true));
          await tester.tap(find.byType(FinanceActionMenu));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();
          expect(find.text('Delete Finance User?'), findsOneWidget);
          expect(
            find.text('Are you sure you want to delete this finance user?'),
            findsOneWidget,
          );
          expect(fixture.requests.where((r) => r.method == 'DELETE'), isEmpty);
          await tester.tap(find.text('Delete').last);
          await tester.pumpAndSettle();
          expect(
            fixture.requests.where((r) => r.method == 'DELETE'),
            hasLength(1),
          );
          expect(find.text('Cannot Delete Finance User'), findsOneWidget);
          expect(
            find.text(
              'This finance user cannot be deleted because they have recorded payment history.',
            ),
            findsOneWidget,
          );
          expect(
            find.textContaining('FINANCE_USER_HAS_PAYMENT_HISTORY'),
            findsNothing,
          );
        }, () => MockClient(fixture.call));
      });
    });
  }

  testWidgets('empty Finance Users list shows a helpful empty state', (
    tester,
  ) async {
    _size(tester, 390);
    await http.runWithClient(
      () async {
        await pumpPage(tester, const FinanceUsersPage(embedBodyOnly: true));
        expect(find.text('No finance users found.'), findsOneWidget);
        expect(
          find.text('Add Finance User'),
          findsNWidgets(2),
        ); // header + empty
        expect(find.textContaining('Showing'), findsNothing);
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('/finance-users')) {
          return jsonResponse({
            'financeUsers': [],
            'pagination': {'page': 1, 'limit': 50, 'total': 0},
          });
        }
        return jsonResponse({});
      }),
    );
  });

  testWidgets('inside the desktop shell the page title is not repeated', (
    tester,
  ) async {
    _size(tester, 1280);
    Widget frame(bool inShell) => MaterialApp(
      home: Scaffold(
        body: FinancePageFrame(
          embedBodyOnly: true,
          titleInShell: inShell,
          child: FinancePageHeader(
            title: 'Finance Users',
            subtitle: 'Manage staff.',
            primaryAction: AdminPrimaryButton(
              label: 'Add Finance User',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(frame(true));
    expect(
      find.text('Finance Users'),
      findsNothing,
    ); // the shell top bar owns it
    expect(find.text('Manage staff.'), findsOneWidget);
    expect(find.text('Add Finance User'), findsOneWidget);
    await tester.pumpWidget(frame(false));
    expect(find.text('Finance Users'), findsOneWidget);
    expect(find.text('Manage staff.'), findsOneWidget);
  });

  testWidgets('mobile Finance menu is a compact grouped list', (tester) async {
    _size(tester, 360, 800);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FeatureAuth(),
        child: const MaterialApp(home: FinanceAdminMobileMenuPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    for (final label in [
      'Dashboard',
      'Finance Users',
      'Class Fees',
      'Student Discounts',
      'Generate Fees',
      'Fee Ledger',
      'Collect Payment',
      'Payment History',
    ]) {
      expect(find.text(label), findsOneWidget);
      // Compact row, not a giant card.
      final row = find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(row).height, lessThanOrEqualTo(64), reason: label);
    }
    expect(find.text('Finance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile dashboard shows compact two-column summary cards', (
    tester,
  ) async {
    _size(tester, 390);
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const FinanceDashboardPage(basePath: adminBase, embedBodyOnly: true),
      );
      final billed = tester.getTopLeft(find.text('Total Billed'));
      final collected = tester.getTopLeft(find.text('Total Collected'));
      final outstanding = tester.getTopLeft(find.text('Outstanding Balance'));
      expect(collected.dy, billed.dy); // same row
      expect(collected.dx, greaterThan(billed.dx));
      expect(outstanding.dy, greaterThan(billed.dy)); // second row
      final card = find
          .ancestor(
            of: find.text('Total Billed'),
            matching: find.byType(FinanceCard),
          )
          .first;
      expect(tester.getSize(card).height, lessThanOrEqualTo(96));
      for (final s in ['Fee Status', 'Collections', 'Quick Actions']) {
        expect(find.text(s), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }, () => MockClient(fixture.call));
  });

  testWidgets('desktop dashboard shows the four totals in a single row', (
    tester,
  ) async {
    _size(tester, 1280);
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const FinanceDashboardPage(basePath: adminBase, embedBodyOnly: true),
      );
      final ys = [
        for (final t in [
          'Total Billed',
          'Total Collected',
          'Outstanding Balance',
          'Total Discounts',
        ])
          tester.getTopLeft(find.text(t)).dy,
      ];
      expect(ys.toSet(), hasLength(1));
      expect(tester.takeException(), isNull);
    }, () => MockClient(fixture.call));
  });

  group('every standalone Finance page shows its title exactly once', () {
    final pages = <String, Widget>{
      'Finance Users': const FinanceUsersPage(),
      'Class Fees': const ClassFeesPage(basePath: adminBase),
      'Student Discounts': const StudentDiscountsPage(basePath: adminBase),
      'Generate Fees': const GenerateFeesPage(basePath: adminBase),
      'Fee Ledger': const FeeLedgerPage(basePath: adminBase),
      'Collect Fees': const CollectPaymentPage(basePath: adminBase),
      'Payment History': const PaymentHistoryPage(basePath: adminBase),
    };
    pages.forEach((title, page) {
      testWidgets(title, (tester) async {
        _size(tester, 390);
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          await pumpPage(tester, page);
          expect(find.byType(AppBar), findsNothing);
          expect(find.text(title), findsOneWidget);
          expect(find.byTooltip('Back'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }, () => MockClient(fixture.call));
      });
    });
  });

  testWidgets('class fee editor uses Admin dialog + readable billing cycle', (
    tester,
  ) async {
    _size(tester, 1280);
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const ClassFeesPage(basePath: adminBase, embedBodyOnly: true),
      );
      expect(find.text('Monthly'), findsOneWidget); // table cell, not MONTHLY
      expect(find.text('MONTHLY'), findsNothing);
      await tester.tap(
        find.byWidgetPredicate((w) => w is OutlinedButton).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminFeatureDialog), findsOneWidget);
      expect(_inDialog(find.text('Edit Class Fee')), findsOneWidget);
      expect(find.byType(Input3D), findsOneWidget);
      expect(find.byType(Select3D<String>), findsOneWidget);
      expect(_inDialog(find.text('Monthly')), findsOneWidget);
      expect(_inDialog(find.text('Save')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient(fixture.call));
  });

  testWidgets(
    'student discount editor is an Admin dialog opened from the row menu',
    (tester) async {
      _size(tester, 1280);
      final fixture = FinanceFixture();
      await http.runWithClient(() async {
        await pumpPage(
          tester,
          const StudentDiscountsPage(basePath: adminBase, embedBodyOnly: true),
        );
        await tester.tap(find.byType(FinanceActionMenu).first);
        await tester.pumpAndSettle();
        expect(find.text('Remove Discount'), findsOneWidget);
        await tester.tap(find.text('Edit Discount'));
        await tester.pumpAndSettle();
        expect(_inDialog(find.text('Student Discount')), findsOneWidget);
        expect(find.byType(Input3D), findsNWidgets(2));
        expect(_inDialog(find.text('Save Discount')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => MockClient(fixture.call));
    },
  );

  testWidgets('Payment History details open in an Admin popup', (tester) async {
    _size(tester, 1280);
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const PaymentHistoryPage(basePath: adminBase, embedBodyOnly: true),
      );
      expect(find.text('Showing 1 of 1 payment'), findsOneWidget);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(_inDialog(find.text('Payment Details')), findsOneWidget);
      expect(_inDialog(find.text('RCPT-51')), findsOneWidget);
      expect(_inDialog(find.text('Amina Hassan')), findsOneWidget);
      expect(_inDialog(find.text('Cash')), findsOneWidget);
      expect(_inDialog(find.text('Download Receipt')), findsOneWidget);
      expect(_inDialog(find.text('Close')), findsOneWidget);
      await tester.tap(_inDialog(find.text('Close')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminFeatureDialog), findsNothing);
    }, () => MockClient(fixture.call));
  });

  testWidgets('Fee Ledger uses shared pagination, badges and the row menu', (
    tester,
  ) async {
    _size(tester, 1280);
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const FeeLedgerPage(basePath: adminBase, embedBodyOnly: true),
      );
      expect(find.text('Showing 1 of 1 fee'), findsOneWidget);
      expect(find.byType(FinanceStatusBadge), findsOneWidget);
      expect(find.text('Partial'), findsOneWidget);
      await tester.tap(find.byType(FinanceActionMenu));
      await tester.pumpAndSettle();
      expect(find.text('View Ledger'), findsOneWidget);
      expect(find.text('Collect Payment'), findsOneWidget);
    }, () => MockClient(fixture.call));
  });

  testWidgets('Generate Fees confirmation is an Admin dialog', (tester) async {
    _size(tester, 1280, 1000);
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const GenerateFeesPage(basePath: adminBase, embedBodyOnly: true),
      );
      final month = find.byWidgetPredicate(
        (w) => w is AdminFilterDropdown<int> && w.label == 'Month',
      );
      await tester.tap(month);
      await tester.pumpAndSettle();
      await tester.tap(find.text('September').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(AdminPrimaryButton, 'Generate Fees'),
      );
      await tester.tap(
        find.widgetWithText(AdminPrimaryButton, 'Generate Fees'),
      );
      await tester.pumpAndSettle();
      expect(_inDialog(find.text('Generate Fees?')), findsOneWidget);
      expect(_inDialog(find.text('Will Generate')), findsOneWidget);
      expect(_inDialog(find.text('Cancel')), findsOneWidget);
      await tester.tap(_inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();
      expect(
        fixture.requests.any(
          (r) => r.url.path.endsWith('/fees/generate') && r.method == 'POST',
        ),
        isFalse,
      );
    }, () => MockClient(fixture.call));
  });

  testWidgets('recording a payment ends in the Payment Recorded popup', (
    tester,
  ) async {
    _size(tester, 390);
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const CollectPaymentPage(
          basePath: adminBase,
          initial: {'studentId': 7, 'feeId': 12, 'academicYearId': 2},
          embedBodyOnly: true,
        ),
      );
      for (final section in ['Fee Summary', 'Payment Information']) {
        expect(find.text(section), findsOneWidget);
      }
      expect(find.text('Record Payment'), findsOneWidget);
      await tester.ensureVisible(find.text('Record Payment'));
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();
      expect(_inDialog(find.text('Confirm Payment')), findsOneWidget);
      await tester.tap(_inDialog(find.text('Record Payment')));
      await tester.pumpAndSettle();
      expect(_inDialog(find.text('Payment Recorded')), findsOneWidget);
      expect(_inDialog(find.text('Receipt Number')), findsOneWidget);
      expect(_inDialog(find.text('Download Receipt')), findsOneWidget);
      expect(_inDialog(find.text('Done')), findsOneWidget);
      await tester.tap(_inDialog(find.text('Done')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminFeatureDialog), findsNothing);
      // Back at the search step, ready for the next payment.
      expect(find.text('Student'), findsWidgets);
      expect(tester.takeException(), isNull);
    }, () => MockClient(fixture.call));
  });
}
