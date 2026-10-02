import 'package:flutter/material.dart';
import 'package:kobac/finance/models/finance_payment.dart';
import 'package:kobac/finance/services/finance_payment_service.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/fee_record.dart';
import 'package:kobac/finance/services/fee_ledger_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/pages/finance_payment_details_dialog.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

class StudentFeeLedgerPage extends StatefulWidget {
  final String basePath;
  final int studentId;
  final int academicYearId;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentFeeLedgerPage({
    super.key,
    required this.basePath,
    required this.studentId,
    required this.academicYearId,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<StudentFeeLedgerPage> createState() => _StudentFeeLedgerPageState();
}

class _StudentFeeLedgerPageState extends State<StudentFeeLedgerPage> {
  late final FeeLedgerService _service = FeeLedgerService(
    basePath: widget.basePath,
  );
  StudentFeeLedger? _ledger;
  FinancePaymentHistory? _payments;
  String? _paymentsError;
  bool _loading = true;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
    });
    final result = await _service.studentLedger(
      studentId: widget.studentId,
      academicYearId: widget.academicYearId,
    );
    final history = await FinancePaymentService(basePath: widget.basePath)
        .studentHistory(
          studentId: widget.studentId,
          academicYearId: widget.academicYearId,
        );
    if (!mounted) return;
    setState(() {
      _payments = history is FinanceSuccess<FinancePaymentHistory>
          ? history.data
          : null;
      _paymentsError = history is FinanceError ? history.message : null;
      _loading = false;
      if (result is FinanceSuccess<StudentFeeLedger>) {
        _ledger = result.data;
      } else {
        final err = result as FinanceError;
        _ledger = null;
        _error = err.message;
        _errorCode = err.code;
      }
    });
  }

  @override
  Widget build(BuildContext context) => FinancePageFrame(
    embedBodyOnly: widget.embedBodyOnly,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinancePageHeader(
          title: 'Student Ledger',
          secondaryActions: [
            AdminSecondaryButton(
              label: 'Back to ledger',
              onPressed: () =>
                  widget.onNavigateToPage?.call('financeFeeLedger'),
            ),
          ],
          subtitle: _ledger == null
              ? 'Fees and payments for this student.'
              : '${_ledger!.studentName} · ${_ledger!.emisNumber ?? '—'} · ${_ledger!.className ?? '—'} · ${_ledger!.academicYearName}',
        ),
        const SizedBox(height: 16),

        _buildBody(),
      ],
    ),
  );

  Widget _buildBody() {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: kAdminNavy));
    if (_errorCode == 'FINANCE_NOT_ENABLED')
      return const FinanceNotEnabledView();
    if (_error != null) {
      return AdminErrorState(
        title: 'Could not load the student ledger',
        message: _error!,
        onRetry: _load,
      );
    }
    final ledger = _ledger;
    if (ledger == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceSummaryGrid(
          tiles: [
            AdminStatTile(
              icon: Icons.attach_money_rounded,
              color: kAdminNavy,
              value: formatMoney(ledger.summary.totalOriginal),
              label: 'Original Fees',
            ),
            AdminStatTile(
              icon: Icons.percent_rounded,
              color: kAdminNavy,
              value: formatMoney(ledger.summary.totalDiscount),
              label: 'Discounts',
            ),
            AdminStatTile(
              icon: Icons.receipt_long_outlined,
              color: kAdminNavy,
              value: formatMoney(ledger.summary.totalCharged),
              label: 'Charged',
            ),
            AdminStatTile(
              icon: Icons.check_circle_outline_rounded,
              color: kAdminGreen,
              value: formatMoney(ledger.summary.totalPaid),
              label: 'Paid',
            ),
            AdminStatTile(
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFF59E0B),
              value: formatMoney(ledger.summary.totalRemaining),
              label: 'Remaining',
            ),
            AdminStatTile(
              icon: Icons.check_circle_rounded,
              color: kAdminGreen,
              value: '${ledger.summary.paidCount}',
              label: 'Paid Fees',
            ),
            AdminStatTile(
              icon: Icons.hourglass_bottom_rounded,
              color: const Color(0xFFF59E0B),
              value: '${ledger.summary.partialCount}',
              label: 'Partial Fees',
            ),
            AdminStatTile(
              icon: Icons.cancel_outlined,
              color: feeStatusColor('UNPAID'),
              value: '${ledger.summary.unpaidCount}',
              label: 'Unpaid Fees',
            ),
          ],
        ),
        const SizedBox(height: 22),
        const FinanceSectionTitle('Fees by billing period'),
        if (ledger.fees.isEmpty)
          const AdminEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No fees found',
            message: 'No fees have been generated yet for this student.',
          )
        else
          FinanceTableCard(
            columns: const [
              AdminTableColumn('Period', flex: 2),
              AdminTableColumn('Original', flex: 2),
              AdminTableColumn('Discount', flex: 2),
              AdminTableColumn('Charged', flex: 2),
              AdminTableColumn('Paid', flex: 2),
              AdminTableColumn('Remaining', flex: 2),
              AdminTableColumn('Status', flex: 2),
              AdminTableColumn('Actions', flex: 2, align: TextAlign.right),
            ],
            rows: ledger.fees.map((fee) {
              return AdminTableRow(
                flexes: const [2, 2, 2, 2, 2, 2, 2, 2],
                cells: [
                  Text(
                    fee.billingPeriodLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kAdminNavy,
                    ),
                  ),
                  Text(formatMoney(fee.originalAmount)),
                  Text(
                    '${formatMoney(fee.discountAmount)} (${formatMoney(fee.discountPercentage)}%)',
                  ),
                  Text(formatMoney(fee.amount)),
                  Text(formatMoney(fee.paidAmount)),
                  Text(formatMoney(fee.remainingAmount)),
                  FinanceStatusBadge(fee.status),
                  Align(
                    alignment: Alignment.centerRight,
                    child: fee.canCollectPayment
                        ? AdminPrimaryButton(
                            label: 'Collect',
                            onPressed: () => widget.onNavigateToPage?.call(
                              'financeCollectPayment',
                              arguments: {
                                'studentId': fee.studentId,
                                'feeId': fee.id,
                                'academicYearId': fee.academicYearId,
                              },
                            ),
                          )
                        : const Text('—'),
                  ),
                ],
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
        const FinanceSectionTitle('Payment history'),
        if (_paymentsError != null)
          AdminErrorState(
            title: 'Could not load payments',
            message: _paymentsError!,
            onRetry: _load,
          )
        else if (_payments?.payments.isEmpty ?? true)
          const Text('No payments recorded for this academic year.')
        else
          FinanceTableCard(
            columns: const [
              AdminTableColumn('Receipt', flex: 2),
              AdminTableColumn('Date', flex: 2),
              AdminTableColumn('Amount', flex: 2),
              AdminTableColumn('Method'),
              AdminTableColumn('Actions'),
            ],
            rows: _payments!.payments
                .map(
                  (p) => AdminTableRow(
                    flexes: const [2, 2, 2, 1, 1],
                    cells: [
                      Text(
                        p.receiptNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kAdminNavy,
                        ),
                      ),
                      Text(formatFinanceDate(p.paidAt)),
                      Text(formatMoney(p.amount)),
                      Text(financeLabel(p.method)),
                      AdminSecondaryButton(
                        label: 'View',
                        onPressed: () => showFinancePaymentDetailsDialog(
                          context,
                          basePath: widget.basePath,
                          paymentId: p.id,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
