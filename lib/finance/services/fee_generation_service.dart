import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

import 'package:kobac/finance/models/fee_generation.dart';
import 'package:kobac/finance/services/finance_base.dart';

class FeeGenerationService {
  final ApiClient _client = ApiClient();
  final String basePath;
  FeeGenerationService({required this.basePath});

  Map<String, dynamic> _body({
    required int academicYearId,
    int? billingYear,
    int? billingMonth,
  }) => {
    'academic_year_id': academicYearId,
    if (billingYear != null) 'billing_year': billingYear,
    if (billingMonth != null) 'billing_month': billingMonth,
  };

  /// Performs NO writes — safe to call repeatedly while the user adjusts the
  /// period before committing to POST /fees/generate.
  Future<FinanceResult<FeeGenerationResult>> preview({
    required int academicYearId,
    int? billingYear,
    int? billingMonth,
  }) => _call(
    '$basePath/fees/generate/preview',
    _body(
      academicYearId: academicYearId,
      billingYear: billingYear,
      billingMonth: billingMonth,
    ),
    'FeeGenerationService.preview',
    'Could not preview fee generation.',
  );

  Future<FinanceResult<FeeGenerationResult>> generate({
    required int academicYearId,
    int? billingYear,
    int? billingMonth,
  }) => _call(
    '$basePath/fees/generate',
    _body(
      academicYearId: academicYearId,
      billingYear: billingYear,
      billingMonth: billingMonth,
    ),
    'FeeGenerationService.generate',
    'Could not generate fees.',
  );

  Future<FinanceResult<FeeGenerationResult>> _call(
    String path,
    Map<String, dynamic> body,
    String logContext,
    String fallbackMessage,
  ) async {
    try {
      final response = await _client.post(apiUrl(path), body: body);
      devLogResponse(logContext, response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(response, fallbackMessage);
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      if (map == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FeeGenerationResult.fromJson(map));
    } catch (e, st) {
      return FinanceError(userFriendlyMessage(e, st, logContext));
    }
  }
}
