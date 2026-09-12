import 'package:flutter/material.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/timetables_service.dart';
import 'package:kobac/utils/student_pdf_handler.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _borderGray = Color(0xFFE2E7ED);
const _subtleText = Color(0xFF64748B);

/// Opens the single, centered "Print Timetable" dialog used by the Time
/// Table page on both mobile and PWA. The admin picks between Teacher
/// Timetable and Classes by Level inside the dialog itself — there is only
/// one print entry point on the page.
Future<void> showTimetablePrintDialog(
  BuildContext context, {
  int? initialAcademicYearId,
  int? initialTeacherId,
  bool initialClassesByLevel = false,
}) async {
  final provider = context.read<AcademicYearsProvider>();
  final width = MediaQuery.sizeOf(context).width;
  final maxWidth = width < 700 ? width - 32 : 560.0;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => ChangeNotifierProvider<AcademicYearsProvider>.value(
      value: provider,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _TimetablePrintForm(
            initialYearId: initialAcademicYearId,
            initialTeacherId: initialTeacherId,
            initialClassesByLevel: initialClassesByLevel,
          ),
        ),
      ),
    ),
  );
}

class _TimetablePrintForm extends StatefulWidget {
  final int? initialYearId;
  final int? initialTeacherId;
  final bool initialClassesByLevel;

  const _TimetablePrintForm({
    this.initialYearId,
    this.initialTeacherId,
    this.initialClassesByLevel = false,
  });

  @override
  State<_TimetablePrintForm> createState() => _TimetablePrintFormState();
}

class _TimetablePrintFormState extends State<_TimetablePrintForm> {
  late bool _classesByLevel;
  int? _yearId;
  int? _teacherId;
  int? _levelId;
  List<TeacherModel> _teachers = [];
  List<SchoolLevel> _levels = [];
  bool _teachersLoading = true;
  bool _levelsLoading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _classesByLevel = widget.initialClassesByLevel;
    _yearId = widget.initialYearId;
    _teacherId = widget.initialTeacherId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final provider = context.read<AcademicYearsProvider>();
    await Future.wait([
      provider.ensureLoaded(),
      _loadTeachers(),
      _loadLevels(),
    ]);
    if (!mounted) return;
    setState(() => _yearId ??= provider.activeYear?.id);
  }

  Future<void> _loadTeachers() async {
    final result = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      _teachersLoading = false;
      if (result is TeacherSuccess<List<TeacherModel>>) _teachers = result.data;
    });
  }

  Future<void> _loadLevels() async {
    final result = await ExamHallService().levels();
    if (!mounted) return;
    setState(() {
      _levelsLoading = false;
      if (result is HallSuccess<List<SchoolLevel>>) _levels = result.data;
    });
  }

  String _safe(String value) =>
      value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');

  String get _yearName {
    for (final year in context.read<AcademicYearsProvider>().years) {
      if (year.id == _yearId) return year.name;
    }
    return 'academic-year';
  }

  String get _teacherName {
    for (final teacher in _teachers) {
      if (teacher.id == _teacherId) return teacher.fullName;
    }
    return 'teacher';
  }

  String? get _levelName {
    for (final level in _levels) {
      if (level.id == _levelId) return level.name;
    }
    return null;
  }

  String get _primaryLabel {
    if (!_classesByLevel) return 'Print Teacher Timetable';
    final name = _levelName;
    return name != null && name.isNotEmpty
        ? 'Print $name Timetable'
        : 'Print Level Timetable';
  }

  void _selectType(bool classesByLevel) {
    if (_generating || _classesByLevel == classesByLevel) return;
    setState(() {
      _classesByLevel = classesByLevel;
      if (classesByLevel) _teacherId = null;
      // _levelId is intentionally left untouched here so switching between
      // Teacher/Classes-by-Level modes never silently drops a level the
      // admin already picked.
    });
  }

  Future<void> _generate(bool download) async {
    if (_generating || _yearId == null) return;
    if (!_classesByLevel && _teacherId == null) return;
    if (_classesByLevel && _levelId == null) return;
    setState(() => _generating = true);
    final result = _classesByLevel
        ? await TimetablesService().getClassesByLevelTimetablePrintPdf(
            academicYearId: _yearId!,
            levelId: _levelId!,
            levelLabel: _levelName,
          )
        : await TimetablesService().getTeacherTimetablePrintPdf(
            teacherId: _teacherId!,
            academicYearId: _yearId!,
          );
    if (!mounted) return;
    if (result is TimetableError) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }
    final document = (result as TimetableSuccess<PdfFileResult>).data;
    final filename =
        document.filename ??
        (_classesByLevel
            ? 'classes-by-level-${_safe(_levelName ?? 'level')}-${_safe(_yearName)}.pdf'
            : 'timetable-${_safe(_teacherName)}-${_safe(_yearName)}.pdf');
    try {
      if (download) {
        await savePdfWithFeedback(
          context,
          bytes: document.bytes,
          filename: filename,
        );
      } else {
        final opened = await previewStudentPdf(document.bytes, filename);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Allow pop-ups to preview the PDF.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The PDF could not be generated. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    final validYear = provider.years.any((year) => year.id == _yearId);
    final validTeacher = _teachers.any((t) => t.id == _teacherId);
    final validLevel = _levels.any((l) => l.id == _levelId);
    final canSubmit =
        validYear &&
        (_classesByLevel ? validLevel : validTeacher) &&
        !_generating;

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
            _Header(busy: _generating),
            const SizedBox(height: 18),
            _PrintTypeCard(
              icon: Icons.co_present_rounded,
              title: 'Teacher Timetable',
              subtitle: 'Print the timetable for one selected teacher.',
              selected: !_classesByLevel,
              onTap: () => _selectType(false),
            ),
            const SizedBox(height: 10),
            _PrintTypeCard(
              icon: Icons.groups_rounded,
              title: 'Classes by Level',
              subtitle:
                  'Print one weekly wall timetable containing all classes '
                  'in the selected level.',
              selected: _classesByLevel,
              onTap: () => _selectType(true),
            ),
            const SizedBox(height: 18),
            Select3D<int?>(
              value: validYear ? _yearId : null,
              label: 'Academic Year *',
              items: provider.years
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
              onChanged: _generating || provider.loading
                  ? null
                  : (value) => setState(() => _yearId = value),
            ),
            if (!_classesByLevel) ...[
              const SizedBox(height: 14),
              Select3D<int?>(
                value: validTeacher ? _teacherId : null,
                label: _teachersLoading ? 'Loading teachers...' : 'Teacher *',
                items: _teachers
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
                onChanged: _generating || _teachersLoading
                    ? null
                    : (value) => setState(() => _teacherId = value),
              ),
            ] else ...[
              const SizedBox(height: 14),
              Select3D<int?>(
                value: validLevel ? _levelId : null,
                label: _levelsLoading ? 'Loading levels...' : 'Level *',
                items: _levels
                    .map(
                      (level) => DropdownMenuItem<int?>(
                        value: level.id,
                        child: Text(
                          level.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _generating || _levelsLoading
                    ? null
                    : (value) => setState(() => _levelId = value),
              ),
              const SizedBox(height: 10),
              const Text(
                'Creates one A4 landscape weekly timetable containing all '
                'classes in the selected level.',
                style: TextStyle(fontSize: 12, color: _subtleText),
              ),
            ],
            if (_generating) const _GeneratingIndicator(),
            const SizedBox(height: 20),
            _Actions(
              canSubmit: canSubmit,
              busy: _generating,
              primaryLabel: _primaryLabel,
              onPreview: () => _generate(false),
              onDownload: () => _generate(true),
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
        child: const Icon(Icons.print_rounded, color: _blue),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Print Timetable',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _blue,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Choose what you want to print',
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

class _PrintTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PrintTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? _blue.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _blue : _borderGray,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (selected ? _blue : Colors.grey).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? _blue : Colors.grey[600],
            ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? _blue : Colors.black87,
                  ),
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
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? _green : Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _green),
        ),
        SizedBox(width: 10),
        Flexible(
          child: Text(
            'Generating document...',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  final bool canSubmit;
  final bool busy;
  final String primaryLabel;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  const _Actions({
    required this.canSubmit,
    required this.busy,
    required this.primaryLabel,
    required this.onPreview,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 10,
    runSpacing: 10,
    children: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      OutlinedButton.icon(
        onPressed: canSubmit ? onPreview : null,
        icon: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.preview_rounded, size: 18),
        label: const Text('Preview'),
      ),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _green.withOpacity(0.5),
        ),
        onPressed: canSubmit ? onDownload : null,
        icon: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download_rounded, size: 18),
        label: Text(primaryLabel, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
