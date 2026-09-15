import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:kobac/services/timetable_generator_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:provider/provider.dart';

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
  // Working days are shift-specific on the backend (Morning/Afternoon are
  // fully independent records) — this is the single source of truth for
  // both the shift selector and the outgoing GET/PUT requests.
  int? _shiftId;
  Set<String> _workingDays = {};
  String? _workingDaysShiftName;
  List<LevelSubjectPeriod> _subjects = [];
  final _periodForm = GlobalKey<FormState>();
  final Map<int, TextEditingController> _periodInputs = {};
  TimetableGeneratorPreview? _preview;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _errorDetails = {};
  int _scopeVersion = 0;
  int _daysRequest = 0;
  void _clearPeriods() {
    for (final controller in _periodInputs.values) {
      controller.dispose();
    }
    _periodInputs.clear();
    _subjects = [];
    _preview = null;
    _error = null;
    _errorDetails = {};
  }

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialAcademicYearId;
    _loadLevels();
    Future.microtask(() => context.read<ShiftsProvider>().ensureLoaded());
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

  /// Switching shift must never show the previous shift's days while the
  /// new one loads, so the visible selection is cleared up front — the
  /// admin sees a loading state, never stale Morning chips while Afternoon
  /// is being fetched.
  void _onShiftChanged(int? shiftId) {
    setState(() {
      _scopeVersion++;
      _preview = null;
      _errorDetails = {};
      _busy = false;
      _shiftId = shiftId;
      _workingDays = {};
      _workingDaysShiftName = null;
      _error = null;
    });
    if (shiftId != null && _yearId != null) _loadWorkingDays();
  }

  Future<void> _loadWorkingDays() async {
    final yearId = _yearId;
    final shiftId = _shiftId;
    final request = ++_daysRequest;
    if (yearId == null || shiftId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await TimetableGeneratorService().getWorkingDays(
      academicYearId: yearId,
      shiftId: shiftId,
    );
    // Discard if the year/shift changed while this request was in flight —
    // a slow response can never leak into the wrong shift's selection.
    if (!mounted ||
        request != _daysRequest ||
        _yearId != yearId ||
        _shiftId != shiftId)
      return;
    setState(() {
      _busy = false;
      if (result is GeneratorSuccess<WorkingDaysConfig> &&
          (result.data.shiftId == null || result.data.shiftId == shiftId) &&
          (result.data.academicYearId == null ||
              result.data.academicYearId == yearId)) {
        _workingDays = result.data.days.toSet();
        _workingDaysShiftName = result.data.shiftName;
      } else {
        _error = result is GeneratorError
            ? result.message
            : 'Working days do not match this shift and year.';
      }
    });
  }

  Future<void> _saveWorkingDays() async {
    if (_busy) return;
    final scope = _scopeVersion;
    final yearId = _yearId;
    final shiftId = _shiftId;
    if (yearId == null || shiftId == null) return;
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
      academicYearId: yearId,
      shiftId: shiftId,
      days: selectedDays,
    );
    if (!mounted || scope != _scopeVersion) return;
    if (saveResult is GeneratorError) {
      setState(() {
        _busy = false;
        _error = saveResult.message;
      });
      return;
    }
    final reloadResult = await TimetableGeneratorService().getWorkingDays(
      academicYearId: yearId,
      shiftId: shiftId,
    );
    if (!mounted || scope != _scopeVersion) return;
    final validReload =
        reloadResult is GeneratorSuccess<WorkingDaysConfig> &&
        (reloadResult.data.shiftId == null ||
            reloadResult.data.shiftId == shiftId) &&
        (reloadResult.data.academicYearId == null ||
            reloadResult.data.academicYearId == yearId);
    setState(() {
      _busy = false;
      if (validReload) {
        _workingDays = reloadResult.data.days.toSet();
        _workingDaysShiftName = reloadResult.data.shiftName;
        _error = null;
        _step = 2;
      } else {
        _workingDays = {};
        _workingDaysShiftName = null;
        _error = reloadResult is GeneratorError
            ? reloadResult.message
            : 'Working days do not match this shift and year.';
      }
    });
    if (validReload) {
      _toast('Working days saved successfully.');
    }
  }

  Future<void> _loadSubjects(int? levelId) async {
    setState(() {
      _scopeVersion++;
      _clearPeriods();
      _busy = false;
      _levelId = levelId;
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
          // This wizard is always a NEW generation session — never an edit
          // screen — so every field starts genuinely empty regardless of
          // whatever periods_per_week the backend may have saved from a
          // previous session. The admin must retype every value here; nothing
          // is ever bound from `subject.periodsPerWeek`, a cache, or any
          // other prior state.
          _periodInputs[subject.subjectId] = TextEditingController();
          if (kDebugMode) {
            debugPrint(
              '[LevelSubjectsInit] ${subject.subjectName} -> '
              '"${_periodInputs[subject.subjectId]!.text}"',
            );
          }
        }
      },
    );
  }

  Future<void> _saveSubjects() async {
    if (_busy || _yearId == null || _levelId == null) return;
    final hasBlankField = _subjects.any(
      (subject) =>
          (_periodInputs[subject.subjectId]?.text.trim() ?? '').isEmpty,
    );
    if (hasBlankField) {
      setState(() => _error = 'Enter periods per week for every subject.');
      return;
    }
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
    if (saved && mounted && _levelId == levelId && _yearId == yearId) {
      await _previewTimetable();
    }
  }

  /// Step 3's Continue/Save button is gated purely on locally-visible field
  /// state — never on preview/readiness/capacity/teacher-assignment data,
  /// which belong to the Preview step. Every displayed subject must have a
  /// non-blank, valid, non-negative whole number.
  bool get _allSubjectFieldsValid =>
      _subjects.isNotEmpty &&
      _subjects.every((subject) {
        final text = _periodInputs[subject.subjectId]?.text.trim() ?? '';
        if (!RegExp(r'^\d+$').hasMatch(text)) return false;
        final value = int.tryParse(text);
        return value != null && value >= 0;
      });

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
        // A capacity/assignment rejection must never become a replace bypass.
        final alreadyExists =
            error.statusCode == 409 &&
            error.message.toLowerCase().contains('already exist');
        if (!alreadyExists || replace) {
          _preview = null;
          _step = 3;
          return false;
        }
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
      setState(() {
        _preview = null;
        _step = 3;
        _error =
            'The backend returned an incomplete timetable. Refresh the preview and review the configuration.';
      });
      return;
    }
    _toast('Timetable generated successfully.');
    Navigator.pop(context, true);
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
    final scope = _scopeVersion;
    setState(() {
      _busy = true;
      _error = null;
      _errorDetails = {};
    });
    final result = await future;
    if (!mounted || scope != _scopeVersion) return;
    if (result is GeneratorError) {
      final handled = onError == null ? false : await onError(result);
      if (!mounted || scope != _scopeVersion) return;
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

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: _green));
  }

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
            _scopeVersion++;
            _daysRequest++;
            _clearPeriods();
            _busy = false;
            _shiftId = null;
            _yearId = value;
            _levelId = null;
            _subjects = [];
            _preview = null;
            _workingDays = {};
            _workingDaysShiftName = null;
          });
        },
      ),
    ],
  );

  Widget _workingDaysStep() {
    final shiftsProvider = context.watch<ShiftsProvider>();
    final shifts = shiftsProvider.shifts;
    final shiftsLoading = shiftsProvider.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          'Working Days',
          'Each shift has its own independent working days.',
        ),
        const SizedBox(height: 18),
        Select3D<int?>(
          value: shifts.any((s) => s.id == _shiftId) ? _shiftId : null,
          label: shiftsLoading ? 'Loading shifts...' : 'Shift *',
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Select shift'),
            ),
            ...shifts.map(
              (shift) => DropdownMenuItem<int?>(
                value: shift.id,
                child: Text(shift.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: _busy ? null : _onShiftChanged,
        ),
        const SizedBox(height: 18),
        if (_shiftId == null)
          _notice('Select a shift to view and configure its working days.')
        else ...[
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
            '${_workingDays.length} working day${_workingDays.length == 1 ? '' : 's'} selected'
            '${_workingDaysShiftName != null ? ' for $_workingDaysShiftName' : ''}',
            style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }

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
          'Each class must exactly fill its weekly timetable before generation.',
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
          onChanged: (_) => setState(() {
            // Editing after a preview always invalidates it — a fresh
            // Review is required before Generate. Clearing the stale
            // blank/save-error notice here too means it disappears the
            // moment the admin starts fixing the field it was about, not
            // only after the next full save attempt.
            _preview = null;
            _error = null;
          }),
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
      if (_preview != null) _classReadinessSection(),
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
        if (_preview!.hasReadinessContract) ...[
          _classReadinessSection(),
          if (_preview!.classResults.any(
                (c) => c.missingTeacherAssignments.isNotEmpty,
              ) &&
              widget.onOpenCourseAssignments != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context, false);
                widget.onOpenCourseAssignments!();
              },
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Go to Course Assign Teacher'),
            ),
          ],
        ] else ...[
          _notice(
            'The backend has not returned complete per-class readiness. Refresh the preview before generating.',
            error: true,
          ),
        ],
        ..._preview!.issues.map((issue) => _notice(issue, error: true)),
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

  /// The new complete-timetable-mode per-class readiness view — one card
  /// per class with its requested/available/difference/status, plus any
  /// missing period requirements or teacher assignments for that class.
  /// Never locally recomputes readiness: every field comes straight from
  /// the backend's per-class diagnostic. Both under-allocation and
  /// over-allocation block generation.
  Widget _classReadinessSection() {
    final (String banner, Color bannerColor) = _preview!.canGenerate
        ? ('All classes are ready to generate.', _green)
        : (
            'Each class must exactly fill its weekly timetable. Fix the blocking issues before generating.',
            const Color(0xFFB42318),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          banner,
          style: TextStyle(
            color: bannerColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        for (final result in _preview!.classResults)
          _classReadinessCard(result),
      ],
    );
  }

  Widget _classReadinessCard(TimetableClassReadiness result) {
    const amberBg = Color(0xFFFFF8E8);
    const amberBorder = Color(0xFFF4D58A);
    const amberText = Color(0xFF9A6700);
    // Distinct colors identify the correction needed; both states block.
    const orangeBg = Color(0xFFFFF6ED);
    const orangeBorder = Color(0xFFFED29B);
    const orangeText = Color(0xFFB54708);
    const redBg = Color(0xFFFFF1F2);
    const redBorder = Color(0xFFFECACA);
    const redText = Color(0xFFB42318);
    final (Color bg, Color border, Color text, String label) =
        result.missingRequirements.isNotEmpty ||
            result.missingTeacherAssignments.isNotEmpty ||
            (result.isBlocking && !result.isCapacityWarning)
        ? (redBg, redBorder, redText, 'BLOCKED')
        : switch (result.status) {
            TimetableClassStatus.complete => (
              _green.withValues(alpha: .08),
              _green,
              _green,
              'COMPLETE',
            ),
            TimetableClassStatus.underAllocated => (
              amberBg,
              amberBorder,
              amberText,
              'UNDER ALLOCATED',
            ),
            TimetableClassStatus.overAllocated => (
              orangeBg,
              orangeBorder,
              orangeText,
              'OVER ALLOCATED',
            ),
            _ => (amberBg, amberBorder, amberText, 'PENDING'),
          };
    String? statusMessage = result.message;
    final difference = result.difference;
    if (difference != null && difference > 0) {
      statusMessage =
          'Add ' +
          difference.toString() +
          ' more periods to fill this class timetable.';
    } else if (difference != null && difference < 0) {
      statusMessage =
          'Reduce the configured periods by ' + (-difference).toString() + '.';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.className.isEmpty ? 'Class' : result.className,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: text.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (result.requestedPeriods != null)
                Text('Requested Periods: ${result.requestedPeriods}'),
              if (result.availableSlots != null)
                Text('Available Slots: ${result.availableSlots}'),
              if (result.difference != null)
                Text('Difference: ${result.difference}'),
            ],
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 6),
            Text(statusMessage, style: TextStyle(color: text)),
          ],
          if (result.missingRequirements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Missing Period Requirements',
              style: TextStyle(color: redText, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            for (final subject in result.missingRequirements)
              Text('• $subject', style: const TextStyle(color: redText)),
          ],
          if (result.missingTeacherAssignments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Teacher Assignment Required',
              style: TextStyle(color: redText, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            for (final message in result.missingTeacherAssignments)
              Text('• $message', style: const TextStyle(color: redText)),
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
    if (kDebugMode && _step == 2) {
      final filled = _subjects
          .where(
            (s) =>
                int.tryParse(_periodInputs[s.subjectId]?.text.trim() ?? '') !=
                null,
          )
          .length;
      debugPrint(
        '[LevelSubjectsContinue] subjects=${_subjects.length} '
        'filled=$filled allValid=$_allSubjectFieldsValid '
        'isSaving=$_busy '
        'canContinue=${!_busy && _levelId != null && _allSubjectFieldsValid}',
      );
    }
    VoidCallback? primary;
    String label = _step == 2
        ? 'Save Level Configuration'
        : _step == 4
        ? 'Generate Timetable'
        : 'Continue';
    if (_step == 0 && _yearId != null) {
      primary = () => setState(() => _step = 1);
    } else if (_step == 1 && _shiftId != null && _workingDays.isNotEmpty) {
      primary = _saveWorkingDays;
      label = 'Save Working Days';
    } else if (_step == 2 &&
        _yearId != null &&
        _levelId != null &&
        _allSubjectFieldsValid) {
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
              child: Text(
                _step == 0
                    ? 'Cancel'
                    : _step == 3
                    ? 'Back to Fix'
                    : 'Back',
              ),
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
}
