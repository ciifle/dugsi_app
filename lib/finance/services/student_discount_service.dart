import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

import 'package:kobac/finance/models/student_discount.dart';
import 'package:kobac/finance/services/finance_base.dart';

class StudentDiscountService {
  final ApiClient _client = ApiClient();
  final String basePath;
  StudentDiscountService({required this.basePath});

  Future<FinanceResult<List<StudentDiscount>>> list({
    required int academicYearId,
    int? classId,
    String? search,
  }) async {
    try {
      final query = <String, String>{
        'academic_year_id': '$academicYearId',
        if (classId != null) 'class_id': '$classId',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };
      final uri = apiUrl('$basePath/student-discounts')
          .replace(queryParameters: query);
      final response = await _client.get(uri);
      devLogResponse(
          'StudentDiscountService.list', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not load student discounts.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw) ?? {};
      final discounts = (map['studentDiscounts'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => StudentDiscount.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return FinanceSuccess(discounts);
    } catch (e, st) {
      return FinanceError(
          userFriendlyMessage(e, st, 'StudentDiscountService.list'));
    }
  }

  /// Works for any enrolled student, whether or not a discount is already
  /// configured (configured:false + preview fields when none exists yet).
  Future<FinanceResult<StudentDiscount>> get({
    required int studentId,
    required int academicYearId,
  }) async {
    try {
      final response = await _client.get(apiUrl(
          '$basePath/student-discounts/$studentId?academic_year_id=$academicYearId'));
      devLogResponse(
          'StudentDiscountService.get', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not load the student discount.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      final discount = financeMap(map?['studentDiscount']);
      if (discount == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(StudentDiscount.fromJson(discount));
    } catch (e, st) {
      return FinanceError(
          userFriendlyMessage(e, st, 'StudentDiscountService.get'));
    }
  }

  Future<FinanceResult<StudentDiscount>> upsert({
    required int studentId,
    required int academicYearId,
    required num discountPercentage,
    String? reason,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{
        'academic_year_id': academicYearId,
        'discount_percentage': discountPercentage,
        if (reason != null) 'reason': reason,
        if (isActive != null) 'is_active': isActive,
      };
      final response = await _client.put(
          apiUrl('$basePath/student-discounts/$studentId'),
          body: body);
      devLogResponse(
          'StudentDiscountService.upsert', response.statusCode, response.body);
      final raw = financeDecode(response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not save the discount.');
        return FinanceError(message, response.statusCode, code);
      }
      final map = financeMap(raw);
      final discount = financeMap(map?['studentDiscount']);
      if (discount == null) return FinanceError('Invalid response from server.');
      return FinanceSuccess(StudentDiscount.fromJson(discount));
    } catch (e, st) {
      return FinanceError(
          userFriendlyMessage(e, st, 'StudentDiscountService.upsert'));
    }
  }

  Future<FinanceResult<bool>> delete({
    required int studentId,
    required int academicYearId,
  }) async {
    try {
      final response = await _client.delete(apiUrl(
          '$basePath/student-discounts/$studentId?academic_year_id=$academicYearId'));
      devLogResponse(
          'StudentDiscountService.delete', response.statusCode, response.body);
      if (response.statusCode != 200) {
        final (message, code) =
            financeErrorInfo(response, 'Could not remove the discount.');
        return FinanceError(message, response.statusCode, code);
      }
      return FinanceSuccess(true);
    } catch (e, st) {
      return FinanceError(
          userFriendlyMessage(e, st, 'StudentDiscountService.delete'));
    }
  }
}
