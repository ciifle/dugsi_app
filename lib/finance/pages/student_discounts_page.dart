import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/utils/money_format.dart';

import 'package:kobac/finance/models/class_fee.dart';
import 'package:kobac/finance/models/finance_collection.dart';
import 'package:kobac/finance/services/finance_collection_service.dart';
import 'package:kobac/finance/models/student_discount.dart';
import 'package:kobac/finance/services/class_fee_service.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/student_discount_service.dart';
import 'package:kobac/finance/widgets/finance_student_picker.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

class StudentDiscountsPage extends StatefulWidget {
  final String basePath;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentDiscountsPage({
    super.key,
    required this.basePath,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<StudentDiscountsPage> createState() => _StudentDiscountsPageState();
}

class _StudentDiscountsPageState extends State<StudentDiscountsPage> {
  late final StudentDiscountService _service = StudentDiscountService(
    basePath: widget.basePath,
  );
  late final ClassFeeService _classFeeService = ClassFeeService(
    basePath: widget.basePath,
  );

  int? _selectedYearId;
  int? _selectedClassId;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  List<ClassFee> _classes = [];
  List<StudentDiscount> _discounts = [];
  bool _loading = true;
  int _loadRequest = 0;
  bool _deleting = false;
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
      await _loadClasses(yearId);
      _load(yearId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses(int yearId) async {
    final result = await _classFeeService.list(academicYearId: yearId);
    if (!mounted) return;
    if (result is FinanceSuccess<List<ClassFee>>) {
      setState(() => _classes = result.data);
    }
  }

  Future<void> _load(int yearId) async {
    if (!mounted) return;
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
    });
    final result = await _service.list(
      academicYearId: yearId,
      classId: _selectedClassId,
      search: _search.isEmpty ? null : _search,
    );
    if (!mounted || request != _loadRequest) return;
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<List<StudentDiscount>>) {
        _discounts = result.data;
      } else {
        final err = result as FinanceError;
        _discounts = [];
        _error = err.message;
        _errorCode = err.code;
      }
    });
  }

  void _onYearChanged(int? yearId) {
    if (yearId == null || yearId == _selectedYearId) return;
    setState(() {
      _selectedYearId = yearId;
      _selectedClassId = null;
    });
    _loadClasses(yearId);
    _load(yearId);
  }

  void _onClassChanged(int? classId) {
    setState(() => _selectedClassId = classId);
    final yearId = _selectedYearId;
    if (yearId != null) _load(yearId);
  }

  void _onSearchChanged(String value) {
    _search = value;
    final yearId = _selectedYearId;
    if (yearId != null) _load(yearId);
  }

  Future<void> _openEditDialog(StudentDiscount discount) async {
    final yearId = _selectedYearId;
    if (yearId == null) return;
    await _openDiscountForStudentId(discount.studentId, yearId);
  }

  Future<void> _openAddDialog() async {
    final yearId = _selectedYearId;
    if (yearId == null) return;
    final picked = await showFinanceStudentPicker(
      context,
      search: (q) => _searchStudents(q, yearId),
    );
    if (picked == null || !mounted) return;
    await _openDiscountForStudentId(picked.id, yearId);
  }

  Future<FinanceStudentSearchResult> _searchStudents(
    String query,
    int yearId,
  ) async {
    final result = await FinanceCollectionService(basePath: widget.basePath)
        .students(
          academicYearId: yearId,
          classId: _selectedClassId,
          search: query,
          limit: 20,
        );
    if (result is FinanceSuccess<FinanceStudentPage>) {
      return FinanceStudentSearchResult([
        for (final s in result.data.students)
          FinanceStudentChoice(
            id: s.studentId,
            name: s.studentName,
            emis: s.emisNumber,
            className: s.className,
          ),
      ]);
    }
    return FinanceStudentSearchResult([], (result as FinanceError).message);
  }

  Future<void> _openDiscountForStudentId(int studentId, int yearId) async {
    final result = await _service.get(
      studentId: studentId,
      academicYearId: yearId,
    );
    if (!mounted) return;
    if (result is FinanceError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }
    final discount = (result as FinanceSuccess<StudentDiscount>).data;
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _EditDiscountDialog(
        basePath: widget.basePath,
        academicYearId: yearId,
        studentId: discount.studentId,
        studentName: discount.studentName,
        className: discount.className,
        baseAmount: discount.baseAmount,
        initialPercentage: discount.discountPercentage,
        initialReason: discount.reason,
        initialActive: discount.isActive ?? true,
      ),
    );
    if (saved == true && mounted) _load(yearId);
  }

  Future<void> _delete(StudentDiscount discount) async {
    if (_deleting) return;
    final yearId = _selectedYearId;
    if (yearId == null) return;
    _deleting = true;
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Remove Discount?',
      message:
          'Remove the fee discount for ${discount.studentName}? This does not affect any fees already generated.',
      confirmLabel: 'Remove',
    );
    if (!mounted) return;
    if (confirmed != true) {
      _deleting = false;
      return;
    }
    final result = await _service.delete(
      studentId: discount.studentId,
      academicYearId: yearId,
    );
    _deleting = false;
    if (!mounted) return;
    if (result is FinanceError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }
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
        FinancePageHeader(
          title: 'Student Discounts',
          subtitle: 'Configure fee discounts for individual students.',
          primaryAction: AdminPrimaryButton(
            label: 'Add Discount',
            icon: Icons.add_rounded,
            onPressed: _selectedYearId == null ? null : _openAddDialog,
          ),
        ),
        const SizedBox(height: 14),
        FinanceFilterBar(
          filters: [
            FinanceYearSelector(
              selectedYearId: _selectedYearId,
              onChanged: _onYearChanged,
            ),
            AdminFilterDropdown<int>(
              label: 'Class',
              value: _selectedClassId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All classes')),
                ..._classes.map(
                  (c) => DropdownMenuItem(
                    value: c.classId,
                    child: Text(c.className),
                  ),
                ),
              ],
              onChanged: _onClassChanged,
            ),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search student or EMIS',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: _onSearchChanged,
            ),
          ],
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
        title: 'Could not load discounts',
        message: _error!,
        onRetry: () {
          if (yearId != null) _load(yearId);
        },
      );
    }
    if (_discounts.isEmpty) {
      return AdminEmptyState(
        icon: Icons.percent_rounded,
        title: 'No discounts configured',
        message: 'No students with a discount configured for this filter.',
        action: _selectedYearId == null
            ? null
            : AdminPrimaryButton(
                label: 'Add Discount',
                icon: Icons.add_rounded,
                onPressed: _openAddDialog,
              ),
      );
    }
    return FinanceTableCard(
      columns: const [
        AdminTableColumn('Student', flex: 3),
        AdminTableColumn('Class', flex: 2),
        AdminTableColumn('Class Fee', flex: 2),
        AdminTableColumn('Discount', flex: 2),
        AdminTableColumn('Discount Amount', flex: 2),
        AdminTableColumn('Final Fee', flex: 2),
        AdminTableColumn('Status', flex: 2),
        AdminTableColumn('Actions', flex: 1, align: TextAlign.right),
      ],
      rows: _discounts.map((d) {
        return AdminTableRow(
          flexes: const [3, 2, 2, 2, 2, 2, 2, 1],
          cells: [
            Text(
              d.studentName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kAdminNavy,
              ),
            ),
            Text(d.className),
            Text(formatMoney(d.baseAmount)),
            d.isFullyFree
                ? const AdminStatusPill(label: '100%', color: kAdminNavy)
                : Text('${formatMoney(d.discountPercentage)}%'),
            Text(formatMoney(d.discountAmount)),
            Text(formatMoney(d.effectiveAmount)),
            AdminStatusPill.active(d.isActive ?? false),
            Align(
              alignment: Alignment.centerRight,
              child: FinanceActionMenu(
                actions: [
                  FinanceMenuAction(
                    'Edit Discount',
                    Icons.edit_outlined,
                    () => _openEditDialog(d),
                  ),
                  FinanceMenuAction(
                    'Remove Discount',
                    Icons.delete_outline_rounded,
                    () => _delete(d),
                    destructive: true,
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _EditDiscountDialog extends StatefulWidget {
  final String basePath;
  final int academicYearId;
  final int studentId;
  final String studentName;
  final String className;
  final num? baseAmount;
  final num? initialPercentage;
  final String? initialReason;
  final bool initialActive;

  const _EditDiscountDialog({
    required this.basePath,
    required this.academicYearId,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.baseAmount,
    required this.initialPercentage,
    required this.initialReason,
    required this.initialActive,
  });

  @override
  State<_EditDiscountDialog> createState() => _EditDiscountDialogState();
}

class _EditDiscountDialogState extends State<_EditDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _percentController;
  late final TextEditingController _reasonController;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _percentController = TextEditingController(
      text: widget.initialPercentage?.toString() ?? '0',
    );
    _reasonController = TextEditingController(text: widget.initialReason ?? '');
    _isActive = widget.initialActive;
  }

  @override
  void dispose() {
    _percentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final service = StudentDiscountService(basePath: widget.basePath);
    final result = await service.upsert(
      studentId: widget.studentId,
      academicYearId: widget.academicYearId,
      discountPercentage: num.parse(_percentController.text.trim()),
      reason: _reasonController.text.trim(),
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
    final percent = num.tryParse(_percentController.text) ?? 0;
    return PopScope(
      canPop: !_saving,
      child: AdminFeatureDialog(
        title: 'Student Discount',
        onClose: _saving ? () {} : null,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kAdminNavy.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kAdminNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.className,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: kAdminTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Original Fee: ${formatMoney(widget.baseAmount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Input3D(
                controller: _percentController,
                label: 'Discount Percentage (0-100)',
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final n = num.tryParse(v?.trim() ?? '');
                  if (n == null || !n.isFinite || n < 0 || n > 100)
                    return 'Enter a value between 0 and 100';
                  return null;
                },
              ),
              if (percent >= 100) ...[
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AdminStatusPill(
                    label: 'FREE / 100% Discount',
                    color: kAdminNavy,
                    icon: Icons.volunteer_activism_rounded,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Input3D(
                controller: _reasonController,
                label: 'Reason (optional)',
                enabled: !_saving,
                inputFormatters: [LengthLimitingTextInputFormatter(255)],
              ),
              const SizedBox(height: 4),
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
                primaryLabel: 'Save Discount',
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
