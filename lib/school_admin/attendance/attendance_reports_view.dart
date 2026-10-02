import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kobac/models/attendance_report.dart';
import 'package:kobac/school_admin/attendance/attendance_reports_controller.dart';
import 'package:kobac/school_admin/attendance/take_attendance_view.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';

const Color _kAbsent = Color(0xFFC0392B);
const Color _kLate = Color(0xFF8E6C00);

/// Attendance > Reports: Class Attendance and Student Attendance.
///
/// One widget for every platform; [isDesktop] only switches tables (desktop)
/// for compact cards (phones). Renders plain sections — the Attendance page
/// owns the single scroll area. All figures are the backend's.
class AttendanceReportsView extends StatefulWidget {
  final AttendanceReportsController controller;
  final bool isDesktop;

  const AttendanceReportsView({
    super.key,
    required this.controller,
    required this.isDesktop,
  });

  @override
  State<AttendanceReportsView> createState() => _AttendanceReportsViewState();
}

class _AttendanceReportsViewState extends State<AttendanceReportsView> {
  AttendanceReportsController get c => widget.controller;
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => c.searchStudents(value),
    );
  }

  Future<void> _pick(DateTime initial, ValueChanged<DateTime> onPicked,
      String help) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: c.firstDate,
      lastDate: c.lastDate,
      helpText: help,
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
    if (picked != null && mounted) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TypeSwitcher(value: c.type, onChanged: c.setType),
        const SizedBox(height: 14),
        _filters(),
        const SizedBox(height: 16),
        if (c.type == AttendanceReportType.classReport)
          _classResult()
        else
          _studentResult(),
      ],
    ),
  );

  // --- Filters --------------------------------------------------------------

  Widget _filters() {
    final isClass = c.type == AttendanceReportType.classReport;
    final yearField = AdminFilterDropdown<int>(
      key: ValueKey('report-year-${c.yearId}-${c.years.length}'),
      label: 'Academic Year',
      value: c.yearId,
      items: [
        for (final y in c.years)
          DropdownMenuItem<int>(
            value: y.id,
            child: Text(
              y.isActive ? '${y.name} (Active)' : y.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null && v != c.yearId) {
          _search.clear();
          c.selectYear(v);
        }
      },
    );
    final subjectField = isClass
        ? (c.classesLoading
              ? const AttendanceSkeletonBlock(height: 46)
              : AdminFilterDropdown<int>(
                  key: ValueKey('report-class-${c.classId}-${c.classes.length}'),
                  label: 'Class',
                  value: c.classId,
                  items: [
                    for (final cls in c.classes)
                      DropdownMenuItem<int>(
                        value: cls.id,
                        child: Text(cls.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: c.yearId == null ? null : c.selectClass,
                ))
        : _studentPicker();
    final start = AttendanceDateField(
      label: 'Start Date',
      tapKey: const ValueKey('report-start'),
      value: c.startDate,
      enabled: c.yearId != null,
      onTap: () => _pick(c.startDate, c.setStartDate, 'Start date'),
    );
    final end = AttendanceDateField(
      label: 'End Date',
      tapKey: const ValueKey('report-end'),
      value: c.endDate,
      enabled: c.yearId != null,
      onTap: () => _pick(c.endDate, c.setEndDate, 'End date'),
    );
    final loading = isClass ? c.classReportLoading : c.studentReportLoading;
    final canView = isClass ? c.canViewClassReport : c.canViewStudentReport;
    return AdminFilterBar(
      filters: [yearField, subjectField, start, end],
      actions: [
        _PresetChip(
          label: 'This Month',
          onTap: () => c.applyPreset(ReportDatePreset.thisMonth),
        ),
        _PresetChip(
          label: 'Academic Year',
          onTap: () => c.applyPreset(ReportDatePreset.academicYear),
        ),
        FilledButton.icon(
          key: const ValueKey('report-view'),
          onPressed: !canView || loading
              ? null
              : (isClass ? c.loadClassReport : c.loadStudentReport),
          style: FilledButton.styleFrom(
            backgroundColor: kAdminGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.insights_rounded, size: 18),
          label: Text(loading ? 'Loading…' : 'View Report'),
        ),
        if (c.dateError != null)
          Text(
            c.dateError!,
            key: const ValueKey('report-date-error'),
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        if (isClass && c.classesError != null)
          Text(
            c.classesError!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
      ],
    );
  }

  Widget _studentPicker() {
    final selected = c.selectedStudent;
    if (selected != null) {
      return InputDecorator(
        key: const ValueKey('report-student-selected'),
        decoration: InputDecoration(
          labelText: 'Student',
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAdminBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAdminBorder),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                [selected.name, ?selected.emisNumber].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: kAdminNavy),
              ),
            ),
            IconButton(
              tooltip: 'Change student',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                _search.clear();
                c.clearStudent();
              },
            ),
          ],
        ),
      );
    }
    final hasQuery = c.searchQuery.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('report-student-search'),
          controller: _search,
          enabled: c.yearId != null,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Student',
            hintText: 'Search by name or EMIS',
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: c.searchLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAdminBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAdminBorder),
            ),
          ),
        ),
        if (hasQuery && !c.searchLoading) ...[
          const SizedBox(height: 6),
          Container(
            key: const ValueKey('report-student-results'),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kAdminBorder),
            ),
            child: c.searchError != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      c.searchError!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  )
                : c.searchResults.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No students match this search.',
                      style: TextStyle(color: kAdminTextSecondary),
                    ),
                  )
                : Column(
                    children: [
                      for (final s in c.searchResults.take(8))
                        InkWell(
                          key: ValueKey('report-student-${s.id}'),
                          onTap: () {
                            _search.clear();
                            c.selectStudent(s);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 18,
                                  color: kAdminTextSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    [
                                      s.name,
                                      ?s.emisNumber,
                                      ?s.className,
                                    ].join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: kAdminNavy,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  // --- Class report ---------------------------------------------------------

  Widget _classResult() {
    if (c.classReportLoading && c.classReport == null) {
      return const _ReportSkeleton(key: ValueKey('class-report-loading'));
    }
    final error = c.classReportError;
    if (error != null) {
      return AttendanceInlineState(
        key: const ValueKey('class-report-error'),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade700,
        message: error.message,
        action: AdminSecondaryButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: c.loadClassReport,
        ),
      );
    }
    final r = c.classReport;
    if (r == null) {
      return const AttendanceInlineState(
        icon: Icons.assessment_outlined,
        message:
            'Choose an academic year, class and date range, then select View Report.',
      );
    }
    final counts = r.summary.counts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportHeader(
          title: 'CLASS ATTENDANCE REPORT',
          details: [
            ('Academic Year', r.academicYearName ?? '—'),
            ('Class', r.className ?? c.selectedClass?.name ?? '—'),
            ('Date Range', r.period.label),
          ],
          download: _DownloadButton(
            buttonKey: const ValueKey('class-report-pdf'),
            busy: c.classPdfBusy,
            onPressed: () => saveAttendancePdf(
              context,
              fetch: c.downloadClassPdf,
              fallbackFilename: c.classPdfFallbackFilename,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _StatChips(
          keyPrefix: 'class-summary',
          items: [
            ('Students', '${r.summary.totalStudents}', kAdminNavy),
            ('Recorded', '${counts.recordedSessions}', kAdminNavy),
            ('Present', '${counts.present}', kAdminGreen),
            ('Absent', '${counts.absent}', _kAbsent),
            ('Late', '${counts.late}', _kLate),
            ('Attendance', counts.percentageLabel, kAdminNavy),
          ],
        ),
        if (!r.hasAttendance) ...[
          const SizedBox(height: 12),
          const AttendanceBanner(
            key: ValueKey('class-report-no-data'),
            icon: Icons.info_outline_rounded,
            message: 'No attendance was recorded during this period.',
          ),
        ],
        const SizedBox(height: 16),
        AttendanceSection(
          title: 'Students (${r.students.length})',
          child: r.students.isEmpty
              ? const AttendanceInlineState(
                  icon: Icons.people_outline_rounded,
                  message: 'No enrolled students were found for this class.',
                )
              : widget.isDesktop
              ? _ClassTable(students: r.students)
              : _ClassCards(students: r.students),
        ),
      ],
    );
  }

  // --- Student report -------------------------------------------------------

  Widget _studentResult() {
    if (c.studentReportLoading && c.studentReport == null) {
      return const _ReportSkeleton(key: ValueKey('student-report-loading'));
    }
    final error = c.studentReportError;
    if (error != null) {
      return AttendanceInlineState(
        key: const ValueKey('student-report-error'),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade700,
        message: error.message,
        action: AdminSecondaryButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: c.loadStudentReport,
        ),
      );
    }
    final r = c.studentReport;
    if (r == null) {
      return const AttendanceInlineState(
        icon: Icons.person_search_outlined,
        message:
            'Search for a student, choose a date range, then select View Report.',
      );
    }
    final counts = r.counts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportHeader(
          title: 'STUDENT ATTENDANCE REPORT',
          details: [
            ('Student', r.studentName ?? c.selectedStudent?.name ?? '—'),
            ('EMIS', r.emisNumber ?? '—'),
            ('Class', r.className ?? '—'),
            ('Academic Year', r.academicYearName ?? '—'),
            ('Date Range', r.period.label),
          ],
          download: _DownloadButton(
            buttonKey: const ValueKey('student-report-pdf'),
            busy: c.studentPdfBusy,
            onPressed: () => saveAttendancePdf(
              context,
              fetch: c.downloadStudentPdf,
              fallbackFilename: c.studentPdfFallbackFilename,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _StatChips(
          keyPrefix: 'student-summary',
          items: [
            ('Recorded Sessions', '${counts.recordedSessions}', kAdminNavy),
            ('Present', '${counts.present}', kAdminGreen),
            ('Absent', '${counts.absent}', _kAbsent),
            ('Late', '${counts.late}', _kLate),
            ('Attendance', counts.percentageLabel, kAdminNavy),
          ],
        ),
        if (!r.hasAttendance) ...[
          const SizedBox(height: 12),
          const AttendanceBanner(
            key: ValueKey('student-report-no-data'),
            icon: Icons.info_outline_rounded,
            message:
                'No attendance was recorded for this student during this period.',
          ),
        ],
        const SizedBox(height: 16),
        AttendanceSection(
          title: 'Attendance History (${r.history.length})',
          child: r.history.isEmpty
              ? const AttendanceInlineState(
                  icon: Icons.history_rounded,
                  message: 'No lessons were recorded in this period.',
                )
              : widget.isDesktop
              ? _HistoryTable(history: r.history)
              : _HistoryCards(history: r.history),
        ),
      ],
    );
  }
}

// ===========================================================================
// Pieces
// ===========================================================================

class _TypeSwitcher extends StatelessWidget {
  final AttendanceReportType value;
  final ValueChanged<AttendanceReportType> onChanged;
  const _TypeSwitcher({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: SegmentedButton<AttendanceReportType>(
      key: const ValueKey('report-type'),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kAdminNavy,
        selectedForegroundColor: Colors.white,
        foregroundColor: kAdminNavy,
        side: const BorderSide(color: kAdminBorder),
        visualDensity: VisualDensity.compact,
      ),
      segments: const [
        ButtonSegment(
          value: AttendanceReportType.classReport,
          icon: Icon(Icons.groups_outlined, size: 16),
          label: Text('Class Attendance', key: ValueKey('report-type-class')),
        ),
        ButtonSegment(
          value: AttendanceReportType.student,
          icon: Icon(Icons.person_outline_rounded, size: 16),
          label: Text('Student Attendance', key: ValueKey('report-type-student')),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    ),
  );
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ActionChip(
    key: ValueKey('preset-$label'),
    label: Text(label),
    onPressed: onTap,
    side: const BorderSide(color: kAdminBorder),
    backgroundColor: Colors.white,
    labelStyle: const TextStyle(color: kAdminNavy, fontSize: 12),
  );
}

class _DownloadButton extends StatelessWidget {
  final Key buttonKey;
  final bool busy;
  final VoidCallback onPressed;
  const _DownloadButton({
    required this.buttonKey,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => AdminSecondaryButton(
    key: buttonKey,
    label: busy ? 'Preparing PDF…' : 'Download PDF',
    icon: busy ? Icons.hourglass_top_rounded : Icons.picture_as_pdf_outlined,
    onPressed: busy ? null : onPressed,
  );
}

class _ReportHeader extends StatelessWidget {
  final String title;
  final List<(String, String)> details;
  final Widget download;
  const _ReportHeader({
    required this.title,
    required this.details,
    required this.download,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kAdminBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: .4,
                fontWeight: FontWeight.w800,
                color: kAdminNavy,
              ),
            ),
            download,
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            for (final (label, value) in details)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kAdminTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kAdminNavy,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _StatChips extends StatelessWidget {
  final String keyPrefix;
  final List<(String, String, Color)> items;
  const _StatChips({required this.keyPrefix, required this.items});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (label, value, color) in items)
        Container(
          key: ValueKey('$keyPrefix-$label'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kAdminBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kAdminTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AttendanceSkeletonBlock(height: 96),
      SizedBox(height: 12),
      AttendanceSkeletonBlock(height: 40),
      SizedBox(height: 12),
      AttendanceSkeletonBlock(height: 52),
      SizedBox(height: 8),
      AttendanceSkeletonBlock(height: 52),
    ],
  );
}

TextStyle get _cell => const TextStyle(fontSize: 13, color: kAdminNavy);

Widget _num(String v, {Color? color}) => Text(
  v,
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: color ?? kAdminNavy,
  ),
);

class _ClassTable extends StatelessWidget {
  final List<ClassReportStudent> students;
  const _ClassTable({required this.students});

  static const _flexes = [1, 2, 4, 1, 1, 1, 1, 2];

  @override
  Widget build(BuildContext context) => AdminTableCard(
    columns: const [
      AdminTableColumn('No.', flex: 1),
      AdminTableColumn('EMIS', flex: 2),
      AdminTableColumn('Student Name', flex: 4),
      AdminTableColumn('Present', flex: 1, align: TextAlign.center),
      AdminTableColumn('Absent', flex: 1, align: TextAlign.center),
      AdminTableColumn('Late', flex: 1, align: TextAlign.center),
      AdminTableColumn('Recorded', flex: 1, align: TextAlign.center),
      AdminTableColumn('Attendance %', flex: 2, align: TextAlign.center),
    ],
    rows: [
      for (var i = 0; i < students.length; i++)
        AdminTableRow(
          key: ValueKey('class-report-row-${students[i].studentId}'),
          flexes: _flexes,
          cells: [
            Text('${i + 1}', style: _cell),
            Text(students[i].emisNumber ?? '—', style: _cell),
            Text(
              students[i].displayName,
              overflow: TextOverflow.ellipsis,
              style: _cell.copyWith(fontWeight: FontWeight.w700),
            ),
            _num('${students[i].counts.present}', color: kAdminGreen),
            _num('${students[i].counts.absent}', color: _kAbsent),
            _num('${students[i].counts.late}', color: _kLate),
            _num('${students[i].counts.recordedSessions}'),
            _num(students[i].counts.percentageLabel),
          ],
        ),
    ],
  );
}

class _ClassCards extends StatelessWidget {
  final List<ClassReportStudent> students;
  const _ClassCards({required this.students});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final s in students)
        Container(
          key: ValueKey('class-report-row-${s.studentId}'),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kAdminBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kAdminNavy,
                ),
              ),
              Text(
                s.emisNumber ?? 'No EMIS number',
                style: const TextStyle(fontSize: 12, color: kAdminTextSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _kv('Present', '${s.counts.present}', kAdminGreen),
                  _kv('Absent', '${s.counts.absent}', _kAbsent),
                  _kv('Late', '${s.counts.late}', _kLate),
                  _kv('Recorded', '${s.counts.recordedSessions}', kAdminNavy),
                  _kv('Attendance', s.counts.percentageLabel, kAdminNavy),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _kv(String label, String value, Color color) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      '$label ',
      style: const TextStyle(fontSize: 12, color: kAdminTextSecondary),
    ),
    Text(
      value,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
    ),
  ],
);

/// Status with icon + text (never colour alone).
class _StatusPill extends StatelessWidget {
  final String? status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final s = status ?? '—';
    return switch (s) {
      'PRESENT' => const AdminStatusPill(
        label: 'Present',
        color: kAdminGreen,
        icon: Icons.check_circle_rounded,
      ),
      'ABSENT' => const AdminStatusPill(
        label: 'Absent',
        color: _kAbsent,
        icon: Icons.cancel_rounded,
      ),
      'LATE' => const AdminStatusPill(
        label: 'Late',
        color: _kLate,
        icon: Icons.schedule_rounded,
      ),
      _ => AdminStatusPill(label: s, color: kAdminTextSecondary),
    };
  }
}

String _time(String? t) {
  if (t == null || t.isEmpty) return '—';
  final parts = t.split(':');
  final h = int.tryParse(parts.first);
  final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (h == null || m == null) return t;
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
}

class _HistoryTable extends StatelessWidget {
  final List<StudentHistoryEntry> history;
  const _HistoryTable({required this.history});

  static const _flexes = [2, 3, 2, 2, 3, 2];

  @override
  Widget build(BuildContext context) => AdminTableCard(
    columns: const [
      AdminTableColumn('Date', flex: 2),
      AdminTableColumn('Subject', flex: 3),
      AdminTableColumn('Period', flex: 2),
      AdminTableColumn('Time', flex: 2),
      AdminTableColumn('Teacher', flex: 3),
      AdminTableColumn('Status', flex: 2),
    ],
    rows: [
      for (var i = 0; i < history.length; i++)
        AdminTableRow(
          key: ValueKey('history-row-$i'),
          flexes: _flexes,
          cells: [
            Text(history[i].date ?? '—', style: _cell),
            Text(
              history[i].subjectName ?? '—',
              overflow: TextOverflow.ellipsis,
              style: _cell.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(history[i].period ?? '—', style: _cell),
            Text(_time(history[i].time), style: _cell),
            Text(
              history[i].teacherName ?? '—',
              overflow: TextOverflow.ellipsis,
              style: _cell,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(history[i].status),
            ),
          ],
        ),
    ],
  );
}

class _HistoryCards extends StatelessWidget {
  final List<StudentHistoryEntry> history;
  const _HistoryCards({required this.history});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < history.length; i++)
        Container(
          key: ValueKey('history-row-$i'),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAdminBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history[i].subjectName ?? '—',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kAdminNavy,
                      ),
                    ),
                    Text(
                      [
                        history[i].date ?? '—',
                        ?history[i].period,
                        _time(history[i].time),
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: kAdminTextSecondary,
                      ),
                    ),
                    if (history[i].teacherName != null)
                      Text(
                        history[i].teacherName!,
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
              const SizedBox(width: 8),
              _StatusPill(history[i].status),
            ],
          ),
        ),
    ],
  );
}
