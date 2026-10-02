import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kobac/exam_fees/models/exam_fee_models.dart';
import 'package:kobac/exam_fees/services/exam_fee_service.dart';
import 'package:kobac/exam_fees/state/exam_fees_controller.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/utils/money_format.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';

const Color kExamFeeAmber = Color(0xFFB7791F);
const Color kExamFeeRed = Color(0xFFC0392B);
const Color kExamFeeInfo = Color(0xFF5B6B8C);

/// 2-decimal money; 6.50 stays "6.50", never "7".
String money(double? v) => v == null ? '—' : formatMoney(v);

void examFeeSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : kAdminGreen,
      ),
    );
}

/// Status with icon + text (never colour alone).
class ExamFeeStatusPill extends StatelessWidget {
  final String status;
  const ExamFeeStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) => switch (status) {
    kFeePaid => const AdminStatusPill(
      label: 'PAID',
      color: kAdminGreen,
      icon: Icons.check_circle_rounded,
    ),
    kFeePartial => const AdminStatusPill(
      label: 'PARTIAL',
      color: kExamFeeAmber,
      icon: Icons.timelapse_rounded,
    ),
    kFeeUnpaid => const AdminStatusPill(
      label: 'UNPAID',
      color: kExamFeeRed,
      icon: Icons.radio_button_unchecked_rounded,
    ),
    kFeeWaived => const AdminStatusPill(
      label: 'WAIVED',
      color: kExamFeeInfo,
      icon: Icons.do_not_disturb_on_outlined,
    ),
    _ => AdminStatusPill(label: status, color: kAdminTextSecondary),
  };
}

/// "Not generated" is not a fee status: it means no financial record yet.
class NotGeneratedPill extends StatelessWidget {
  const NotGeneratedPill({super.key});
  @override
  Widget build(BuildContext context) => const AdminStatusPill(
    label: 'NOT GENERATED',
    color: kAdminTextSecondary,
    icon: Icons.hourglass_empty_rounded,
  );
}

class ExamFeeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const ExamFeeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kAdminBorder),
      boxShadow: [
        BoxShadow(
          color: kAdminNavy.withValues(alpha: .03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

/// Compact money/count tiles; wrap to 2-up on phones.
class ExamFeeStatGrid extends StatelessWidget {
  final List<(String, String, IconData, Color)> items;
  final String keyPrefix;
  const ExamFeeStatGrid({super.key, required this.items, this.keyPrefix = 'stat'});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final perRow = c.maxWidth >= 900 ? items.length : (c.maxWidth >= 520 ? 4 : 2);
      final w = (c.maxWidth - 10 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (label, value, icon, color) in items)
            SizedBox(
              width: w,
              child: ExamFeeCard(
                key: ValueKey('$keyPrefix-$label'),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: kAdminNavy,
                              ),
                            ),
                          ),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: kAdminTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class ExamFeeInlineState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool error;
  const ExamFeeInlineState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) => ExamFeeCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Column(
      children: [
        Icon(
          icon,
          size: 34,
          color: error ? Colors.red.shade700 : kAdminNavy.withValues(alpha: .35),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kAdminNavy,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kAdminTextSecondary, fontSize: 13.5),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 14), action!],
      ],
    ),
  );
}

class ExamFeeErrorState extends StatelessWidget {
  final ExamFeeFailure failure;
  final VoidCallback onRetry;
  const ExamFeeErrorState({super.key, required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) => ExamFeeInlineState(
    key: const ValueKey('exam-fee-error'),
    icon: Icons.error_outline_rounded,
    title: 'Something needs attention',
    message: failure.message,
    error: true,
    action: AdminSecondaryButton(
      label: 'Retry',
      icon: Icons.refresh_rounded,
      onPressed: onRetry,
    ),
  );
}

class ExamFeeSkeleton extends StatelessWidget {
  final int rows;
  const ExamFeeSkeleton({super.key, this.rows = 4});

  Widget _block(double h) => Container(
    height: h,
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: kAdminNavy.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('exam-fee-loading'),
    children: [_block(70), for (var i = 0; i < rows; i++) _block(52)],
  );
}

/// Label/value pairs used at the top of every dialog.
class ExamFeeInfoGrid extends StatelessWidget {
  final List<(String, String)> items;
  const ExamFeeInfoGrid(this.items, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kAdminHeaderBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kAdminBorder),
    ),
    child: Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        for (final (label, value) in items)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 110, maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kAdminTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kAdminNavy,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Branded dialog on wide screens, bottom sheet on phones. Same content.
Future<T?> showExamFeeSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext) builder,
  double maxWidth = 520,
}) {
  final phone = MediaQuery.sizeOf(context).width < 600;
  if (!phone) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => AdminFeatureDialog(
        title: title,
        maxWidth: maxWidth,
        child: builder(ctx),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: kAdminBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kAdminNavy,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: kAdminNavy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

InputDecoration examFeeInput(String label, {String? hint, String? error, String? helper}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      helperText: helper,
      helperMaxLines: 3,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAdminBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAdminBorder),
      ),
    );

/// Primary submit with a spinner while busy (and disabled to stop repeats).
class ExamFeeSubmitButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  final Color color;
  const ExamFeeSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
    this.buttonKey,
    this.color = kAdminGreen,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    key: buttonKey,
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(label),
  );
}

/// Receipt PDF through the existing web/mobile PDF save helper. Repeated
/// taps on the same payment are ignored by the controller.
Future<void> downloadExamFeeReceipt(
  BuildContext context,
  ExamFeesController controller,
  ExamFeePayment payment,
) async {
  final r = await controller.downloadReceipt(payment.id);
  if (r == null || !context.mounted) return;
  if (r is ExamFeeFailure) {
    examFeeSnack(context, r.message, error: true);
    return;
  }
  final file = (r as ExamFeeSuccess<PdfFileResult>).data;
  final saved = await savePdfWithFeedback(
    context,
    bytes: file.bytes,
    filename:
        file.filename ?? 'exam-fee-receipt-${payment.receiptNumber ?? payment.id}.pdf',
  );
  if (saved && kIsWeb && context.mounted) {
    examFeeSnack(context, 'Receipt downloaded.');
  }
}

class ExamFeeReceiptButton extends StatelessWidget {
  final ExamFeesController controller;
  final ExamFeePayment payment;
  final String label;
  const ExamFeeReceiptButton({
    super.key,
    required this.controller,
    required this.payment,
    this.label = 'View / Download Receipt',
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final busy = controller.receiptBusy.contains(payment.id);
      return AdminSecondaryButton(
        key: ValueKey('receipt-${payment.id}'),
        label: busy ? 'Preparing receipt…' : label,
        icon: busy ? Icons.hourglass_top_rounded : Icons.receipt_long_outlined,
        onPressed: busy
            ? null
            : () => downloadExamFeeReceipt(context, controller, payment),
      );
    },
  );
}

/// Horizontal scroll only when the content area is narrower than the table
/// needs, so money columns never shrink into unreadability.
class ExamFeeWideTable extends StatelessWidget {
  final double minWidth;
  final Widget child;
  const ExamFeeWideTable({super.key, required this.minWidth, required this.child});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth >= minWidth) return child;
      return Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: child),
        ),
      );
    },
  );
}

class ExamFeesNotEnabledView extends StatelessWidget {
  final VoidCallback? onBack;
  const ExamFeesNotEnabledView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) => AdminEmptyState(
    key: const ValueKey('exam-fees-not-enabled'),
    icon: Icons.lock_outline_rounded,
    title: 'Exam Fees are not enabled',
    message:
        'Exam Fees are not enabled for this school. Contact Dugsi support if '
        'you believe this is a mistake.',
    action: onBack == null
        ? null
        : AdminSecondaryButton(
            label: 'Back to Dashboard',
            icon: Icons.arrow_back_rounded,
            onPressed: onBack,
          ),
  );
}
