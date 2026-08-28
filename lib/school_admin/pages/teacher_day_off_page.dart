import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_day_off_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

const _navy = Color(0xFF023471);
const _green = Color(0xFF5AB04B);

class TeacherDayOffPage extends StatefulWidget {
  final bool embedBodyOnly;
  const TeacherDayOffPage({super.key, this.embedBodyOnly = false});

  @override
  State<TeacherDayOffPage> createState() => _TeacherDayOffPageState();
}

class _TeacherDayOffPageState extends State<TeacherDayOffPage> {
  final _service = TeacherDayOffService();
  List<TeacherDayOff> _items = [];
  List<TeacherModel> _teachers = [];
  int? _teacherFilter;
  String? _dayFilter;
  bool? _activeFilter;
  bool _loading = true;
  String? _error;

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
    final results = await Future.wait([
      _service.list(),
      TeachersService().listTeachers(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (results[0] is TeacherDayOffSuccess<List<TeacherDayOff>>) {
        _items = (results[0] as TeacherDayOffSuccess<List<TeacherDayOff>>).data;
      } else {
        _error = (results[0] as TeacherDayOffError).message;
      }
      if (results[1] is TeacherSuccess<List<TeacherModel>>) {
        _teachers = (results[1] as TeacherSuccess<List<TeacherModel>>).data;
      }
    });
  }

  List<TeacherDayOff> get _visible => _items.where((item) {
    return (_teacherFilter == null || item.teacherId == _teacherFilter) &&
        (_dayFilter == null || item.day == _dayFilter) &&
        (_activeFilter == null || item.isActive == _activeFilter);
  }).toList();

  Future<void> _openForm([TeacherDayOff? item]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TeacherDayOffDialog(
        teachers: _teachers,
        initial: item,
        service: _service,
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _delete(TeacherDayOff item) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete day off?',
      message: '${item.teacherName} — ${item.dayLabel} will be removed.',
    );
    if (confirmed != true) return;
    final result = await _service.delete(item.id);
    if (!mounted) return;
    if (result is TeacherDayOffError) {
      _snack(result.message, error: true);
    } else {
      _snack('Teacher day off deleted.');
      await _load();
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : _green,
      ),
    );
  }

  Widget _body() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EAF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D023471),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final filters = <Widget>[
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _teacherFilter,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All teachers'),
                    ),
                    ..._teachers.map(
                      (teacher) => DropdownMenuItem(
                        value: teacher.id,
                        child: Text(
                          teacher.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _teacherFilter = value),
                ),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _dayFilter,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All days'),
                    ),
                    ...teacherDayLabels.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _dayFilter = value),
                ),
                DropdownButtonFormField<bool?>(
                  isExpanded: true,
                  initialValue: _activeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All statuses')),
                    DropdownMenuItem(value: true, child: Text('Active')),
                    DropdownMenuItem(value: false, child: Text('Inactive')),
                  ],
                  onChanged: (value) => setState(() => _activeFilter = value),
                ),
              ];
              final addButton = FilledButton.icon(
                onPressed: _loading ? null : _openForm,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  minimumSize: const Size(170, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Day Off'),
              );
              if (constraints.maxWidth >= 820) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < filters.length; index++) ...[
                      Expanded(child: filters[index]),
                      if (index < filters.length - 1) const SizedBox(width: 14),
                    ],
                    const SizedBox(width: 14),
                    addButton,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < filters.length; index++) ...[
                    filters[index],
                    const SizedBox(height: 14),
                  ],
                  addButton,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(color: _green),
        if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (!_loading && _visible.isEmpty)
          const Expanded(
            child: Center(child: Text('No teacher day-off records found.')),
          )
        else if (!_loading)
          Expanded(
            child: kIsWeb || MediaQuery.sizeOf(context).width >= 760
                ? SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Teacher')),
                          DataColumn(label: Text('Day Off')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _visible
                            .map(
                              (item) => DataRow(
                                cells: [
                                  DataCell(Text(item.teacherName)),
                                  DataCell(Text(item.dayLabel)),
                                  DataCell(
                                    Chip(
                                      label: Text(
                                        item.isActive ? 'Active' : 'Inactive',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          onPressed: () => _openForm(item),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          onPressed: () => _delete(item),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
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
                  )
                : ListView.builder(
                    itemCount: _visible.length,
                    itemBuilder: (_, index) {
                      final item = _visible[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.teacherName),
                          subtitle: Text(
                            '${item.dayLabel} · ${item.isActive ? 'Active' : 'Inactive'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => value == 'edit'
                                ? _openForm(item)
                                : _delete(item),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => widget.embedBodyOnly
      ? _body()
      : Scaffold(
          appBar: AppBar(title: const Text('Teacher Day Off')),
          body: _body(),
        );
}

class _TeacherDayOffDialog extends StatefulWidget {
  final List<TeacherModel> teachers;
  final TeacherDayOff? initial;
  final TeacherDayOffService service;
  const _TeacherDayOffDialog({
    required this.teachers,
    required this.initial,
    required this.service,
  });

  @override
  State<_TeacherDayOffDialog> createState() => _TeacherDayOffDialogState();
}

class _TeacherDayOffDialogState extends State<_TeacherDayOffDialog> {
  int? _teacherId;
  String? _day;
  bool _active = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _teacherId = widget.initial?.teacherId;
    _day = widget.initial?.day;
    _active = widget.initial?.isActive ?? true;
  }

  Future<void> _save() async {
    if (_teacherId == null || _day == null) {
      setState(() => _error = 'Select a teacher and day.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = widget.initial == null
        ? await widget.service.create(
            teacherId: _teacherId!,
            day: _day!,
            isActive: _active,
          )
        : await widget.service.update(
            widget.initial!.id,
            teacherId: _teacherId!,
            day: _day!,
            isActive: _active,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is TeacherDayOffError) {
      setState(() => _error = result.message);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.event_busy_outlined, color: _navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.initial == null
                ? 'Add Teacher Day Off'
                : 'Edit Teacher Day Off',
            style: const TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _teacherId,
            decoration: const InputDecoration(labelText: 'Teacher *'),
            items: widget.teachers
                .map(
                  (teacher) => DropdownMenuItem(
                    value: teacher.id,
                    child: Text(
                      teacher.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _teacherId = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Day *'),
            items: teacherDayLabels.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: _saving ? null : (value) => setState(() => _day = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _active,
            onChanged: _saving
                ? null
                : (value) => setState(() => _active = value),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}
