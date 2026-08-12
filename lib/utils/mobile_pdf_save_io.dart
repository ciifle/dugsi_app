import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:kobac/utils/mobile_pdf_save_result.dart';

typedef MobilePdfSavePicker =
    Future<String?> Function({
      required Uint8List bytes,
      required String filename,
    });

Future<String?> _platformSavePicker({
  required Uint8List bytes,
  required String filename,
}) => FilePicker.platform.saveFile(
  dialogTitle: 'Save PDF',
  fileName: filename,
  type: FileType.custom,
  allowedExtensions: const ['pdf'],
  bytes: bytes,
);

Future<MobileSaveResult> saveMobilePdf({
  required Uint8List bytes,
  required String suggestedFilename,
  MobilePdfSavePicker? picker,
}) async {
  final filename = sanitizePdfFilename(suggestedFilename);
  try {
    final savedLocation = await (picker ?? _platformSavePicker)(
      bytes: bytes,
      filename: filename,
    );
    if (savedLocation == null) {
      return const MobileSaveResult(status: MobileSaveStatus.cancelled);
    }
    return const MobileSaveResult(status: MobileSaveStatus.saved);
  } catch (_) {
    return const MobileSaveResult(
      status: MobileSaveStatus.failed,
      errorMessage: 'Could not save the PDF. Please try again.',
    );
  }
}
