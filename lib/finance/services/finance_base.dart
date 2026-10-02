import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/services/auth_provider.dart';

/// Resolves which base path to call for the finance endpoints depending on
/// the signed-in role: FINANCE users hit `/api/finance/*`, SCHOOL_ADMIN hits
/// the equivalent `/api/school-admin/finance/*` (same shared backend
/// service, only the auth chain differs). finance-users has no FINANCE
/// equivalent and is always school-admin scoped (see [kFinanceUsersBasePath]).
String financeBasePath(BuildContext context) {
  final role = context.read<AuthProvider>().user?.userRole;
  return role == UserRole.schoolAdmin
      ? 'api/school-admin/finance'
      : 'api/finance';
}

const String kFinanceUsersBasePath = 'api/school-admin/finance-users';

sealed class FinanceResult<T> {}

class FinanceSuccess<T> extends FinanceResult<T> {
  final T data;
  FinanceSuccess(this.data);
}

class FinanceError extends FinanceResult<Never> {
  final String message;
  final int? statusCode;
  final String? code;
  FinanceError(this.message, [this.statusCode, this.code]);
}

dynamic financeDecode(String body) {
  try {
    return body.isEmpty ? null : jsonDecode(body);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? financeMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// Extracts {message, code} from the flat error JSON the backend's global
/// error handler returns (`{message, ...details}`, e.g. `{message, code:
/// 'FINANCE_NOT_ENABLED'}`).
(String message, String? code) financeErrorInfo(
  http.Response response,
  String fallback,
) {
  final map = financeMap(financeDecode(response.body));
  final code = map?['code']?.toString();
  const messages = {
    'FINANCE_NOT_ENABLED': 'Finance is not enabled for this school.',
    'PAYMENT_EXCEEDS_BALANCE': 'Payment amount exceeds the remaining balance.',
    'FEE_ALREADY_PAID': 'This fee has already been fully paid.',
    'FINANCE_USER_HAS_PAYMENT_HISTORY': 'This finance user cannot be deleted because they have recorded payment history.',
    'TERM_UNSUPPORTED': 'Term billing is not currently available for this academic-year configuration.',
  };
  if (messages.containsKey(code)) return (messages[code]!, code);
  if (response.statusCode == 401) return ('Your session has expired. Please sign in again.', code);
  if (response.statusCode == 403) return ('You do not have permission to perform this action.', code);
  if (response.statusCode == 404) return ('This record could not be found. Refresh and try again.', code);
  if (response.statusCode >= 500) return (fallback, code);
  final message = map?['message'];
  // Do not expose database, stack, or implementation details to cashiers.
  if (message is String && message.length <= 240 &&
      !RegExp(r'SQL|Sequelize|Exception|stack|VARCHAR|constraint|column', caseSensitive: false).hasMatch(message)) {
    return (message, code);
  }
  return (response.statusCode == 409 ? 'This record changed or already exists. Refresh and try again.' : fallback, code);
}
