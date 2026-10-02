import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/models/finance_collection.dart';
import 'package:kobac/finance/services/finance_collection_service.dart';
import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/pages/finance_payment_details_dialog.dart';
import 'package:kobac/finance/services/fee_ledger_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/finance_payment_service.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

enum _Step { search, fees, form }

class IndividualPaymentPage extends StatefulWidget {
  final String basePath;
  final Widget? leading;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  /// Optional preselection, e.g. arriving from the Fee Ledger's "Collect"
  /// action: `{'studentId': int, 'feeId': int?, 'academicYearId': int?}`.
  final Map<String, dynamic>? initial;

  const IndividualPaymentPage({
    super.key,
    required this.basePath,
    this.leading,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
    this.initial,
  });

  @override
  State<IndividualPaymentPage> createState() => _IndividualPaymentPageState();
}

class _IndividualPaymentPageState extends State<IndividualPaymentPage> {
  late final FeeLedgerService _ledgerService = FeeLedgerService(
    basePath: widget.basePath,
  );
  late final FinancePaymentService _paymentService = FinancePaymentService(
    basePath: widget.basePath,
  );

  _Step _step = _Step.search;
  int? _yearId;

  static const _searchMinChars = 2;
  static const _searchDebounce = Duration(milliseconds: 250);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounceTimer;
  bool _searching = false;
  int _searchRequest = 0;
  String? _searchError;
  List<FinanceStudent> _searchResults = [];

  int? _studentId;
  String? _studentName;
  bool _loadingFees = false;
  String? _feesError;
  String? _feesErrorCode;
  List<FeeRecord> _outstandingFees = [];
  FeeRecord? _selectedFee;

  final TextEditingController _amountController = TextEditingController();
  String _method = 'CASH';
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AcademicYearsProvider>();
      await ensureFinanceYears(provider);
      if (!mounted) return;
      final initial = widget.initial;
      final yearId =
          (initial?['academicYearId'] as int?) ?? selectedFinanceYear(provider);
      setState(() => _yearId = yearId);
      final studentId = initial?['studentId'] as int?;
      if (studentId != null && yearId != null) {
        await _loadStudentFees(studentId, yearId);
        if (!mounted) return;
        final feeId = initial?['feeId'] as int?;
        if (feeId != null) {
          final match = _outstandingFees.where((f) => f.id == feeId).toList();
          if (match.isNotEmpty) _selectFee(match.first);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Called on every keystroke: only *schedules* a search after
  /// [_searchDebounce] of no further typing, so the field never fires a
  /// request (and the resulting setState/loading UI) mid-keystroke.
  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    if (value.trim().length < _searchMinChars) {
      _searchRequest++; // drop any in-flight/pending response
      setState(() {
        _searchResults = [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    _searchDebounceTimer = Timer(_searchDebounce, () => _search(value));
  }

  Future<void> _search(String query) async {
    final request = ++_searchRequest;
    final yearId = _yearId;
    if (yearId == null || query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    final result = await FinanceCollectionService(
      basePath: widget.basePath,
    ).students(academicYearId: yearId, search: query.trim(), limit: 50);
    if (!mounted || request != _searchRequest) return;
    setState(() {
      _searching = false;
      if (result is FinanceSuccess<FinanceStudentPage>) {
        _searchResults = result.data.students;
      } else {
        _searchError = (result as FinanceError).message;
      }
    });
  }

  Future<void> _loadStudentFees(int studentId, int yearId) async {
    setState(() {
      _step = _Step.fees;
      _outstandingFees = [];
      _loadingFees = true;
      _feesError = null;
      _feesErrorCode = null;
      _studentId = studentId;
    });
    final result = await _ledgerService.studentLedger(
      studentId: studentId,
      academicYearId: yearId,
    );
    if (!mounted) return;
    setState(() {
      _loadingFees = false;
      if (result is FinanceSuccess<StudentFeeLedger>) {
        _studentName = result.data.studentName;
        _outstandingFees = result.data.fees
            .where((f) => f.canCollectPayment)
            .toList();
        _step = _Step.fees;
      } else {
        final err = result as FinanceError;
        _feesError = err.message;
        _feesErrorCode = err.code;
      }
    });
  }

  void _selectFee(FeeRecord fee) {
    _submitError = null;
    _referenceController.clear();
    _notesController.clear();
    _selectedFee = fee;
    _amountController.text = fee.remainingAmount.toString();
    setState(() => _step = _Step.form);
  }

  Future<void> _confirmAndSubmit() async {
    final fee = _selectedFee;
    if (fee == null || _submitting) return;
    final amount = num.tryParse(_amountController.text.trim());
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(_amountController.text.trim())) {
      setState(() => _submitError = 'Enter a valid amount greater than 0.');
      return;
    }
    if (amount > fee.remainingAmount) {
      setState(
        () => _submitError = 'Amount cannot exceed the remaining balance.',
      );
      return;
    }
    if (_notesController.text.length > 500) {
      setState(() => _submitError = 'Notes must be 500 characters or fewer.');
      return;
    }
    setState(() => _submitting = true);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => AdminFeatureDialog(
        title: 'Confirm Payment',
        onClose: () => Navigator.pop(dialogContext, false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoGrid(
              rows: [
                ('Student', _studentName ?? '—'),
                ('Period', fee.billingPeriodLabel),
                ('Remaining Before', formatMoney(fee.remainingAmount)),
                ('Payment Amount', formatMoney(amount)),
                ('Method', financeLabel(_method)),
              ],
            ),
            const SizedBox(height: 18),
            FinanceDialogActions(
              primaryLabel: 'Record Payment',
              onCancel: () => Navigator.pop(dialogContext, false),
              onPrimary: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _submitting = false);
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final result = await _paymentService.recordPayment(
      feeId: fee.id,
      amount: amount,
      method: _method,
      referenceNumber: _referenceController.text,
      notes: _notesController.text,
    );
    if (!mounted) return;
    if (result is FinanceSuccess<FinancePaymentCollectionResult>) {
      setState(() => _submitting = false);
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black38,
        barrierDismissible: false,
        builder: (_) => _PaymentRecordedDialog(
          result: result.data,
          studentName: _studentName,
          service: _paymentService,
        ),
      );
      if (mounted) _collectAnother();
      return;
    }
    final err = result as FinanceError;
    setState(() {
      _submitting = false;
      _submitError = err.message;
    });
    if (err.code == 'PAYMENT_EXCEEDS_BALANCE' ||
        err.code == 'FEE_ALREADY_PAID') {
      // Another Finance user may have collected payment concurrently — refresh
      // the fee rather than leaving a stale balance on screen.
      final yearId = _yearId;
      final studentId = _studentId;
      if (yearId != null && studentId != null)
        await _loadStudentFees(studentId, yearId);
      if (!mounted) return;
      setState(() => _step = _Step.fees);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err.message), backgroundColor: Colors.red),
    );
  }

  void _collectAnother() {
    _searchDebounceTimer?.cancel();
    setState(() {
      _step = _Step.search;
      _studentId = null;
      _studentName = null;
      _outstandingFees = [];
      _selectedFee = null;
      _searchController.clear();
      _searchResults = [];
      _referenceController.clear();
      _notesController.clear();
      _method = 'CASH';
      _submitError = null;
    });
  }

  @override
  Widget build(BuildContext context) => FinancePageFrame(
    embedBodyOnly: widget.embedBodyOnly,
    child: _buildBody(),
  );

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(height: 12),
        ],
        const FinancePageHeader(
          title: 'Collect Payment',
          subtitle: "Record a payment against a student's outstanding fee.",
        ),
        const SizedBox(height: 16),
        switch (_step) {
          _Step.search => _buildSearchStep(),
          _Step.fees => _buildFeesStep(),
          _Step.form => AbsorbPointer(
            absorbing: _submitting,
            child: _buildFormStep(),
          ),
        },
      ],
    );
  }

  Widget _buildSearchStep() {
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinanceSectionTitle('Student'),
          FinanceYearSelector(
            selectedYearId: _yearId,
            onChanged: (v) {
              setState(() => _yearId = v);
              _searchDebounceTimer?.cancel();
              _search(_searchController.text);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            decoration: const InputDecoration(
              labelText: 'Search student by name or EMIS',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            // Pressing search/done on the keyboard runs immediately; typing
            // only schedules a debounced search (see _onSearchChanged).
            onSubmitted: (v) {
              _searchDebounceTimer?.cancel();
              _search(v);
            },
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          if (_searching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: kAdminNavy),
              ),
            ),
          if (_searchError != null) FinanceInlineError(_searchError!),
          if (!_searching && _searchError == null && _searchResults.isEmpty)
            const Text(
              'Search enrolled students by name or EMIS, including students without generated fees.',
              style: TextStyle(color: kAdminTextSecondary, fontSize: 13),
            ),
          if (_searchResults.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kAdminBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < _searchResults.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: kAdminBorder),
                    InkWell(
                      onTap: () {
                        final yearId = _yearId;
                        if (yearId != null)
                          _loadStudentFees(_searchResults[i].studentId, yearId);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            FinanceInitialAvatar(
                              _searchResults[i].studentName,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _searchResults[i].studentName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: kAdminNavy,
                                    ),
                                  ),
                                  Text(
                                    '${_searchResults[i].emisNumber ?? '—'} · ${_searchResults[i].className}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: kAdminTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: kAdminTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeesStep() {
    if (_loadingFees) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: kAdminNavy),
        ),
      );
    }
    if (_feesErrorCode == 'FINANCE_NOT_ENABLED')
      return const FinanceNotEnabledView();
    if (_feesError != null) {
      return AdminErrorState(
        title: 'Could not load fees',
        message: _feesError!,
        onRetry: () {
          final yearId = _yearId;
          final studentId = _studentId;
          if (yearId != null && studentId != null)
            _loadStudentFees(studentId, yearId);
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              FinanceInitialAvatar(_studentName ?? ''),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: kAdminNavy,
                      ),
                    ),
                    const Text(
                      'Select the fee to collect',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: kAdminTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _collectAnother,
                child: const Text('Change student'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_outstandingFees.isEmpty)
          const FinanceCard(
            child: AdminEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Nothing to collect',
              message:
                  'This student has no outstanding fees for this academic year.',
            ),
          )
        else
          FinanceTableCard(
            columns: const [
              AdminTableColumn('Billing Period', flex: 2),
              AdminTableColumn('Charged', flex: 2),
              AdminTableColumn('Paid', flex: 2),
              AdminTableColumn('Remaining', flex: 2),
              AdminTableColumn('Status', flex: 2),
              AdminTableColumn('Actions', flex: 1, align: TextAlign.right),
            ],
            rows: _outstandingFees.map((fee) {
              return AdminTableRow(
                flexes: const [2, 2, 2, 2, 2, 1],
                cells: [
                  Text(
                    fee.billingPeriodLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kAdminNavy,
                    ),
                  ),
                  Text(formatMoney(fee.amount)),
                  Text(formatMoney(fee.paidAmount)),
                  Text(formatMoney(fee.remainingAmount)),
                  FinanceStatusBadge(fee.status),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AdminPrimaryButton(
                      label: 'Select',
                      onPressed: () => _selectFee(fee),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFormStep() {
    final fee = _selectedFee;
    if (fee == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FinanceSectionTitle('Fee Summary'),
              _InfoGrid(
                rows: [
                  ('Student', _studentName ?? '—'),
                  ('Class', fee.className),
                  ('Billing Period', fee.billingPeriodLabel),
                  ('Amount Due', formatMoney(fee.amount)),
                  ('Paid', formatMoney(fee.paidAmount)),
                  ('Remaining', formatMoney(fee.remainingAmount)),
                ],
                columns: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FinanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FinanceSectionTitle('Payment Information'),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              AdminFilterDropdown<String>(
                label: 'Method',
                value: _method,
                items: kPaymentMethods
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(financeLabel(m)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _method = v ?? 'CASH'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                ),
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => Text(
                      '$currentLength / $maxLength',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: kAdminTextSecondary,
                      ),
                    ),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 8),
                FinanceInlineError(_submitError!),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  AdminSecondaryButton(
                    label: 'Back',
                    onPressed: () => setState(() => _step = _Step.fees),
                  ),
                  AdminPrimaryButton(
                    label: _submitting ? 'Processing...' : 'Record Payment',
                    icon: Icons.check_rounded,
                    onPressed: _submitting ? null : _confirmAndSubmit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Label / value pairs laid out in a compact grid (1 column in narrow
/// containers, [columns] when there is room).
class _InfoGrid extends StatelessWidget {
  final List<(String, String)> rows;
  final int columns;
  const _InfoGrid({required this.rows, this.columns = 1});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = box.maxWidth >= 520 ? columns : 1;
      final width = (box.maxWidth - (count - 1) * 16) / count;
      return Wrap(
        spacing: 16,
        runSpacing: 10,
        children: [
          for (final r in rows)
            SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.$1,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kAdminTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.$2,
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
      );
    },
  );
}

/// Shown after a payment is recorded: real receipt, amount and balance from
/// the server response, with Download Receipt / Done.
class _PaymentRecordedDialog extends StatefulWidget {
  final FinancePaymentCollectionResult result;
  final String? studentName;
  final FinancePaymentService service;
  const _PaymentRecordedDialog({
    required this.result,
    required this.studentName,
    required this.service,
  });

  @override
  State<_PaymentRecordedDialog> createState() => _PaymentRecordedDialogState();
}

class _PaymentRecordedDialogState extends State<_PaymentRecordedDialog> {
  bool _downloading = false;

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    await downloadPaymentReceipt(
      context,
      widget.service,
      widget.result.paymentId,
      fallbackName: 'receipt-${widget.result.receiptNumber}.pdf',
    );
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return PopScope(
      canPop: !_downloading,
      child: AdminFeatureDialog(
        title: 'Payment Recorded',
        onClose: _downloading ? () {} : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kAdminGreen.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: kAdminGreen,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _InfoGrid(
              rows: [
                ('Receipt Number', r.receiptNumber),
                ('Student', widget.studentName ?? '—'),
                ('Amount Paid', formatMoney(r.amount)),
                ('Method', financeLabel(r.method)),
                ('Remaining Balance', formatMoney(r.fee.remainingAmount)),
                ('Status', financeLabel(r.fee.status)),
              ],
            ),
            const SizedBox(height: 20),
            FinanceDialogActions(
              cancelLabel: 'Done',
              onCancel: () => Navigator.pop(context),
              primaryLabel: 'Download Receipt',
              busy: _downloading,
              onPrimary: _download,
            ),
          ],
        ),
      ),
    );
  }
}
