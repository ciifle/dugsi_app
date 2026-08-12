import 'dart:typed_data';

import 'package:http/http.dart' as http;

class PdfFileResult {
  final Uint8List bytes;
  final String contentType;
  final String? filename;

  const PdfFileResult(this.bytes, this.contentType, this.filename);
}

String? pdfFilenameFromContentDisposition(String? value) {
  if (value == null) return null;
  final match = RegExp(
    r'''filename\*?=(?:UTF-8'')?["']?([^"';]+)''',
    caseSensitive: false,
  ).firstMatch(value);
  final raw = match?.group(1);
  if (raw == null) return null;
  final clean = Uri.decodeComponent(
    raw,
  ).replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();
  return clean.toLowerCase().endsWith('.pdf') ? clean : '$clean.pdf';
}

PdfFileResult? pdfFileResultFromResponse(http.Response response) {
  final contentType = response.headers['content-type'] ?? '';
  if (response.statusCode != 200 ||
      !contentType.toLowerCase().contains('application/pdf')) {
    return null;
  }
  return PdfFileResult(
    Uint8List.fromList(response.bodyBytes),
    contentType,
    pdfFilenameFromContentDisposition(response.headers['content-disposition']),
  );
}
