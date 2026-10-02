import 'package:flutter/foundation.dart';

/// Debug-only terminal diagnostics for School Admin lesson attendance.
///
/// Nothing is printed in release builds. Request headers are never logged
/// (they carry the bearer token) and token/password/secret values inside
/// response bodies are redacted.
typedef AttendanceLogSink = void Function(String message);

/// Where diagnostics go. Tests replace this to capture output.
AttendanceLogSink attendanceLogSink = (message) =>
    debugPrint(message, wrapWidth: 1024);

/// Defaults to debug builds only; tests may flip it.
bool attendanceDiagnosticsEnabled = kDebugMode;

const int _maxBodyChars = 4000;

final RegExp _secretField = RegExp(
  r'"([A-Za-z_]*(?:token|password|secret|authorization)[A-Za-z_]*)"\s*:\s*"[^"]*"',
  caseSensitive: false,
);

/// Redacts secret-looking JSON fields and truncates very long bodies.
String safeAttendanceBody(String? body) {
  if (body == null || body.isEmpty) return '<empty>';
  var text = body.replaceAllMapped(_secretField, (m) => '"${m[1]}":"***"');
  if (text.length > _maxBodyChars) {
    text = '${text.substring(0, _maxBodyChars)}… (${body.length} chars total)';
  }
  return text;
}

void attendanceLog(String tag, Map<String, Object?> fields) {
  if (!attendanceDiagnosticsEnabled) return;
  final buffer = StringBuffer(tag);
  fields.forEach((key, value) {
    if (value == null) return;
    buffer.write('\n$key: $value');
  });
  attendanceLogSink(buffer.toString());
}

void logAttendanceRequest(
  String operation,
  String method,
  Uri url, {
  Map<String, Object?>? body,
}) => attendanceLog('[ADMIN ATTENDANCE REQUEST]', {
  'operation': operation,
  'endpoint': '$method ${url.path}',
  'parameters': url.queryParameters.isEmpty ? null : url.queryParameters,
  'body': body,
});

void logAttendanceResponse(String operation, int status, String body) =>
    attendanceLog('[ADMIN ATTENDANCE RESPONSE]', {
      'operation': operation,
      'status': status,
      'body': safeAttendanceBody(body),
    });

const String kAttendanceErrorTag = '[ADMIN ATTENDANCE ERROR]';
const String kReportTag = '[ADMIN ATTENDANCE REPORT]';
const String kReportErrorTag = '[ADMIN ATTENDANCE REPORT ERROR]';

void logAttendanceError({
  String tag = kAttendanceErrorTag,
  required String operation,
  String? endpoint,
  Map<String, String>? parameters,
  int? status,
  String? code,
  String? message,
  String? responseBody,
  Object? exception,
  StackTrace? stackTrace,
}) => attendanceLog(tag, {
  'Operation': operation,
  'Endpoint': endpoint,
  'Parameters': parameters,
  'HTTP': status,
  'Code': code,
  'Message': message,
  'Response': responseBody == null ? null : safeAttendanceBody(responseBody),
  'Exception': exception,
  'StackTrace': stackTrace,
});
