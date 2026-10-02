import 'package:flutter/material.dart';

import 'package:kobac/exam_fees/models/exam_fee_models.dart';
import 'package:kobac/exam_fees/services/exam_fee_service.dart';
import 'package:kobac/exam_fees/state/exam_fees_controller.dart';
import 'package:kobac/exam_fees/widgets/exam_fees_ui.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';

Widget _errorText(String? message) => message == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          message,
          key: const ValueKey('dialog-error'),
          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
        ),
      );

Widget _actions(BuildContext context, Widget submit, {String cancel = 'Cancel'}) =>
    Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 8,
        children: [
          AdminSecondaryButton(
            label: cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          submit,
        ],
      ),
    );

const _note = TextStyle(fontSize: 12.5, color: kAdminTextSecondary, height: 1.35);

// ===========================================================================
// Customize fee
// ===========================================================================

Future<bool?> showCustomizeFee(
  BuildContext context,
  ExamFeesController c,
  StudentExamFee fee,
) => showExamFeeSheet<bool>(
  context,
  title: 'Customize Exam Fee',
  builder: (_) => _CustomizeForm(controller: c, fee: fee),
);

class _CustomizeForm extends StatefulWidget {
  final ExamFeesController controller;
  final StudentExamFee fee;
  const _CustomizeForm({required this.controller, required this.fee});
  @override
  State<_CustomizeForm> createState() => _CustomizeFormState();
}

class _CustomizeFormState extends State<_CustomizeForm> {
  late final _amount = TextEditingController(text: moneyInputText(widget.fee.amount));
  final _reason = TextEditingController();
  String? _amountError, _reasonError, _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseMoneyInput(_amount.text);
    setState(() {
      _error = null;
      _amountError = amount == null || toCents(amount) <= 0
          ? 'Enter an amount greater than 0.'
          : toCents(amount) < toCents(widget.fee.paidAmount)
          ? 'The new fee cannot be less than the ${money(widget.fee.paidAmount)} already paid.'
          : null;
      _reasonError = _reason.text.trim().isEmpty ? 'A reason is required.' : null;
    });
    if (_amountError != null || _reasonError != null || _busy) return;
    setState(() => _busy = true);
    final r = await widget.controller.updateAmount(
      widget.fee,
      amount: amount!,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    if (r is ExamFeeFailure) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExamFeeInfoGrid([
        ('Student', widget.fee.displayName),
        ('Original Fee', money(widget.fee.originalAmount)),
        ('Current Fee', money(widget.fee.amount)),
        ('Already Paid', money(widget.fee.paidAmount)),
      ]),
      const SizedBox(height: 14),
      TextField(
        key: const ValueKey('customize-amount'),
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: examFeeInput('New Amount', error: _amountError),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('customize-reason'),
        controller: _reason,
        maxLength: 255,
        decoration: examFeeInput('Reason', error: _reasonError),
      ),
      const Text(
        'The original generated fee is kept for the record; only the payable amount changes.',
        style: _note,
      ),
      _errorText(_error),
      _actions(
        context,
        ExamFeeSubmitButton(
          buttonKey: const ValueKey('customize-save'),
          label: 'Save Fee',
          busy: _busy,
          onPressed: _submit,
        ),
      ),
    ],
  );
}

// ===========================================================================
// Waive / unwaive
// ===========================================================================

Future<bool?> showWaiveFee(
  BuildContext context,
  ExamFeesController c,
  StudentExamFee fee,
) => showExamFeeSheet<bool>(
  context,
  title: 'Waive Exam Fee',
  builder: (_) => _WaiveForm(controller: c, fee: fee),
);

class _WaiveForm extends StatefulWidget {
  final ExamFeesController controller;
  final StudentExamFee fee;
  const _WaiveForm({required this.controller, required this.fee});
  @override
  State<_WaiveForm> createState() => _WaiveFormState();
}

class _WaiveFormState extends State<_WaiveForm> {
  final _reason = TextEditingController();
  String? _reasonError, _error;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _reasonError = _reason.text.trim().isEmpty ? 'A reason is required.' : null;
    });
    if (_reasonError != null || _busy) return;
    setState(() => _busy = true);
    final r = await widget.controller.waive(widget.fee, reason: _reason.text.trim());
    if (!mounted) return;
    if (r is ExamFeeFailure) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExamFeeInfoGrid([
        ('Student', widget.fee.displayName),
        ('Original Fee', money(widget.fee.originalAmount)),
        ('Current Fee', money(widget.fee.amount)),
      ]),
      const SizedBox(height: 12),
      const Text(
        "Waiving makes this student's payable exam fee zero. It is not a "
        'payment and no receipt is created. You can restore the fee later '
        'with Unwaive.',
        key: ValueKey('waive-explanation'),
        style: TextStyle(fontSize: 13.5, color: kAdminNavy, height: 1.4),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('waive-reason'),
        controller: _reason,
        maxLength: 255,
        decoration: examFeeInput('Reason', error: _reasonError),
      ),
      _errorText(_error),
      _actions(
        context,
        ExamFeeSubmitButton(
          buttonKey: const ValueKey('waive-confirm'),
          label: 'Waive Fee',
          busy: _busy,
          color: kExamFeeInfo,
          onPressed: _submit,
        ),
      ),
    ],
  );
}

Future<bool?> showUnwaiveFee(
  BuildContext context,
  ExamFeesController c,
  StudentExamFee fee,
) => showExamFeeSheet<bool>(
  context,
  title: 'Unwaive Exam Fee',
  builder: (_) => _UnwaiveForm(controller: c, fee: fee),
);

class _UnwaiveForm extends StatefulWidget {
  final ExamFeesController controller;
  final StudentExamFee fee;
  const _UnwaiveForm({required this.controller, required this.fee});
  @override
  State<_UnwaiveForm> createState() => _UnwaiveFormState();
}

class _UnwaiveFormState extends State<_UnwaiveForm> {
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.controller.unwaive(widget.fee);
    if (!mounted) return;
    if (r is ExamFeeFailure) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExamFeeInfoGrid([
        ('Student', widget.fee.displayName),
        ('Original Fee', money(widget.fee.originalAmount)),
        if (widget.fee.waiverReason != null) ('Waiver Reason', widget.fee.waiverReason!),
      ]),
      const SizedBox(height: 12),
      Text(
        "The student's fee will return to the original generated amount of "
        '${money(widget.fee.originalAmount)} and become payable again.',
        style: const TextStyle(fontSize: 13.5, color: kAdminNavy, height: 1.4),
      ),
      _errorText(_error),
      _actions(
        context,
        ExamFeeSubmitButton(
          buttonKey: const ValueKey('unwaive-confirm'),
          label: 'Unwaive Fee',
          busy: _busy,
          onPressed: _submit,
        ),
      ),
    ],
  );
}

// ===========================================================================
// Individual collection
// ===========================================================================

Future<bool?> showCollectFee(
  BuildContext context,
  ExamFeesController c,
  StudentExamFee fee,
) => showExamFeeSheet<bool>(
  context,
  title: 'Collect Exam Fee',
  builder: (_) => _CollectForm(controller: c, fee: fee),
);

class _CollectForm extends StatefulWidget {
  final ExamFeesController controller;
  final StudentExamFee fee;
  const _CollectForm({required this.controller, required this.fee});
  @override
  State<_CollectForm> createState() => _CollectFormState();
}

class _CollectFormState extends State<_CollectForm> {
  late final _amount = TextEditingController(
    text: moneyInputText(widget.fee.remainingAmount),
  );
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'CASH';
  String? _amountError, _error;
  bool _busy = false;
  PaymentRecordResult? _done;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseMoneyInput(_amount.text);
    setState(() {
      _error = null;
      _amountError = amount == null || toCents(amount) <= 0
          ? 'Enter an amount greater than 0.'
          : toCents(amount) > toCents(widget.fee.remainingAmount)
          ? 'The payment is greater than the remaining balance of ${money(widget.fee.remainingAmount)}.'
          : null;
    });
    if (_amountError != null || _busy) return;
    setState(() => _busy = true);
    final r = await widget.controller.recordPayment(
      widget.fee,
      amount: amount!,
      method: _method,
      referenceNumber: _reference.text,
      notes: _notes.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r is ExamFeeSuccess<PaymentRecordResult>) {
        _done = r.data;
      } else {
        _error = (r as ExamFeeFailure).message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _done;
    if (done != null) {
      return Column(
        key: const ValueKey('collect-success'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_rounded, color: kAdminGreen, size: 44),
          const SizedBox(height: 8),
          const Text(
            'Payment recorded successfully',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kAdminNavy),
          ),
          const SizedBox(height: 12),
          ExamFeeInfoGrid([
            ('Receipt Number', done.payment.receiptNumber ?? '—'),
            ('Amount', money(done.payment.amount)),
            ('Method', done.payment.method ?? '—'),
            ('Remaining', money(done.remainingAmount)),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                ExamFeeReceiptButton(controller: widget.controller, payment: done.payment),
                AdminPrimaryButton(
                  key: const ValueKey('collect-done'),
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final c = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExamFeeInfoGrid([
          ('Student', widget.fee.displayName),
          ('Exam', c.selectedExam?.name ?? c.register?.scope.examName ?? '—'),
          ('Current Fee', money(widget.fee.amount)),
          ('Already Paid', money(widget.fee.paidAmount)),
          ('Remaining', money(widget.fee.remainingAmount)),
        ]),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('collect-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: examFeeInput(
            'Amount',
            error: _amountError,
            helper: 'Reduce the amount for a partial payment.',
          ),
        ),
        const SizedBox(height: 12),
        _MethodField(value: _method, onChanged: (v) => setState(() => _method = v)),
        const SizedBox(height: 12),
        TextField(
          controller: _reference,
          maxLength: 100,
          decoration: examFeeInput('Reference Number (optional)'),
        ),
        TextField(
          controller: _notes,
          maxLength: 500,
          decoration: examFeeInput('Notes (optional)'),
        ),
        _errorText(_error),
        _actions(
          context,
          ExamFeeSubmitButton(
            buttonKey: const ValueKey('collect-submit'),
            label: 'Record Payment',
            busy: _busy,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class _MethodField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _MethodField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: const ValueKey('payment-method'),
    initialValue: value,
    isExpanded: true,
    decoration: examFeeInput('Payment Method'),
    items: [
      for (final m in kExamFeePaymentMethods)
        DropdownMenuItem(value: m, child: Text(m)),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

// ===========================================================================
// Bulk collection (atomic)
// ===========================================================================

Future<bool?> showBulkCollect(BuildContext context, ExamFeesController c) =>
    showExamFeeSheet<bool>(
      context,
      title: 'Collect Selected (${c.selection.length})',
      maxWidth: 640,
      builder: (_) => _BulkForm(controller: c, fees: c.selectedFees),
    );

class _BulkForm extends StatefulWidget {
  final ExamFeesController controller;
  final List<StudentExamFee> fees;
  const _BulkForm({required this.controller, required this.fees});
  @override
  State<_BulkForm> createState() => _BulkFormState();
}

class _BulkFormState extends State<_BulkForm> {
  late final Map<int, TextEditingController> _amounts = {
    for (final f in widget.fees)
      f.studentId: TextEditingController(text: moneyInputText(f.remainingAmount)),
  };
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'CASH';
  final Map<int, String> _rowErrors = {};
  String? _error;
  bool _busy = false;
  BulkCollectionResult? _done;

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final entries = <BulkCollectEntry>[];
    final errors = <int, String>{};
    for (final f in widget.fees) {
      final amount = parseMoneyInput(_amounts[f.studentId]!.text);
      if (amount == null || toCents(amount) <= 0) {
        errors[f.studentId] = 'Enter an amount greater than 0.';
      } else if (toCents(amount) > toCents(f.remainingAmount)) {
        errors[f.studentId] = 'More than the remaining ${money(f.remainingAmount)}.';
      } else {
        entries.add(BulkCollectEntry(f.studentId, amount));
      }
    }
    setState(() {
      _error = null;
      _rowErrors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;
    setState(() => _busy = true);
    final r = await widget.controller.collectBulk(
      entries: entries,
      method: _method,
      referenceNumber: _reference.text,
      notes: _notes.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r is ExamFeeSuccess<BulkCollectionResult>) {
        _done = r.data;
      } else {
        final f = r as ExamFeeFailure;
        _error = f.message;
        for (final e in f.entryErrors) {
          final id = e.studentId ??
              (e.index != null && e.index! < widget.fees.length
                  ? widget.fees[e.index!].studentId
                  : null);
          if (id != null) {
            _rowErrors[id] = examFeeErrorMessage(
              code: e.code,
              backendMessage: e.message,
              fallback: 'This student could not be collected.',
            );
          }
        }
      }
    });
  }

  double get _total {
    var cents = 0;
    for (final c in _amounts.values) {
      cents += toCents(parseMoneyInput(c.text) ?? 0);
    }
    return cents / 100;
  }

  @override
  Widget build(BuildContext context) {
    final done = _done;
    if (done != null) {
      return Column(
        key: const ValueKey('bulk-success'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_rounded, color: kAdminGreen, size: 44),
          const SizedBox(height: 8),
          Text(
            '${done.paymentCount} payments recorded successfully',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kAdminNavy),
          ),
          const SizedBox(height: 4),
          Text(
            'Total collected: ${money(done.totalCollected)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kAdminTextSecondary),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Align(
              alignment: Alignment.centerRight,
              child: AdminPrimaryButton(
                key: const ValueKey('bulk-done'),
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in widget.fees)
          Container(
            key: ValueKey('bulk-row-${f.studentId}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kAdminHeaderBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _rowErrors.containsKey(f.studentId) ? Colors.red.shade300 : kAdminBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: kAdminNavy),
                          ),
                          Text(
                            'Remaining ${money(f.remainingAmount)}',
                            style: const TextStyle(fontSize: 12, color: kAdminTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        key: ValueKey('bulk-amount-${f.studentId}'),
                        controller: _amounts[f.studentId],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: examFeeInput('Amount'),
                      ),
                    ),
                  ],
                ),
                if (_rowErrors[f.studentId] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _rowErrors[f.studentId]!,
                      key: ValueKey('bulk-error-${f.studentId}'),
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
        Text(
          'Total: ${money(_total)}',
          key: const ValueKey('bulk-total'),
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w800, color: kAdminNavy),
        ),
        const SizedBox(height: 12),
        _MethodField(value: _method, onChanged: (v) => setState(() => _method = v)),
        const SizedBox(height: 12),
        TextField(
          controller: _reference,
          maxLength: 100,
          decoration: examFeeInput('Reference Number (optional)'),
        ),
        TextField(
          controller: _notes,
          maxLength: 500,
          decoration: examFeeInput('Notes (optional)'),
        ),
        const Text(
          'All selected payments are recorded together. If any one fails, none is recorded.',
          style: _note,
        ),
        _errorText(_error),
        _actions(
          context,
          ExamFeeSubmitButton(
            buttonKey: const ValueKey('bulk-submit'),
            label: 'Collect ${widget.fees.length} Payments',
            busy: _busy,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Setup: set/update fee
// ===========================================================================

Future<bool?> showSetFee(
  BuildContext context,
  ExamFeesController c,
  ExamFeeClassSetting row,
) => showExamFeeSheet<bool>(
  context,
  title: row.configured ? 'Update Exam Fee' : 'Set Exam Fee',
  builder: (_) => _SettingForm(controller: c, row: row),
);

class _SettingForm extends StatefulWidget {
  final ExamFeesController controller;
  final ExamFeeClassSetting row;
  const _SettingForm({required this.controller, required this.row});
  @override
  State<_SettingForm> createState() => _SettingFormState();
}

class _SettingFormState extends State<_SettingForm> {
  late final _amount = TextEditingController(
    text: widget.row.setting == null ? '' : moneyInputText(widget.row.setting!.amount),
  );
  String? _amountError, _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseMoneyInput(_amount.text);
    setState(() {
      _error = null;
      _amountError = amount == null || toCents(amount) <= 0
          ? 'Enter an amount greater than 0.'
          : null;
    });
    if (_amountError != null || _busy) return;
    setState(() => _busy = true);
    final r = await widget.controller.saveSetting(widget.row.classId, amount!);
    if (!mounted) return;
    if (r is ExamFeeFailure) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExamFeeInfoGrid([
        ('Exam', widget.controller.selectedExam?.name ?? '—'),
        ('Class', widget.row.className),
        ('Current Fee', widget.row.setting == null ? 'Not configured' : money(widget.row.setting!.amount)),
      ]),
      const SizedBox(height: 14),
      TextField(
        key: const ValueKey('setting-amount'),
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: examFeeInput('Exam Fee', error: _amountError),
      ),
      const SizedBox(height: 8),
      const Text(
        'Changing this setting does not change fees already generated for students.',
        key: ValueKey('setting-change-note'),
        style: _note,
      ),
      _errorText(_error),
      _actions(
        context,
        ExamFeeSubmitButton(
          buttonKey: const ValueKey('setting-save'),
          label: 'Save Fee',
          busy: _busy,
          onPressed: _submit,
        ),
      ),
    ],
  );
}

// ===========================================================================
// Generation: preview -> generate
// ===========================================================================

Future<bool?> showGeneration(
  BuildContext context,
  ExamFeesController c,
  ExamFeeClassSetting row,
) => showExamFeeSheet<bool>(
  context,
  title: 'Generate Exam Fees',
  maxWidth: 600,
  builder: (_) => _GenerationSheet(controller: c, row: row),
);

class _GenerationSheet extends StatefulWidget {
  final ExamFeesController controller;
  final ExamFeeClassSetting row;
  const _GenerationSheet({required this.controller, required this.row});
  @override
  State<_GenerationSheet> createState() => _GenerationSheetState();
}

class _GenerationSheetState extends State<_GenerationSheet> {
  GenerationPreview? _preview;
  GenerationResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await widget.controller.previewGeneration(widget.row.classId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r is ExamFeeSuccess<GenerationPreview>) {
        _preview = r.data;
      } else {
        _error = (r as ExamFeeFailure).message;
      }
    });
  }

  Future<void> _generate() async {
    final r = await widget.controller.generate(widget.row.classId);
    if (r == null || !mounted) return; // already generating
    setState(() {
      if (r is ExamFeeSuccess<GenerationResult>) {
        _result = r.data;
      } else {
        _error = (r as ExamFeeFailure).message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return Column(
        key: const ValueKey('generation-result'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_rounded, color: kAdminGreen, size: 44),
          const SizedBox(height: 8),
          const Text(
            'Exam fees generated',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kAdminNavy),
          ),
          const SizedBox(height: 12),
          ExamFeeInfoGrid([
            ('Created', '${result.created}'),
            ('Already Generated', '${result.alreadyGenerated}'),
            ('Eligible', '${result.eligible}'),
            ('Fee', money(result.amount)),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Align(
              alignment: Alignment.centerRight,
              child: AdminPrimaryButton(
                key: const ValueKey('generation-done'),
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ),
        ],
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
      );
    }
    final p = _preview;
    if (p == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _errorText(_error),
          const SizedBox(height: 12),
          AdminSecondaryButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: _loadPreview),
        ],
      );
    }
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final busy = widget.controller.generating.contains(widget.row.classId);
        return Column(
          key: const ValueKey('generation-preview'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Preview only — nothing has been saved yet.',
              key: ValueKey('preview-note'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kExamFeeAmber),
            ),
            const SizedBox(height: 10),
            ExamFeeInfoGrid([
              ('Exam', p.scope.examName ?? widget.controller.selectedExam?.name ?? '—'),
              ('Class', p.scope.className ?? widget.row.className),
              ('Configured Fee', money(p.currentAmount)),
            ]),
            const SizedBox(height: 10),
            ExamFeeInfoGrid([
              ('Eligible Students', '${p.eligible}'),
              ('Will Be Generated', '${p.willGenerate}'),
              ('Already Generated', '${p.alreadyGenerated}'),
              ('Generated in Another Class', '${p.alreadyGeneratedInOtherClass}'),
            ]),
            if (p.differsFromCurrentSetting > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${p.differsFromCurrentSetting} already-generated '
                  '${p.differsFromCurrentSetting == 1 ? 'fee uses' : 'fees use'} a different '
                  'amount from the current setting. Existing fees are never changed by generation.',
                  style: _note,
                ),
              ),
            if (p.message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(p.message!, style: TextStyle(color: Colors.red.shade700)),
              ),
            if (!p.canGenerate && p.message == null)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('There are no new students to generate fees for.', style: _note),
              ),
            _errorText(_error),
            _actions(
              context,
              ExamFeeSubmitButton(
                buttonKey: const ValueKey('generation-generate'),
                label: 'Generate Fees',
                busy: busy,
                onPressed: p.canGenerate ? _generate : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ===========================================================================
// Details
// ===========================================================================

Future<void> showStudentFeeDetail(
  BuildContext context,
  ExamFeesController c,
  StudentExamFee fee,
) => showExamFeeSheet<void>(
  context,
  title: 'Exam Fee Details',
  maxWidth: 600,
  builder: (_) => _StudentFeeDetail(controller: c, feeId: fee.id),
);

class _StudentFeeDetail extends StatefulWidget {
  final ExamFeesController controller;
  final int feeId;
  const _StudentFeeDetail({required this.controller, required this.feeId});
  @override
  State<_StudentFeeDetail> createState() => _StudentFeeDetailState();
}

class _StudentFeeDetailState extends State<_StudentFeeDetail> {
  late Future<ExamFeeResult<StudentFeeDetail>> _future =
      widget.controller.loadStudentFee(widget.feeId);

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<ExamFeeResult<StudentFeeDetail>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
            );
          }
          final r = snap.data!;
          if (r is ExamFeeFailure) {
            return ExamFeeErrorState(
              failure: r,
              onRetry: () => setState(
                () => _future = widget.controller.loadStudentFee(widget.feeId),
              ),
            );
          }
          final d = (r as ExamFeeSuccess<StudentFeeDetail>).data;
          final f = d.fee;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExamFeeInfoGrid([
                ('Student', f.displayName),
                ('EMIS', f.emisNumber ?? '—'),
                ('Exam', d.examName ?? '—'),
                ('Class', d.className ?? '—'),
                ('Original Fee', money(f.originalAmount)),
                ('Payable', money(f.amount)),
                ('Paid', money(f.paidAmount)),
                ('Remaining', money(f.remainingAmount)),
              ]),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: ExamFeeStatusPill(f.status)),
              if (d.adjustmentReason != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Customized: ${d.adjustmentReason}${d.adjustedBy == null ? '' : ' (by ${d.adjustedBy})'}',
                  style: _note,
                ),
              ],
              if (d.waiverReason != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Waived: ${d.waiverReason}${d.waivedBy == null ? '' : ' (by ${d.waivedBy})'}',
                  style: _note,
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Payments (${d.payments.length})',
                style: const TextStyle(fontWeight: FontWeight.w800, color: kAdminNavy),
              ),
              const SizedBox(height: 6),
              if (d.payments.isEmpty)
                const Text('No payments recorded yet.', style: _note)
              else
                for (final p in d.payments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          '${p.receiptNumber ?? '—'} · ${money(p.amount)} · ${p.method ?? ''} · ${p.paidAtLabel}',
                          style: const TextStyle(color: kAdminNavy, fontSize: 13),
                        ),
                        ExamFeeReceiptButton(
                          controller: widget.controller,
                          payment: p,
                          label: 'Receipt',
                        ),
                      ],
                    ),
                  ),
            ],
          );
        },
      );
}

Future<void> showPaymentDetail(
  BuildContext context,
  ExamFeesController c,
  ExamFeePayment payment,
) => showExamFeeSheet<void>(
  context,
  title: 'Payment ${payment.receiptNumber ?? ''}',
  builder: (_) => _PaymentDetail(controller: c, paymentId: payment.id),
);

class _PaymentDetail extends StatefulWidget {
  final ExamFeesController controller;
  final int paymentId;
  const _PaymentDetail({required this.controller, required this.paymentId});
  @override
  State<_PaymentDetail> createState() => _PaymentDetailState();
}

class _PaymentDetailState extends State<_PaymentDetail> {
  late Future<ExamFeeResult<ExamFeePayment>> _future =
      widget.controller.loadPayment(widget.paymentId);

  @override
  Widget build(BuildContext context) => FutureBuilder<ExamFeeResult<ExamFeePayment>>(
    future: _future,
    builder: (context, snap) {
      if (!snap.hasData) {
        return const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
        );
      }
      final r = snap.data!;
      if (r is ExamFeeFailure) {
        return ExamFeeErrorState(
          failure: r,
          onRetry: () => setState(
            () => _future = widget.controller.loadPayment(widget.paymentId),
          ),
        );
      }
      final p = (r as ExamFeeSuccess<ExamFeePayment>).data;
      return Column(
        key: const ValueKey('payment-detail'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExamFeeInfoGrid([
            ('Receipt', p.receiptNumber ?? '—'),
            ('Student', p.studentName ?? '—'),
            ('EMIS', p.emisNumber ?? '—'),
            ('Academic Year', p.academicYearName ?? '—'),
            ('Exam', p.examName ?? '—'),
            ('Class', p.className ?? '—'),
            ('Amount', money(p.amount)),
            ('Method', p.method ?? '—'),
            ('Reference', p.referenceNumber ?? '—'),
            ('Date', p.paidAtLabel),
            ('Recorded By', p.recordedByName ?? '—'),
            if (p.notes != null) ('Notes', p.notes!),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ExamFeeReceiptButton(controller: widget.controller, payment: p),
            ),
          ),
        ],
      );
    },
  );
}
