import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/school_admin/widgets/web_sidebar.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:provider/provider.dart';

/// Supported desktop navigation and retired Parents regression coverage.
void main() {
  Future<void> pump(WidgetTester tester, void Function(String) onNavigate) =>
      tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: WebSidebar(
                  selectedPage: 'dashboard',
                  onNavigate: onNavigate,
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('Students exposes supported routes without Parents', (
    tester,
  ) async {
    String? selectedPage;
    await pump(tester, (page) => selectedPage = page);

    expect(find.text('Parents'), findsNothing);
    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();

    expect(find.text('All Students'), findsOneWidget);
    expect(find.text('Parents'), findsNothing);

    await tester.tap(find.text('All Students'));
    await tester.pumpAndSettle();

    expect(selectedPage, 'students');
    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();
    expect(selectedPage, 'addStudent');
    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
    expect(find.text('All Students'), findsNothing);
  });

  testWidgets('Time Table submenu exposes and selects Periods', (tester) async {
    String? selectedPage;
    await pump(tester, (page) => selectedPage = page);

    expect(find.text('Periods'), findsNothing);
    await tester.ensureVisible(find.text('Time Table').first);
    await tester.tap(find.text('Time Table').first);
    await tester.pumpAndSettle();

    expect(find.text('Course Assign Teacher'), findsOneWidget);
    await tester.ensureVisible(find.text('Periods'));
    expect(find.text('Periods'), findsOneWidget);

    await tester.tap(find.text('Periods'));
    await tester.pumpAndSettle();

    expect(selectedPage, 'periods');
  });
}
