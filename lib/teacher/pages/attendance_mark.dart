import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/teacher_attendance_sync.dart';
import 'package:kobac/services/teacher_service.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

// ---------- COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE6F0FF); // Light tint of blue
const Color kSoftGreen = Color(0xFFEDF7EB); // Light tint of green
const Color kDarkGreen = Color(0xFF3A7A30); // Darker shade of green
const Color kDarkBlue = Color(0xFF01255C); // Darker shade of blue
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSuccessColor = Color(0xFF5AB04B); // Green for present
const Color kCardColor = Colors.white;

// ================== MAIN SCREEN =====================
class TeacherAttendanceScreen extends StatefulWidget {
  final TeacherAttendanceSync? controller;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  /// When false, renders bare content with no Scaffold/AppBar/back arrow â€”
  /// used when this screen is hosted as a root page inside the Teacher
  /// mobile shell (which owns the single persistent header + bottom nav).
  /// The search field stays inline (always visible) instead of an AppBar
  /// toggle, matching the pattern used by the shell's other root pages.
  final bool showAppBar;

  const TeacherAttendanceScreen({
    Key? key,
    this.controller,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  TeacherAttendanceSync? _offline;
  Map<String, dynamic>? _appliedDashboard;
  String? _setupError;

  int? _lessonId;
  bool _saving = false;
  List<TeacherAssignmentModel> _assignments = [];
  int? _selectedClassId;
  String _selectedClassName = 'Select class';
  DateTime _attendanceDate = DateTime.now();
  List<TeacherStudentModel> _students = [];
  List<String> _statusList = []; // PRESENT | ABSENT, same order as _students
  bool _studentsLoading = true;
  String? _studentsError;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<TeacherStudentModel> get currentClassStudents => _students;

  List<TeacherStudentModel> get filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      final name = (s.name ?? '').toLowerCase();
      final emis = (s.emisNumber ?? '').toLowerCase();
      return name.contains(q) || emis.contains(q);
    }).toList();
  }

  List<String> get filteredStatusList {
    return filteredStudents.map((s) {
      final i = _students.indexOf(s);
      return i >= 0 && i < _statusList.length ? _statusList[i] : 'PRESENT';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _connect();
  }

  /// Attaches to the signed-in teacher's worker and shows its cache at once;
  /// network refresh happens in the background and never blocks the page.
  Future<void> _connect() async {
    try {
      final pending = widget.controller != null
          ? Future.value(widget.controller!)
          : context.read<AuthProvider>().attendanceSync;
      if (pending == null) {
        throw const AttendanceSyncException(
          'Sign in as a teacher to take attendance.',
        );
      }
      final sync = await pending;
      if (!mounted) return;
      _offline = sync;
      sync.addListener(_onSyncChanged);
      _applyDashboard();
      if (widget.controller == null) unawaited(sync.sync());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _studentsLoading = false;
        _setupError = e is AttendanceSyncException
            ? e.message
            : 'Attendance is not available on this device.';
      });
    }
  }

  void _onSyncChanged() {
    if (!mounted) return;
    if (!identical(_offline?.dashboard, _appliedDashboard)) {
      _applyDashboard();
    } else if (_selectedClassId != null && _students.isEmpty) {
      _loadStudents(_selectedClassId!); // roster may have just downloaded
    } else {
      setState(() {});
    }
  }

  void _applyDashboard() {
    final sync = _offline;
    final data = sync?.dashboard;
    _appliedDashboard = data;
    if (sync == null || data == null) {
      setState(() {
        _assignments = [];
        _selectedClassId = null;
        _students = [];
        _statusList = [];
        _studentsLoading = false;
      });
      return;
    }
    final assigned = sync.assignedClassIds;
    setState(() {
      _assignments = TeacherDashboardModel.fromJson(
        data,
      ).assignments.where((a) => assigned.contains(a.classId)).toList();
      if (!_assignments.any((a) => a.classId == _selectedClassId)) {
        _selectedClassId = null;
      }
      if (_selectedClassId == null && _assignments.isNotEmpty) {
        _selectedClassId = _assignments.first.classId;
        _selectedClassName = _assignments.first.classDisplayName;
      }
    });
    if (_selectedClassId != null) {
      _loadStudents(_selectedClassId!);
    } else {
      setState(() => _studentsLoading = false);
    }
    _syncLessonSelection();
  }

  /// Students come only from the cached, server-provided enrolled roster.
  void _loadStudents(int classId) {
    final sync = _offline;
    if (sync == null) return;
    final previous = <int, String>{
      for (var i = 0; i < _students.length; i++)
        _students[i].id: _statusList[i],
    };
    final roster = sync.rosterFor(classId);
    setState(() {
      _studentsLoading = false;
      if (roster == null) {
        _students = [];
        _statusList = [];
        _studentsError = sync.busy
            ? 'Downloading the student list…'
            : 'The student list for this class is not on this device yet. '
                  'Connect to the internet and tap Sync Now.';
        return;
      }
      _studentsError = null;
      _students = roster.map(TeacherStudentModel.fromJson).toList();
      _statusList = _students
          .map((student) => previous[student.id] ?? 'PRESENT')
          .toList();
    });
  }

  List<Map<String, dynamic>> get _lessonsForSelection {
    final sync = _offline;
    final classId = _selectedClassId;
    if (sync == null || classId == null) return const [];
    return sync.lessonsFor(classId, _attendanceDate);
  }

  /// Keeps the chosen lesson valid for the class/date; auto-picks a single match.
  void _syncLessonSelection() {
    final options = _lessonsForSelection;
    setState(() {
      if (!options.any((l) => l['id'] == _lessonId)) _lessonId = null;
      if (_lessonId == null && options.length == 1) {
        _lessonId = options.single['id'] as int?;
      }
    });
  }

  /// Why saving is not possible yet, or null when it is.
  String? get _saveBlocker {
    final sync = _offline;
    if (_setupError != null) return _setupError;
    if (sync == null) return 'Loading attendance…';
    if (!sync.hasSchedule) {
      return 'Your lesson schedule has not been downloaded to this device. '
          'Connect to the internet and tap Sync Now, then try again.';
    }
    if (_assignments.isEmpty) {
      return 'No classes are assigned to you. Contact your School Admin.';
    }
    if (_selectedClassId == null) return 'Select a class.';
    if (_lessonsForSelection.isEmpty) {
      final days =
          sync.lessons
              .where(
                (l) =>
                    TeacherAttendanceSync.lessonClassId(l) == _selectedClassId,
              )
              .map((l) => '${l['day']}')
              .toSet()
              .toList()
            ..sort();
      return days.isEmpty
          ? 'No scheduled lessons for this class in your timetable.'
          : 'No lesson for this class on ${_weekdayName(_attendanceDate)}. '
                'Scheduled days: ${days.join(', ')}.';
    }
    if (_lessonId == null) return 'Select the scheduled lesson.';
    if (_students.isEmpty) return _studentsError ?? 'No enrolled students.';
    final timing = _selectedTiming;
    if (timing?.timing == LessonTiming.early) return timing!.message;
    return null;
  }

  static String _weekdayName(DateTime date) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][date.weekday - 1];

  void _onClassChanged(int? classId) {
    if (classId == null) return;
    final a = _assignments.cast<TeacherAssignmentModel?>().firstWhere(
      (e) => e?.classId == classId,
      orElse: () => null,
    );
    final name = a?.classDisplayName ?? 'Unassigned';
    setState(() {
      _selectedClassId = classId;
      _lessonId = null;
      _selectedClassName = name;
      _searchQuery = '';
      _searchController.clear();
      _students = [];
      _statusList = [];
    });
    _loadStudents(classId);
    _syncLessonSelection();
  }

  /// Unique classes from assignments (by classId). Never show "class 0"; use Unassigned.
  List<({int id, String name})> get _uniqueClasses {
    final seen = <int>{};
    final out = <({int id, String name})>[];
    for (final a in _assignments) {
      if (seen.add(a.classId)) {
        out.add((id: a.classId, name: a.classDisplayName));
      }
    }
    return out;
  }

  void _setStatus(int studentIndex, String status) {
    if (studentIndex < 0 || studentIndex >= _statusList.length) return;
    setState(() {
      _statusList[studentIndex] = status;
    });
  }

  void _onDateTapped() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _attendanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _attendanceDate = picked);
      _syncLessonSelection();
    }
  }

  Future<void> _saveAttendance() async {
    final sync = _offline;
    final lessonId = _lessonId;
    if (_saving || sync == null || lessonId == null || _saveBlocker != null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await sync.save(
        lessonId: lessonId,
        date: _attendanceDate,
        records: List.generate(
          _students.length,
          (i) => {'student_id': _students[i].id, 'status': _statusList[i]},
        ),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Saved on this device. It is sent automatically when the server is reachable.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is AttendanceSyncException
                ? e.message
                : 'Attendance could not be saved on this device.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ({LessonTiming timing, String? message})? get _selectedTiming {
    final sync = _offline;
    final lesson = _lessonsForSelection
        .where((l) => l['id'] == _lessonId)
        .firstOrNull;
    if (sync == null || lesson == null) return null;
    return sync.lessonTiming(lesson, _attendanceDate);
  }

  Future<void> _syncNow() async {
    final sync = _offline;
    if (sync == null) return;
    await sync.sync(manual: true);
  }

  Future<void> _confirmResubmit(AttendanceSubmission entry) async {
    final sync = _offline;
    if (sync == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resubmit attendance?'),
        content: const Text(
          'A corrected copy with the same student marks and original capture '
          'time is saved and sent. The original stays listed as replaced. The '
          'server still refuses it if attendance for this lesson already exists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sync.resubmit(entry);
      if (widget.controller == null) unawaited(sync.sync(manual: true));
    } on AttendanceSyncException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDismiss(AttendanceSubmission entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from this device?'),
        content: Text(
          '${describeSubmission(entry)}\n\nRemoving it from this device does '
          'not change any records on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await _offline?.dismiss(entry);
  }

  static Color _stateColor(SubmissionState state) => switch (state) {
    SubmissionState.synced => kDarkGreen,
    SubmissionState.adminReview => kSoftOrange,
    SubmissionState.failed => kErrorColor,
    SubmissionState.syncing => kPrimaryBlue,
    _ => kTextSecondary,
  };

  static String _time(DateTime value) {
    final t = value.toLocal();
    return '${_formatDayMonth(t)} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDayMonth(DateTime t) =>
      '${t.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][t.month - 1]}';

  Widget _countChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );

  Widget _banner(IconData icon, Color color, String text, {Widget? action}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: kTextPrimary)),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _syncPanel() {
    final sync = _offline;
    final lessons = _lessonsForSelection;
    final blocker = _saveBlocker;
    final pending = sync?.pendingCount ?? 0;
    final attention = sync?.attentionCount ?? 0;
    final timing = _selectedTiming;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sync != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (pending > 0)
                      _countChip('$pending pending sync', kPrimaryBlue)
                    else if (attention == 0)
                      _countChip('All attendance sent', kDarkGreen),
                    if (attention > 0)
                      _countChip('$attention need attention', kErrorColor),
                  ],
                ),
              ),
            if (_setupError != null)
              _banner(Icons.error_outline, kErrorColor, _setupError!),
            if (sync != null && !sync.hasSchedule)
              _banner(
                Icons.cloud_download_outlined,
                kSoftOrange,
                'No lesson schedule is stored on this device, so attendance '
                'cannot be taken offline yet. Connect to the internet and tap '
                'Sync Now to download your classes, lessons and students.',
              ),
            if (sync?.health == SyncHealth.offline)
              _banner(
                Icons.cloud_off_rounded,
                kTextSecondary,
                'Offline. Attendance you save stays on this device and is sent '
                'automatically when the server is reachable.'
                '${sync!.cachedAt == null ? '' : ' Schedule downloaded ${_time(sync.cachedAt!)}.'}',
              )
            else if (sync?.health == SyncHealth.authRequired)
              _banner(
                Icons.lock_clock_outlined,
                kSoftOrange,
                'Your session expired. Sign in again to send '
                '$pending saved record${pending == 1 ? '' : 's'}; they stay on this device.',
              )
            else if (sync?.health == SyncHealth.accessDenied ||
                sync?.health == SyncHealth.serverError ||
                sync?.health == SyncHealth.endpointMissing)
              _banner(
                Icons.warning_amber_rounded,
                kSoftOrange,
                sync!.message ?? 'Sync is temporarily unavailable.',
              ),
            Text(
              sync?.settings == null
                  ? 'Grace period: not downloaded yet.'
                  : 'Grace period: ${sync!.settings!['grace_minutes']} minutes after lesson end (${sync.settings!['timezone']}). Later attendance is recorded as late.',
            ),
            const Text(
              'Attendance can be submitted during or after the lesson, with no '
              'approval needed. Offline records will synchronize when '
              'internet is available.',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (lessons.isNotEmpty)
              DropdownButton<int>(
                isExpanded: true,
                value: _lessonId,
                hint: const Text('Select scheduled lesson'),
                items: lessons
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e['id'] as int,
                        child: Text(
                          '${e['day']} ${e['startTime'] ?? e['start_time']} – ${e['endTime'] ?? e['end_time']} ${e['subjectName'] ?? e['subject']?['name'] ?? ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) => setState(() => _lessonId = id),
              ),
            if (blocker == null && timing?.message != null)
              _banner(
                timing!.timing == LessonTiming.early
                    ? Icons.schedule_rounded
                    : Icons.hourglass_bottom_rounded,
                kSoftOrange,
                timing.message!,
              ),
            if (blocker != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  blocker,
                  style: const TextStyle(color: kSoftOrange),
                ),
              ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: sync == null || sync.busy ? null : _syncNow,
                  icon: const Icon(Icons.sync),
                  label: Text(sync?.busy == true ? 'Syncing…' : 'Sync Now'),
                ),
              ],
            ),
            ...?sync?.entries.map(_entryTile),
          ],
        ),
      ),
    );
  }

  Widget _entryTile(AttendanceSubmission e) {
    final sync = _offline;
    final color = e.replacedBy != null ? kTextSecondary : _stateColor(e.state);
    final reason = describeSubmission(e);
    final retryable =
        e.sendable &&
        (e.state == SubmissionState.savedOffline ||
            e.state == SubmissionState.pendingSync ||
            (e.state == SubmissionState.failed && !e.serverFinal));
    final resubmittable = sync != null && sync.canResubmit(e);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              e.statusLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.date} • ${e.label}'),
                Text(
                  'Captured on device ${_time(e.capturedAt)}'
                  '${e.receivedAt == null ? '' : ' • Received by server ${_time(e.receivedAt!)}'}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                if (e.legacy)
                  const Text(
                    'Saved by an earlier app version.',
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                if (reason.isNotEmpty)
                  Text(reason, style: TextStyle(color: color, fontSize: 12)),
                if (retryable || resubmittable)
                  Wrap(
                    spacing: 4,
                    children: [
                      if (retryable)
                        TextButton(
                          onPressed: sync == null || sync.busy
                              ? null
                              : _syncNow,
                          child: const Text('Retry'),
                        ),
                      if (resubmittable)
                        TextButton(
                          onPressed: () => _confirmResubmit(e),
                          child: const Text('Resubmit'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (e.state == SubmissionState.failed)
            IconButton(
              tooltip: 'Remove from this device',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDismiss(e),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _offline?.removeListener(_onSyncChanged);

    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  Widget _buildDesktopAttendanceBody(
    List<TeacherStudentModel> filtered,
    List<String> filteredStatus,
    List<({int id, String name})> uniqueClasses,
  ) {
    Widget statusButton({
      required String label,
      required String status,
      required int studentIndex,
      required bool selected,
    }) {
      return OutlinedButton(
        onPressed: () => _setStatus(studentIndex, status),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? Colors.white : kTextSecondary,
          backgroundColor: selected ? kPrimaryBlue : Colors.transparent,
          side: BorderSide(color: selected ? kPrimaryBlue : teacherWebBorder),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(label),
      );
    }

    return Container(
      color: teacherWebBg,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(child: _syncPanel()),
          ),
          const TeacherWebSectionTitle(
            title: 'Attendance',
            subtitle: 'Mark and review attendance records.',
          ),
          const SizedBox(height: 16),
          TeacherWebCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherWebDropdown<int?>(
                  label: 'Class',
                  value: _selectedClassId,
                  items: uniqueClasses
                      .map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: _onClassChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _updateSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: kPrimaryBlue,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _onDateTapped,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(_formatDate(_attendanceDate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TeacherWebCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TeacherWebTableHeader(
                    columns: ['Student', 'Roll', 'Status'],
                  ),
                  if (_studentsLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimaryBlue),
                      ),
                    )
                  else if (_studentsError != null)
                    Expanded(
                      child: Center(
                        child: TeacherErrorState(message: _studentsError!),
                      ),
                    )
                  else if (filtered.isEmpty)
                    const Expanded(
                      child: Center(
                        child: TeacherEmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'No students found for this class',
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: teacherWebBorder),
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          final status = filteredStatus[index];
                          final studentIndex = _students.indexOf(student);
                          return TeacherWebTableRow(
                            cells: [
                              Text(
                                student.name ?? 'Student ${student.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                              Text(
                                student.emisNumber ?? '${student.id}',
                                style: const TextStyle(color: kTextSecondary),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  statusButton(
                                    label: 'Present',
                                    status: 'PRESENT',
                                    studentIndex: studentIndex,
                                    selected: status == 'PRESENT',
                                  ),
                                  statusButton(
                                    label: 'Absent',
                                    status: 'ABSENT',
                                    studentIndex: studentIndex,
                                    selected: status == 'ABSENT',
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saving || _saveBlocker != null
                  ? null
                  : _saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save attendance'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredStudents;
    final filteredStatus = filteredStatusList;
    final uniqueClasses = _uniqueClasses;

    if (widget.embedBodyOnly) {
      return _buildDesktopAttendanceBody(
        filtered,
        filteredStatus,
        uniqueClasses,
      );
    }

    final body = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (!widget.embedBodyOnly && widget.showAppBar)
          SliverAppBar(
            expandedHeight: _isSearching ? 84 : 96,
            pinned: true,
            backgroundColor: kPrimaryBlue,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              centerTitle: false,
              title: _isSearching
                  ? null
                  : const Text(
                      "Attendance",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 12, top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(10),
              ),
            ),
            actions: [
              if (_isSearching)
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _stopSearch,
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _startSearch,
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
            bottom: _isSearching
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _updateSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            hintStyle: TextStyle(
                              color: kTextSecondary,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kPrimaryBlue,
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: kTextSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _updateSearchQuery('');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

        // ---------------- MAIN CONTENT ----------------
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _syncPanel(),
              // ---------------- HEADER CARD WITH DROPDOWN ----------------
              _HeaderCardWithDropdown(
                uniqueClasses: uniqueClasses,
                selectedClassId: _selectedClassId,
                selectedClassName: _selectedClassName,
                onClassChanged: _onClassChanged,
                studentCount: currentClassStudents.length,
                formattedDate: _formatDate(_attendanceDate),
                onDateTap: _onDateTapped,
                studentsLoading: _studentsLoading,
              ),

              const SizedBox(height: 20),

              // ---------------- SEARCH RESULT COUNT ----------------
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Found ${filtered.length} student${filtered.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // ---------------- STUDENTS HEADER ----------------
              if (_searchQuery.isEmpty) _buildStudentsHeader(filtered.length),

              const SizedBox(height: 12),

              // ---------------- STUDENT LIST ERROR (e.g. 404) ----------------
              if (_studentsError != null && !_studentsLoading)
                _buildStudentsError(),

              // ---------------- STUDENT CARDS ----------------
              if (filtered.isNotEmpty && _studentsError == null)
                ...List.generate(filtered.length, (index) {
                  final student = filtered[index];
                  final status = filteredStatus[index];
                  final originalIndex = _students.indexOf(student);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudentAttendanceCard(
                      name: student.name ?? 'Student ${student.id}',
                      roll: student.emisNumber ?? '${student.id}',
                      status: status,
                      onStatusChanged: (newStatus) =>
                          _setStatus(originalIndex, newStatus),
                    ),
                  );
                })
              else if (_studentsError == null && !_studentsLoading)
                _buildEmptyState(),

              const SizedBox(height: 20),

              // ---------------- SAVE BUTTON ----------------
              _SaveButton(
                onPressed: _saving || _saveBlocker != null
                    ? null
                    : _saveAttendance,
              ),

              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );

    if (widget.embedBodyOnly) {
      return Container(
        color: teacherWebBg,
        padding: const EdgeInsets.all(24),
        child: body,
      );
    }

    if (!widget.showAppBar) {
      return ColoredBox(
        color: teacherWebBg,
        child: Column(
          children: [
            _buildInlineSearchField(),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(backgroundColor: teacherWebBg, body: body);
  }

  Widget _buildInlineSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryBlue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: teacherWebBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: teacherWebBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimaryBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsHeader(int count) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_rounded,
                color: kPrimaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Student List",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count students',
            style: TextStyle(
              color: kPrimaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: teacherWebBorder),
      ),
      child: TeacherErrorState(
        message:
            _studentsError ??
            'Load the student roster online before using attendance offline.',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TeacherEmptyState(
        icon: _searchQuery.isNotEmpty
            ? Icons.search_off_rounded
            : Icons.people_outline_rounded,
        title: _searchQuery.isNotEmpty ? 'No students found' : 'No students',
        message: _searchQuery.isNotEmpty
            ? 'Try different search terms'
            : 'Select a class to load students',
      ),
    );
  }
}

// ================== HEADER CARD WITH DROPDOWN =====================
class _HeaderCardWithDropdown extends StatelessWidget {
  final List<({int id, String name})> uniqueClasses;
  final int? selectedClassId;
  final String selectedClassName;
  final ValueChanged<int?> onClassChanged;
  final int studentCount;
  final String formattedDate;
  final VoidCallback? onDateTap;
  final bool studentsLoading;

  const _HeaderCardWithDropdown({
    required this.uniqueClasses,
    required this.selectedClassId,
    required this.selectedClassName,
    required this.onClassChanged,
    required this.studentCount,
    required this.formattedDate,
    this.onDateTap,
    this.studentsLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Class Dropdown
          Container(
            decoration: BoxDecoration(
              color: kPrimaryBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedClassId,
                  items: [
                    if (uniqueClasses.isEmpty)
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text(
                          'No classes assigned',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ...uniqueClasses.map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: uniqueClasses.isEmpty ? null : onClassChanged,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  isExpanded: true,
                  dropdownColor: kPrimaryBlue,
                  hint: Text(
                    selectedClassName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Date Row (tappable)
          Row(
            children: [
              GestureDetector(
                onTap: onDateTap,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              if (studentsLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimaryGreen,
                  ),
                )
              else
                Icon(Icons.people_rounded, size: 16, color: kPrimaryGreen),
              const SizedBox(width: 4),
              Text(
                "Total: $studentCount",
                style: TextStyle(
                  color: kPrimaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============== STUDENT ATTENDANCE CARD ==============
class _StudentAttendanceCard extends StatelessWidget {
  final String name;
  final String roll;
  final String status; // PRESENT | ABSENT | LATE
  final ValueChanged<String> onStatusChanged;

  const _StudentAttendanceCard({
    required this.name,
    required this.roll,
    required this.status,
    required this.onStatusChanged,
  });

  static const List<String> _statusCycle = ['PRESENT', 'ABSENT'];

  @override
  Widget build(BuildContext context) {
    final isPresent = status == 'PRESENT';
    final isLate = status == 'LATE';
    final statusColor = isPresent
        ? kPrimaryGreen
        : (isLate ? kSoftOrange : kErrorColor);
    final statusLabel = status == 'LATE'
        ? 'Late'
        : (isPresent ? 'Present' : 'Absent');
    final nextStatus =
        _statusCycle[(_statusCycle.indexOf(status) + 1) % _statusCycle.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onStatusChanged(nextStatus),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      roll,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPresent
                                  ? Icons.check_circle_rounded
                                  : (isLate
                                        ? Icons.schedule_rounded
                                        : Icons.cancel_rounded),
                              color: statusColor,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.touch_app_rounded, size: 20, color: kTextSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== SAVE BUTTON =====================
class _SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SaveButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: kPrimaryGreen,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGreen.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.save_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Save Attendance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
