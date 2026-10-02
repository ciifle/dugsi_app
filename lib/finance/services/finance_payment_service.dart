import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/pdf_file_result.dart';

import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/finance_collection_service.dart';

class FinancePaymentService {
  final ApiClient _client = ApiClient();
  final String basePath;
  FinancePaymentService({required this.basePath});

  /// Backend derives school_id/recorded_by/receipt_number server-side and
  /// re-validates the balance under a row lock — client-side amount caps are
  /// UX only, never authoritative. Surfaces PAYMENT_EXCEEDS_BALANCE /
  /// FEE_ALREADY_PAID via [FinanceError.code] so the caller can refetch the
  /// fee and show the exact backend message.
  Future<FinanceResult<FinancePaymentCollectionResult>> recordPayment({
    required int feeId,
    required num amount,
    required String method,
    String? referenceNumber,
    String? notes,
  }) async {
    if (notes != null && notes.length > 500) {
      return FinanceError('Notes must be 500 characters or fewer.');
    }
    if (!amount.isFinite || amount <= 0) {
      return FinanceError('Enter a valid payment amount greater than zero.');
    }
    if (!kPaymentMethods.contains(method)) {
      return FinanceError('Choose a supported payment method.');
    }
    try {
      final body = <String, dynamic>{
        'fee_id': feeId,
        'amount': amount,
        'method': method,
        if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
          'reference_number': referenceNumber.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      final response = await _client.post(
        apiUrl('$basePath/payments'),
        body: body,
      );
      devLogResponse(
        'FinancePaymentService.recordPayment',
        response.statusCode,
        response.body,
      );
      final raw = financeDecode(response.body);
      if (response.statusCode != 201) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not record the payment.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      if (map == null) return FinanceError('Invalid response from server.');
      final result = FinancePaymentCollectionResult.fromJson(map);
      financeCollectionChanges.collected();
      return FinanceSuccess(result);
    } catch (e, st) {
      return FinanceError(
        userFriendlyMessage(e, st, 'FinancePaymentService.recordPayment'),
      );
    }
  }

  Future<FinanceResult<FinancePaymentPage>> list({
    int? academicYearId,
    int? studentId,
    int? classId,
    int? feeId,
    String? method,
    int? billingYear,
    int? billingMonth,
    String? dateFrom,
    String? dateTo,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final query = <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (academicYearId != null) 'academic_year_id': '$academicYearId',
        if (studentId != null) 'student_id': '$studentId',
        if (classId != null) 'class_id': '$classId',
        if (feeId != null) 'fee_id': '$feeId',
        if (method != null && method.isNotEmpty) 'method': method,
        if (billingYear != null) 'billing_year': '$billingYear',
        if (billingMonth != null) 'billing_month': '$billingMonth',
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };
      final uri = apiUrl('$basePath/payments').replace(queryParameters: query);
      final response = await _client.get(uri);
      devLogResponse(
        'FinancePaymentService.list',
        response.statusCode,
        response.body,
      );
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not load payment history.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      if (map == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinancePaymentPage.fromJson(map));
    } catch (e, st) {
      return FinanceError(
        userFriendlyMessage(e, st, 'FinancePaymentService.list'),
      );
    }
  }

  Future<FinanceResult<FinancePaymentRecord>> getById(int id) async {
    try {
      final response = await _client.get(apiUrl('$basePath/payments/$id'));
      devLogResponse(
        'FinancePaymentService.getById',
        response.statusCode,
        response.body,
      );
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not load the payment.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      final payment = financeMap(map?['payment']);
      if (payment == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinancePaymentRecord.fromJson(payment));
    } catch (e, st) {
      return FinanceError(
        userFriendlyMessage(e, st, 'FinancePaymentService.getById'),
      );
    }
  }

  Future<FinanceResult<FinancePaymentHistory>> studentHistory({
    required int studentId,
    required int academicYearId,
  }) async {
    try {
      final response = await _client.get(
        apiUrl(
          '$basePath/students/$studentId/payments?academic_year_id=$academicYearId',
        ),
      );
      devLogResponse(
        'FinancePaymentService.studentHistory',
        response.statusCode,
        response.body,
      );
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not load payment history.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      if (map == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(FinancePaymentHistory.fromJson(map));
    } catch (e, st) {
      return FinanceError(
        userFriendlyMessage(e, st, 'FinancePaymentService.studentHistory'),
      );
    }
  }

  Future<FinanceResult<PdfFileResult>> receipt(int paymentId) async {
    try {
      final response = await _client.get(
        apiUrl('$basePath/payments/$paymentId/receipt'),
      );
      devLogResponse(
        'FinancePaymentService.receipt',
        response.statusCode,
        'application/pdf',
      );
      final pdf = pdfFileResultFromResponse(response);
      if (pdf == null) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not download the receipt.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      return FinanceSuccess(pdf);
    } catch (e, st) {
      return FinanceError(
        userFriendlyMessage(e, st, 'FinancePaymentService.receipt'),
      );
    }
  }
}
