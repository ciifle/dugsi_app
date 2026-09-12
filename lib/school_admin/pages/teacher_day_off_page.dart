import 'package:kobac/school_admin/widgets/web_admin_reference_kit.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:kobac/services/teacher_day_off_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/timetable_generator_service.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/widgets/form_3d/form_card.dart';
import 'package:kobac/widgets/form_3d/select_3d.dart';

const _navy = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _pageBg = Color(0xFFF4F7FB);

Widget _inlineNotice(String message, {bool error = false}) => Container(
  margin: const EdgeInsets.only(top: 14),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: error ? const Color(0xFFFFF1F2) : const Color(0xFFFFF8E8),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: error ? const Color(0xFFFCA5A5) : const Color(0xFFF5C76B),
    ),
  ),
  child: Row(
    children: [
      Icon(
        error ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
        color: error ? Colors.red.shade700 : Colors.orange.shade800,
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ],
  ),
);

Widget _confirmationDetails(List<(String, String)> rows) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFF4F7FB),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFDCE3EC)),
  ),
  child: Column(
    children: rows
        .map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                Flexible(
                  child: Text(
                    row.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  ),
);

class TeacherDayOffPage extends StatefulWidget {
  final bool embedBodyOnly;
  const TeacherDayOffPage({super.key, this.embedBodyOnly = false});

  @override
  State<TeacherDayOffPage> createState() => _TeacherDayOffPageState();
}

class _TeacherDayOffPageState extends State<TeacherDayOffPage> {
  final _service = TeacherDayOffService();
  final _yearsService = AcademicYearsService();
  List<TeacherDayOff> _items = const [];
  List<TeacherModel> _teachers = const [];
  List<AcademicYear> _years = const [];
  int? _yearId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final results = await Future.wait([
      _yearsService.list(),
      _yearsService.active(),
      TeachersService().listTeachers(),
    ]);
    if (!mounted) return;
    final yearsResult = results[0];
    final activeResult = results[1];
    final teachersResult = results[2];
    if (yearsResult is AcademicYearSuccess<List<AcademicYear>>) {
      _years = yearsResult.data;
    }
    AcademicYear? active;
    if (activeResult is AcademicYearSuccess<AcademicYear?>) {
      active = activeResult.data;
    }
    if (teachersResult is TeacherSuccess<List<TeacherModel>>) {
      _teachers = teachersResult.data;
    }
    _yearId = active?.id ?? (_years.isNotEmpty ? _years.first.id : null);
    if (_yearId == null) {
      setState(() {
        _loading = false;
        _error = 'Create an academic year before assigning teacher days off.';
      });
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    final yearId = _yearId;
    if (yearId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.list(academicYearId: yearId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is TeacherDayOffSuccess<List<TeacherDayOff>>) {
        _items = result.data;
      } else {
        _error = (result as TeacherDayOffError).message;
      }
    });
  }

  Map<int, List<TeacherDayOff>> get _grouped {
    final map = <int, List<TeacherDayOff>>{};
    for (final item in _items.where((item) => item.isActive)) {
      map.putIfAbsent(item.teacherId, () => []).add(item);
    }
    for (final values in map.values) {
      values.sort(
        (a, b) => teacherDayLabels.keys
            .toList()
            .indexOf(a.day)
            .compareTo(teacherDayLabels.keys.toList().indexOf(b.day)),
      );
    }
    return map;
  }

  AcademicYear? get _year {
    for (final year in _years) {
      if (year.id == _yearId) return year;
    }
    return null;
  }

  Future<void> _openManual([TeacherDayOff? item]) async {
    if (_yearId == null) return;
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ManualDayOffDialog(
        year: _year!,
        teachers: _teachers,
        existing: _items,
        initialItems: item == null
            ? const []
            : (_grouped[item.teacherId] ?? [item]),
      ),
    );
    if (changed == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher days off saved successfully.'),
            backgroundColor: _green,
          ),
        );
      }
    }
  }

  Future<void> _openRandom() async {
    if (_yearId == null) return;
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _RandomDayOffDialog(years: _years, initialYearId: _yearId!),
    );
    if (changed == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher days off generated successfully.'),
            backgroundColor: _green,
          ),
        );
      }
    }
  }

  Future<void> _delete(TeacherDayOff item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AdminFeatureDialog(
        title: 'Remove Teacher Day Off?',
        maxWidth: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _confirmationDetails([
              ('Teacher', item.teacherName),
              ('Day', item.day),
              ('Academic Year', _year?.name ?? '—'),
            ]),
            const SizedBox(height: 16),
            const Text('This recurring weekly day off will be removed.'),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final result = await _service.delete(item.id);
    if (!mounted) return;
    if (result is TeacherDayOffError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } else {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopWebAdminLayout(context)) return _webBody();

    final content = Container(
      color: _pageBg,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _header(),
            const SizedBox(height: 20),
            _summary(),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _messageCard(Icons.error_outline, _error!, 'Retry', _initialize)
            else if (_grouped.isEmpty)
              _messageCard(
                Icons.event_available_outlined,
                'No teacher days off have been configured for this academic year.',
                'Random Generate',
                _openRandom,
                secondaryLabel: 'Add Manually',
                secondaryAction: () => _openManual(),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 760
                    ? _desktopTable()
                    : _mobileCards(),
              ),
          ],
        ),
      ),
    );
    return widget.embedBodyOnly
        ? content
        : Scaffold(
            appBar: AppBar(title: const Text('Teacher Day Off')),
            body: content,
          );
  }

  bool _webDeleting = false;
  Future<void> _deleteWebGroup(List<TeacherDayOff> items) async {
    if (_webDeleting || items.isEmpty) return;
    final confirmed = await showAdminFeatureConfirmation(
      context,
      title: 'Remove Teacher Days Off?',
      message:
          'Remove ' +
          items.map((item) => item.day).toSet().join(', ') +
          ' for ' +
          items.first.teacherName +
          ' in ' +
          (_year?.name ?? '') +
          '?',
      confirmLabel: 'Remove Days Off',
      confirmColor: Colors.red,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _webDeleting = true);
    String? error;
    for (final item in items) {
      final result = await _service.delete(item.id);
      if (result is TeacherDayOffError) {
        error = result.message;
        break;
      }
    }
    if (!mounted) return;
    setState(() => _webDeleting = false);
    await _load();
    if (mounted && error != null)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
  }

  Widget _webBody() {
    final groups = _grouped.values.toList();
    final knownTeachers = _teachers.map((teacher) => teacher.id).toSet();
    final covered = _grouped.keys.where(knownTeachers.contains).length;
    final coverage = knownTeachers.isEmpty
        ? null
        : (covered * 100 / knownTeachers.length).round();
    return WebAdminPage(
      title: 'Teacher Day Off',
      subtitle: 'Manage recurring weekly teacher days off by academic year',
      icon: Icons.event_available_rounded,
      year: _year?.name,
      children: [
        WebAdminCard(
          child: Wrap(
            spacing: 16,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 350,
                child: DropdownButtonFormField<int>(
                  initialValue: _yearId,
                  isExpanded: true,
                  decoration: webAdminInput(
                    'Academic Year',
                    icon: Icons.calendar_month_outlined,
                  ),
                  items: _years
                      .map(
                        (year) => DropdownMenuItem(
                          value: year.id,
                          child: Text(year.name),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value != null) {
                            _yearId = value;
                            _load();
                          }
                        },
                ),
              ),
              webAdminAction(
                'Random Generate',
                Icons.shuffle,
                _yearId == null ? null : _openRandom,
                color: webNavy,
              ),
              webAdminAction(
                'Add Manually',
                Icons.add,
                _yearId == null ? null : () => _openManual(),
                outlined: true,
                color: webNavy,
              ),
            ],
          ),
        ),
        WebAdminStats(
          items: [
            WebAdminStat(
              'Total Teachers',
              _teachers.length.toString(),
              Icons.groups_rounded,
            ),
            WebAdminStat(
              'Teachers With Day Off',
              groups.length.toString(),
              Icons.person_off_outlined,
              webGreen,
            ),
            WebAdminStat(
              'Weekly Day-Off Entries',
              _items.where((item) => item.isActive).length.toString(),
              Icons.event_repeat,
              Colors.orange,
            ),
            if (coverage != null)
              WebAdminStat(
                'Coverage',
                coverage.toString() + '%',
                Icons.check_circle,
                webGreen,
              ),
          ],
        ),
        WebAdminDataPanel(
          title: 'Teachers and Weekly Days Off',
          subtitle: '',
          icon: Icons.groups,
          searchHint: 'Search teachers...',
          noun: 'teachers',
          loading: _loading,
          error: _error,
          retry: _initialize,
          columns: const [
            '#',
            'Teacher Name',
            'Weekly Day(s) Off',
            'Academic Year',
            'Actions',
          ],
          columnWidths: const {
            0: FixedColumnWidth(46),
            1: FlexColumnWidth(2.4),
            2: FlexColumnWidth(2.3),
            3: FlexColumnWidth(1.2),
            4: FixedColumnWidth(110),
          },
          rows: groups.asMap().entries.map((entry) {
            final items = entry.value;
            final unique = <String, TeacherDayOff>{
              for (final item in items) item.day: item,
            };
            return WebAdminRow(
              searchText: items.first.teacherName,
              cells: [
                Text((entry.key + 1).toString()),
                Text(items.first.teacherName),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: unique.values.map((item) {
                    final colors = [
                      const Color(0xFF22A447),
                      const Color(0xFFE34B54),
                      const Color(0xFF2387E8),
                      const Color(0xFF347CF6),
                      const Color(0xFF023471),
                      const Color(0xFFF28A22),
                      const Color(0xFFFF981C),
                    ];
                    final index = const [
                      'MON',
                      'TUE',
                      'WED',
                      'THU',
                      'FRI',
                      'SAT',
                      'SUN',
                    ].indexOf(item.day);
                    final color = colors[index < 0 ? 0 : index];
                    return InputChip(
                      label: Text(item.day),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: color.withValues(alpha: .09),
                      side: BorderSide(color: color.withValues(alpha: .45)),
                      labelStyle: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      deleteIcon: Icon(Icons.close, size: 14, color: color),
                      onDeleted: _webDeleting ? null : () => _delete(item),
                    );
                  }).toList(),
                ),
                Text(_year?.name ?? '?'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    webAdminIcon(
                      'Edit',
                      Icons.edit_outlined,
                      _webDeleting ? null : () => _openManual(items.first),
                    ),
                    webAdminIcon(
                      'Delete',
                      Icons.delete_outline,
                      _webDeleting ? null : () => _deleteWebGroup(items),
                      destructive: true,
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _header() => FormCard(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(
          width: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teacher Day Off',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Manage recurring weekly teacher days off by academic year.',
              ),
            ],
          ),
        ),
        SizedBox(
          width: 260,
          child: Select3D<int>(
            value: _yearId,
            label: 'Academic Year',
            items: _years
                .map(
                  (year) =>
                      DropdownMenuItem(value: year.id, child: Text(year.name)),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (value) {
                    if (value != null) {
                      _yearId = value;
                      _load();
                    }
                  },
          ),
        ),
        FilledButton.icon(
          onPressed: _yearId == null ? null : _openRandom,
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          ),
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Random Generate'),
        ),
        OutlinedButton.icon(
          onPressed: _yearId == null ? null : () => _openManual(),
          style: OutlinedButton.styleFrom(
            foregroundColor: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Manually'),
        ),
      ],
    ),
  );

  Widget _summary() {
    final grouped = _grouped;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _stat(
          'Total Teachers',
          _teachers.length,
          Icons.groups_2_outlined,
          _navy,
        ),
        _stat(
          'Teachers With Day Off',
          grouped.length,
          Icons.person_off_outlined,
          _green,
        ),
        _stat(
          'Weekly Day-Off Entries',
          _items.where((e) => e.isActive).length,
          Icons.event_repeat_rounded,
          Colors.orange.shade700,
        ),
      ],
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) =>
      Container(
        width: 250,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14023471),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                Text(label, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      );

  Widget _desktopTable() => FormCard(
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF1FA)),
          columns: const [
            DataColumn(label: Text('Teacher')),
            DataColumn(label: Text('Weekly Days Off')),
            DataColumn(label: Text('Academic Year')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _grouped.values
              .map(
                (items) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        items.first.teacherName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(_dayChips(items)),
                    DataCell(Text(_year?.name ?? '—')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => _openManual(items.first),
                            icon: const Icon(Icons.edit_outlined, color: _navy),
                          ),
                          ...items.map(
                            (item) => IconButton(
                              tooltip: 'Remove ${item.dayLabel}',
                              onPressed: () => _delete(item),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    ),
  );

  Widget _mobileCards() => Column(
    children: _grouped.values
        .map(
          (items) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          items.first.teacherName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openManual(items.first),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  Text(
                    _year?.name ?? '',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  _dayChips(items),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );

  Widget _dayChips(List<TeacherDayOff> items) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: items
        .map(
          (item) => InputChip(
            label: Text(item.day),
            backgroundColor: const Color(0xFFEAF5E7),
            side: BorderSide(color: _green.withValues(alpha: .45)),
            onDeleted: () => _delete(item),
            deleteIconColor: Colors.red.shade600,
          ),
        )
        .toList(),
  );

  Widget _messageCard(
    IconData icon,
    String text,
    String action,
    Future<void> Function() callback, {
    String? secondaryLabel,
    VoidCallback? secondaryAction,
  }) => FormCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _navy),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _green),
                onPressed: callback,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(action),
              ),
              if (secondaryLabel != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: _navy),
                  onPressed: secondaryAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(secondaryLabel),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ManualDayOffDialog extends StatefulWidget {
  final AcademicYear year;
  final List<TeacherModel> teachers;
  final List<TeacherDayOff> existing;
  final List<TeacherDayOff> initialItems;
  const _ManualDayOffDialog({
    required this.year,
    required this.teachers,
    required this.existing,
    required this.initialItems,
  });

  @override
  State<_ManualDayOffDialog> createState() => _ManualDayOffDialogState();
}

class _ManualDayOffDialogState extends State<_ManualDayOffDialog> {
  int? _teacherId;
  final Set<String> _days = {};
  Set<String> _workingDays = {};
  bool _loadingWorkingDays = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _teacherId = widget.initialItems.firstOrNull?.teacherId;
    _days.addAll(widget.initialItems.map((item) => item.day));
    _loadWorkingDays();
  }

  bool get _editing => widget.initialItems.isNotEmpty;

  Future<void> _loadWorkingDays() async {
    final result = await TimetableGeneratorService().getWorkingDays(
      widget.year.id,
    );
    if (!mounted) return;
    setState(() {
      _loadingWorkingDays = false;
      if (result is GeneratorSuccess<List<String>>) {
        _workingDays = result.data.toSet();
      } else {
        _error = (result as GeneratorError).message;
      }
    });
  }

  Future<void> _save() async {
    if (_loadingWorkingDays || _workingDays.isEmpty) {
      setState(
        () => _error =
            'Configure school working days before assigning teacher days off.',
      );
      return;
    }
    if (_teacherId == null || _days.isEmpty) {
      setState(() => _error = 'Select a teacher and at least one weekday.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final TeacherDayOffResult<dynamic> result;
    if (_editing) {
      final existingByDay = {
        for (final item in widget.initialItems) item.day: item,
      };
      final added = _days.difference(existingByDay.keys.toSet()).toList();
      final removed = existingByDay.keys.toSet().difference(_days).toList();
      TeacherDayOffResult<dynamic> editResult = TeacherDayOffSuccess(true);
      if (added.isNotEmpty) {
        editResult = await TeacherDayOffService().createBulk(
          teacherId: _teacherId!,
          days: added,
          academicYearId: widget.year.id,
        );
      }
      if (editResult is! TeacherDayOffError) {
        for (final day in removed) {
          editResult = await TeacherDayOffService().delete(
            existingByDay[day]!.id,
          );
          if (editResult is TeacherDayOffError) break;
        }
      }
      result = editResult;
    } else {
      final existingDays = widget.existing
          .where((e) => e.teacherId == _teacherId)
          .map((e) => e.day)
          .toSet();
      final newDays = _days.difference(existingDays).toList();
      if (newDays.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'Those days are already assigned to this teacher.';
        });
        return;
      }
      result = await TeacherDayOffService().createBulk(
        teacherId: _teacherId!,
        days: newDays,
        academicYearId: widget.year.id,
      );
    }
    if (!mounted) return;
    if (result is TeacherDayOffError) {
      final message = result.message;
      setState(() {
        _saving = false;
        _error = message;
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    insetPadding: const EdgeInsets.all(20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.event_busy_rounded, color: _navy),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !_editing
                            ? 'Add Teacher Day Off'
                            : 'Edit Teacher Day Off',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Manage recurring weekly availability.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _confirmationDetails([('Academic Year *', widget.year.name)]),
                  const SizedBox(height: 15),
                  Select3D<int>(
                    value: _teacherId,
                    label: 'Teacher',
                    items: widget.teachers
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: !_editing
                        ? (value) => setState(() => _teacherId = value)
                        : null,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Recurring weekly days off',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: teacherDayLabels.entries.map((entry) {
                      final available = _workingDays.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.key),
                        selected: _days.contains(entry.key),
                        selectedColor: _green.withValues(alpha: .22),
                        checkmarkColor: _green,
                        side: BorderSide(
                          color: _days.contains(entry.key)
                              ? _green
                              : const Color(0xFFDCE3EC),
                        ),
                        onSelected: _saving || _loadingWorkingDays || !available
                            ? null
                            : (selected) => setState(() {
                                selected
                                    ? _days.add(entry.key)
                                    : _days.remove(entry.key);
                              }),
                      );
                    }).toList(),
                  ),
                  if (!_loadingWorkingDays && _workingDays.isEmpty)
                    _inlineNotice(
                      'No school working days are configured for this academic year.',
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: _navy),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(backgroundColor: _green),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RandomDayOffDialog extends StatefulWidget {
  final List<AcademicYear> years;
  final int initialYearId;
  const _RandomDayOffDialog({required this.years, required this.initialYearId});

  @override
  State<_RandomDayOffDialog> createState() => _RandomDayOffDialogState();
}

class _RandomDayOffDialogState extends State<_RandomDayOffDialog> {
  final _service = TimetableGeneratorService();
  List<SchoolLevel> _levels = const [];
  List<String> _workingDays = const [];
  late int _yearId;
  int? _levelId;
  int _daysPerTeacher = 1;
  DayOffPreview? _preview;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialYearId;
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      ExamHallService().levels(),
      _service.getWorkingDays(_yearId),
    ]);
    if (!mounted) return;
    final levelResult = results[0];
    final daysResult = results[1];
    if (levelResult is HallSuccess<List<SchoolLevel>>) {
      _levels = levelResult.data.where((e) => e.isActive).toList();
      _levelId = _levels.isEmpty ? null : _levels.first.id;
    }
    if (daysResult is GeneratorSuccess<List<String>>)
      _workingDays = daysResult.data;
    setState(() {
      _loading = false;
      if (levelResult is HallError) _error = levelResult.message;
      if (daysResult is GeneratorError) _error = daysResult.message;
    });
  }

  Future<void> _previewRandom() async {
    if (_levelId == null) {
      setState(() => _error = 'Select a level first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _service.previewDayOffs(
      academicYearId: _yearId,
      levelId: _levelId!,
      daysOffPerTeacher: _daysPerTeacher,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result is GeneratorSuccess<DayOffPreview>) {
        _preview = result.data;
      } else {
        _error = (result as GeneratorError).message;
      }
    });
  }

  Future<void> _apply() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AdminFeatureDialog(
        title: 'Apply Random Teacher Days Off?',
        maxWidth: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _confirmationDetails([
              (
                'Academic Year',
                widget.years
                        .where((year) => year.id == _yearId)
                        .map((year) => year.name)
                        .firstOrNull ??
                    '—',
              ),
              (
                'Level',
                _levels
                        .where((level) => level.id == _levelId)
                        .map((level) => level.name)
                        .firstOrNull ??
                    '—',
              ),
              ('Days Off Per Teacher', '$_daysPerTeacher per week'),
            ]),
            const SizedBox(height: 16),
            const Text(
              'These recurring weekly days off will be used by timetable generation.',
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Apply Days Off'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _service.generateDayOffs(
      academicYearId: _yearId,
      levelId: _levelId!,
      daysOffPerTeacher: _daysPerTeacher,
    );
    if (!mounted) return;
    if (result is GeneratorSuccess<Map<String, dynamic>>) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = (result as GeneratorError).message;
      });
    }
  }

  String _teacherName(Map<String, dynamic> row) =>
      (row['teacher_name'] ??
              row['teacherName'] ??
              row['full_name'] ??
              row['name'] ??
              'Teacher')
          .toString();
  List<String> _rowDays(Map<String, dynamic> row) {
    final raw = row['days'] ?? row['days_off'] ?? row['day_offs'] ?? row['day'];
    return raw is List
        ? raw.map((e) => e.toString().toUpperCase()).toList()
        : raw == null
        ? const []
        : [raw.toString().toUpperCase()];
  }

  Widget _previewRow(Map<String, dynamic> row) => Card(
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFEAF1FA),
        child: Icon(Icons.person_outline, color: _navy),
      ),
      title: Text(
        _teacherName(row),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Wrap(
        spacing: 6,
        children: _rowDays(row)
            .map(
              (day) =>
                  Chip(label: Text(day), visualDensity: VisualDensity.compact),
            )
            .toList(),
      ),
    ),
  );

  Widget _warningRow(String warning) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text('- $warning', style: TextStyle(color: Colors.orange.shade900)),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    insetPadding: const EdgeInsets.all(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 760),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shuffle_rounded, color: _navy),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Random Teacher Days Off',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Generate recurring weekly days off before creating the timetable.',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormCard(
                        child: Column(
                          children: [
                            Select3D<int>(
                              value: _yearId,
                              label: 'Academic Year',
                              items: widget.years
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y.id,
                                      child: Text(y.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _busy
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _yearId = value;
                                        _preview = null;
                                        _loadReferences();
                                      }
                                    },
                            ),
                            const SizedBox(height: 14),
                            Select3D<int>(
                              value: _levelId,
                              label: 'Level',
                              items: _levels
                                  .map(
                                    (l) => DropdownMenuItem(
                                      value: l.id,
                                      child: Text(l.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _busy
                                  ? null
                                  : (value) => setState(() {
                                      _levelId = value;
                                      _preview = null;
                                    }),
                            ),
                            const SizedBox(height: 14),
                            Select3D<int>(
                              value: _daysPerTeacher,
                              label: 'Weekly days off per teacher',
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('1 day'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('2 days'),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text('3 days'),
                                ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) => setState(() {
                                      _daysPerTeacher = value ?? 1;
                                      _preview = null;
                                    }),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  const Text(
                                    'Working days: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  ..._workingDays.map(
                                    (d) => Chip(
                                      label: Text(d),
                                      backgroundColor: const Color(0xFFEAF1FA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      if (_preview != null) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Randomized preview',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 9),
                        if (_preview!.teachers.isEmpty)
                          const FormCard(
                            child: Text(
                              'The server returned an empty preview.',
                            ),
                          ),
                        ..._preview!.teachers.map(_previewRow),
                        ..._preview!.warnings.map(_warningRow),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 10,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: _navy),
                  child: const Text('Cancel'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _previewRandom,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy),
                  ),
                  icon: const Icon(Icons.shuffle),
                  label: Text(
                    _preview == null
                        ? 'Preview Random Days Off'
                        : 'Randomize Again',
                  ),
                ),
                if (_preview != null) ...[
                  FilledButton.icon(
                    onPressed: _busy ? null : _apply,
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Apply'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
