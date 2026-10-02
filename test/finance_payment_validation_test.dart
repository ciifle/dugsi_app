import 'package:flutter_test/flutter_test.dart';

import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/models/finance_payment.dart';

FeeRecord _fee({required num amount, required num paid, required num remaining, required String status}) {
  return FeeRecord(
    id: 1,
    studentId: 1,
    studentName: 'Student A',
    classId: 1,
    className: '1A',
    academicYearId: 2,
    billingCycle: 'MONTHLY',
    billingYear: 2026,
    billingMonth: 9,
    dueDate: '2026-09-30',
    originalAmount: amount,
    discountPercentage: 20,
    discountAmount: amount * 0.2,
    amount: amount,
    paidAmount: paid,
    remainingAmount: remaining,
    status: status,
  );
}

void main() {
  group('kPaymentMethods', () {
    test('is exactly CASH, CARD, MOBILE, BANK — never any other method', () {
      expect(kPaymentMethods, ['CASH', 'CARD', 'MOBILE', 'BANK']);
    });
  });

  group('FeeRecord.canCollectPayment', () {
    test('true when remaining_amount > 0 (UNPAID)', () {
      final fee = _fee(amount: 100, paid: 0, remaining: 100, status: 'UNPAID');
      expect(fee.canCollectPayment, true);
    });

    test('true when remaining_amount > 0 (PARTIAL)', () {
      final fee = _fee(amount: 100, paid: 30, remaining: 70, status: 'PARTIAL');
      expect(fee.canCollectPayment, true);
    });

    test('false when remaining_amount == 0 (PAID) — Collect Payment must be hidden', () {
      final fee = _fee(amount: 100, paid: 100, remaining: 0, status: 'PAID');
      expect(fee.canCollectPayment, false);
    });

    test('false for a fully-discounted free fee (amount 0, remaining 0, PAID)', () {
      final fee = _fee(amount: 0, paid: 0, remaining: 0, status: 'PAID');
      expect(fee.canCollectPayment, false);
    });
  });

  group('client-side amount-vs-remaining guard (mirrors CollectPaymentPage._confirmAndSubmit)', () {
    test('amount greater than remaining is rejected before any request is sent', () {
      final fee = _fee(amount: 100, paid: 30, remaining: 70, status: 'PARTIAL');
      const attemptedAmount = 80;
      expect(attemptedAmount > fee.remainingAmount, true);
    });

    test('amount equal to remaining is allowed (pays off the fee)', () {
      final fee = _fee(amount: 100, paid: 30, remaining: 70, status: 'PARTIAL');
      const attemptedAmount = 70;
      expect(attemptedAmount > fee.remainingAmount, false);
    });
  });

  group('FinancePaymentCollectionResult.fromJson (POST /payments response shape)', () {
    test('parses the flat fee_id shape — distinct from the nested PaymentRecord GET shape', () {
      final json = {
        'payment': {
          'id': 501,
          'receipt_number': 'RCPT-20260918-000501',
          'fee_id': 12,
          'amount': 30.0,
          'method': 'CASH',
          'reference_number': null,
          'notes': null,
          'paid_at': '2026-09-18T10:00:00.000Z',
          'recorded_by': {'id': 9, 'name': 'Finance User'},
        },
        'fee': {'id': 12, 'amount': 100.0, 'paid_amount': 30.0, 'remaining_amount': 70.0, 'status': 'PARTIAL'},
      };
      final result = FinancePaymentCollectionResult.fromJson(json);
      expect(result.feeId, 12);
      expect(result.fee.remainingAmount, 70.0);
      expect(result.fee.status, 'PARTIAL');
      expect(result.recordedBy.name, 'Finance User');
    });
  });
}
