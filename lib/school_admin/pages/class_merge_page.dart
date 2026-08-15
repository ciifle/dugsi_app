import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/class_merge_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/widgets/form_3d/form_theme_3d.dart';

const _blue = FormTheme3D.primaryBlue;
const _green = FormTheme3D.primaryGreen;
const _bg = FormTheme3D.bgColor;

/// School Admin: move/merge students between classes within the same
/// academic year. This is distinct from promotion — it never changes the
/// academic year, and never touches marks/attendance/promotion history.
class ClassMergePage extends StatefulWidget {
  final int? classId;
  final String? className;
  final int? initialAcademicYearId;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const ClassMergePage({
    super.key,
    this.classId,
    this.className,
    this.initialAcademicYearId,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<ClassMergePage> createState() => _ClassMergePageState();
}

class _ClassMergePageState extends State<ClassMergePage>
    with SingleTickerProviderStateMixin {
  final _service = ClassMergeService();
  final _search = TextEditingController();

  int? _academicYearId;
  int? _sourceClassId;
  int? _destinationClassId;
  List<ClassModel> _classes = const [];
  List<StudentModel> _roster = const [];
  List<ClassMergeHistoryEntry> _history = const [];
  final Set<int> _selected = {};

  bool _loading = true;
  bool _working = false;
  bool _rosterLoaded = false;
  String? _error;
  ClassMergePreview? _preview;
  ClassMergeRequest? _previewedRequest;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging && mounted) setState(() {});
      });
    _academicYearId = widget.initialAcademicYearId;
    _sourceClassId = widget.classId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialise());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  List<ClassModel> get _targetClasses =>
      _classes.where((c) => c.id != _sourceClassId).toList();

  List<StudentModel> get _visibleRoster {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _roster;
    return _roster
        .where(
          (s) =>
              s.studentName.toLowerCase().contains(query) ||
              s.emisNumber.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _initialise() async {
    final years = context.read<AcademicYearsProvider>();
    await years.ensureLoaded();
    if (!mounted) return;
    final active = years.activeYear;
    if (_academicYearId == null && active == null) {
      setState(() {
        _loading = false;
        _error = years.error ?? 'No active academic year set';
      });
      return;
    }
    _academicYearId ??= active!.id;
    await _loadClasses();
    await Future.wait([_loadRoster(), _loadHistory()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadClasses() async {
    final yearId = _academicYearId;
    if (yearId == null) return;
    final result = await ClassesService().listClasses(academicYearId: yearId);
    if (!mounted || yearId != _academicYearId) return;
    if (result is ClassSuccess<List<ClassModel>>) {
      setState(() => _classes = result.data);
    }
  }

  void _invalidatePreview() {
    _preview = null;
    _previewedRequest = null;
  }

  Future<void> _onYearChanged(int? value) async {
    if (value == null || value == _academicYearId) return;
    setState(() {
      _academicYearId = value;
      _sourceClassId = null;
      _destinationClassId = null;
      _classes = const [];
      _roster = const [];
      _rosterLoaded = false;
      _history = const [];
      _selected.clear();
      _error = null;
      _invalidatePreview();
    });
    await Future.wait([_loadClasses(), _loadHistory()]);
  }

  Future<void> _onSourceClassChanged(int? value) async {
    if (value == null || value == _sourceClassId) return;
    setState(() {
      _sourceClassId = value;
      _destinationClassId = null;
      _roster = const [];
      _rosterLoaded = false;
      _history = const [];
      _selected.clear();
      _error = null;
      _invalidatePreview();
    });
    await Future.wait([_loadRoster(), _loadHistory()]);
  }

  Future<void> _loadRoster() async {
    final yearId = _academicYearId;
    final classId = _sourceClassId;
    if (yearId == null || classId == null) return;
    setState(() {
      _working = true;
      _error = null;
    });
    final result = await ClassesService().getClass(
      classId,
      academicYearId: yearId,
    );
    if (!mounted || yearId != _academicYearId || classId != _sourceClassId) {
      return;
    }
    setState(() {
      _working = false;
      if (result is ClassSuccess<ClassModel>) {
        _roster = result.data.students;
        _rosterLoaded = true;
      } else {
        _roster = const [];
        _rosterLoaded = false;
        _error = (result as ClassError).message;
      }
    });
  }

  Future<void> _loadHistory() async {
    final yearId = _academicYearId;
    final classId = _sourceClassId;
    final result = await _service.history(
      academicYearId: yearId,
      classId: classId,
    );
    if (!mounted || yearId != _academicYearId || classId != _sourceClassId) {
      return;
    }
    if (result is ClassMergeSuccess<List<ClassMergeHistoryEntry>>) {
      setState(() => _history = result.data);
    }
  }

  void _toggleStudent(int studentId, bool? checked) => setState(() {
    if (checked == true) {
      _selected.add(studentId);
    } else {
      _selected.remove(studentId);
    }
    _invalidatePreview();
  });

  void _onDestinationChanged(int? value) => setState(() {
    _destinationClassId = value;
    _invalidatePreview();
  });

  void _selectAllShown() => setState(() {
    _selected.addAll(_visibleRoster.map((s) => s.id));
    _invalidatePreview();
  });

  void _clearSelection() => setState(() {
    _selected.clear();
    _invalidatePreview();
  });

  ClassMergeRequest? _buildRequest() {
    final yearId = _academicYearId;
    final sourceId = _sourceClassId;
    final destinationId = _destinationClassId;
    if (yearId == null || sourceId == null || destinationId == null)
      return null;
    if (sourceId == destinationId || _selected.isEmpty) return null;
    return ClassMergeRequest(
      academicYearId: yearId,
      sourceClassId: sourceId,
      moves: [
        ClassMergeMove(
          targetClassId: destinationId,
          studentIds: _selected.toSet().toList(),
        ),
      ],
    );
  }

  Future<void> _runPreview() async {
    final request = _buildRequest();
    if (request == null) {
      _snack(
        'Choose a destination class and select at least one student.',
        error: true,
      );
      return;
    }
    setState(() => _working = true);
    final result = await _service.preview(request);
    if (!mounted) return;
    setState(() {
      _working = false;
      if (result is ClassMergeSuccess<ClassMergePreview>) {
        _preview = result.data;
        _previewedRequest = request;
      }
    });
    if (result is ClassMergeError) {
      if (result.validation != null)
        setState(() => _preview = result.validation);
      _snack(result.message, error: true);
    }
  }

  Future<void> _confirmAndProcess() async {
    final request = _previewedRequest;
    final preview = _preview;
    if (request == null || preview?.canProcess != true) return;
    final destination = request.moves.single;
    final confirmed = await showAdminFeatureConfirmation(
      context,
      title: 'Move ${request.selectedCount} Students',
      message:
          'Academic Year:\n${_yearName(request.academicYearId)}\n\n'
          'Source:\n${_className(request.sourceClassId)}\n\n'
          'To:\n${_className(destination.targetClassId)}\n\n'
          'This moves the selected students within the same academic year. '
          'Historical marks, attendance, and promotions remain unchanged.',
      confirmLabel: 'Move Students',
      icon: Icons.swap_horiz_rounded,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    final result = await _service.process(request);
    if (!mounted) return;
    if (result is ClassMergeSuccess<ClassMergePreview>) {
      final data = result.data;
      final movedCount = data.processedCount ?? request.selectedCount;
      final sourceName = _className(request.sourceClassId);
      final destinationName = _className(destination.targetClassId);
      setState(() {
        _working = false;
        _selected.clear();
        _invalidatePreview();
      });
      final parts = <String>[
        '$movedCount students moved from $sourceName to $destinationName',
        if (data.remainingSourceCount != null)
          '${data.remainingSourceCount} remaining in source class',
      ];
      _snack(parts.join(' • '));
      await Future.wait([_loadRoster(), _loadClasses(), _loadHistory()]);
      if (mounted) {
        await _showSuccessDialog(
          count: movedCount,
          source: sourceName,
          destination: destinationName,
        );
      }
    } else {
      final error = result as ClassMergeError;
      setState(() {
        _working = false;
        if (error.validation != null) _preview = error.validation;
        _previewedRequest = null;
      });
      _snack(error.message, error: true);
    }
  }

  Future<void> _showSuccessDialog({
    required int count,
    required String source,
    required String destination,
  }) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.check_circle_rounded, color: _green, size: 46),
      title: const Text('Students Moved Successfully'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count students moved'),
          const SizedBox(height: 14),
          _HistoryRouteRow(from: source, to: destination),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            _tabController.animateTo(1);
          },
          icon: const Icon(Icons.history_rounded),
          label: const Text('View History'),
        ),
      ],
    ),
  );

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
    final child = Column(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Move / Merge Students',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _blue,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.className?.trim().isNotEmpty == true
                            ? 'Move students out of ${widget.className} within the same academic year.'
                            : 'Move students between classes within the same academic year.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        TabBar(
          controller: _tabController,
          labelColor: _blue,
          unselectedLabelColor: FormTheme3D.textHint,
          indicatorColor: _green,
          indicatorWeight: 3,
          dividerColor: Color(0xFFE5E7EB),
          labelStyle: TextStyle(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Move Students'),
            Tab(text: 'History'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [_workflow(years), _historyView()],
                ),
        ),
      ],
    );
    if (widget.embedBodyOnly) return ColoredBox(color: _bg, child: child);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: child),
      bottomNavigationBar: _tabController.index == 0 && _rosterLoaded
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _previewButton(),
            )
          : null,
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
              title: 'Select Academic Year & Source Class',
              subtitle: 'Changing either clears the current selection.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _drop<int>(
                  'Academic Year',
                  _academicYearId,
                  years
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  _onYearChanged,
                ),
                _drop<int>(
                  'Source Class',
                  _sourceClassId,
                  _classes
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  _onSourceClassChanged,
                ),
                _drop<int>(
                  'Destination Class',
                  _destinationClassId,
                  _targetClasses
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  _sourceClassId == null ? null : _onDestinationChanged,
                ),
                if (widget.embedBodyOnly)
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
                onPressed: _working ? null : _loadRoster,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      if (_working) const LinearProgressIndicator(),
      if (_rosterLoaded) ...[
        const SizedBox(height: 14),
        if (_roster.isEmpty)
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
                    'No students found in this class for the selected academic year.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          _rosterCard(),
      ],
      if (_preview != null) ...[
        const SizedBox(height: 14),
        _previewView(_preview!),
      ],
    ],
  );

  Widget _rosterCard() {
    final visible = _visibleRoster;
    final visibleIds = visible.map((s) => s.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selected.contains);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedBodyOnly)
            Row(
              children: [
                Semantics(
                  label: 'Select all shown students',
                  child: Checkbox(
                    value: allVisibleSelected,
                    onChanged: visible.isEmpty
                        ? null
                        : (v) =>
                              v == true ? _selectAllShown() : _clearSelection(),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_selected.length} selected  •  ${_roster.length} total  •  ${visible.length} shown',
                    style: const TextStyle(
                      color: FormTheme3D.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: visible.isEmpty ? null : _selectAllShown,
                  icon: const Icon(Icons.checklist_rounded),
                  label: const Text('Select all shown'),
                ),
                OutlinedButton.icon(
                  onPressed: _selected.isEmpty ? null : _clearSelection,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear selection'),
                ),
              ],
            )
          else
            _mobileSelectionToolbar(visible),
          const SizedBox(height: 10),
          _moveSummary(),
          const SizedBox(height: 10),
          if (widget.embedBodyOnly)
            _desktopRosterTable(visible)
          else
            ...visible.map(_mobileStudentCard),
          const SizedBox(height: 14),
          if (_destinationClassId == null || _selected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _destinationClassId == null
                    ? 'Choose one destination class to continue.'
                    : 'Select at least one student to continue.',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (widget.embedBodyOnly) _previewButton(),
        ],
      ),
    );
  }

  Widget _previewButton() => SizedBox(
    width: widget.embedBodyOnly ? 260 : double.infinity,
    child: FilledButton.icon(
      onPressed: _working || _buildRequest() == null ? null : _runPreview,
      style: _primaryButtonStyle(),
      icon: const Icon(Icons.visibility_outlined),
      label: Text('Preview Move (${_selected.length})'),
    ),
  );

  Widget _mobileSelectionToolbar(List<StudentModel> visible) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: _selectionMetric('Selected', _selected.length)),
          const SizedBox(width: 10),
          Expanded(child: _selectionMetric('Students', _roster.length)),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: visible.isEmpty ? null : _selectAllShown,
              icon: const Icon(Icons.checklist_rounded, size: 18),
              label: const Text('Select all'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selected.isEmpty ? null : _clearSelection,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: _fieldDecoration(
          'Search students (${visible.length} shown)',
          Icons.search_rounded,
        ),
      ),
    ],
  );

  Widget _selectionMetric(String label, int value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _blue.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _blue.withValues(alpha: 0.12)),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: FormTheme3D.textHint),
        ),
      ],
    ),
  );

  Widget _moveSummary() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _blue.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _blue.withValues(alpha: 0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Move Summary',
          style: TextStyle(color: _blue, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryValue('Source', _className(_sourceClassId)),
            ),
            const Icon(Icons.arrow_forward_rounded, color: _green),
            Expanded(
              child: _summaryValue(
                'Destination',
                _className(_destinationClassId),
                end: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_selected.length} ${_selected.length == 1 ? 'student' : 'students'} selected',
          style: const TextStyle(fontWeight: FontWeight.w700, color: _blue),
        ),
      ],
    ),
  );

  Widget _summaryValue(String label, String value, {bool end = false}) =>
      Column(
        crossAxisAlignment: end
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: FormTheme3D.textHint),
          ),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: end ? TextAlign.end : TextAlign.start,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      );

  Widget _mobileStudentCard(StudentModel student) {
    final checked = _selected.contains(student.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: checked ? _green : const Color(0xFFE8ECF2),
          width: checked ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: (v) => _toggleStudent(student.id, v),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                    Text(
                      'EMIS ${student.emisNumber.isEmpty ? '—' : student.emisNumber} • ${student.classDisplayName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: FormTheme3D.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _desktopRosterTable(List<StudentModel> visible) {
    if (visible.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 34),
        child: Center(child: Text('No students matched the search.')),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF7F9FC)),
            headingTextStyle: const TextStyle(
              color: Color(0xFF253858),
              fontWeight: FontWeight.w700,
            ),
            dataRowMinHeight: 64,
            dataRowMaxHeight: 74,
            horizontalMargin: 16,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('')),
              DataColumn(label: Text('Student')),
              DataColumn(label: Text('EMIS')),
              DataColumn(label: Text('Current Class')),
            ],
            rows: visible.map((student) {
              final checked = _selected.contains(student.id);
              return DataRow(
                selected: checked,
                onSelectChanged: (v) => _toggleStudent(student.id, v),
                cells: [
                  DataCell(
                    Checkbox(
                      value: checked,
                      onChanged: (v) => _toggleStudent(student.id, v),
                    ),
                  ),
                  DataCell(Text(student.studentName)),
                  DataCell(
                    Text(student.emisNumber.isEmpty ? '—' : student.emisNumber),
                  ),
                  DataCell(Text(student.classDisplayName)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _previewView(ClassMergePreview preview) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Move Preview',
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
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(preview.message!),
          ),
        const SizedBox(height: 8),
        _moveSummary(),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricCard(
              'Selected',
              preview.selectedCount,
              Icons.people_alt_outlined,
              _blue,
            ),
            _metricCard(
              'Valid',
              preview.validStudents.length,
              Icons.check_circle_outline_rounded,
              _green,
            ),
            _metricCard(
              'Invalid',
              preview.invalidStudents.length,
              Icons.cancel_outlined,
              Colors.red,
            ),
          ],
        ),
        if (preview.invalidStudents.isNotEmpty) ...[
          const SizedBox(height: 10),
          ExpansionTile(
            title: Text('Invalid students (${preview.invalidStudents.length})'),
            children: preview.invalidStudents
                .map(
                  (s) => ListTile(
                    title: Text(s.name),
                    subtitle: Text(
                      [s.emis, s.reason]
                          .whereType<String>()
                          .where((e) => e.isNotEmpty)
                          .join(' • '),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (preview.validStudents.isNotEmpty) ...[
          ExpansionTile(
            title: Text('Valid students (${preview.validStudents.length})'),
            children: preview.validStudents
                .map(
                  (s) => ListTile(title: Text(s.name), subtitle: Text(s.emis)),
                )
                .toList(),
          ),
        ],
        if (!preview.canProcess)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Resolve invalid students before processing.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: preview.canProcess && !_working
                ? _confirmAndProcess
                : null,
            style: _primaryButtonStyle(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Move Students'),
          ),
        ),
      ],
    ),
  );

  Widget _historyView() {
    if (_history.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeading(
            icon: Icons.history_rounded,
            title: 'Merge History',
            subtitle:
                'Students moved between classes in the same academic year.',
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
                    'No merge history yet',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (widget.embedBodyOnly) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeading(
            icon: Icons.history_rounded,
            title: 'Merge History',
            subtitle:
                'Students moved between classes in the same academic year.',
          ),
          const SizedBox(height: 14),
          _card(
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
                    columns: const [
                      DataColumn(label: Text('Student')),
                      DataColumn(label: Text('EMIS')),
                      DataColumn(label: Text('From Class')),
                      DataColumn(label: Text('To Class')),
                      DataColumn(label: Text('Academic Year')),
                      DataColumn(label: Text('Moved By')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Reason')),
                    ],
                    rows: _history
                        .map(
                          (h) => DataRow(
                            cells: [
                              DataCell(Text(h.studentName)),
                              DataCell(Text(h.emis)),
                              DataCell(Text(h.fromClassName)),
                              DataCell(Text(h.toClassName)),
                              DataCell(Text(h.academicYearName)),
                              DataCell(Text(h.movedBy)),
                              DataCell(Text(h.date)),
                              DataCell(Text(h.reason)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: _history.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        if (index == 0) {
          return _SectionHeading(
            icon: Icons.history_rounded,
            title: 'Merge History',
            subtitle: '${_history.length} moves recorded',
          );
        }
        final item = _history[index - 1];
        return _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _blue,
                ),
              ),
              Text(
                'EMIS ${item.emis}',
                style: const TextStyle(
                  color: FormTheme3D.textHint,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              _HistoryRouteRow(from: item.fromClassName, to: item.toClassName),
              const SizedBox(height: 6),
              Text(
                '${item.academicYearName} • Moved by ${item.movedBy}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                item.date,
                style: const TextStyle(
                  fontSize: 12,
                  color: FormTheme3D.textHint,
                ),
              ),
              if (item.reason.isNotEmpty && item.reason != '—')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Reason: ${item.reason}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCard(String label, int value, IconData icon, Color color) =>
      Container(
        width: 150,
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
            Expanded(
              child: Column(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FormTheme3D.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
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

  Widget _drop<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? changed, {
    double width = 220,
  }) => SizedBox(
    width: width,
    child: DropdownButtonFormField<T>(
      value: items.any((e) => e.value == value) ? value : null,
      items: items,
      onChanged: changed,
      decoration: _fieldDecoration(label, Icons.tune_rounded),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _blue),
      borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
      isExpanded: true,
    ),
  );
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

  const _HistoryRouteRow({required this.from, required this.to});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.school_rounded, color: _blue, size: 18),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          from,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.arrow_forward_rounded, color: _blue, size: 18),
      ),
      Expanded(
        child: Text(
          to,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
