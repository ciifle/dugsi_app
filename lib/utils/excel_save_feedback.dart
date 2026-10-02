import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/utils/download_helper.dart';

typedef ExcelSavePicker =
    Future<String?> Function({
      required Uint8List bytes,
      required String filename,
    });

String sanitizeExcelFilename(String value) {
  var name = value
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'[\/:*?"<>|]'), '-')
      .trim();
  name = name.replaceAll(RegExp(r'(\.xlsx)+$', caseSensitive: false), '');
  if (name.isEmpty) name = 'document';
  if (name.length > 120) name = name.substring(0, 120).trim();
  return '$name.xlsx';
}

Future<String?> _platformSavePicker({
  required Uint8List bytes,
  required String filename,
}) => FilePicker.platform.saveFile(
  dialogTitle: 'Save Excel file',
  fileName: filename,
  type: FileType.custom,
  allowedExtensions: const ['xlsx'],
  bytes: bytes,
);

/// Saves an Excel workbook the same way the app already saves the marks
/// export: web triggers a browser download (correct xlsx MIME type via
/// `downloadFile`), mobile/desktop opens the system save dialog.
///
/// Returns true once the file was handed to the browser / written to storage;
/// false when the user cancelled the save dialog or saving failed (a friendly
/// snackbar is shown for failures).
Future<bool> saveExcelWithFeedback(
  BuildContext context, {
  required Uint8List bytes,
  required String filename,
  ExcelSavePicker? picker,
  bool? isWeb,
}) async {
  final name = sanitizeExcelFilename(filename);
  try {
    if (isWeb ?? kIsWeb) {
      downloadFile(bytes, name);
      return true;
    }
    final location = await (picker ?? _platformSavePicker)(
      bytes: bytes,
      filename: name,
    );
    if (location == null) return false; // user cancelled
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel file saved successfully\nFilename: $name'),
          backgroundColor: const Color(0xFF5AB04B),
        ),
      );
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the Excel file. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
}
