import 'dart:html' as html;

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Web-only download helper (kept out of mobile builds via the conditional
/// export in download_helper.dart). Triggers a browser download of an Excel
/// workbook without navigating away or opening a tab.
void downloadFile(List<int> bytes, String filename) {
  final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes], _xlsxMime));
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Revoking synchronously can cancel the download in some browsers.
  Future<void>.delayed(
    const Duration(seconds: 1),
    () => html.Url.revokeObjectUrl(url),
  );
}
