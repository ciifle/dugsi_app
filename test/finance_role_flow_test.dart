import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/finance/pages/finance_profile_page.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/finance/widgets/finance_web_shell.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:provider/provider.dart';

import 'finance_workflows_test.dart' show FinanceFixture, jsonResponse, yearJson;

class _SavePicker extends FilePicker {
  final List<String?> saved;
  _SavePicker(this.saved);
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    saved.add(fileName);
    return '/downloads/$fileName';
  }
}

void _size(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _inDialog(Finder f) => find.descendant(of: find.byType(AdminFeatureDialog), matching: f);

/// FINANCE login through the real AuthProvider -> roleToHome.
Future<Widget> _financeHome(FinanceFixture fixture, [AuthProvider? existing]) async {
  final auth = existing ?? AuthProvider();
  expect(await auth.loginWithIdentifier('cashier@example.test', 'test-password'), isNull);
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(home: roleToHome(auth.user)),
  );
}

void main() {
  final saved = <String?>[];
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient().setToken('test-token');
    saved.clear();
    FilePicker.platform = _SavePicker(saved);
  });
  tearDown(() => ApiClient().setToken(null));

  group('FINANCE academic years', () {
    test('FINANCE provider issues a single GET to the finance path and derives the active year', () async {
      final seen = <http.Request>[];
      late AcademicYearsProvider provider;
      await http.runWithClient(() async {
        provider = AcademicYearsProvider(service: AcademicYearsService.finance());
        await provider.refresh();
      }, () => MockClient((r) async {
        seen.add(r);
        return jsonResponse({
          'success': true,
          'data': [
            {'id': 3, 'school_id': 1, 'name': '2026-2027', 'start_date': '2026-09-01', 'end_date': '2027-06-30', 'is_active': 1},
            {'id': 2, 'school_id': 1, 'name': '2025-2026', 'start_date': '2025-09-01', 'end_date': '2026-06-30', 'is_active': 0},
          ],
        });
      }));
      expect(seen.map((r) => '${r.method} ${r.url.path}'), ['GET /api/finance/academic-years']);
      expect(seen.single.headers['Authorization'], 'Bearer test-token');
      expect(provider.years.map((y) => y.name), ['2026-2027', '2025-2026']);
      expect(provider.activeYear?.id, 3); // is_active == 1
    });

    testWidgets('FINANCE login lands on a real dashboard using finance-scoped years', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        expect(find.text('Total Billed'), findsOneWidget);
        expect(find.text('Academic year access unavailable'), findsNothing);
        final paths = fixture.requests.map((r) => r.url.path).toList();
        expect(paths, contains('/api/finance/academic-years'));
        expect(paths.any((p) => p.contains('school-admin')), isFalse); // never borrows admin endpoints
        final dash = fixture.requests.firstWhere((r) => r.url.path == '/api/finance/dashboard');
        expect(dash.url.queryParameters['academic_year_id'], '2'); // the real year id
        expect(find.text('Finance Users'), findsNothing);
        expect(tester.takeException(), isNull);
      }, () => MockClient(fixture.call));
    });

    testWidgets('a server error shows Could not load academic years. with a working Retry', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      var failing = true;
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        expect(find.text('Could not load academic years.'), findsOneWidget);
        expect(find.textContaining('not available to Finance accounts'), findsNothing); // obsolete message is gone
        expect(find.textContaining('DioException'), findsNothing);
        failing = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.text('Total Billed'), findsOneWidget);
      }, () => MockClient((r) async {
        if (failing && r.url.path.contains('/academic-years')) return jsonResponse({'message': 'boom'}, 500);
        return fixture.call(r);
      }));
    });

    testWidgets('FINANCE_NOT_ENABLED from the years API uses the finance-disabled state', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        expect(find.text('Finance is not enabled'), findsOneWidget);
        expect(find.text('Could not load academic years.'), findsNothing);
      }, () => MockClient((r) async {
        if (r.url.path.contains('/academic-years')) {
          return jsonResponse({'message': 'Finance is not enabled', 'code': 'FINANCE_NOT_ENABLED'}, 403);
        }
        return fixture.call(r);
      }));
    });

    testWidgets('a school with no years gets an empty state, not an error', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        expect(find.text('No academic years have been configured for this school.'), findsOneWidget);
      }, () => MockClient((r) async {
        if (r.url.path.endsWith('/academic-years')) return jsonResponse({'academic_years': []});
        if (r.url.path.endsWith('/active')) return jsonResponse({'academic_year': null});
        return fixture.call(r);
      }));
    });
  });

  group('FINANCE dashboard initialization states', () {
    testWidgets('loading shows a skeleton, never the dead-end or an error', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      final pendingYears = Completer<http.Response>();
      var hold = false;
      await http.runWithClient(() async {
        final home = await _financeHome(fixture);
        hold = true;
        await tester.pumpWidget(home);
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(FinanceSkeleton), findsOneWidget);
        expect(find.textContaining('Academic year access'), findsNothing);
        expect(find.textContaining('Could not load'), findsNothing);
        expect(find.byType(FinanceBottomNav), findsOneWidget); // shell is stable while loading
        pendingYears.complete(jsonResponse({'academic_years': [yearJson]}));
        hold = false;
        await tester.pumpAndSettle();
        expect(find.text('Total Billed'), findsOneWidget);
      }, () => MockClient((r) async {
        if (hold && r.url.path == '/api/finance/academic-years') return pendingYears.future;
        return fixture.call(r);
      }));
    });

    testWidgets('dashboard shows the header, real year and real totals', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        expect(find.text('Manage school fees, collections and student balances.'), findsOneWidget);
        expect(find.text('Academic Year'), findsWidgets);
        expect(find.text('2026-2027'), findsWidgets); // from the API, not hard-coded
        for (final label in ['Total Billed', 'Total Collected', 'Outstanding Balance', 'Total Discounts']) {
          expect(find.text(label), findsOneWidget);
        }
        // Compact 2x2 grid on a phone.
        expect(tester.getTopLeft(find.text('Total Billed')).dy, tester.getTopLeft(find.text('Total Collected')).dy);
        expect(tester.getTopLeft(find.text('Outstanding Balance')).dy, greaterThan(tester.getTopLeft(find.text('Total Billed')).dy));
        for (final label in ['Collect Payment', 'View Ledger', 'Generate Fees', 'Payment History']) {
          expect(find.text(label), findsOneWidget);
        }
      }, () => MockClient(fixture.call));
    });

    testWidgets('a dashboard API failure shows the Admin error state and Retry recovers', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      var failing = true;
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        expect(find.text('Could not load dashboard'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.textContaining('contact'), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
        failing = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.text('Total Billed'), findsOneWidget);
      }, () => MockClient((r) async {
        if (failing && r.url.path == '/api/finance/dashboard') return jsonResponse({'message': 'boom'}, 500);
        return fixture.call(r);
      }));
    });
  });

  group('FINANCE mobile shell', () {
    testWidgets('bottom navigation has four focused tabs and no admin-only items', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        expect(find.byType(FinanceBottomNav), findsOneWidget);
        for (final label in ['Dashboard', 'Fee Ledger', 'Collect', 'Profile']) {
          expect(find.descendant(of: find.byType(FinanceBottomNav), matching: find.text(label)), findsOneWidget);
        }
        // Drawer reaches the secondary pages and never Finance Users.
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await tester.pumpAndSettle();
        for (final label in ['Class Fees', 'Student Discounts', 'Generate Fees', 'Payment History']) {
          expect(find.descendant(of: find.byType(Drawer), matching: find.text(label)), findsOneWidget);
        }
        expect(find.text('Finance Users'), findsNothing);
      }, () => MockClient(fixture.call));
    });

    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets('every tab fits at ${width.toInt()}px', (tester) async {
        _size(tester, width, 800);
        final fixture = FinanceFixture()..role = 'FINANCE';
        await http.runWithClient(() async {
          await tester.pumpWidget(await _financeHome(fixture));
          await tester.pumpAndSettle();
          for (final tab in ['Fee Ledger', 'Collect', 'Profile', 'Dashboard']) {
            await tester.tap(find.descendant(of: find.byType(FinanceBottomNav), matching: find.text(tab)));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: tab);
          }
        }, () => MockClient(fixture.call));
      });
    }

    testWidgets('dashboard -> fee ledger -> collect -> payment recorded -> receipt', (tester) async {
      _size(tester, 390, 900);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(FinanceBottomNav), matching: find.text('Fee Ledger')));
        await tester.pumpAndSettle();
        expect(find.text('Amina Hassan'), findsOneWidget);
        expect(find.text('Partial'), findsOneWidget);
        await tester.tap(find.byType(FinanceActionMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Collect Payment'));
        await tester.pumpAndSettle();
        expect(find.text('Fee Summary'), findsOneWidget);
        expect(find.text('0 / 500'), findsOneWidget);
        await tester.ensureVisible(find.text('Record Payment'));
        await tester.tap(find.text('Record Payment'));
        await tester.pumpAndSettle();
        await tester.tap(_inDialog(find.text('Record Payment')));
        await tester.pumpAndSettle();
        expect(_inDialog(find.text('Payment Recorded')), findsOneWidget);
        expect(fixture.requests.where((r) => r.method == 'POST' && r.url.path == '/api/finance/payments'), hasLength(1));
        await tester.tap(_inDialog(find.text('Download Receipt')));
        await tester.pumpAndSettle();
        expect(fixture.requests.any((r) => r.url.path == '/api/finance/payments/51/receipt'), isTrue);
        expect(saved, ['historical-RCPT-51.pdf']);
      }, () => MockClient(fixture.call));
    });

    testWidgets('dashboard -> generate fees -> preview -> generate', (tester) async {
      _size(tester, 390, 1000);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Generate Fees'));
        await tester.tap(find.text('Generate Fees'));
        await tester.pumpAndSettle();
        await tester.tap(find.byWidgetPredicate((w) => w is AdminFilterDropdown<int> && w.label == 'Month'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('September').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preview'));
        await tester.pumpAndSettle();
        expect(find.text('Per-class status'), findsOneWidget);
        expect(fixture.requests.where((r) => r.url.path == '/api/finance/fees/generate/preview'), hasLength(1));
        expect(fixture.requests.where((r) => r.method == 'POST' && r.url.path == '/api/finance/fees/generate'), isEmpty);
      }, () => MockClient(fixture.call));
    });

    testWidgets('payment history -> details -> receipt', (tester) async {
      _size(tester, 390, 900);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        await tester.pumpWidget(await _financeHome(fixture));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('View all'));
        await tester.tap(find.text('View all'));
        await tester.pumpAndSettle();
        expect(find.text('Payment History'), findsWidgets);
        expect(find.text('RCPT-51'), findsOneWidget);
        await tester.tap(find.text('View'));
        await tester.pumpAndSettle();
        expect(_inDialog(find.text('Payment Details')), findsOneWidget);
        await tester.tap(_inDialog(find.text('Download Receipt')));
        await tester.pumpAndSettle();
        expect(saved, ['historical-RCPT-51.pdf']);
      }, () => MockClient(fixture.call));
    });

    testWidgets('profile shows the authenticated user and logs out via AuthProvider', (tester) async {
      _size(tester, 390, 844);
      final fixture = FinanceFixture()..role = 'FINANCE';
      await http.runWithClient(() async {
        final auth = AuthProvider();
        await tester.pumpWidget(await _financeHome(fixture, auth));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(FinanceBottomNav), matching: find.text('Profile')));
        await tester.pumpAndSettle();
        expect(find.byType(FinanceProfilePage), findsOneWidget);
        expect(find.text('My Profile'), findsOneWidget);
        expect(find.text('FINANCE'), findsNothing); // never the raw role
        expect(find.text('Finance'), findsWidgets);
        expect(find.text('C'), findsOneWidget); // initials avatar
        expect(find.text('Cashier'), findsWidgets);
        expect(find.text('cashier@example.test'), findsNWidgets(2)); // profile card + account details
        expect(find.text('Test School'), findsWidgets);
        expect(find.text('Logout'), findsOneWidget);
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();
        expect(find.text('Log out?'), findsOneWidget); // Admin confirmation modal
        expect(auth.isAuthenticated, isTrue); // nothing happens until confirmed
        await tester.tap(_inDialog(find.text('Logout')));
        await tester.pumpAndSettle();
        expect(auth.isAuthenticated, isFalse); // the app's normal logout ran
      }, () => MockClient(fixture.call));
    });
  });

  group('FINANCE desktop shell', () {
    Future<void> pumpDesktop(WidgetTester tester, FinanceFixture fixture) async {
      final auth = AuthProvider();
      expect(await auth.loginWithIdentifier('cashier@example.test', 'test-password'), isNull);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AcademicYearsProvider>(
              create: (_) => AcademicYearsProvider(service: AcademicYearsService.finance()),
            ),
          ],
          child: const MaterialApp(home: FinanceWebShell()),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final width in [960.0, 1130.0, 1280.0, 1440.0]) {
      testWidgets('sidebar shell loads the dashboard at ${width.toInt()}px', (tester) async {
        _size(tester, width, 900);
        final fixture = FinanceFixture()..role = 'FINANCE';
        await http.runWithClient(() async {
          await pumpDesktop(tester, fixture);
          expect(find.text('Total Billed'), findsOneWidget);
          for (final label in ['Class Fees', 'Student Discounts', 'Generate Fees', 'Fee Ledger', 'Collect Payment', 'Payment History']) {
            expect(find.text(label), findsWidgets, reason: label);
          }
          expect(find.text('Finance Users'), findsNothing);
          for (final label in ['Fee Ledger', 'Class Fees', 'Payment History', 'Profile']) {
            await tester.tap(find.text(label).first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$label at $width');
          }
        }, () => MockClient(fixture.call));
      });
    }
  });

  testWidgets('a session role other than FINANCE never gets the finance year scope', (tester) async {
    // SCHOOL_ADMIN keeps the school-admin provider: no finance path request.
    _size(tester, 390, 844);
    final fixture = FinanceFixture()..role = 'SCHOOL_ADMIN';
    await http.runWithClient(() async {
      final years = AcademicYearsProvider();
      await years.ensureLoaded();
      expect(years.years.single.id, yearJson['id']);
    }, () => MockClient(fixture.call));
    expect(fixture.requests.every((r) => r.url.path.contains('school-admin')), isTrue);
  });
}
