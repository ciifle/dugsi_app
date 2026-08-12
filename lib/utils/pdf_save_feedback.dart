import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/utils/mobile_pdf_save.dart';
import 'package:kobac/utils/mobile_pdf_save_result.dart';
import 'package:kobac/utils/student_pdf_handler.dart';

Future<void> savePdfWithFeedback(
  BuildContext context, {
  required Uint8List bytes,
  required String filename,
}) async {
  if (kIsWeb) {
    await downloadStudentPdf(bytes, filename);
    return;
  }

  final result = await saveMobilePdf(bytes: bytes, suggestedFilename: filename);
  if (!context.mounted || result.status == MobileSaveStatus.cancelled) return;
  if (result.status == MobileSaveStatus.saved) {
    final savedFilename = result.savedFilename;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedFilename == null
              ? 'PDF saved successfully'
              : 'PDF saved successfully\nFilename: $savedFilename',
        ),
        backgroundColor: const Color(0xFF5AB04B),
      ),
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.errorMessage ?? 'Could not save the PDF. Please try again.',
      ),
      backgroundColor: Colors.red,
    ),
  );
}
