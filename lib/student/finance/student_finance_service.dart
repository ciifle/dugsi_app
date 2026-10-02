import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/finance_payment_service.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/pdf_file_result.dart';

class StudentFinanceSummary {
  final int yearId;
  final String yearName;
  final num charged, paid, outstanding;
  final bool hasOutstanding;
  final String? currentStatus;
  const StudentFinanceSummary({
    required this.yearId,
    required this.yearName,
    required this.charged,
    required this.paid,
    required this.outstanding,
    required this.hasOutstanding,
    this.currentStatus,
  });
  factory StudentFinanceSummary.fromJson(Map<String, dynamic> json) {
    final year = financeMap(json['academic_year'])!;
    num amount(String key) => num.parse(json[key].toString());
    return StudentFinanceSummary(
      yearId: int.parse(year['id'].toString()),
      yearName: year['name'].toString(),
      charged: amount('total_charged'),
      paid: amount('total_paid'),
      outstanding: amount('total_outstanding'),
      hasOutstanding: json['has_outstanding_balance'] == true,
      currentStatus: financeMap(
        json['current_billing_period'],
      )?['status']?.toString(),
    );
  }
}

class StudentFinanceOverview {
  final StudentFinanceSummary summary;
  final FinanceFeeLedgerPage ledger;
  const StudentFinanceOverview(this.summary, this.ledger);
  // Zero charge can also mean a generated, fully discounted fee.
  String get balanceMessage => ledger.total == 0
      ? 'No fees have been generated yet.'
      : summary.hasOutstanding
      ? 'You have an outstanding balance.'
      : 'No outstanding balance.';
}

/// Self-service reads only. No caller-supplied student or school identity.
class StudentFinanceService {
  static const basePath = 'api/student/finance';
  final _client = ApiClient();
  final _payments = FinancePaymentService(basePath: basePath);
  Future<FinanceResult<T>> _get<T>(
    String path,
    T Function(Map<String, dynamic>) parse, [
    Map<String, String>? query,
  ]) async {
    try {
      final response = await _client.get(
        apiUrl('$basePath/$path').replace(queryParameters: query),
      );
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not load your financial information. Please try again.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(financeDecode(response.body));
      if (map == null)
        return FinanceError(
          'Could not read the server response. Please try again.',
        );
      return FinanceSuccess(parse(map));
    } catch (_) {
      return FinanceError(
        'Could not load your financial information. Check your connection and try again.',
      );
    }
  }

  Future<FinanceResult<StudentFinanceSummary>> summary({int? yearId}) => _get(
    'summary',
    StudentFinanceSummary.fromJson,
    {if (yearId != null) 'academic_year_id': '$yearId'},
  );
  Future<FinanceResult<FinanceFeeLedgerPage>> fees({
    int? yearId,
    int page = 1,
    int limit = 20,
    String? status,
  }) => _get('fees', FinanceFeeLedgerPage.fromJson, {
    if (yearId != null) 'academic_year_id': '$yearId',
    'page': '$page',
    'limit': '$limit',
    if (status != null) 'status': status,
  });
  Future<FinanceResult<FeeRecord>> fee(int id) =>
      _get('fees/$id', (json) => FeeRecord.fromJson(financeMap(json['fee'])!));
  Future<FinanceResult<FinancePaymentPage>> payments({
    int? yearId,
    int page = 1,
  }) => _get('payments', FinancePaymentPage.fromJson, {
    if (yearId != null) 'academic_year_id': '$yearId',
    'page': '$page',
    'limit': '20',
  });
  Future<FinanceResult<FinancePaymentRecord>> payment(int id) =>
      _payments.getById(id);
  Future<FinanceResult<PdfFileResult>> receipt(int id) => _payments.receipt(id);
  Future<FinanceResult<StudentFinanceOverview>> overview({
    int? yearId,
    int limit = 20,
  }) async {
    final result = await summary(yearId: yearId);
    if (result is! FinanceSuccess<StudentFinanceSummary>)
      return result as FinanceError;
    final ledger = await fees(yearId: result.data.yearId, limit: limit);
    if (ledger is! FinanceSuccess<FinanceFeeLedgerPage>)
      return ledger as FinanceError;
    return FinanceSuccess(StudentFinanceOverview(result.data, ledger.data));
  }
}
