import 'package:flutter/material.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:kobac/services/timetable_generator_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const _navy = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

Future<bool?> showTimetableGeneratorDialog(
  BuildContext context, {
  required List<AcademicYear> years,
  int? initialAcademicYearId,
  VoidCallback? onOpenCourseAssignments,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _TimetableGeneratorDialog(
    years: years,
    initialAcademicYearId: initialAcademicYearId,
    onOpenCourseAssignments: onOpenCourseAssignments,
  ),
);

class _TimetableGeneratorDialog extends StatefulWidget {
  final List<AcademicYear> years;
  final int? initialAcademicYearId;
  final VoidCallback? onOpenCourseAssignments;
  const _TimetableGeneratorDialog({
    required this.years,
    this.initialAcademicYearId,
    this.onOpenCourseAssignments,
  });

  @override
  State<_TimetableGeneratorDialog> createState() =>
      _TimetableGeneratorDialogState();
}

class _TimetableGeneratorDialogState extends State<_TimetableGeneratorDialog> {
  int _step = 0;
  int? _yearId;
  int? _levelId;
  List<SchoolLevel> _levels = [];
  Set<String> _workingDays = {};
  List<LevelSubjectPeriod> _subjects = [];
  int _daysOffPerTeacher = 1;
  DayOffPreview? _dayOffPreview;
  TimetableGeneratorPreview? _preview;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialAcademicYearId;
    _loadLevels();
    if (_yearId != null) _loadWorkingDays();
  }

  Future<void> _loadLevels() async {
    final result = await ExamHallService().levels();
    if (!mounted) return;
    setState(() {
      if (result is HallSuccess<List<SchoolLevel>>) {
        _levels = result.data;
      } else {
        _error = (result as HallError).message;
      }
    });
  }

  Future<void> _loadWorkingDays() async {
    final yearId = _yearId;
    if (yearId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await TimetableGeneratorService().getWorkingDays(yearId);
    if (!mounted || _yearId != yearId) return;
    setState(() {
      _busy = false;
      if (result is GeneratorSuccess<List<String>>) {
        _workingDays = result.data.toSet();
      } else {
        _error = (result as GeneratorError).message;
      }
    });
  }

  Future<void> _saveWorkingDays() async {
    final yearId = _yearId;
    if (yearId == null) return;
    final selectedDays = _days
        .where(_workingDays.contains)
        .toList(growable: false);
    if (selectedDays.isEmpty) {
      setState(() => _error = 'Select at least one working day.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final saveResult = await TimetableGeneratorService().saveWorkingDays(
      yearId,
      selectedDays,
    );
    if (!mounted || _yearId != yearId) return;
    if (saveResult is GeneratorError) {
      setState(() {
        _busy = false;
        _error = saveResult.message;
      });
      return;
    }
    final reloadResult = await TimetableGeneratorService().getWorkingDays(
      yearId,
    );
    if (!mounted || _yearId != yearId) return;
    setState(() {
      _busy = false;
      if (reloadResult is GeneratorSuccess<List<String>>) {
        _workingDays = reloadResult.data.toSet();
        _error = null;
        _step = 2;
      } else {
        _error = (reloadResult as GeneratorError).message;
      }
    });
    if (reloadResult is GeneratorSuccess<List<String>>) {
      _toast('Working days saved successfully.');
    }
  }

  Future<void> _loadSubjects(int? levelId) async {
    setState(() {
      _levelId = levelId;
      _subjects = [];
      _preview = null;
      _dayOffPreview = null;
      _error = null;
    });
    if (levelId == null || _yearId == null) return;
    await _run(
      TimetableGeneratorService().getLevelSubjects(levelId, _yearId!),
      success: (value) => _subjects = value,
    );
  }

  Future<void> _saveSubjects() async {
    if (_yearId == null || _levelId == null) return;
    await _run(
      TimetableGeneratorService().saveLevelSubjects(
        _levelId!,
        _yearId!,
        _subjects,
      ),
      success: (_) {
        _step = 3;
        _toast('Weekly subject periods saved.');
      },
    );
  }

  Future<void> _previewDaysOff() async {
    if (_yearId == null || _levelId == null) return;
    await _run(
      TimetableGeneratorService().previewDayOffs(
        academicYearId: _yearId!,
        levelId: _levelId!,
        daysOffPerTeacher: _daysOffPerTeacher,
      ),
      success: (value) => _dayOffPreview = value,
    );
  }

  Future<void> _applyDaysOff() async {
    final apply = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apply Random Teacher Days Off?'),
        content: Text(
          'These weekly days off will be used by the timetable generator for ${_yearName()}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (apply != true || !mounted) return;
    await _run(
      TimetableGeneratorService().generateDayOffs(
        academicYearId: _yearId!,
        levelId: _levelId!,
        daysOffPerTeacher: _daysOffPerTeacher,
      ),
      success: (_) {
        _step = 4;
        _toast('Teacher days off applied.');
      },
    );
  }

  Future<void> _previewTimetable() async {
    if (_yearId == null || _levelId == null) return;
    await _run(
      TimetableGeneratorService().previewTimetable(
        academicYearId: _yearId!,
        levelId: _levelId!,
      ),
      success: (value) => _preview = value,
    );
  }

  Future<void> _generate({bool replace = false}) async {
    await _run(
      TimetableGeneratorService().generateTimetable(
        academicYearId: _yearId!,
        levelId: _levelId!,
        replaceExisting: replace,
      ),
      success: (_) {
        _toast('Timetable generated successfully.');
        Navigator.pop(context, true);
      },
      onError: (error) async {
        if (error.statusCode != 409) return false;
        final replaceApproved = await _confirmReplace();
        if (replaceApproved == true && mounted) {
          await _generate(replace: true);
        }
        return true;
      },
    );
  }

  Future<bool?> _confirmReplace() => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Timetable Already Exists'),
      content: Text(
        'A timetable already exists for ${_levelName()} in ${_yearName()}. Only timetable rows for this level and academic year will be replaced.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Replace Existing Timetable'),
        ),
      ],
    ),
  );

  Future<void> _run<T>(
    Future<GeneratorResult<T>> future, {
    required void Function(T value) success,
    Future<bool> Function(GeneratorError error)? onError,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await future;
    if (!mounted) return;
    if (result is GeneratorError) {
      final handled = onError == null ? false : await onError(result);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (!handled) _error = result.message;
      });
      return;
    }
    setState(() => _busy = false);
    success((result as GeneratorSuccess<T>).data);
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: _green));

  String _yearName() =>
      widget.years
          .where((year) => year.id == _yearId)
          .map((year) => year.name)
          .firstOrNull ??
      'the selected academic year';
  String _levelName() =>
      _levels
          .where((level) => level.id == _levelId)
          .map((level) => level.name)
          .firstOrNull ??
      'the selected level';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 820),
        child: FormCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _header(),
              _stepBar(),
              const Divider(height: 1, color: Color(0xFFE5EAF1)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _stepBody(),
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                  child: _notice(_error!, error: true),
                ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 18, 12, 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: _navy),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate Timetable',
                style: TextStyle(
                  color: _navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Configure, preview and generate one level at a time.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );

  Widget _stepBar() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: Row(
      children:
          ['Year', 'Working Days', 'Level Subjects', 'Days Off', 'Preview']
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: entry.key <= _step
                          ? _green
                          : Colors.grey.shade300,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    label: Text(entry.value),
                    backgroundColor: entry.key == _step
                        ? _navy.withValues(alpha: .08)
                        : Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              )
              .toList(),
    ),
  );

  Widget _stepBody() {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    switch (_step) {
      case 0:
        return _yearStep();
      case 1:
        return _workingDaysStep();
      case 2:
        return _subjectsStep();
      case 3:
        return _daysOffStep();
      default:
        return _previewStep();
    }
  }

  Widget _yearStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('Academic Year', 'Select the timetable’s academic-year scope.'),
      const SizedBox(height: 18),
      Select3D<int?>(
        value: widget.years.any((year) => year.id == _yearId) ? _yearId : null,
        label: 'Academic Year *',
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Select year')),
          ...widget.years.map(
            (year) => DropdownMenuItem<int?>(
              value: year.id,
              child: Text(year.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _yearId = value;
            _levelId = null;
            _subjects = [];
            _preview = null;
          });
          if (value != null) _loadWorkingDays();
        },
      ),
    ],
  );

  Widget _workingDaysStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('Working Days', 'Choose the exact weekdays used by the school.'),
      const SizedBox(height: 18),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: _days.map((day) {
          final selected = _workingDays.contains(day);
          return FilterChip(
            label: Text(day),
            selected: selected,
            selectedColor: _green.withValues(alpha: .16),
            checkmarkColor: _green,
            side: BorderSide(
              color: selected ? _green : const Color(0xFFDCE3EC),
            ),
            onSelected: (value) => setState(() {
              value ? _workingDays.add(day) : _workingDays.remove(day);
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),
      Text(
        '${_workingDays.length} working day${_workingDays.length == 1 ? '' : 's'} selected',
        style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
      ),
    ],
  );

  Widget _subjectsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Level & Weekly Subject Periods',
        'Configure each level independently.',
      ),
      const SizedBox(height: 16),
      Select3D<int?>(
        value: _levels.any((level) => level.id == _levelId) ? _levelId : null,
        label: 'Level *',
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Select level'),
          ),
          ..._levels.map(
            (level) => DropdownMenuItem<int?>(
              value: level.id,
              child: Text(level.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: _loadSubjects,
      ),
      const SizedBox(height: 16),
      if (_levelId != null && _subjects.isEmpty)
        _notice('No timetable subjects were returned for this level.'),
      ..._subjects.map(
        (subject) => Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subject.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: subject.periodsPerWeek == 0
                    ? null
                    : () => setState(() => subject.periodsPerWeek--),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${subject.periodsPerWeek}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => subject.periodsPerWeek++),
                icon: const Icon(Icons.add_circle_outline, color: _green),
              ),
            ],
          ),
        ),
      ),
      if (_subjects.isNotEmpty)
        Text(
          'Required periods/week: ${_subjects.fold<int>(0, (sum, item) => sum + item.periodsPerWeek)}',
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
    ],
  );

  Widget _daysOffStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Random Teacher Days Off',
        'Preview is read-only until you explicitly apply it.',
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        key: ValueKey(_daysOffPerTeacher),
        initialValue: _daysOffPerTeacher,
        isExpanded: true,
        decoration: _inputDecoration('Days Off Per Teacher Per Week'),
        items: List.generate(3, (index) => index + 1)
            .map(
              (value) => DropdownMenuItem(value: value, child: Text('$value')),
            )
            .toList(),
        onChanged: (value) => setState(() {
          _daysOffPerTeacher = value ?? 1;
          _dayOffPreview = null;
        }),
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: _previewDaysOff,
        icon: const Icon(Icons.shuffle_rounded),
        label: Text(
          _dayOffPreview == null
              ? 'Preview Random Days Off'
              : 'Randomize Again',
        ),
      ),
      if (_dayOffPreview != null) ...[
        const SizedBox(height: 14),
        ..._dayOffPreview!.teachers.map(_teacherDayOffRow),
        ..._dayOffPreview!.warnings.map(
          (warning) => _notice(warning, error: true),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _green),
          onPressed: _applyDaysOff,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Apply Teacher Days Off'),
        ),
      ],
    ],
  );

  Widget _previewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Timetable Preview',
        'The backend validates capacity, workload and collisions.',
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: _previewTimetable,
        icon: const Icon(Icons.visibility_rounded),
        label: Text(_preview == null ? 'Preview Timetable' : 'Refresh Preview'),
      ),
      if (_preview != null) ...[
        const SizedBox(height: 16),
        _summaryCard(),
        const SizedBox(height: 12),
        ..._preview!.issues.map((issue) => _notice(issue, error: true)),
        if (_preview!.issues.any(
              (issue) =>
                  issue.toLowerCase().contains('teacher') &&
                  issue.toLowerCase().contains('assign'),
            ) &&
            widget.onOpenCourseAssignments != null)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context, false);
              widget.onOpenCourseAssignments!();
            },
            icon: const Icon(Icons.assignment_ind_outlined),
            label: const Text('Go to Course Assign Teacher'),
          ),
        if (_preview!.rows.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Preview Rows',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ..._preview!.rows.take(30).map(_previewRow),
        ],
      ],
    ],
  );

  Widget _summaryCard() {
    final summary = _preview!.summary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _preview!.feasible
            ? _green.withValues(alpha: .08)
            : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _preview!.feasible ? _green : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _yearName(),
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          Text(_levelName(), style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          ...summary.entries.map(
            (entry) => Text('${_label(entry.key)}: ${entry.value}'),
          ),
          const SizedBox(height: 8),
          Text(
            _preview!.feasible
                ? 'Ready to Generate'
                : 'Configuration needs attention',
            style: TextStyle(
              color: _preview!.feasible ? _green : Colors.red.shade700,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherDayOffRow(Map<String, dynamic> row) {
    final teacher = row['teacher'] is Map ? row['teacher'] as Map : const {};
    final name =
        (row['teacher_name'] ??
                row['teacherName'] ??
                teacher['fullName'] ??
                teacher['name'] ??
                'Teacher')
            .toString();
    final rawDays =
        row['days'] ?? row['days_off'] ?? row['day_offs'] ?? row['day'];
    final days = rawDays is List
        ? rawDays.join(', ')
        : rawDays?.toString() ?? '';
    return _dataRow(name, days);
  }

  Widget _previewRow(Map<String, dynamic> row) {
    final title = [row['class_name'], row['subject_name']]
        .where((value) => value != null && value.toString().isNotEmpty)
        .join(' • ');
    final detail =
        [row['day'], row['period_name'] ?? row['period'], row['teacher_name']]
            .where((value) => value != null && value.toString().isNotEmpty)
            .join(' — ');
    return _dataRow(title.isEmpty ? 'Timetable entry' : title, detail);
  }

  Widget _dataRow(String title, String detail) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            detail,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _footer() {
    VoidCallback? primary;
    String label = 'Continue';
    if (_step == 0 && _yearId != null) {
      primary = () => setState(() => _step = 1);
    } else if (_step == 1 && _workingDays.isNotEmpty) {
      primary = _saveWorkingDays;
      label = 'Save Working Days';
    } else if (_step == 2 && _levelId != null && _subjects.isNotEmpty) {
      primary = _saveSubjects;
      label = 'Save Level Configuration';
    } else if (_step == 3) {
      label = _dayOffPreview == null
          ? 'Preview Days Off First'
          : 'Apply Days Off to Continue';
    } else if (_step == 4 && _preview?.feasible == true) {
      primary = _generate;
      label = 'Generate Timetable';
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5EAF1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _busy
                  ? null
                  : _step == 0
                  ? () => Navigator.pop(context)
                  : () => setState(() => _step--),
              child: Text(_step == 0 ? 'Cancel' : 'Back'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PrimaryButton3D(
              label: _busy && _step == 4 ? 'Generating timetable…' : label,
              onPressed: _busy ? null : primary,
              loading: _busy,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
    ],
  );

  Widget _notice(String message, {bool error = false}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFF1F2) : const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: error ? const Color(0xFFFECACA) : const Color(0xFFF4D58A),
      ),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: error ? const Color(0xFFB42318) : const Color(0xFF7A5200),
      ),
    ),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );

  String _label(Object key) => key
      .toString()
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
