import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/school_admin/attendance/take_attendance_controller.dart';
import 'package:kobac/school_admin/attendance/attendance_reports_view.dart';
import 'package:kobac/school_admin/attendance/take_attendance_view.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_leave_guard.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

/// Statuses the single-record edit accepts (PATCH keeps historical LATE).
const List<String> kAttendanceStatusOptions = ['PRESENT', 'ABSENT', 'LATE'];

const String kAttendanceSubtitle = 'Take, review and manage student attendance.';

String _dateToYmd(DateTime d) => attendanceYmd(d);

enum AdminAttendanceView { take, records, reports }

class AdminAttendanceScreen extends StatefulWidget {
  /// Records view: date filter defaults to today.
  final bool defaultToToday;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  /// Tab to open; null = the tab last used in this Attendance session.
  final AdminAttendanceView? initialView;

  /// Explicit controller (tests). Otherwise the School Admin session's shared
  /// controller ([AttendanceSessionScope]) is used, so mobile and desktop
  /// render the same state; only outside that scope does the screen create
  /// (and dispose) its own.
  final TakeAttendanceController? controller;

  /// Test hook: force the desktop presentation without a web build.
  @visibleForTesting
  final bool? desktopOverride;

  const AdminAttendanceScreen({
    Key? key,
    this.defaultToToday = true,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
    this.initialView,
    this.controller,
    this.desktopOverride,
  }) : super(key: key);

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  late final TakeAttendanceController _take;
  late final bool _ownsController;
  late AdminAttendanceView _view;
  AcademicYearsProvider? _years;
  bool _yearsReady = false;

  // --- Attendance Records (existing list / edit / delete) ---
  int? _filterClassId;
  DateTime _filterDate = DateTime.now();
  late Future<AttendanceResult<List<AttendanceModel>>> _attendanceFuture;
  List<ClassModel> _classes = [];
  bool _refLoaded = false;

  @override
  void initState() {
    super.initState();
    final shared = widget.controller ?? AttendanceSessionScope.maybeOf(context);
    _ownsController = shared == null;
    _take = shared ?? TakeAttendanceController();
    if (widget.initialView != null) {
      _take.lastView = widget.initialView!.index;
    }
    _view = AdminAttendanceView.values[_take.lastView];
    _loadRefData();
    _loadAttendance();
    AdminLeaveGuard.register(_confirmLeave);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initYears());
  }

  @override
  void dispose() {
    AdminLeaveGuard.unregister(_confirmLeave);
    _years?.removeListener(_syncYears);
    if (_ownsController) _take.dispose();
    super.dispose();
  }

  Future<void> _initYears() async {
    if (!mounted) return;
    final years = context.read<AcademicYearsProvider>();
    _years = years..addListener(_syncYears);
    _syncYears();
    await years.ensureLoaded();
    _yearsReady = true;
    _syncYears();
  }

  void _syncYears() {
    final years = _years;
    if (!mounted || years == null) return;
    if (years.years.isNotEmpty) {
      _take.setYears(years.years, years.activeYear);
      _take.reports.setYears(years.years, years.activeYear);
    }
    setState(() {});
  }

  Future<bool> _confirmLeave() async {
    if (!_take.hasUnsavedChanges || !mounted) return true;
    final discard = await confirmDiscardAttendance(context);
    // The session controller outlives this page, so Discard must really
    // drop the marks rather than keep them for the next visit.
    if (discard) _take.clearAll();
    return discard;
  }

  Future<void> _loadRefData() async {
    final classRes = await ClassesService().listClasses();
    if (!mounted) return;
    setState(() {
      if (classRes is ClassSuccess<List<ClassModel>>) _classes = classRes.data;
      _refLoaded = true;
    });
  }

  void _loadAttendance() {
    setState(() {
      _attendanceFuture = AttendanceService().listAttendance(
        classId: _filterClassId,
        date: _dateToYmd(_filterDate),
      );
    });
  }

  String _className(int? id) {
    if (id == null) return '—';
    for (final c in _classes) { if (c.id == id) return c.name; }
    return '—';
  }

  /// Derive status options from records + fallback.
  List<String> _statusOptions(List<AttendanceModel> records) {
    final fromData = <String>{};
    for (final r in records) {
      if (r.status != null && r.status!.isNotEmpty) fromData.add(r.status!);
    }
    final combined = [...kAttendanceStatusOptions];
    for (final s in fromData) {
      if (!combined.contains(s)) combined.add(s);
    }
    return combined;
  }

  Future<void> _openUpdateStatus(AttendanceModel record, List<String> statusOptions) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _UpdateAttendanceStatusDialog(
        record: record,
        currentStatus: record.status ?? 'PRESENT',
        statusOptions: statusOptions,
        onSave: (status) => _updateStatusFromDialog(ctx, record.id, status),
      ),
    );
    if (updated == true && mounted) {
      _loadAttendance();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<bool> _updateStatusFromDialog(BuildContext ctx, int id, String status) async {
    final result = await AttendanceService().updateAttendanceStatus(id, {'status': status});
    if (result is AttendanceSuccess) return true;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text((result as AttendanceError).message), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  Future<void> _deleteAttendance(AttendanceModel record) async {
    final studentName = record.studentName ?? 'this student';
    final dateStr = record.date ?? _dateToYmd(_filterDate);
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete attendance record?',
      message: 'Delete this attendance record for $studentName on $dateStr?',
    );
    if (confirmed != true) return;
    final result = await AttendanceService().deleteAttendance(record.id);
    if (!mounted) return;
    if (result is AttendanceSuccess) {
      _loadAttendance();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance record deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as AttendanceError).message), backgroundColor: Colors.red),
      );
    }
  }

  void _clearFilters() {
    _filterClassId = null;
    _filterDate = DateTime.now();
    _loadAttendance();
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: kPrimaryBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _filterDate = picked;
    _loadAttendance();
  }

  String _displayEmis(String? emis) {
    if (emis == null || emis.trim().isEmpty) return '-';
    return emis;
  }

  // --- Layout ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Presentation only: both branches render the same controller, view and
    // records features below.
    final isDesktop = widget.desktopOverride ??
        isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly);
    final content = _buildContent(isDesktop);

    final Widget page;
    if (isDesktop) {
      // Shell sidebar + top bar stay fixed; the whole page content scrolls.
      page = Container(
        color: const Color(0xFFF8F9FC),
        child: _scrollable(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: content,
        ),
      );
    } else {
      page = Scaffold(
        backgroundColor: kBgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BackButton(onPressed: () => Navigator.of(context).maybePop()),
                  ),
                ),
              Expanded(
                child: _scrollable(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Only the PopScope rebuilds when marks change, never the whole page.
    return ValueListenableBuilder<int>(
      valueListenable: _take.marksVersion,
      child: page,
      builder: (context, _, child) => PopScope(
        canPop: !_take.hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await confirmDiscardAttendance(context) && context.mounted) {
            _take.clearAll();
            Navigator.of(context).pop();
          }
        },
        child: child!,
      ),
    );
  }

  Widget _scrollable({required EdgeInsets padding, required Widget child}) {
    final scroll = SingleChildScrollView(
      key: const ValueKey('attendance-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: child,
    );
    if (_view != AdminAttendanceView.records) return scroll;
    return RefreshIndicator(
      onRefresh: () async => _loadAttendance(),
      color: kPrimaryGreen,
      child: scroll,
    );
  }

  Widget _buildContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Same header on every platform; it scrolls with the page.
        Text(
          'Attendance',
          key: const ValueKey('attendance-title'),
          style: TextStyle(
            fontSize: isDesktop ? 26 : 24,
            fontWeight: FontWeight.w800,
            color: kAdminNavy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          kAttendanceSubtitle,
          style: TextStyle(fontSize: 14, color: kAdminTextSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _ViewToggle(
          value: _view,
          compact: !isDesktop,
          onChanged: (v) => setState(() {
            _view = v;
            _take.lastView = v.index;
          }),
        ),
        const SizedBox(height: 16),
        switch (_view) {
          AdminAttendanceView.take => _yearsGate(
            () => TakeAttendanceView(controller: _take, isDesktop: isDesktop),
          ),
          AdminAttendanceView.records => _buildRecordsView(isDesktop),
          AdminAttendanceView.reports => _yearsGate(
            () => AttendanceReportsView(
              controller: _take.reports,
              isDesktop: isDesktop,
            ),
          ),
        },
      ],
    );
  }

  /// Take Attendance and Reports both need the academic years first.
  Widget _yearsGate(Widget Function() child) {
    final years = _years;
    if (years == null || years.years.isEmpty) {
      if (years == null || !_yearsReady || years.loading) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
        );
      }
      if (years.error != null) {
        return AdminErrorState(
          title: 'Could not load academic years',
          message: years.error!,
          onRetry: years.refresh,
        );
      }
      return const AdminEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No academic years',
        message: 'Create an academic year before taking attendance.',
      );
    }
    return child();
  }

  // --- Attendance Records ---------------------------------------------------

  Widget _recordsFilters() {
    return AdminFilterBar(
      filters: [
        AdminFilterDropdown<int?>(
          key: ValueKey('records-class-$_filterClassId-${_classes.length}'),
          label: 'Class',
          value: _filterClassId,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All classes')),
            ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) {
            _filterClassId = v;
            _loadAttendance();
          },
        ),
        InkWell(
          key: const ValueKey('records-date'),
          onTap: _pickFilterDate,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kAdminBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kAdminBorder),
              ),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: kAdminNavy),
            ),
            child: Text(_dateToYmd(_filterDate), style: const TextStyle(fontSize: 14, color: kAdminNavy)),
          ),
        ),
      ],
      actions: [
        AdminSecondaryButton(label: 'Clear', icon: Icons.filter_alt_off_outlined, onPressed: _clearFilters),
      ],
    );
  }

  Widget _buildRecordsView(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_refLoaded) ...[_recordsFilters(), const SizedBox(height: 16)],
        FutureBuilder<AttendanceResult<List<AttendanceModel>>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
              );
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: userFriendlyMessage(snapshot.error!, null, 'AdminAttendanceScreen'),
                onRetry: _loadAttendance,
              );
            }
            final result = snapshot.data;
            if (result == null) return const Center(child: Text('No data'));
            if (result is AttendanceError) {
              return _ErrorState(message: result.message, onRetry: _loadAttendance);
            }
            final list = (result as AttendanceSuccess<List<AttendanceModel>>).data;
            final statusOptions = _statusOptions(list);
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.event_note_rounded, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No attendance records for this date${_filterClassId != null ? ' / class' : ''}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }
            if (!isDesktop) {
              return Column(
                children: [
                  for (final record in list)
                    _AttendanceCard(
                      record: record,
                      studentName: record.studentName ?? '—',
                      emis: _displayEmis(record.emisNumber),
                      className: record.className ?? _className(record.classId),
                      statusOptions: statusOptions,
                      onUpdateStatus: () => _openUpdateStatus(record, statusOptions),
                      onDelete: () => _deleteAttendance(record),
                    ),
                ],
              );
            }
            final presentCount = list.where((r) => (r.status ?? '').toUpperCase() == 'PRESENT').length;
            final absentCount = list.where((r) => (r.status ?? '').toUpperCase() == 'ABSENT').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AttendanceSummaryCards(
                  presentCount: presentCount,
                  absentCount: absentCount,
                  totalCount: list.length,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8ECF2)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: kAdminHeaderBg,
                          border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
                        ),
                        child: Row(
                          children: [
                            for (final (label, flex) in const [
                              ('Student', 3),
                              ('EMIS', 2),
                              ('Class', 2),
                              ('Subject', 2),
                              ('Status', 2),
                              ('Date', 2),
                            ])
                              Expanded(
                                flex: flex,
                                child: Text(
                                  label,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                ),
                              ),
                            const SizedBox(width: 80),
                          ],
                        ),
                      ),
                      ...list.map((record) => _AttendanceRow(
                            record: record,
                            studentName: record.studentName ?? '—',
                            emis: _displayEmis(record.emisNumber),
                            className: record.className ?? _className(record.classId),
                            onUpdateStatus: () => _openUpdateStatus(record, statusOptions),
                            onDelete: () => _deleteAttendance(record),
                          )),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final AdminAttendanceView value;
  final ValueChanged<AdminAttendanceView> onChanged;

  /// Phones: three equal segments with short labels (fits 360px).
  final bool compact;
  const _ViewToggle({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  static const _tabs = [
    (AdminAttendanceView.take, 'Take Attendance', 'Take', Icons.fact_check_outlined),
    (AdminAttendanceView.records, 'Attendance Records', 'Records', Icons.history_rounded),
    (AdminAttendanceView.reports, 'Reports', 'Reports', Icons.assessment_outlined),
  ];

  Widget _tab(AdminAttendanceView v, String label, IconData icon) {
    final selected = value == v;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('attendance-tab-${v.name}'),
        onTap: selected ? null : () => onChanged(v),
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
              Icon(icon, size: compact ? 16 : 17, color: selected ? Colors.white : kAdminNavy),
              SizedBox(width: compact ? 4 : 6),
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
    key: const ValueKey('attendance-modes'),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kAdminBorder),
    ),
    child: compact
        ? Row(
            children: [
              for (final (v, _, short, icon) in _tabs)
                Expanded(child: _tab(v, short, icon)),
            ],
          )
        : Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final (v, full, _, icon) in _tabs) _tab(v, full, icon),
            ],
          ),
  );
}

class _AttendanceSummaryCards extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int totalCount;

  const _AttendanceSummaryCards({
    required this.presentCount,
    required this.absentCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Total Records', value: '$totalCount', color: kPrimaryBlue)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(label: 'Present', value: '$presentCount', color: kPrimaryGreen)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(label: 'Absent', value: '$absentCount', color: const Color(0xFFE67E22))),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceModel record;
  final String studentName;
  final String emis;
  final String className;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;

  const _AttendanceRow({
    required this.record,
    required this.studentName,
    required this.emis,
    required this.className,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  String _displayValue(String value) {
    if (value.trim().isEmpty || value == '—') return '-';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final initial = studentName.trim().isNotEmpty ? studentName.trim().substring(0, 1).toUpperCase() : '?';
    final displayDate = _displayValue(record.date ?? '');
    TextStyle cell() => TextStyle(fontSize: 14, color: Colors.grey.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kPrimaryBlue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(emis, style: cell(), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(_displayValue(className), style: cell(), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Text(
              _displayValue(record.subjectName ?? ''),
              style: cell(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 2, child: _AttendanceStatusBadge(status: record.status)),
          Expanded(flex: 2, child: Text(displayDate, style: cell(), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: kPrimaryGreen),
                  onPressed: onUpdateStatus,
                  tooltip: 'Edit Status',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatusBadge extends StatelessWidget {
  final String? status;

  const _AttendanceStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? '').toUpperCase();
    Color background;
    Color foreground;
    if (normalized == 'PRESENT') {
      background = kPrimaryGreen.withValues(alpha: 0.12);
      foreground = kPrimaryGreen;
    } else if (normalized == 'ABSENT') {
      background = const Color(0xFFFFE8E0);
      foreground = const Color(0xFFE67E22);
    } else {
      background = Colors.grey.shade100;
      foreground = Colors.grey.shade700;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status ?? '-',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceModel record;
  final String studentName;
  final String emis;
  final String className;
  final List<String> statusOptions;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;

  const _AttendanceCard({
    required this.record,
    required this.studentName,
    required this.emis,
    required this.className,
    required this.statusOptions,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = [
      if (record.subjectName != null && record.subjectName!.isNotEmpty) record.subjectName!,
      if (record.time != null && record.time!.isNotEmpty) record.time!,
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAdminBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_outline_rounded, color: kPrimaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  studentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
                Text('EMIS: $emis · ${record.status ?? "—"}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                if (lesson.isNotEmpty)
                  Text(lesson, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (record.date != null)
                  Text('$className · ${record.date}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 22, color: kPrimaryGreen), onPressed: onUpdateStatus, tooltip: 'Edit Status'),
          IconButton(icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]), onPressed: onDelete, tooltip: 'Delete'),
        ],
      ),
    );
  }
}

class _UpdateAttendanceStatusDialog extends StatefulWidget {
  final AttendanceModel record;
  final String currentStatus;
  final List<String> statusOptions;
  final Future<bool> Function(String status) onSave;

  const _UpdateAttendanceStatusDialog({
    required this.record,
    required this.currentStatus,
    required this.statusOptions,
    required this.onSave,
  });

  @override
  State<_UpdateAttendanceStatusDialog> createState() => _UpdateAttendanceStatusDialogState();
}

class _UpdateAttendanceStatusDialogState extends State<_UpdateAttendanceStatusDialog> {
  late String _status;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _status = widget.statusOptions.contains(widget.currentStatus) ? widget.currentStatus : (widget.statusOptions.isNotEmpty ? widget.statusOptions.first : 'PRESENT');
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onSave(_status);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Update Attendance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            const SizedBox(height: 20),
            Select3D<String>(
              value: _status,
              label: 'Status',
              items: widget.statusOptions.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v ?? 'PRESENT'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: PrimaryButton3D(label: 'Save', onPressed: _submit, loading: _submitting, height: 48)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAdminBorder),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 22),
        ),
      ),
    );
  }
}
