import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/models/lesson_attendance.dart';
import 'package:kobac/school_admin/attendance/attendance_review_controller.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/services/attendance_review_service.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/auth_provider.dart';

const _amber = Color(0xFFD97706);
const _red = Color(0xFFDC2626);

String _two(int v) => v.toString().padLeft(2, '0');
String _stamp(DateTime? t) {
  if (t == null) return '—';
  final l = t.toLocal();
  return '${l.year}-${_two(l.month)}-${_two(l.day)} ${_two(l.hour)}:${_two(l.minute)}';
}

String _lessonTime(AttendanceSubmissionAudit a) {
  final start = formatLessonTime(a.startTime);
  final end = formatLessonTime(a.endTime);
  if (start.isEmpty && end.isEmpty) return 'Time not recorded';
  return [start, end].where((s) => s.isNotEmpty).join(' – ');
}

/// Text of the Legacy Review introduction; shared with tests.
const kLegacyReviewIntro =
    'New teacher attendance, including late and offline submissions, is '
    'accepted automatically and appears in Records and Reports. The '
    'submissions below were queued for approval under the earlier rules (or '
    'their lesson time could not be verified) and still need a decision. '
    'Approving records the teacher\'s marks; rejecting records nothing.';

/// School Admin "Legacy Review" tab, shown only while legacy `pending
/// approval` submissions exist. Not part of the normal attendance workflow.
class AttendanceReviewView extends StatefulWidget {
  final AttendanceReviewController controller;
  final bool isDesktop;
  const AttendanceReviewView({
    super.key,
    required this.controller,
    required this.isDesktop,
  });

  @override
  State<AttendanceReviewView> createState() => _AttendanceReviewViewState();
}

class _AttendanceReviewViewState extends State<AttendanceReviewView> {
  AttendanceReviewController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (_allowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && c.items.isEmpty && !c.loading) c.load();
      });
    }
  }

  /// Server-side every route requires SCHOOL_ADMIN; this only avoids
  /// showing the tab's actions to anyone else.
  bool get _allowed {
    AuthProvider? auth;
    try {
      auth = Provider.of<AuthProvider?>(context, listen: false);
    } catch (_) {}
    final role = auth?.user?.role;
    return role == null || role.toUpperCase() == 'SCHOOL_ADMIN';
  }

  Future<void> _open(AttendanceSubmissionAudit a) async {
    final detail = SubmissionReviewDetail(controller: c, submission: a);
    if (widget.isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
            child: detail,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: kAdminBg,
            appBar: AppBar(
              title: const Text('Legacy submission'),
              backgroundColor: Colors.white,
              foregroundColor: kAdminNavy,
              elevation: 0,
            ),
            body: SafeArea(child: detail),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_allowed) {
      return const AdminEmptyState(
        icon: Icons.lock_outline,
        title: 'School Admins only',
        message: 'Only School Admin accounts can review teacher attendance.',
      );
    }
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Column(
        key: const ValueKey('attendance-review'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'Legacy Review',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kAdminNavy,
                ),
              ),
              AdminSecondaryButton(
                key: const ValueKey('review-refresh'),
                label: 'Refresh',
                icon: Icons.refresh,
                onPressed: c.loading ? null : c.load,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            kLegacyReviewIntro,
            style: TextStyle(fontSize: 13, color: kAdminTextSecondary),
          ),
          const SizedBox(height: 12),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    if (c.loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
      );
    }
    if (c.error != null && c.items.isEmpty) {
      return AdminErrorState(
        title: 'Could not load submissions',
        message: c.error!,
        onRetry: c.load,
      );
    }
    if (c.items.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'No legacy submissions waiting',
        message:
            'Everything has been decided. New teacher attendance is accepted '
            'automatically and needs no action.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in c.items)
          _SubmissionTile(
            key: ValueKey('submission-${a.id}'),
            submission: a,
            controller: c,
            wide: widget.isDesktop,
            onOpen: () => _open(a),
          ),
      ],
    );
  }
}

/// Status pill for a legacy pending submission.
const _legacyPill = AdminStatusPill(label: 'LEGACY PENDING', color: _amber);

class _SubmissionTile extends StatelessWidget {
  final AttendanceSubmissionAudit submission;
  final AttendanceReviewController controller;
  final bool wide;
  final VoidCallback onOpen;
  const _SubmissionTile({
    super.key,
    required this.submission,
    required this.controller,
    required this.wide,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final a = submission;
    final reason = submissionReasonText(a.reason);
    final title = Text(
      '${controller.subjectName(a)} · ${controller.className(a)}',
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: kAdminNavy,
        fontSize: 15,
      ),
    );
    final facts = <Widget>[
      _fact(Icons.person_outline, controller.teacherName(a)),
      _fact(
        Icons.event_outlined,
        '${a.date ?? 'Date unknown'}${a.day == null ? '' : ' (${a.day})'} · ${_lessonTime(a)}',
      ),
      _fact(Icons.cloud_done_outlined, 'Received ${_stamp(a.receivedAt)}'),
      _fact(
        Icons.groups_outlined,
        '${a.marks.length} students · ${a.presentCount} present · ${a.absentCount} absent',
      ),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAdminBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 8),
                  _legacyPill,
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 18, runSpacing: 6, children: facts),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: const TextStyle(fontSize: 12.5, color: _amber),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: wide ? Alignment.centerRight : Alignment.centerLeft,
                child: TextButton.icon(
                  key: ValueKey('review-open-${a.id}'),
                  onPressed: onOpen,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _fact(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: kAdminTextSecondary),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: kAdminTextSecondary),
        ),
      ),
    ],
  );
}

/// Full legacy submission: lesson, timing, each student's submitted status
/// and the register's current status, plus Approve / Reject while pending.
class SubmissionReviewDetail extends StatefulWidget {
  final AttendanceReviewController controller;
  final AttendanceSubmissionAudit submission;
  const SubmissionReviewDetail({
    super.key,
    required this.controller,
    required this.submission,
  });

  @override
  State<SubmissionReviewDetail> createState() => _SubmissionReviewDetailState();
}

class _SubmissionReviewDetailState extends State<SubmissionReviewDetail> {
  AttendanceResult<LessonRegister>? _register;
  bool _registerLoading = true;

  AttendanceSubmissionAudit get a => widget.submission;
  AttendanceReviewController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadRegister();
  }

  Future<void> _loadRegister() async {
    final res = await c.loadRegister(a);
    if (!mounted) return;
    setState(() {
      _register = res;
      _registerLoading = false;
    });
  }

  LessonRegister? get _reg => _register is AttendanceSuccess<LessonRegister>
      ? (_register as AttendanceSuccess<LessonRegister>).data
      : null;

  Future<void> _decide(bool approve) async {
    final String note;
    if (approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => const _ApproveDialog(),
      );
      if (ok != true || !mounted) return;
      note = '';
    } else {
      final reason = await showDialog<String>(
        context: context,
        builder: (_) => const _RejectDialog(),
      );
      if (reason == null || !mounted) return;
      note = reason;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final result = await c.decide(a, approve: approve, note: note);
    messenger?.removeCurrentSnackBar(); // show the outcome immediately
    messenger?.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? kAdminGreen : _red,
      ),
    );
    if (result.settled && mounted) navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final reg = _reg;
    final byId = {
      for (final s in reg?.students ?? const <RegisterStudent>[])
        s.studentId: s,
    };
    final submittedIds = {for (final m in a.marks) m.studentId};
    final notSubmitted = (reg?.students ?? const <RegisterStudent>[])
        .where((s) => !submittedIds.contains(s.studentId))
        .toList();
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final busy = c.deciding.contains(a.id);
        return Column(
          key: ValueKey('submission-detail-${a.id}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${reg?.lesson.subjectName ?? c.subjectName(a)} · ${reg?.className ?? c.className(a)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kAdminNavy,
                          ),
                        ),
                      ),
                      _legacyPill,
                    ],
                  ),
                  const SizedBox(height: 10),
                  _row('Teacher', reg?.lesson.teacherName ?? c.teacherName(a)),
                  _row(
                    'Lesson',
                    '${a.date ?? '—'}${a.day == null ? '' : ' (${a.day})'} · ${_lessonTime(a)}',
                  ),
                  _row('Received by server', _stamp(a.receivedAt)),
                  _row(
                    'Captured on device',
                    a.recordedAt == null
                        ? 'Not provided'
                        : '${_stamp(DateTime.tryParse(a.recordedAt!))} (teacher device claim)',
                  ),
                  if (a.reason != null)
                    _row('Reason', submissionReasonText(a.reason)),
                  if (a.decision != null)
                    _row(
                      'Decision',
                      '${a.decision == 'approve' ? 'Approved' : 'Rejected'} ${_stamp(a.decidedAt)}'
                          '${a.decisionNote == null ? '' : ' — "${a.decisionNote}"'}',
                    ),
                  _row(
                    'Students',
                    '${a.marks.length} submitted · ${a.presentCount} present · ${a.absentCount} absent',
                  ),
                  if (reg != null && reg.attendanceRecorded && a.isPending)
                    _warning(
                      'Attendance for this lesson already exists in the '
                      'register. The server will refuse an approval and mark '
                      'this submission Conflict; nothing will be overwritten.',
                    ),
                  if (_register is AttendanceError)
                    _warning(
                      'Student names could not be loaded '
                      '(${(_register as AttendanceError).message}). Showing student IDs.',
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Student statuses',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kAdminNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_registerLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(color: kAdminNavy),
                      ),
                    ),
                  for (final m in a.marks)
                    _studentRow(
                      byId[m.studentId]?.studentName ??
                          'Student #${m.studentId}',
                      byId[m.studentId]?.emisNumber,
                      m.status,
                      byId[m.studentId]?.status,
                    ),
                  if (notSubmitted.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${notSubmitted.length} enrolled student(s) not in this '
                      'submission will stay unrecorded: '
                      '${notSubmitted.map((s) => s.studentName ?? '#${s.studentId}').join(', ')}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: kAdminTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (a.isPending)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: kAdminBorder)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('review-reject'),
                      onPressed: busy ? null : () => _decide(false),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: _red),
                    ),
                    ElevatedButton.icon(
                      key: const ValueKey('review-approve'),
                      onPressed: busy ? null : () => _decide(true),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(busy ? 'Sending…' : 'Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAdminGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value) {
    final labelText = Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        color: kAdminTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
    final valueText = Text(
      value,
      style: const TextStyle(fontSize: 13.5, color: kAdminNavy),
    );
    // Phones: label above value so values keep the full width.
    if (MediaQuery.sizeOf(context).width < 480) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelText, valueText],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: labelText),
          Expanded(child: valueText),
        ],
      ),
    );
  }

  Widget _warning(String text) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _amber.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _amber.withValues(alpha: .35)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );

  Widget _studentRow(
    String name,
    String? emis,
    String submitted,
    String? current,
  ) {
    final present = submitted == 'PRESENT';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kAdminBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kAdminNavy,
                  ),
                ),
                if (emis != null || current != null)
                  Text(
                    [
                      ?emis,
                      if (current != null) 'Register now: $current',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: kAdminTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          AdminStatusPill(
            label: present ? 'PRESENT' : submitted,
            color: present ? kAdminGreen : _red,
          ),
        ],
      ),
    );
  }
}

/// Approve a legacy submission: a plain confirmation with no text input.
/// Returns true when confirmed, null if cancelled.
class _ApproveDialog extends StatelessWidget {
  const _ApproveDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('approve-dialog'),
      title: const Text('Record this legacy submission?'),
      content: const SizedBox(
        width: 420,
        child: Text(
          'The teacher\'s marks will be added to the attendance register.',
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('review-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const ValueKey('review-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kAdminGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

/// Reject: a meaningful reason is required (backend stores it as the
/// decision note shown to the teacher). Returns the reason, or null.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _reason.text.trim();
    if (text.length < kMinRejectReasonLength) {
      setState(
        () => _error = text.isEmpty
            ? 'A rejection reason is required.'
            : 'Enter a meaningful reason (at least $kMinRejectReasonLength characters).',
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('reject-dialog'),
      scrollable: true,
      title: const Text('Reject this attendance submission?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No attendance will be recorded from this submission. The '
              'teacher will see your reason.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('review-note'),
              controller: _reason,
              maxLength: 1000,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Rejection reason',
                hintText: 'e.g. Wrong class register submitted',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('review-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const ValueKey('review-confirm'),
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Rejection'),
        ),
      ],
    );
  }
}

/// View/update the school's timezone and grace period.
class AttendancePolicyDialog extends StatefulWidget {
  final AttendanceReviewController controller;
  const AttendancePolicyDialog({super.key, required this.controller});

  @override
  State<AttendancePolicyDialog> createState() => _AttendancePolicyDialogState();
}

class _AttendancePolicyDialogState extends State<AttendancePolicyDialog> {
  final _grace = TextEditingController();
  final _tz = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _grace.dispose();
    _tz.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await widget.controller.loadPolicy();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (res) {
        case AttendanceSuccess(:final data):
          _grace.text = '${data.graceMinutes}';
          _tz.text = data.timezone;
        case AttendanceError(:final message):
          _error = message;
      }
    });
  }

  Future<void> _save() async {
    final grace = int.tryParse(_grace.text.trim());
    final tz = _tz.text.trim();
    if (grace == null || grace < 0 || grace > 1440) {
      setState(() => _fieldError = 'Enter whole minutes from 0 to 1440.');
      return;
    }
    if (tz.isEmpty || !tz.contains('/') && tz != 'UTC') {
      setState(
        () => _fieldError = 'Enter an IANA timezone, e.g. Africa/Mogadishu.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _fieldError = null;
      _error = null;
    });
    final res = await widget.controller.savePolicy(
      AttendancePolicy(timezone: tz, graceMinutes: grace),
    );
    if (!mounted) return;
    switch (res) {
      case AttendanceSuccess(:final data):
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            backgroundColor: kAdminGreen,
            content: Text(
              'Saved: ${data.graceMinutes} minutes grace (${data.timezone}).',
            ),
          ),
        );
        Navigator.of(context).pop();
      case AttendanceError(:final message):
        setState(() {
          _saving = false;
          _error = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('attendance-policy-dialog'),
      scrollable: true,
      title: const Text('Attendance policy'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teachers can submit attendance any time after a lesson '
                    'starts, including later or from an offline device; it '
                    'is accepted without approval. The grace period after '
                    'the lesson ends (server receipt time, school timezone) '
                    'decides whether a submission is logged as on time or '
                    'late, and how long teachers can correct their own '
                    'attendance. Default: 30 minutes, Africa/Mogadishu.',
                    style: TextStyle(fontSize: 13, color: kAdminTextSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const ValueKey('policy-grace'),
                    controller: _grace,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Grace period (minutes)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('policy-timezone'),
                    controller: _tz,
                    decoration: const InputDecoration(
                      labelText: 'School timezone (IANA)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_fieldError != null || _error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _fieldError ?? _error!,
                      style: const TextStyle(color: _red),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          key: const ValueKey('policy-save'),
          onPressed: _loading || _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
