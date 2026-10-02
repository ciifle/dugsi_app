import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/class_fee.dart';
import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/services/class_fee_service.dart';
import 'package:kobac/finance/services/fee_ledger_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

const List<String> kFeeStatusFilters = ['UNPAID', 'PARTIAL', 'PAID'];

class FeeLedgerPage extends StatefulWidget {
  final String basePath;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const FeeLedgerPage({
    super.key,
    required this.basePath,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<FeeLedgerPage> createState() => _FeeLedgerPageState();
}

class _FeeLedgerPageState extends State<FeeLedgerPage> {
  final ScrollController _pageScroll = ScrollController();

  late final FeeLedgerService _service = FeeLedgerService(
    basePath: widget.basePath,
  );
  late final ClassFeeService _classFeeService = ClassFeeService(
    basePath: widget.basePath,
  );

  int? _yearId;
  int? _classId;
  String? _status;
  String? _billingCycle;
  int? _billingYear;
  int? _billingMonth;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  int _page = 1;
  static const _limit = 50;

  List<ClassFee> _classes = [];
  FinanceFeeLedgerPage? _ledgerPage;
  bool _loading = true;
  int _loadRequest = 0;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AcademicYearsProvider>();
      await ensureFinanceYears(provider);
      if (!mounted) return;
      final yearId = selectedFinanceYear(provider);
      if (yearId == null) {
        setState(() => _loading = false);
        return;
      }
      setState(() => _yearId = yearId);
      final classResult = await _classFeeService.list(academicYearId: yearId);
      if (mounted && classResult is FinanceSuccess<List<ClassFee>>) {
        setState(() => _classes = classResult.data);
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
    final request = ++_loadRequest;
    final yearId = _yearId;
    if (yearId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
    });
    final result = await _service.listFees(
      academicYearId: yearId,
      classId: _classId,
      status: _status,
      billingCycle: _billingCycle,
      billingYear: _billingYear,
      billingMonth: _billingMonth,
      search: _search.isEmpty ? null : _search,
      page: _page,
      limit: _limit,
    );
    if (!mounted || request != _loadRequest) return;
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<FinanceFeeLedgerPage>) {
        _ledgerPage = result.data;
      } else {
        final err = result as FinanceError;
        _ledgerPage = null;
        _error = err.message;
        _errorCode = err.code;
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
        const FinancePageHeader(
          title: 'Fee Ledger',
          subtitle:
              'Review generated fees, balances and payment status for the academic year.',
        ),
        const SizedBox(height: 14),
        FinanceFilterBar(
          filters: [
            FinanceYearSelector(
              selectedYearId: _yearId,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _yearId = v;
                  _classId = null;
                  _classes = [];
                });
                _loadYearClasses(v);
                _resetAndLoad();
              },
            ),
            AdminFilterDropdown<int>(
              label: 'Class',
              value: _classId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All classes')),
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
              label: 'Status',
              value: _status,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All statuses'),
                ),
                ...kFeeStatusFilters.map(
                  (s) =>
                      DropdownMenuItem(value: s, child: Text(financeLabel(s))),
                ),
              ],
              onChanged: (v) {
                setState(() => _status = v);
                _resetAndLoad();
              },
            ),
            AdminFilterDropdown<String>(
              label: 'Billing Cycle',
              value: _billingCycle,
              items: [
                const DropdownMenuItem(value: null, child: Text('All cycles')),
                ...kBillingCycles.map(
                  (c) =>
                      DropdownMenuItem(value: c, child: Text(financeLabel(c))),
                ),
              ],
              onChanged: (v) {
                setState(() => _billingCycle = v);
                _resetAndLoad();
              },
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Billing year (optional)',
              ),
              onSubmitted: (value) {
                final year = int.tryParse(value.trim());
                if (value.trim().isNotEmpty && year == null) return;
                _billingYear = year;
                _resetAndLoad();
              },
            ),
            AdminFilterDropdown<int>(
              label: 'Billing month',
              value: _billingMonth,
              items: [
                const DropdownMenuItem(value: null, child: Text('All months')),
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(value: m, child: Text(kMonthNames[m - 1])),
              ],
              onChanged: (value) {
                setState(() => _billingMonth = value);
                _resetAndLoad();
              },
            ),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search student or EMIS',
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
    if (_loading && _ledgerPage == null)
      return const Center(child: CircularProgressIndicator(color: kAdminNavy));
    if (_errorCode == 'FINANCE_NOT_ENABLED')
      return const FinanceNotEnabledView();
    if (_error != null) {
      return AdminErrorState(
        title: 'Could not load the fee ledger',
        message: _error!,
        onRetry: _load,
      );
    }
    final page = _ledgerPage;
    if (page == null || page.fees.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No fees found',
        message: 'No generated fees found for the selected filters.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceTableCard(
          columns: const [
            AdminTableColumn('Student', flex: 3),
            AdminTableColumn('EMIS', flex: 2),
            AdminTableColumn('Class', flex: 2),
            AdminTableColumn('Period', flex: 2),
            AdminTableColumn('Charged', flex: 2),
            AdminTableColumn('Paid', flex: 2),
            AdminTableColumn('Remaining', flex: 2),
            AdminTableColumn('Status', flex: 2),
            AdminTableColumn('Actions', flex: 1, align: TextAlign.right),
          ],
          rows: page.fees.map((fee) => _buildRow(fee)).toList(),
        ),
        const SizedBox(height: 12),
        _buildPagination(page),
      ],
    );
  }

  Map<String, int> _studentLedgerArgs(FeeRecord fee) => {
    'studentId': fee.studentId,
    'academicYearId': fee.academicYearId,
  };

  AdminTableRow _buildRow(FeeRecord fee) {
    return AdminTableRow(
      flexes: const [3, 2, 2, 2, 2, 2, 2, 2, 1],
      onTap: () => widget.onNavigateToPage?.call(
        'financeStudentLedger',
        arguments: _studentLedgerArgs(fee),
      ),
      cells: [
        Text(
          fee.studentName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: kAdminNavy,
          ),
        ),
        Text(fee.emisNumber ?? '—'),
        Text(fee.className),
        Text(fee.billingPeriodLabel),
        Text(formatMoney(fee.amount)),
        Text(formatMoney(fee.paidAmount)),
        Text(formatMoney(fee.remainingAmount)),
        FinanceStatusBadge(fee.status),
        Align(
          alignment: Alignment.centerRight,
          child: FinanceActionMenu(
            actions: [
              FinanceMenuAction(
                'View Ledger',
                Icons.receipt_long_outlined,
                () => widget.onNavigateToPage?.call(
                  'financeStudentLedger',
                  arguments: _studentLedgerArgs(fee),
                ),
              ),
              if (fee.canCollectPayment)
                FinanceMenuAction(
                  'Collect Payment',
                  Icons.payments_outlined,
                  () => widget.onNavigateToPage?.call(
                    'financeCollectPayment',
                    arguments: {
                      'studentId': fee.studentId,
                      'feeId': fee.id,
                      'academicYearId': fee.academicYearId,
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(FinanceFeeLedgerPage page) => AdminPaginationBar(
    page: page.page,
    pageSize: page.limit,
    total: page.total,
    singular: 'fee',
    plural: 'fees',
    onPageChanged: _loading
        ? null
        : (p) {
            if (_pageScroll.hasClients) _pageScroll.jumpTo(0);
            setState(() => _page = p);
            _load();
          },
  );
}
