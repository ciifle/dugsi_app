import 'package:flutter/material.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/utils/money_format.dart';
import 'package:kobac/utils/mobile_pdf_save_result.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';

import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/finance_payment_service.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

/// Downloads and saves a payment receipt PDF with the app's normal PDF
/// save/feedback flow. Returns true when the file was saved/handed to the
/// browser; failures show a clean snackbar.
Future<bool> downloadPaymentReceipt(
  BuildContext context,
  FinancePaymentService service,
  int paymentId, {
  String? fallbackName,
}) async {
  final result = await service.receipt(paymentId);
  if (!context.mounted) return false;
  if (result is FinanceSuccess) {
    final pdf = (result as FinanceSuccess).data;
    return savePdfWithFeedback(
      context,
      bytes: pdf.bytes,
      filename: sanitizePdfFilename(
        pdf.filename ?? fallbackName ?? 'receipt-$paymentId.pdf',
      ),
    );
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text((result as FinanceError).message),
      backgroundColor: Colors.red,
    ),
  );
  return false;
}

String financePaymentPeriodLabel(FinancePaymentRecord p) {
  if (p.billingCycle == 'MONTHLY' &&
      p.billingMonth != null &&
      p.billingMonth! >= 1 &&
      p.billingMonth! <= 12) {
    return '${kMonthNames[p.billingMonth! - 1]} ${p.billingYear}';
  }
  if (p.billingCycle == 'YEARLY') return 'Yearly ${p.billingYear}';
  final label = '${p.billingCycle ?? ''} ${p.billingYear ?? ''}'.trim();
  return label.isEmpty ? '—' : label;
}

/// Read-only payment details. Payments are immutable in this phase — there is
/// deliberately no Edit/Delete affordance.
Future<void> showFinancePaymentDetailsDialog(
  BuildContext context, {
  required String basePath,
  required int paymentId,
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black38,
  builder: (_) =>
      _PaymentDetailsDialog(basePath: basePath, paymentId: paymentId),
);

class _PaymentDetailsDialog extends StatefulWidget {
  final String basePath;
  final int paymentId;
  const _PaymentDetailsDialog({
    required this.basePath,
    required this.paymentId,
  });

  @override
  State<_PaymentDetailsDialog> createState() => _PaymentDetailsDialogState();
}

class _PaymentDetailsDialogState extends State<_PaymentDetailsDialog> {
  late final FinancePaymentService _service = FinancePaymentService(
    basePath: widget.basePath,
  );
  FinancePaymentRecord? _payment;
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.getById(widget.paymentId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<FinancePaymentRecord>) {
        _payment = result.data;
      } else {
        _payment = null;
        _error = (result as FinanceError).message;
      }
    });
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    await downloadPaymentReceipt(context, _service, widget.paymentId);
    if (mounted) setState(() => _downloading = false);
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: kAdminTextSecondary),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _divider() => const Divider(height: 10, color: kAdminBorder);

  @override
  Widget build(BuildContext context) {
    final p = _payment;
    return AdminFeatureDialog(
      title: 'Payment Details',
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: kAdminNavy),
              ),
            )
          else if (_error != null) ...[
            FinanceInlineError(_error!),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: AdminSecondaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: _load,
              ),
            ),
          ] else if (p != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.receiptNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: kAdminNavy,
                    ),
                  ),
                ),
                Text(
                  formatMoney(p.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: kAdminGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formatFinanceDateTime(p.paidAt),
              style: const TextStyle(color: kAdminTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            _divider(),
            _row('Student', p.studentName),
            _row('EMIS', p.emisNumber ?? '—'),
            _row('Class', p.className),
            _divider(),
            _row('Billing Period', financePaymentPeriodLabel(p)),
            _row('Method', financeLabel(p.method)),
            _row('Reference', p.referenceNumber ?? '—'),
            _row('Notes', p.notes ?? '—'),
            _divider(),
            _row('Recorded By', p.recordedBy.name ?? '—'),
          ],
          const SizedBox(height: 18),
          FinanceDialogActions(
            cancelLabel: 'Close',
            onCancel: () => Navigator.pop(context),
            primaryLabel: 'Download Receipt',
            busy: _downloading,
            onPrimary: p == null ? null : _download,
          ),
        ],
      ),
    );
  }
}
