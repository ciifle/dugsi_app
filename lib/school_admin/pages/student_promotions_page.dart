import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/pages/student_promotion_history_page.dart';
import 'package:kobac/school_admin/pages/promotion_batch_details_page.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/promotions_service.dart';
import 'package:kobac/widgets/form_3d/form_theme_3d.dart';

const _blue = FormTheme3D.primaryBlue;
const _green = FormTheme3D.primaryGreen;
const _bg = FormTheme3D.bgColor;

class StudentPromotionsPage extends StatefulWidget {
  final bool embedBodyOnly;
  const StudentPromotionsPage({super.key, this.embedBodyOnly = false});
  @override
  State<StudentPromotionsPage> createState() => _StudentPromotionsPageState();
}

class _StudentPromotionsPageState extends State<StudentPromotionsPage> {
  final _service = PromotionsService();
  final _search = TextEditingController();
  List<ClassModel> _classes = const [];
  List<PromotionStudent> _students = const [];
  List<PromotionHistoryItem> _history = const [];
  final Set<int> _selected = {};
  int? _fromYear, _toYear, _fromClass, _toClass;
  String _decision = 'promoted';
  bool _loading = true, _working = false;
  bool _studentsLoaded = false;
  String? _error;
  PromotionPreview? _preview;
  PromotionRequest? _previewedRequest;
  String _resultFilter = 'all';
  String _eligibilityFilter = 'all';

  bool get _needsDestination =>
      _decision == 'promoted' || _decision == 'repeated';
  bool get _canLoadStudents =>
      _fromYear != null &&
      _fromYear! > 0 &&
      _fromClass != null &&
      _fromClass! > 0 &&
      (!_needsDestination || (_toYear != null && _toClass != null));

  List<PromotionStudent> get _visibleStudents {
    final query = _search.text.trim().toLowerCase();
    return _students
        .where(
          (student) =>
              (query.isEmpty ||
                  student.name.toLowerCase().contains(query) ||
                  student.emis.toLowerCase().contains(query)) &&
              (_resultFilter == 'all' ||
                  (_resultFilter == 'selected'
                      ? _selected.contains(student.id)
                      : _resultKey(student) == _resultFilter)) &&
              (_eligibilityFilter == 'all' ||
                  _eligibilityKey(student) == _eligibilityFilter),
        )
        .toList();
  }

  String _eligibilityKey(PromotionStudent student) {
    if (student.percentage == null) return 'no_result';
    if (!passesPromotionThreshold(student.percentage)) return 'issue';
    if (student.eligible != false) return 'ready';
    final value = (student.reason ?? '').toLowerCase();
    if (value.contains('result') || value.contains('unavailable')) {
      return 'no_result';
    }
    if (value.contains('processed')) return 'already_processed';
    return 'issue';
  }

  String _ineligibilityReason(PromotionStudent student) {
    if (_decision == 'promoted' &&
        !passesPromotionThreshold(student.percentage)) {
      return student.percentage == null
          ? 'No final percentage is available for promotion.'
          : 'Not eligible for promotion: below the 50% threshold.';
    }
    return student.reason?.trim().isNotEmpty == true
        ? student.reason!
        : 'Backend eligibility marked this student as ineligible.';
  }

  String _resultKey(PromotionStudent student) {
    if (student.percentage == null) return 'unavailable';
    return passesPromotionThreshold(student.percentage) ? 'pass' : 'fail';
  }

  bool _canSelect(PromotionStudent student) =>
      _decision != 'promoted' ||
      canPromoteByPercentageAndEligibility(
        student.percentage,
        student.eligible,
      );

  bool get _hasInvalidPromotedSelection =>
      _decision == 'promoted' &&
      _students.any(
        (student) =>
            _selected.contains(student.id) &&
            !passesPromotionThreshold(student.percentage),
      );

  void _toggleStudentSelection(PromotionStudent student) {
    if (!_canSelect(student)) return;
    setState(() {
      if (_selected.contains(student.id)) {
        _selected.remove(student.id);
      } else {
        _selected.add(student.id);
      }
      _preview = null;
      _previewedRequest = null;
    });
  }

  void _selectVisibleStudents(Iterable<PromotionStudent> students) => setState(
    () {
      _selected.addAll(students.where(_canSelect).map((student) => student.id));
      _preview = null;
      _previewedRequest = null;
    },
  );

  void _clearSelectedStudents() => setState(() {
    _selected.clear();
    _preview = null;
    _previewedRequest = null;
  });

  String get _processLabel => switch (_decision) {
    'promoted' => 'Promote Students',
    'repeated' => 'Repeat Students',
    'graduated' => 'Graduate Students',
    'transferred' => 'Mark as Transferred',
    'left' => 'Mark as Left',
    _ => 'Process Students',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialise());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _initialise() async {
    final years = context.read<AcademicYearsProvider>();
    await years.ensureLoaded();
    final classResult = await ClassesService().listClasses();
    final historyResult = await _service.history();
    if (!mounted) return;
    setState(() {
      final activeId = years.activeYear?.id;
      if (_fromYear == null &&
          activeId != null &&
          years.years.any((year) => year.id == activeId)) {
        _fromYear = activeId;
      }
      if (classResult is ClassSuccess<List<ClassModel>>)
        _classes = classResult.data;
      if (historyResult is PromotionSuccess<List<PromotionHistoryItem>>) {
        _history = historyResult.data;
      }
      _loading = false;
    });
  }

  PromotionRequest? _requestSnapshot() {
    if (_fromYear == null || _fromClass == null || _selected.isEmpty)
      return null;
    if (_needsDestination && (_toYear == null || _toClass == null)) return null;
    return PromotionRequest(
      fromAcademicYearId: _fromYear!,
      toAcademicYearId: _needsDestination ? _toYear : null,
      fromClassId: _fromClass!,
      toClassId: _needsDestination ? _toClass : null,
      decision: _decision,
      studentIds: _selected.toList(),
    );
  }

  void _invalidate({bool clearStudents = false}) {
    if (clearStudents) {
      _students = const [];
      _studentsLoaded = false;
      _search.clear();
      _resultFilter = 'all';
      _eligibilityFilter = 'all';
    }
    _selected.clear();
    _preview = null;
    _previewedRequest = null;
    _error = null;
  }

  Future<void> _loadStudents() async {
    if (_fromYear == null || _fromYear! <= 0) {
      _snack('Please select a source academic year.');
      return;
    }
    if (_fromClass == null || _fromClass! <= 0) {
      _snack('Please select a class.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
      _preview = null;
      _previewedRequest = null;
      _selected.clear();
      _studentsLoaded = false;
    });
    final result = await _service.students(
      fromAcademicYearId: _fromYear!,
      classId: _fromClass!,
    );
    if (!mounted) return;
    setState(() {
      _working = false;
      if (result is PromotionSuccess<List<PromotionStudent>>) {
        _students = result.data;
        _studentsLoaded = true;
        _error = null;
      } else {
        _studentsLoaded = false;
        _error = (result as PromotionError).message;
      }
    });
  }

  Future<void> _runPreview() async {
    if (_hasInvalidPromotedSelection) {
      _snack(
        'Some selected students are below the 50% promotion threshold. '
        'Review the selection before continuing.',
        error: true,
      );
      return;
    }
    final request = _requestSnapshot();
    if (request == null) {
      _snack('Complete the required filters and select students.');
      return;
    }
    setState(() => _working = true);
    final result = await _service.preview(request);
    if (!mounted) return;
    setState(() {
      _working = false;
      if (result is PromotionSuccess<PromotionPreview>) {
        _preview = result.data;
        _previewedRequest = request;
        _error = null;
      }
    });
    if (result is PromotionError) {
      if (result.validation != null)
        setState(() => _preview = result.validation);
      _snack(result.message, error: true);
    }
  }

  Future<void> _process() async {
    if (_hasInvalidPromotedSelection) {
      _snack(
        'Some selected students are below the 50% promotion threshold. '
        'Review the selection before continuing.',
        error: true,
      );
      return;
    }
    final request = _previewedRequest;
    if (request == null || _preview?.canProcess != true) return;
    final confirmed = await showAdminFeatureConfirmation(
      context,
      title: 'Process student enrollments?',
      message:
          'Process ${request.studentIds.length} students as ${request.decision.toUpperCase()}? '
          '\nFrom: ${_yearName(request.fromAcademicYearId)} / ${_className(request.fromClassId)}'
          '\nTo: ${_yearName(request.toAcademicYearId)} / ${_className(request.toClassId)}'
          '\nThis updates their academic enrollment records.',
      confirmLabel: 'Process',
      icon: Icons.trending_up_rounded,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    final result = await _service.process(request);
    if (!mounted) return;
    if (result is PromotionSuccess) {
      final history = await _service.history();
      setState(() {
        _working = false;
        _selected.clear();
        _preview = null;
        _previewedRequest = null;
        if (history is PromotionSuccess<List<PromotionHistoryItem>>)
          _history = history.data;
      });
      _snack('Promotion processed successfully.');
      await _loadStudents();
    } else {
      final error = result as PromotionError;
      setState(() {
        _working = false;
        if (error.validation != null) _preview = error.validation;
        _previewedRequest = null;
      });
      _snack(
        error.statusCode == 409
            ? '${error.message} Preview again before processing.'
            : error.message,
        error: true,
      );
    }
  }

  String _yearName(int? id) {
    if (id == null) return '—';
    final years = context.read<AcademicYearsProvider>().years;
    for (final year in years) {
      if (year.id == id) return year.name;
    }
    return '—';
  }

  String _className(int? id) {
    if (id == null) return '—';
    for (final item in _classes) {
      if (item.id == id) return item.name;
    }
    return '—';
  }

  void _snack(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? Colors.red : _green,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final years = context.watch<AcademicYearsProvider>().years;
    final child = Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: _blue, secondary: _green),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? _green : null,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _green,
          linearTrackColor: Color(0xFFE5E7EB),
        ),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            if (!widget.embedBodyOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: _blue),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Promotions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _blue,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Select years and classes, view eligible students, preview, then process.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            TabBar(
              labelColor: _blue,
              unselectedLabelColor: FormTheme3D.textHint,
              indicatorColor: _green,
              indicatorWeight: 3,
              dividerColor: const Color(0xFFE5E7EB),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: [
                const Tab(text: 'Promotion workflow'),
                const Tab(text: 'History'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(children: [_workflow(years), _historyView()]),
            ),
          ],
        ),
      ),
    );
    if (widget.embedBodyOnly) return ColoredBox(color: _bg, child: child);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: child),
    );
  }

  Widget _workflow(List<AcademicYear> years) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(
              icon: Icons.tune_rounded,
              title: 'Promotion Setup',
              subtitle: 'Select the academic years, classes, and decision.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _drop<int>(
                  'From Academic Year',
                  _fromYear,
                  years
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  (v) => setState(() {
                    _fromYear = v;
                    _invalidate(clearStudents: true);
                  }),
                ),
                _drop<int>(
                  'To Academic Year',
                  _toYear,
                  years
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  _needsDestination
                      ? (v) => setState(() {
                          _toYear = v;
                          _invalidate();
                        })
                      : null,
                ),
                _drop<int>(
                  'From Class',
                  _fromClass,
                  _classes
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  (v) => setState(() {
                    _fromClass = v;
                    _invalidate(clearStudents: true);
                  }),
                ),
                _drop<int>(
                  'To Class',
                  _toClass,
                  _classes
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  _needsDestination
                      ? (v) => setState(() {
                          _toClass = v;
                          _invalidate();
                        })
                      : null,
                ),
                _drop<String>(
                  'Decision',
                  _decision,
                  const [
                        'promoted',
                        'repeated',
                        'graduated',
                        'transferred',
                        'left',
                      ]
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e, child: Text(_label(e))),
                      )
                      .toList(),
                  (v) => setState(() {
                    _decision = v!;
                    if (!_needsDestination) _toClass = null;
                    _invalidate(clearStudents: true);
                  }),
                ),
                if (!widget.embedBodyOnly)
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: _fieldDecoration(
                        'Student search',
                        Icons.search_rounded,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilledButton.icon(
                        onPressed: _working || !_canLoadStudents
                            ? null
                            : _loadStudents,
                        style: _primaryButtonStyle(),
                        icon: _working
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.people_alt_outlined),
                        label: Text(
                          _working ? 'Loading…' : 'View eligible students',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Load students from the selected source academic year and class.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (_error != null)
        _card(
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: _working ? null : _loadStudents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      if (_working) const LinearProgressIndicator(),
      if (_studentsLoaded) ...[
        const SizedBox(height: 14),
        if (_students.isEmpty)
          _card(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 42,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No eligible students found for the selected academic year and class.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else if (widget.embedBodyOnly)
          _desktopReviewTable()
        else
          _mobileStudentReview(),
      ],
      if (_preview != null) ...[
        const SizedBox(height: 14),
        _previewView(_preview!),
      ],
    ],
  );

  Widget _mobileStudentReview() {
    final visible = _visibleStudents;
    final selectable = visible.where(_canSelect).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _promotionSummary(),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose Students',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${visible.length} shown • ${_selected.length} selected',
                style: const TextStyle(color: FormTheme3D.textHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: _fieldDecoration(
                  'Search by name or EMIS',
                  Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working || selectable.isEmpty
                          ? null
                          : () => _selectVisibleStudents(selectable),
                      icon: const Icon(Icons.checklist_rounded, size: 18),
                      label: const Text('Select visible'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working || _selected.isEmpty
                          ? null
                          : _clearSelectedStudents,
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...visible.map(_mobilePromotionStudentCard),
        if (_selected.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Select at least one eligible student to preview.',
              style: TextStyle(color: FormTheme3D.textHint),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _working || _selected.isEmpty ? null : _runPreview,
            style: _primaryButtonStyle(),
            icon: const Icon(Icons.visibility_outlined),
            label: Text('Preview Promotion (${_selected.length})'),
          ),
        ),
      ],
    );
  }

  Widget _mobilePromotionStudentCard(PromotionStudent student) {
    final selected = _selected.contains(student.id);
    final selectable = _canSelect(student);
    final status = _resultKey(student);
    final statusColor = status == 'pass'
        ? _green
        : status == 'fail'
        ? Colors.red
        : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _green : statusColor.withValues(alpha: 0.28),
          width: selected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: selectable ? () => _toggleStudentSelection(student) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: selectable
                    ? (_) => _toggleStudentSelection(student)
                    : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.emis} • ${student.className ?? '—'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: FormTheme3D.textHint,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      student.percentage == null
                          ? 'Percentage unavailable'
                          : '${student.percentage}%',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _blue,
                      ),
                    ),
                    if (!selectable)
                      Text(
                        _ineligibilityReason(student),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Academic history',
                icon: const Icon(Icons.history_edu_rounded, color: _blue),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentPromotionHistoryPage(
                      studentId: student.id,
                      studentName: student.name,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopReviewTable() {
    final visible = _visibleStudents;
    final selectableVisible = visible.where(_canSelect).toList();
    final visibleIds = selectableVisible.map((student) => student.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selected.contains);

    void toggleAll(bool? selected) => selected == true
        ? _selectVisibleStudents(selectableVisible)
        : _clearSelectedStudents();

    return Column(
      children: [
        _promotionSummary(),
        const SizedBox(height: 14),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: _fieldDecoration(
                        'Search by name or EMIS number',
                        Icons.search_rounded,
                      ),
                    ),
                  ),
                  _compactFilter(
                    label: 'Result status',
                    value: _resultFilter,
                    values: const [
                      'all',
                      'pass',
                      'fail',
                      'unavailable',
                      'selected',
                    ],
                    onChanged: (value) =>
                        setState(() => _resultFilter = value ?? 'all'),
                  ),
                  _compactFilter(
                    label: 'Eligibility',
                    value: _eligibilityFilter,
                    values: const [
                      'all',
                      'ready',
                      'issue',
                      'no_result',
                      'already_processed',
                    ],
                    onChanged: (value) =>
                        setState(() => _eligibilityFilter = value ?? 'all'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _working || selectableVisible.isEmpty
                        ? null
                        : () => _selectVisibleStudents(selectableVisible),
                    icon: const Icon(Icons.checklist_rounded),
                    label: const Text('Select visible'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _working || _selected.isEmpty
                        ? null
                        : _clearSelectedStudents,
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Clear selection'),
                  ),
                  FilledButton.icon(
                    onPressed: _working || _selected.isEmpty
                        ? null
                        : _runPreview,
                    style: _primaryButtonStyle(),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text('Preview Promotion (${_selected.length})'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Semantics(
                    label: 'Select all shown students',
                    child: Checkbox(
                      value: allVisibleSelected,
                      onChanged: _working || selectableVisible.isEmpty
                          ? null
                          : toggleAll,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_selected.length} selected  •  ${_students.length} total  •  ${visible.length} shown',
                    style: const TextStyle(
                      color: FormTheme3D.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 34),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: FormTheme3D.textHint,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No eligible students found',
                        style: TextStyle(
                          color: _blue,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('No students matched the selected filters.'),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: const WidgetStatePropertyAll(
                          Color(0xFFF7F9FC),
                        ),
                        headingTextStyle: const TextStyle(
                          color: Color(0xFF253858),
                          fontWeight: FontWeight.w700,
                        ),
                        dataRowMinHeight: 68,
                        dataRowMaxHeight: 78,
                        horizontalMargin: 16,
                        columnSpacing: 28,
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Student')),
                          DataColumn(label: Text('EMIS')),
                          DataColumn(label: Text('Current Class')),
                          DataColumn(label: Text('Percentage')),
                          DataColumn(label: Text('Grade')),
                          DataColumn(label: Text('Result Status')),
                          DataColumn(label: Text('Eligibility')),
                        ],
                        rows: [
                          for (var index = 0; index < visible.length; index++)
                            _studentDataRow(visible[index], index + 1),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _studentDataRow(PromotionStudent student, int rowNumber) {
    final selected = _selected.contains(student.id);
    final selectable = _canSelect(student);
    return DataRow(
      selected: selected,
      onSelectChanged: selectable
          ? (_) => _toggleStudentSelection(student)
          : null,
      cells: [
        DataCell(Text('$rowNumber')),
        DataCell(
          SizedBox(
            width: 230,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _blue.withValues(alpha: 0.09),
                  foregroundColor: _blue,
                  child: Text(
                    _initials(student.name),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student.name.isEmpty ? 'Unnamed student' : student.name,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(student.emis.trim().isEmpty ? '—' : student.emis)),
        DataCell(_badge(student.className ?? '—', _blue)),
        DataCell(
          Text(student.percentage == null ? '—' : '${student.percentage}%'),
        ),
        DataCell(_badge(student.grade ?? '—', _green)),
        DataCell(_statusBadge(_resultKey(student))),
        DataCell(_eligibilityBadge(student)),
      ],
    );
  }

  Widget _compactFilter({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) => SizedBox(
    width: 170,
    child: DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _fieldDecoration(label, Icons.filter_list_rounded),
      items: values
          .map(
            (item) => DropdownMenuItem(value: item, child: Text(_label(item))),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );

  Widget _promotionSummary() {
    final pass = _students
        .where((student) => _resultKey(student) == 'pass')
        .length;
    final fail = _students
        .where((student) => _resultKey(student) == 'fail')
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.embedBodyOnly
            ? 178.0
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _reviewMetric(
              'Total',
              _students.length,
              Icons.groups_rounded,
              _blue,
              width,
            ),
            _reviewMetric(
              'Pass',
              pass,
              Icons.check_circle_rounded,
              _green,
              width,
            ),
            _reviewMetric(
              'Fail',
              fail,
              Icons.cancel_rounded,
              Colors.red,
              width,
            ),
            _reviewMetric(
              'Selected',
              _selected.length,
              Icons.how_to_reg_rounded,
              const Color(0xFF01255C),
              width,
            ),
          ],
        );
      },
    );
  }

  Widget _reviewMetric(
    String label,
    int value,
    IconData icon,
    Color color,
    double width,
  ) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: FormTheme3D.textHint, fontSize: 12),
            ),
            Text(
              '$value',
              style: const TextStyle(
                color: _blue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final color = normalized.contains('pass')
        ? _green
        : normalized.contains('fail')
        ? Colors.red
        : Colors.orange;
    return _badge(_label(status), color);
  }

  Widget _eligibilityBadge(PromotionStudent student) {
    final key = _eligibilityKey(student);
    final label = key == 'ready'
        ? 'Ready'
        : (student.reason?.trim().isNotEmpty == true
              ? student.reason!
              : _label(key));
    final color = key == 'ready'
        ? _green
        : key == 'already_processed'
        ? Colors.blueGrey
        : Colors.orange;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: _badge(label, color),
    );
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  Widget _previewView(PromotionPreview preview) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Preview results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _blue,
                ),
              ),
            ),
            Chip(
              label: Text(
                preview.canProcess ? 'Ready to process' : 'Cannot process',
              ),
              backgroundColor: (preview.canProcess ? _green : Colors.red)
                  .withValues(alpha: 0.12),
            ),
          ],
        ),
        if (preview.message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(preview.message!),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricCard(
              'Selected',
              _selected.length,
              Icons.people_alt_outlined,
              _blue,
            ),
            _metricCard(
              'Ready',
              _countCategories(preview, const [
                'valid_students',
                'ready_students',
              ]),
              Icons.check_circle_outline_rounded,
              _green,
            ),
            _metricCard(
              'Failed',
              _countCategories(preview, const ['failed_students']),
              Icons.cancel_outlined,
              Colors.red,
            ),
            _metricCard(
              'Unavailable',
              _countCategories(preview, const ['result_unavailable_students']),
              Icons.warning_amber_rounded,
              Colors.orange,
            ),
            _metricCard(
              'Processed',
              _countCategories(preview, const ['already_processed']),
              Icons.history_rounded,
              Colors.blueGrey,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...preview.categories.entries
            .where((e) => e.value.isNotEmpty)
            .map(
              (entry) => ExpansionTile(
                title: Text('${_label(entry.key)} (${entry.value.length})'),
                children: entry.value
                    .map(
                      (s) => ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          [
                            s.emis,
                            if (s.percentage != null) '${s.percentage}%',
                            s.grade,
                            s.status,
                            s.reason,
                          ].whereType<String>().join(' • '),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        if (!preview.canProcess)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Remove or resolve invalid students before processing.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: preview.canProcess && !_working ? _process : null,
            style: _primaryButtonStyle(),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_processLabel),
          ),
        ),
      ],
    ),
  );

  Widget _historyView() {
    final groups = groupPromotionHistory(_history);
    if (groups.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeading(
            icon: Icons.history_rounded,
            title: 'Promotion History',
            subtitle: 'View completed class promotion records.',
          ),
          const SizedBox(height: 18),
          _card(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 48,
                    color: FormTheme3D.textHint,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No promotion history yet',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Completed promotions will appear here.',
                    style: TextStyle(color: FormTheme3D.textHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: groups.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        if (index == 0) {
          return _SectionHeading(
            icon: Icons.history_rounded,
            title: 'Promotion History',
            subtitle:
                '${groups.length} batches • ${_history.length} students processed',
          );
        }
        final group = groups[index - 1];
        final item = group.first;
        final color = promotionDecisionColor(item.decision);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(FormTheme3D.radiusCard),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PromotionBatchDetailsPage(group: group),
              ),
            ),
            child: _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          promotionDecisionIcon(item.decision),
                          color: color,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        label: Text(_label(item.decision)),
                        backgroundColor: color.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide.none,
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          formatPromotionDate(item.date),
                          maxLines: 1,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FormTheme3D.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _HistoryRouteRow(
                    from: item.fromClass,
                    to: item.toClass,
                    icon: Icons.school_rounded,
                    emphasized: true,
                  ),
                  const SizedBox(height: 10),
                  _HistoryRouteRow(
                    from: item.fromYear,
                    to: item.toYear,
                    icon: Icons.calendar_month_rounded,
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        color: _blue,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${group.studentCount} ${group.studentCount == 1 ? 'student' : 'students'}',
                          style: const TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Kept temporarily to avoid touching the working history data flow while the
  // grouped presentation above replaces its rendering.
  // ignore: unused_element
  Widget _historyViewLegacy() {
    if (_history.isEmpty)
      return const Center(child: Text('No promotion history'));
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = _history[i];
        return _card(
          ListTile(
            title: Text(item.student.name),
            subtitle: Text(
              '${item.fromYear} / ${item.fromClass} → ${item.toYear} / ${item.toClass}\n${item.date}',
            ),
            isThreeLine: true,
            leading: CircleAvatar(
              backgroundColor: _blue.withValues(alpha: 0.1),
              foregroundColor: _blue,
              child: Text(
                item.student.name.trim().isEmpty
                    ? '?'
                    : item.student.name.trim()[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            trailing: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(_label(item.decision)),
                  backgroundColor: _green.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: _blue),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentPromotionHistoryPage(
                        studentId: item.student.id,
                        studentName: item.student.name,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _countCategories(PromotionPreview preview, List<String> keys) {
    var count = 0;
    for (final key in keys) {
      count += preview.categories[key]?.length ?? 0;
    }
    return count;
  }

  Widget _metricCard(String label, int value, IconData icon, Color color) =>
      Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: FormTheme3D.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: FormTheme3D.cardBg,
      borderRadius: BorderRadius.circular(FormTheme3D.radiusCard),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: FormTheme3D.cardShadow,
    ),
    child: child,
  );

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
    backgroundColor: _green,
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFFD1D5DB),
    disabledForegroundColor: const Color(0xFF6B7280),
    minimumSize: const Size(0, 50),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(FormTheme3D.radiusButton),
    ),
    elevation: 3,
    shadowColor: _green.withValues(alpha: 0.35),
  );

  InputDecoration _fieldDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _blue, size: 20),
        filled: true,
        fillColor: FormTheme3D.inputBg,
        labelStyle: const TextStyle(color: FormTheme3D.textHint),
        floatingLabelStyle: const TextStyle(
          color: _blue,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      );

  IconData _fieldIcon(String label) {
    if (label.contains('Year')) return Icons.calendar_month_rounded;
    if (label.contains('Class')) return Icons.school_rounded;
    if (label == 'Decision') return Icons.task_alt_rounded;
    return Icons.tune_rounded;
  }

  Widget _drop<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? changed,
  ) => SizedBox(
    width: 220,
    child: DropdownButtonFormField<T>(
      value: items.any((e) => e.value == value) ? value : null,
      items: items,
      onChanged: changed,
      decoration: _fieldDecoration(label, _fieldIcon(label)),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _blue),
      borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
      isExpanded: true,
    ),
  );

  static String _label(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _blue, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _blue,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: FormTheme3D.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HistoryRouteRow extends StatelessWidget {
  final String from;
  final String to;
  final IconData icon;
  final bool emphasized;

  const _HistoryRouteRow({
    required this.from,
    required this.to,
    required this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _blue, size: 19),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          from,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: emphasized ? _blue : FormTheme3D.textPrimary,
            fontSize: emphasized ? 16 : 14,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(Icons.arrow_forward_rounded, color: _blue, size: 20),
      ),
      Expanded(
        child: Text(
          to,
          maxLines: 2,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: emphasized ? _blue : FormTheme3D.textPrimary,
            fontSize: emphasized ? 16 : 14,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
