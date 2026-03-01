import 'dart:async';

/// Converts technical errors to user-friendly messages.
/// Always prints the full error (and optional stackTrace) for developers in the terminal.
String userFriendlyMessage(
  Object error, [
  StackTrace? stackTrace,
  String? context,
]) {
  final prefix = context != null ? '[$context] ' : '';
  // Dev: print exact error so developers can debug
  print('$prefix API error (exact): $error');
  if (stackTrace != null) {
    print('$prefix StackTrace: $stackTrace');
  }

  final s = error.toString().toLowerCase();
  if (s.contains('socket') || s.contains('connection') || s.contains('clientexception') || s.contains('connection refused') || s.contains('network')) {
    return 'Cannot connect. Please check your internet connection and try again.';
  }
  if (error is TimeoutException || s.contains('timeout')) {
    return 'Request took too long. Please try again.';
  }
  if (s.contains('failed host lookup') || s.contains('nodata')) {
    return 'No internet connection. Please check your network and try again.';
  }
  if (s.contains('401') || s.contains('unauthorized')) {
    return 'Session expired. Please sign in again.';
  }
  if (s.contains('500') || s.contains('502') || s.contains('503') || s.contains('server')) {
    return 'Something went wrong on our side. Please try again later.';
  }
  // Generic fallback – user never sees raw exception
  return 'Something went wrong. Please try again.';
}

/// Log API response for developers (status + body).
void devLogResponse(String context, int statusCode, String body) {
  print('[$context] API response: status=$statusCode body=${body.length > 500 ? "${body.substring(0, 500)}..." : body}');
}
