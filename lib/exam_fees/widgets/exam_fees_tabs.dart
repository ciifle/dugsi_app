import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kobac/exam_fees/models/exam_fee_models.dart';
import 'package:kobac/exam_fees/services/exam_fee_service.dart';
import 'package:kobac/exam_fees/state/exam_fees_controller.dart';
import 'package:kobac/exam_fees/widgets/exam_fee_dialogs.dart';
import 'package:kobac/exam_fees/widgets/exam_fees_ui.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

const _cell = TextStyle(fontSize: 13, color: kAdminNavy);
const _head = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: kAdminTextSecondary,
);

Widget _money(double v, {bool bold = false, Color? color}) => Text(
  money(v),
  textAlign: TextAlign.right,
  maxLines: 1,
  style: TextStyle(
    fontSize: 13,
    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
    color: color ?? kAdminNavy,
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
);

/// Simple flexed table (header + rows) inside a white card.
class _Table extends StatelessWidget {
  final List<(String, int, TextAlign)> columns;
  final List<Widget> rows;
  const _Table({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) => ExamFeeCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: kAdminHeaderBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: kAdminBorder)),
          ),
          child: Row(
            children: [
              for (final (label, flex, align) in columns)
                Expanded(
                  flex: flex,
                  child: Text(label, textAlign: align, style: _head),
                ),
            ],
          ),
        ),
        ...rows,
      ],
    ),
  );
}

Widget _row({
  Key? key,
  required List<(Widget, int)> cells,
  VoidCallback? onTap,
  bool muted = false,
}) => Material(
  key: key,
  color: muted ? kAdminHeaderBg : Colors.white,
  child: InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kAdminBorder)),
      ),
      child: Row(
        children: [
          for (final (w, flex) in cells)
            Expanded(
              flex: flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              ),
            ),
        ],
      ),
    ),
  ),
);

Future<void> _afterDialog(
  BuildContext context,
  Future<bool?> dialog,
  String message,
) async {
  final ok = await dialog;
  if (ok == true && context.mounted) examFeeSnack(context, message);
}

// ===========================================================================
// REGISTER
// ===========================================================================

class ExamFeeRegisterTab extends StatelessWidget {
  final ExamFeesController controller;
  final bool isDesktop;
  const ExamFeeRegisterTab({
    super.key,
    required this.controller,
    required this.isDesktop,
  });

  ExamFeesController get c => controller;

  @override
  Widget build(BuildContext context) {
    if (c.examId == null) {
      return const ExamFeeInlineState(
        icon: Icons.quiz_outlined,
        title: 'Select an exam',
        message: 'Choose an academic year and exam to see its exam fees.',
      );
    }
    if (c.classId == null) {
      return const ExamFeeInlineState(
        icon: Icons.class_outlined,
        title: 'Select a class',
        message: 'Choose a class to view its exam fee register.',
      );
    }
    if (c.registerLoading && c.register == null) return const ExamFeeSkeleton();
    if (c.registerError != null) {
      return ExamFeeErrorState(failure: c.registerError!, onRetry: c.loadRegister);
    }
    final r = c.register;
    if (r == null) return const ExamFeeSkeleton();
    final s = r.summary;
    final hasRows = r.students.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Backend totals only; nothing is summed from the rows.
        ExamFeeStatGrid(
          keyPrefix: 'register-summary',
          items: [
            ('Students', '${s.generatedStudents}', Icons.people_alt_outlined, kAdminNavy),
            ('Total Charged', money(s.totalCharged), Icons.request_quote_outlined, kAdminNavy),
            ('Collected', money(s.totalCollected), Icons.payments_outlined, kAdminGreen),
            ('Outstanding', money(s.outstanding), Icons.hourglass_bottom_rounded, kExamFeeRed),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _count('Paid', s.paidCount, kAdminGreen),
            _count('Partial', s.partialCount, kExamFeeAmber),
            _count('Unpaid', s.unpaidCount, kExamFeeRed),
            _count('Waived', s.waivedCount, kExamFeeInfo),
            _count('Not Generated', s.notGeneratedStudents, kAdminTextSecondary),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasRows)
          ExamFeeInlineState(
            key: const ValueKey('register-empty'),
            icon: r.setting == null ? Icons.settings_outlined : Icons.playlist_add_rounded,
            title: r.setting == null ? 'No fee configured' : 'No fees generated',
            message: r.setting == null
                ? 'Set an exam fee for this class in Setup & Generate.'
                : 'The fee is configured (${money(r.setting!.amount)}). Generate it for the class in Setup & Generate.',
            action: AdminSecondaryButton(
              label: 'Go to Setup & Generate',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => c.setTab(ExamFeesTab.setup),
            ),
          )
        else ...[
          _bulkBar(context),
          const SizedBox(height: 10),
          isDesktop ? _desktopTable(context, r) : _mobileCards(context, r),
        ],
        if (r.notGenerated.isNotEmpty || r.generatedInOtherClass.isNotEmpty) ...[
          const SizedBox(height: 18),
          _notGenerated(r),
        ],
      ],
    );
  }

  Widget _count(String label, int value, Color color) => Container(
    key: ValueKey('register-count-$label'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: kAdminBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kAdminTextSecondary)),
        const SizedBox(width: 6),
        Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    ),
  );

  Widget _bulkBar(BuildContext context) {
    final payable = c.selectableRows;
    if (payable.isEmpty) return const SizedBox.shrink();
    final n = c.selection.length;
    return ExamFeeCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                key: const ValueKey('select-all'),
                value: c.allSelectableSelected,
                onChanged: c.mutating ? null : (_) => c.toggleSelectAll(),
              ),
              Flexible(
                child: Text(
                  n == 0 ? 'Select payable students' : '$n selected',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kAdminNavy, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (n > 0)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                AdminSecondaryButton(label: 'Clear', onPressed: c.clearSelection),
                AdminPrimaryButton(
                  key: const ValueKey('collect-selected'),
                  label: 'Collect Selected ($n)',
                  icon: Icons.payments_outlined,
                  onPressed: c.mutating
                      ? null
                      : () => showBulkCollect(context, c),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, StudentExamFee f, {bool compact = false}) {
    final items = <PopupMenuEntry<String>>[
      if (f.canCustomize)
        const PopupMenuItem(value: 'customize', child: Text('Customize fee')),
      if (f.canWaive) const PopupMenuItem(value: 'waive', child: Text('Waive')),
      if (f.canUnwaive) const PopupMenuItem(value: 'unwaive', child: Text('Unwaive')),
      const PopupMenuItem(value: 'details', child: Text('View details')),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (f.canCollect)
          compact
              ? Flexible(
                  child: AdminPrimaryButton(
                    key: ValueKey('collect-${f.id}'),
                    label: 'Collect',
                    onPressed: c.mutating ? null : () => showCollectFee(context, c, f),
                  ),
                )
              : Tooltip(
                  message: 'Collect',
                  child: IconButton(
                    key: ValueKey('collect-${f.id}'),
                    icon: const Icon(Icons.payments_outlined, color: kAdminGreen),
                    onPressed: c.mutating ? null : () => showCollectFee(context, c, f),
                  ),
                ),
        PopupMenuButton<String>(
          key: ValueKey('actions-${f.id}'),
          tooltip: 'More actions',
          enabled: !c.mutating,
          icon: const Icon(Icons.more_vert_rounded, color: kAdminNavy),
          itemBuilder: (_) => items,
          onSelected: (v) {
            switch (v) {
              case 'customize':
                _afterDialog(context, showCustomizeFee(context, c, f), 'Exam fee updated.');
              case 'waive':
                _afterDialog(context, showWaiveFee(context, c, f), 'Exam fee waived.');
              case 'unwaive':
                _afterDialog(context, showUnwaiveFee(context, c, f), 'Exam fee restored.');
              case 'details':
                showStudentFeeDetail(context, c, f);
            }
          },
        ),
      ],
    );
  }

  Widget _check(StudentExamFee f) => SizedBox(
    width: 40,
    child: f.selectable
        ? Checkbox(
            key: ValueKey('select-${f.id}'),
            value: c.selection.contains(f.id),
            onChanged: c.mutating ? null : (_) => c.toggleSelection(f.id),
          )
        : const SizedBox.shrink(),
  );

  Widget _desktopTable(BuildContext context, ExamFeeRegister r) => ExamFeeWideTable(
    minWidth: 1060,
    child: _Table(
      columns: const [
        ('', 1, TextAlign.left),
        ('Student', 4, TextAlign.left),
        ('EMIS', 2, TextAlign.left),
        ('Original Fee', 2, TextAlign.right),
        ('Payable', 2, TextAlign.right),
        ('Paid', 2, TextAlign.right),
        ('Remaining', 2, TextAlign.right),
        ('Status', 2, TextAlign.center),
        ('Actions', 3, TextAlign.right),
      ],
      rows: [
        for (final f in r.students)
          _row(
            key: ValueKey('fee-row-${f.id}'),
            cells: [
              (Align(alignment: Alignment.centerLeft, child: _check(f)), 1),
              (
                Text(
                  f.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: _cell.copyWith(fontWeight: FontWeight.w700),
                ),
                4,
              ),
              (Text(f.emisNumber ?? '—', style: _cell, overflow: TextOverflow.ellipsis), 2),
              (_money(f.originalAmount, color: kAdminTextSecondary), 2),
              (_money(f.amount, bold: true), 2),
              (_money(f.paidAmount, color: kAdminGreen), 2),
              (_money(f.remainingAmount, color: f.remainingAmount > 0 ? kExamFeeRed : null), 2),
              (Center(child: ExamFeeStatusPill(f.status)), 2),
              (Align(alignment: Alignment.centerRight, child: _actions(context, f)), 3),
            ],
          ),
      ],
    ),
  );

  Widget _mobileCards(BuildContext context, ExamFeeRegister r) => Column(
    children: [
      for (final f in r.students)
        Padding(
          key: ValueKey('fee-row-${f.id}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: ExamFeeCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (f.selectable) _check(f),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kAdminNavy,
                            ),
                          ),
                          Text(
                            f.emisNumber ?? 'No EMIS number',
                            style: const TextStyle(fontSize: 12, color: kAdminTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    ExamFeeStatusPill(f.status),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _kv('Payable', money(f.amount)),
                    _kv('Paid', money(f.paidAmount)),
                    _kv('Remaining', money(f.remainingAmount)),
                    if (f.isCustomized) _kv('Original', money(f.originalAmount)),
                  ],
                ),
                const SizedBox(height: 6),
                _actions(context, f, compact: true),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _kv(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: kAdminTextSecondary)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kAdminNavy)),
    ],
  );

  /// Students without a fee for this exam: not financial records, never UNPAID.
  Widget _notGenerated(ExamFeeRegister r) => ExamFeeCard(
    key: const ValueKey('not-generated'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Not Generated (${r.notGenerated.length})',
          style: const TextStyle(fontWeight: FontWeight.w800, color: kAdminNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'These enrolled students have no exam fee yet. Generate fees in Setup & Generate.',
          style: TextStyle(fontSize: 12.5, color: kAdminTextSecondary),
        ),
        const SizedBox(height: 8),
        for (final s in r.notGenerated)
          Padding(
            key: ValueKey('not-generated-${s.studentId}'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    [s.displayName, ?s.emisNumber].join(' · '),
                    style: _cell,
                  ),
                ),
                const NotGeneratedPill(),
              ],
            ),
          ),
        if (r.generatedInOtherClass.isNotEmpty) ...[
          const Divider(height: 20),
          Text(
            'Generated in another class (${r.generatedInOtherClass.length})',
            style: const TextStyle(fontWeight: FontWeight.w700, color: kAdminNavy),
          ),
          for (final s in r.generatedInOtherClass)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${s.displayName} — ${s.className ?? 'another class'}',
                style: _cell,
              ),
            ),
        ],
      ],
    ),
  );
}

// ===========================================================================
// SETUP & GENERATE
// ===========================================================================

class ExamFeeSetupTab extends StatelessWidget {
  final ExamFeesController controller;
  final bool isDesktop;
  const ExamFeeSetupTab({super.key, required this.controller, required this.isDesktop});

  ExamFeesController get c => controller;

  Future<void> _delete(BuildContext context, ExamFeeClassSetting row) async {
    final ok = await showDeleteConfirmDialog(
      context,
      title: 'Delete exam fee?',
      message:
          'Remove the ${money(row.setting?.amount)} exam fee for ${row.className}? '
          'This is only possible before fees are generated.',
    );
    if (ok != true || !context.mounted) return;
    final r = await c.deleteSetting(row);
    if (!context.mounted) return;
    if (r is ExamFeeFailure) {
      examFeeSnack(context, r.message, error: true);
    } else {
      examFeeSnack(context, 'Exam fee setting deleted.');
    }
  }

  List<Widget> _buttons(BuildContext context, ExamFeeClassSetting row) => [
    AdminSecondaryButton(
      key: ValueKey('set-fee-${row.classId}'),
      label: row.configured ? 'Update' : 'Set Fee',
      icon: Icons.edit_outlined,
      onPressed: c.mutating
          ? null
          : () => _afterDialog(context, showSetFee(context, c, row), 'Exam fee saved.'),
    ),
    if (row.configured)
      AdminPrimaryButton(
        key: ValueKey('generate-${row.classId}'),
        label: 'Preview / Generate',
        icon: Icons.playlist_add_check_rounded,
        onPressed: c.generating.contains(row.classId)
            ? null
            : () => _afterDialog(
                context,
                showGeneration(context, c, row),
                'Exam fees generated.',
              ),
      ),
    if (row.configured && row.generatedCount == 0)
      IconButton(
        key: ValueKey('delete-setting-${row.classId}'),
        tooltip: 'Delete setting',
        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
        onPressed: c.mutating ? null : () => _delete(context, row),
      ),
  ];

  Widget _status(ExamFeeClassSetting row) => row.configured
      ? AdminStatusPill(
          label: row.generatedCount > 0 ? 'Generated (${row.generatedCount})' : 'Configured',
          color: kAdminGreen,
          icon: Icons.check_circle_rounded,
        )
      : const AdminStatusPill(
          label: 'Not configured',
          color: kAdminTextSecondary,
          icon: Icons.remove_circle_outline_rounded,
        );

  @override
  Widget build(BuildContext context) {
    if (c.examId == null) {
      return const ExamFeeInlineState(
        icon: Icons.quiz_outlined,
        title: 'Select an exam',
        message: 'Choose an academic year and exam to configure its fees.',
      );
    }
    if (c.settingsLoading && c.settings == null) return const ExamFeeSkeleton();
    if (c.settingsError != null) {
      return ExamFeeErrorState(failure: c.settingsError!, onRetry: c.loadSettings);
    }
    final s = c.settings;
    if (s == null) return const ExamFeeSkeleton();
    if (s.classes.isEmpty) {
      return const ExamFeeInlineState(
        icon: Icons.class_outlined,
        title: 'No classes available',
        message: 'Create classes before configuring exam fees.',
      );
    }
    if (isDesktop) {
      return ExamFeeWideTable(
        minWidth: 860,
        child: _Table(
          columns: const [
            ('Class', 3, TextAlign.left),
            ('Configured Fee', 2, TextAlign.right),
            ('Status', 3, TextAlign.center),
            ('Actions', 5, TextAlign.right),
          ],
          rows: [
            for (final row in s.classes)
              _row(
                key: ValueKey('setting-row-${row.classId}'),
                cells: [
                  (Text(row.className, style: _cell.copyWith(fontWeight: FontWeight.w700)), 3),
                  (
                    row.setting == null
                        ? const Text('—', textAlign: TextAlign.right, style: _cell)
                        : _money(row.setting!.amount, bold: true),
                    2,
                  ),
                  (Center(child: _status(row)), 3),
                  (
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      children: _buttons(context, row),
                    ),
                    5,
                  ),
                ],
              ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final row in s.classes)
          Padding(
            key: ValueKey('setting-row-${row.classId}'),
            padding: const EdgeInsets.only(bottom: 10),
            child: ExamFeeCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.className,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kAdminNavy,
                          ),
                        ),
                      ),
                      Text(
                        row.setting == null ? '—' : money(row.setting!.amount),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kAdminNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft, child: _status(row)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: _buttons(context, row)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// PAYMENTS
// ===========================================================================

class ExamFeePaymentsTab extends StatefulWidget {
  final ExamFeesController controller;
  final bool isDesktop;
  const ExamFeePaymentsTab({super.key, required this.controller, required this.isDesktop});

  @override
  State<ExamFeePaymentsTab> createState() => _ExamFeePaymentsTabState();
}

class _ExamFeePaymentsTabState extends State<ExamFeePaymentsTab> {
  ExamFeesController get c => widget.controller;
  late final _search = TextEditingController(text: c.search);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final initial = (start ? c.startDate : c.endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: kAdminNavy,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    start ? c.setPaymentFilters(start: picked) : c.setPaymentFilters(end: picked);
  }

  String _ymd(DateTime? d) => d == null
      ? 'Any'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _dateField(String label, DateTime? value, bool start) => InkWell(
    key: ValueKey(start ? 'payments-start' : 'payments-end'),
    onTap: () => _pickDate(start),
    borderRadius: BorderRadius.circular(10),
    child: InputDecorator(
      decoration: examFeeInput(label).copyWith(
        suffixIcon: value == null
            ? const Icon(Icons.calendar_today_outlined, size: 18)
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => start
                    ? c.setPaymentFilters(start: null)
                    : c.setPaymentFilters(end: null),
              ),
      ),
      child: Text(_ymd(value), style: _cell),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final filters = AdminFilterBar(
      filters: [
        DropdownButtonFormField<String?>(
          key: ValueKey('payments-method-${c.methodFilter}'),
          initialValue: c.methodFilter,
          isExpanded: true,
          decoration: examFeeInput('Payment Method'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All methods')),
            for (final m in kExamFeePaymentMethods)
              DropdownMenuItem<String?>(value: m, child: Text(m)),
          ],
          onChanged: (v) => c.setPaymentFilters(method: v),
        ),
        _dateField('From', c.startDate, true),
        _dateField('To', c.endDate, false),
        TextField(
          key: const ValueKey('payments-search'),
          controller: _search,
          decoration: examFeeInput(
            'Search',
            hint: 'Receipt, reference, student or EMIS',
          ).copyWith(prefixIcon: const Icon(Icons.search_rounded, size: 18)),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 400),
              () => c.setPaymentFilters(searchText: v),
            );
          },
        ),
      ],
      actions: c.dateRangeError == null
          ? null
          : [
              Text(
                c.dateRangeError!,
                key: const ValueKey('payments-date-error'),
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        const SizedBox(height: 14),
        _body(context),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (c.yearId == null) {
      return const ExamFeeInlineState(icon: Icons.calendar_month_outlined, title: 'Select an academic year');
    }
    if (c.paymentsLoading && c.paymentsPage == null) return const ExamFeeSkeleton();
    if (c.paymentsError != null) {
      return ExamFeeErrorState(failure: c.paymentsError!, onRetry: c.loadPayments);
    }
    final p = c.paymentsPage;
    if (p == null) return const ExamFeeSkeleton();
    if (p.payments.isEmpty) {
      return const ExamFeeInlineState(
        key: ValueKey('payments-empty'),
        icon: Icons.receipt_long_outlined,
        title: 'No payments found',
        message: 'No exam fee payments match these filters.',
      );
    }
    final list = widget.isDesktop
        ? ExamFeeWideTable(
            minWidth: 1000,
            child: _Table(
              columns: const [
                ('Receipt', 3, TextAlign.left),
                ('Student', 3, TextAlign.left),
                ('Exam', 2, TextAlign.left),
                ('Class', 2, TextAlign.left),
                ('Amount', 2, TextAlign.right),
                ('Method', 2, TextAlign.center),
                ('Date', 3, TextAlign.left),
                ('Recorded By', 2, TextAlign.left),
              ],
              rows: [
                for (final pay in p.payments)
                  _row(
                    key: ValueKey('payment-row-${pay.id}'),
                    onTap: () => showPaymentDetail(context, c, pay),
                    cells: [
                      (Text(pay.receiptNumber ?? '—', style: _cell.copyWith(fontWeight: FontWeight.w700)), 3),
                      (
                        Text(
                          [pay.studentName ?? '—', ?pay.emisNumber].join('\n'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _cell,
                        ),
                        3,
                      ),
                      (Text(pay.examName ?? '—', style: _cell, overflow: TextOverflow.ellipsis), 2),
                      (Text(pay.className ?? '—', style: _cell, overflow: TextOverflow.ellipsis), 2),
                      (_money(pay.amount, bold: true), 2),
                      (Text(pay.method ?? '—', textAlign: TextAlign.center, style: _cell), 2),
                      (Text(pay.paidAtLabel, style: _cell), 3),
                      (Text(pay.recordedByName ?? '—', style: _cell, overflow: TextOverflow.ellipsis), 2),
                    ],
                  ),
              ],
            ),
          )
        : Column(
            children: [
              for (final pay in p.payments)
                Padding(
                  key: ValueKey('payment-row-${pay.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showPaymentDetail(context, c, pay),
                    child: ExamFeeCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pay.studentName ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: kAdminNavy),
                                ),
                                Text(
                                  '${pay.receiptNumber ?? '—'} · ${pay.method ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: kAdminTextSecondary),
                                ),
                                Text(
                                  [pay.examName, pay.className, pay.paidAtLabel]
                                      .whereType<String>()
                                      .join(' · '),
                                  style: const TextStyle(fontSize: 12, color: kAdminTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(pay.amount),
                            style: const TextStyle(fontWeight: FontWeight.w800, color: kAdminNavy),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list,
        const SizedBox(height: 12),
        AdminPaginationBar(
          key: const ValueKey('payments-pagination'),
          page: p.page,
          pageSize: c.pageSize,
          total: p.total,
          singular: 'payment',
          plural: 'payments',
          onPageChanged: c.paymentsLoading ? null : (page) => c.loadPayments(toPage: page),
        ),
      ],
    );
  }
}
