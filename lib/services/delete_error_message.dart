const deleteFailureMessage = 'Unable to delete this item. Please try again.';

/// Only display plain, useful application errors; never database diagnostics.
String safeDeleteError(Object? message) {
  if (message is! String || message.trim().isEmpty) return deleteFailureMessage;
  final text = message.trim();
  if (RegExp(
    r'foreign\s*key|constraint|\bsql\b|mysql|sequelize|unknown column|parent row|'
    r'ER_[A-Z_]+|sqlstate|stack\s*trace|<[^>]+>|\bat\s+\S+\s*\([^)]*:\d+|'
    r'exception|errno|syntax error',
    caseSensitive: false,
  ).hasMatch(text)) {
    return deleteFailureMessage;
  }
  return text;
}
