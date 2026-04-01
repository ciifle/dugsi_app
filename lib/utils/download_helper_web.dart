import 'dart:html' as html;

/// Web-only download helper to avoid compilation issues on mobile
void downloadFile(List<int> bytes, String filename) {
  // Create a blob from bytes
  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  
  // Create a temporary anchor element
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..style.display = 'none';
  
  // Add to DOM, click, and remove
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  
  // Clean up the object URL
  html.Url.revokeObjectUrl(url);
  
  print('DEBUG: Web download completed successfully');
}
