import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/class_fee.dart';
import 'package:kobac/finance/services/class_fee_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

class ClassFeesPage extends StatefulWidget {
  final String basePath;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const ClassFeesPage({
    super.key,
    required this.basePath,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<ClassFeesPage> createState() => _ClassFeesPageState();
}

class _ClassFeesPageState extends State<ClassFeesPage> {
  late final ClassFeeService _service = ClassFeeService(
    basePath: widget.basePath,
  );
  int? _selectedYearId;
  List<ClassFee> _classFees = [];
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
    final result = await _service.list(academicYearId: yearId);
    if (!mounted || request != _loadRequest) return;
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<List<ClassFee>>) {
        _classFees = result.data;
      } else {
        final err = result as FinanceError;
        _classFees = [];
        _error = err.message;
        _errorCode = err.code;
      }
    });
  }

  void _onYearChanged(int? yearId) {
    if (yearId == null || yearId == _selectedYearId) return;
    setState(() => _selectedYearId = yearId);
    _load(yearId);
  }

  Future<void> _openEditDialog(ClassFee classFee) async {
    final yearId = _selectedYearId;
    if (yearId == null) return;
    final current = await _service.get(
      classId: classFee.classId,
      academicYearId: yearId,
    );
    if (!mounted) return;
    if (current is FinanceError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(current.message), backgroundColor: Colors.red),
      );
      return;
    }
    classFee = (current as FinanceSuccess<ClassFee>).data;
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _EditClassFeeDialog(
        classFee: classFee,
        basePath: widget.basePath,
        academicYearId: yearId,
      ),
    );
    if (saved != true) return;
    if (!mounted) return;
    _load(yearId);
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
        const FinancePageHeader(
          title: 'Class Fees',
          subtitle: 'Set and manage class fee amounts for the academic year.',
        ),
        const SizedBox(height: 14),
        FinanceYearSelector(
          selectedYearId: _selectedYearId,
          onChanged: _onYearChanged,
        ),
        const SizedBox(height: 16),
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kAdminNavy));
    }
    if (_errorCode == 'FINANCE_NOT_ENABLED')
      return const FinanceNotEnabledView();
    if (_error != null) {
      final yearId = _selectedYearId;
      return AdminErrorState(
        title: 'Could not load class fees',
        message: _error!,
        onRetry: () {
          if (yearId != null) _load(yearId);
        },
      );
    }
    if (_classFees.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.class_outlined,
        title: 'No classes available',
        message: 'No classes are available for this academic year yet.',
      );
    }
    return FinanceTableCard(
      columns: const [
        AdminTableColumn('Class', flex: 3),
        AdminTableColumn('Amount', flex: 2),
        AdminTableColumn('Billing Cycle', flex: 2),
        AdminTableColumn('Status', flex: 2),
        AdminTableColumn('Actions', flex: 2, align: TextAlign.right),
      ],
      rows: _classFees.map((cf) {
        return AdminTableRow(
          flexes: const [3, 2, 2, 2, 2],
          cells: [
            Text(
              cf.className,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kAdminNavy,
              ),
            ),
            Text(cf.configured ? formatMoney(cf.amount) : 'Not configured'),
            Text(cf.configured ? financeLabel(cf.billingCycle ?? '') : '—'),
            cf.configured
                ? AdminStatusPill.active(cf.isActive ?? false)
                : const AdminStatusPill(
                    label: 'Not configured',
                    color: kAdminTextSecondary,
                    icon: Icons.remove_circle_outline_rounded,
                  ),
            Align(
              alignment: Alignment.centerRight,
              child: AdminSecondaryButton(
                label: cf.configured ? 'Edit' : 'Configure',
                onPressed: () => _openEditDialog(cf),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _EditClassFeeDialog extends StatefulWidget {
  final ClassFee classFee;
  final String basePath;
  final int academicYearId;
  const _EditClassFeeDialog({
    required this.classFee,
    required this.basePath,
    required this.academicYearId,
  });

  @override
  State<_EditClassFeeDialog> createState() => _EditClassFeeDialogState();
}

class _EditClassFeeDialogState extends State<_EditClassFeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String _billingCycle;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.classFee.amount?.toString() ?? '',
    );
    _billingCycle = widget.classFee.billingCycle ?? 'MONTHLY';
    _isActive = widget.classFee.isActive ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final service = ClassFeeService(basePath: widget.basePath);
    final result = await service.upsert(
      classId: widget.classFee.classId,
      academicYearId: widget.academicYearId,
      amount: num.parse(_amountController.text.trim()),
      billingCycle: _billingCycle,
      isActive: _isActive,
    );
    if (!mounted) return;
    if (result is FinanceSuccess) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = (result as FinanceError).message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AdminFeatureDialog(
        title: widget.classFee.configured
            ? 'Edit Class Fee'
            : 'Configure Class Fee',
        onClose: _saving ? () {} : null,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kAdminNavy.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.class_outlined,
                      size: 18,
                      color: kAdminNavy,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.classFee.className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kAdminNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Input3D(
                controller: _amountController,
                label: 'Amount',
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final n = num.tryParse(v?.trim() ?? '');
                  if (n == null || !n.isFinite || n < 0)
                    return 'Enter a valid amount (0 or more)';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Select3D<String>(
                value: _billingCycle,
                label: 'Billing Cycle',
                items: kBillingCycles
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(financeLabel(c)),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _billingCycle = v ?? 'MONTHLY'),
              ),
              if (_billingCycle == 'TERM') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF5C36B)),
                  ),
                  child: const Text(
                    'Term fee generation is not currently available.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF92650B)),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text(
                  'Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kAdminNavy,
                  ),
                ),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _isActive = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                FinanceInlineError(_error!),
              ],
              const SizedBox(height: 14),
              FinanceDialogActions(
                primaryLabel: 'Save',
                busy: _saving,
                onPrimary: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
