import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/pages/academic_years_page.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final active in [false, true]) {
      testWidgets(
        'academic year card fits its compact action row at ${width}px, active=$active',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final provider = AcademicYearsProvider();
          await http.runWithClient(
            () async {
              await provider.ensureLoaded();
              await tester.pumpWidget(
                ChangeNotifierProvider.value(
                  value: provider,
                  child: const MaterialApp(
                    home: Scaffold(body: AcademicYearsPage(embedBodyOnly: true)),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.text('2026-2027'), findsOneWidget);
              expect(find.text(active ? 'Active' : 'Inactive'), findsOneWidget);
              expect(find.text('Edit'), findsOneWidget);
              expect(
                find.text('Activate'),
                active ? findsNothing : findsOneWidget,
              );
              expect(find.text('Delete'), findsOneWidget);
              expect(tester.takeException(), isNull);
            },
            () => MockClient(
              (request) async {
                if (request.url.path.endsWith('/active')) {
                  return active
                      ? http.Response(
                          jsonEncode({
                            'academic_year': {
                              'id': 2,
                              'name': '2026-2027',
                              'is_active': 1,
                            },
                          }),
                          200,
                        )
                      : http.Response(jsonEncode({'message': 'none'}), 404);
                }
                return http.Response(
                  jsonEncode({
                    'academic_years': [
                      {'id': 2, 'name': '2026-2027', 'is_active': active ? 1 : 0},
                    ],
                  }),
                  200,
                );
              },
            ),
          );
          provider.dispose();
        },
      );
    }
  }
}
