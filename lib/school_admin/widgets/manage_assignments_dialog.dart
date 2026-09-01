import 'package:flutter/material.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart'
    show showDeleteConfirmDialog;
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _borderGray = Color(0xFFE2E7ED);
const _subtleText = Color(0xFF64748B);

enum _ManageStep { choose, resetYear, clearTeacher }

/// Opens the single, centered "Manage Assignments" dialog reachable from the
/// Course Assign Teacher page's Manage button. The admin explicitly picks an
/// academic year (and, for clearing a teacher, a teacher) inside the dialog
/// — nothing here is pre-submitted from the page's active-year filter.
///
/// Returns `true` if a destructive action completed successfully, so the
/// caller knows to refresh its assignment list.
Future<bool?> showManageAssignmentsDialog(
  BuildContext context, {
  int? initialAcademicYearId,
}) async {
  final academicYearsProvider = context.read<AcademicYearsProvider>();
  final width = MediaQuery.sizeOf(context).width;
  final maxWidth = width < 700 ? width - 32 : 520.0;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => ChangeNotifierProvider<AcademicYearsProvider>.value(
      value: academicYearsProvider,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _ManageAssignmentsForm(
            initialAcademicYearId: initialAcademicYearId,
          ),
        ),
      ),
    ),
  );
}

class _ManageAssignmentsForm extends StatefulWidget {
  final int? initialAcademicYearId;

  const _ManageAssignmentsForm({this.initialAcademicYearId});

  @override
  State<_ManageAssignmentsForm> createState() =>
      _ManageAssignmentsFormState();
}

class _ManageAssignmentsFormState extends State<_ManageAssignmentsForm> {
  _ManageStep _step = _ManageStep.choose;

  int? _resetYearId;
  int? _clearYearId;
  int? _clearTeacherId;

  List<TeacherModel> _teachers = [];
  bool _teachersLoading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _resetYearId = widget.initialAcademicYearId;
    _clearYearId = widget.initialAcademicYearId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final provider = context.read<AcademicYearsProvider>();
    await Future.wait([provider.ensureLoaded(), _loadTeachers()]);
  }

  Future<void> _loadTeachers() async {
    final result = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      _teachersLoading = false;
      if (result is TeacherSuccess<List<TeacherModel>>) _teachers = result.data;
    });
  }

  void _goTo(_ManageStep step) {
    if (_submitting) return;
    setState(() => _step = step);
  }

  Future<void> _confirmResetYear(AcademicYear year) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Reset Academic Year Assignments?',
      message:
          'Academic Year: ${year.name}\n\n'
          'This will remove all teacher course assignments for ${year.name}.'
          '\n\n'
          'It will NOT delete:\n'
          '• Teachers\n'
          '• Classes\n'
          '• Subjects\n'
          '• Timetable entries',
      confirmLabel: 'Reset Assignments',
      icon: Icons.restart_alt_rounded,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    final result = await SchoolAdminAssignmentsService()
        .deleteAssignmentsForYear(year.id);
    if (!mounted) return;
    if (result is AssignmentSuccess<int?>) {
      final count = result.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count != null
                ? '$count assignment${count == 1 ? '' : 's'} removed from ${year.name}.'
                : 'Assignments removed from ${year.name}.',
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as AssignmentError).message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmClearTeacher(AcademicYear year, TeacherModel teacher) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: "Clear ${teacher.fullName}'s Assignments?",
      message:
          'Academic Year: ${year.name}\n\n'
          "This will remove all of ${teacher.fullName}'s course assignments "
          'for the selected academic year only.',
      confirmLabel: 'Clear Assignments',
      icon: Icons.person_remove_alt_1_rounded,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    final result = await SchoolAdminAssignmentsService()
        .deleteAssignmentsForTeacherYear(
          academicYearId: year.id,
          teacherId: teacher.id,
        );
    if (!mounted) return;
    if (result is AssignmentSuccess<int?>) {
      final count = result.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count != null
                ? '$count assignment${count == 1 ? '' : 's'} removed for ${teacher.fullName}.'
                : "${teacher.fullName}'s assignments removed for ${year.name}.",
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as AssignmentError).message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          20,
          22,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(busy: _submitting),
            if (_step != _ManageStep.choose) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _submitting ? null : () => _goTo(_ManageStep.choose),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: _blue,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (provider.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: _green)),
              )
            else if (provider.years.isEmpty)
              const _EmptyYearsNotice()
            else if (_step == _ManageStep.choose)
              _ChooseStep(
                onResetYear: () => _goTo(_ManageStep.resetYear),
                onClearTeacher: () => _goTo(_ManageStep.clearTeacher),
              )
            else if (_step == _ManageStep.resetYear)
              _ResetYearStep(
                years: provider.years,
                selectedYearId: _resetYearId,
                submitting: _submitting,
                onYearChanged: (value) => setState(() => _resetYearId = value),
                onCancel: () => Navigator.pop(context),
                onConfirm: (year) => _confirmResetYear(year),
              )
            else
              _ClearTeacherStep(
                years: provider.years,
                teachers: _teachers,
                teachersLoading: _teachersLoading,
                selectedYearId: _clearYearId,
                selectedTeacherId: _clearTeacherId,
                submitting: _submitting,
                onYearChanged: (value) => setState(() => _clearYearId = value),
                onTeacherChanged: (value) =>
                    setState(() => _clearTeacherId = value),
                onCancel: () => Navigator.pop(context),
                onConfirm: (year, teacher) => _confirmClearTeacher(year, teacher),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool busy;
  const _Header({required this.busy});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.tune_rounded, color: _blue),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Assignments',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _blue,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Manage teacher course assignments by academic year.',
              style: TextStyle(color: _subtleText, fontSize: 13),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Close',
        onPressed: busy ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}

class _EmptyYearsNotice extends StatelessWidget {
  const _EmptyYearsNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FA),
      border: Border.all(color: _borderGray),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: _subtleText),
        SizedBox(width: 10),
        Expanded(child: Text('No academic years available.')),
      ],
    ),
  );
}

class _ChooseStep extends StatelessWidget {
  final VoidCallback onResetYear;
  final VoidCallback onClearTeacher;

  const _ChooseStep({required this.onResetYear, required this.onClearTeacher});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ActionCard(
        icon: Icons.event_busy_rounded,
        title: 'Reset Academic Year',
        subtitle:
            'Remove all teacher course assignments from a selected academic year.',
        onTap: onResetYear,
      ),
      const SizedBox(height: 10),
      _ActionCard(
        icon: Icons.person_remove_alt_1_rounded,
        title: 'Clear Teacher Assignments',
        subtitle:
            "Remove one teacher's assignments from a selected academic year.",
        onTap: onClearTeacher,
      ),
    ],
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderGray),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.red[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _blue),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _subtleText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        ],
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final String heading;
  final String value;
  final String detail;

  const _SummaryCard({
    required this.heading,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _blue.withOpacity(0.05),
      border: Border.all(color: _blue.withOpacity(0.18)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(fontSize: 11, color: _subtleText),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(detail, style: const TextStyle(fontSize: 12.5, color: _subtleText)),
      ],
    ),
  );
}

class _ResetYearStep extends StatelessWidget {
  final List<AcademicYear> years;
  final int? selectedYearId;
  final bool submitting;
  final ValueChanged<int?> onYearChanged;
  final VoidCallback onCancel;
  final ValueChanged<AcademicYear> onConfirm;

  const _ResetYearStep({
    required this.years,
    required this.selectedYearId,
    required this.submitting,
    required this.onYearChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    AcademicYear? selected;
    for (final year in years) {
      if (year.id == selectedYearId) selected = year;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Select3D<int?>(
          value: selected?.id,
          label: 'Academic Year *',
          items: years
              .map(
                (year) => DropdownMenuItem<int?>(
                  value: year.id,
                  child: Text(
                    year.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: submitting ? null : onYearChanged,
        ),
        if (selected != null) ...[
          const SizedBox(height: 14),
          _SummaryCard(
            heading: 'Academic Year',
            value: selected.name,
            detail:
                'You are about to remove all course assignments from this '
                'academic year.',
          ),
        ],
        const SizedBox(height: 18),
        _StepActions(
          submitting: submitting,
          canSubmit: selected != null,
          confirmLabel: 'Reset Assignments',
          confirmColor: Colors.red[700]!,
          onCancel: onCancel,
          onConfirm: selected == null ? null : () => onConfirm(selected!),
        ),
      ],
    );
  }
}

class _ClearTeacherStep extends StatelessWidget {
  final List<AcademicYear> years;
  final List<TeacherModel> teachers;
  final bool teachersLoading;
  final int? selectedYearId;
  final int? selectedTeacherId;
  final bool submitting;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onTeacherChanged;
  final VoidCallback onCancel;
  final void Function(AcademicYear year, TeacherModel teacher) onConfirm;

  const _ClearTeacherStep({
    required this.years,
    required this.teachers,
    required this.teachersLoading,
    required this.selectedYearId,
    required this.selectedTeacherId,
    required this.submitting,
    required this.onYearChanged,
    required this.onTeacherChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    AcademicYear? selectedYear;
    for (final year in years) {
      if (year.id == selectedYearId) selectedYear = year;
    }
    TeacherModel? selectedTeacher;
    for (final teacher in teachers) {
      if (teacher.id == selectedTeacherId) selectedTeacher = teacher;
    }
    final canSubmit = selectedYear != null && selectedTeacher != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Select3D<int?>(
          value: selectedYear?.id,
          label: 'Academic Year *',
          items: years
              .map(
                (year) => DropdownMenuItem<int?>(
                  value: year.id,
                  child: Text(
                    year.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: submitting ? null : onYearChanged,
        ),
        const SizedBox(height: 14),
        Select3D<int?>(
          value: teachers.any((t) => t.id == selectedTeacherId)
              ? selectedTeacherId
              : null,
          label: teachersLoading ? 'Loading teachers...' : 'Teacher *',
          items: teachers
              .map(
                (teacher) => DropdownMenuItem<int?>(
                  value: teacher.id,
                  child: Text(
                    teacher.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (submitting || teachersLoading) ? null : onTeacherChanged,
        ),
        if (selectedYear != null && selectedTeacher != null) ...[
          const SizedBox(height: 14),
          _SummaryCard(
            heading: 'Teacher / Academic Year',
            value: '${selectedTeacher.fullName} — ${selectedYear.name}',
            detail:
                "This will remove all of this teacher's course assignments "
                'for the selected academic year only.',
          ),
        ],
        const SizedBox(height: 18),
        _StepActions(
          submitting: submitting,
          canSubmit: canSubmit,
          confirmLabel: 'Clear Assignments',
          confirmColor: Colors.red[700]!,
          onCancel: onCancel,
          onConfirm: !canSubmit
              ? null
              : () => onConfirm(selectedYear!, selectedTeacher!),
        ),
      ],
    );
  }
}

class _StepActions extends StatelessWidget {
  final bool submitting;
  final bool canSubmit;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  const _StepActions({
    required this.submitting,
    required this.canSubmit,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 10,
    runSpacing: 10,
    children: [
      TextButton(
        onPressed: submitting ? null : onCancel,
        child: const Text('Cancel'),
      ),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: confirmColor.withOpacity(0.5),
        ),
        onPressed: (canSubmit && !submitting) ? onConfirm : null,
        icon: submitting
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.delete_outline_rounded, size: 18),
        label: Text(confirmLabel, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
