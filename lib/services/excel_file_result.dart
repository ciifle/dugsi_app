import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:kobac/services/content_disposition.dart';

const String xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class ExcelFileResult {
  final Uint8List bytes;
  final String contentType;
  final String? filename;

  const ExcelFileResult(this.bytes, this.contentType, this.filename);
}

String? excelFilenameFromContentDisposition(String? value) =>
    contentDispositionFilenameWithExtension(value, '.xlsx');

/// Returns null unless the response is a genuine spreadsheet: HTTP 200, the
/// Open XML MIME type, and a zip container (`PK`) - never an error page or a
/// PDF that merely got an .xlsx name.
ExcelFileResult? excelFileResultFromResponse(http.Response response) {
  final contentType = response.headers['content-type'] ?? '';
  final bytes = response.bodyBytes;
  final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
  if (response.statusCode != 200 ||
      !contentType.toLowerCase().contains('spreadsheetml.sheet') ||
      !isZip) {
    return null;
  }
  return ExcelFileResult(
    Uint8List.fromList(bytes),
    contentType,
    excelFilenameFromContentDisposition(
      response.headers['content-disposition'],
    ),
  );
}
