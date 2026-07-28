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
    if (query.isEmpty) return _students;
    return _students
        .where(
          (student) =>
              student.name.toLowerCase().contains(query) ||
              student.emis.toLowerCase().contains(query),
        )
        .toList();
  }

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  if (!widget.embedBodyOnly) ...[
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: _blue),
                    ),
                    const SizedBox(width: 10),
                  ],
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
        else
          _card(
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Eligible Students',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _blue,
                            ),
                          ),
                          Text(
                            '${_students.length} total • ${_visibleStudents.length} shown • ${_selected.length} selected',
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selected
                          ..clear()
                          ..addAll(_visibleStudents.map((e) => e.id));
                        _preview = null;
                        _previewedRequest = null;
                      }),
                      child: const Text('Select visible'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selected.clear();
                        _preview = null;
                        _previewedRequest = null;
                      }),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                ..._visibleStudents.map(
                  (student) => CheckboxListTile(
                    value: _selected.contains(student.id),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        _selected.add(student.id);
                      } else {
                        _selected.remove(student.id);
                      }
                      _preview = null;
                      _previewedRequest = null;
                    }),
                    title: Text(student.name),
                    subtitle: Text(
                      '${student.emis} • ${student.className ?? '—'}',
                    ),
                    secondary: IconButton(
                      tooltip: 'Academic history',
                      icon: const Icon(Icons.history_edu_rounded),
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
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _working || _selected.isEmpty
                        ? null
                        : _runPreview,
                    style: _primaryButtonStyle(),
                    child: Text('Preview Promotion (${_selected.length})'),
                  ),
                ),
              ],
            ),
          ),
      ],
      if (_preview != null) ...[
        const SizedBox(height: 14),
        _previewView(_preview!),
      ],
    ],
  );

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
