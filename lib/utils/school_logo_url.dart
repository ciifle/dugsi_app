String? normalizeSchoolLogoUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return trimmed;
  if (uri.scheme.toLowerCase() == 'http' &&
      uri.host.toLowerCase() == 'api.dugsi.so') {
    return uri.replace(scheme: 'https').toString();
  }
  return trimmed;
}
