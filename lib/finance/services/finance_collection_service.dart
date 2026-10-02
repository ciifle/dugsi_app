import 'package:flutter/foundation.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import '../models/finance_collection.dart';
import 'finance_base.dart';

/// Mounted dashboards refetch; dashboards mounted later load normally.
class FinanceCollectionChanges extends ChangeNotifier {
  void collected() => notifyListeners();
}

final financeCollectionChanges = FinanceCollectionChanges();

class CollectionError extends FinanceError {
  final List<CollectionValidationIssue> issues;
  final bool outcomeUnknown;
  CollectionError(
    String message, {
    int? status,
    String? code,
    this.issues = const [],
    this.outcomeUnknown = false,
  }) : super(message, status, code);
}

class FinanceCollectionService {
  final String basePath;
  final ApiClient _client = ApiClient();
  FinanceCollectionService({required this.basePath});

  Future<FinanceResult<FinanceStudentPage>> students({
    required int academicYearId,
    int? classId,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get(
        apiUrl('$basePath/students').replace(
          queryParameters: {
            'academic_year_id': '$academicYearId',
            if (classId != null) 'class_id': '$classId',
            if (search != null) 'search': search.trim(),
            'page': '$page',
            'limit': '$limit',
          },
        ),
      );
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not load students.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      return FinanceSuccess(
        FinanceStudentPage.fromJson(financeMap(financeDecode(response.body))!),
      );
    } catch (e, st) {
      return FinanceError(
        userFriendlyMessage(e, st, 'FinanceCollectionService.students'),
      );
    }
  }

  Future<FinanceResult<ClassCollectionRegister>> register({
    required int academicYearId,
    required int classId,
    required CollectionPeriod period,
  }) async {
    try {
      final response = await _client.get(
        apiUrl('$basePath/collections/class').replace(
          queryParameters: {
            'academic_year_id': '$academicYearId',
            'class_id': '$classId',
            'billing_month': '${period.month}',
            'billing_year': '${period.year}',
          },
        ),
      );
      if (response.statusCode != 200) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not load fee collection.',
        );
        return FinanceError(message, response.statusCode, code);
      }
      return FinanceSuccess(
        ClassCollectionRegister.fromJson(
          financeMap(financeDecode(response.body))!,
        ),
      );
    } catch (e, st) {
      return FinanceError(
        userFriendlyMessage(e, st, 'FinanceCollectionService.register'),
      );
    }
  }

  Future<FinanceResult<BulkCollectionResult>> collect(
    BulkCollectionRequest request,
  ) async {
    try {
      final response = await _client.post(
        apiUrl('$basePath/collections/class'),
        body: request.toJson(),
      );
      final json = financeMap(financeDecode(response.body));
      if (response.statusCode != 201) {
        final (message, code) = financeErrorInfo(
          response,
          'Could not record payments.',
        );
        return CollectionError(
          message,
          status: response.statusCode,
          code: code,
          issues: (json?['errors'] as List? ?? [])
              .whereType<Map>()
              .map(
                (e) => CollectionValidationIssue.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
        );
      }
      final result = BulkCollectionResult.fromJson(json!);
      financeCollectionChanges.collected();
      return FinanceSuccess(result);
    } catch (_) {
      // A lost response is not proof of rollback. Do not encourage a blind retry.
      return CollectionError(
        'The payment result could not be confirmed. Check Payment History and refresh balances before recording again.',
        outcomeUnknown: true,
      );
    }
  }
}
