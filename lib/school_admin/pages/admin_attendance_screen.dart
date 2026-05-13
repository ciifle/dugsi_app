import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

/// Status options: at least PRESENT; extend from data or use fallback.
const List<String> kAttendanceStatusOptions = ['PRESENT', 'ABSENT', 'LATE'];

String _dateToYmd(DateTime d) {
  final y = d.year;
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class AdminAttendanceScreen extends StatefulWidget {
  /// If true, date filter defaults to today and is applied on load.
  final bool defaultToToday;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminAttendanceScreen({
    Key? key,
    this.defaultToToday = true,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  int? _filterClassId;
  DateTime _filterDate;
  late Future<AttendanceResult<List<AttendanceModel>>> _attendanceFuture;
  List<ClassModel> _classes = [];
  List<StudentModel> _students = [];
  bool _refLoaded = false;

  _AdminAttendanceScreenState() : _filterDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRefData();
    _loadAttendance();
  }

  Future<void> _loadRefData() async {
    final classRes = await ClassesService().listClasses();
    final studentRes = await StudentsService().listStudents();
    if (!mounted) return;
    setState(() {
      if (classRes is ClassSuccess<List<ClassModel>>) _classes = classRes.data;
      if (studentRes is StudentSuccess<List<StudentModel>>) _students = studentRes.data;
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

  String _studentName(int? id) {
    if (id == null) return '—';
    for (final s in _students) { if (s.id == id) return s.studentName; }
    return '—';
  }
  String _studentEmis(int? id) {
    if (id == null) return '—';
    for (final s in _students) { if (s.id == id) return s.emisNumber; }
    return '—';
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
    final studentName = _studentName(record.studentId);
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
    setState(() {
      _filterClassId = null;
      _filterDate = DateTime.now();
      _loadAttendance();
    });
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _filterDate = picked;
      _loadAttendance();
    });
  }

  String _displayEmis(String emis) {
    if (emis.trim().isEmpty || emis == '—') return '-';
    return emis;
  }

  InputDecoration _desktopFilterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: kPrimaryBlue, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context)
        : _buildMobilePageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) return body;
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(child: body),
    );
  }

  Widget _buildMobilePageBody(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('Attendance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                    ),
                  ],
                ),
              ),
              if (_refLoaded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Select3D<int?>(
                          value: _filterClassId,
                          label: 'Class',
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('All classes')),
                            ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setState(() { _filterClassId = v; _loadAttendance(); }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DatePicker3D(
                          label: 'Date',
                          value: _dateToYmd(_filterDate),
                          initialDate: _filterDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          onDatePicked: (d) => setState(() { _filterDate = d; _loadAttendance(); }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadAttendance(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<AttendanceResult<List<AttendanceModel>>>(
                    future: _attendanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
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
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_note_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No attendance records for this date${_filterClassId != null ? ' / class' : ''}.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final record = list[index];
                          return _AttendanceCard(
                            record: record,
                            studentName: record.studentName ?? _studentName(record.studentId),
                            emis: _studentEmis(record.studentId),
                            className: record.className ?? _className(record.classId),
                            statusOptions: statusOptions,
                            onUpdateStatus: () => _openUpdateStatus(record, statusOptions),
                            onDelete: () => _deleteAttendance(record),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildDesktopPageBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_refLoaded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildDesktopFilterToolbar(),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadAttendance(),
              color: kPrimaryGreen,
              child: FutureBuilder<AttendanceResult<List<AttendanceModel>>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        _ErrorState(
                          message: userFriendlyMessage(snapshot.error!, null, 'AdminAttendanceScreen'),
                          onRetry: _loadAttendance,
                        ),
                      ],
                    );
                  }
                  final result = snapshot.data;
                  if (result == null) {
                    return const Center(child: Text('No data'));
                  }
                  if (result is AttendanceError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        _ErrorState(message: result.message, onRetry: _loadAttendance),
                      ],
                    );
                  }
                  final list = (result as AttendanceSuccess<List<AttendanceModel>>).data;
                  final statusOptions = _statusOptions(list);
                  if (list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Center(
                          child: Text(
                            'No attendance records for this date${_filterClassId != null ? ' / class' : ''}.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }

                  final presentCount = list.where((r) => (r.status ?? '').toUpperCase() == 'PRESENT').length;
                  final absentCount = list.where((r) => (r.status ?? '').toUpperCase() == 'ABSENT').length;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Student',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'EMIS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Class',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 80),
                                ],
                              ),
                            ),
                            ...list.map((record) {
                              return _AttendanceRow(
                                record: record,
                                studentName: record.studentName ?? _studentName(record.studentId),
                                emis: _displayEmis(_studentEmis(record.studentId)),
                                className: record.className ?? _className(record.classId),
                                onUpdateStatus: () => _openUpdateStatus(record, statusOptions),
                                onDelete: () => _deleteAttendance(record),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilterToolbar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final fieldWidth = isWide ? (constraints.maxWidth - 88) / 2 : constraints.maxWidth;

          Widget classField() {
            return SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<int?>(
                value: _filterClassId,
                decoration: _desktopFilterDecoration('Class'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All classes')),
                  ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (value) => setState(() {
                  _filterClassId = value;
                  _loadAttendance();
                }),
              ),
            );
          }

          Widget dateField() {
            return SizedBox(
              width: fieldWidth,
              child: InputDecorator(
                decoration: _desktopFilterDecoration('Date'),
                child: InkWell(
                  onTap: _pickFilterDate,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateToYmd(_filterDate),
                          style: const TextStyle(fontSize: 14, color: kPrimaryBlue),
                        ),
                      ),
                      Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
            );
          }

          if (isWide) {
            return Row(
              children: [
                classField(),
                const SizedBox(width: 16),
                dateField(),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            );
          }

          return Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              classField(),
              dateField(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
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
                    color: kPrimaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kPrimaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              emis,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _displayValue(className),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: _AttendanceStatusBadge(status: record.status),
          ),
          Expanded(
            flex: 2,
            child: Text(
              displayDate,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
      background = kPrimaryGreen.withOpacity(0.12);
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
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
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_outline_rounded, color: kPrimaryBlue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                  Text('EMIS: $emis · ${record.status ?? "—"}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  if (record.recordedAt != null || record.date != null)
                    Text('${record.date ?? ""} ${record.recordedAt ?? ""}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 22, color: kPrimaryGreen), onPressed: onUpdateStatus, tooltip: 'Edit Status'),
            IconButton(icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]), onPressed: onDelete, tooltip: 'Delete'),
          ],
        ),
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
      ),
    );
  }
}
