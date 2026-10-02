import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/class_fee.dart';
import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/services/class_fee_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/finance_payment_service.dart';
import 'package:kobac/finance/pages/finance_payment_details_dialog.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String basePath;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const PaymentHistoryPage({
    super.key,
    required this.basePath,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final ScrollController _pageScroll = ScrollController();

  late final FinancePaymentService _service = FinancePaymentService(
    basePath: widget.basePath,
  );
  late final ClassFeeService _classFeeService = ClassFeeService(
    basePath: widget.basePath,
  );

  int? _yearId;
  int? _classId;
  String? _method;
  DateTimeRange? _dates;
  String? _errorCode;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  int _page = 1;
  static const _limit = 50;

  List<ClassFee> _classes = [];
  FinancePaymentPage? _paymentPage;
  bool _loading = true;
  int _loadRequest = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AcademicYearsProvider>();
      await ensureFinanceYears(provider);
      if (!mounted) return;
      final yearId = widget.basePath.contains('school-admin')
          ? selectedFinanceYear(provider)
          : null;
      setState(() => _yearId = yearId);
      if (yearId != null) {
        final classResult = await _classFeeService.list(academicYearId: yearId);
        if (mounted && classResult is FinanceSuccess<List<ClassFee>>) {
          setState(() => _classes = classResult.data);
        }
      }
      _load();
    });
  }

  @override
  void dispose() {
    _pageScroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (_yearId == null && widget.basePath.contains('school-admin')) {
      setState(() => _loading = false);
      return;
    }
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
    });
    final result = await _service.list(
      academicYearId: _yearId,
      classId: _classId,
      method: _method,
      dateFrom: _dates?.start.toIso8601String().split('T').first,
      dateTo: _dates?.end.toIso8601String().split('T').first,
      search: _search.isEmpty ? null : _search,
      page: _page,
      limit: _limit,
    );
    if (!mounted || request != _loadRequest) return;
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<FinancePaymentPage>) {
        _paymentPage = result.data;
      } else {
        _paymentPage = null;
        _error = (result as FinanceError).message;
        _errorCode = result.code;
      }
    });
  }

  Future<void> _loadYearClasses(int yearId) async {
    final result = await _classFeeService.list(academicYearId: yearId);
    if (!mounted || _yearId != yearId) return;
    if (result is FinanceSuccess<List<ClassFee>>)
      setState(() => _classes = result.data);
  }

  void _resetAndLoad() {
    _page = 1;
    _load();
  }

  @override
  Widget build(BuildContext context) => FinancePageFrame(
    embedBodyOnly: widget.embedBodyOnly,
    scrollController: _pageScroll,
    child: _buildBody(),
  );

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinancePageHeader(
          title: 'Payment History',
          subtitle: widget.basePath.contains('school-admin')
              ? 'Recorded payments for the selected academic year.'
              : 'Recorded payments across all academic years. Filter by date or search.',
        ),
        const SizedBox(height: 14),
        FinanceFilterBar(
          filters: [
            if (widget.basePath.contains('school-admin'))
              FinanceYearSelector(
                selectedYearId: _yearId,
                onChanged: (v) {
                  setState(() {
                    _yearId = v;
                    _classId = null;
                    _classes = [];
                  });
                  if (v != null) _loadYearClasses(v);
                  _resetAndLoad();
                },
              ),
            if (widget.basePath.contains('school-admin'))
              AdminFilterDropdown<int>(
                label: 'Class',
                value: _classId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All classes'),
                  ),
                  ..._classes.map(
                    (c) => DropdownMenuItem(
                      value: c.classId,
                      child: Text(c.className),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _classId = v);
                  _resetAndLoad();
                },
              ),
            AdminFilterDropdown<String>(
              label: 'Method',
              value: _method,
              items: [
                const DropdownMenuItem(value: null, child: Text('All methods')),
                ...kPaymentMethods.map(
                  (m) =>
                      DropdownMenuItem(value: m, child: Text(financeLabel(m))),
                ),
              ],
              onChanged: (v) {
                setState(() => _method = v);
                _resetAndLoad();
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range_outlined, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: kAdminNavy,
                side: const BorderSide(color: kAdminBorder),
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              label: Text(
                _dates == null
                    ? 'Date range'
                    : '${formatFinanceDate(_dates!.start.toIso8601String())} - ${formatFinanceDate(_dates!.end.toIso8601String())}',
              ),
              onPressed: () async {
                final dates = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 366)),
                  initialDateRange: _dates,
                );
                if (!mounted || dates == null) return;
                setState(() => _dates = dates);
                _resetAndLoad();
              },
            ),
            if (_dates != null)
              TextButton(
                onPressed: () {
                  setState(() => _dates = null);
                  _resetAndLoad();
                },
                child: const Text('Clear dates'),
              ),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search student, EMIS, receipt, or reference',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (v) {
                _search = v;
                _resetAndLoad();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        AbsorbPointer(absorbing: _loading, child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_errorCode == 'FINANCE_NOT_ENABLED')
      return const FinanceNotEnabledView();
    if (_loading && _paymentPage == null)
      return const Center(child: CircularProgressIndicator(color: kAdminNavy));
    if (_error != null) {
      return AdminErrorState(
        title: 'Could not load payment history',
        message: _error!,
        onRetry: _load,
      );
    }
    final page = _paymentPage;
    if (page == null || page.payments.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No payments found',
        message: 'No payments found for the selected filters.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceTableCard(
          columns: const [
            AdminTableColumn('Receipt #', flex: 2),
            AdminTableColumn('Date', flex: 2),
            AdminTableColumn('Student', flex: 2),
            AdminTableColumn('Amount', flex: 2),
            AdminTableColumn('Method', flex: 1),
            AdminTableColumn('Recorded By', flex: 2),
            AdminTableColumn('Actions', flex: 2, align: TextAlign.right),
          ],
          rows: page.payments.map((p) {
            return AdminTableRow(
              flexes: const [2, 2, 3, 2, 1, 2, 2],
              onTap: () => _openDetails(p.id),
              cells: [
                Text(
                  p.receiptNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kAdminNavy,
                  ),
                ),
                Text(formatFinanceDate(p.paidAt)),
                Text(p.studentName),
                Text(formatMoney(p.amount)),
                Text(financeLabel(p.method)),
                Text(p.recordedBy.name ?? '—'),
                Align(
                  alignment: Alignment.centerRight,
                  child: AdminSecondaryButton(
                    label: 'View',
                    onPressed: () => _openDetails(p.id),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPagination(page),
      ],
    );
  }

  void _openDetails(int paymentId) => showFinancePaymentDetailsDialog(
    context,
    basePath: widget.basePath,
    paymentId: paymentId,
  );

  Widget _buildPagination(FinancePaymentPage page) => AdminPaginationBar(
    page: page.page,
    pageSize: page.limit,
    total: page.total,
    singular: 'payment',
    plural: 'payments',
    onPageChanged: _loading
        ? null
        : (p) {
            if (_pageScroll.hasClients) _pageScroll.jumpTo(0);
            setState(() => _page = p);
            _load();
          },
  );
}
