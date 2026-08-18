import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/school_admin/widgets/web_sidebar.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Classes submenu exposes and selects Class Merge', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    var selectedPage = 'dashboard';

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: WebSidebar(
                selectedPage: selectedPage,
                onNavigate: (page) => setState(() => selectedPage = page),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Class Merge'), findsNothing);
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();

    expect(find.text('All Classes'), findsOneWidget);
    expect(find.text('Class Merge'), findsOneWidget);

    await tester.tap(find.text('Class Merge'));
    await tester.pumpAndSettle();

    expect(selectedPage, 'classMerge');
    final semantics = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.text('Class Merge'),
            matching: find.byType(Semantics),
          ),
        )
        .firstWhere((widget) => widget.properties.selected != null);
    expect(semantics.properties.selected, isTrue);
    expect(find.text('Student Promotions'), findsOneWidget);
    semanticsHandle.dispose();
  });
}
