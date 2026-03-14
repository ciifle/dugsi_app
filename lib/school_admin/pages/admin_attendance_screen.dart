import 'package:flutter/material.dart';
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

  const AdminAttendanceScreen({Key? key, this.defaultToToday = true}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Container(
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
                        onPressed: () => setState(() {
                          _filterClassId = null;
                          _filterDate = DateTime.now();
                          _loadAttendance();
                        }),
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
