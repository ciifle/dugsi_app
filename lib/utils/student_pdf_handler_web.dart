import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> previewStudentPdf(Uint8List bytes, String filename) async {
  final url = html.Url.createObjectUrlFromBlob(
    html.Blob([bytes], 'application/pdf'),
  );
  html.window.open(url, '_blank');
  Future<void>.delayed(
    const Duration(minutes: 2),
    () => html.Url.revokeObjectUrl(url),
  );
  return true;
}

Future<void> downloadStudentPdf(Uint8List bytes, String filename) async {
  final url = html.Url.createObjectUrlFromBlob(
    html.Blob([bytes], 'application/pdf'),
  );
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
    const Duration(seconds: 1),
    () => html.Url.revokeObjectUrl(url),
  );
}
