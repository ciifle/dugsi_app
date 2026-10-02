import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/finance/models/finance_collection.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';
import 'package:kobac/finance/pages/finance_dashboard_page.dart';
import 'package:kobac/finance/services/finance_collection_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'finance_workflows_test.dart'
    show FinanceFixture, pumpPage, creationJson;

Map<String, dynamic> row(
  int id,
  String name,
  String status,
  num? remaining, {
  bool missing = false,
  num discount = 0,
}) => {
  'student_id': id,
  'student_name': name,
  'emis_number': 'EMIS-$id',
  'fee_id': missing ? null : id + 100,
  'status': status,
  'requires_fee_generation': missing,
  'original_amount': missing ? null : 35,
  'discount_percentage': missing ? null : discount,
  'amount_due': missing
      ? null
      : discount == 100
      ? 0
      : 35,
  'paid_amount': missing
      ? null
      : status == 'PARTIAL'
      ? 15
      : status == 'PAID' && discount != 100
      ? 35
      : 0,
  'remaining_amount': remaining,
};

class CollectionFixture extends FinanceFixture {
  bool saved = false, reject = false, empty = false;
  Completer<void>? saveGate;
  int registerCalls = 0;
  final batches = <Map<String, dynamic>>[];
  @override
  Future<http.Response> call(http.Request request) async {
    if (!request.url.path.endsWith('/collections/class'))
      return super.call(request);
    requests.add(request);
    if (request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      batches.add(body);
      if (saveGate != null) await saveGate!.future;
      if (reject)
        return http.Response(
          jsonEncode({
            'code': 'COLLECTION_VALIDATION_FAILED',
            'message': 'No payments saved.',
            'errors': [
              {'student_id': 7, 'code': 'FEE_ALREADY_PAID'},
            ],
          }),
          400,
        );
      saved = true;
      return http.Response(
        jsonEncode({
          'count': (body['payments'] as List).length,
          'payments': [
            for (final p in body['payments'])
              {'student_id': p['student_id'], ...creationJson},
          ],
        }),
        201,
      );
    }
    registerCalls++;
    return http.Response(
      jsonEncode({
        'academicYear': {'id': 2, 'name': '2026-2027'},
        'class': {'id': 3, 'name': 'Grade 6 A'},
        'billingPeriod': {
          'year': int.parse(request.url.queryParameters['billing_year']!),
          'month': int.parse(request.url.queryParameters['billing_month']!),
        },
        'feeConfiguration': {},
        'students': empty
            ? []
            : [
                row(
                  7,
                  'Amina Hassan',
                  saved ? 'PAID' : 'PARTIAL',
                  saved ? 0 : 20,
                ),
                row(8, 'Ahmed Ali', saved ? 'PAID' : 'UNPAID', saved ? 0 : 35),
                row(9, 'Paid Student', 'PAID', 0),
                row(10, 'Free Student', 'PAID', 0, discount: 100),
                row(
                  11,
                  'Missing Fee Student',
                  'FEE_GENERATION_REQUIRED',
                  null,
                  missing: true,
                ),
              ],
      }),
      200,
    );
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openRegister(
  WidgetTester tester, {
  String base = 'api/finance',
}) async {
  await pumpPage(
    tester,
    CollectPaymentPage(basePath: base, embedBodyOnly: true),
  );
  expect(find.text('Collect Fees'), findsOneWidget);
  final cls = find.byWidgetPredicate(
    (w) => w is AdminFilterDropdown<int> && w.label == 'Class',
  );
  await tapVisible(tester, cls);
  await tapVisible(tester, find.text('Grade 6 A').last);
}

Future<void> selectMethod(WidgetTester tester, String label) async {
  final picker = find.byWidgetPredicate(
    (w) => w is AdminFilterDropdown<String> && w.label == 'Payment Method',
  );
  await tapVisible(tester, picker);
  await tapVisible(tester, find.text(label).last);
}

void main() {
  test('typed rows preserve null missing-fee amounts and eligibility', () {
    expect(
      CollectionStudent.fromJson(
        row(1, 'Missing', 'FEE_GENERATION_REQUIRED', null, missing: true),
      ).amountDue,
      isNull,
    );
    expect(
      CollectionStudent.fromJson(
        row(1, 'Free', 'PAID', 0, discount: 100),
      ).canCollect,
      false,
    );
    expect(
      CollectionStudent.fromJson(row(1, 'Partial', 'PARTIAL', 20)).canCollect,
      true,
    );
  });
  for (final base in ['api/finance', 'api/school-admin/finance']) {
    test('$base lookup and collection use actual contracts', () async {
      final f = CollectionFixture();
      await http.runWithClient(() async {
        final service = FinanceCollectionService(basePath: base);
        final students = await service.students(
          academicYearId: 2,
          classId: 3,
          search: 'EMIS-7',
        );
        expect(students, isA<FinanceSuccess<FinanceStudentPage>>());
        expect(
          (students as FinanceSuccess<FinanceStudentPage>)
              .data
              .students
              .first
              .studentId,
          7,
        );
        final register = await service.register(
          academicYearId: 2,
          classId: 3,
          period: const CollectionPeriod(2026, 9),
        );
        expect(
          (register as FinanceSuccess<ClassCollectionRegister>).data.students,
          hasLength(5),
        );
        await service.collect(
          const BulkCollectionRequest(
            academicYearId: 2,
            classId: 3,
            period: CollectionPeriod(2026, 9),
            payments: [CollectionPaymentInput(studentId: 7, method: 'CASH')],
          ),
        );
        expect(f.batches.single['payments'], [
          {'student_id': 7, 'method': 'CASH'},
        ]);
        expect(f.requests.every((r) => r.url.path.startsWith('/$base/')), true);
      }, () => MockClient(f.call));
    });
  }
  testWidgets(
    'active year, months, class register, states, selection and confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final f = CollectionFixture();
      await http.runWithClient(() async {
        await openRegister(tester);
        expect(find.byType(DataTable), findsOneWidget);
        expect(find.text('2026-2027'), findsOneWidget);
        expect(find.text('Missing Fee Student'), findsOneWidget);
        expect(find.text('Fee not generated'), findsOneWidget);
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('select-9')))
              .onChanged,
          isNull,
        );
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('select-10')))
              .onChanged,
          isNull,
        );
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('select-11')))
              .onChanged,
          isNull,
        );
        await tapVisible(tester, find.byKey(const ValueKey('select-7')));
        expect(find.text('Save 1 Payments'), findsOneWidget);
        await tapVisible(tester, find.byKey(const ValueKey('select-8')));
        expect(find.text('Save 2 Payments'), findsOneWidget);
        await tapVisible(tester, find.byKey(const ValueKey('select-8')));
        await tapVisible(tester, find.text('Save 1 Payments'));
        expect(find.byType(AdminFeatureDialog), findsOneWidget);
        expect(find.text('Confirm Collection'), findsOneWidget);
        expect(find.textContaining('20.00'), findsWidgets);
        expect(f.batches, isEmpty);
        await selectMethod(tester, 'Mobile');
        await tapVisible(tester, find.text('Confirm & Save'));
        expect(f.batches.single['payments'], [
          {'student_id': 7, 'method': 'MOBILE'},
        ]);
        expect(f.registerCalls, 2);
        expect(find.text('1 payments recorded successfully.'), findsOneWidget);
        expect(find.text('Save 0 Payments'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => MockClient(f.call));
    },
  );
  testWidgets(
    'select all excludes paid/free/missing rows; failure preserves filters and selection',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final f = CollectionFixture()..reject = true;
      await http.runWithClient(() async {
        await openRegister(tester);
        await tapVisible(tester, find.byType(Checkbox).first);
        expect(find.text('Save 2 Payments'), findsOneWidget);
        await tapVisible(tester, find.text('Save 2 Payments'));
        await selectMethod(tester, 'Cash');
        await tapVisible(tester, find.text('Confirm & Save'));
        expect(find.text('Amina Hassan: Fee already paid.'), findsOneWidget);
        expect(find.text('Save 2 Payments'), findsOneWidget);
        expect(f.saved, false);
        expect(f.registerCalls, 1);
      }, () => MockClient(f.call));
    },
  );
  testWidgets('save lock prevents double taps and concurrent POST', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = CollectionFixture()..saveGate = Completer<void>();
    await http.runWithClient(() async {
      await openRegister(tester);
      await tapVisible(tester, find.byKey(const ValueKey('select-7')));
      await tapVisible(tester, find.text('Save 1 Payments'));
      await selectMethod(tester, 'Bank');
      await tester.tap(find.text('Confirm & Save'));
      await tester.pumpAndSettle();
      expect(f.batches, hasLength(1));
      final savingButton = tester.widget<AdminPrimaryButton>(
        find.byType(AdminPrimaryButton),
      );
      expect(savingButton.onPressed, isNull);
      f.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(f.batches, hasLength(1));
    }, () => MockClient(f.call));
  });
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('mobile register and keyboard remain stable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final f = CollectionFixture();
      await http.runWithClient(() async {
        await openRegister(tester);
        expect(find.byType(DataTable), findsNothing);
        final search = find.byType(TextField);
        await tapVisible(tester, search);
        final focus = tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.enterText(search, 'EMIS-7');
        await tester.pumpAndSettle();
        expect(focus.hasFocus, true);
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).focusNode,
          same(focus),
        );
        expect(find.text('Ahmed Ali'), findsNothing);
        expect(find.text('Amina Hassan'), findsOneWidget);
        expect(f.registerCalls, 1);
        expect(tester.takeException(), isNull);
        await tester.enterText(search, 'Amina');
        await tester.pumpAndSettle();
        expect(focus.hasFocus, true);
        expect(find.text('Amina Hassan'), findsOneWidget);
      }, () => MockClient(f.call));
    });
  }
  testWidgets(
    'month change reloads once and resets selection; no students is distinct',
    (tester) async {
      final f = CollectionFixture();
      await http.runWithClient(() async {
        await openRegister(tester);
        await tapVisible(tester, find.byKey(const ValueKey('select-7')));
        f.empty = true;
        await tapVisible(
          tester,
          find.byWidgetPredicate(
            (w) => w is AdminFilterDropdown<String> && w.label == 'Month',
          ),
        );
        await tapVisible(tester, find.text('October 2026').last);
        expect(f.registerCalls, 2);
        expect(
          find.text('No enrolled students found for this class.'),
          findsOneWidget,
        );
        expect(f.requests.last.url.queryParameters['billing_month'], '10');
      }, () => MockClient(f.call));
    },
  );
  testWidgets('mounted dashboard refetches after collection notification', (
    tester,
  ) async {
    final f = CollectionFixture();
    await http.runWithClient(() async {
      await pumpPage(
        tester,
        const FinanceDashboardPage(
          basePath: 'api/finance',
          embedBodyOnly: true,
        ),
      );
      final before = f.requests
          .where((r) => r.url.path.endsWith('/dashboard'))
          .length;
      financeCollectionChanges.collected();
      await tester.pumpAndSettle();
      expect(
        f.requests.where((r) => r.url.path.endsWith('/dashboard')).length,
        before + 1,
      );
    }, () => MockClient(f.call));
  });
}
