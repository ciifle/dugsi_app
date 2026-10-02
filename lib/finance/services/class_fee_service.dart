import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

import 'package:kobac/finance/models/class_fee.dart';
import 'package:kobac/finance/services/finance_base.dart';

/// Not a singleton: the base path (`api/finance` vs
/// `api/school-admin/finance`) depends on the caller's role, so the shell
/// that mounts a Finance page constructs one instance with the resolved path.
class ClassFeeService {
  final ApiClient _client = ApiClient();
  final String basePath;
  ClassFeeService({required this.basePath});

  Future<FinanceResult<ClassFee>> get({required int classId, required int academicYearId}) async {
    try {
      final response = await _client.get(apiUrl('$basePath/class-fees/$classId?academic_year_id=$academicYearId'));
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(response, 'Could not load the class fee.');
        return FinanceError(message, response.statusCode, code);
      }
      final fee = financeMap(financeMap(financeDecode(response.body))?['classFee']);
      if (fee == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(ClassFee.fromJson(fee));
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'ClassFeeService.get'));
    }
  }

  Future<FinanceResult<List<ClassFee>>> list({
    required int academicYearId,
  }) async {
    try {
      final response = await _client.get(
        apiUrl('$basePath/class-fees?academic_year_id=$academicYearId'),
      );
      devLogResponse('ClassFeeService.list', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not load class fees.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw) ?? {};
      final classFees = (map['classFees'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ClassFee.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return FinanceSuccess(classFees);
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'ClassFeeService.list'));
    }
  }

  Future<FinanceResult<ClassFee>> upsert({
    required int classId,
    required int academicYearId,
    required num amount,
    String? billingCycle,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{
        'academic_year_id': academicYearId,
        'amount': amount,
      };
      if (billingCycle != null) body['billing_cycle'] = billingCycle;
      if (isActive != null) body['is_active'] = isActive;
      final response =
          await _client.put(apiUrl('$basePath/class-fees/$classId'), body: body);
      devLogResponse('ClassFeeService.upsert', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not save the class fee.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      final classFee = financeMap(map?['classFee']);
      if (classFee == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(ClassFee.fromJson(classFee));
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'ClassFeeService.upsert'));
    }
  }
}
