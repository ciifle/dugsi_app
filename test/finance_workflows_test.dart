import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/class_fee_service.dart';
import 'package:kobac/finance/services/student_discount_service.dart';
import 'package:kobac/finance/services/fee_generation_service.dart';
import 'package:kobac/finance/services/fee_ledger_service.dart';
import 'package:kobac/finance/services/finance_payment_service.dart';
import 'package:kobac/finance/services/finance_user_service.dart';
import 'package:kobac/finance/models/class_fee.dart';
import 'package:kobac/finance/models/student_discount.dart';
import 'package:kobac/finance/models/fee_generation.dart';
import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/pages/class_fees_page.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';
import 'package:kobac/finance/pages/finance_dashboard_page.dart';
import 'package:kobac/finance/pages/finance_users_page.dart';
import 'package:kobac/finance/pages/fee_ledger_page.dart';
import 'package:kobac/finance/pages/generate_fees_page.dart';
import 'package:kobac/finance/pages/payment_history_page.dart';
import 'package:kobac/finance/pages/student_discounts_page.dart';
import 'package:kobac/finance/pages/student_fee_ledger_page.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/finance/widgets/finance_web_shell.dart';
import 'package:kobac/finance/widgets/finance_web_sidebar.dart';
import 'package:kobac/finance/pages/finance_dashboard.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';

const adminBase = 'api/school-admin/finance';
const yearJson = {
  'id': 2,
  'name': '2026-2027',
  'start_date': '2026-09-01',
  'end_date': '2027-06-30',
  'is_active': 1,
};
const feeJson = {
  'id': 12,
  'student_id': 7,
  'student_name': 'Amina Hassan',
  'emis_number': 'EMIS-7',
  'class_id': 3,
  'class_name': 'Grade 6 A',
  'academic_year_id': 2,
  'billing_cycle': 'MONTHLY',
  'billing_year': 2026,
  'billing_month': 9,
  'original_amount': 100,
  'discount_percentage': 20,
  'discount_amount': 20,
  'amount': 80,
  'paid_amount': 10,
  'remaining_amount': 70,
  'status': 'PARTIAL',
};
const classJson = {
  'class_id': 3,
  'class_name': 'Grade 6 A',
  'configured': true,
  'amount': 100,
  'billing_cycle': 'MONTHLY',
  'is_active': true,
};
const discountJson = {
  'student_id': 7,
  'student_name': 'Amina Hassan',
  'class_id': 3,
  'class_name': 'Grade 6 A',
  'academic_year_id': 2,
  'configured': true,
  'discount_percentage': 100,
  'base_amount': 100,
  'discount_amount': 100,
  'effective_amount': 0,
  'is_active': true,
};
const paymentJson = {
  'id': 51,
  'receipt_number': 'RCPT-51',
  'amount': 30,
  'method': 'CASH',
  'paid_at': '2026-09-19T10:00:00Z',
  'recorded_by': {'id': 9, 'name': 'Cashier'},
  'fee': {
    'id': 12,
    'billing_cycle': 'MONTHLY',
    'billing_year': 2026,
    'billing_month': 9,
    'academic_year_id': 2,
  },
  'student': {'id': 7, 'name': 'Amina Hassan', 'emis_number': 'EMIS-7'},
  'class': {'id': 3, 'name': 'Grade 6 A'},
};
const creationJson = {
  'payment': {
    'id': 51,
    'receipt_number': 'RCPT-51',
    'fee_id': 12,
    'amount': 30,
    'method': 'CASH',
    'recorded_by': {'id': 9, 'name': 'Cashier'},
  },
  'fee': {
    'id': 12,
    'amount': 80,
    'paid_amount': 40,
    'remaining_amount': 40,
    'status': 'PARTIAL',
  },
};
const userJson = {
  'id': 9,
  'name': 'Cashier',
  'email': 'cashier@example.test',
  'role': 'FINANCE',
  'created_at': '2026-09-19T10:00:00Z',
};
final generationJson = {
  'academic_year': yearJson,
  'period': {
    'billing_cycle': 'MONTHLY',
    'billing_year': 2026,
    'billing_month': 9,
  },
  'summary': {
    'eligible_classes': 1,
    'configured_classes': 1,
    'total_students': 1,
    'will_generate': 1,
    'already_generated': 0,
    'net_amount': 80,
    'created': 0,
    'skipped_existing': 1,
  },
  'classes': [
    {
      'class_id': 3,
      'class_name': 'Grade 6 A',
      'status': 'CONFIGURED',
      'enrolled_students': 1,
      'will_generate': 1,
      'net_amount': 80,
    },
  ],
  'warnings': [],
};
http.Response jsonResponse(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

class FinanceFixture {
  final requests = <http.Request>[];
  String role = 'SCHOOL_ADMIN';
  bool enabled = true;
  String? paymentError;
  String? deleteError;
  Future<http.Response> call(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (path.endsWith('/auth/login'))
      return jsonResponse({
        'token': 'test-token',
        'user': {...userJson, 'role': role},
      });
    if (path.endsWith('/auth/me'))
      return jsonResponse({
        'user': {...userJson, 'role': role},
        'profile': userJson,
        'feesEnabled': enabled,
        'schoolFeatures': {'feesEnabled': enabled},
        'school': {'id': 1, 'name': 'Test School'},
      });
    if (path.endsWith('/academic-years/active'))
      return jsonResponse({'academic_year': yearJson});
    if (path.endsWith('/academic-years'))
      return jsonResponse({
        'academic_years': [yearJson],
      });
    if (path.endsWith('/receipt'))
      return http.Response(
        '%PDF-1.4\nfixture',
        200,
        headers: {
          'content-type': 'application/pdf',
          'content-disposition':
              'attachment; filename="historical-RCPT-51.pdf"',
        },
      );
    if (path.contains('/finance-users')) {
      if (request.method == 'DELETE' && deleteError != null)
        return jsonResponse({'code': deleteError, 'message': 'Protected'}, 409);
      if (path.endsWith('/finance-users') && request.method == 'GET')
        return jsonResponse({
          'financeUsers': [userJson],
          'pagination': {'page': 1, 'limit': 50, 'total': 1},
        });
      return jsonResponse({
        'financeUser': userJson,
      }, request.method == 'POST' ? 201 : 200);
    }
    if (path.endsWith('/students'))
      return jsonResponse({
        'students': [
          {
            'student_id': 7,
            'student_name': 'Amina Hassan',
            'emis_number': 'EMIS-7',
            'class_id': 3,
            'class_name': 'Grade 6 A',
            'academic_year_id': 2,
          },
        ],
        'pagination': {'page': 1, 'limit': 50, 'total': 1},
      });
    if (path.endsWith('/class-fees'))
      return jsonResponse({
        'academic_year': yearJson,
        'classFees': [classJson],
      });
    if (path.contains('/class-fees/'))
      return jsonResponse({
        'academic_year': yearJson,
        'classFee': {
          ...classJson,
          if (request.method == 'PUT')
            ...jsonDecode(request.body) as Map<String, dynamic>,
        },
      });
    if (path.endsWith('/student-discounts'))
      return jsonResponse({
        'studentDiscounts': [discountJson],
      });
    if (path.contains('/student-discounts/'))
      return jsonResponse({'studentDiscount': discountJson});
    if (path.contains('/fees/generate')) return jsonResponse(generationJson);
    if (path.endsWith('/dashboard'))
      return jsonResponse({
        'academic_year': yearJson,
        'total_charged': 1250,
        'total_paid': 900,
        'total_outstanding': 350,
        'total_discount': 100,
        'paid_fees': 5,
        'partial_fees': 2,
        'unpaid_fees': 3,
        'fully_discounted_fee_count': 1,
        'collections_today': 30,
        'collections_this_month': 500,
      });
    if (path.endsWith('/students/7/fees'))
      return jsonResponse({
        'student': {'id': 7, 'name': 'Amina Hassan', 'class_name': 'Grade 6 A'},
        'academic_year': yearJson,
        'summary': {
          'total_charged': 80,
          'total_paid': 10,
          'total_remaining': 70,
        },
        'fees': [feeJson],
      });
    if (path.endsWith('/fees'))
      return jsonResponse({
        'academic_year': yearJson,
        'fees': [feeJson],
        'pagination': {'page': 1, 'limit': 50, 'total': 1},
      });
    if (path.endsWith('/payments') && request.method == 'POST') {
      if (paymentError != null)
        return jsonResponse({
          'code': paymentError,
          'message': 'Balance changed',
        }, 409);
      return jsonResponse(creationJson, 201);
    }
    if (path.endsWith('/payments/51'))
      return jsonResponse({'payment': paymentJson});
    if (path.endsWith('/payments'))
      return jsonResponse({
        'student': {'id': 7, 'name': 'Amina Hassan'},
        'summary': {'payment_count': 1, 'total_paid': 30},
        'payments': [paymentJson],
        'pagination': {'page': 1, 'limit': 50, 'total': 1},
      });
    return jsonResponse({'message': 'Unhandled test route: ' + path}, 404);
  }
}

class LoadedYears extends AcademicYearsProvider {
  LoadedYears() {
    years = [
      AcademicYear.fromJson(yearJson),
      const AcademicYear(id: 4, name: '2025-2026', isActive: false),
    ];
    activeYear = years.first;
  }
  @override
  Future<void> ensureLoaded() async {}
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  AcademicYearsProvider? years,
  AuthProvider? auth,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AcademicYearsProvider>.value(
          value: years ?? LoadedYears(),
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth ?? AuthProvider(),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: page)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient().setToken('test-token');
    onUnauthorized = null;
  });
  tearDown(() {
    ApiClient().setToken(null);
    onUnauthorized = null;
  });

  for (final base in [adminBase, 'api/finance']) {
    test(
      base + ' authenticated service workflow preserves actual contracts',
      () async {
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          final classes = ClassFeeService(basePath: base);
          expect(
            await classes.list(academicYearId: 2),
            isA<FinanceSuccess<List<ClassFee>>>(),
          );
          expect(
            await classes.get(classId: 3, academicYearId: 2),
            isA<FinanceSuccess<ClassFee>>(),
          );
          final zero = await classes.upsert(
            classId: 3,
            academicYearId: 2,
            amount: 0,
            billingCycle: 'YEARLY',
            isActive: true,
          );
          expect((zero as FinanceSuccess<ClassFee>).data.amount, 0);
          final discounts = StudentDiscountService(basePath: base);
          await discounts.list(academicYearId: 2, search: 'Amina');
          expect(
            ((await discounts.get(studentId: 7, academicYearId: 2))
                    as FinanceSuccess<StudentDiscount>)
                .data
                .effectiveAmount,
            0,
          );
          await discounts.upsert(
            studentId: 7,
            academicYearId: 2,
            discountPercentage: 100,
            reason: '',
            isActive: true,
          );
          await discounts.delete(studentId: 7, academicYearId: 2);
          final generation = FeeGenerationService(basePath: base);
          await generation.preview(
            academicYearId: 2,
            billingYear: 2026,
            billingMonth: 9,
          );
          final generated = await generation.generate(
            academicYearId: 2,
            billingYear: 2026,
            billingMonth: 9,
          );
          expect(
            (generated as FinanceSuccess<FeeGenerationResult>)
                .data
                .summary
                .skippedExisting,
            1,
          );
          final ledger = FeeLedgerService(basePath: base);
          await ledger.dashboard(academicYearId: 2);
          await ledger.listFees(
            academicYearId: 2,
            classId: 3,
            status: 'PARTIAL',
            search: 'Amina',
            billingMonth: 9,
          );
          await ledger.studentLedger(studentId: 7, academicYearId: 2);
          final payments = FinancePaymentService(basePath: base);
          final collected = await payments.recordPayment(
            feeId: 12,
            amount: 30,
            method: 'CASH',
            notes: 'x' * 500,
          );
          expect(
            (collected as FinanceSuccess<FinancePaymentCollectionResult>)
                .data
                .fee
                .remainingAmount,
            40,
          );
          await payments.list(
            academicYearId: 2,
            dateFrom: '2026-09-01',
            dateTo: '2026-09-19',
            method: 'CASH',
          );
          await payments.studentHistory(studentId: 7, academicYearId: 2);
          expect(
            ((await payments.getById(51))
                    as FinanceSuccess<FinancePaymentRecord>)
                .data
                .feeId,
            12,
          );
          final receipt = await payments.receipt(51);
          expect(
            (receipt as FinanceSuccess).data.filename,
            'historical-RCPT-51.pdf',
          );
          expect(
            fixture.requests.every(
              (r) => r.url.path.startsWith('/' + base + '/'),
            ),
            true,
          );
          expect(
            fixture.requests.every(
              (r) => r.headers['Authorization'] == 'Bearer test-token',
            ),
            true,
          );
          final post = fixture.requests.singleWhere(
            (r) => r.method == 'POST' && r.url.path.endsWith('/payments'),
          );
          expect(jsonDecode(post.body), {
            'fee_id': 12,
            'amount': 30,
            'method': 'CASH',
            'notes': 'x' * 500,
          });
          expect(
            fixture.requests
                .singleWhere((r) => r.method == 'DELETE')
                .url
                .queryParameters['academic_year_id'],
            '2',
          );
        }, () => MockClient(fixture.call));
      },
    );
  }

  test(
    '501-character notes, nonfinite and invalid amounts never reach HTTP',
    () async {
      var calls = 0;
      await http.runWithClient(
        () async {
          final service = FinancePaymentService(basePath: adminBase);
          expect(
            await service.recordPayment(
              feeId: 12,
              amount: 30,
              method: 'CASH',
              notes: 'x' * 501,
            ),
            isA<FinanceError>(),
          );
          for (final amount in [double.nan, double.infinity, -1, 0]) {
            expect(
              await service.recordPayment(
                feeId: 12,
                amount: amount,
                method: 'CASH',
              ),
              isA<FinanceError>(),
            );
          }
          expect(calls, 0);
        },
        () => MockClient((_) async {
          calls++;
          return jsonResponse({});
        }),
      );
    },
  );

  test(
    'finance user create/list/view/update/delete and protected delete',
    () async {
      final fixture = FinanceFixture();
      await http.runWithClient(() async {
        final users = FinanceUserService();
        await users.create(
          name: 'Cashier',
          email: 'cashier@example.test',
          password: 'valid-password',
        );
        await users.list();
        expect(await users.getById(9), isA<FinanceSuccess>());
        await users.update(9, name: 'Changed', password: '');
        expect(jsonDecode(fixture.requests.last.body), {'name': 'Changed'});
        fixture.deleteError = 'FINANCE_USER_HAS_PAYMENT_HISTORY';
        final protected = await users.delete(9);
        expect(
          (protected as FinanceError).message,
          contains('cannot be deleted'),
        );
        fixture.deleteError = null;
        expect(await users.delete(9), isA<FinanceSuccess>());
      }, () => MockClient(fixture.call));
    },
  );

  test(
    'safe server, authorization, missing, network and timeout failures',
    () async {
      for (final status in [400, 401, 403, 404, 409, 500]) {
        final (message, _) = financeErrorInfo(
          jsonResponse({
            'message': 'SQL exception with sensitive diagnostics',
          }, status),
          'Try again.',
        );
        expect(message.toLowerCase(), isNot(contains('sql')));
      }
      for (final error in [
        http.ClientException('offline'),
        TimeoutException('timeout'),
      ]) {
        await http.runWithClient(() async {
          expect(
            await FinancePaymentService(basePath: adminBase).list(),
            isA<FinanceError>(),
          );
        }, () => MockClient((_) async => throw error));
      }
      await http.runWithClient(
        () async {
          expect(
            await FinancePaymentService(basePath: adminBase).receipt(51),
            isA<FinanceError>(),
          );
        },
        () => MockClient(
          (_) async => http.Response(
            '<html>error</html>',
            200,
            headers: {'content-type': 'text/html'},
          ),
        ),
      );
    },
  );

  test(
    'year selection persists with global provider and never falls back after removal',
    () {
      final years = LoadedYears();
      rememberFinanceYear(years, 4);
      expect(selectedFinanceYear(years), 4);
      years.removeDeletedYear(4);
      expect(selectedFinanceYear(years), isNull);
      expect(selectedFinanceYear(LoadedYears()), 2);
    },
  );

  for (final width in [1440.0, 1280.0, 1130.0, 960.0, 360.0, 390.0, 412.0]) {
    testWidgets('Finance pages fit at ' + width.toString(), (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = FinanceFixture();
      await http.runWithClient(() async {
        for (final page in <Widget>[
          const FinanceDashboardPage(basePath: adminBase, embedBodyOnly: true),
          const FinanceUsersPage(embedBodyOnly: true),
          const ClassFeesPage(basePath: adminBase, embedBodyOnly: true),
          const StudentDiscountsPage(basePath: adminBase, embedBodyOnly: true),
          const GenerateFeesPage(basePath: adminBase, embedBodyOnly: true),
          const FeeLedgerPage(basePath: adminBase, embedBodyOnly: true),
          const StudentFeeLedgerPage(
            basePath: adminBase,
            studentId: 7,
            academicYearId: 2,
            embedBodyOnly: true,
          ),
          const CollectPaymentPage(
            basePath: adminBase,
            initial: {'studentId': 7, 'feeId': 12, 'academicYearId': 2},
            embedBodyOnly: true,
          ),
          const PaymentHistoryPage(basePath: adminBase, embedBodyOnly: true),
        ]) {
          await pumpPage(tester, page);
          expect(
            tester.takeException(),
            isNull,
            reason: page.runtimeType.toString() + ' at ' + width.toString(),
          );
          await tester.pumpWidget(const SizedBox());
        }
      }, () => MockClient(fixture.call));
    });
  }

  testWidgets(
    'collect validates amount and notes then displays server receipt and balance',
    (tester) async {
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
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), '71');
        await tester.ensureVisible(find.text('Record Payment'));
        await tester.tap(find.text('Record Payment'));
        await tester.pumpAndSettle();
        expect(
          find.text('Amount cannot exceed the remaining balance.'),
          findsOneWidget,
        );
        expect(fixture.requests.where((r) => r.method == 'POST'), isEmpty);
        await tester.enterText(fields.at(0), '30');
        await tester.enterText(fields.at(2), 'x' * 501);
        expect(
          tester.widget<TextField>(fields.at(2)).controller!.text.length,
          500,
        );
        await tester.ensureVisible(find.text('Record Payment'));
        await tester.tap(find.text('Record Payment'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AdminFeatureDialog),
            matching: find.text('Record Payment'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Payment Recorded'), findsOneWidget);
        expect(find.textContaining('RCPT-51'), findsOneWidget);
        expect(find.textContaining('40.00'), findsOneWidget);
        expect(
          fixture.requests
              .where(
                (r) => r.method == 'POST' && r.url.path.endsWith('/payments'),
              )
              .length,
          1,
        );
      }, () => MockClient(fixture.call));
    },
  );

  for (final code in ['PAYMENT_EXCEEDS_BALANCE', 'FEE_ALREADY_PAID']) {
    testWidgets(code + ' refetches the student ledger', (tester) async {
      final fixture = FinanceFixture()..paymentError = code;
      await http.runWithClient(() async {
        await pumpPage(
          tester,
          const CollectPaymentPage(
            basePath: adminBase,
            initial: {'studentId': 7, 'feeId': 12, 'academicYearId': 2},
            embedBodyOnly: true,
          ),
        );
        await tester.enterText(find.byType(TextField).first, '30');
        await tester.ensureVisible(find.text('Record Payment'));
        await tester.tap(find.text('Record Payment'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AdminFeatureDialog),
            matching: find.text('Record Payment'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          fixture.requests
              .where((r) => r.url.path.endsWith('/students/7/fees'))
              .length,
          2,
        );
        expect(find.text('Payment Recorded'), findsNothing);
      }, () => MockClient(fixture.call));
    });
  }

  testWidgets(
    'generation month change invalidates preview and prevents stale submit',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
        expect(
          find.widgetWithText(AdminPrimaryButton, 'Generate Fees'),
          findsOneWidget,
        );
        await tester.tap(month);
        await tester.pumpAndSettle();
        await tester.tap(find.text('October').last);
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(AdminPrimaryButton, 'Generate Fees'),
          findsNothing,
        );
        expect(
          fixture.requests.any((r) => r.url.path.endsWith('/fees/generate')),
          false,
        );
      }, () => MockClient(fixture.call));
    },
  );

  for (final enabled in [true, false]) {
    testWidgets(
      'FINANCE login -> AuthProvider -> role shell, enabled=' +
          enabled.toString(),
      (tester) async {
        final fixture = FinanceFixture()
          ..role = 'FINANCE'
          ..enabled = enabled;
        final auth = AuthProvider();
        await http.runWithClient(() async {
          expect(
            await auth.loginWithIdentifier(
              'cashier@example.test',
              'test-password',
            ),
            isNull,
          );
          expect(auth.isAuthenticated, true);
          expect(roleToHome(auth.user), isA<FinanceDashboardScreen>());
          await pumpPage(tester, roleToHome(auth.user), auth: auth);
          // FINANCE loads its own years (read-only finance API) and lands on a real dashboard.
          expect(
            find.text(enabled ? 'Total Billed' : 'Finance is not enabled'),
            findsOneWidget,
          );
          expect(
            find.textContaining('Academic year access unavailable'),
            findsNothing,
          );
          expect(
            fixture.requests.any((r) => r.url.path.contains('school-admin')),
            false,
          );
          expect(find.text('Finance Users'), findsNothing);
          if (enabled) {
            await pumpPage(tester, const FinanceWebShell(), auth: auth);
            final sidebarItem = find.descendant(
              of: find.byType(FinanceWebSidebar),
              matching: find.text('Payment History'),
            );
            await tester.ensureVisible(sidebarItem);
            await tester.tap(sidebarItem);
            await tester.pumpAndSettle();
            expect(find.text('RCPT-51'), findsOneWidget);
            expect(
              fixture.requests.any(
                (r) => r.url.path == '/api/finance/payments',
              ),
              true,
            );
          }
        }, () => MockClient(fixture.call));
      },
    );
  }
}
