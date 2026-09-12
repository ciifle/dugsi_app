import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/school_admin/pages/exam_hall_management_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/school_admin/widgets/web_admin_theme.dart';
import 'package:kobac/school_admin/widgets/web_admin_legacy_routes.dart';
import 'package:kobac/school_admin/widgets/web_sidebar.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/widgets/form_3d/form_theme_3d.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real page loading and failed request retry inherit navy', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            theme: webAdminTheme(ThemeData()),
            home: const Scaffold(body: LevelsPage()),
          ),
        );
        await tester.pump();
        final spinner = find.byType(CircularProgressIndicator);
        expect(spinner, findsOneWidget);
        expect(
          Theme.of(tester.element(spinner)).progressIndicatorTheme.color,
          FormTheme3D.primaryBlue,
        );
        pending.complete(
          http.Response('{"message":"Unable to load levels."}', 500),
        );
        await tester.pumpAndSettle();
        expect(find.text('Retry'), findsOneWidget);
        expect(
          Theme.of(
            tester.element(find.text('Retry')),
          ).textButtonTheme.style!.foregroundColor!.resolve({}),
          FormTheme3D.primaryBlue,
        );
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(calls, 2);
        expect(find.text('Retry'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
      () => MockClient((request) {
        calls++;
        return calls == 1
            ? pending.future
            : Future.value(http.Response('{"levels":[]}', 200));
      }),
    );
  });
  test('old Parents entry points resolve safely without exposing a page', () {
    for (final path in [
      'parents',
      '/parents',
      '/admin/parents',
      '/school-admin/parents/',
      '/parents?old=true',
    ]) {
      expect(isRetiredWebAdminRoute(path), isTrue);
      expect(supportedWebAdminPage(path), 'students');
    }
    expect(supportedWebAdminPage('addStudent'), 'addStudent');
    expect(isRetiredWebAdminRoute('/parent/home'), isFalse);
  });

  test(
    'desktop palette replaces defaults without mutating the mobile theme',
    () {
      final mobile = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      );
      final original = mobile.colorScheme;
      final web = webAdminTheme(mobile);
      expect(mobile.colorScheme, same(original));
      expect(web.colorScheme.primary, FormTheme3D.primaryBlue);
      expect(web.colorScheme.secondary, FormTheme3D.primaryGreen);
      expect(web.progressIndicatorTheme.color, FormTheme3D.primaryBlue);
      expect(
        web.textButtonTheme.style!.foregroundColor!.resolve({}),
        FormTheme3D.primaryBlue,
      );
      expect(
        web.checkboxTheme.fillColor!.resolve({WidgetState.selected}),
        FormTheme3D.primaryBlue,
      );
      expect(
        web.radioTheme.fillColor!.resolve({WidgetState.selected}),
        FormTheme3D.primaryBlue,
      );
      expect(
        web.switchTheme.trackColor!.resolve({WidgetState.selected}),
        FormTheme3D.primaryGreen,
      );
      expect(web.textSelectionTheme.cursorColor, FormTheme3D.primaryBlue);
    },
  );

  for (final width in [960, 1024, 1130, 1280, 1366, 1440, 1920]) {
    testWidgets('logo, states and navigation fit at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width.toDouble(), 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retried = false;
      final theme = webAdminTheme(ThemeData());
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Row(
                children: [
                  WebSidebar(
                    width: width < 1200 ? 220 : 260,
                    selectedPage: 'students',
                    onNavigate: (_) {},
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const LinearProgressIndicator(),
                        const Icon(
                          Icons.error_outline,
                          color: FormTheme3D.errorRed,
                        ),
                        const Text('Unable to load records.'),
                        TextButton.icon(
                          onPressed: () => retried = true,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        final data = await rootBundle.load('assets/dugsi logo-04.png');
        expect(data.lengthInBytes, greaterThan(0));
      });
      final logo = find.bySemanticsLabel('Dugsi logo');
      expect(logo, findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image).first);
      await tester.runAsync(
        () => precacheImage(
          image.image,
          tester.element(find.byType(Image).first),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<RawImage>(find.byType(RawImage).first).image,
        isNotNull,
      );
      expect((image.image as AssetImage).assetName, 'assets/dugsi logo-04.png');
      expect(image.fit, BoxFit.contain);
      expect(find.text('Parents'), findsNothing);
      expect(find.text('All Students'), findsOneWidget);
      expect(find.text('Add Student'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Retry'))).colorScheme.primary,
        FormTheme3D.primaryBlue,
      );
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
      await tester.tap(find.text('Students'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('All Students'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
