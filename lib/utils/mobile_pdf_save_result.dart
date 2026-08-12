enum MobileSaveStatus { saved, cancelled, failed }

class MobileSaveResult {
  final MobileSaveStatus status;
  final String? savedFilename;
  final String? savedLocationLabel;
  final String? errorMessage;

  const MobileSaveResult({
    required this.status,
    this.savedFilename,
    this.savedLocationLabel,
    this.errorMessage,
  });
}

String sanitizePdfFilename(String value) {
  var name = Uri.decodeComponent(value)
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
      .trim();
  name = name.replaceAll(RegExp(r'(\.pdf)+$', caseSensitive: false), '');
  if (name.isEmpty) name = 'document';
  if (name.length > 120) name = name.substring(0, 120).trim();
  return '$name.pdf';
}
