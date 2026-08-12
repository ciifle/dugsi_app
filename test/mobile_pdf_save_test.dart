import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/mobile_pdf_actions.dart';
import 'package:kobac/utils/mobile_pdf_save_io.dart';
import 'package:kobac/utils/mobile_pdf_save_result.dart';

void main() {
  test(
    'save picker receives PDF bytes and a sanitized editable filename',
    () async {
      Uint8List? receivedBytes;
      String? receivedFilename;
      final result = await saveMobilePdf(
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        suggestedFilename: r'class/marks?.PDF.pdf',
        picker: ({required bytes, required filename}) async {
          receivedBytes = bytes;
          receivedFilename = filename;
          return '/chosen/by-user/edited-name.pdf';
        },
      );

      expect(receivedBytes, [0x25, 0x50, 0x44, 0x46]);
      expect(receivedFilename, 'class-marks-.pdf');
      expect(result.status, MobileSaveStatus.saved);
    },
  );

  test('picker cancellation is cancelled rather than failed', () async {
    final result = await saveMobilePdf(
      bytes: Uint8List.fromList([1]),
      suggestedFilename: 'report.pdf',
      picker: ({required bytes, required filename}) async => null,
    );
    expect(result.status, MobileSaveStatus.cancelled);
    expect(result.errorMessage, isNull);
  });

  test('picker failure returns a readable failure', () async {
    final result = await saveMobilePdf(
      bytes: Uint8List.fromList([1]),
      suggestedFilename: 'report.pdf',
      picker: ({required bytes, required filename}) async {
        throw Exception('provider error');
      },
    );
    expect(result.status, MobileSaveStatus.failed);
    expect(result.errorMessage, 'Could not save the PDF. Please try again.');
  });

  test('PDF filename sanitizer preserves exactly one extension', () {
    expect(sanitizePdfFilename('report'), 'report.pdf');
    expect(sanitizePdfFilename('report.PDF.pdf'), 'report.pdf');
    expect(sanitizePdfFilename('../unsafe:name.pdf'), '..-unsafe-name.pdf');
    expect(
      sanitizePdfFilename('${'a' * 140}.pdf').length,
      lessThanOrEqualTo(124),
    );
  });

  test('mobile download does not use sharing and web handler is untouched', () {
    final mobile = File(
      'lib/utils/student_pdf_handler_mobile.dart',
    ).readAsStringSync();
    final save = File('lib/utils/mobile_pdf_save_io.dart').readAsStringSync();
    final web = File(
      'lib/utils/student_pdf_handler_web.dart',
    ).readAsStringSync();

    expect(mobile, isNot(contains('Printing.sharePdf')));
    expect(mobile, isNot(contains('Share.share')));
    expect(save, contains('FilePicker.platform.saveFile'));
    expect(save, contains("allowedExtensions: const ['pdf']"));
    expect(web, contains("html.Blob([bytes], 'application/pdf')"));
    expect(web, contains('html.AnchorElement'));
  });

  test('all four mobile forms use shared save feedback and action stack', () {
    for (final path in [
      'lib/school_admin/widgets/student_print_dialog.dart',
      'lib/school_admin/widgets/student_academic_report_dialog.dart',
      'lib/school_admin/widgets/class_roster_print_dialog.dart',
      'lib/school_admin/widgets/class_marks_print_dialog.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('savePdfWithFeedback'));
      expect(source, contains('MobilePdfActions'));
    }
  });

  testWidgets('mobile action stack fits a 320x640 viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MobilePdfActions(
              enabled: true,
              busy: false,
              previewLabel: 'Preview Marks Report',
              saveLabel: 'Save Marks Report',
              onPreview: () {},
              onSave: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Preview Marks Report'), findsOneWidget);
    expect(find.text('Save Marks Report'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
