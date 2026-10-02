import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/quick_action_card.dart';
import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/services/finance_payment_service.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/finance_dashboard.dart';
import 'package:kobac/finance/services/fee_ledger_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/finance_collection_service.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

class FinanceDashboardPage extends StatefulWidget {
  final String basePath;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const FinanceDashboardPage({
    super.key,
    required this.basePath,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends State<FinanceDashboardPage> {
  late final FeeLedgerService _service = FeeLedgerService(
    basePath: widget.basePath,
  );
  FinanceDashboard? _dashboard;
  bool _loading = true;
  int _loadRequest = 0;
  String? _error;
  String? _errorCode;
  int? _selectedYearId;
  List<FinancePaymentRecord> _recentPayments = const [];

  @override
  void initState() {
    super.initState();
    financeCollectionChanges.addListener(_onCollection);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AcademicYearsProvider>();
      await ensureFinanceYears(provider);
      if (!mounted) return;
      final yearId = selectedFinanceYear(provider);
      if (yearId == null) {
        setState(() => _loading = false);
        return;
      }
      setState(() => _selectedYearId = yearId);
      _load(yearId);
    });
  }

  Future<void> _load(int yearId) async {
    if (!mounted) return;
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
    });
    final result = await _service.dashboard(academicYearId: yearId);
    // Recent payments are supplementary: a failure just hides the section.
    final recent = await FinancePaymentService(
      basePath: widget.basePath,
    ).list(academicYearId: yearId, limit: 5);
    if (!mounted || request != _loadRequest) return;
    _recentPayments = recent is FinanceSuccess<FinancePaymentPage>
        ? recent.data.payments
        : const [];
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<FinanceDashboard>) {
        _dashboard = result.data;
      } else {
        final err = result as FinanceError;
        _dashboard = null;
        _error = err.message;
        _errorCode = err.code;
      }
    });
  }

  void _onCollection() {
    final yearId = _selectedYearId;
    if (mounted && yearId != null) _load(yearId);
  }

  @override
  void dispose() {
    financeCollectionChanges.removeListener(_onCollection);
    super.dispose();
  }

  void _onYearChanged(int? yearId) {
    if (yearId == null || yearId == _selectedYearId) return;
    setState(() => _selectedYearId = yearId);
    _load(yearId);
  }

  @override
  Widget build(BuildContext context) {
    final yearsState = context.watch<AcademicYearsProvider>();
    return FinancePageFrame(
      embedBodyOnly: widget.embedBodyOnly,
      child: _buildBody(yearsState),
    );
  }

  Widget _buildBody(AcademicYearsProvider yearsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinancePageHeader(
          title: 'Finance',
          subtitle: 'Manage school fees, collections and student balances.',
        ),
        const SizedBox(height: 14),
        FinanceYearSelector(
          selectedYearId: _selectedYearId,
          onChanged: _onYearChanged,
        ),
        const SizedBox(height: 16),
        if (_loading)
          const FinanceCardsSkeleton()
        else if (_errorCode == 'FINANCE_NOT_ENABLED')
          const FinanceNotEnabledView()
        else if (_error != null)
          AdminErrorState(
            title: 'Could not load dashboard',
            message: _error!,
            onRetry: () {
              final yearId = _selectedYearId;
              if (yearId != null) _load(yearId);
            },
          )
        else if (_dashboard == null)
          const AdminEmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No academic year selected',
            message: 'Create or select an academic year to see finance totals.',
          )
        else
          _buildStats(_dashboard!),
      ],
    );
  }

  Widget _buildStats(FinanceDashboard d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceSummaryGrid(
          tiles: [
            AdminStatTile(
              icon: Icons.account_balance_wallet_rounded,
              color: kAdminNavy,
              value: formatMoney(d.totalCharged),
              label: 'Total Billed',
            ),
            AdminStatTile(
              icon: Icons.check_circle_outline_rounded,
              color: kAdminGreen,
              value: formatMoney(d.totalPaid),
              label: 'Total Collected',
            ),
            AdminStatTile(
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFF59E0B),
              value: formatMoney(d.totalOutstanding),
              label: 'Outstanding Balance',
            ),
            AdminStatTile(
              icon: Icons.percent_rounded,
              color: kAdminNavy,
              value: formatMoney(d.totalDiscount),
              label: 'Total Discounts',
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, box) {
            final collections = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinanceSectionTitle('Collections'),
                FinanceSummaryGrid(
                  tiles: [
                    AdminStatTile(
                      icon: Icons.today_rounded,
                      color: kAdminNavy,
                      value: formatMoney(d.collectionsToday),
                      label: 'Collected Today',
                    ),
                    AdminStatTile(
                      icon: Icons.calendar_view_month_rounded,
                      color: kAdminNavy,
                      value: formatMoney(d.collectionsThisMonth),
                      label: 'Collected This Month',
                    ),
                  ],
                ),
              ],
            );
            final status = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinanceSectionTitle('Fee Status'),
                FinanceSummaryGrid(
                  tiles: [
                    AdminStatTile(
                      icon: Icons.check_circle_rounded,
                      color: kAdminGreen,
                      value: '${d.paidFees}',
                      label: 'Paid',
                    ),
                    AdminStatTile(
                      icon: Icons.hourglass_bottom_rounded,
                      color: const Color(0xFFF59E0B),
                      value: '${d.partialFees}',
                      label: 'Partial',
                    ),
                    AdminStatTile(
                      icon: Icons.cancel_outlined,
                      color: feeStatusColor('UNPAID'),
                      value: '${d.unpaidFees}',
                      label: 'Unpaid',
                    ),
                    AdminStatTile(
                      icon: Icons.volunteer_activism_rounded,
                      color: kAdminNavy,
                      value: '${d.fullyDiscountedFeeCount}',
                      label: 'Fully Discounted (Free)',
                    ),
                  ],
                ),
              ],
            );
            if (box.maxWidth >= 1100) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: collections),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: status),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [collections, const SizedBox(height: 22), status],
            );
          },
        ),
        const SizedBox(height: 22),
        const FinanceSectionTitle('Quick Actions'),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 900 ? 4 : 2;
            const gap = 10.0;
            final width = (box.maxWidth - (cols - 1) * gap) / cols;
            Widget card(
              IconData icon,
              Color color,
              String title,
              String description,
              String page,
            ) => SizedBox(
              width: width,
              height: 72,
              child: QuickActionCard(
                icon: icon,
                iconColor: color,
                title: title,
                description: description,
                onTap: () => widget.onNavigateToPage?.call(page),
              ),
            );
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                card(
                  Icons.payments_rounded,
                  kAdminGreen,
                  'Collect Payment',
                  'Record a payment',
                  'financeCollectPayment',
                ),
                card(
                  Icons.list_alt_rounded,
                  kAdminNavy,
                  'View Ledger',
                  'Fees and balances',
                  'financeFeeLedger',
                ),
                card(
                  Icons.receipt_long_rounded,
                  kAdminNavy,
                  'Generate Fees',
                  'Preview and create',
                  'financeGenerateFees',
                ),
                card(
                  Icons.history_rounded,
                  kAdminNavy,
                  'Payment History',
                  'Past payments',
                  'financePaymentHistory',
                ),
              ],
            );
          },
        ),
        if (_recentPayments.isNotEmpty) ...[
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: FinanceSectionTitle('Recent Payments')),
              TextButton(
                onPressed: () =>
                    widget.onNavigateToPage?.call('financePaymentHistory'),
                child: const Text('View all'),
              ),
            ],
          ),
          FinanceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _recentPayments.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: kAdminBorder),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        FinanceInitialAvatar(
                          _recentPayments[i].studentName,
                          size: 34,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _recentPayments[i].studentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: kAdminNavy,
                                ),
                              ),
                              Text(
                                '${_recentPayments[i].receiptNumber} · ${formatFinanceDate(_recentPayments[i].paidAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kAdminTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(_recentPayments[i].amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: kAdminGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
