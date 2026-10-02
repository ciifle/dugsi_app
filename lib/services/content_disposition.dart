/// Extracts a safe file name from a `Content-Disposition` header.
///
/// The RFC 5987 form (`filename*=UTF-8''...`) wins over the plain
/// `filename="..."` form. Path separators and control characters are replaced
/// so the result can never escape the download folder. Returns null when the
/// header carries no usable name.
String? contentDispositionFilename(String? header) {
  if (header == null) return null;
  String? raw;
  final extended = RegExp(
    r"filename\*\s*=\s*[\w-]*'[^']*'([^;]+)",
    caseSensitive: false,
  ).firstMatch(header);
  if (extended != null) raw = extended.group(1)?.trim();
  raw ??= RegExp(
    r'filename\s*=\s*"([^"]*)"',
    caseSensitive: false,
  ).firstMatch(header)?.group(1);
  raw ??= RegExp(
    r'filename\s*=\s*([^";\s]+)',
    caseSensitive: false,
  ).firstMatch(header)?.group(1);
  if (raw == null) return null;
  String decoded;
  try {
    decoded = Uri.decodeComponent(raw);
  } catch (_) {
    decoded = raw; // stray '%' in a plain filename
  }
  final clean = decoded
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
      .trim();
  return clean.isEmpty ? null : clean;
}

/// [contentDispositionFilename] forced to end in [extension] (e.g. `.pdf`).
String? contentDispositionFilenameWithExtension(
  String? header,
  String extension,
) {
  final name = contentDispositionFilename(header);
  if (name == null) return null;
  return name.toLowerCase().endsWith(extension) ? name : '$name$extension';
}
