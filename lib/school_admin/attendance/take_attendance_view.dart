import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kobac/models/lesson_attendance.dart';
import 'package:kobac/school_admin/attendance/take_attendance_controller.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/services/attendance_service.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';

const Color _kAmber = Color(0xFFB7791F);
const Color _kAbsent = Color(0xFFC0392B);
const Color _kLate = Color(0xFF8E6C00);

/// Branded "Unsaved Attendance" confirmation. True = discard.
Future<bool> confirmDiscardAttendance(BuildContext context) async {
  final discard = await showDeleteConfirmDialog(
    context,
    title: 'Unsaved Attendance',
    message: "You have attendance changes that haven't been saved.",
    confirmLabel: 'Discard',
    cancelLabel: 'Continue Editing',
    icon: Icons.warning_amber_rounded,
  );
  return discard == true;
}

void _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : kAdminGreen,
      ),
    );
}

/// Saves a backend-generated PDF through the existing web/mobile PDF helper
/// (browser download on web, save dialog on Android). Used by the lesson
/// register and both reports. [fetch] returns null when a download is
/// already running, so repeated taps do nothing.
Future<void> saveAttendancePdf(
  BuildContext context, {
  required Future<AttendanceResult<PdfFileResult>?> Function() fetch,
  required String fallbackFilename,
}) async {
  final result = await fetch();
  if (result == null || !context.mounted) return;
  if (result is AttendanceError) {
    _snack(context, result.message, error: true);
    return;
  }
  final file = (result as AttendanceSuccess<PdfFileResult>).data;
  final saved = await savePdfWithFeedback(
    context,
    bytes: file.bytes,
    // Backend Content-Disposition name wins.
    filename: file.filename ?? fallbackFilename,
  );
  // Mobile shows its own "saved" message with the file name.
  if (saved && kIsWeb && context.mounted) {
    _snack(context, 'PDF downloaded.');
  }
}

Future<void> downloadAttendancePdf(
  BuildContext context,
  TakeAttendanceController controller,
) => saveAttendancePdf(
  context,
  fetch: controller.downloadPdf,
  fallbackFilename: controller.pdfFallbackFilename,
);

/// "Print Lesson Attendance" for the open register. Always visible once a
/// register is loaded; disabled, with the reason shown, until attendance has
/// been saved for the lesson (an unrecorded lesson is never printed).
class AttendancePrintButton extends StatelessWidget {
  final TakeAttendanceController controller;
  const AttendancePrintButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.register == null) return const SizedBox.shrink();
      final busy = controller.downloadingPdf;
      final recorded = controller.canPrint;
      final button = AdminSecondaryButton(
        key: const ValueKey('attendance-print'),
        label: busy ? 'Preparing PDF…' : 'Print Lesson Attendance',
        icon: busy ? Icons.hourglass_top_rounded : Icons.picture_as_pdf_outlined,
        onPressed: !recorded || busy || controller.saving
            ? null
            : () => downloadAttendancePdf(context, controller),
      );
      if (recorded) return button;
      return Tooltip(
        message: 'Save attendance for this lesson to print it.',
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            button,
            const Text(
              'Available after attendance is saved',
              key: ValueKey('attendance-print-reason'),
              style: TextStyle(fontSize: 12, color: kAdminTextSecondary),
            ),
          ],
        ),
      );
    },
  );
}

/// Take / edit lesson attendance. Renders as plain sections (no scrolling of
/// its own): the page around it owns the single scroll area.
class TakeAttendanceView extends StatefulWidget {
  final TakeAttendanceController controller;
  final bool isDesktop;

  const TakeAttendanceView({
    super.key,
    required this.controller,
    required this.isDesktop,
  });

  @override
  State<TakeAttendanceView> createState() => _TakeAttendanceViewState();
}

class _TakeAttendanceViewState extends State<TakeAttendanceView> {
  TakeAttendanceController get c => widget.controller;

  /// Runs [action] unless unsaved marks exist and the Admin keeps editing.
  Future<void> _guarded(VoidCallback action) async {
    if (c.saving) return;
    if (c.hasUnsavedChanges && !await confirmDiscardAttendance(context)) {
      return;
    }
    if (!mounted) return;
    action();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: c.date,
      firstDate: c.firstDate,
      lastDate: c.lastDate,
      helpText: 'Attendance date',
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
    if (picked == null || !mounted) return;
    if (DateUtils.isSameDay(picked, c.date)) return;
    await _guarded(() => c.selectDate(picked));
  }

  Future<void> _save() async {
    if (c.saving) return;
    final unmarked = c.unmarkedCount;
    if (unmarked > 0 && c.pendingRecords.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black38,
        builder: (ctx) => AdminFeatureDialog(
          title: 'Some students are not marked',
          maxWidth: 440,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$unmarked ${unmarked == 1 ? 'student is' : 'students are'} '
                'not marked. They will stay "Not marked" — nobody is marked '
                'absent automatically.',
                style: const TextStyle(color: kAdminNavy, height: 1.4),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  AdminSecondaryButton(
                    label: 'Keep Marking',
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  AdminPrimaryButton(
                    label: 'Save Anyway',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (proceed != true || !mounted) return;
    }
    final outcome = await c.save();
    if (outcome == null || !mounted) return;
    _snack(context, outcome.message, error: !outcome.success);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filters(),
        const SizedBox(height: 16),
        _lessonsSection(),
        if (c.timetableId != null) ...[
          const SizedBox(height: 16),
          _registerSection(),
        ],
      ],
    ),
  );

  // --- Filters --------------------------------------------------------------

  Widget _filters() {
    final yearItems = [
      for (final y in c.years)
        DropdownMenuItem<int>(
          value: y.id,
          child: Text(
            y.isActive ? '${y.name} (Active)' : y.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];
    final classItems = [
      for (final cls in c.classes)
        DropdownMenuItem<int>(
          value: cls.id,
          child: Text(cls.name, overflow: TextOverflow.ellipsis),
        ),
    ];
    return AdminFilterBar(
      filters: [
        AdminFilterDropdown<int>(
          key: ValueKey('attendance-year-${c.yearId}-${c.years.length}'),
          label: 'Academic Year',
          value: c.yearId,
          items: yearItems,
          onChanged: c.saving
              ? null
              : (v) {
                  if (v == null || v == c.yearId) return;
                  _guarded(() => c.selectYear(v));
                },
        ),
        AttendanceDateField(
          value: c.date,
          enabled: c.yearId != null && !c.saving,
          onTap: _pickDate,
        ),
        c.classesLoading
            ? const AttendanceSkeletonBlock(height: 46)
            : AdminFilterDropdown<int>(
                key: ValueKey(
                  'attendance-class-${c.classId}-${c.classes.length}-${c.yearId}',
                ),
                label: 'Class',
                value: c.classId,
                items: classItems,
                onChanged: c.saving || c.yearId == null
                    ? null
                    : (v) {
                        if (v == null || v == c.classId) return;
                        _guarded(() => c.selectClass(v));
                      },
              ),
      ],
      actions: c.classesError == null
          ? null
          : [
              Text(
                c.classesError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
              AdminSecondaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: c.loadClasses,
              ),
            ],
    );
  }

  // --- Lessons --------------------------------------------------------------

  Widget _lessonsSection() {
    Widget body;
    if (c.yearId == null) {
      body = const AttendanceInlineState(
        icon: Icons.calendar_month_outlined,
        message: 'Select an academic year to start taking attendance.',
      );
    } else if (c.classId == null) {
      body = const AttendanceInlineState(
        icon: Icons.class_outlined,
        message: 'Select a class and date to view timetable lessons.',
      );
    } else if (c.lessonsLoading && c.lessons.isEmpty) {
      body = const _LessonSkeleton(key: ValueKey('lessons-loading'));
    } else if (c.lessonsError != null && c.lessons.isEmpty) {
      body = AttendanceInlineState(
        key: const ValueKey('lessons-error'),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade700,
        message: c.lessonsError!.message,
        action: AdminSecondaryButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => c.loadLessons(),
        ),
      );
    } else if (c.lessonsLoaded && c.lessons.isEmpty) {
      body = const AttendanceInlineState(
        key: ValueKey('lessons-empty'),
        icon: Icons.event_busy_outlined,
        message: 'No timetable lessons were found for this class on this date.',
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final perRow = w >= 1300 ? 4 : (w >= 900 ? 3 : (w >= 560 ? 2 : 1));
          final cardWidth = (w - 12 * (perRow - 1)) / perRow;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final lesson in c.lessons)
                SizedBox(
                  width: cardWidth,
                  child: _LessonCard(
                    lesson: lesson,
                    selected: lesson.timetableId == c.timetableId,
                    onTap: c.saving
                        ? null
                        : () {
                            if (lesson.timetableId == c.timetableId) return;
                            _guarded(() => c.selectLesson(lesson.timetableId));
                          },
                  ),
                ),
            ],
          );
        },
      );
    }
    final day = c.lessonsDayName;
    return AttendanceSection(
      title: 'Lessons',
      trailing: day == null ? null : AttendanceMutedText('$day · ${c.dateYmd}'),
      child: body,
    );
  }

  // --- Register -------------------------------------------------------------

  Widget _registerSection() {
    if (c.registerLoading && c.register == null) {
      return const AttendanceSection(
        title: 'Student Register',
        child: _RegisterSkeleton(key: ValueKey('register-loading')),
      );
    }
    final error = c.registerError;
    if (error != null && c.register == null) {
      return AttendanceSection(
        title: 'Student Register',
        child: AttendanceInlineState(
          key: const ValueKey('register-error'),
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red.shade700,
          message: error.message,
          action: AdminSecondaryButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: c.loadRegister,
          ),
        ),
      );
    }
    final register = c.register;
    if (register == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LessonInfoCard(
          register: register,
          fallbackClassName: c.selectedClass?.name,
          // Same place on every platform: right beside the selected lesson,
          // above its summary and register.
          print: AttendancePrintButton(controller: c),
        ),
        const SizedBox(height: 12),
        if (!register.attendanceRecorded) ...[
          const AttendanceBanner(
            key: ValueKey('attendance-not-taken'),
            icon: Icons.info_outline_rounded,
            message: 'Attendance has not been taken for this lesson yet.',
          ),
          const SizedBox(height: 12),
        ],
        _SummaryRow(summary: register.summary),
        const SizedBox(height: 16),
        _studentsSection(register),
      ],
    );
  }

  Widget _studentsSection(LessonRegister register) {
    final students = register.students;
    final editable = students.any((s) => s.editable);
    return AttendanceSection(
      title: 'Students (${students.length})',
      trailing: students.isEmpty || !editable
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AdminSecondaryButton(
                  key: const ValueKey('attendance-mark-all-present'),
                  label: 'Mark All Present',
                  icon: Icons.done_all_rounded,
                  onPressed: c.saving ? null : c.markAllPresent,
                ),
                AdminSecondaryButton(
                  key: const ValueKey('attendance-clear-all'),
                  label: 'Clear All',
                  icon: Icons.backspace_outlined,
                  onPressed: c.saving ? null : c.clearAll,
                ),
              ],
            ),
      child: students.isEmpty
          ? const AttendanceInlineState(
              key: ValueKey('register-no-students'),
              icon: Icons.people_outline_rounded,
              message: 'No enrolled students were found for this class.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.isDesktop
                    ? _DesktopRegisterTable(controller: c, students: students)
                    : _MobileRegisterList(controller: c, students: students),
                const SizedBox(height: 16),
                _SaveBar(
                  controller: c,
                  recorded: register.attendanceRecorded,
                  onSave: _save,
                ),
              ],
            ),
    );
  }
}

// ===========================================================================
// Building blocks
// ===========================================================================

class AttendanceSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const AttendanceSection({super.key, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Column(
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kAdminNavy,
            ),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 10),
      child,
    ],
  );
}

class AttendanceMutedText extends StatelessWidget {
  final String text;
  const AttendanceMutedText(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      color: kAdminTextSecondary,
      fontWeight: FontWeight.w600,
    ),
  );
}

class AttendanceDateField extends StatelessWidget {
  final DateTime value;
  final bool enabled;
  final VoidCallback onTap;
  final String label;
  final Key tapKey;
  const AttendanceDateField({
    super.key,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.label = 'Date',
    this.tapKey = const ValueKey('attendance-date'),
  });

  @override
  Widget build(BuildContext context) => InkWell(
    key: tapKey,
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(10),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        enabled: enabled,
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
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: kAdminNavy,
        ),
      ),
      child: Text(
        attendanceYmd(value),
        style: const TextStyle(fontSize: 14, color: kAdminNavy),
      ),
    ),
  );
}

class AttendanceInlineState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String message;
  final Widget? action;
  const AttendanceInlineState({
    super.key,
    required this.icon,
    required this.message,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kAdminBorder),
    ),
    child: Column(
      children: [
        Icon(icon, size: 30, color: iconColor ?? kAdminNavy.withValues(alpha: .35)),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: kAdminTextSecondary, fontSize: 14),
        ),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}

class AttendanceBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  const AttendanceBanner({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _kAmber.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kAmber.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: _kAmber),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: kAdminNavy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class AttendanceSkeletonBlock extends StatelessWidget {
  final double height;
  const AttendanceSkeletonBlock({super.key, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: kAdminNavy.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

class _LessonSkeleton extends StatelessWidget {
  const _LessonSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AttendanceSkeletonBlock(height: 92),
      SizedBox(height: 10),
      AttendanceSkeletonBlock(height: 92),
    ],
  );
}

class _RegisterSkeleton extends StatelessWidget {
  const _RegisterSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AttendanceSkeletonBlock(height: 72),
      const SizedBox(height: 12),
      for (var i = 0; i < 4; i++) ...[
        const AttendanceSkeletonBlock(height: 52),
        const SizedBox(height: 8),
      ],
    ],
  );
}

// --- Lesson card ------------------------------------------------------------

class _LessonStatusPill extends StatelessWidget {
  final bool recorded;
  const _LessonStatusPill({required this.recorded});

  @override
  Widget build(BuildContext context) => AdminStatusPill(
    label: recorded ? 'Recorded' : 'Not Taken',
    color: recorded ? kAdminGreen : _kAmber,
    icon: recorded ? Icons.check_circle_rounded : Icons.schedule_rounded,
  );
}

class _LessonCard extends StatelessWidget {
  final AttendanceLesson lesson;
  final bool selected;
  final VoidCallback? onTap;
  const _LessonCard({
    required this.lesson,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label:
        '${lesson.periodLabel}, ${lesson.subjectLabel}, '
        '${lesson.attendanceRecorded ? 'attendance recorded' : 'attendance not taken'}',
    child: Material(
      color: selected ? kAdminNavy.withValues(alpha: .05) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('lesson-${lesson.timetableId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kAdminNavy : kAdminBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.periodLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kAdminTextSecondary,
                      ),
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.radio_button_checked_rounded,
                        size: 18,
                        color: kAdminNavy,
                      ),
                    ),
                  _LessonStatusPill(recorded: lesson.attendanceRecorded),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lesson.subjectLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kAdminNavy,
                ),
              ),
              const SizedBox(height: 6),
              _IconLine(Icons.access_time_rounded, lesson.timeRange),
              const SizedBox(height: 2),
              _IconLine(Icons.person_outline_rounded, lesson.teacherLabel),
            ],
          ),
        ),
      ),
    ),
  );
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: kAdminTextSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text.isEmpty ? '—' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: kAdminTextSecondary),
        ),
      ),
    ],
  );
}

// --- Selected lesson / summary ---------------------------------------------

class _LessonInfoCard extends StatelessWidget {
  final LessonRegister register;
  final String? fallbackClassName;
  final Widget? print;
  const _LessonInfoCard({
    required this.register,
    this.fallbackClassName,
    this.print,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = register.lesson;
    final items = <(String, String)>[
      ('Class', register.className ?? fallbackClassName ?? '—'),
      ('Subject', lesson.subjectLabel),
      ('Teacher', lesson.teacherLabel),
      (
        'Date',
        register.dayName == null
            ? (register.date ?? '—')
            : '${register.dayName}, ${register.date ?? ''}',
      ),
      ('Period', lesson.periodLabel),
      ('Time', lesson.timeRange.isEmpty ? '—' : lesson.timeRange),
    ];
    return Container(
      key: const ValueKey('attendance-lesson-info'),
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
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Selected Lesson',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kAdminNavy,
                    ),
                  ),
                  _LessonStatusPill(recorded: register.attendanceRecorded),
                ],
              ),
              ?print,
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final perRow = w >= 760 ? 6 : (w >= 420 ? 3 : 2);
              final itemWidth = (w - 12 * (perRow - 1)) / perRow;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final (label, value) in items)
                    SizedBox(
                      width: itemWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Compact backend summary: values are shown exactly as the backend sent.
class _SummaryRow extends StatelessWidget {
  final RegisterSummary summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final chips = [
      ('Total Students', '${summary.totalStudents}', kAdminNavy),
      ('Recorded', '${summary.recorded}', kAdminNavy),
      ('Present', '${summary.present}', kAdminGreen),
      ('Absent', '${summary.absent}', _kAbsent),
      ('Late', '${summary.late}', _kLate),
      ('Attendance', summary.percentageLabel, kAdminNavy),
    ];
    return Wrap(
      key: const ValueKey('attendance-summary'),
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value, color) in chips)
          Container(
            key: ValueKey('summary-$label'),
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
}

// --- Student register -------------------------------------------------------

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

/// Text (not color alone) describing a row's current local state.
String? _statusNote(RegisterStudent s, String? local) {
  if (!s.enrolled) return 'Not enrolled · read only';
  if (local == null) return 'Not marked';
  if (local == kStatusLate) return 'Late (recorded earlier)';
  if (local != s.status) return 'Unsaved change';
  if (!kLessonRegisterStatuses.contains(local)) return 'Recorded as $local';
  return null;
}

Color _noteColor(RegisterStudent s, String? local) {
  if (local == kStatusLate) return _kLate;
  if (local != null && local != s.status) return _kAmber;
  return kAdminTextSecondary;
}

class _MarkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;
  const _MarkButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : kAdminBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? icon : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected
                    ? Colors.white
                    : (onTap == null
                          ? kAdminTextSecondary.withValues(alpha: .4)
                          : kAdminTextSecondary),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : (onTap == null
                              ? kAdminTextSecondary.withValues(alpha: .5)
                              : kAdminNavy),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _presentButton(
  TakeAttendanceController c,
  RegisterStudent s,
  String? local,
) => _MarkButton(
  key: ValueKey('mark-present-${s.studentId}'),
  label: 'Present',
  icon: Icons.check_circle_rounded,
  selected: local == kStatusPresent,
  color: kAdminGreen,
  onTap: s.editable && !c.saving
      ? () => c.setMark(s.studentId, kStatusPresent)
      : null,
);

Widget _absentButton(
  TakeAttendanceController c,
  RegisterStudent s,
  String? local,
) => _MarkButton(
  key: ValueKey('mark-absent-${s.studentId}'),
  label: 'Absent',
  icon: Icons.cancel_rounded,
  selected: local == kStatusAbsent,
  color: _kAbsent,
  onTap: s.editable && !c.saving
      ? () => c.setMark(s.studentId, kStatusAbsent)
      : null,
);

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar(this.name);
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: kAdminNavy.withValues(alpha: .08),
      shape: BoxShape.circle,
    ),
    child: Text(
      _initials(name),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: kAdminNavy,
      ),
    ),
  );
}

class _MobileRegisterList extends StatelessWidget {
  final TakeAttendanceController controller;
  final List<RegisterStudent> students;
  const _MobileRegisterList({required this.controller, required this.students});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final s in students)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ValueListenableBuilder<String?>(
            valueListenable: controller.markFor(s.studentId),
            builder: (context, local, _) {
              final note = _statusNote(s, local);
              return Container(
                key: ValueKey('student-${s.studentId}'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAdminBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _Avatar(s.displayName),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kAdminNavy,
                                ),
                              ),
                              Text(
                                s.emisNumber ?? 'No EMIS number',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kAdminTextSecondary,
                                ),
                              ),
                              if (note != null)
                                Text(
                                  note,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _noteColor(s, local),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _presentButton(controller, s, local)),
                        const SizedBox(width: 8),
                        Expanded(child: _absentButton(controller, s, local)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ],
  );
}

class _DesktopRegisterTable extends StatelessWidget {
  final TakeAttendanceController controller;
  final List<RegisterStudent> students;
  const _DesktopRegisterTable({
    required this.controller,
    required this.students,
  });

  static const _flexes = [1, 2, 4, 2, 2];

  @override
  Widget build(BuildContext context) => AdminTableCard(
    columns: const [
      AdminTableColumn('No.', flex: 1),
      AdminTableColumn('EMIS', flex: 2),
      AdminTableColumn('Student Name', flex: 4),
      AdminTableColumn('Present', flex: 2),
      AdminTableColumn('Absent', flex: 2),
    ],
    rows: [
      for (var i = 0; i < students.length; i++)
        AdminTableRow(
          key: ValueKey('student-${students[i].studentId}'),
          flexes: _flexes,
          cells: [
            Text(
              '${i + 1}',
              style: const TextStyle(color: kAdminTextSecondary, fontSize: 13),
            ),
            Text(
              students[i].emisNumber ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kAdminNavy, fontSize: 13),
            ),
            _listen(students[i], (s, local) {
              final note = _statusNote(s, local);
              return Row(
                children: [
                  _Avatar(s.displayName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kAdminNavy,
                          ),
                        ),
                        if (note != null)
                          Text(
                            note,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _noteColor(s, local),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            _listen(
              students[i],
              (s, local) => Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 120,
                  child: _presentButton(controller, s, local),
                ),
              ),
            ),
            _listen(
              students[i],
              (s, local) => Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 120,
                  child: _absentButton(controller, s, local),
                ),
              ),
            ),
          ],
        ),
    ],
  );

  Widget _listen(
    RegisterStudent s,
    Widget Function(RegisterStudent, String?) build,
  ) => ValueListenableBuilder<String?>(
    valueListenable: controller.markFor(s.studentId),
    builder: (context, local, _) => build(s, local),
  );
}

class _SaveBar extends StatelessWidget {
  final TakeAttendanceController controller;
  final bool recorded;
  final VoidCallback onSave;
  const _SaveBar({
    required this.controller,
    required this.recorded,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: controller.marksVersion,
    builder: (context, _, _) {
      final pending = controller.pendingRecords.length;
      final unmarked = controller.unmarkedCount;
      final saving = controller.saving;
      final parts = [
        if (pending > 0)
          '$pending unsaved ${pending == 1 ? 'change' : 'changes'}'
        else
          'No unsaved changes',
        if (unmarked > 0) '$unmarked not marked',
      ];
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kAdminBorder),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Text(
              parts.join(' · '),
              key: const ValueKey('attendance-pending'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: pending > 0 ? _kAmber : kAdminTextSecondary,
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('attendance-save'),
              onPressed: saving || pending == 0 ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: kAdminGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                saving
                    ? 'Saving…'
                    : (recorded ? 'Save Changes' : 'Save Attendance'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
