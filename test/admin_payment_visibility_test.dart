import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/school_admin/pages/school_admin_screen.dart';
import 'student_finance_test.dart' show FeatureAuth, StudentFixture, mount;

void main() {
  testWidgets('mobile admin payment quick actions disappear and reflow', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final auth = FeatureAuth();
    final f = StudentFixture();
    await http.runWithClient(() async {
      await mount(t, const SchoolAdminScreen(), auth);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Create Fee'), findsOneWidget);
      await t.ensureVisible(find.text('Finance'));
      expect(t.takeException(), isNull);
      auth.change(false);
      await t.pumpAndSettle();
      expect(find.text('Finance'), findsNothing);
      expect(find.text('Create Fee'), findsNothing);
      expect(find.text('Fees'), findsNothing);
      expect(find.text('Add Student'), findsOneWidget);
      expect(find.text('Add Teacher'), findsOneWidget);
      auth.change(true);
      await t.pumpAndSettle();
      expect(find.text('Finance'), findsOneWidget);
      expect(t.takeException(), isNull);
    }, () => MockClient(f.call));
  });
}
