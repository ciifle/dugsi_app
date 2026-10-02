import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/student/finance/student_finance_service.dart';
import 'package:kobac/student/finance/student_finance_page.dart';
import 'package:kobac/student/pages/student_pay_fee_screen.dart';
import 'package:kobac/student/widgets/student_drawer.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/pages/finance_admin_mobile_menu_page.dart';
import 'package:kobac/school_admin/pages/admin_fees_screen.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/school_admin/widgets/web_dashboard.dart';
import 'package:kobac/school_admin/widgets/quick_action_card.dart';
import 'finance_workflows_test.dart'
    show feeJson, paymentJson, yearJson, jsonResponse, LoadedYears;

class FeatureAuth extends AuthProvider {
  bool enabled = true;
  @override
  bool get feesEnabled => enabled;
  void change(bool value) {
    enabled = value;
    notifyListeners();
  }

  @override
  void disableFinanceAccess() => change(false);
}

class StudentFixture {
  final requests = <http.Request>[];
  int count = 1;
  bool paid = false, fail = false, emptyPayments = false;
  Future<http.Response> call(http.Request r) async {
    requests.add(r);
    final p = r.url.path;
    if (p.endsWith('/academic-years'))
      return jsonResponse({
        'academic_years': [yearJson],
      });
    if (fail) return jsonResponse({'message': 'Internal SQL secret'}, 500);
    if (p.endsWith('/summary'))
      return jsonResponse({
        'academic_year': yearJson,
        'total_charged': paid ? 0 : 80,
        'total_paid': paid ? 0 : 10,
        'total_outstanding': paid ? 0 : 70,
        'has_outstanding_balance': !paid,
        'current_billing_period': {
          'billing_year': 2026,
          'billing_month': 9,
          'status': count == 0
              ? null
              : paid
              ? 'PAID'
              : 'PARTIAL',
          'fees': [],
        },
      });
    if (p.endsWith('/fees'))
      return jsonResponse({
        'academic_year': yearJson,
        'fees': count == 0 ? [] : [feeJson],
        'pagination': {'page': 1, 'limit': 20, 'total': count},
      });
    if (p.endsWith('/fees/12')) return jsonResponse({'fee': feeJson});
    if (p.endsWith('/payments'))
      return jsonResponse({
        'academic_year': yearJson,
        'payments': emptyPayments ? [] : [paymentJson],
        'pagination': {'page': 1, 'limit': 20, 'total': emptyPayments ? 0 : 1},
      });
    if (p.endsWith('/payments/51'))
      return jsonResponse({'payment': paymentJson});
    if (p.endsWith('/receipt'))
      return http.Response(
        '%PDF-1.4 fixture',
        200,
        headers: {
          'content-type': 'application/pdf',
          'content-disposition': 'attachment; filename="receipt-51.pdf"',
        },
      );
    return jsonResponse({});
  }
}

Future<void> mount(WidgetTester t, Widget child, FeatureAuth auth) async {
  await t.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AcademicYearsProvider>(
          create: (_) => LoadedYears(),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    ApiClient().setToken('student-token');
    onUnauthorized = null;
  });
  tearDown(() {
    ApiClient().setToken(null);
    onUnauthorized = null;
  });
  test('all six endpoints are authenticated self-service GETs', () async {
    final f = StudentFixture();
    await http.runWithClient(() async {
      final s = StudentFinanceService();
      expect(await s.summary(), isA<FinanceSuccess<StudentFinanceSummary>>());
      await s.fees(yearId: 2, status: 'PARTIAL', page: 2);
      await s.fee(12);
      await s.payments();
      await s.payment(51);
      expect(await s.receipt(51), isA<FinanceSuccess>());
      expect(f.requests.length, 6);
      for (final r in f.requests) {
        expect(r.method, 'GET');
        expect(r.url.path, startsWith('/api/student/finance/'));
        expect(r.headers['Authorization'], 'Bearer student-token');
        expect(r.url.queryParameters.keys, isNot(contains('student_id')));
        expect(r.url.queryParameters.keys, isNot(contains('school_id')));
      }
      expect(f.requests[1].url.queryParameters['status'], 'PARTIAL');
    }, () => MockClient(f.call));
  });
  for (final state in ['outstanding', 'paid', 'empty']) {
    test(
      'summary distinguishes $state including zero-charge generated fees',
      () async {
        final f = StudentFixture()
          ..paid = state != 'outstanding'
          ..count = state == 'empty' ? 0 : 1;
        await http.runWithClient(() async {
          final result =
              await StudentFinanceService().overview()
                  as FinanceSuccess<StudentFinanceOverview>;
          expect(
            result.data.balanceMessage,
            state == 'empty'
                ? 'No fees have been generated yet.'
                : state == 'paid'
                ? 'No outstanding balance.'
                : 'You have an outstanding balance.',
          );
          expect(f.requests.last.url.queryParameters['academic_year_id'], '2');
        }, () => MockClient(f.call));
      },
    );
  }
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    testWidgets('fees, details and receipts scroll without overflow at $size', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final f = StudentFixture();
      await http.runWithClient(() async {
        await mount(t, const StudentFinancePage(), FeatureAuth());
        expect(find.text('You have an outstanding balance.'), findsOneWidget);
        expect(find.text('Pay Now'), findsNothing);
        await t.ensureVisible(find.text('Details'));
        await t.tap(find.text('Details'));
        await t.pumpAndSettle();
        expect(find.text('Fee Details'), findsOneWidget);
        expect(find.text('Original amount'), findsOneWidget);
        expect(find.text('20.00 (20.00%)'), findsOneWidget);
        Navigator.of(t.element(find.text('Fee Details'))).pop();
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Payment History'));
        await t.tap(find.text('Payment History'));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('View'));
        await t.tap(find.text('View'));
        await t.pumpAndSettle();
        expect(find.text('Payment Details'), findsOneWidget);
        await t.ensureVisible(find.text('Download Receipt'));
        expect(find.text('RCPT-51'), findsWidgets);
        expect(t.takeException(), isNull);
      }, () => MockClient(f.call));
    });
  }
  testWidgets('disabled direct and former payment routes make no requests', (
    t,
  ) async {
    final f = StudentFixture();
    final auth = FeatureAuth()..enabled = false;
    await http.runWithClient(() async {
      await mount(t, const StudentPayFeeScreen(), auth);
      expect(find.byType(FinanceNotEnabledView), findsOneWidget);
      expect(f.requests, isEmpty);
      auth.change(true);
      await t.pumpAndSettle();
      expect(find.text('Fees & Payments'), findsOneWidget);
      auth.change(false);
      await t.pumpAndSettle();
      expect(find.byType(FinanceNotEnabledView), findsOneWidget);
    }, () => MockClient(f.call));
  });
  testWidgets('summary skeleton, safe network error and retry', (t) async {
    final f = StudentFixture()..fail = true;
    final gate = Completer<void>();
    await http.runWithClient(
      () async {
        await t.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: FeatureAuth(),
            child: MaterialApp(
              home: Scaffold(body: StudentFinanceSummaryCard(onView: () {})),
            ),
          ),
        );
        await t.pump();
        expect(find.byType(FinanceCardsSkeleton), findsOneWidget);
        gate.complete();
        await t.pumpAndSettle();
        expect(find.textContaining('Internal SQL'), findsNothing);
        f.fail = false;
        await t.tap(find.text('Retry'));
        await t.pumpAndSettle();
        expect(find.text('You have an outstanding balance.'), findsOneWidget);
      },
      () => MockClient((r) async {
        await gate.future;
        return f.call(r);
      }),
    );
  });
  testWidgets('no payment records has distinct empty state', (t) async {
    final f = StudentFixture()..emptyPayments = true;
    await http.runWithClient(() async {
      await mount(
        t,
        const StudentFinancePage(initialPayments: true),
        FeatureAuth(),
      );
      expect(find.text('No payments have been recorded yet.'), findsOneWidget);
    }, () => MockClient(f.call));
  });
  testWidgets('student drawer updates feature visibility', (t) async {
    final auth = FeatureAuth();
    await mount(t, AppDrawer(), auth);
    expect(find.text('Fees & Payments'), findsOneWidget);
    auth.change(false);
    await t.pumpAndSettle();
    expect(find.text('Fees & Payments'), findsNothing);
  });
  testWidgets('admin quick actions reflow and update after feature switch', (
    t,
  ) async {
    t.view.physicalSize = const Size(1440, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final auth = FeatureAuth();
    final f = StudentFixture();
    await http.runWithClient(() async {
      await mount(t, const WebDashboard(), auth);
      final enabled = t
          .widgetList<QuickActionCard>(find.byType(QuickActionCard))
          .map((e) => e.title)
          .toList();
      expect(enabled, containsAll(['Finance', 'Fees']));
      auth.change(false);
      await t.pumpAndSettle();
      final disabled = t
          .widgetList<QuickActionCard>(find.byType(QuickActionCard))
          .map((e) => e.title)
          .toList();
      expect(disabled, isNot(contains('Finance')));
      expect(disabled, isNot(contains('Fees')));
      expect(disabled.length, enabled.length - 2);
      auth.change(true);
      await t.pumpAndSettle();
      expect(find.text('Finance'), findsOneWidget);
      expect(t.takeException(), isNull);
    }, () => MockClient(f.call));
  });

  for (final status in [401, 403, 404, 500]) {
    test('detail and receipt errors preserve safe status $status', () async {
      var expired = false;
      onUnauthorized = () => expired = true;
      await http.runWithClient(
        () async {
          final service = StudentFinanceService();
          for (final result in [
            await service.fee(12),
            await service.receipt(51),
          ]) {
            expect(result, isA<FinanceError>());
            expect((result as FinanceError).statusCode, status);
            expect(result.message, isNot(contains('SQL')));
          }
          expect(expired, status == 401);
        },
        () => MockClient(
          (_) async => jsonResponse({
            'code': status == 403 ? 'FINANCE_NOT_ENABLED' : 'UNKNOWN',
            'message': 'SQL internal',
          }, status),
        ),
      );
    });
  }
  test(
    'all fee statuses, discounts and months preserve backend values',
    () async {
      await http.runWithClient(
        () async {
          final result =
              await StudentFinanceService().fees()
                  as FinanceSuccess<FinanceFeeLedgerPage>;
          expect(result.data.fees.map((e) => e.status), [
            'UNPAID',
            'PARTIAL',
            'PAID',
          ]);
          expect(result.data.fees.map((e) => e.billingMonth), [9, 10, 11]);
          expect(result.data.fees.last.remainingAmount, 0);
          expect(result.data.fees.last.discountPercentage, 100);
        },
        () => MockClient(
          (_) async => jsonResponse({
            'academic_year': yearJson,
            'fees': [
              {
                ...feeJson,
                'status': 'UNPAID',
                'paid_amount': 0,
                'remaining_amount': 80,
              },
              {...feeJson, 'billing_month': 10},
              {
                ...feeJson,
                'billing_month': 11,
                'status': 'PAID',
                'discount_percentage': 100,
                'discount_amount': 100,
                'amount': 0,
                'paid_amount': 0,
                'remaining_amount': 0,
              },
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 3},
          }),
        ),
      );
    },
  );
  testWidgets('backend feature denial hides student finance immediately', (
    t,
  ) async {
    final auth = FeatureAuth();
    await http.runWithClient(
      () async {
        await mount(t, const StudentFinancePage(), auth);
        expect(auth.feesEnabled, false);
        expect(find.byType(FinanceNotEnabledView), findsOneWidget);
        expect(find.text('Download Receipt'), findsNothing);
      },
      () => MockClient(
        (_) async => jsonResponse({'code': 'FINANCE_NOT_ENABLED'}, 403),
      ),
    );
  });
  testWidgets(
    'disabled admin direct finance and legacy fees routes do not load',
    (t) async {
      final f = StudentFixture();
      final auth = FeatureAuth()..enabled = false;
      await http.runWithClient(() async {
        await mount(t, const FinanceAdminMobileMenuPage(), auth);
        expect(find.byType(FinanceNotEnabledView), findsOneWidget);
        await mount(t, const AdminFeesScreen(openCreateOnLoad: true), auth);
        expect(
          find.text('Fees and payments are not enabled for your school.'),
          findsOneWidget,
        );
        expect(f.requests, isEmpty);
      }, () => MockClient(f.call));
    },
  );
}
