import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  VoidCallback? onOpenTeacherDaysOff,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _TimetableGeneratorDialog(
    years: years,
    initialAcademicYearId: initialAcademicYearId,
    onOpenCourseAssignments: onOpenCourseAssignments,
    onOpenTeacherDaysOff: onOpenTeacherDaysOff,
  ),
);

class _TimetableGeneratorDialog extends StatefulWidget {
  final List<AcademicYear> years;
  final int? initialAcademicYearId;
  final VoidCallback? onOpenCourseAssignments;
  final VoidCallback? onOpenTeacherDaysOff;
  const _TimetableGeneratorDialog({
    required this.years,
    this.initialAcademicYearId,
    this.onOpenCourseAssignments,
    this.onOpenTeacherDaysOff,
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
  final _periodForm = GlobalKey<FormState>();
  final Map<int, TextEditingController> _periodInputs = {};
  TimetableGeneratorPreview? _preview;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _errorDetails = {};
  final Set<String> _expandedCapacitySubjects = {};

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
      _error = null;
    });
    if (levelId == null || _yearId == null) return;
    final yearId = _yearId!;
    await _run(
      TimetableGeneratorService().getLevelSubjects(levelId, yearId),
      success: (value) {
        // Discard if the level/year changed while this request was in flight,
        // so a slow response can never leak a previous level's subjects.
        if (_levelId != levelId || _yearId != yearId) return;
        for (final controller in _periodInputs.values) {
          controller.dispose();
        }
        _periodInputs.clear();
        _subjects = value;
        for (final subject in value) {
          _periodInputs[subject.subjectId] = TextEditingController(
            text: '${subject.periodsPerWeek}',
          );
        }
      },
    );
  }

  Future<void> _saveSubjects() async {
    if (_busy || _yearId == null || _levelId == null) return;
    if (_periodForm.currentState?.validate() != true) return;
    for (final subject in _subjects) {
      subject.periodsPerWeek = int.parse(
        _periodInputs[subject.subjectId]!.text,
      );
    }
    final levelId = _levelId!;
    final yearId = _yearId!;
    _preview = null;
    var saved = false;
    await _run(
      TimetableGeneratorService().saveLevelSubjects(levelId, yearId, _subjects),
      success: (_) {
        saved = true;
        _step = 3;
        _toast('Level timetable configuration saved.');
      },
    );
    // Reload from the backend so the level step reflects the persisted
    // configuration rather than only the locally-entered values.
    if (saved && mounted && _levelId == levelId && _yearId == yearId) {
      await _loadSubjects(levelId);
    }
  }

  Future<void> _previewTimetable() async {
    if (_busy || _yearId == null || _levelId == null) return;
    setState(() => _preview = null);
    await _run(
      TimetableGeneratorService().previewTimetable(
        academicYearId: _yearId!,
        levelId: _levelId!,
      ),
      success: (value) => _preview = value,
    );
  }

  Future<void> _generate({bool replace = false}) async {
    if (_preview?.canGenerate != true || _yearId == null || _levelId == null) {
      return;
    }
    TimetableGenerationResult? generated;
    await _run(
      TimetableGeneratorService().generateTimetable(
        academicYearId: _yearId!,
        levelId: _levelId!,
        replaceExisting: replace,
      ),
      success: (value) => generated = value,
      onError: (error) async {
        if (error.statusCode != 409) return false;
        final replaceApproved = await _confirmReplace();
        if (replaceApproved == true && mounted) {
          await _generate(replace: true);
        }
        return true;
      },
    );
    final result = generated;
    if (result == null || !mounted) return;
    if (result.unscheduled.isNotEmpty) {
      await _showGenerationResultDialog(result);
      if (!mounted) return;
    } else {
      _toast('Timetable generated successfully.');
    }
    Navigator.pop(context, true);
  }

  Future<void> _showGenerationResultDialog(
    TimetableGenerationResult result,
  ) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Timetable Generated',
                style: TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.totalScheduled} lesson${result.totalScheduled == 1 ? '' : 's'} scheduled',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (result.totalUnscheduled > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${result.totalUnscheduled} requested lesson${result.totalUnscheduled == 1 ? '' : 's'} could not fit',
                  style: const TextStyle(
                    color: Color(0xFF9A6700),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final summary in result.unscheduled)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF4D58A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.className.isEmpty
                                    ? 'Class'
                                    : summary.className,
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (summary.requested != null)
                                    Text('${summary.requested} requested'),
                                  if (summary.requested != null &&
                                      summary.scheduled != null)
                                    const Text('•'),
                                  if (summary.scheduled != null)
                                    Text('${summary.scheduled} scheduled'),
                                ],
                              ),
                              Text(
                                '${summary.unscheduled} unscheduled',
                                style: const TextStyle(
                                  color: Color(0xFF7A5200),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
      _errorDetails = {};
    });
    final result = await future;
    if (!mounted) return;
    if (result is GeneratorError) {
      final handled = onError == null ? false : await onError(result);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (!handled) {
          _error = result.message;
          _errorDetails = result.details;
        }
      });
      return;
    }
    setState(() {
      _busy = false;
      success((result as GeneratorSuccess<T>).data);
    });
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _stepBody(),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _notice(_error!, error: true),
                      ],
                    ],
                  ),
                ),
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

  Widget _stepBar() => LayoutBuilder(
    builder: (context, constraints) {
      const steps = [
        'Year',
        'Working Days',
        'Level Subjects',
        'Preview',
        'Generate',
      ];
      if (constraints.maxWidth < 600) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Row(
            children: [
              Text(
                'Step ' + (_step + 1).toString() + ' of 5',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  steps[_step],
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children:
              ['Year', 'Working Days', 'Level Subjects', 'Preview', 'Generate']
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
    },
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
        return _previewStep();
      default:
        return _generateStep();
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
      Form(
        key: _periodForm,
        child: Column(children: _subjects.map(_periodRow).toList()),
      ),
      if (_subjects.isNotEmpty)
        Text(
          'Total Required Periods: ${_periodInputs.values.fold<int>(0, (sum, input) => sum + (int.tryParse(input.text) ?? 0))}',
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
    ],
  );

  @override
  void dispose() {
    for (final controller in _periodInputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _periodRow(LevelSubjectPeriod subject) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final name = Text(
          subject.subjectName,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
        );
        final input = TextFormField(
          key: ValueKey('subject-periods-${subject.subjectId}'),
          controller: _periodInputs[subject.subjectId],
          keyboardType: TextInputType.number,
          inputFormatters: [
            TextInputFormatter.withFunction(
              (oldValue, newValue) =>
                  RegExp(r'^[0-9]*$').hasMatch(newValue.text)
                  ? newValue
                  : oldValue,
            ),
          ],
          validator: (value) =>
              int.tryParse(value ?? '') == null ? 'Enter a whole number' : null,
          onChanged: (_) => setState(() => _preview = null),
          decoration: _inputDecoration('Periods per week'),
        );
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [name, const SizedBox(height: 12), input],
          );
        }
        return Row(
          children: [
            Expanded(child: name),
            const SizedBox(width: 20),
            SizedBox(width: 180, child: input),
          ],
        );
      },
    ),
  );

  bool get _needsTeacherDaysOff =>
      timetableNeedsTeacherDaysOff(_preview?.raw ?? {}) ||
      timetableNeedsTeacherDaysOff(_errorDetails) ||
      timetableNeedsTeacherDaysOff({'message': _error ?? ''});

  Widget _dayOffNotice() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _notice('Teacher days off are not configured.'),
      if (widget.onOpenTeacherDaysOff != null)
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context, false);
            widget.onOpenTeacherDaysOff!();
          },
          icon: const Icon(Icons.event_busy_outlined),
          label: const Text('Manage Teacher Days Off'),
        ),
    ],
  );

  Widget _generateStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Generate Timetable',
        'Review the validated configuration before generating.',
      ),
      const SizedBox(height: 16),
      if (_preview != null) _summaryCard(),
    ],
  );

  Widget _previewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Timetable Preview',
        'Preview checks capacity and uses the separately saved teacher days off.',
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: _previewTimetable,
        icon: const Icon(Icons.visibility_rounded),
        label: Text(_preview == null ? 'Preview Timetable' : 'Refresh Preview'),
      ),
      if (_needsTeacherDaysOff) _dayOffNotice(),
      if (_preview != null) ...[
        const SizedBox(height: 16),
        _summaryCard(),
        const SizedBox(height: 12),
        if (_preview!.capacityIssues.isNotEmpty) _capacityIssuesSection(),
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
            'Preview Schedule',
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
    final canGenerate = _preview!.canGenerate;
    final hasWarnings = _preview!.capacityIssues.isNotEmpty;
    int? asInt(dynamic value) => value == null
        ? null
        : (value is num ? value.toInt() : int.tryParse(value.toString()));
    final required = asInt(
      summary['required_periods'] ??
          summary['requiredPeriods'] ??
          summary['required'],
    );
    final available = asInt(
      summary['available_periods'] ??
          summary['availablePeriods'] ??
          summary['available'],
    );
    final freeSlots =
        canGenerate && !hasWarnings && required != null && available != null
        ? available - required
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canGenerate
            ? _green.withValues(alpha: .08)
            : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: canGenerate ? _green : Colors.red.shade200),
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
            canGenerate
                ? 'Ready to Generate'
                : 'Timetable Cannot Be Generated Yet',
            style: TextStyle(
              color: canGenerate ? _green : Colors.red.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (canGenerate && hasWarnings) ...[
            const SizedBox(height: 2),
            const Text(
              'With capacity warnings',
              style: TextStyle(
                color: Color(0xFF9A6700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (freeSlots != null && freeSlots > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$freeSlots free timetable slot${freeSlots == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _capacityIssuesSection() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Capacity Warnings',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'These classes requested more weekly periods than they have '
          'physical timetable slots for. Generation can still proceed — '
          'each is scheduled up to its available capacity.',
          style: TextStyle(color: Color(0xFF7A5200)),
        ),
        const SizedBox(height: 10),
        for (final issue in _preview!.capacityIssues) _capacityIssueCard(issue),
      ],
    ),
  );

  Widget _capacityIssueCard(TimetableCapacityIssue issue) {
    final expanded = _expandedCapacitySubjects.contains(issue.className);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4D58A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue.className.isEmpty ? 'Class' : issue.className,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (issue.requested != null) Text('${issue.requested} requested'),
              if (issue.requested != null && issue.scheduled != null)
                const Text('•'),
              if (issue.scheduled != null) Text('${issue.scheduled} scheduled'),
            ],
          ),
          if (issue.unscheduled != null && issue.unscheduled! > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${issue.unscheduled} unscheduled',
              style: const TextStyle(
                color: Color(0xFF7A5200),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (issue.available != null) ...[
            const SizedBox(height: 4),
            Text('Available timetable slots: ${issue.available}'),
          ],
          const SizedBox(height: 6),
          Text(
            'Reason: ${issue.reasonText}',
            style: const TextStyle(color: Color(0xFF7A5200)),
          ),
          if (issue.subjectResults.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() {
                if (expanded) {
                  _expandedCapacitySubjects.remove(issue.className);
                } else {
                  _expandedCapacitySubjects.add(issue.className);
                }
              }),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Hide subject details' : 'Subject details',
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _navy,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: issue.subjectResults
                      .map(
                        (subject) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subject.subjectName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                [
                                  if (subject.requested != null)
                                    'Requested ${subject.requested}',
                                  if (subject.scheduled != null)
                                    'Scheduled ${subject.scheduled}',
                                  if (subject.hasUnscheduled)
                                    'Unscheduled ${subject.unscheduled}',
                                ].join(' • '),
                                style: TextStyle(
                                  color: subject.hasUnscheduled
                                      ? const Color(0xFF7A5200)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
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
    } else if (_step == 3 &&
        _preview?.canGenerate == true &&
        !_needsTeacherDaysOff) {
      primary = () => setState(() => _step = 4);
      label = 'Continue to Generate';
    } else if (_step == 4 && _preview?.canGenerate == true) {
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
            child: FilledButton(
              onPressed: _busy ? null : primary,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label, textAlign: TextAlign.center),
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
