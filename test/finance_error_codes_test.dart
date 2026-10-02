import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/models/finance_payment.dart';

void main() {
  group('financeErrorInfo (backend error JSON: {message, ...details})', () {
    test('extracts FINANCE_NOT_ENABLED code and message', () {
      final response = http.Response(
        '{"message":"Feature disabled: payments_enabled","code":"FINANCE_NOT_ENABLED"}',
        403,
      );
      final (message, code) = financeErrorInfo(response, 'fallback');
      expect(code, 'FINANCE_NOT_ENABLED');
      expect(message, 'Finance is not enabled for this school.');
    });

    test('extracts PAYMENT_EXCEEDS_BALANCE code', () {
      final response = http.Response(
        '{"message":"Payment amount exceeds the remaining fee balance.","code":"PAYMENT_EXCEEDS_BALANCE"}',
        400,
      );
      final (message, code) = financeErrorInfo(response, 'fallback');
      expect(code, 'PAYMENT_EXCEEDS_BALANCE');
      expect(message, contains('exceeds'));
    });

    test('extracts FEE_ALREADY_PAID code', () {
      final response = http.Response(
        '{"message":"This fee has already been fully paid.","code":"FEE_ALREADY_PAID"}',
        400,
      );
      final (message, code) = financeErrorInfo(response, 'fallback');
      expect(code, 'FEE_ALREADY_PAID');
    });

    test('extracts FINANCE_USER_HAS_PAYMENT_HISTORY code with payment_count detail', () {
      final response = http.Response(
        '{"message":"This Finance user has recorded payment history and cannot be deleted.",'
        '"code":"FINANCE_USER_HAS_PAYMENT_HISTORY","payment_count":4}',
        409,
      );
      final (message, code) = financeErrorInfo(response, 'fallback');
      expect(code, 'FINANCE_USER_HAS_PAYMENT_HISTORY');
      expect(message, contains('cannot be deleted'));
    });

    test('falls back to the provided message when no code is present', () {
      final response = http.Response('{}', 500);
      final (message, code) = financeErrorInfo(response, 'Something went wrong.');
      expect(code, isNull);
      expect(message, 'Something went wrong.');
    });
  });

  group('Pagination parsing defaults', () {
    test('FinanceFeeLedgerPage defaults page to 1 and limit to 50 when missing', () {
      final page = FinanceFeeLedgerPage.fromJson({
        'academic_year': {'id': 2, 'name': '2025/2026'},
        'fees': [],
        'pagination': {'total': 0},
      });
      expect(page.page, 1);
      expect(page.limit, 50);
      expect(page.total, 0);
    });

    test('FinancePaymentPage preserves an explicit page/limit/total', () {
      final page = FinancePaymentPage.fromJson({
        'payments': [],
        'pagination': {'page': 3, 'limit': 20, 'total': 47},
      });
      expect(page.page, 3);
      expect(page.limit, 20);
      expect(page.total, 47);
    });
  });
}
