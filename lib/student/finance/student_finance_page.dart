import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/pages/finance_payment_details_dialog.dart'
    show financePaymentPeriodLabel;
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/utils/money_format.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/utils/mobile_pdf_save_result.dart';
import 'student_finance_service.dart';

Widget _error(FinanceError error, VoidCallback retry) =>
    error.code == 'FINANCE_NOT_ENABLED'
    ? const FinanceNotEnabledView()
    : AdminErrorState(
        title: error.statusCode == 404
            ? 'Record unavailable'
            : 'Could not load Finance',
        message: error.message,
        onRetry: retry,
      );
void _featureError(BuildContext context, FinanceError error) {
  if (error.code == 'FINANCE_NOT_ENABLED')
    context.read<AuthProvider>().disableFinanceAccess();
}

class StudentFinanceSummaryCard extends StatelessWidget {
  final VoidCallback onView;
  const StudentFinanceSummaryCard({super.key, required this.onView});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.feesEnabled) return const SizedBox.shrink();
    return _DashboardSummary(
      key: ValueKey('${auth.user?.id}:${auth.user?.schoolId}'),
      onView: onView,
    );
  }
}

class _DashboardSummary extends StatefulWidget {
  final VoidCallback onView;
  const _DashboardSummary({super.key, required this.onView});
  @override
  State<_DashboardSummary> createState() => _DashboardSummaryState();
}

class _DashboardSummaryState extends State<_DashboardSummary> {
  FinanceResult<StudentFinanceOverview>? _result;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _result = null);
    final result = await StudentFinanceService().overview(limit: 1);
    if (!mounted) return;
    if (result is FinanceError) _featureError(context, result);
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) => FinanceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FinanceSectionTitle('Fees & Payments'),
        const SizedBox(height: 12),
        if (_result == null)
          const FinanceCardsSkeleton()
        else if (_result case FinanceError error)
          _error(error, _load)
        else
          _SummaryContent(
            data: (_result as FinanceSuccess<StudentFinanceOverview>).data,
          ),
        const SizedBox(height: 16),
        AdminSecondaryButton(label: 'View Fees', onPressed: widget.onView),
      ],
    ),
  );
}

class _SummaryContent extends StatelessWidget {
  final StudentFinanceOverview data;
  const _SummaryContent({required this.data});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        data.summary.yearName,
        style: const TextStyle(color: kAdminTextSecondary),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 28,
        runSpacing: 14,
        children: [
          _amount('Charged', data.summary.charged),
          _amount('Paid', data.summary.paid),
          _amount('Outstanding', data.summary.outstanding),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        data.balanceMessage,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: data.summary.hasOutstanding ? kAdminNavy : kAdminGreen,
        ),
      ),
      if (data.summary.currentStatus != null) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Current month'),
            FinanceStatusBadge(data.summary.currentStatus!),
          ],
        ),
      ],
    ],
  );
  Widget _amount(String label, num amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: kAdminTextSecondary)),
      Text(
        formatMoney(amount),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: kAdminNavy,
        ),
      ),
    ],
  );
}

class StudentFinancePage extends StatelessWidget {
  final bool embedBodyOnly, initialPayments;
  const StudentFinancePage({
    super.key,
    this.embedBodyOnly = false,
    this.initialPayments = false,
  });
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.feesEnabled)
      return FinancePageFrame(
        embedBodyOnly: embedBodyOnly,
        titleInShell: false,
        child: const FinanceNotEnabledView(),
      );
    return _StudentFinanceBody(
      key: ValueKey('${auth.user?.id}:${auth.user?.schoolId}:$initialPayments'),
      embedBodyOnly: embedBodyOnly,
      initialPayments: initialPayments,
    );
  }
}

class _StudentFinanceBody extends StatefulWidget {
  final bool embedBodyOnly, initialPayments;
  const _StudentFinanceBody({
    super.key,
    required this.embedBodyOnly,
    required this.initialPayments,
  });
  @override
  State<_StudentFinanceBody> createState() => _StudentFinanceBodyState();
}

class _StudentFinanceBodyState extends State<_StudentFinanceBody> {
  final _service = StudentFinanceService();
  final _scroll = ScrollController();
  StudentFinanceOverview? _overview;
  FinanceFeeLedgerPage? _fees;
  FinancePaymentPage? _payments;
  List<StudentAcademicYearOption> _years = [];
  String? _yearsError;
  FinanceError? _errorValue;
  bool _loading = true;
  late bool _history = widget.initialPayments;
  int? _year;
  String? _status;
  int _page = 1, _sequence = 0;
  @override
  void initState() {
    super.initState();
    _loadYears();
    _load(reset: true);
  }

  Future<void> _loadYears() async {
    final result = await StudentService().listAcademicYears();
    if (!mounted) return;
    setState(() {
      if (result is StudentSuccess<List<StudentAcademicYearOption>>) {
        _years = result.data;
        _yearsError = null;
      } else {
        _yearsError = 'Academic years could not be loaded.';
      }
    });
  }

  Future<void> _load({bool reset = false}) async {
    final sequence = ++_sequence;
    setState(() {
      _loading = true;
      _errorValue = null;
    });
    FinanceError? error;
    if (reset || _overview == null) {
      final result = await _service.overview(yearId: _year);
      if (!mounted || sequence != _sequence) return;
      if (result is FinanceSuccess<StudentFinanceOverview>) {
        _overview = result.data;
        _year = result.data.summary.yearId;
        _fees = result.data.ledger;
      } else {
        error = result as FinanceError;
      }
    }
    if (error == null && _history) {
      final result = await _service.payments(yearId: _year, page: _page);
      if (!mounted || sequence != _sequence) return;
      if (result is FinanceSuccess<FinancePaymentPage>) {
        _payments = result.data;
      } else {
        error = result as FinanceError;
      }
    } else if (error == null && !reset) {
      final result = await _service.fees(
        yearId: _year,
        page: _page,
        status: _status,
      );
      if (!mounted || sequence != _sequence) return;
      if (result is FinanceSuccess<FinanceFeeLedgerPage>) {
        _fees = result.data;
      } else {
        error = result as FinanceError;
      }
    }
    if (!mounted || sequence != _sequence) return;
    if (error != null) _featureError(context, error);
    if (mounted)
      setState(() {
        _errorValue = error;
        _loading = false;
      });
  }

  @override
  void dispose() {
    _sequence++;
    _scroll.dispose();
    super.dispose();
  }

  void _switch(bool history) {
    if (_history == history) return;
    setState(() {
      _history = history;
      _page = 1;
    });
    _load();
  }

  Future<void> _detail({FeeRecord? fee, FinancePaymentRecord? payment}) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black38,
        builder: (_) => _StudentDetail(
          feeId: fee?.id,
          paymentId: payment?.id,
          yearName: _overview?.summary.yearName ?? '',
        ),
      );
  @override
  Widget build(BuildContext context) => FinancePageFrame(
    embedBodyOnly: widget.embedBodyOnly,
    titleInShell: false,
    scrollController: _scroll,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FinancePageHeader(
          title: 'Fees & Payments',
          subtitle:
              'Your generated fees, balances and receipts. Payments are recorded by the school.',
        ),
        const SizedBox(height: 16),
        if (_overview != null)
          FinanceCard(child: _SummaryContent(data: _overview!)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: AdminFilterDropdown<int>(
                label: 'Academic Year',
                value: _year,
                items:
                    {
                          for (final y in _years) y.id: y.name,
                          if (_overview != null)
                            _overview!.summary.yearId:
                                _overview!.summary.yearName,
                        }.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() {
                          _year = value;
                          _page = 1;
                          _status = null;
                          _overview = null;
                          _fees = null;
                          _payments = null;
                        });
                        _load(reset: true);
                      },
              ),
            ),
            ChoiceChip(
              label: const Text('Fees'),
              selected: !_history,
              onSelected: (_) => _switch(false),
            ),
            ChoiceChip(
              label: const Text('Payment History'),
              selected: _history,
              onSelected: (_) => _switch(true),
            ),
            if (!_history)
              SizedBox(
                width: 180,
                child: AdminFilterDropdown<String>(
                  label: 'Status',
                  value: _status ?? '',
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All statuses')),
                    DropdownMenuItem(value: 'UNPAID', child: Text('Unpaid')),
                    DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
                    DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                  ],
                  onChanged: _loading
                      ? null
                      : (value) {
                          setState(() {
                            _status = value == '' ? null : value;
                            _page = 1;
                          });
                          _load();
                        },
                ),
              ),
            AdminSecondaryButton(
              label: 'Refresh',
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _page = 1;
                        _status = null;
                      });
                      _load(reset: true);
                    },
            ),
          ],
        ),
        if (_yearsError != null)
          TextButton(onPressed: _loadYears, child: Text('$_yearsError Retry')),
        const SizedBox(height: 20),
        if (_loading && _overview == null)
          const FinanceCardsSkeleton()
        else if (_errorValue != null)
          _error(_errorValue!, () => _load(reset: _overview == null))
        else ...[
          if (_loading) const LinearProgressIndicator(),
          AbsorbPointer(
            absorbing: _loading,
            child: _history ? _paymentList() : _feeList(),
          ),
        ],
      ],
    ),
  );
  Widget _feeList() {
    final fees = _fees;
    if (fees == null) return const FinanceCardsSkeleton();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fees.fees.isEmpty)
          AdminEmptyState(
            icon: Icons.receipt_long_outlined,
            title: _status == null ? 'No generated fees' : 'No matching fees',
            message: _status == null
                ? 'No fees have been generated yet.'
                : 'No fees match this status.',
          )
        else
          FinanceTableCard(
            columns: const [
              AdminTableColumn('Period', flex: 2),
              AdminTableColumn('Class', flex: 2),
              AdminTableColumn('Charged'),
              AdminTableColumn('Paid'),
              AdminTableColumn('Remaining'),
              AdminTableColumn('Status'),
              AdminTableColumn('Action'),
            ],
            rows: fees.fees
                .map(
                  (fee) => AdminTableRow(
                    flexes: const [2, 2, 1, 1, 1, 1, 1],
                    cells: [
                      Text(fee.billingPeriodLabel),
                      Text(fee.className),
                      Text(formatMoney(fee.amount)),
                      Text(formatMoney(fee.paidAmount)),
                      Text(formatMoney(fee.remainingAmount)),
                      FinanceStatusBadge(fee.status),
                      AdminSecondaryButton(
                        label: 'Details',
                        onPressed: () => _detail(fee: fee),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        _pagination(fees.page, fees.limit, fees.total, 'fee', 'fees'),
      ],
    );
  }

  Widget _paymentList() {
    final payments = _payments;
    if (payments == null) return const FinanceCardsSkeleton();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (payments.payments.isEmpty)
          const AdminEmptyState(
            icon: Icons.receipt_outlined,
            title: 'No payments',
            message: 'No payments have been recorded yet.',
          )
        else
          FinanceTableCard(
            columns: const [
              AdminTableColumn('Receipt', flex: 2),
              AdminTableColumn('Date', flex: 2),
              AdminTableColumn('Period', flex: 2),
              AdminTableColumn('Amount'),
              AdminTableColumn('Method'),
              AdminTableColumn('Action'),
            ],
            rows: payments.payments
                .map(
                  (p) => AdminTableRow(
                    flexes: const [2, 2, 2, 1, 1, 1],
                    cells: [
                      Text(p.receiptNumber),
                      Text(formatFinanceDate(p.paidAt)),
                      Text(financePaymentPeriodLabel(p)),
                      Text(formatMoney(p.amount)),
                      Text(financeLabel(p.method)),
                      AdminSecondaryButton(
                        label: 'View',
                        onPressed: () => _detail(payment: p),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        _pagination(
          payments.page,
          payments.limit,
          payments.total,
          'payment',
          'payments',
        ),
      ],
    );
  }

  Widget _pagination(
    int page,
    int limit,
    int total,
    String singular,
    String plural,
  ) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: AdminPaginationBar(
      page: page,
      pageSize: limit,
      total: total,
      singular: singular,
      plural: plural,
      onPageChanged: _loading
          ? null
          : (value) {
              if (_scroll.hasClients) _scroll.jumpTo(0);
              setState(() => _page = value);
              _load();
            },
    ),
  );
}

class _StudentDetail extends StatefulWidget {
  final int? feeId, paymentId;
  final String yearName;
  const _StudentDetail({this.feeId, this.paymentId, required this.yearName});
  @override
  State<_StudentDetail> createState() => _StudentDetailState();
}

class _StudentDetailState extends State<_StudentDetail> {
  final _service = StudentFinanceService();
  FeeRecord? _fee;
  FinancePaymentRecord? _payment;
  FinanceError? _errorValue;
  bool _loading = true, _downloading = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorValue = null;
    });
    final result = widget.feeId != null
        ? await _service.fee(widget.feeId!)
        : await _service.payment(widget.paymentId!);
    if (!mounted) return;
    if (result is FinanceSuccess<FeeRecord>)
      _fee = result.data;
    else if (result is FinanceSuccess<FinancePaymentRecord>)
      _payment = result.data;
    else {
      _errorValue = result as FinanceError;
      _featureError(context, _errorValue!);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _receipt() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    final result = await _service.receipt(widget.paymentId!);
    if (!mounted) return;
    if (result is FinanceSuccess<PdfFileResult>) {
      await savePdfWithFeedback(
        context,
        bytes: result.data.bytes,
        filename: sanitizePdfFilename(result.data.filename ?? 'receipt.pdf'),
      );
    } else {
      final error = result as FinanceError;
      _featureError(context, error);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    if (mounted) setState(() => _downloading = false);
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: kAdminTextSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: kAdminNavy,
            ),
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<AuthProvider>().feesEnabled;
    return AdminFeatureDialog(
      title: widget.feeId != null ? 'Fee Details' : 'Payment Details',
      child: !enabled
          ? const FinanceNotEnabledView()
          : _loading
          ? const FinanceCardsSkeleton()
          : _errorValue != null
          ? _error(_errorValue!, _load)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_fee case final f?) ...[
                  _row('Billing period', f.billingPeriodLabel),
                  _row('Academic year', widget.yearName),
                  _row('Class', f.className),
                  _row('Original amount', formatMoney(f.originalAmount)),
                  _row(
                    'Discount',
                    '${formatMoney(f.discountAmount)} (${formatMoney(f.discountPercentage)}%)',
                  ),
                  _row('Charged', formatMoney(f.amount)),
                  _row('Paid', formatMoney(f.paidAmount)),
                  _row('Remaining', formatMoney(f.remainingAmount)),
                  if (f.dueDate.isNotEmpty)
                    _row('Due date', formatFinanceDate(f.dueDate)),
                  FinanceStatusBadge(f.status),
                ],
                if (_payment case final p?) ...[
                  _row('Receipt number', p.receiptNumber),
                  _row('Amount', formatMoney(p.amount)),
                  _row('Method', financeLabel(p.method)),
                  _row('Payment date', formatFinanceDate(p.paidAt)),
                  if (p.referenceNumber?.isNotEmpty == true)
                    _row('Reference', p.referenceNumber!),
                  _row('Academic year', widget.yearName),
                  _row('Billing period', financePaymentPeriodLabel(p)),
                  _row('Class', p.className),
                  const SizedBox(height: 16),
                  if (_downloading) const LinearProgressIndicator(),
                  AdminPrimaryButton(
                    label: _downloading ? 'Downloading…' : 'Download Receipt',
                    onPressed: _downloading ? null : _receipt,
                  ),
                ],
              ],
            ),
    );
  }
}
