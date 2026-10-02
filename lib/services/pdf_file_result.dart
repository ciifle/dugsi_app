import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:kobac/services/content_disposition.dart';

class PdfFileResult {
  final Uint8List bytes;
  final String contentType;
  final String? filename;

  const PdfFileResult(this.bytes, this.contentType, this.filename);
}

String? pdfFilenameFromContentDisposition(String? value) =>
    contentDispositionFilenameWithExtension(value, '.pdf');

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
