import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

import 'package:kobac/finance/models/finance_user.dart';
import 'package:kobac/finance/services/finance_base.dart';

class FinanceUserPage {
  final List<FinanceUser> users;
  final int page;
  final int limit;
  final int total;
  const FinanceUserPage({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
  });
}

/// School Admin only — manages FINANCE-role accounts for their own school.
/// GET/POST /api/school-admin/finance-users, PATCH/DELETE .../{id}.
class FinanceUserService {
  final ApiClient _client = ApiClient();
  static const _base = kFinanceUsersBasePath;

  Future<FinanceResult<FinanceUserPage>> list({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get(
        apiUrl('$_base?page=$page&limit=$limit'),
      );
      devLogResponse('FinanceUserService.list', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not load finance users.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw) ?? {};
      final pagination = financeMap(map['pagination']) ?? {};
      final users = (map['financeUsers'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => FinanceUser.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return FinanceSuccess(
        FinanceUserPage(
          users: users,
          page: (pagination['page'] as num?)?.toInt() ?? page,
          limit: (pagination['limit'] as num?)?.toInt() ?? limit,
          total: (pagination['total'] as num?)?.toInt() ?? users.length,
        ),
      );
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'FinanceUserService.list'));
    }
  }

  Future<FinanceResult<FinanceUser>> getById(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(response, 'Could not load finance user.');
        return FinanceError(message, response.statusCode, code);
      }
      final user = financeMap(financeMap(financeDecode(response.body))?['financeUser']);
      if (user == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinanceUser.fromJson(user));
    } catch (e, st) { return FinanceError(userFriendlyMessage(e, st, 'FinanceUserService.getById')); }
  }

  Future<FinanceResult<FinanceUser>> create({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        apiUrl(_base),
        body: {'name': name, 'email': email, 'password': password},
      );
      devLogResponse('FinanceUserService.create', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 201) {
        final (message, code) =
            financeErrorInfo(response, 'Could not create finance user.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      final userMap = financeMap(map?['financeUser']);
      if (userMap == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinanceUser.fromJson(userMap));
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'FinanceUserService.create'));
    }
  }

  Future<FinanceResult<FinanceUser>> update(
    int id, {
    String? name,
    String? email,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null && password.isNotEmpty) body['password'] = password;
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('FinanceUserService.update', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not update finance user.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      final userMap = financeMap(map?['financeUser']);
      if (userMap == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinanceUser.fromJson(userMap));
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'FinanceUserService.update'));
    }
  }

  /// On 409 with code FINANCE_USER_HAS_PAYMENT_HISTORY, [FinanceError.message]
  /// is already the exact backend message to show the user.
  Future<FinanceResult<bool>> delete(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('FinanceUserService.delete', response.statusCode, response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not delete finance user.');
        return FinanceError(message, response.statusCode, code);
      }
      return FinanceSuccess(true);
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'FinanceUserService.delete'));
    }
  }
}
