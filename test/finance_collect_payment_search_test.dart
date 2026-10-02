import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';

import 'finance_workflows_test.dart' show FinanceFixture, adminBase, pumpPage;

/// Realistic Android phones with a typical on-screen keyboard.
const _phones = <String, ({Size size, double keyboard})>{
  '360x640': (size: Size(360, 640), keyboard: 300),
  '360x800': (size: Size(360, 800), keyboard: 300),
  '390x844': (size: Size(390, 844), keyboard: 340),
  '412x915': (size: Size(412, 915), keyboard: 360),
};

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Simulates the Android keyboard opening/closing: only `viewInsets.bottom`
/// changes, the way the real platform reports it, while whatever field is
/// currently focused stays put unless the app itself does something.
Future<void> _keyboard(WidgetTester tester, double height) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  await tester.pump();
  await tester.pumpAndSettle();
}

/// The [FocusNode] actually driving the search field's `EditableText` -
/// reading this (not just `hasFocus` on some test-only node) is what proves
/// the *same* TextField Element survived a rebuild: if the field had been
/// unmounted and remounted, this would be a fresh, unfocused FocusNode.
FocusNode _searchFocusNode(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(TextField).first,
        matching: find.byType(EditableText),
      ),
    )
    .focusNode;

bool _keyboardConnected(WidgetTester tester) => tester.testTextInput.isVisible;

Future<void> _openCollectPayment(
  WidgetTester tester,
  FinanceFixture fixture,
) async {
  await pumpPage(
    tester,
    const CollectPaymentPage(basePath: adminBase, embedBodyOnly: true),
  );
  await tester.tap(find.text('Individual Payment'));
  await tester.pumpAndSettle();
  expect(find.text('Search student by name or EMIS'), findsOneWidget);
}

void main() {
  for (final entry in _phones.entries) {
    final phone = entry.value;

    testWidgets(
      'the search field keeps focus through typing, debounce, loading and results (${entry.key})',
      (tester) async {
        _phone(tester, phone.size);
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          await _openCollectPayment(tester, fixture);

          // Focus the field; the keyboard opens. This is exactly where the
          // page used to shrink below its old fixed minimum height and swap
          // in a differently-shaped subtree, silently remounting the field.
          await tester.tap(find.byType(TextField));
          await tester.pump();
          await _keyboard(tester, phone.keyboard);
          expect(_searchFocusNode(tester).hasFocus, isTrue);
          expect(_keyboardConnected(tester), isTrue);
          expect(tester.takeException(), isNull);

          // Type "BRQ26" and let the debounce timer schedule a search.
          await tester.enterText(find.byType(TextField), 'BRQ26');
          await tester.pump(
            const Duration(milliseconds: 100),
          ); // < debounce: no request yet
          expect(
            fixture.requests.where((r) => r.url.path.endsWith('/students')),
            isEmpty,
          );
          expect(_searchFocusNode(tester).hasFocus, isTrue);
          expect(find.text('BRQ26'), findsOneWidget);

          // Let the debounce fire: search starts (loading), then resolves
          // (results). The field must stay focused and keep its text through
          // every one of those setState calls/provider updates.
          await tester.pump(const Duration(milliseconds: 250));
          expect(
            _searchFocusNode(tester).hasFocus,
            isTrue,
            reason: 'lost focus when loading started',
          );
          expect(find.text('BRQ26'), findsOneWidget);
          await tester.pumpAndSettle();
          expect(
            fixture.requests.where((r) => r.url.path.endsWith('/students')),
            hasLength(1),
          );
          expect(
            find.text('Amina Hassan'),
            findsOneWidget,
          ); // results rendered below the field
          expect(
            _searchFocusNode(tester).hasFocus,
            isTrue,
            reason: 'lost focus when results arrived',
          );
          expect(_keyboardConnected(tester), isTrue);
          expect(find.text('BRQ26'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Continue typing on top of the existing results; the field is
          // still the same, focused, live TextField.
          await tester.enterText(find.byType(TextField), 'BRQ26001');
          await tester.pump();
          expect(find.text('BRQ26001'), findsOneWidget);
          expect(_searchFocusNode(tester).hasFocus, isTrue);
          expect(tester.takeException(), isNull);
        }, () => MockClient(fixture.call));
      },
    );

    testWidgets(
      'no RenderFlex overflow while the keyboard is open (${entry.key})',
      (tester) async {
        _phone(tester, phone.size);
        final fixture = FinanceFixture();
        await http.runWithClient(() async {
          await _openCollectPayment(tester, fixture);
          await tester.tap(find.byType(TextField));
          await _keyboard(tester, phone.keyboard);
          await tester.enterText(find.byType(TextField), 'Amina');
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }, () => MockClient(fixture.call));
      },
    );
  }

  testWidgets('typing does not fire a request per keystroke (debounced)', (
    tester,
  ) async {
    _phone(tester, const Size(390, 844));
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await _openCollectPayment(tester, fixture);
      await tester.tap(find.byType(TextField));
      for (final partial in ['A', 'Am', 'Ami', 'Amin', 'Amina']) {
        await tester.enterText(find.byType(TextField), partial);
        await tester.pump(
          const Duration(milliseconds: 60),
        ); // well under the debounce
      }
      expect(
        fixture.requests.where((r) => r.url.path.endsWith('/students')),
        isEmpty,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      // One search, for the final value only.
      final searches = fixture.requests
          .where((r) => r.url.path.endsWith('/students'))
          .toList();
      expect(searches, hasLength(1));
      expect(searches.single.url.queryParameters['search'], 'Amina');
    }, () => MockClient(fixture.call));
  });

  testWidgets('an in-flight search is dropped in favour of a newer one', (
    tester,
  ) async {
    _phone(tester, const Size(390, 844));
    final fixture = FinanceFixture();
    await http.runWithClient(() async {
      await _openCollectPayment(tester, fixture);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Am');
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // first search fires
      await tester.enterText(find.byType(TextField), 'Amina');
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // second search fires before the fixture flushes
      await tester.pumpAndSettle();
      expect(_searchFocusNode(tester).hasFocus, isTrue);
      expect(find.text('Amina Hassan'), findsOneWidget);
      expect(find.text('BRQ26'), findsNothing);
    }, () => MockClient(fixture.call));
  });

  testWidgets(
    'clearing back below the minimum length clears results without a request',
    (tester) async {
      _phone(tester, const Size(390, 844));
      final fixture = FinanceFixture();
      await http.runWithClient(() async {
        await _openCollectPayment(tester, fixture);
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Amina');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text('Amina Hassan'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'A');
        await tester.pump();
        expect(find.text('Amina Hassan'), findsNothing);
        expect(_searchFocusNode(tester).hasFocus, isTrue);
        expect(
          find.text(
            'Search enrolled students by name or EMIS, including students without generated fees.',
          ),
          findsOneWidget,
        );
      }, () => MockClient(fixture.call));
    },
  );

  testWidgets(
    'changing the academic year re-searches immediately, bypassing the debounce',
    (tester) async {
      _phone(tester, const Size(390, 844));
      final fixture = FinanceFixture();
      await http.runWithClient(() async {
        await _openCollectPayment(tester, fixture);
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Amina');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(
          fixture.requests.where((r) => r.url.path.endsWith('/students')),
          hasLength(1),
        );

        final selector = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'AdminFilterDropdown<int>',
        );
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(find.text('2025-2026').last);
        await tester.pumpAndSettle();
        expect(
          fixture.requests.where((r) => r.url.path.endsWith('/students')),
          hasLength(2),
        );
      }, () => MockClient(fixture.call));
    },
  );

  testWidgets(
    'selecting a result moves to the fee step (the search field is expected to go away)',
    (tester) async {
      _phone(tester, const Size(390, 844));
      final fixture = FinanceFixture();
      await http.runWithClient(() async {
        await _openCollectPayment(tester, fixture);
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Amina');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Amina Hassan'));
        await tester.pumpAndSettle();
        expect(find.text('Search student by name or EMIS'), findsNothing);
        expect(
          fixture.requests.any((r) => r.url.path.contains('/students/7/fees')),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }, () => MockClient(fixture.call));
    },
  );

  testWidgets(
    'disposing mid-debounce does not throw (setState after unmount)',
    (tester) async {
      _phone(tester, const Size(390, 844));
      final fixture = FinanceFixture();
      await http.runWithClient(() async {
        await _openCollectPayment(tester, fixture);
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Amina');
        // Navigate away before the debounce timer (250ms) fires.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(
          fixture.requests.where((r) => r.url.path.endsWith('/students')),
          isEmpty,
        );
      }, () => MockClient(fixture.call));
    },
  );
}
