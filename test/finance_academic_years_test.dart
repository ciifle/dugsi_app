import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/finance/models/finance_dashboard.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:provider/provider.dart';

import 'finance_workflows_test.dart' show FinanceFixture, jsonResponse;

/// The real FINANCE response: {success, data: [...]} newest first, active = is_active 1.
Map<String, dynamic> _yearsBody() => {
  'success': true,
  'data': [
    {'id': 3, 'school_id': 1, 'name': '2026-2027', 'start_date': '2026-09-01', 'end_date': '2027-06-30', 'is_active': 1},
    {'id': 2, 'school_id': 1, 'name': '2025-2026', 'start_date': '2025-09-01', 'end_date': '2026-06-30', 'is_active': 0},
  ],
};

/// Real runtime dashboard shape: the year key is camelCase `academicYear`.
Map<String, dynamic> _dashboard(int yearId, String name) => {
  'academicYear': {'id': yearId, 'name': name},
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
};

/// FINANCE backend: real years endpoint + real dashboard shape, everything
/// else from the shared fixture. Records every request.
Future<http.Response> Function(http.Request) _backend(FinanceFixture fixture) => (request) async {
  final path = request.url.path;
  if (path == '/api/finance/academic-years') {
    fixture.requests.add(request);
    return jsonResponse(_yearsBody());
  }
  if (path == '/api/finance/dashboard') {
    fixture.requests.add(request);
    final id = int.parse(request.url.queryParameters['academic_year_id']!);
    return jsonResponse(_dashboard(id, id == 3 ? '2026-2027' : '2025-2026'));
  }
  return fixture.call(request);
};

void _size(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<Widget> _financeHome() async {
  final auth = AuthProvider();
  expect(await auth.loginWithIdentifier('cashier@example.test', 'test-password'), isNull);
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(home: roleToHome(auth.user)),
  );
}

Future<void> _openFromDrawer(WidgetTester tester, String label) async {
  // Sub pages show a back button instead of the menu; go back to a tab first.
  if (find.byIcon(Icons.menu_rounded).evaluate().isEmpty) {
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byIcon(Icons.menu_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text(label)));
  await tester.pumpAndSettle();
}

List<http.Request> _years(FinanceFixture f) => f.requests.where((r) => r.url.path.endsWith('/academic-years')).toList();

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

  group('academic-year service, per role', () {
    test('FINANCE: one GET /api/finance/academic-years; active = is_active 1; ids preserved', () async {
      final seen = <http.Request>[];
      await http.runWithClient(() async {
        final result = await AcademicYearsService.finance().list();
        final years = (result as AcademicYearSuccess<List<AcademicYear>>).data;
        expect(years.map((y) => (y.id, y.name, y.isActive)), [(3, '2026-2027', true), (2, '2025-2026', false)]);
        expect(years.first.startDate, DateTime(2026, 9, 1));
      }, () => MockClient((r) async {
        seen.add(r);
        return jsonResponse(_yearsBody());
      }));
      expect(seen.single.url.path, '/api/finance/academic-years');
      expect(seen.single.url.path.contains('school-admin'), isFalse);
    });

    test('SCHOOL_ADMIN keeps its endpoints (list + active) and behavior', () async {
      final seen = <String>[];
      late AcademicYearsProvider provider;
      await http.runWithClient(() async {
        provider = AcademicYearsProvider(); // the default, School Admin service
        await provider.refresh();
      }, () => MockClient((r) async {
        seen.add(r.url.path);
        if (r.url.path.endsWith('/active')) return jsonResponse({'academic_year': {'id': 7, 'name': '2026-2027', 'is_active': 1}});
        return jsonResponse({'academic_years': [{'id': 7, 'name': '2026-2027', 'is_active': 1}]});
      }));
      expect(seen, ['/api/school-admin/academic-years', '/api/school-admin/academic-years/active']);
      expect(provider.activeYear?.id, 7);
      expect(seen.any((p) => p.contains('/api/finance/')), isFalse);
    });

    test('empty list is a success with no years (not an error)', () async {
      late AcademicYearsProvider provider;
      await http.runWithClient(() async {
        provider = AcademicYearsProvider(service: AcademicYearsService.finance());
        await provider.refresh();
      }, () => MockClient((r) async => jsonResponse({'success': true, 'data': []})));
      expect(provider.years, isEmpty);
      expect(provider.error, isNull);
      expect(provider.activeYear, isNull);
    });

    test('no active year: Finance falls back to the newest year (existing rule)', () async {
      late AcademicYearsProvider provider;
      await http.runWithClient(() async {
        provider = AcademicYearsProvider(service: AcademicYearsService.finance());
        await provider.refresh();
      }, () => MockClient((r) async => jsonResponse({
        'success': true,
        'data': [
          {'id': 3, 'name': '2026-2027', 'is_active': 0},
          {'id': 2, 'name': '2025-2026', 'is_active': 0},
        ],
      })));
      expect(provider.activeYear, isNull);
      expect(selectedFinanceYear(provider), 3);
    });

    for (final c in <String, (int, Map<String, Object?>, int?, String?)>{
      '401': (401, {'message': 'Unauthorized'}, 401, null),
      '403': (403, {'message': 'Forbidden'}, 403, null),
      'FINANCE_NOT_ENABLED': (403, {'message': 'Finance is not enabled', 'code': 'FINANCE_NOT_ENABLED'}, 403, 'FINANCE_NOT_ENABLED'),
      '500': (500, {'message': 'Server error'}, 500, null),
    }.entries) {
      test('${c.key} is reported with its status/code and keeps no stale years', () async {
        var signedOut = 0;
        onUnauthorized = () => signedOut++;
        late AcademicYearsProvider provider;
        await http.runWithClient(() async {
          provider = AcademicYearsProvider(service: AcademicYearsService.finance());
          await provider.refresh();
        }, () => MockClient((r) async => jsonResponse(c.value.$2, c.value.$1)));
        expect(provider.years, isEmpty);
        expect(provider.error, isNotNull);
        expect(provider.errorStatus, c.value.$3);
        expect(provider.errorCode, c.value.$4);
        expect(signedOut, c.key == '401' ? 1 : 0); // 401 -> the app's normal session handling
      });
    }

    test('a network failure is an error and Retry can succeed', () async {
      var offline = true;
      late AcademicYearsProvider provider;
      await http.runWithClient(() async {
        provider = AcademicYearsProvider(service: AcademicYearsService.finance());
        await provider.refresh();
        expect(provider.error, isNotNull);
        expect(provider.error, isNot(contains('ClientException')));
        offline = false;
        await provider.refresh();
      }, () => MockClient((r) async {
        if (offline) throw http.ClientException('offline');
        return jsonResponse(_yearsBody());
      }));
      expect(provider.error, isNull);
      expect(provider.activeYear?.id, 3);
    });
  });

  group('dashboard model', () {
    test('parses the real camelCase academicYear key (and the documented snake_case)', () {
      final real = FinanceDashboard.fromJson(_dashboard(3, '2026-2027'));
      expect((real.academicYearId, real.academicYearName), (3, '2026-2027'));
      expect(real.totalCharged, 1250);
      expect(real.totalOutstanding, 350);
      expect(real.collectionsThisMonth, 500);
      final documented = FinanceDashboard.fromJson({..._dashboard(2, '2025-2026')}..['academic_year'] = {'id': 2, 'name': '2025-2026'}..remove('academicYear'));
      expect(documented.academicYearId, 2);
    });
  });

  group('FINANCE dashboard flow', () {
    testWidgets('login -> years -> active year -> dashboard with that year id', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome());
        await tester.pumpAndSettle();
        final order = fixture.requests.map((r) => r.url.path).where((p) => p.endsWith('/academic-years') || p.endsWith('/dashboard')).toList();
        expect(order, ['/api/finance/academic-years', '/api/finance/dashboard']);
        expect(fixture.requests.firstWhere((r) => r.url.path == '/api/finance/dashboard').url.queryParameters['academic_year_id'], '3');
        expect(find.text('Total Billed'), findsOneWidget);
        expect(find.text('2026-2027'), findsWidgets);
        expect(find.textContaining('Could not load academic years'), findsNothing);
        expect(fixture.requests.any((r) => r.url.path.contains('school-admin')), isFalse);
      }, () => MockClient(_backend(fixture)));
    });

    testWidgets('switching the academic year reloads the dashboard for that year', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome());
        await tester.pumpAndSettle();
        final selector = find.byWidgetPredicate((w) => w is AdminFilterDropdown<int> && w.label == 'Academic Year');
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(find.text('2025-2026').last);
        await tester.pumpAndSettle();
        final dashboards = fixture.requests.where((r) => r.url.path == '/api/finance/dashboard').toList();
        expect(dashboards.map((r) => r.url.queryParameters['academic_year_id']), ['3', '2']);
      }, () => MockClient(_backend(fixture)));
    });

    testWidgets('every year-scoped page shares the one selected year and one years request', (tester) async {
      _size(tester, 390, 900);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome());
        await tester.pumpAndSettle();

        Iterable<String?> yearParams(String pathEnd) => fixture.requests
            .where((r) => r.url.path.endsWith(pathEnd) && r.method == 'GET')
            .map((r) => r.url.queryParameters['academic_year_id']);

        await _openFromDrawer(tester, 'Class Fees');
        expect(yearParams('/class-fees'), contains('3'));
        await _openFromDrawer(tester, 'Student Discounts');
        expect(yearParams('/student-discounts'), contains('3'));
        await _openFromDrawer(tester, 'Fee Ledger');
        expect(yearParams('/fees'), contains('3'));
        await _openFromDrawer(tester, 'Generate Fees');
        expect(find.text('2026-2027'), findsWidgets);
        await _openFromDrawer(tester, 'Collect Payment');
        expect(find.text('2026-2027'), findsWidgets);
        await _openFromDrawer(tester, 'Payment History');
        expect(find.text('Payment History'), findsWidgets);

        // Nothing re-requested academic years while navigating.
        expect(_years(fixture), hasLength(1));
        expect(tester.takeException(), isNull);
      }, () => MockClient(_backend(fixture)));
    });
  });
}
