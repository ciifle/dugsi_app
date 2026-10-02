import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/exam_fees/state/exam_fees_controller.dart';
import 'package:kobac/exam_fees/widgets/exam_fees_tabs.dart';
import 'package:kobac/exam_fees/widgets/exam_fees_ui.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/auth_provider.dart';

const String kExamFeesSubtitle =
    'Configure, generate and collect exam fees.';

/// School Admin "Exam Fees" (Exam Fee Custom).
///
/// One page for Android, phone-width PWA and desktop PWA; [ExamFeesController]
/// holds all state and only the presentation adapts. The page itself is the
/// route guard: when examFeeCustomEnabled is off (or missing) nothing of the
/// module renders, however it was reached.
class ExamFeesPage extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  /// Explicit controller (tests). Otherwise the School Admin session's
  /// [ExamFeesSessionScope] controller, or a page-owned one.
  final ExamFeesController? controller;

  @visibleForTesting
  final bool? desktopOverride;

  const ExamFeesPage({
    super.key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
    this.controller,
    this.desktopOverride,
  });

  @override
  State<ExamFeesPage> createState() => _ExamFeesPageState();
}

class _ExamFeesPageState extends State<ExamFeesPage> {
  late final ExamFeesController _c;
  late final bool _owns;
  AcademicYearsProvider? _years;
  bool _yearsReady = false;

  @override
  void initState() {
    super.initState();
    final shared = widget.controller ?? ExamFeesSessionScope.maybeOf(context);
    _owns = shared == null;
    _c = shared ?? ExamFeesController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    // A server denial hides the module from navigation too.
    _c.onFeatureDisabled = auth.disableExamFeeAccess;
    // Nothing is requested while the module is off.
    if (!auth.examFeeCustomEnabled || _years != null) return;
    final years = context.read<AcademicYearsProvider>();
    _years = years..addListener(_syncYears);
    _syncYears();
    await years.ensureLoaded();
    _yearsReady = true;
    _syncYears();
    _c.ensureTabData();
  }

  void _syncYears() {
    final y = _years;
    if (!mounted || y == null) return;
    if (y.years.isNotEmpty) _c.setYears(y.years, y.activeYear);
    setState(() {});
  }

  @override
  void dispose() {
    _years?.removeListener(_syncYears);
    if (_c.onFeatureDisabled != null && !_owns) _c.onFeatureDisabled = null;
    if (_owns) _c.dispose();
    super.dispose();
  }

  void _back() {
    if (widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('dashboard');
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        widget.desktopOverride ?? isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly);
    final enabled = context.watch<AuthProvider>().examFeeCustomEnabled;
    if (enabled && _years == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    }

    final content = ListenableBuilder(
      listenable: _c,
      builder: (context, _) => !enabled || _c.featureDisabled
          ? Padding(
              padding: const EdgeInsets.only(top: 40),
              child: ExamFeesNotEnabledView(onBack: _back),
            )
          : _content(isDesktop),
    );

    if (isDesktop) {
      return Container(
        color: const Color(0xFFF8F9FC),
        child: SingleChildScrollView(
          key: const ValueKey('exam-fees-scroll'),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: content,
        ),
      );
    }
    return Scaffold(
      backgroundColor: kAdminBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Navigator.of(context).canPop())
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: 'Back',
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kAdminBorder),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: kAdminNavy, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('exam-fees-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(bool isDesktop) {
    final years = _years;
    final yearsPending = years == null || !_yearsReady || years.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Exam Fees',
          key: const ValueKey('exam-fees-title'),
          style: TextStyle(fontSize: isDesktop ? 26 : 24, fontWeight: FontWeight.w800, color: kAdminNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          kExamFeesSubtitle,
          style: TextStyle(fontSize: 14, color: kAdminTextSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        if (years != null && years.years.isEmpty && !yearsPending)
          years.error != null
              ? AdminErrorState(
                  title: 'Could not load academic years',
                  message: years.error!,
                  onRetry: years.refresh,
                )
              : const AdminEmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'No academic years',
                  message: 'Create an academic year before setting up exam fees.',
                )
        else if (yearsPending && (years?.years.isEmpty ?? true))
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
          )
        else ...[
          _selectors(),
          const SizedBox(height: 14),
          _TabSwitcher(value: _c.tab, compact: !isDesktop, onChanged: _c.setTab),
          const SizedBox(height: 16),
          switch (_c.tab) {
            ExamFeesTab.register => ExamFeeRegisterTab(controller: _c, isDesktop: isDesktop),
            ExamFeesTab.setup => ExamFeeSetupTab(controller: _c, isDesktop: isDesktop),
            ExamFeesTab.payments => ExamFeePaymentsTab(controller: _c, isDesktop: isDesktop),
          },
        ],
      ],
    );
  }

  Widget _selectors() {
    final c = _c;
    final examLoading = c.examsLoading;
    return AdminFilterBar(
      filters: [
        AdminFilterDropdown<int>(
          key: ValueKey('ef-year-${c.yearId}-${c.years.length}'),
          label: 'Academic Year',
          value: c.yearId,
          items: [
            for (final y in c.years)
              DropdownMenuItem<int>(
                value: y.id,
                child: Text(y.isActive ? '${y.name} (Active)' : y.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: c.mutating
              ? null
              : (v) {
                  if (v != null && v != c.yearId) c.selectYear(v);
                },
        ),
        examLoading
            ? const LinearProgressIndicator(minHeight: 2)
            : AdminFilterDropdown<int>(
                key: ValueKey('ef-exam-${c.examId}-${c.exams.length}-${c.yearId}'),
                label: c.exams.isEmpty && c.examsError == null ? 'Exam (none this year)' : 'Exam',
                value: c.examId,
                items: [
                  for (final e in c.exams)
                    DropdownMenuItem<int>(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: c.mutating || c.yearId == null ? null : c.selectExam,
              ),
        c.classesLoading
            ? const LinearProgressIndicator(minHeight: 2)
            : AdminFilterDropdown<int>(
                key: ValueKey('ef-class-${c.classId}-${c.classes.length}-${c.yearId}'),
                label: c.tab == ExamFeesTab.payments ? 'Class (optional)' : 'Class',
                value: c.classId,
                items: [
                  for (final cls in c.classes)
                    DropdownMenuItem<int>(value: cls.id, child: Text(cls.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: c.mutating || c.yearId == null ? null : c.selectClass,
              ),
      ],
      actions: [
        if (c.examsError != null)
          _inlineError(c.examsError!, c.loadExams),
        if (c.classesError != null)
          _inlineError(c.classesError!, c.loadClasses),
      ],
    );
  }

  Widget _inlineError(String message, VoidCallback retry) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 8,
    children: [
      Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
      TextButton(onPressed: retry, child: const Text('Retry')),
    ],
  );
}

class _TabSwitcher extends StatelessWidget {
  final ExamFeesTab value;
  final bool compact;
  final ValueChanged<ExamFeesTab> onChanged;
  const _TabSwitcher({required this.value, required this.compact, required this.onChanged});

  static const _tabs = [
    (ExamFeesTab.register, 'Register', 'Register', Icons.fact_check_outlined),
    (ExamFeesTab.setup, 'Setup & Generate', 'Setup', Icons.tune_rounded),
    (ExamFeesTab.payments, 'Payments', 'Payments', Icons.receipt_long_outlined),
  ];

  Widget _tab(ExamFeesTab t, String label, IconData icon) {
    final selected = value == t;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('exam-fees-tab-${t.name}'),
        onTap: selected ? null : () => onChanged(t),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 14),
          decoration: BoxDecoration(
            color: selected ? kAdminNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : kAdminNavy),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : kAdminNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('exam-fees-tabs'),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kAdminBorder),
    ),
    child: compact
        ? Row(children: [for (final (t, _, s, i) in _tabs) Expanded(child: _tab(t, s, i))])
        : Wrap(spacing: 4, runSpacing: 4, children: [for (final (t, f, _, i) in _tabs) _tab(t, f, i)]),
  );
}
