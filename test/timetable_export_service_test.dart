import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/content_disposition.dart';
import 'package:kobac/services/excel_file_result.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/services/timetables_service.dart';
import 'package:kobac/utils/excel_save_feedback.dart';

http.Response _pdf({String? disposition}) => http.Response.bytes(
  utf8.encode('%PDF-1.4 fixture'),
  200,
  headers: {
    'content-type': 'application/pdf',
    if (disposition != null) 'content-disposition': disposition,
  },
);

http.Response _xlsx({String? disposition}) => http.Response.bytes(
  const [0x50, 0x4B, 0x03, 0x04, 0x14, 0x00],
  200,
  headers: {
    'content-type': xlsxMimeType,
    if (disposition != null) 'content-disposition': disposition,
  },
);

Future<T> _with<T>(
  Future<http.Response> Function(http.Request) handler,
  Future<T> Function() body,
) => http.runWithClient(body, () => MockClient(handler));

String _message(Object result) => (result as TimetableError).message;

void main() {
  final service = TimetablesService();

  group('request generation', () {
    Future<http.Request> capture(
      Future<Object?> Function() call,
      http.Response response,
    ) async {
      late http.Request seen;
      await _with((r) async {
        seen = r;
        return response;
      }, call);
      return seen;
    }

    test('Class PDF', () async {
      final r = await capture(
        () => service.getClassesTimetablePrintPdf(
          academicYearId: 7,
          levelId: 3,
        ),
        _pdf(),
      );
      expect(r.method, 'GET');
      expect(r.url.path, '/api/school-admin/timetables/classes/print');
      expect(r.url.queryParameters, {'academic_year_id': '7', 'level_id': '3'});
      expect(r.headers['Accept'], 'application/pdf');
    });

    test('Class Excel, all levels: no level_id', () async {
      final r = await capture(
        () => service.getClassesTimetableExcel(academicYearId: 7),
        _xlsx(),
      );
      expect(r.url.path, '/api/school-admin/timetables/classes/export');
      expect(r.url.queryParameters, {'academic_year_id': '7'});
      expect(r.headers['Accept'], xlsxMimeType);
    });

    test('Class Excel, specific level', () async {
      final r = await capture(
        () => service.getClassesTimetableExcel(academicYearId: 7, levelId: 4),
        _xlsx(),
      );
      expect(r.url.path, '/api/school-admin/timetables/classes/export');
      expect(r.url.queryParameters, {'academic_year_id': '7', 'level_id': '4'});
    });

    test('Teacher PDF: no level_id, no shift', () async {
      final r = await capture(
        () => service.getTeacherTimetablePrintPdf(
          teacherId: 12,
          academicYearId: 7,
        ),
        _pdf(),
      );
      expect(r.url.path, '/api/school-admin/timetables/teachers/12/print');
      expect(r.url.queryParameters, {'academic_year_id': '7'});
    });

    test('Teacher Excel: no level_id', () async {
      final r = await capture(
        () => service.getTeacherTimetableExcel(teacherId: 12, academicYearId: 7),
        _xlsx(),
      );
      expect(r.url.path, '/api/school-admin/timetables/teachers/12/export');
      expect(r.url.queryParameters, {'academic_year_id': '7'});
    });

    test('uses the configured API base URL and the shared bearer token', () async {
      ApiClient().setToken('secret-token');
      addTearDown(() => ApiClient().setToken(null));
      final r = await capture(
        () => service.getTeacherTimetableExcel(teacherId: 1, academicYearId: 7),
        _xlsx(),
      );
      expect(r.url.origin, apiUrl('x').origin);
      expect(r.headers['Authorization'], 'Bearer secret-token');
    });
  });

  group('successful responses', () {
    test('return bytes and the server filename', () async {
      final result = await _with(
        (_) async =>
            _xlsx(disposition: 'attachment; filename="Dugsi_Class_2026.xlsx"'),
        () => service.getClassesTimetableExcel(academicYearId: 7),
      );
      final file = (result as TimetableSuccess<ExcelFileResult>).data;
      expect(file.filename, 'Dugsi_Class_2026.xlsx');
      expect(file.bytes.take(2), [0x50, 0x4B]);
    });

    test('PDF result carries its filename', () async {
      final result = await _with(
        (_) async => _pdf(disposition: 'attachment; filename="t.pdf"'),
        () => service.getTeacherTimetablePrintPdf(
          teacherId: 1,
          academicYearId: 7,
        ),
      );
      expect((result as TimetableSuccess<PdfFileResult>).data.filename, 't.pdf');
    });
  });

  group('failures', () {
    Future<String> classPdf(http.Response response) async => _message(
      await _with(
        (_) async => response,
        () => service.getClassesTimetablePrintPdf(
          academicYearId: 7,
          levelId: 3,
          levelLabel: 'Sare',
        ),
      ),
    );
    Future<String> classExcel(http.Response response) async => _message(
      await _with(
        (_) async => response,
        () => service.getClassesTimetableExcel(academicYearId: 7),
      ),
    );

    test('400 uses a backend message when clean, else a generic one', () async {
      expect(
        await classExcel(
          http.Response(jsonEncode({'message': 'Please select a level.'}), 400),
        ),
        'Please select a level.',
      );
      expect(
        await classExcel(http.Response('', 400)),
        'Please check your selection and try again.',
      );
    });

    test('401 tells the app to sign out and shows a session message', () async {
      var signedOut = 0;
      onUnauthorized = () => signedOut++;
      addTearDown(() => onUnauthorized = null);
      expect(
        await classExcel(http.Response('', 401)),
        'Your session has expired. Please sign in again.',
      );
      expect(signedOut, 1);
    });

    test('403', () async {
      expect(
        await classExcel(http.Response('', 403)),
        'School administrator access is required.',
      );
    });

    test('404', () async {
      expect(
        await classExcel(http.Response('', 404)),
        'No timetable entries were found for this selection.',
      );
    });

    test('409 (Excel/teacher: periods; class PDF: shift mismatch)', () async {
      expect(
        await classExcel(http.Response('', 409)),
        'No periods are configured for this timetable.',
      );
      expect(
        await classPdf(http.Response('', 409)),
        "Sare classes could not be matched to a single shift. Check each class's shift assignment and try again.",
      );
    });

    test('500 never leaks SQL, HTML or JSON', () async {
      for (final body in [
        jsonEncode({'message': 'ER_BAD_FIELD_ERROR: Unknown column'}),
        '<html><body>Bad gateway</body></html>',
        jsonEncode({'error': 'SequelizeDatabaseError: constraint failed'}),
        '',
      ]) {
        expect(
          await classExcel(http.Response(body, 500)),
          'Could not export the timetable. Please try again.',
        );
      }
    });

    test('network failure', () async {
      final result = await _with(
        (_) async => throw http.ClientException('connection refused'),
        () => service.getClassesTimetableExcel(academicYearId: 7),
      );
      expect(
        _message(result),
        'Cannot connect. Please check your internet connection and try again.',
      );
    });

    test('timeout', () async {
      final result = await _with(
        (_) async => throw TimeoutException('slow'),
        () => service.getTeacherTimetablePrintPdf(
          teacherId: 1,
          academicYearId: 7,
        ),
      );
      expect(_message(result), 'Request took too long. Please try again.');
    });

    test('HTML/JSON/wrong type with status 200 is rejected, never saved', () async {
      const generic = 'Could not export the timetable. Please try again.';
      expect(
        await classExcel(
          http.Response(
            '<html>login</html>',
            200,
            headers: const {'content-type': 'text/html'},
          ),
        ),
        generic,
      );
      expect(await classExcel(_pdf()), generic); // PDF served for an xlsx call
      expect(
        await classPdf(
          http.Response(
            '{"ok":true}',
            200,
            headers: const {'content-type': 'application/json'},
          ),
        ),
        generic,
      );
      // Claims to be a PDF but is not one.
      expect(
        await classPdf(
          http.Response.bytes(
            utf8.encode('<html>proxy error</html>'),
            200,
            headers: const {'content-type': 'application/pdf'},
          ),
        ),
        generic,
      );
    });
  });

  group('Content-Disposition', () {
    test('quoted filename keeps a correct extension', () {
      expect(
        excelFilenameFromContentDisposition(
          'attachment; filename="Dugsi_Class_Timetable_2026-2027.xlsx"',
        ),
        'Dugsi_Class_Timetable_2026-2027.xlsx',
      );
      expect(
        pdfFilenameFromContentDisposition(
          'attachment; filename="Dugsi_Class_Timetable_2026-2027.pdf"',
        ),
        'Dugsi_Class_Timetable_2026-2027.pdf',
      );
    });

    test('RFC 5987 filename* is decoded and preferred', () {
      expect(
        excelFilenameFromContentDisposition(
          "attachment; filename=\"fallback.xlsx\"; filename*=UTF-8''Dugsi%20Teacher%20Ahmed.xlsx",
        ),
        'Dugsi Teacher Ahmed.xlsx',
      );
      expect(
        excelFilenameFromContentDisposition(
          "attachment; filename*=UTF-8''Dugsi_Timetable_%C3%A7.xlsx",
        ),
        'Dugsi_Timetable_ç.xlsx',
      );
    });

    test('adds the missing extension and strips path characters', () {
      expect(
        excelFilenameFromContentDisposition('attachment; filename="a/b:c"'),
        'a-b-c.xlsx',
      );
      expect(
        pdfFilenameFromContentDisposition('attachment; filename=timetable'),
        'timetable.pdf',
      );
      expect(
        excelFilenameFromContentDisposition(
          'attachment; filename="../../etc/passwd"',
        ),
        '..-..-etc-passwd.xlsx',
      );
    });

    test('missing, empty or malformed headers yield null instead of throwing', () {
      expect(contentDispositionFilename(null), isNull);
      expect(contentDispositionFilename('attachment'), isNull);
      expect(contentDispositionFilename('attachment; filename=""'), isNull);
      expect(contentDispositionFilename('attachment; filename="100%.xlsx"'), '100%.xlsx');
    });
  });

  group('excelFileResultFromResponse', () {
    test('accepts a real xlsx response', () {
      final result = excelFileResultFromResponse(_xlsx());
      expect(result, isNotNull);
      expect(result!.bytes.take(2).toList(), [0x50, 0x4B]);
    });

    test('rejects a PDF, an error status, or a non-zip body', () {
      expect(excelFileResultFromResponse(_pdf()), isNull);
      expect(
        excelFileResultFromResponse(
          http.Response.bytes(
            const [0x50, 0x4B, 3, 4, 5],
            404,
            headers: const {'content-type': xlsxMimeType},
          ),
        ),
        isNull,
      );
      expect(
        excelFileResultFromResponse(
          http.Response.bytes(
            const [1, 2, 3, 4, 5],
            200,
            headers: const {'content-type': xlsxMimeType},
          ),
        ),
        isNull,
      );
    });

    test('the download MIME type is the Open XML spreadsheet type', () {
      expect(
        xlsxMimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    });
  });

  group('saveExcelWithFeedback', () {
    Future<BuildContext> pumpContext(WidgetTester tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return captured;
    }

    final bytes = Uint8List.fromList(const [0x50, 0x4B, 3, 4]);

    testWidgets('mobile: saves via the picker with an .xlsx name', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      String? pickedName;
      final saved = await saveExcelWithFeedback(
        context,
        bytes: bytes,
        filename: 'Dugsi_Timetable_2026-2027',
        isWeb: false,
        picker: ({required bytes, required filename}) async {
          pickedName = filename;
          return '/storage/$filename';
        },
      );
      await tester.pump();
      expect(saved, isTrue);
      expect(pickedName, 'Dugsi_Timetable_2026-2027.xlsx');
      expect(
        find.textContaining('Excel file saved successfully'),
        findsOneWidget,
      );
    });

    testWidgets('cancelling the save dialog shows nothing and reports false', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      final saved = await saveExcelWithFeedback(
        context,
        bytes: bytes,
        filename: 'x.xlsx',
        isWeb: false,
        picker: ({required bytes, required filename}) async => null,
      );
      await tester.pump();
      expect(saved, isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a failing picker shows a friendly error', (tester) async {
      final context = await pumpContext(tester);
      final saved = await saveExcelWithFeedback(
        context,
        bytes: bytes,
        filename: 'x.xlsx',
        isWeb: false,
        picker: ({required bytes, required filename}) async =>
            throw Exception('disk full'),
      );
      await tester.pump();
      expect(saved, isFalse);
      expect(
        find.text('Could not save the Excel file. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('disk full'), findsNothing);
    });

    testWidgets('web uses the browser download path, not the file picker', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      var pickerCalled = false;
      final saved = await saveExcelWithFeedback(
        context,
        bytes: bytes,
        filename: 'x.xlsx',
        isWeb: true,
        picker: ({required bytes, required filename}) async {
          pickerCalled = true;
          return 'x';
        },
      );
      expect(pickerCalled, isFalse);
      expect(saved, isTrue);
    });

    test('filename sanitising always yields a single .xlsx extension', () {
      expect(sanitizeExcelFilename('a.xlsx.xlsx'), 'a.xlsx');
      expect(sanitizeExcelFilename('bad/name?.xlsx'), 'bad-name-.xlsx');
      expect(sanitizeExcelFilename(''), 'document.xlsx');
    });
  });
}
