import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/models/finance_dashboard.dart';
import 'package:kobac/finance/services/finance_base.dart';

class FeeLedgerService {
  final ApiClient _client = ApiClient();
  final String basePath;
  FeeLedgerService({required this.basePath});

  Future<FinanceResult<FinanceFeeLedgerPage>> listFees({
    required int academicYearId,
    int? classId,
    int? studentId,
    String? status,
    String? billingCycle,
    int? billingYear,
    int? billingMonth,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final query = <String, String>{
        'academic_year_id': '$academicYearId',
        'page': '$page',
        'limit': '$limit',
        if (classId != null) 'class_id': '$classId',
        if (studentId != null) 'student_id': '$studentId',
        if (status != null && status.isNotEmpty) 'status': status,
        if (billingCycle != null && billingCycle.isNotEmpty)
          'billing_cycle': billingCycle,
        if (billingYear != null) 'billing_year': '$billingYear',
        if (billingMonth != null) 'billing_month': '$billingMonth',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };
      final uri = apiUrl('$basePath/fees').replace(queryParameters: query);
      final response = await _client.get(uri);
      devLogResponse('FeeLedgerService.listFees', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not load the fee ledger.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      if (map == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinanceFeeLedgerPage.fromJson(map));
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'FeeLedgerService.listFees'));
    }
  }

  Future<FinanceResult<StudentFeeLedger>> studentLedger({
    required int studentId,
    required int academicYearId,
  }) async {
    try {
      final response = await _client.get(apiUrl(
          '$basePath/students/$studentId/fees?academic_year_id=$academicYearId'));
      devLogResponse(
          'FeeLedgerService.studentLedger', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not load the student ledger.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      if (map == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(StudentFeeLedger.fromJson(map));
    } catch (e, st) {
      return FinanceError(
          userFriendlyMessage(e, st, 'FeeLedgerService.studentLedger'));
    }
  }

  Future<FinanceResult<FinanceDashboard>> dashboard({
    required int academicYearId,
  }) async {
    try {
      final response = await _client
          .get(apiUrl('$basePath/dashboard?academic_year_id=$academicYearId'));
      devLogResponse('FeeLedgerService.dashboard', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not load the dashboard.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      if (map == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinanceDashboard.fromJson(map));
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, 'FeeLedgerService.dashboard'));
    }
  }
}
