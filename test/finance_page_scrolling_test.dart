import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/finance/pages/class_fees_page.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';
import 'package:kobac/finance/pages/fee_ledger_page.dart';
import 'package:kobac/finance/pages/finance_dashboard.dart';
import 'package:kobac/finance/pages/finance_dashboard_page.dart';
import 'package:kobac/finance/pages/finance_profile_page.dart';
import 'package:kobac/finance/pages/finance_users_page.dart';
import 'package:kobac/finance/pages/generate_fees_page.dart';
import 'package:kobac/finance/pages/individual_payment_page.dart';
import 'package:kobac/finance/pages/payment_history_page.dart';
import 'package:kobac/finance/pages/student_discounts_page.dart';
import 'package:kobac/finance/pages/student_fee_ledger_page.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/finance/widgets/finance_web_shell.dart';
import 'package:kobac/finance/widgets/finance_web_sidebar.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/web_top_bar.dart';
import 'finance_workflows_test.dart'
    show
        FinanceFixture,
        pumpPage,
        feeJson,
        paymentJson,
        userJson,
        discountJson,
        classJson,
        generationJson;
import 'finance_class_collection_test.dart' show row;

class LongFinanceFixture extends FinanceFixture {
  @override
  Future<http.Response> call(http.Request r) async {
    final path = r.url.path;
    final page = int.tryParse(r.url.queryParameters['page'] ?? '') ?? 1;
    final fees = List.generate(
      20,
      (i) => {...feeJson, 'id': 100 + i, 'student_name': 'Ledger Student $i'},
    );
    dynamic result;
    if (path.endsWith('/fees') && !path.contains('/students/'))
      result = {
        'fees': fees,
        'pagination': {'page': page, 'limit': 20, 'total': 40},
      };
    if (path.endsWith('/students/7/fees'))
      result = {
        'student': {
          'id': 7,
          'name': 'Ledger Student',
          'class_name': 'Grade 6 A',
        },
        'summary': {},
        'fees': fees,
      };
    if (path.endsWith('/payments'))
      result = {
        'payments': List.generate(
          20,
          (i) => {
            ...paymentJson,
            'id': 100 + i,
            'receipt_number': 'RCPT-$i',
            'student': {'id': i, 'name': 'History Student $i'},
          },
        ),
        'pagination': {'page': page, 'limit': 20, 'total': 40},
      };
    if (path.endsWith('/finance-users'))
      result = {
        'financeUsers': List.generate(
          20,
          (i) => {...userJson, 'id': i + 1, 'name': 'Finance User $i'},
        ),
        'pagination': {'page': page, 'limit': 50, 'total': 20},
      };
    if (path.endsWith('/student-discounts'))
      result = {
        'studentDiscounts': List.generate(
          20,
          (i) => {
            ...discountJson,
            'student_id': i + 1,
            'student_name': 'Discount Student $i',
          },
        ),
      };
    if (path.endsWith('/class-fees'))
      result = {
        'classFees': List.generate(
          20,
          (i) => {
            ...classJson,
            'class_id': i + 3,
            'class_name': i == 0 ? 'Grade 6 A' : 'Class $i',
          },
        ),
      };
    if (path.endsWith('/collections/class'))
      result = {
        'academicYear': {'id': 2},
        'class': {'id': 3, 'name': 'Grade 6 A'},
        'billingPeriod': {'month': 9, 'year': 2026},
        'students': List.generate(
          20,
          (i) => row(i + 7, 'Collection Student $i', 'UNPAID', 35),
        ),
      };
    if (path.endsWith('/fees/generate/preview'))
      result = {
        ...generationJson,
        'classes': List.generate(
          20,
          (i) => {
            'class_id': i + 3,
            'class_name': 'Generate Class $i',
            'status': 'CONFIGURED',
            'enrolled_students': 20,
            'will_generate': 20,
            'net_amount': 700,
          },
        ),
      };
    if (result != null) {
      requests.add(r);
      return http.Response(jsonEncode(result), 200);
    }
    return super.call(r);
  }
}

// EditableText may scroll its own multiline input; select the page viewport.
Finder verticalPage() => find
    .descendant(
      of: find.byKey(const ValueKey('finance-page-scroll')),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    )
    .first;
Future<void> visibleTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final pages = <String, Widget>{
    'Fee Ledger': const FeeLedgerPage(
      basePath: 'api/finance',
      embedBodyOnly: true,
    ),
    'Payment History': const PaymentHistoryPage(
      basePath: 'api/finance',
      embedBodyOnly: true,
    ),
    'Finance Users': const FinanceUsersPage(embedBodyOnly: true),
    'Class Fees': const ClassFeesPage(
      basePath: 'api/finance',
      embedBodyOnly: true,
    ),
    'Student Discounts': const StudentDiscountsPage(
      basePath: 'api/finance',
      embedBodyOnly: true,
    ),
    'Finance': const FinanceDashboardPage(
      basePath: 'api/finance',
      embedBodyOnly: true,
    ),
    'Student Ledger': const StudentFeeLedgerPage(
      basePath: 'api/finance',
      studentId: 7,
      academicYearId: 2,
      embedBodyOnly: true,
    ),
    'My Profile': const FinanceProfilePage(embedBodyOnly: true),
    'Generate Fees': const GenerateFeesPage(
      basePath: 'api/finance',
      embedBodyOnly: true,
    ),
    'Collect Payment': const IndividualPaymentPage(
      basePath: 'api/finance',
      embedBodyOnly: true,
      initial: {'studentId': 7, 'feeId': 100, 'academicYearId': 2},
    ),
  };
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    for (final entry in pages.entries) {
      testWidgets('${entry.key} uses one whole-page scroll at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final fixture = LongFinanceFixture();
        await http.runWithClient(() async {
          await pumpPage(
            tester,
            FinancePageChrome(
              header: const SizedBox(
                height: 56,
                child: Text('Finance / Barwaaqo Academy'),
              ),
              child: entry.value,
            ),
          );
          final header = tester.getRect(
            find.text('Finance / Barwaaqo Academy'),
          );
          expect(verticalPage(), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is SingleChildScrollView &&
                  w.scrollDirection == Axis.vertical,
            ),
            findsOneWidget,
          );
          final title = find.text(entry.key).first;
          expect(title.hitTestable(), findsOneWidget);
          final state = tester.state<ScrollableState>(verticalPage());
          if (state.position.maxScrollExtent > 100) {
            await tester.drag(verticalPage(), const Offset(0, -550));
            await tester.pumpAndSettle();
            expect(
              tester.getRect(title).bottom,
              lessThan(0),
              reason: 'heading must scroll offscreen with content',
            );
          }
          if ([
            'Fee Ledger',
            'Payment History',
            'Finance Users',
          ].contains(entry.key)) {
            await tester.ensureVisible(find.byType(AdminPaginationBar));
            await tester.pumpAndSettle();
            expect(
              find.byType(AdminPaginationBar).hitTestable(),
              findsOneWidget,
            );
          }
          if (entry.key == 'Class Fees') {
            await tester.ensureVisible(find.text('Class 19'));
            await tester.pumpAndSettle();
            expect(find.text('Class 19').hitTestable(), findsOneWidget);
          }
          if (entry.key == 'Student Discounts') {
            await tester.ensureVisible(find.text('Discount Student 19'));
            await tester.pumpAndSettle();
            expect(
              find.text('Discount Student 19').hitTestable(),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(find.text('Finance / Barwaaqo Academy')),
            header,
          );
          expect(
            find.text('Finance / Barwaaqo Academy').hitTestable(),
            findsOneWidget,
          );
        }, () => MockClient(fixture.call));
      });
    }
    testWidgets('full class and final save action scroll at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fixture = LongFinanceFixture();
      await http.runWithClient(() async {
        await pumpPage(
          tester,
          const CollectPaymentPage(
            basePath: 'api/finance',
            embedBodyOnly: true,
          ),
        );
        await visibleTap(
          tester,
          find.byWidgetPredicate(
            (w) => w is AdminFilterDropdown<int> && w.label == 'Class',
          ),
        );
        await visibleTap(tester, find.text('Grade 6 A').last);
        expect(verticalPage(), findsOneWidget);
        await tester.drag(verticalPage(), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.text('Collect Fees')).bottom, lessThan(0));
        await tester.ensureVisible(find.text('Collection Student 19'));
        await tester.pumpAndSettle();
        expect(
          find.text('Collection Student 19').hitTestable(),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Save 0 Payments'));
        await tester.pumpAndSettle();
        expect(find.text('Save 0 Payments').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => MockClient(fixture.call));
    });
  }
  testWidgets('mobile root header and bottom navigation stay fixed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fixture = LongFinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(tester, const FinanceMobileShell());
      await tester.tap(
        find.descendant(
          of: find.byType(FinanceBottomNav),
          matching: find.text('Fee Ledger'),
        ),
      );
      await tester.pumpAndSettle();
      final nav = tester.getRect(find.byType(FinanceBottomNav));
      final header = tester.getRect(find.byType(FinanceRootPageHeader));
      await tester.drag(verticalPage(), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(FinanceRootPageHeader)), header);
      expect(find.byType(FinanceRootPageHeader).hitTestable(), findsOneWidget);
      expect(
        find
            .descendant(
              of: find.byKey(const ValueKey('finance-page-scroll')),
              matching: find.text('Fee Ledger'),
            )
            .hitTestable(),
        findsNothing,
      );
      expect(tester.getRect(find.byType(FinanceBottomNav)), nav);
      await tester.ensureVisible(find.byType(AdminPaginationBar));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(AdminPaginationBar)).bottom,
        lessThanOrEqualTo(nav.top),
      );
      final pagination = tester.widget<AdminPaginationBar>(
        find.byType(AdminPaginationBar),
      );
      pagination.onPageChanged!(2);
      await tester.pumpAndSettle();
      expect(tester.state<ScrollableState>(verticalPage()).position.pixels, 0);
      expect(find.text('Fee Ledger').hitTestable(), findsWidgets);
    }, () => MockClient(fixture.call));
  });
  testWidgets('desktop header and sidebar stay fixed while content scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fixture = LongFinanceFixture();
    await http.runWithClient(() async {
      await pumpPage(tester, const FinanceWebShell());
      await tester.tap(
        find.descendant(
          of: find.byType(FinanceWebSidebar),
          matching: find.text('Fee Ledger'),
        ),
      );
      await tester.pumpAndSettle();
      final sidebar = tester.getRect(find.byType(FinanceWebSidebar));
      final header = tester.getRect(find.byType(WebTopBar));
      expect(verticalPage(), findsOneWidget);
      await tester.drag(verticalPage(), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(WebTopBar)), header);
      expect(tester.getRect(find.byType(FinanceWebSidebar)), sidebar);
      await tester.ensureVisible(find.byType(AdminPaginationBar));
      await tester.pumpAndSettle();
      expect(find.byType(AdminPaginationBar).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient(fixture.call));
  });
}
