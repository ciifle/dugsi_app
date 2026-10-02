import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/fee_generation.dart';
import 'package:kobac/finance/services/fee_generation_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

class GenerateFeesPage extends StatefulWidget {
  final String basePath;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const GenerateFeesPage({
    super.key,
    required this.basePath,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<GenerateFeesPage> createState() => _GenerateFeesPageState();
}

class _GenerateFeesPageState extends State<GenerateFeesPage> {
  late final FeeGenerationService _service = FeeGenerationService(
    basePath: widget.basePath,
  );

  int? _yearId;
  String _cycle = 'MONTHLY'; // MONTHLY | YEARLY
  int? _month;
  int? _year;

  bool _previewing = false;
  bool _generating = false;
  bool _generated = false;
  String? _error;
  FeeGenerationResult? _result;

  AcademicYear? get _selectedYear {
    final years = context.read<AcademicYearsProvider>().years;
    if (_yearId == null) return null;
    final matches = years.where((y) => y.id == _yearId);
    return matches.isEmpty ? null : matches.first;
  }

  List<int> get _validMonthsForYear {
    final year = _selectedYear;
    if (year?.startDate == null || year?.endDate == null) {
      return List.generate(12, (i) => i + 1);
    }
    final start = year!.startDate!;
    final end = year.endDate!;
    final months = <int>{};
    var cursor = DateTime(start.year, start.month, 1);
    final endCursor = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(endCursor)) {
      if (_year == null || cursor.year == _year) months.add(cursor.month);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months.toList()..sort();
  }

  int get _defaultBillingYear =>
      _selectedYear?.startDate?.year ?? DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AcademicYearsProvider>();
      await ensureFinanceYears(provider);
      if (!mounted) return;
      final yearId = selectedFinanceYear(provider);
      setState(() {
        _yearId = yearId;
        _year = _defaultBillingYear;
      });
    });
  }

  Future<void> _preview() async {
    final yearId = _yearId;
    if (yearId == null ||
        _previewing ||
        _generating ||
        (_cycle == 'MONTHLY' && _month == null))
      return;
    setState(() {
      _previewing = true;
      _generated = false;
      _error = null;
      _result = null;
    });
    final result = await _service.preview(
      academicYearId: yearId,
      billingYear: _cycle == 'MONTHLY' ? (_year ?? _defaultBillingYear) : null,
      billingMonth: _cycle == 'MONTHLY' ? _month : null,
    );
    if (!mounted) return;
    setState(() {
      _previewing = false;
      if (result is FinanceSuccess<FeeGenerationResult>) {
        _result = result.data;
      } else {
        _error = (result as FinanceError).message;
      }
    });
  }

  Future<void> _confirmAndGenerate() async {
    final yearId = _yearId;
    final preview = _result;
    if (yearId == null ||
        preview == null ||
        _generating ||
        _previewing ||
        _generated)
      return;
    setState(() => _generating = true);
    final periodLabel = preview.period.billingCycle == 'MONTHLY'
        ? '${kMonthNames[preview.period.billingMonth - 1]} ${preview.period.billingYear}'
        : 'Yearly ${preview.period.billingYear}';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => AdminFeatureDialog(
        title: 'Generate Fees?',
        onClose: () => Navigator.pop(dialogContext, false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This creates fee ledger entries for $periodLabel.',
              style: const TextStyle(height: 1.4, color: kAdminNavy),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kAdminNavy.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _confirmRow(
                    'Will Generate',
                    '${preview.summary.willGenerate}',
                  ),
                  _confirmRow(
                    'Already Existing',
                    '${preview.summary.alreadyGenerated}',
                  ),
                  _confirmRow(
                    'Net Amount',
                    formatMoney(preview.summary.netAmount),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FinanceDialogActions(
              primaryLabel: 'Generate Fees',
              onCancel: () => Navigator.pop(dialogContext, false),
              onPrimary: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _generating = false);
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    final result = await _service.generate(
      academicYearId: yearId,
      billingYear: _cycle == 'MONTHLY' ? (_year ?? _defaultBillingYear) : null,
      billingMonth: _cycle == 'MONTHLY' ? _month : null,
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (result is FinanceSuccess<FeeGenerationResult>) {
        _result = result.data;
        _generated = true;
      } else {
        _error = (result as FinanceError).message;
      }
    });
  }

  static Widget _confirmRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: kAdminTextSecondary, fontSize: 13.5),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: kAdminNavy,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FinancePageFrame(
    embedBodyOnly: widget.embedBodyOnly,
    child: _buildBody(),
  );

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FinancePageHeader(
          title: 'Generate Fees',
          subtitle: 'Preview a billing period, then generate fee rows for it.',
        ),
        const SizedBox(height: 16),
        IgnorePointer(
          ignoring: _previewing || _generating,
          child: _buildStepOneAndTwo(),
        ),
        const SizedBox(height: 16),
        if (_previewing)
          const Center(child: CircularProgressIndicator(color: kAdminNavy))
        else if (_error != null)
          AdminErrorState(
            title: 'Request failed',
            message: _error!,
            onRetry: _preview,
          )
        else if (_result != null)
          _buildPreviewResult(_result!),
      ],
    );
  }

  Widget _buildStepOneAndTwo() {
    final years = context.watch<AcademicYearsProvider>().years;
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinanceSectionTitle('Academic Year'),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AdminFilterDropdown<int>(
              label: 'Academic Year',
              value: _yearId,
              items: years
                  .map(
                    (y) => DropdownMenuItem(value: y.id, child: Text(y.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _yearId = v;
                rememberFinanceYear(context.read<AcademicYearsProvider>(), v);
                _month = null;
                _year = _defaultBillingYear;
                _result = null;
                _generated = false;
              }),
            ),
          ),
          const SizedBox(height: 16),
          const FinanceSectionTitle('Billing Period'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 200,
                child: AdminFilterDropdown<String>(
                  label: 'Cycle',
                  value: _cycle,
                  items: const [
                    DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                    DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
                  ],
                  onChanged: (v) => setState(() {
                    _cycle = v ?? 'MONTHLY';
                    _result = null;
                    _generated = false;
                  }),
                ),
              ),
              if (_cycle == 'MONTHLY') ...[
                SizedBox(
                  width: 160,
                  child: AdminFilterDropdown<int>(
                    label: 'Year',
                    value: _year,
                    items:
                        {
                              for (
                                var y = _defaultBillingYear;
                                y <=
                                    (_selectedYear?.endDate?.year ??
                                        _defaultBillingYear);
                                y++
                              )
                                y,
                            }
                            .map(
                              (y) =>
                                  DropdownMenuItem(value: y, child: Text('$y')),
                            )
                            .toList(),
                    onChanged: (v) => setState(() {
                      _year = v;
                      _month = null;
                      _result = null;
                      _generated = false;
                      _error = null;
                    }),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: AdminFilterDropdown<int>(
                    label: 'Month',
                    value: _month,
                    items: _validMonthsForYear
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(kMonthNames[m - 1]),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _month = v;
                      _result = null;
                      _generated = false;
                      _error = null;
                    }),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AdminPrimaryButton(
            label: 'Preview',
            icon: Icons.visibility_outlined,
            onPressed:
                (_previewing ||
                    _generating ||
                    _yearId == null ||
                    (_cycle == 'MONTHLY' && _month == null))
                ? null
                : _preview,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewResult(FeeGenerationResult result) {
    final s = result.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_generated)
          FinanceCard(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: kAdminGreen,
                  size: 32,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Fees Generated Successfully',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: kAdminNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created: ${s.created ?? s.willGenerate}   Already Existing: ${s.skippedExisting ?? s.alreadyGenerated}',
                    ),
                    Text('Net Amount: ${formatMoney(s.netAmount)}'),
                  ],
                ),
                AdminSecondaryButton(
                  label: 'View Fee Ledger',
                  onPressed: () =>
                      widget.onNavigateToPage?.call('financeFeeLedger'),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FinanceSectionTitle('Classes'),
              FinanceSummaryGrid(
                tiles: [
                  AdminStatTile(
                    icon: Icons.class_outlined,
                    color: kAdminNavy,
                    value: '${s.eligibleClasses}',
                    label: 'Eligible Classes',
                  ),
                  AdminStatTile(
                    icon: Icons.check_circle_outline_rounded,
                    color: kAdminGreen,
                    value: '${s.configuredClasses}',
                    label: 'Configured Classes',
                  ),
                  AdminStatTile(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFF59E0B),
                    value: '${s.unconfiguredClasses}',
                    label: 'Unconfigured Classes',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const FinanceSectionTitle('Students & Fees'),
              FinanceSummaryGrid(
                tiles: [
                  AdminStatTile(
                    icon: Icons.people_outline_rounded,
                    color: kAdminNavy,
                    value: '${s.totalStudents}',
                    label: 'Total Students',
                  ),
                  AdminStatTile(
                    icon: Icons.receipt_long_outlined,
                    color: kAdminGreen,
                    value: '${s.willGenerate}',
                    label: 'Fees To Generate',
                  ),
                  AdminStatTile(
                    icon: Icons.history_rounded,
                    color: kAdminTextSecondary,
                    value: '${s.alreadyGenerated}',
                    label: 'Already Generated',
                  ),
                  AdminStatTile(
                    icon: Icons.percent_rounded,
                    color: kAdminNavy,
                    value: '${s.discountedStudents}',
                    label: 'Discounted Students',
                  ),
                  AdminStatTile(
                    icon: Icons.volunteer_activism_rounded,
                    color: kAdminNavy,
                    value: '${s.freeStudents}',
                    label: 'Free Students',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const FinanceSectionTitle('Amounts'),
              FinanceSummaryGrid(
                tiles: [
                  AdminStatTile(
                    icon: Icons.attach_money_rounded,
                    color: kAdminNavy,
                    value: formatMoney(s.grossAmount),
                    label: 'Gross Amount',
                  ),
                  AdminStatTile(
                    icon: Icons.money_off_rounded,
                    color: kAdminNavy,
                    value: formatMoney(s.discountAmount),
                    label: 'Discount Amount',
                  ),
                  AdminStatTile(
                    icon: Icons.account_balance_wallet_rounded,
                    color: kAdminGreen,
                    value: formatMoney(s.netAmount),
                    label: 'Net Amount',
                  ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 22),
        const FinanceSectionTitle('Per-class status'),
        FinanceTableCard(
          columns: const [
            AdminTableColumn('Class', flex: 2),
            AdminTableColumn('Status', flex: 2),
            AdminTableColumn('Enrolled', flex: 1),
            AdminTableColumn('Will Generate', flex: 1),
            AdminTableColumn('Net Amount', flex: 2),
          ],
          rows: result.classes.map((c) {
            return AdminTableRow(
              flexes: const [2, 2, 1, 1, 2],
              cells: [
                Text(
                  c.className,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kAdminNavy,
                  ),
                ),
                AdminStatusPill(
                  label: generationStatusLabel(c.status),
                  color: generationStatusColor(c.status),
                ),
                Text('${c.enrolledStudents}'),
                Text('${c.willGenerate}'),
                Text(formatMoney(c.netAmount)),
              ],
            );
          }).toList(),
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...result.warnings.map(
            (w) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF5C36B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${w.className}: Term fee generation is not currently available.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF92650B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (!_generated)
          AdminPrimaryButton(
            label: _generating ? 'Generating...' : 'Generate Fees',
            icon: Icons.play_arrow_rounded,
            onPressed: _generating ? null : _confirmAndGenerate,
          ),
      ],
    );
  }
}
