import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/timetable_generator_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const _navy = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _amberBg = Color(0xFFFFF8E8);
const _amberBorder = Color(0xFFF4D58A);
const _amberText = Color(0xFF9A6700);
const _redBg = Color(0xFFFFF1F2);
const _redBorder = Color(0xFFFECACA);
const _redText = Color(0xFFB42318);
const _grayBg = Color(0xFFF3F4F6);
const _grayBorder = Color(0xFFE2E8F0);
const _grayText = Color(0xFF64748B);

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<dynamic> _asList(dynamic value) => value is List ? value : const [];

/// Class-configured, school-wide timetable generation — the primary
/// automatic-generation entry point, replacing the old level-based wizard.
/// Every class configures its own weekly subject-period requirements
/// (derived only from that class's own class_subjects); capacity comes
/// entirely from the backend (that class's own shift working days and
/// periods); the whole school is solved together in one generation run.
/// Levels are not used here at all — they remain elsewhere for
/// organization, filtering and reporting only.
Future<bool?> showSchoolTimetableGeneratorDialog(
  BuildContext context, {
  required List<AcademicYear> years,
  int? initialAcademicYearId,
  VoidCallback? onOpenCourseAssignments,
  VoidCallback? onOpenTeacherDaysOff,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _SchoolTimetableGeneratorDialog(
    years: years,
    initialAcademicYearId: initialAcademicYearId,
    onOpenCourseAssignments: onOpenCourseAssignments,
    onOpenTeacherDaysOff: onOpenTeacherDaysOff,
  ),
);

String _statusLabel(TimetableClassStatus? status) => switch (status) {
  TimetableClassStatus.complete => 'READY',
  TimetableClassStatus.underAllocated => 'UNDER ALLOCATED',
  TimetableClassStatus.overAllocated => 'OVER ALLOCATED',
  TimetableClassStatus.notConfigured => 'NOT CONFIGURED',
  _ => 'NOT CONFIGURED',
};

// Per the final permissive backend policy, UNDER_ALLOCATED and
// OVER_ALLOCATED are both ordinary warnings — never blockers — so both use
// the same amber warning styling. Red is reserved for a genuine hard block
// (backend can_generate == false) or a real server/network error, never for
// an informational per-class status.
(Color, Color, Color) _statusColors(TimetableClassStatus? status) =>
    switch (status) {
      TimetableClassStatus.complete => (
        _green.withValues(alpha: .08),
        _green,
        _green,
      ),
      TimetableClassStatus.underAllocated ||
      TimetableClassStatus.overAllocated => (
        _amberBg,
        _amberBorder,
        _amberText,
      ),
      _ => (_grayBg, _grayBorder, _grayText),
    };

class _SchoolTimetableGeneratorDialog extends StatefulWidget {
  final List<AcademicYear> years;
  final int? initialAcademicYearId;
  final VoidCallback? onOpenCourseAssignments;
  final VoidCallback? onOpenTeacherDaysOff;

  const _SchoolTimetableGeneratorDialog({
    required this.years,
    this.initialAcademicYearId,
    this.onOpenCourseAssignments,
    this.onOpenTeacherDaysOff,
  });

  @override
  State<_SchoolTimetableGeneratorDialog> createState() =>
      _SchoolTimetableGeneratorDialogState();
}

class _SchoolTimetableGeneratorDialogState
    extends State<_SchoolTimetableGeneratorDialog> {
  int _step = 0;
  int? _yearId;
  int _scopeVersion = 0;
  bool _busy = false;
  bool _generating = false;
  String? _error;

  List<ClassTimetableSummary> _classes = [];
  SchoolTimetablePreview? _preview;

  String _quickFilter = 'all';
  int? _levelFilter;
  int? _shiftFilter;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialAcademicYearId;
    if (_yearId != null) _loadYearScope();
  }

  String _yearName(int? id) =>
      widget.years.where((y) => y.id == id).map((y) => y.name).firstOrNull ??
      'the selected academic year';

  List<(int, String)> get _shiftsInScope {
    final seen = <int>{};
    final result = <(int, String)>[];
    for (final klass in _classes) {
      final id = klass.shiftId;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      result.add((id, klass.shiftName ?? 'Shift $id'));
    }
    result.sort((a, b) => a.$1.compareTo(b.$1));
    return result;
  }

  List<(int, String)> get _levelsInScope {
    final seen = <int>{};
    final result = <(int, String)>[];
    for (final klass in _classes) {
      final id = klass.levelId;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      result.add((id, klass.levelName ?? 'Level $id'));
    }
    result.sort((a, b) => a.$2.compareTo(b.$2));
    return result;
  }

  Future<void> _loadYearScope() async {
    final yearId = _yearId;
    if (yearId == null) return;
    final scope = ++_scopeVersion;
    setState(() {
      _busy = true;
      _error = null;
      _classes = [];
      _preview = null;
      _quickFilter = 'all';
      _levelFilter = null;
      _shiftFilter = null;
    });
    if (kDebugMode) {
      debugPrint('[TIMETABLE] _loadYearScope calling getClassSummaries '
          'for academicYearId=$yearId');
    }
    final result = await TimetableGeneratorService().getClassSummaries(
      academicYearId: yearId,
    );
    if (kDebugMode) {
      debugPrint(
        '[TIMETABLE] _loadYearScope result: '
        '${result is GeneratorSuccess<List<ClassTimetableSummary>> ? 'SUCCESS with ${result.data.length} class(es)' : 'ERROR: ${(result as GeneratorError).message}'}',
      );
    }
    if (!mounted || scope != _scopeVersion) return;
    setState(() {
      _busy = false;
      if (result is GeneratorSuccess<List<ClassTimetableSummary>>) {
        _classes = result.data;
      } else {
        _error = (result as GeneratorError).message;
      }
    });
  }

  Future<void> _loadClassSummaries() async {
    final yearId = _yearId;
    if (yearId == null) return;
    final scope = _scopeVersion;
    if (kDebugMode) {
      debugPrint('[TIMETABLE] _loadClassSummaries calling getClassSummaries '
          'for academicYearId=$yearId');
    }
    final result = await TimetableGeneratorService().getClassSummaries(
      academicYearId: yearId,
    );
    if (kDebugMode) {
      debugPrint(
        '[TIMETABLE] _loadClassSummaries result: '
        '${result is GeneratorSuccess<List<ClassTimetableSummary>> ? 'SUCCESS with ${result.data.length} class(es)' : 'ERROR: ${(result as GeneratorError).message}'}',
      );
    }
    if (!mounted || scope != _scopeVersion) return;
    setState(() {
      if (result is GeneratorSuccess<List<ClassTimetableSummary>>) {
        _classes = result.data;
      }
    });
  }

  Future<void> _refreshPreview({bool silent = false}) async {
    final yearId = _yearId;
    if (yearId == null) return;
    final scope = _scopeVersion;
    if (!silent) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    final result = await TimetableGeneratorService().previewSchoolTimetable(
      academicYearId: yearId,
    );
    if (!mounted || scope != _scopeVersion) return;
    setState(() {
      _busy = false;
      if (result is GeneratorSuccess<SchoolTimetablePreview>) {
        _preview = result.data;
      } else {
        _error = (result as GeneratorError).message;
      }
    });
  }

  Future<void> _openClassEditor(int classId, String className) async {
    final yearId = _yearId;
    if (yearId == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ClassSubjectEditorDialog(
        classId: classId,
        className: className,
        academicYearId: yearId,
      ),
    );
    if (saved == true && mounted) {
      await _loadClassSummaries();
      if (_preview != null) await _refreshPreview(silent: true);
    }
  }

  List<ClassTimetableSummary> get _filteredClasses {
    return _classes.where((klass) {
      if (_levelFilter != null && klass.levelId != _levelFilter) return false;
      if (_shiftFilter != null && klass.shiftId != _shiftFilter) return false;
      if (_quickFilter == 'ready' &&
          klass.status != TimetableClassStatus.complete) {
        return false;
      }
      if (_quickFilter == 'needs' &&
          klass.status == TimetableClassStatus.complete) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _readyCount => _classes
      .where((c) => c.status == TimetableClassStatus.complete)
      .length;

  // Single source of truth for whether Generate may proceed: the backend's
  // own `can_generate` flag. Warnings (under/over-allocation, missing
  // requirements/teachers, unscheduled lessons) never disable this.
  bool get _generateReady => _preview?.canGenerate == true;

  /// Only populated when the backend has genuinely blocked generation
  /// (`can_generate == false`) — a real reason, never invented locally
  /// from warning-only conditions like capacity mismatches.
  String? get _generateBlockedReason {
    final preview = _preview;
    if (preview == null) {
      return 'Run the school review to check whether this school can be generated.';
    }
    if (preview.canGenerate) return null;
    if (preview.errors.isNotEmpty) {
      return preview.errors.join(' ');
    }
    if (!preview.feasible) {
      return 'The backend reports no feasible timetable was found for this school yet.';
    }
    return 'The backend has not marked this school ready to generate yet.';
  }

  /// A short, non-blocking summary of warnings for when generation IS
  /// allowed but some classes still have capacity/requirement/teacher/
  /// unscheduled-lesson warnings — purely informational.
  String? get _generateWarningSummary {
    final preview = _preview;
    if (preview == null || !preview.canGenerate || !preview.hasWarnings) {
      return null;
    }
    final parts = <String>[];
    final unscheduled = preview.totalUnscheduled ?? 0;
    if (unscheduled > 0) {
      parts.add(
        '$unscheduled requested lesson${unscheduled == 1 ? '' : 's'} may remain unscheduled',
      );
    }
    final warningClasses = preview.classes
        .where(
          (c) =>
              c.status == TimetableClassStatus.underAllocated ||
              c.status == TimetableClassStatus.overAllocated ||
              c.missingRequirements.isNotEmpty ||
              c.missingTeacherAssignments.isNotEmpty,
        )
        .length;
    if (warningClasses > 0) {
      parts.add(
        '$warningClasses class${warningClasses == 1 ? '' : 'es'} have configuration warnings',
      );
    }
    if (parts.isEmpty) return 'Some warnings were reported by the backend.';
    return '${parts.join(' and ')}. You can still generate now.';
  }

  Future<void> _onTapGenerate() async {
    final preview = _preview;
    if (preview == null || !preview.canGenerate) return;
    if (preview.hasWarnings) {
      final confirmed = await _confirmGenerateWithWarnings();
      if (confirmed != true) return;
    }
    if (!mounted) return;
    await _generate();
  }

  Future<bool?> _confirmGenerateWithWarnings() => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Generate timetable with warnings?'),
      content: const Text(
        'Some timetable slots may remain FREE and some requested lessons '
        'may remain unscheduled. No teacher or class conflicts will be '
        'created. You can review and adjust the configuration afterwards.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _amberText),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Generate Anyway'),
        ),
      ],
    ),
  );

  Future<void> _generate({bool replace = false}) async {
    final yearId = _yearId;
    if (yearId == null || !_generateReady) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    final result = await TimetableGeneratorService().generateSchoolTimetable(
      academicYearId: yearId,
      replaceExisting: replace,
    );
    if (!mounted) return;
    if (result is GeneratorError) {
      final topCode = result.details['code']?.toString().toUpperCase();
      final nestedCode = _asMap(
        result.details['data'],
      )['code']?.toString().toUpperCase();
      final isTimetableExists =
          result.statusCode == 409 &&
          (topCode == 'TIMETABLE_EXISTS' || nestedCode == 'TIMETABLE_EXISTS');
      if (isTimetableExists && !replace) {
        setState(() => _generating = false);
        final confirmed = await _confirmReplace();
        if (confirmed == true && mounted) {
          await _generate(replace: true);
        }
        return;
      }
      final errorList = _asList(result.details['errors'])
          .map((e) => e is Map ? _asMap(e)['message']?.toString() : e.toString())
          .whereType<String>()
          .where((e) => e.trim().isNotEmpty)
          .toList();
      setState(() {
        _generating = false;
        _error = errorList.isEmpty
            ? result.message
            : '${result.message}\n${errorList.map((e) => '• $e').join('\n')}';
      });
      return;
    }
    final generated = (result as GeneratorSuccess<SchoolGenerationResult>).data;
    setState(() => _generating = false);
    await _showGenerationResultDialog(generated);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<bool?> _confirmReplace() => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Replace existing timetable?'),
      content: Text(
        'A timetable already exists for ${_yearName(_yearId)}. Generate a '
        'new timetable and replace the existing one? Class configuration, '
        'teacher assignments, teacher days off, and working days all remain '
        'unchanged.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _green),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Replace & Generate'),
        ),
      ],
    ),
  );

  Future<void> _showGenerationResultDialog(SchoolGenerationResult result) =>
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
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
                  const SizedBox(height: 12),
                  if (result.generatedRows != null)
                    Text(
                      '${result.generatedRows} lesson${result.generatedRows == 1 ? '' : 's'} scheduled${result.generatedCount != null ? ' across ${result.generatedCount} class${result.generatedCount == 1 ? '' : 'es'}' : ''}.',
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // A successful generation can still leave requested
                  // lessons unscheduled and slots FREE under the
                  // permissive backend policy — this is still SUCCESS,
                  // never rendered as a failure.
                  if (result.hasUnscheduled) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${result.unscheduledRows} requested lesson${result.unscheduledRows == 1 ? '' : 's'} could not be placed.',
                        style: const TextStyle(
                          color: _amberText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Some slots may remain free.',
                        style: TextStyle(
                          color: _amberText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'No FREE periods.',
                        style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            minimumSize: const Size(0, 46),
                          ),
                          child: const Text('View Timetable'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 820),
        child: FormCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _header(),
              _stepBar(),
              const Divider(height: 1, color: Color(0xFFE5EAF1)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(color: _green),
                          ),
                        )
                      else
                        _stepBody(),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
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
    padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: _navy),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate School Timetable',
                style: TextStyle(
                  color: _navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Configure classes, review capacity and generate the complete weekly timetable.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: (_busy || _generating)
              ? null
              : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );

  Widget _stepBar() {
    const steps = [
      'Academic Year & Working Days',
      'Configure Classes',
      'Review School',
      'Generate',
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Row(
              children: [
                Text(
                  'Step ${_step + 1} of ${steps.length}',
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[_step],
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: steps
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: CircleAvatar(
                        backgroundColor: entry.key <= _step
                            ? _green
                            : Colors.grey.shade300,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      label: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 12),
                      ),
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
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _yearAndWorkingDaysStep();
      case 1:
        return _configureClassesStep();
      case 2:
        return _reviewSchoolStep();
      default:
        return _generateStep();
    }
  }

  Widget _title(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      ),
    ],
  );

  Widget _yearAndWorkingDaysStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Academic Year & Working Days',
        'Select the academic year, then confirm each shift\'s weekly working days.',
      ),
      const SizedBox(height: 14),
      Select3D<int?>(
        value: widget.years.any((y) => y.id == _yearId) ? _yearId : null,
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
            _classes = [];
            _preview = null;
            _error = null;
          });
          if (value != null) _loadYearScope();
        },
      ),
      if (_yearId != null) ...[
        const SizedBox(height: 18),
        const Text(
          'Working Days',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        // Only claim "no classes" when the load actually succeeded with a
        // genuinely empty list — never alongside a real load error, which
        // gets its own banner from `_error` below.
        if (_shiftsInScope.isEmpty && _error == null)
          _notice('No classes found for this academic year yet.')
        else if (_shiftsInScope.isEmpty)
          const SizedBox.shrink()
        else
          for (final shift in _shiftsInScope)
            _ShiftWorkingDaysCard(
              key: ValueKey('$_yearId-${shift.$1}'),
              academicYearId: _yearId!,
              shiftId: shift.$1,
              shiftName: shift.$2,
              onSaved: _loadClassSummaries,
            ),
        if (widget.onOpenTeacherDaysOff != null) ...[
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: widget.onOpenTeacherDaysOff,
            icon: const Icon(Icons.event_busy_outlined, size: 18),
            label: const Text('Manage Teacher Day Offs'),
          ),
        ],
      ],
    ],
  );

  Widget _statTile(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _filterChip(String label, String value) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    visualDensity: VisualDensity.compact,
    selected: _quickFilter == value,
    selectedColor: _green.withValues(alpha: .16),
    onSelected: (_) => setState(() => _quickFilter = value),
  );

  Widget _configureClassesStep() {
    final filtered = _filteredClasses;
    final needsCount = _classes.length - _readyCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          'Configure Classes',
          'Set each class\'s own weekly subject periods, in any order.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statTile('${_classes.length}', 'Classes', _navy),
            _statTile('$_readyCount', 'Ready', _green),
            _statTile('$needsCount', 'Need Configuration', _amberText),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _filterChip('All', 'all'),
            _filterChip('Ready', 'ready'),
            _filterChip('Needs Configuration', 'needs'),
            if (_levelsInScope.isNotEmpty)
              SizedBox(
                width: 150,
                child: Select3D<int?>(
                  value: _levelFilter,
                  label: 'Level',
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All levels'),
                    ),
                    ..._levelsInScope.map(
                      (level) => DropdownMenuItem<int?>(
                        value: level.$1,
                        child: Text(level.$2, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _levelFilter = value),
                ),
              ),
            if (_shiftsInScope.isNotEmpty)
              SizedBox(
                width: 150,
                child: Select3D<int?>(
                  value: _shiftFilter,
                  label: 'Shift',
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All shifts'),
                    ),
                    ..._shiftsInScope.map(
                      (shift) => DropdownMenuItem<int?>(
                        value: shift.$1,
                        child: Text(shift.$2, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _shiftFilter = value),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty && _error == null)
          _notice(
            _classes.isEmpty
                ? 'No classes found for this academic year yet.'
                : 'No classes match the current filters.',
          )
        else if (filtered.isEmpty)
          const SizedBox.shrink()
        else
          for (final klass in filtered) _classRow(klass),
      ],
    );
  }

  Widget _classRow(ClassTimetableSummary klass) {
    final (bg, border, text) = _statusColors(klass.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      klass.className,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: text.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(klass.status),
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 2,
                children: [
                  if (klass.shiftName != null)
                    Text(
                      klass.shiftName!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  if (klass.subjectCount != null)
                    Text(
                      '${klass.subjectCount} Subject${klass.subjectCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  if (klass.availableSlots != null)
                    Text(
                      '${klass.availableSlots} Weekly Slots',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Configured: ${klass.configuredPeriods ?? 0}${klass.availableSlots != null ? ' / ${klass.availableSlots}' : ''}',
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (klass.status == TimetableClassStatus.underAllocated &&
                  klass.availableSlots != null)
                Text(
                  '${klass.availableSlots! - (klass.configuredPeriods ?? 0)} slots may remain free',
                  style: const TextStyle(color: _amberText, fontSize: 12),
                )
              else if (klass.status == TimetableClassStatus.overAllocated &&
                  klass.availableSlots != null)
                Text(
                  '${(klass.configuredPeriods ?? 0) - klass.availableSlots!} periods over capacity',
                  style: const TextStyle(color: _amberText, fontSize: 12),
                ),
            ],
          );
          final button = OutlinedButton(
            onPressed: _busy
                ? null
                : () => _openClassEditor(klass.classId, klass.className),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              klass.status == null ||
                      klass.status == TimetableClassStatus.notConfigured
                  ? 'Configure'
                  : 'Edit',
            ),
          );
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 8), button],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }

  /// Whether a class deserves a card in the Warnings list — any status
  /// other than READY/COMPLETE, a missing requirement/teacher, or lessons
  /// the solver couldn't place even though the class itself looks
  /// COMPLETE (e.g. a teacher-time conflict). A class with none of these
  /// simply doesn't appear — it needs no attention.
  bool _hasWarning(TimetableClassReadiness c) =>
      c.status != TimetableClassStatus.complete ||
      c.missingRequirements.isNotEmpty ||
      c.missingTeacherAssignments.isNotEmpty ||
      (c.effectiveUnscheduled ?? 0) > 0;

  Widget _reviewSchoolStep() {
    final preview = _preview;
    final results = preview?.classes ?? const [];
    final warningResults = results.where(_hasWarning).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          'Review School',
          'Fresh backend readiness for every class — the source of truth for generation.',
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _refreshPreview(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh Review'),
        ),
        const SizedBox(height: 12),
        if (preview != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statTile('${results.length}', 'Classes', _navy),
              if (preview.totalRequested != null)
                _statTile('${preview.totalRequested}', 'Requested', _navy),
              if (preview.totalScheduled != null)
                _statTile('${preview.totalScheduled}', 'Scheduled', _green),
              if (preview.totalUnscheduled != null)
                _statTile(
                  '${preview.totalUnscheduled}',
                  'Unscheduled',
                  (preview.totalUnscheduled ?? 0) > 0 ? _amberText : _green,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Red is reserved for a genuine backend block (can_generate ==
          // false) or an explicit top-level error — never for ordinary
          // capacity/requirement/teacher/unscheduled warnings, which stay
          // amber and never disable Continue.
          if (!preview.canGenerate && preview.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _notice(preview.errors.join('\n'), error: true),
            ),
          Text(
            !preview.canGenerate
                ? (_generateBlockedReason ??
                      'The backend has not marked this school ready to generate yet.')
                : preview.hasWarnings
                ? (_generateWarningSummary ??
                      'Ready to generate, with some warnings below.')
                : 'All classes are ready — the whole school can be generated with no warnings.',
            style: TextStyle(
              color: !preview.canGenerate
                  ? _redText
                  : preview.hasWarnings
                  ? _amberText
                  : _green,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          if (warningResults.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Warnings',
              style: TextStyle(
                color: _navy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (final result in warningResults) _reviewClassCard(result),
          ],
        ] else
          _notice('Preview has not loaded yet.'),
      ],
    );
  }

  /// Every card that appears here has already passed `_hasWarning` — under
  /// the permissive policy this is ALWAYS an informational warning, never
  /// a blocker, so it is always styled amber (never red/gray/status-based)
  /// regardless of which specific condition triggered it.
  Widget _reviewClassCard(TimetableClassReadiness result) {
    final unscheduled = result.effectiveUnscheduled ?? 0;
    String? capacityMessage;
    if (result.requestedPeriods != null && result.availableSlots != null) {
      if (result.status == TimetableClassStatus.underAllocated) {
        final free =
            result.difference ??
            (result.availableSlots! - result.requestedPeriods!);
        capacityMessage = '$free slot${free == 1 ? '' : 's'} may remain free';
      } else if (result.status == TimetableClassStatus.overAllocated) {
        final excess =
            -(result.difference ??
                (result.availableSlots! - result.requestedPeriods!));
        capacityMessage = 'Reduce by $excess period${excess == 1 ? '' : 's'}';
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _amberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amberBorder),
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
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _amberText.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(result.status),
                  style: const TextStyle(
                    color: _amberText,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (capacityMessage != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              runSpacing: 2,
              children: [
                if (result.requestedPeriods != null)
                  Text(
                    'Configured: ${result.requestedPeriods}',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (result.availableSlots != null)
                  Text(
                    'Capacity: ${result.availableSlots}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              capacityMessage,
              style: const TextStyle(
                color: _amberText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
          if (unscheduled > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$unscheduled requested lesson${unscheduled == 1 ? '' : 's'} could not be scheduled with the current constraints.',
              style: const TextStyle(
                color: _amberText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 14,
              runSpacing: 2,
              children: [
                if (result.requestedPeriods != null)
                  Text(
                    'Requested: ${result.requestedPeriods}',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (result.scheduled != null)
                  Text(
                    'Scheduled: ${result.scheduled}',
                    style: const TextStyle(fontSize: 12),
                  ),
                Text(
                  'Unscheduled: $unscheduled',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'You can still generate this timetable. The unscheduled '
              'lessons will be reported so you can adjust them later.',
              style: TextStyle(color: _amberText, fontSize: 12),
            ),
            if (result.subjectResults.any((s) => s.hasUnscheduled)) ...[
              const SizedBox(height: 6),
              for (final subject in result.subjectResults.where(
                (s) => s.hasUnscheduled,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${subject.subjectName} — Requested ${subject.requested ?? '—'}, '
                    'Scheduled ${subject.scheduled ?? '—'}, '
                    'Unscheduled ${subject.unscheduled ?? '—'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
            if (result.reasonText != null && result.reasonText!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Reason: ${result.reasonText}',
                style: const TextStyle(
                  color: _amberText,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          if (result.missingRequirements.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Missing period requirements:',
              style: TextStyle(
                color: _amberText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            for (final subject in result.missingRequirements)
              Text(
                '- $subject',
                style: const TextStyle(color: _amberText, fontSize: 12),
              ),
          ],
          if (result.missingTeacherAssignments.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Missing teacher assignments:',
              style: TextStyle(
                color: _amberText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            for (final message in result.missingTeacherAssignments)
              Text(
                '- $message',
                style: const TextStyle(color: _amberText, fontSize: 12),
              ),
            if (widget.onOpenCourseAssignments != null) ...[
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, false);
                  widget.onOpenCourseAssignments!();
                },
                icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                label: const Text('Go to Course Assign Teacher'),
              ),
            ],
          ],
          if (result.classId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  _openClassEditor(result.classId!, result.className),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Fix Class'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _generateStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Generate Whole School Timetable',
        'One solve covers the entire school so cross-level teacher conflicts are handled together.',
      ),
      const SizedBox(height: 14),
      if (_generating)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 26),
          child: Column(
            children: [
              CircularProgressIndicator(color: _green),
              SizedBox(height: 12),
              Text(
                'Generating complete school timetable...',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: !_generateReady
                ? _redBg
                : (_preview?.hasWarnings ?? false)
                ? _amberBg
                : _green.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: !_generateReady
                  ? _redBorder
                  : (_preview?.hasWarnings ?? false)
                  ? _amberBorder
                  : _green,
            ),
          ),
          child: Text(
            !_generateReady
                ? (_generateBlockedReason ??
                      'The school is not ready to generate yet — go back to Review School to see why.')
                : 'The backend allows generating this timetable for ${_yearName(_yearId)} now.',
            style: TextStyle(
              color: !_generateReady
                  ? _redText
                  : (_preview?.hasWarnings ?? false)
                  ? _amberText
                  : _green,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (_generateReady && (_preview?.hasWarnings ?? false)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _amberBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _amberBorder),
            ),
            child: Text(
              _generateWarningSummary ??
                  'Some warnings were reported — you can still generate now.',
              style: const TextStyle(
                color: _amberText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ],
  );

  Widget _notice(String message, {bool error = false}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error ? _redBg : _amberBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: error ? _redBorder : _amberBorder),
    ),
    child: Text(
      message,
      style: TextStyle(color: error ? _redText : _amberText, fontSize: 13),
    ),
  );

  Widget _footer() {
    VoidCallback? primary;
    String label = 'Continue';
    String? disabledReason;
    if (_step == 0 && _yearId != null) {
      primary = () => setState(() => _step = 1);
    } else if (_step == 1 && _classes.isNotEmpty) {
      primary = () {
        setState(() => _step = 2);
        _refreshPreview();
      };
      label = 'Review School';
    } else if (_step == 2) {
      label = 'Continue to Generate';
      if (_generateReady) {
        primary = () => setState(() => _step = 3);
      } else {
        disabledReason = _generateBlockedReason;
      }
    } else if (_step == 3) {
      label = 'Generate Whole School Timetable';
      if (_generateReady) {
        primary = () => _onTapGenerate();
      } else {
        disabledReason = _generateBlockedReason;
      }
    }
    final busy = _busy || _generating;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5EAF1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (disabledReason != null && !busy)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(
                disabledReason,
                style: const TextStyle(
                  color: _redText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: busy
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
                    onPressed: busy ? null : primary,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(label, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One shift's independent working-day configuration. Morning and
/// Afternoon (or any other shifts a school defines) are fully separate
/// backend records — this widget is keyed per (academicYearId, shiftId) by
/// its parent so switching year or shift always mounts a brand-new state,
/// never reusing another shift's selected days.
class _ShiftWorkingDaysCard extends StatefulWidget {
  final int academicYearId;
  final int shiftId;
  final String shiftName;
  final VoidCallback? onSaved;

  const _ShiftWorkingDaysCard({
    super.key,
    required this.academicYearId,
    required this.shiftId,
    required this.shiftName,
    this.onSaved,
  });

  @override
  State<_ShiftWorkingDaysCard> createState() => _ShiftWorkingDaysCardState();
}

class _ShiftWorkingDaysCardState extends State<_ShiftWorkingDaysCard> {
  static const _allDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await TimetableGeneratorService().getWorkingDays(
      academicYearId: widget.academicYearId,
      shiftId: widget.shiftId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is GeneratorSuccess<WorkingDaysConfig>) {
        _selected = result.data.days.toSet();
      } else {
        _error = (result as GeneratorError).message;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await TimetableGeneratorService().saveWorkingDays(
      academicYearId: widget.academicYearId,
      shiftId: widget.shiftId,
      days: _selected,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is GeneratorError) {
      setState(() => _error = result.message);
      return;
    }
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shiftName,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allDays.map((day) {
                    final selected = _selected.contains(day);
                    return ChoiceChip(
                      label: Text(day, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      selected: selected,
                      selectedColor: _green.withValues(alpha: .18),
                      onSelected: _saving
                          ? null
                          : (value) => setState(() {
                              if (value) {
                                _selected.add(day);
                              } else {
                                _selected.remove(day);
                              }
                            }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_selected.length} working day${_selected.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: (_saving || _selected.isEmpty) ? null : _save,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    style: const TextStyle(color: _redText, fontSize: 12),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Per-class weekly subject-period editor. Loads ONLY the subjects the
/// backend returns for this exact class (its own class_subjects — never a
/// level union or another class's subjects). `periods_per_week == null`
/// means not-yet-configured and renders as a genuinely empty field —
/// never defaulted to 0, never carried over from another class or a
/// previous wizard session. This dialog is instantiated fresh every time
/// it is opened, so its controllers can never leak between classes.
class _ClassSubjectEditorDialog extends StatefulWidget {
  final int classId;
  final String className;
  final int academicYearId;

  const _ClassSubjectEditorDialog({
    required this.classId,
    required this.className,
    required this.academicYearId,
  });

  @override
  State<_ClassSubjectEditorDialog> createState() =>
      _ClassSubjectEditorDialogState();
}

class _ClassSubjectEditorDialogState extends State<_ClassSubjectEditorDialog> {
  ClassSubjectConfig? _config;
  final Map<int, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await TimetableGeneratorService().getClassSubjects(
      widget.classId,
      widget.academicYearId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is GeneratorSuccess<ClassSubjectConfig>) {
        for (final controller in _controllers.values) {
          controller.dispose();
        }
        _controllers.clear();
        _config = result.data;
        for (final subject in _config!.subjects) {
          // periods_per_week == null means not-yet-configured; the field
          // must stay empty, never a default of 0/1/2/3.
          _controllers[subject.subjectId] = TextEditingController(
            text: subject.periodsPerWeek?.toString() ?? '',
          );
        }
      } else {
        _error = (result as GeneratorError).message;
      }
    });
  }

  int get _configuredTotal => _controllers.values.fold<int>(
    0,
    (sum, c) => sum + (int.tryParse(c.text.trim()) ?? 0),
  );

  bool get _allValid {
    final subjects = _config?.subjects ?? const [];
    return subjects.isNotEmpty &&
        subjects.every((s) {
          final text = _controllers[s.subjectId]?.text.trim() ?? '';
          if (text.isEmpty) return false;
          final value = int.tryParse(text);
          return value != null && value >= 0;
        });
  }

  String? _capacityMessage(int? capacity) {
    if (capacity == null) return null;
    final diff = capacity - _configuredTotal;
    if (diff > 0) return '$diff period${diff == 1 ? '' : 's'} remaining';
    if (diff == 0) return 'Weekly timetable fully allocated';
    return 'Reduce allocation by ${-diff} period${-diff == 1 ? '' : 's'}';
  }

  Future<void> _save() async {
    if (_saving || _config == null) return;
    final subjects = _config!.subjects;
    final hasBlank = subjects.any(
      (s) => (_controllers[s.subjectId]?.text.trim() ?? '').isEmpty,
    );
    if (hasBlank) {
      setState(() => _error = 'Enter periods per week for every subject.');
      return;
    }
    for (final subject in subjects) {
      subject.periodsPerWeek = int.parse(
        _controllers[subject.subjectId]!.text.trim(),
      );
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await TimetableGeneratorService().saveClassSubjects(
      widget.classId,
      widget.academicYearId,
      subjects,
    );
    if (!mounted) return;
    if (result is GeneratorError) {
      setState(() {
        _saving = false;
        _error = result.message;
      });
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final capacity = config?.availableSlots;
    final remaining = capacity != null ? capacity - _configuredTotal : null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: FormCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.className,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (config?.shiftName case final shiftName?)
                            Text(
                              '$shiftName Shift',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5EAF1)),
              if (!_loading && config != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _capacityStat(
                            'Weekly Capacity',
                            capacity?.toString() ?? '—',
                          ),
                          _capacityStat('Configured', '$_configuredTotal'),
                          _capacityStat(
                            remaining == null
                                ? 'Remaining'
                                : remaining < 0
                                ? 'Excess'
                                : 'Remaining',
                            remaining == null ? '—' : '${remaining.abs()}',
                            color: remaining == null
                                ? _navy
                                : remaining == 0
                                ? _green
                                : (remaining < 0 ? _redText : _amberText),
                          ),
                        ],
                      ),
                      if (_capacityMessage(capacity) != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _capacityMessage(capacity)!,
                          style: TextStyle(
                            color: remaining == null
                                ? _navy
                                : remaining == 0
                                ? _green
                                : (remaining < 0 ? _redText : _amberText),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(color: _green),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (config == null || config.subjects.isEmpty)
                              const Text(
                                'No timetable subjects were returned for this class.',
                              )
                            else
                              for (final subject in config.subjects)
                                _subjectRow(subject),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _redBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _redBorder),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: _redText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5EAF1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: (_saving || !_allValid) ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Class Configuration'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _capacityStat(String label, String value, {Color color = _navy}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      );

  Widget _subjectRow(LevelSubjectPeriod subject) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final name = Text(
          subject.subjectName,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
        );
        final input = TextFormField(
          key: ValueKey('class-subject-periods-${subject.subjectId}'),
          controller: _controllers[subject.subjectId],
          keyboardType: TextInputType.number,
          inputFormatters: [
            TextInputFormatter.withFunction(
              (oldValue, newValue) =>
                  RegExp(r'^[0-9]*$').hasMatch(newValue.text)
                  ? newValue
                  : oldValue,
            ),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Periods per week',
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [name, const SizedBox(height: 6), input],
          );
        }
        return Row(
          children: [
            Expanded(child: name),
            const SizedBox(width: 16),
            SizedBox(width: 160, child: input),
          ],
        );
      },
    ),
  );
}
