import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/utils/money_format.dart';
import '../models/class_fee.dart';
import '../models/finance_collection.dart';
import '../models/finance_payment.dart';
import '../services/class_fee_service.dart';
import '../services/finance_base.dart';
import '../services/finance_collection_service.dart';
import '../widgets/finance_ui.dart';
import 'individual_payment_page.dart';

class ClassCollectionPage extends StatefulWidget {
  final String basePath;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;
  final Map<String, dynamic>? initial;
  const ClassCollectionPage({
    super.key,
    required this.basePath,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
    this.initial,
  });
  @override
  State<ClassCollectionPage> createState() => _ClassCollectionPageState();
}

class _ClassCollectionPageState extends State<ClassCollectionPage> {
  late final _service = FinanceCollectionService(basePath: widget.basePath);
  late final _classesService = ClassFeeService(basePath: widget.basePath);
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _selected = <int>{};
  final _methods = <int, String>{};
  List<ClassFee> _classes = [];
  List<CollectionPeriod> _periods = [];
  ClassCollectionRegister? _register;
  int? _yearId, _classId;
  CollectionPeriod? _period;
  int _request = 0, _classRequest = 0;
  bool _loading = false,
      _loadingClasses = false,
      _saving = false,
      _individual = false;
  bool _unknownOutcome = false;
  String? _error, _classesError, _errorCode, _saveError;
  List<CollectionValidationIssue> _issues = [];

  @override
  void initState() {
    super.initState();
    _individual = widget.initial?['studentId'] != null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final years = context.read<AcademicYearsProvider>();
      await ensureFinanceYears(years);
      if (!mounted) return;
      await _changeYear(selectedFinanceYear(years));
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _changeYear(int? id) async {
    final request = ++_classRequest;
    _request++;
    final years = context.read<AcademicYearsProvider>().years.where(
      (y) => y.id == id,
    );
    final periods = years.isEmpty
        ? <CollectionPeriod>[]
        : CollectionPeriod.forYear(years.first);
    final now = DateTime.now();
    final current = periods.where(
      (p) => p.year == now.year && p.month == now.month,
    );
    setState(() {
      _yearId = id;
      _periods = periods;
      _period = current.isNotEmpty ? current.first : periods.firstOrNull;
      _classId = null;
      _classes = [];
      _register = null;
      _selected.clear();
      _methods.clear();
      _loading = false;
      _loadingClasses = id != null;
      _classesError = null;
      _error = null;
      _errorCode = null;
      _saveError = null;
      _issues = [];
      _unknownOutcome = false;
    });
    if (id == null) return;
    final result = await _classesService.list(academicYearId: id);
    if (!mounted || request != _classRequest) return;
    setState(() {
      _loadingClasses = false;
      if (result is FinanceSuccess<List<ClassFee>>) {
        _classes = result.data;
      } else {
        _classesError = (result as FinanceError).message;
        _errorCode = result.code;
      }
    });
  }

  Future<void> _load() async {
    final year = _yearId, cls = _classId, period = _period;
    final request = ++_request;
    setState(() {
      _register = null;
      _selected.clear();
      _methods.clear();
      _error = null;
      _errorCode = null;
      _saveError = null;
      _issues = [];
      _loading = year != null && cls != null && period != null;
    });
    if (year == null || cls == null || period == null) return;
    final result = await _service.register(
      academicYearId: year,
      classId: cls,
      period: period,
    );
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<ClassCollectionRegister>) {
        _register = result.data;
        _unknownOutcome = false;
      } else {
        _error = (result as FinanceError).message;
        _errorCode = result.code;
      }
    });
  }

  List<CollectionStudent> get _visible {
    final query = _search.text.trim().toLowerCase();
    return (_register?.students ?? [])
        .where(
          (s) =>
              s.studentName.toLowerCase().contains(query) ||
              (s.emisNumber ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  void _select(CollectionStudent student, bool selected) => setState(() {
    if (selected) {
      _selected.add(student.studentId);
    } else {
      _selected.remove(student.studentId);
    }
  });

  Future<void> _save() async {
    final register = _register;
    if (_saving || _unknownOutcome || register == null || _selected.isEmpty)
      return;
    final selected = register.students
        .where((s) => _selected.contains(s.studentId) && s.canCollect)
        .toList();
    setState(() {
      _saving = true;
      _saveError = null;
      _issues = [];
    });
    _searchFocus.unfocus();
    String? method;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AdminFeatureDialog(
          title: 'Confirm Collection',
          onClose: () => Navigator.pop(dialogContext, false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                register.className,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kAdminNavy,
                ),
              ),
              Text(register.period.label),
              const SizedBox(height: 12),
              Text('Students: ${selected.length}'),
              Text(
                'Total being recorded: ${formatMoney(selected.fold<num>(0, (sum, s) => sum + s.remainingAmount!))}',
              ),
              const SizedBox(height: 16),
              AdminFilterDropdown<String>(
                label: 'Payment Method',
                value: method,
                items: kPaymentMethods
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(financeLabel(m)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => update(() => method = value),
              ),
              if (_methods.keys.any(_selected.contains))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Student method overrides are retained.'),
                ),
              const SizedBox(height: 16),
              const Text(
                'You are recording payments already received by the school.',
              ),
              const SizedBox(height: 8),
              const Text(
                'The server uses each student’s current remaining balance when saving.',
                style: TextStyle(fontSize: 12, color: kAdminTextSecondary),
              ),
              const SizedBox(height: 20),
              FinanceDialogActions(
                primaryLabel: 'Confirm & Save',
                onCancel: () => Navigator.pop(dialogContext, false),
                onPrimary: method == null
                    ? null
                    : () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (confirmed != true || method == null) {
      setState(() => _saving = false);
      return;
    }
    final result = await _service.collect(
      BulkCollectionRequest(
        academicYearId: register.academicYearId,
        classId: register.classId,
        period: register.period,
        payments: selected
            .map(
              (s) => CollectionPaymentInput(
                studentId: s.studentId,
                method: _methods[s.studentId] ?? method!,
              ),
            )
            .toList(),
      ),
    );
    if (!mounted) return;
    if (result is FinanceSuccess<BulkCollectionResult>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.data.count} payments recorded successfully.'),
        ),
      );
      await _load();
      if (mounted) setState(() => _saving = false);
    } else {
      final error = result as FinanceError;
      setState(() {
        _saving = false;
        _saveError = error.message;
        _issues = error is CollectionError ? error.issues : [];
        _unknownOutcome = error is CollectionError && error.outcomeUnknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_individual)
      return IndividualPaymentPage(
        basePath: widget.basePath,
        embedBodyOnly: widget.embedBodyOnly,
        initial: widget.initial,
        onNavigateToPage: widget.onNavigateToPage,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: AdminSecondaryButton(
            label: 'Class Collection',
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              setState(() => _individual = false);
              if (_classId != null) _load();
            },
          ),
        ),
      );
    return PopScope(
      canPop: !_saving,
      child: FinancePageFrame(
        embedBodyOnly: widget.embedBodyOnly,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FinancePageHeader(
              title: 'Collect Fees',
              subtitle: 'Record monthly fee collections for students.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                AdminSecondaryButton(
                  label: 'Individual Payment',
                  icon: Icons.person_outline_rounded,
                  onPressed: _saving
                      ? null
                      : () => setState(() => _individual = true),
                ),
                if (widget.onNavigateToPage != null)
                  AdminSecondaryButton(
                    label: 'Payment History',
                    onPressed: _saving
                        ? null
                        : () =>
                              widget.onNavigateToPage!('financePaymentHistory'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: _saving,
              child: FinanceCard(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final width = box.maxWidth >= 750
                        ? (box.maxWidth - 24) / 3
                        : box.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: width,
                          child: FinanceYearSelector(
                            selectedYearId: _yearId,
                            onChanged: _changeYear,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: AdminFilterDropdown<String>(
                            key: ValueKey('month-$_yearId'),
                            label: 'Month',
                            value: _period?.key,
                            items: _periods
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.key,
                                    child: Text(p.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(
                                () => _period = _periods
                                    .where((p) => p.key == value)
                                    .firstOrNull,
                              );
                              _load();
                            },
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: AdminFilterDropdown<int>(
                            key: ValueKey('class-$_yearId'),
                            label: 'Class',
                            value: _classId,
                            items: _classes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.classId,
                                    child: Text(c.className),
                                  ),
                                )
                                .toList(),
                            onChanged: _loadingClasses
                                ? null
                                : (value) {
                                    setState(() => _classId = value);
                                    _load();
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_loadingClasses) const LinearProgressIndicator(),
            if (_classesError != null)
              AdminErrorState(
                title: 'Could not load classes',
                message: _classesError!,
                onRetry: () => _changeYear(_yearId),
              ),
            if (_yearId != null && _periods.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No valid billing months are available for this academic year.',
                ),
              ),
            const SizedBox(height: 16),
            FinanceSearchField(
              controller: _search,
              focusNode: _searchFocus,
              hint: 'Search student by name or EMIS',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (_errorCode == 'FINANCE_NOT_ENABLED')
              const FinanceNotEnabledView()
            else if (_loading)
              const FinanceCardsSkeleton()
            else if (_error != null)
              AdminErrorState(
                title: 'Could not load fee collection.',
                message: _error!,
                onRetry: _load,
              )
            else if (_register == null)
              const AdminEmptyState(
                icon: Icons.groups_outlined,
                title: 'Select a class and month to view collections.',
                message: 'Choose the billing period and class above.',
              )
            else
              ..._registerBody(),
          ],
        ),
      ),
    );
  }

  List<Widget> _registerBody() {
    final students = _register!.students;
    if (students.isEmpty)
      return [
        const AdminEmptyState(
          icon: Icons.groups_outlined,
          title: 'No enrolled students found for this class.',
          message: 'Choose another class or academic year.',
        ),
      ];
    final visible = _visible;
    final eligible = visible.where((s) => s.canCollect).toList();
    final allSelected =
        eligible.isNotEmpty &&
        eligible.every((s) => _selected.contains(s.studentId));
    return [
      if (students.any((s) => s.requiresFeeGeneration))
        FinanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fees have not been generated for some students for ${_register!.period.label}.',
              ),
              if (widget.onNavigateToPage != null)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => widget.onNavigateToPage!('financeGenerateFees'),
                  child: const Text('Go to Generate Fees'),
                ),
            ],
          ),
        ),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Checkbox(
            value: allSelected,
            onChanged: _saving || eligible.isEmpty
                ? null
                : (value) => setState(() {
                    for (final s in eligible) {
                      if (value == true) {
                        _selected.add(s.studentId);
                      } else {
                        _selected.remove(s.studentId);
                      }
                    }
                  }),
          ),
          const Text('Select all eligible shown'),
          Text('${_selected.length} selected'),
          TextButton(
            onPressed: _saving ? null : _load,
            child: const Text('Refresh balances'),
          ),
        ],
      ),
      if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('No students match your search.'),
        ),
      LayoutBuilder(
        builder: (context, box) => box.maxWidth >= 900
            ? _table(visible)
            : Column(children: visible.map(_card).toList()),
      ),
      if (_saveError != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: FinanceInlineError(_saveError!),
        ),
      for (final issue in _issues)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${students.where((s) => s.studentId == issue.studentId).firstOrNull?.studentName ?? 'Student ${issue.studentId ?? ''}'}: ${issue.message}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: AdminPrimaryButton(
          label: _saving
              ? 'Saving payments...'
              : 'Save ${_selected.length} Payments',
          icon: Icons.check_rounded,
          onPressed: _saving || _unknownOutcome || _selected.isEmpty
              ? null
              : _save,
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  String _money(num? amount) => amount == null ? '—' : formatMoney(amount);
  Widget _status(CollectionStudent s) => s.requiresFeeGeneration
      ? const Text(
          'Fee not generated',
          style: TextStyle(color: kAdminTextSecondary),
        )
      : FinanceStatusBadge(s.status);
  Widget _method(CollectionStudent s) => SizedBox(
    width: 145,
    child: AdminFilterDropdown<String>(
      label: 'Method',
      value: _methods[s.studentId],
      items: kPaymentMethods
          .map((m) => DropdownMenuItem(value: m, child: Text(financeLabel(m))))
          .toList(),
      onChanged: _saving
          ? null
          : (value) => setState(() {
              if (value != null) _methods[s.studentId] = value;
            }),
    ),
  );
  Widget _card(CollectionStudent s) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.studentName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: kAdminNavy,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [Text(s.emisNumber ?? '—'), _status(s)],
          ),
          const SizedBox(height: 14),
          for (final item in [
            ('Monthly Fee', s.amountDue),
            ('Already Paid', s.paidAmount),
            ('Remaining Balance', s.remainingAmount),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(child: Text(item.$1)),
                  Text(
                    _money(item.$2),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (s.canCollect) ...[
            Row(
              children: [
                Checkbox(
                  key: ValueKey('select-${s.studentId}'),
                  value: _selected.contains(s.studentId),
                  onChanged: _saving ? null : (v) => _select(s, v == true),
                ),
                const Expanded(child: Text('Mark as Paid')),
              ],
            ),
            if (_selected.contains(s.studentId)) _method(s),
          ],
        ],
      ),
    ),
  );
  Widget _table(List<CollectionStudent> students) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      showCheckboxColumn: false,
      columnSpacing: 20,
      headingRowColor: WidgetStatePropertyAll(
        kAdminNavy.withValues(alpha: .04),
      ),
      columns: [
        'Select',
        'Student',
        'EMIS',
        'Fee',
        'Paid',
        'Balance',
        'Status',
        'Amount / Method',
      ].map((s) => DataColumn(label: Text(s))).toList(),
      rows: students
          .map(
            (s) => DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    key: ValueKey('select-${s.studentId}'),
                    value: _selected.contains(s.studentId),
                    onChanged: !s.canCollect || _saving
                        ? null
                        : (v) => _select(s, v == true),
                  ),
                ),
                DataCell(Text(s.studentName)),
                DataCell(Text(s.emisNumber ?? '—')),
                DataCell(Text(_money(s.amountDue))),
                DataCell(Text(_money(s.paidAmount))),
                DataCell(Text(_money(s.remainingAmount))),
                DataCell(_status(s)),
                DataCell(
                  _selected.contains(s.studentId)
                      ? _method(s)
                      : Text(s.canCollect ? _money(s.remainingAmount) : '—'),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}
