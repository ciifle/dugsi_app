import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/school_admin/widgets/export_timetable_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/excel_file_result.dart';
import 'package:provider/provider.dart';

class _SavePicker extends FilePicker {
  final List<MethodCall> saves;
  _SavePicker(this.saves);

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
    saves.add(MethodCall('save', {'fileName': fileName, 'bytes': bytes}));
    return '/downloads/$fileName';
  }
}

http.Response _pdf() => http.Response.bytes(
  utf8.encode('%PDF-1.4 timetable fixture'),
  200,
  headers: const {'content-type': 'application/pdf'},
);

http.Response _xlsx() => http.Response.bytes(
  const [0x50, 0x4B, 0x03, 0x04, 0x14, 0x00],
  200,
  headers: const {'content-type': xlsxMimeType},
);

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

MockClient _client(
  List<http.Request> requests, {
  http.Response Function(http.Request)? export,
  Future<http.Response>? pendingExport,
}) => MockClient((request) async {
  requests.add(request);
  final path = request.url.path;
  if (path.endsWith('/active')) {
    return _json({
      'academic_year': {'id': 7, 'name': '2026-2027', 'is_active': 1},
    });
  }
  if (path.endsWith('/academic-years')) {
    return _json({
      'academic_years': [
        {'id': 7, 'name': '2026-2027', 'is_active': 1},
        {'id': 6, 'name': '2025-2026', 'is_active': 0},
      ],
    });
  }
  if (path.endsWith('/teachers')) {
    return _json({
      'teachers': [
        {'id': 1, 'fullName': 'Amina Ali', 'email': 'amina@school.so'},
        {'id': 2, 'fullName': 'Ahmed Hassan', 'email': 'ahmed@school.so'},
      ],
    });
  }
  if (path.endsWith('/levels')) {
    return _json({
      'levels': [
        {'id': 3, 'name': 'Sare'},
        {'id': 4, 'name': 'Dhaxe Hoose'},
      ],
    });
  }
  if (path.contains('/timetables/')) {
    if (pendingExport != null) return pendingExport;
    if (export != null) return export(request);
    return path.endsWith('/export') ? _xlsx() : _pdf();
  }
  return _json({});
});

List<http.Request> _exports(List<http.Request> all) =>
    all.where((r) => r.url.path.contains('/timetables/')).toList();

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

bool _enabled(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(_button(label)).enabled;

Widget _host(AcademicYearsProvider provider) =>
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showExportTimetableDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final saves = <MethodCall>[];

  setUp(() {
    saves.clear();
    FilePicker.platform = _SavePicker(saves);
  });

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickDropdown(
    WidgetTester tester,
    int index,
    String label,
  ) async {
    final dropdown = find.byType(DropdownButtonFormField<int?>).at(index);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickTeacher(WidgetTester tester, String name) async {
    await tapText(tester, 'Search and select a teacher');
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  /// Runs [body] with the dialog open, inside a mocked HTTP client.
  Future<void> withDialog(
    WidgetTester tester,
    Future<void> Function(List<http.Request> requests) body, {
    Size size = const Size(1280, 900),
    http.Response Function(http.Request)? export,
    Future<http.Response>? pendingExport,
    FakeViewPadding? viewInsets,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    if (viewInsets != null) tester.view.viewInsets = viewInsets;
    addTearDown(tester.view.reset);
    final requests = <http.Request>[];
    final provider = AcademicYearsProvider();
    await http.runWithClient(() async {
      await provider.ensureLoaded();
      await tester.pumpWidget(_host(provider));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await body(requests);
    }, () => _client(requests, export: export, pendingExport: pendingExport));
    provider.dispose();
  }

  group('defaults and copy', () {
    testWidgets('opens as Class + PDF with the active academic year', (
      tester,
    ) async {
      await withDialog(tester, (_) async {
        expect(find.text('Export Timetable'), findsOneWidget);
        expect(find.text('Timetable Type'), findsOneWidget);
        expect(find.text('File Format'), findsOneWidget);
        expect(find.text('Class Timetable'), findsOneWidget);
        expect(find.text('Teacher Timetable'), findsOneWidget);
        // PDF description + Class level field (required, none chosen)
        expect(find.text('Ready-to-print timetable document.'), findsOneWidget);
        expect(find.text('Select Level *'), findsOneWidget);
        expect(find.text('Teacher *'), findsNothing);
        // Academic year shows its human name, active one preselected.
        expect(find.text('2026-2027'), findsOneWidget);
        expect(find.text('Academic Year *'), findsOneWidget);
        // No Excel-only note in PDF mode.
        expect(
          find.textContaining('will not update the timetable in Dugsi'),
          findsNothing,
        );
        expect(_enabled(tester, 'Download'), isFalse);
        expect(_enabled(tester, 'Cancel'), isTrue);
      });
    });

    testWidgets('Excel shows its description and the non-import note', (
      tester,
    ) async {
      await withDialog(tester, (_) async {
        await tapText(tester, 'Excel');
        expect(
          find.text(
            'Editable spreadsheet. You can make changes in Excel before printing.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Changes made in the downloaded Excel file will not update the timetable in Dugsi.',
          ),
          findsOneWidget,
        );
        expect(find.text('Ready-to-print timetable document.'), findsNothing);
        await tapText(tester, 'PDF');
        expect(find.text('Ready-to-print timetable document.'), findsOneWidget);
      });
    });

    testWidgets('there is exactly one Download and one Cancel action', (
      tester,
    ) async {
      await withDialog(tester, (_) async {
        expect(find.text('Download'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    });
  });

  group('class timetable', () {
    testWidgets('PDF requires a level and sends academic_year_id + level_id', (
      tester,
    ) async {
      await withDialog(tester, (requests) async {
        expect(_enabled(tester, 'Download'), isFalse);
        expect(find.text('All Levels'), findsNothing); // never offered for PDF
        await pickDropdown(tester, 1, 'Sare');
        expect(_enabled(tester, 'Download'), isTrue);
        await tapText(tester, 'Download');
        final sent = _exports(requests).single;
        expect(sent.url.path, '/api/school-admin/timetables/classes/print');
        expect(sent.url.queryParameters, {
          'academic_year_id': '7',
          'level_id': '3',
        });
        expect(sent.headers['Accept'], 'application/pdf');
        expect(saves.single.arguments['fileName'], endsWith('.pdf'));
      });
    });

    testWidgets('Excel works with only an academic year and omits level_id', (
      tester,
    ) async {
      await withDialog(tester, (requests) async {
        await tapText(tester, 'Excel');
        expect(find.text('All Levels'), findsOneWidget);
        expect(_enabled(tester, 'Download'), isTrue);
        await tapText(tester, 'Download');
        final sent = _exports(requests).single;
        expect(sent.url.path, '/api/school-admin/timetables/classes/export');
        expect(sent.url.queryParameters, {'academic_year_id': '7'});
        expect(sent.url.queryParameters.containsKey('level_id'), isFalse);
        expect(sent.headers['Accept'], xlsxMimeType);
        expect(
          saves.single.arguments['fileName'],
          'Dugsi_Class_Timetable_2026-2027.xlsx',
        );
      });
    });

    testWidgets('Excel supports a specific level', (tester) async {
      await withDialog(tester, (requests) async {
        await tapText(tester, 'Excel');
        await pickDropdown(tester, 1, 'Dhaxe Hoose');
        await tapText(tester, 'Download');
        expect(_exports(requests).single.url.queryParameters, {
          'academic_year_id': '7',
          'level_id': '4',
        });
        expect(
          saves.single.arguments['fileName'],
          'Dugsi_Class_Timetable_Dhaxe_Hoose_2026-2027.xlsx',
        );
      });
    });

    testWidgets('a specific level survives PDF <-> Excel', (tester) async {
      await withDialog(tester, (_) async {
        await pickDropdown(tester, 1, 'Sare');
        await tapText(tester, 'Excel');
        expect(find.text('Sare'), findsOneWidget);
        expect(find.text('All Levels'), findsNothing);
        await tapText(tester, 'PDF');
        expect(find.text('Sare'), findsOneWidget);
        expect(_enabled(tester, 'Download'), isTrue);
      });
    });

    testWidgets(
      'Excel + All Levels then PDF asks for a level instead of guessing one',
      (tester) async {
        await withDialog(tester, (requests) async {
          await tapText(tester, 'Excel');
          expect(_enabled(tester, 'Download'), isTrue);
          await tapText(tester, 'PDF');
          expect(find.text('Select Level *'), findsOneWidget);
          expect(_enabled(tester, 'Download'), isFalse);
          await tester.tap(find.text('Download'), warnIfMissed: false);
          await tester.pump();
          expect(_exports(requests), isEmpty);
        });
      },
    );
  });

  group('teacher timetable', () {
    testWidgets('hides Level and shows the teacher field', (tester) async {
      await withDialog(tester, (_) async {
        await tapText(tester, 'Teacher Timetable');
        expect(find.text('Teacher *'), findsOneWidget);
        expect(find.text('Select Level *'), findsNothing);
        expect(find.text('Level'), findsNothing);
        expect(find.byType(DropdownButtonFormField<int?>), findsOneWidget);
      });
    });

    for (final excel in [false, true]) {
      testWidgets(
        'Teacher ${excel ? 'Excel' : 'PDF'} requires a teacher and sends no level_id',
        (tester) async {
          await withDialog(tester, (requests) async {
            await tapText(tester, 'Teacher Timetable');
            if (excel) await tapText(tester, 'Excel');
            expect(_enabled(tester, 'Download'), isFalse);
            await pickTeacher(tester, 'Ahmed Hassan');
            expect(_enabled(tester, 'Download'), isTrue);
            await tapText(tester, 'Download');
            final sent = _exports(requests).single;
            expect(
              sent.url.path,
              '/api/school-admin/timetables/teachers/2/${excel ? 'export' : 'print'}',
            );
            expect(sent.url.queryParameters, {'academic_year_id': '7'});
            expect(
              saves.single.arguments['fileName'],
              'Dugsi_Teacher_Timetable_Ahmed_Hassan_2026-2027.${excel ? 'xlsx' : 'pdf'}',
            );
          });
        },
      );
    }

    testWidgets('teacher list is searchable by name', (tester) async {
      await withDialog(tester, (_) async {
        await tapText(tester, 'Teacher Timetable');
        await tapText(tester, 'Search and select a teacher');
        expect(find.text('Amina Ali'), findsOneWidget);
        expect(find.text('Ahmed Hassan'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'ahm');
        await tester.pumpAndSettle();
        expect(find.text('Amina Ali'), findsNothing);
        expect(find.text('Ahmed Hassan'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'zzz');
        await tester.pumpAndSettle();
        expect(find.text('No teachers match your search.'), findsOneWidget);
      });
    });

    testWidgets('teacher selection survives format and type switches', (
      tester,
    ) async {
      await withDialog(tester, (_) async {
        await tapText(tester, 'Teacher Timetable');
        await pickTeacher(tester, 'Amina Ali');
        await tapText(tester, 'Excel');
        expect(find.text('Amina Ali'), findsOneWidget);
        await tapText(tester, 'Class Timetable');
        await tapText(tester, 'Teacher Timetable');
        expect(find.text('Amina Ali'), findsOneWidget);
        expect(_enabled(tester, 'Download'), isTrue);
      });
    });

    testWidgets('a failed teacher load shows Retry, not a silent empty list', (
      tester,
    ) async {
      var fail = true;
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final provider = AcademicYearsProvider();
      await http.runWithClient(
        () async {
          await provider.ensureLoaded();
          await tester.pumpWidget(_host(provider));
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tapText(tester, 'Teacher Timetable');
          expect(find.text('Retry'), findsOneWidget);
          expect(find.text('Could not load teachers.'), findsOneWidget);
          fail = false;
          await tapText(tester, 'Retry');
          expect(find.text('Search and select a teacher'), findsOneWidget);
        },
        () => MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/teachers')) {
            return fail
                ? _json({'message': 'Could not load teachers.'}, 500)
                : _json({
                    'teachers': [
                      {'id': 1, 'fullName': 'Amina Ali'},
                    ],
                  });
          }
          if (path.endsWith('/active')) {
            return _json({
              'academic_year': {'id': 7, 'name': '2026-2027', 'is_active': 1},
            });
          }
          if (path.endsWith('/academic-years')) {
            return _json({
              'academic_years': [
                {'id': 7, 'name': '2026-2027', 'is_active': 1},
              ],
            });
          }
          return _json({'levels': []});
        }),
      );
      provider.dispose();
    });
  });

  group('academic year', () {
    testWidgets('survives type and format switches and is what is sent', (
      tester,
    ) async {
      await withDialog(tester, (requests) async {
        await pickDropdown(tester, 0, '2025-2026');
        await tapText(tester, 'Excel');
        await tapText(tester, 'Teacher Timetable');
        await tapText(tester, 'PDF');
        await tapText(tester, 'Class Timetable');
        expect(find.text('2025-2026'), findsOneWidget);
        await tapText(tester, 'Excel');
        await tapText(tester, 'Download');
        expect(_exports(requests).single.url.queryParameters, {
          'academic_year_id': '6',
        });
      });
    });
  });

  group('download lifecycle', () {
    testWidgets('loading state blocks a second request; success closes', (
      tester,
    ) async {
      final pending = Completer<http.Response>();
      await withDialog(tester, (requests) async {
        await tapText(tester, 'Excel');
        await tester.tap(find.text('Download'));
        await tester.pump();
        expect(find.text('Downloading...'), findsOneWidget);
        expect(_enabled(tester, 'Downloading...'), isFalse);
        expect(_enabled(tester, 'Cancel'), isFalse);
        await tester.tap(find.text('Downloading...'), warnIfMissed: false);
        await tester.pump();
        expect(_exports(requests), hasLength(1));
        pending.complete(_xlsx());
        await tester.pumpAndSettle();
        expect(_exports(requests), hasLength(1));
        expect(find.text('Export Timetable'), findsNothing); // closed
        expect(saves, hasLength(1));
      }, pendingExport: pending.future);
    });

    final failures = <String, (int, Map<String, String>, String)>{
      '400': (
        400,
        {'message': 'Please select a level.'},
        'Please select a level.',
      ),
      '404': (
        404,
        {'message': 'No timetable entries were found for this selection.'},
        'No timetable entries were found for this selection.',
      ),
      '409': (
        409,
        {'message': 'No periods are configured for this timetable.'},
        'No periods are configured for this timetable.',
      ),
      '500 with SQL noise': (
        500,
        {'message': 'ER_BAD_FIELD_ERROR: Unknown column x'},
        'Could not export the timetable. Please try again.',
      ),
    };
    failures.forEach((name, spec) {
      testWidgets('$name shows a clean message and restores Download', (
        tester,
      ) async {
        await withDialog(tester, (requests) async {
          await tapText(tester, 'Excel');
          await tapText(tester, 'Download');
          expect(find.text(spec.$3), findsOneWidget);
          expect(find.textContaining('Exception'), findsNothing);
          expect(find.textContaining('ER_'), findsNothing);
          expect(_enabled(tester, 'Download'), isTrue);
          expect(find.text('Export Timetable'), findsOneWidget); // still open
          expect(saves, isEmpty);
        }, export: (_) => _json(spec.$2, spec.$1));
      });
    });

    testWidgets('an HTML page with status 200 is never saved as a file', (
      tester,
    ) async {
      await withDialog(
        tester,
        (_) async {
          await tapText(tester, 'Excel');
          await tapText(tester, 'Download');
          expect(
            find.text('Could not export the timetable. Please try again.'),
            findsOneWidget,
          );
          expect(_enabled(tester, 'Download'), isTrue);
          expect(saves, isEmpty);
        },
        export: (_) => http.Response(
          '<html>login</html>',
          200,
          headers: const {'content-type': 'text/html'},
        ),
      );
    });

    testWidgets('a network failure is friendly and recoverable', (
      tester,
    ) async {
      await withDialog(tester, (_) async {
        await tapText(tester, 'Excel');
        await tapText(tester, 'Download');
        expect(find.textContaining('Cannot connect'), findsOneWidget);
        expect(find.textContaining('ClientException'), findsNothing);
        expect(_enabled(tester, 'Download'), isTrue);
      }, export: (_) => throw http.ClientException('connection refused'));
    });

    testWidgets('changing a selection clears the previous error', (
      tester,
    ) async {
      await withDialog(tester, (_) async {
        await tapText(tester, 'Excel');
        await tapText(tester, 'Download');
        expect(find.textContaining('Could not export'), findsOneWidget);
        await tapText(tester, 'PDF');
        expect(find.textContaining('Could not export'), findsNothing);
      }, export: (_) => _json({}, 500));
    });
  });

  group('responsive layout', () {
    const sizes = <String, Size>{
      'desktop 1440': Size(1440, 900),
      'desktop 1280': Size(1280, 800),
      'desktop 1130': Size(1130, 780),
      'desktop 960': Size(960, 700),
      'mobile 360x800': Size(360, 800),
      'mobile 390x844': Size(390, 844),
      'mobile 412x915': Size(412, 915),
    };
    sizes.forEach((name, size) {
      testWidgets('$name: no overflow in any mode', (tester) async {
        await withDialog(tester, (_) async {
          expect(tester.takeException(), isNull);
          await tapText(tester, 'Excel');
          expect(tester.takeException(), isNull);
          await pickDropdown(tester, 1, 'Dhaxe Hoose');
          expect(tester.takeException(), isNull);
          await tapText(tester, 'Teacher Timetable');
          await pickTeacher(tester, 'Ahmed Hassan');
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(Dialog).first).width,
            lessThanOrEqualTo(size.width),
          );
        }, size: size);
      });
    });

    testWidgets('short phone with keyboard open keeps actions reachable', (
      tester,
    ) async {
      await withDialog(
        tester,
        (_) async {
          await tapText(tester, 'Teacher Timetable');
          await tapText(tester, 'Search and select a teacher');
          await tester.enterText(find.byType(TextField), 'a');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Ahmed Hassan').last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Download'), findsOneWidget);
          expect(
            tester.getRect(find.text('Download')).bottom,
            lessThanOrEqualTo(640),
          );
        },
        size: const Size(360, 640),
        viewInsets: const FakeViewPadding(bottom: 280),
      );
    });
  });

  group('timetableExportFallbackName', () {
    test('matches the documented examples', () {
      expect(
        timetableExportFallbackName(
          teacher: false,
          yearName: '2026-2027',
          extension: 'pdf',
        ),
        'Dugsi_Class_Timetable_2026-2027.pdf',
      );
      expect(
        timetableExportFallbackName(
          teacher: true,
          subject: 'Ahmed Ali',
          yearName: '2026-2027',
          extension: 'xlsx',
        ),
        'Dugsi_Teacher_Timetable_Ahmed_Ali_2026-2027.xlsx',
      );
    });

    test('strips path characters', () {
      expect(
        timetableExportFallbackName(
          teacher: true,
          subject: '../Ali/Ahmed:?',
          yearName: '2026/2027',
          extension: 'pdf',
        ),
        'Dugsi_Teacher_Timetable_..AliAhmed_20262027.pdf',
      );
    });
  });
}
