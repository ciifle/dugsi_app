import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, setEquals;
import 'package:provider/provider.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:kobac/utils/student_pdf_handler.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';

const _navy = Color(0xFF023471),
    _green = Color(0xFF5AB04B),
    _bg = Color(0xFFF0F3F7);

enum _PreviewState { notPreviewed, loading, success, error }

Widget _page(
  BuildContext context, {
  required bool embedded,
  required String title,
  String? subtitle,
  required Widget child,
  Widget? action,
  Widget? headerAction,
  List<Widget>? headerSecondaryActions,
}) {
  final pageContent = ColoredBox(
    color: _bg,
    child: SafeArea(
      top: !embedded,
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (embedded) ...[
              AdminPageHeader(
                title: title,
                subtitle: subtitle,
                primaryAction: headerAction ?? action,
                secondaryActions: headerSecondaryActions,
              ),
              const SizedBox(height: 20),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
  final brandedContent = Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _navy,
        primary: _navy,
        secondary: _green,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
    ),
    child: pageContent,
  );
  final body = brandedContent;
  return embedded
      ? body
      : Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.white,
            foregroundColor: _navy,
            surfaceTintColor: Colors.white,
          ),
          backgroundColor: _bg,
          body: body,
          floatingActionButton: action,
        );
}

void _snack(BuildContext c, String text, {bool error = false}) =>
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : _green,
      ),
    );
Widget _empty(IconData icon, String title, String body) => Center(
  child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 54, color: _navy.withValues(alpha: .35)),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
  ),
);
Widget _errorState(String title, String message, VoidCallback retry) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const _AdminIconBox(icon: Icons.cloud_off_rounded, danger: true),
      const SizedBox(height: 14),
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _navy,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    ],
  ),
);
Widget _loadingState(String label) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircularProgressIndicator(color: _green),
      const SizedBox(height: 14),
      Text(label, style: const TextStyle(color: Colors.black54)),
    ],
  ),
);

class _AdminIconBox extends StatelessWidget {
  final IconData icon;
  final bool danger;
  const _AdminIconBox({required this.icon, this.danger = false});
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: (danger ? Colors.red : _navy).withValues(alpha: .09),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: danger ? Colors.red.shade700 : _navy),
  );
}

Future<void> _openPassPdf(
  BuildContext context,
  PdfFileResult file, {
  required bool download,
  required String fallbackName,
}) async {
  final filename = file.filename ?? fallbackName;
  if (download) {
    await savePdfWithFeedback(context, bytes: file.bytes, filename: filename);
  } else {
    final opened = await previewStudentPdf(file.bytes, filename);
    if (!opened && context.mounted) {
      _snack(context, 'Unable to preview the PDF.', error: true);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge(this.active);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? _green.withValues(alpha: .12) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          active
              ? Icons.check_circle_rounded
              : Icons.pause_circle_outline_rounded,
          size: 15,
          color: active ? _green : Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Text(
          active ? 'ACTIVE' : 'INACTIVE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF3D8C30) : Colors.grey.shade700,
          ),
        ),
      ],
    ),
  );
}

class _AllocationSuccessMetric extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color accent;
  final Color background;

  const _AllocationSuccessMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent.withValues(alpha: .24)),
    ),
    child: Column(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: TextStyle(
            color: accent,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

BoxDecoration get _card => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFE2E8F0)),
  boxShadow: [
    BoxShadow(
      color: _navy.withValues(alpha: .05),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ],
);

class LevelsPage extends StatefulWidget {
  final bool embedBodyOnly;
  const LevelsPage({super.key, this.embedBodyOnly = false});
  @override
  State<LevelsPage> createState() => _LevelsPageState();
}

class _LevelsPageState extends State<LevelsPage> {
  final _service = ExamHallService();
  List<SchoolLevel> _items = [];
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
    final r = await _service.levels();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r is HallSuccess<List<SchoolLevel>>)
        _items = r.data;
      else
        _error = (r as HallError).message;
    });
  }

  Future<void> _edit([SchoolLevel? level]) async {
    final name = TextEditingController(text: level?.name),
        order = TextEditingController(
          text: '${level?.sortOrder ?? _items.length + 1}',
        );
    bool active = level?.isActive ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AdminFeatureDialog(
          title: level == null ? 'Add Level' : 'Edit Level',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Level Name',
                  hintText: 'Enter level name',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sort Order',
                  hintText: '1',
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _green,
                title: const Text(
                  'Active status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Available for class organization'),
                value: active,
                onChanged: (v) => setLocal(() => active = v),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () async {
                        if (name.text.trim().isEmpty) {
                          _snack(
                            context,
                            'Level name is required.',
                            error: true,
                          );
                          return;
                        }
                        final r = await _service.saveLevel(
                          id: level?.id,
                          name: name.text,
                          sortOrder: int.tryParse(order.text) ?? 0,
                          active: active,
                        );
                        if (!ctx.mounted) return;
                        if (r is HallError) {
                          _snack(context, r.message, error: true);
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: Text(
                        level == null ? 'Create Level' : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      _snack(context, 'Level saved.');
      _load();
    }
  }

  Future<void> _assign(SchoolLevel level) async {
    final result = await _service.classes();
    if (!mounted) return;
    if (result is HallError) {
      _snack(context, result.message, error: true);
      return;
    }
    final classes = (result as HallSuccess<List<LevelClass>>).data;
    final selected = <int>{
      ...classes.where((e) => e.levelId == level.id).map((e) => e.id),
    };
    final search = TextEditingController();
    var query = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final visible = classes
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();
          return AdminFeatureDialog(
            title: 'Assign Classes · ${level.name}',
            maxWidth: 560,
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height.clamp(480, 620) * .68,
              child: Column(
                children: [
                  TextField(
                    controller: search,
                    onChanged: (value) =>
                        setLocal(() => query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      labelText: 'Search Classes',
                      hintText: 'Search by class name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setLocal(
                          () => selected.addAll(classes.map((e) => e.id)),
                        ),
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () => setLocal(selected.clear),
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      Text(
                        '${selected.length} selected',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: classes.isEmpty
                        ? _empty(
                            Icons.class_outlined,
                            'No classes found',
                            'Create classes before assigning a level.',
                          )
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final c = visible[i];
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  activeColor: _green,
                                  value: selected.contains(c.id),
                                  onChanged: (v) => setLocal(
                                    () => v == true
                                        ? selected.add(c.id)
                                        : selected.remove(c.id),
                                  ),
                                  title: Text(c.name),
                                  subtitle: Text(
                                    c.levelName == null
                                        ? 'No current level'
                                        : 'Current: ${c.levelName}',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () async {
                            final r = await _service.assignClasses(
                              level.id,
                              selected.toList(),
                            );
                            if (!ctx.mounted) return;
                            if (r is HallError) {
                              _snack(context, r.message, error: true);
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          child: const Text('Assign Classes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (ok == true) {
      _snack(context, 'Classes assigned.');
      _load();
    }
  }

  Future<void> _delete(SchoolLevel l) async {
    final ok = await showAdminFeatureConfirmation(
      context,
      title: 'Delete Level?',
      message:
          'Delete ${l.name}? Class names and enrollments will not be changed.',
      confirmLabel: 'Delete Level',
      icon: Icons.delete_outline_rounded,
      confirmColor: Colors.red,
    );
    if (ok != true) return;
    final r = await _service.deleteLevel(l.id);
    if (!mounted) return;
    if (r is HallError)
      _snack(context, r.message, error: true);
    else {
      _snack(context, 'Level deleted.');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? _loadingState('Loading levels…')
        : _error != null
        ? _errorState('Unable to load levels', _error!, _load)
        : _items.isEmpty
        ? _empty(
            Icons.layers_outlined,
            'No levels yet',
            'Add a level to organize your school classes.',
          )
        : LayoutBuilder(
            builder: (c, x) {
              final desktop = x.maxWidth >= 760;
              if (desktop)
                return SingleChildScrollView(
                  child: Container(
                    decoration: _card,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Level')),
                        DataColumn(label: Text('Classes')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Sort Order')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _items
                          .map(
                            (l) => DataRow(
                              cells: [
                                DataCell(Text(l.name)),
                                DataCell(Text('${l.classCount}')),
                                DataCell(_StatusBadge(l.isActive)),
                                DataCell(Text('${l.sortOrder}')),
                                DataCell(
                                  Wrap(
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () => _edit(l),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Assign Classes',
                                        onPressed: () => _assign(l),
                                        icon: const Icon(Icons.class_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        onPressed: () => _delete(l),
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
                );
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 104),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final l = _items[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _AdminIconBox(icon: Icons.layers_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            _StatusBadge(l.isActive),
                          ],
                        ),
                        Text(
                          '${l.classCount} Classes',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 2,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                              onPressed: () => _edit(l),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                              onPressed: () => _assign(l),
                              icon: const Icon(Icons.class_outlined),
                              label: const Text('Assign Classes'),
                            ),
                            TextButton.icon(
                              onPressed: () => _delete(l),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
    return _page(
      context,
      embedded: widget.embedBodyOnly,
      title: 'Levels',
      subtitle: 'Organize classes into academic levels',
      child: content,
      action: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Level'),
      ),
    );
  }
}

class ShiftsPage extends StatefulWidget {
  final bool embedBodyOnly;
  const ShiftsPage({super.key, this.embedBodyOnly = false});
  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final _service = ShiftsService();
  List<Shift> _items = [];
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
    final r = await _service.list();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r is ShiftSuccess<List<Shift>>)
        _items = r.data;
      else
        _error = (r as ShiftError).message;
    });
    if (r is ShiftSuccess<List<Shift>> && mounted) {
      context.read<ShiftsProvider>().refresh();
    }
  }

  Future<void> _edit([Shift? shift]) async {
    final name = TextEditingController(text: shift?.name);
    bool active = shift?.isActive ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AdminFeatureDialog(
          title: shift == null ? 'Add Shift' : 'Edit Shift',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Shift Name',
                  hintText: 'e.g. Morning',
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _green,
                title: const Text(
                  'Active status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Available for class assignment'),
                value: active,
                onChanged: (v) => setLocal(() => active = v),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () async {
                        if (name.text.trim().isEmpty) {
                          _snack(
                            context,
                            'Shift name is required.',
                            error: true,
                          );
                          return;
                        }
                        final r = shift == null
                            ? await _service.create(
                                name: name.text,
                                isActive: active,
                              )
                            : await _service.update(
                                shift.id,
                                name: name.text,
                                isActive: active,
                              );
                        if (!ctx.mounted) return;
                        if (r is ShiftError) {
                          _snack(context, r.message, error: true);
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: Text(
                        shift == null ? 'Create Shift' : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      _snack(context, 'Shift saved.');
      _load();
    }
  }

  Future<void> _assign(Shift shift) async {
    final result = await ClassesService().listClasses();
    if (!mounted) return;
    if (result is ClassError) {
      _snack(context, result.message, error: true);
      return;
    }
    final classes = (result as ClassSuccess<List<ClassModel>>).data;
    final selected = <int>{
      ...classes.where((e) => e.shiftId == shift.id).map((e) => e.id),
    };
    final search = TextEditingController();
    var query = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final visible = classes
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();
          return AdminFeatureDialog(
            title: 'Assign Classes · ${shift.name}',
            maxWidth: 560,
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height.clamp(480, 620) * .68,
              child: Column(
                children: [
                  TextField(
                    controller: search,
                    onChanged: (value) =>
                        setLocal(() => query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      labelText: 'Search Classes',
                      hintText: 'Search by class name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setLocal(
                          () => selected.addAll(classes.map((e) => e.id)),
                        ),
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () => setLocal(selected.clear),
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      Text(
                        '${selected.length} selected',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: classes.isEmpty
                        ? _empty(
                            Icons.class_outlined,
                            'No classes found',
                            'Create classes before assigning a shift.',
                          )
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final c = visible[i];
                              final details = [
                                if (c.levelName != null) c.levelName!,
                                c.shiftName == null
                                    ? 'No current shift'
                                    : 'Current: ${c.shiftName}',
                              ].join(' · ');
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  activeColor: _green,
                                  value: selected.contains(c.id),
                                  onChanged: (v) => setLocal(
                                    () => v == true
                                        ? selected.add(c.id)
                                        : selected.remove(c.id),
                                  ),
                                  title: Text(c.name),
                                  subtitle: Text(details),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () async {
                            final r = await _service.assignClasses(
                              shift.id,
                              selected.toList(),
                            );
                            if (!ctx.mounted) return;
                            if (r is ShiftError) {
                              _snack(context, r.message, error: true);
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          child: const Text('Assign Classes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (ok == true) {
      _snack(context, 'Classes assigned.');
      _load();
    }
  }

  Future<void> _delete(Shift s) async {
    final ok = await showAdminFeatureConfirmation(
      context,
      title: 'Delete Shift?',
      message:
          'Delete ${s.name}? This shift is assigned to one or more classes. '
          'Reassign those classes before deleting it.',
      confirmLabel: 'Delete Shift',
      icon: Icons.delete_outline_rounded,
      confirmColor: Colors.red,
    );
    if (ok != true) return;
    final r = await _service.delete(s.id);
    if (!mounted) return;
    if (r is ShiftError)
      _snack(context, r.message, error: true);
    else {
      _snack(context, 'Shift deleted.');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? _loadingState('Loading shifts…')
        : _error != null
        ? _errorState('Unable to load shifts', _error!, _load)
        : _items.isEmpty
        ? _empty(
            Icons.schedule_rounded,
            'No shifts yet',
            'Add a shift such as Morning or Afternoon to organize classes.',
          )
        : LayoutBuilder(
            builder: (c, x) {
              final desktop = x.maxWidth >= 760;
              if (desktop)
                return SingleChildScrollView(
                  child: Container(
                    decoration: _card,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Shift')),
                        DataColumn(label: Text('Classes')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _items
                          .map(
                            (s) => DataRow(
                              cells: [
                                DataCell(Text(s.name)),
                                DataCell(Text('${s.classCount}')),
                                DataCell(_StatusBadge(s.isActive)),
                                DataCell(
                                  Wrap(
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () => _edit(s),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Assign Classes',
                                        onPressed: () => _assign(s),
                                        icon: const Icon(Icons.class_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        onPressed: () => _delete(s),
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
                );
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 104),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final s = _items[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _AdminIconBox(icon: Icons.schedule_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            _StatusBadge(s.isActive),
                          ],
                        ),
                        Text(
                          '${s.classCount} Classes',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 2,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                              onPressed: () => _edit(s),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                              onPressed: () => _assign(s),
                              icon: const Icon(Icons.class_outlined),
                              label: const Text('Assign Classes'),
                            ),
                            TextButton.icon(
                              onPressed: () => _delete(s),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
    return _page(
      context,
      embedded: widget.embedBodyOnly,
      title: 'Shifts',
      subtitle: 'Manage school shifts and assign classes',
      child: content,
      action: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Shift'),
      ),
    );
  }
}

class ExamHallsPage extends StatefulWidget {
  final bool embedBodyOnly;
  const ExamHallsPage({super.key, this.embedBodyOnly = false});
  @override
  State<ExamHallsPage> createState() => _ExamHallsPageState();
}

class _ExamHallsPageState extends State<ExamHallsPage> {
  final _service = ExamHallService();
  List<ExamHall> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _statusFilter = 'all';
  @override
  void initState() {
    super.initState();
    _load();
  }

  List<ExamHall> get _filtered => _items.where((h) {
    final matchesSearch =
        _search.trim().isEmpty ||
        h.name.toLowerCase().contains(_search.trim().toLowerCase());
    final matchesStatus = _statusFilter == 'all'
        ? true
        : _statusFilter == 'active'
        ? h.isActive
        : !h.isActive;
    return matchesSearch && matchesStatus;
  }).toList();

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _service.halls();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r is HallSuccess<List<ExamHall>>) {
        _items = r.data;
        _error = null;
      } else
        _error = (r as HallError).message;
    });
  }

  Future<void> _edit([ExamHall? h]) async {
    final name = TextEditingController(text: h?.name),
        cap = TextEditingController(text: h == null ? '' : '${h.capacity}');
    bool active = h?.isActive ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AdminFeatureDialog(
          title: h == null ? 'Add Exam Hall' : 'Edit Exam Hall',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Hall Name',
                  hintText: 'e.g. Hall 1',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: cap,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Number of students',
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _green,
                title: const Text(
                  'Active status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Available for hall allocation'),
                value: active,
                onChanged: (v) => setLocal(() => active = v),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () async {
                        final capacity = int.tryParse(cap.text) ?? 0;
                        if (name.text.trim().isEmpty || capacity <= 0) {
                          _snack(
                            context,
                            'Name and a capacity greater than zero are required.',
                            error: true,
                          );
                          return;
                        }
                        final r = await _service.saveHall(
                          id: h?.id,
                          name: name.text,
                          capacity: capacity,
                          active: active,
                        );
                        if (!ctx.mounted) return;
                        if (r is HallError) {
                          _snack(context, r.message, error: true);
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: Text(h == null ? 'Create Hall' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      _snack(context, 'Exam hall saved.');
      _load();
    }
  }

  Future<void> _delete(ExamHall h) async {
    final ok = await showAdminFeatureConfirmation(
      context,
      title: 'Delete Hall?',
      message:
          '${h.name} will be removed. This cannot be done when the hall has allocations. '
          'This action cannot be undone.',
      confirmLabel: 'Delete Hall',
      icon: Icons.delete_outline_rounded,
      confirmColor: Colors.red,
    );
    if (ok != true) return;
    final r = await _service.deleteHall(h.id);
    if (!mounted) return;
    if (r is HallError)
      _snack(context, r.message, error: true);
    else {
      _snack(context, 'Exam hall deleted.');
      _load();
    }
  }

  Widget _desktopBody() {
    final filtered = _filtered;
    final totalCapacity = _items.fold<int>(0, (sum, h) => sum + h.capacity);
    final activeCount = _items.where((h) => h.isActive).length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminStatRow(
            tiles: [
              AdminStatTile(
                icon: Icons.meeting_room_rounded,
                color: kAdminNavy,
                value: '${_items.length}',
                label: 'Total Halls',
              ),
              AdminStatTile(
                icon: Icons.groups_rounded,
                color: kAdminGreen,
                value: '$totalCapacity',
                label: 'Total Capacity',
              ),
              AdminStatTile(
                icon: Icons.check_circle_rounded,
                color: kAdminGreen,
                value: '$activeCount',
                label: 'Active Halls',
              ),
              AdminStatTile(
                icon: Icons.pause_circle_outline_rounded,
                color: Colors.grey.shade600,
                value: '${_items.length - activeCount}',
                label: 'Inactive Halls',
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminFilterBar(
            filters: [
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintText: 'Search halls...',
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kAdminBorder),
                  ),
                ),
              ),
              AdminFilterDropdown<String>(
                label: 'Status',
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
              ),
            ],
            actions: [
              AdminSecondaryButton(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kAdminBorder),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: const AdminEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No halls match your search',
                message: 'Try a different name or clear the status filter.',
              ),
            )
          else
            AdminTableCard(
              columns: const [
                AdminTableColumn('Hall', flex: 3),
                AdminTableColumn('Capacity', flex: 2),
                AdminTableColumn('Status', flex: 2),
                AdminTableColumn('Actions', flex: 2, align: TextAlign.right),
              ],
              rows: filtered
                  .map(
                    (h) => AdminTableRow(
                      flexes: const [3, 2, 2, 2],
                      cells: [
                        Text(
                          h.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kAdminNavy,
                          ),
                        ),
                        Text('${h.capacity}'),
                        AdminStatusPill.active(h.isActive),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message: 'Edit Hall',
                              child: IconButton(
                                onPressed: () => _edit(h),
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            Tooltip(
                              message: 'Delete Hall',
                              child: IconButton(
                                onPressed: () => _delete(h),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading)
      content = _loadingState('Loading exam halls…');
    else if (_error != null)
      content = _errorState('Unable to load exam halls', _error!, _load);
    else if (_items.isEmpty)
      content = AdminEmptyState(
        icon: Icons.meeting_room_outlined,
        title: 'No examination halls yet',
        message:
            'Create halls before allocating students to examination rooms.',
        action: widget.embedBodyOnly
            ? AdminPrimaryButton(
                label: '+ Add First Hall',
                onPressed: () => _edit(),
              )
            : null,
      );
    else
      content = LayoutBuilder(
        builder: (c, x) => x.maxWidth >= 700
            ? _desktopBody()
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 104),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final h = _items[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _AdminIconBox(
                              icon: Icons.meeting_room_rounded,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      color: _navy,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Capacity  •  ${h.capacity} Students',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(h.isActive),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => _edit(h),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                            ),
                            Expanded(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                ),
                                onPressed: () => _delete(h),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      );
    return _page(
      context,
      embedded: widget.embedBodyOnly,
      title: 'Exam Halls',
      subtitle: 'Manage examination rooms and seating capacity',
      child: content,
      action: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Hall'),
      ),
      headerAction: AdminPrimaryButton(
        label: '+ Add Hall',
        onPressed: () => _edit(),
      ),
    );
  }
}

class HallAllocationPage extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;
  const HallAllocationPage({
    super.key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });
  @override
  State<HallAllocationPage> createState() => _HallAllocationPageState();
}

class _HallAllocationPageState extends State<HallAllocationPage>
    with SingleTickerProviderStateMixin {
  final s = ExamHallService();
  late TabController tabs;
  List<AcademicYear> years = [];
  List<SchoolLevel> levels = [];
  List<ExamHall> halls = [];
  List<ExamModel> exams = [];
  List<LevelClass> classes = [];
  List<ExamHallAllocationStudent> students = [];
  List<ExamHallAllocationBatch> history = [];
  int? yearId, levelId, classId, examId, hallId, shiftId;
  final selectedStudentIds = <int>{}, selectedHalls = <int>{};
  Set<int> previewedStudentIds = <int>{};
  Set<int> previewedHallIds = <int>{};
  int? previewedYearId,
      previewedLevelId,
      previewedClassId,
      previewedExamId,
      previewedHallId;
  _PreviewState previewState = _PreviewState.notPreviewed;
  bool? previewWasRandom;
  ExamHallAllocationPreview? preview;
  Map<String, dynamic>? previewRequest;
  bool loading = true, busy = false;
  String? error;
  String studentQuery = '';
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
    _load();
    Future.microtask(() => context.read<ShiftsProvider>().ensureLoaded());
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final results = await Future.wait([
      AcademicYearsService().list(),
      s.levels(),
      s.halls(),
      ExamsService().listExams(),
      s.history(),
    ]);
    if (!mounted) return;
    setState(() {
      loading = false;
      final y = results[0];
      if (y is AcademicYearSuccess<List<AcademicYear>>) years = y.data;
      final l = results[1];
      if (l is HallSuccess<List<SchoolLevel>>) levels = l.data;
      final h = results[2];
      if (h is HallSuccess<List<ExamHall>>)
        halls = h.data.where((e) => e.isActive).toList();
      final e = results[3];
      if (e is ExamSuccess<List<ExamModel>>) exams = e.data;
      final hi = results[4];
      if (hi is HallSuccess<List<ExamHallAllocationBatch>>) history = hi.data;
    });
  }

  Future<void> _loadClasses() async {
    if (levelId == null) return;
    final r = await s.classes(levelId: levelId);
    if (!mounted) return;
    setState(() => classes = r is HallSuccess<List<LevelClass>> ? r.data : []);
  }

  Future<void> _loadStudents() async {
    if (yearId == null || levelId == null) return;
    setState(() => busy = true);
    final r = await s.students(
      academicYearId: yearId!,
      levelId: levelId!,
      classId: classId,
      shiftId: shiftId,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      students = r is HallSuccess<List<ExamHallAllocationStudent>>
          ? r.data
          : [];
      selectedStudentIds.clear();
      if (r is HallError) error = r.message;
    });
  }

  Map<String, dynamic>? _request(bool random) {
    if (yearId == null || levelId == null || examId == null) return null;
    if (random) {
      if (selectedHalls.isEmpty) return null;
      return buildRandomAllocationPayload(
        academicYearId: yearId!,
        levelId: levelId!,
        examId: examId!,
        selectedHallIds: selectedHalls,
        classId: classId,
        shiftId: shiftId,
      );
    }
    if (classId == null || hallId == null || selectedStudentIds.isEmpty)
      return null;
    return buildManualAllocationPayload(
      academicYearId: yearId!,
      levelId: levelId!,
      classId: classId!,
      examId: examId!,
      hallId: hallId!,
      selectedStudentIds: selectedStudentIds,
    );
  }

  String? _validationMessage(bool random) {
    if (yearId == null) return 'Select an academic year.';
    if (levelId == null) return 'Select a level.';
    if (examId == null) return 'Select an exam.';
    if (random) {
      if (selectedHalls.isEmpty) return 'Select at least one exam hall.';
      if (selectedHalls.any((id) => id <= 0))
        return 'One or more selected halls have invalid IDs. Reload the hall list and try again.';
      return null;
    }
    if (classId == null) return 'Select a class.';
    if (hallId == null) return 'Select an exam hall.';
    if (selectedStudentIds.isEmpty) return 'Select at least one student.';
    if (selectedStudentIds.any((id) => id <= 0))
      return 'One or more selected students have invalid IDs. Reload the student list and try again.';
    return null;
  }

  void _invalidatePreview() {
    preview = null;
    previewRequest = null;
    previewedStudentIds = <int>{};
    previewedHallIds = <int>{};
    previewedYearId = null;
    previewedLevelId = null;
    previewedClassId = null;
    previewedExamId = null;
    previewedHallId = null;
    previewWasRandom = null;
    previewState = _PreviewState.notPreviewed;
  }

  bool _previewMatchesSelection(bool random) {
    if (previewState != _PreviewState.success || previewWasRandom != random) {
      return false;
    }
    if (previewedYearId != yearId ||
        previewedLevelId != levelId ||
        previewedClassId != classId ||
        previewedExamId != examId) {
      return false;
    }
    return random
        ? setEquals(previewedHallIds, selectedHalls)
        : previewedHallId == hallId &&
              setEquals(previewedStudentIds, selectedStudentIds);
  }

  Future<void> _preview(bool random) async {
    final validation = _validationMessage(random);
    if (validation != null) {
      _snack(context, validation, error: true);
      return;
    }
    final body = _request(random);
    if (body == null) {
      _snack(
        context,
        'The allocation request could not be prepared.',
        error: true,
      );
      return;
    }
    setState(() {
      busy = true;
      _invalidatePreview();
      previewState = _PreviewState.loading;
    });
    try {
      final r = await s.preview(body, random: random);
      if (!mounted) return;
      if (r is HallError) {
        setState(() => previewState = _PreviewState.error);
        _snack(context, r.message, error: true);
        return;
      }
      setState(() {
        preview = (r as HallSuccess<ExamHallAllocationPreview>).data;
        previewRequest = Map<String, dynamic>.from(body);
        previewedStudentIds = random
            ? <int>{}
            : Set<int>.from(selectedStudentIds);
        previewedHallIds = random ? Set<int>.from(selectedHalls) : <int>{};
        previewedYearId = yearId;
        previewedLevelId = levelId;
        previewedClassId = classId;
        previewedExamId = examId;
        previewedHallId = random ? null : hallId;
        previewWasRandom = random;
        previewState = _PreviewState.success;
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _process(bool random) async {
    if (!_previewMatchesSelection(random)) {
      _snack(
        context,
        'Selection changed. Preview the allocation again.',
        error: true,
      );
      return;
    }
    if (random && preview?.allocationPlan == null) {
      _snack(
        context,
        'Preview the allocation again before processing.',
        error: true,
      );
      return;
    }
    if (!canProcessAllocationPreview(
          preview: preview,
          isRandom: random,
          previewIsCurrent: _previewMatchesSelection(random),
        ) ||
        previewRequest == null) {
      return;
    }
    final yes = await showAdminFeatureConfirmation(
      context,
      title: random
          ? 'Process Random Allocation?'
          : 'Allocate ${selectedStudentIds.length} Students?',
      message:
          'The backend will validate capacity and existing allocations again.',
      confirmLabel: 'Process Allocation',
      icon: Icons.event_seat_rounded,
    );
    if (yes != true) return;
    setState(() => busy = true);
    try {
      final processRequest = random
          ? buildRandomProcessPayload(
              previewRequest: previewRequest!,
              allocationPlan: preview!.allocationPlan,
            )
          : previewRequest!;
      final r = await s.process(processRequest, random: random);
      if (!mounted) return;
      if (r is HallError) {
        _snack(context, r.message, error: true);
        return;
      }
      final completedPreview = preview!;
      final completedBatch = (r as HallSuccess<ExamHallAllocationBatch>).data;
      setState(() {
        _invalidatePreview();
        selectedStudentIds.clear();
        selectedHalls.clear();
      });
      await _refreshAllocationData();
      if (!mounted) return;
      await _showAllocationSuccess(
        allocated: completedBatch.studentCount > 0
            ? completedBatch.studentCount
            : random
            ? completedPreview.allocatable
            : completedPreview.valid,
        unallocated: random ? completedPreview.unallocated : 0,
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _refreshAllocationData() async {
    final results = await Future.wait([s.halls(), s.history()]);
    if (!mounted) return;
    setState(() {
      final hallResult = results[0];
      if (hallResult is HallSuccess<List<ExamHall>>) {
        halls = hallResult.data.where((hall) => hall.isActive).toList();
      }
      final historyResult = results[1];
      if (historyResult is HallSuccess<List<ExamHallAllocationBatch>>) {
        history = historyResult.data;
      }
    });
  }

  Future<void> _cancelHistoryBatch(ExamHallAllocationBatch batch) async {
    final confirmed = await showAdminFeatureConfirmation(
      context,
      title: 'Cancel Allocation Batch?',
      message: 'Batch #${batch.id} will be cancelled.',
      confirmLabel: 'Cancel Batch',
      icon: Icons.cancel_outlined,
      confirmColor: Colors.red,
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final result = await s.cancelBatch(batch.id);
      if (!mounted) return;
      if (result is HallError) {
        _snack(context, result.message, error: true);
      } else {
        _snack(context, 'Allocation batch cancelled.');
        await _refreshAllocationData();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _showAllocationSuccess({
    required int allocated,
    required int unallocated,
  }) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        shadowColor: _navy.withValues(alpha: .14),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideBySideActions = constraints.maxWidth >= 360;
                final secondaryButtons = [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, 'history'),
                    icon: const Icon(Icons.history_rounded, size: 19),
                    label: const Text('View History'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, 'report'),
                    icon: const Icon(Icons.assessment_outlined, size: 19),
                    label: const Text('View Hall Report'),
                  ),
                ];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8F7EF),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: _green,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Allocation Completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Students were allocated successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _AllocationSuccessMetric(
                            icon: Icons.check_circle_outline_rounded,
                            value: allocated,
                            label: 'Allocated',
                            accent: _green,
                            background: const Color(0xFFF0FAF4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AllocationSuccessMetric(
                            icon: Icons.groups_2_outlined,
                            value: unallocated,
                            label: 'Remaining',
                            accent: const Color(0xFFD97706),
                            background: const Color(0xFFFFF8E8),
                          ),
                        ),
                      ],
                    ),
                    if (unallocated > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF2C66D)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 19,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$unallocated students remain unallocated. You can assign them to another hall later.',
                                style: const TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (sideBySideActions)
                      Row(
                        children: [
                          Expanded(child: secondaryButtons[0]),
                          const SizedBox(width: 8),
                          Expanded(child: secondaryButtons[1]),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          secondaryButtons[0],
                          const SizedBox(height: 8),
                          secondaryButtons[1],
                        ],
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, 'done'),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'history') tabs.animateTo(2);
    if (action == 'report') {
      if (widget.onNavigateToPage != null) {
        widget.onNavigateToPage!.call('hallReports');
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HallReportsPage()),
        );
      }
    }
  }

  Widget _drop<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> change,
  ) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: items,
    onChanged: busy ? null : change,
  );
  Widget _summaryRow(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: valueColor ?? _navy,
          ),
        ),
      ),
    ],
  );

  Widget _form(bool random) {
    final shifts = context.watch<ShiftsProvider>().shifts;
    final selectedHallObjects = halls
        .where((hall) => selectedHalls.contains(hall.id))
        .toList();
    final selectedCapacity = selectedHallObjects.fold<int>(
      0,
      (total, hall) => total + hall.capacity,
    );
    final visibleStudents = students.where((student) {
      final q = studentQuery.trim().toLowerCase();
      return q.isEmpty ||
          student.name.toLowerCase().contains(q) ||
          student.emis.toLowerCase().contains(q);
    }).toList();
    void invalidate() => _invalidatePreview();

    final setup = Container(
      padding: const EdgeInsets.all(16),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _AdminIconBox(icon: Icons.tune_rounded),
              SizedBox(width: 10),
              Text(
                'Allocation Setup',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth >= 480
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _drop<int>(
                      'Academic Year',
                      yearId,
                      years
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      (v) => setState(() {
                        yearId = v;
                        examId = null;
                        selectedStudentIds.clear();
                        invalidate();
                      }),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _drop<int>(
                      'Level',
                      levelId,
                      levels
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      (v) {
                        setState(() {
                          levelId = v;
                          classId = null;
                          classes = [];
                          students = [];
                          selectedStudentIds.clear();
                          selectedHalls.clear();
                          invalidate();
                        });
                        _loadClasses();
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _drop<int>(
                      'Exam',
                      examId,
                      exams
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      (v) => setState(() {
                        examId = v;
                        invalidate();
                      }),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _drop<int>(
                      random ? 'Class (optional)' : 'Class',
                      classId,
                      classes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      (v) {
                        setState(() {
                          classId = v;
                          selectedStudentIds.clear();
                          invalidate();
                        });
                        if (!random) _loadStudents();
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _drop<int?>(
                      'Shift',
                      shiftId,
                      [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Shifts'),
                        ),
                        ...shifts.map(
                          (e) => DropdownMenuItem<int?>(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        ),
                      ],
                      (v) {
                        setState(() {
                          shiftId = v;
                          selectedStudentIds.clear();
                          invalidate();
                        });
                        if (!random) _loadStudents();
                      },
                    ),
                  ),
                  if (!random)
                    SizedBox(
                      width: width,
                      child: _drop<int>(
                        'Hall',
                        hallId,
                        halls
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text('${e.name} · ${e.capacity}'),
                              ),
                            )
                            .toList(),
                        (v) => setState(() {
                          hallId = v;
                          invalidate();
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    final selection = random
        ? Container(
            padding: const EdgeInsets.all(16),
            decoration: _card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Halls',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 12),
                ...halls.map((hall) {
                  final selected = selectedHalls.contains(hall.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: hall.id <= 0
                          ? null
                          : () => setState(() {
                              selected
                                  ? selectedHalls.remove(hall.id)
                                  : selectedHalls.add(hall.id);
                              invalidate();
                            }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: selected
                              ? _green.withValues(alpha: .08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? _green : const Color(0xFFE2E8F0),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selected ? _green : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hall.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _navy,
                                ),
                              ),
                            ),
                            Text(
                              'Capacity ${hall.capacity}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Divider(),
                AdminStatRow(
                  tiles: [
                    AdminStatTile(
                      icon: Icons.meeting_room_rounded,
                      color: _navy,
                      value: '${selectedHallObjects.length}',
                      label: 'Selected Halls',
                    ),
                    AdminStatTile(
                      icon: Icons.groups_rounded,
                      color: _green,
                      value: '$selectedCapacity',
                      label: 'Selected Capacity',
                    ),
                  ],
                ),
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: _card,
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Students',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    Text(
                      '${selectedStudentIds.length} selected',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) => setState(() => studentQuery = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search students',
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: students.isEmpty
                          ? null
                          : () => setState(() {
                              selectedStudentIds.addAll(
                                visibleStudents
                                    .map((e) => e.studentId)
                                    .where((id) => id > 0),
                              );
                              invalidate();
                            }),
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: selectedStudentIds.isEmpty
                          ? null
                          : () => setState(() {
                              selectedStudentIds.clear();
                              invalidate();
                            }),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                if (students.isEmpty)
                  _empty(
                    Icons.people_outline,
                    'No students found',
                    'Choose the setup fields to load students.',
                  )
                else if (kIsWeb || MediaQuery.sizeOf(context).width >= 760)
                  AdminTableCard(
                    columns: const [
                      AdminTableColumn('', flex: 1),
                      AdminTableColumn('Student Name', flex: 4),
                      AdminTableColumn('EMIS', flex: 2),
                      AdminTableColumn('Class', flex: 2),
                      AdminTableColumn('Shift', flex: 2),
                    ],
                    rows: visibleStudents
                        .map(
                          (student) => AdminTableRow(
                            flexes: const [1, 4, 2, 2, 2],
                            cells: [
                              Checkbox(
                                activeColor: _green,
                                value: selectedStudentIds.contains(
                                  student.studentId,
                                ),
                                onChanged: student.studentId <= 0
                                    ? null
                                    : (checked) => setState(() {
                                        checked == true
                                            ? selectedStudentIds.add(
                                                student.studentId,
                                              )
                                            : selectedStudentIds.remove(
                                                student.studentId,
                                              );
                                        invalidate();
                                      }),
                              ),
                              Text(student.name),
                              Text(student.emis),
                              Text(student.className),
                              Text(student.shiftName),
                            ],
                          ),
                        )
                        .toList(),
                  )
                else
                  ...visibleStudents.map(
                    (student) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: CheckboxListTile(
                        dense: true,
                        activeColor: _green,
                        value: selectedStudentIds.contains(student.studentId),
                        onChanged: student.studentId <= 0
                            ? null
                            : (checked) => setState(() {
                                checked == true
                                    ? selectedStudentIds.add(student.studentId)
                                    : selectedStudentIds.remove(
                                        student.studentId,
                                      );
                                invalidate();
                              }),
                        title: Text(student.name),
                        subtitle: Text(
                          '${student.emis} · ${student.className}'
                          '${student.shiftName.isNotEmpty ? ' • ${student.shiftName}' : ''}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
    final mainContent = LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = !random && constraints.maxWidth >= 900;
        if (!twoColumn) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
            children: [
              setup,
              const SizedBox(height: 12),
              selection,
              const SizedBox(height: 12),
              _previewCard(random),
            ],
          );
        }
        final matches = halls.where((h) => h.id == hallId).toList();
        final hall = matches.isEmpty ? null : matches.first;
        final selectedCount = selectedStudentIds.length;
        final remaining = hall == null ? null : hall.capacity - selectedCount;
        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
          children: [
            setup,
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 62, child: selection),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 320,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              _AdminIconBox(icon: Icons.event_seat_rounded),
                              SizedBox(width: 10),
                              Text(
                                'Allocation Setup',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _summaryRow(
                            'Selected Hall',
                            hall?.name ?? 'Not selected',
                          ),
                          const Divider(height: 26),
                          _summaryRow(
                            'Capacity',
                            hall == null ? '—' : '${hall.capacity}',
                          ),
                          const SizedBox(height: 12),
                          _summaryRow('Selected', '$selectedCount'),
                          const SizedBox(height: 12),
                          _summaryRow(
                            'Remaining',
                            remaining == null ? '—' : '$remaining',
                            valueColor: remaining != null && remaining < 0
                                ? Colors.red
                                : _green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _previewCard(random),
          ],
        );
      },
    );
    return Stack(
      children: [
        mainContent,
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Center(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size(220, 52),
              ),
              onPressed: busy ? null : () => _preview(random),
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: Text(
                random ? 'Preview Random Allocation' : 'Preview Allocation',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewCard(bool random) {
    final successful =
        previewState == _PreviewState.success &&
        preview != null &&
        previewWasRandom == random;
    final matches = _previewMatchesSelection(random);
    final canProcess = canProcessAllocationPreview(
      preview: preview,
      isRandom: random,
      previewIsCurrent: successful && matches,
    );
    final selectedLabel = random
        ? '${selectedHalls.length} halls'
        : '${selectedStudentIds.length}';
    String value(int Function(ExamHallAllocationPreview value) read) =>
        successful ? '${read(preview!)}' : '—';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allocation Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: $selectedLabel   Valid: ${random ? '—' : value((p) => p.valid)}   Invalid: ${random ? '—' : value((p) => p.invalid)}',
          ),
          Text(
            'Total students: ${value((p) => p.totalStudents)}   Capacity: ${value((p) => p.availableCapacity > 0 ? p.availableCapacity : p.totalCapacity)}',
          ),
          Text(
            'Allocatable: ${value((p) => p.allocatable)}   Unallocated: ${value((p) => p.unallocated)}',
          ),
          if (previewState == _PreviewState.loading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(color: _green),
            ),
          if (successful && random && preview!.unallocated > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Text(
                  '${preview!.unallocated} students will remain unallocated because the selected halls do not have enough capacity. You can allocate them to other halls later.',
                  style: TextStyle(color: Colors.amber.shade900),
                ),
              ),
            ),
          if (successful && random && preview!.halls.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Hall breakdown',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...preview!.halls.map(_hallBreakdownRow),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: canProcess && !busy ? () => _process(random) : null,
            child: const Text('Process Allocation'),
          ),
        ],
      ),
    );
  }

  Widget _hallBreakdownRow(Map<String, dynamic> hall) {
    final name = safeText(
      hall['hall_name'] ?? hall['name'] ?? safeMap(hall['hall'])['name'],
      'Hall',
    );
    final details = <String>[];
    void add(String label, List<String> keys) {
      for (final key in keys) {
        if (hall[key] != null) {
          details.add('$label: ${safeInt(hall[key])}');
          return;
        }
      }
    }

    add('Capacity', ['capacity', 'hall_capacity']);
    add('Existing', ['existing', 'existing_count', 'allocated_count']);
    add('Planned', ['planned', 'planned_count', 'allocatable_count']);
    add('Remaining after allocation', [
      'remaining_after_allocation',
      'remaining_capacity',
    ]);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('$name${details.isEmpty ? '' : '\n${details.join('   ')}'}'),
    );
  }

  Widget _history() {
    if (history.isEmpty)
      return _empty(
        Icons.history,
        'No allocation history',
        'Processed allocations will appear here.',
      );
    if (kIsWeb || MediaQuery.sizeOf(context).width >= 760) {
      const flexes = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      return AdminTableCard(
        columns: const [
          AdminTableColumn('Batch', flex: 2),
          AdminTableColumn('Academic Year', flex: 2),
          AdminTableColumn('Exam', flex: 2),
          AdminTableColumn('Level', flex: 2),
          AdminTableColumn('Shift', flex: 2),
          AdminTableColumn('Allocated', flex: 2),
          AdminTableColumn('Unallocated', flex: 2),
          AdminTableColumn('Status', flex: 2),
          AdminTableColumn('Created', flex: 2),
          AdminTableColumn('Actions', flex: 2, align: TextAlign.right),
        ],
        rows: history
            .map(
              (batch) => AdminTableRow(
                flexes: flexes,
                cells: [
                  Text('#${batch.id}'),
                  Text(batch.academicYear),
                  Text(batch.exam),
                  Text(batch.level),
                  Text(batch.shift),
                  Text('${batch.studentCount}'),
                  Text('${batch.unallocatedCount}'),
                  AdminStatusPill(
                    label: batch.status.toUpperCase(),
                    color: batch.status.toLowerCase() == 'active'
                        ? _green
                        : Colors.grey.shade600,
                  ),
                  Text(batch.date),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AllocationDetailPage(batchId: batch.id),
                          ),
                        ),
                        child: const Text('View'),
                      ),
                      if (batch.status.toLowerCase() == 'active')
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => _cancelHistoryBatch(batch),
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ],
              ),
            )
            .toList(),
      );
    }
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final batch = history[index];
        return Container(
          decoration: _card,
          child: ListTile(
            title: Text(
              batch.exam.isEmpty ? 'Allocation #${batch.id}' : batch.exam,
            ),
            subtitle: Text(
              '${batch.academicYear} · ${batch.level}\n${batch.mode} · ${batch.studentCount} students · ${batch.date}',
            ),
            isThreeLine: true,
            trailing: Chip(label: Text(batch.status)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllocationDetailPage(batchId: batch.id),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => _page(
    context,
    embedded: widget.embedBodyOnly,
    title: 'Hall Allocation',
    subtitle: 'Assign students to examination halls and seats',
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              TabBar(
                controller: tabs,
                labelColor: _navy,
                tabs: const [
                  Tab(text: 'Manual'),
                  Tab(text: 'Random'),
                  Tab(text: 'History'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: tabs,
                  children: [_form(false), _form(true), _history()],
                ),
              ),
            ],
          ),
  );
}

class ExamPassCardsPage extends StatefulWidget {
  final bool embedBodyOnly;
  const ExamPassCardsPage({super.key, this.embedBodyOnly = false});

  @override
  State<ExamPassCardsPage> createState() => _ExamPassCardsPageState();
}

class _ExamPassCardsPageState extends State<ExamPassCardsPage> {
  final s = ExamHallService();
  final Set<int> selectedAllocationIds = <int>{};
  List<AcademicYear> years = [];
  List<ExamModel> exams = [];
  List<ExamHall> halls = [];
  List<SchoolLevel> levels = [];
  List<LevelClass> classes = [];
  List<AdminExamPassCard> passes = [];
  int? yearId, examId, hallId, levelId, classId, shiftId;
  bool loadingFilters = true, loadingPasses = false, pdfBusy = false;
  String? loadError;
  String _search = '';

  List<AdminExamPassCard> get _visiblePasses {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return passes;
    return passes
        .where(
          (p) =>
              p.studentName.toLowerCase().contains(q) ||
              p.emis.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
    Future.microtask(() => context.read<ShiftsProvider>().ensureLoaded());
  }

  Future<void> _init() async {
    final results = await Future.wait([
      AcademicYearsService().list(),
      ExamsService().listExams(),
      s.halls(),
      s.levels(),
    ]);
    if (!mounted) return;
    setState(() {
      loadingFilters = false;
      if (results[0] is AcademicYearSuccess<List<AcademicYear>>) {
        years = (results[0] as AcademicYearSuccess<List<AcademicYear>>).data;
      }
      if (results[1] is ExamSuccess<List<ExamModel>>) {
        exams = (results[1] as ExamSuccess<List<ExamModel>>).data;
      }
      if (results[2] is HallSuccess<List<ExamHall>>) {
        halls = (results[2] as HallSuccess<List<ExamHall>>).data;
      }
      if (results[3] is HallSuccess<List<SchoolLevel>>) {
        levels = (results[3] as HallSuccess<List<SchoolLevel>>).data;
      }
    });
  }

  Map<String, String>? get _filters => yearId == null || examId == null
      ? null
      : buildExamPassFilters(
          academicYearId: yearId!,
          examId: examId!,
          hallId: hallId,
          levelId: levelId,
          classId: classId,
          shiftId: shiftId,
        );

  void _filtersChanged() {
    passes = [];
    selectedAllocationIds.clear();
    loadError = null;
  }

  Future<void> _loadClasses() async {
    if (levelId == null) return;
    final result = await s.classes(levelId: levelId);
    if (!mounted) return;
    setState(() {
      classes = result is HallSuccess<List<LevelClass>> ? result.data : [];
    });
  }

  Future<void> _loadPasses() async {
    final filters = _filters;
    if (filters == null) {
      _snack(context, 'Select an academic year and exam.', error: true);
      return;
    }
    setState(() {
      loadingPasses = true;
      loadError = null;
      selectedAllocationIds.clear();
    });
    try {
      final result = await s.examPasses(filters);
      if (!mounted) return;
      setState(() {
        if (result is HallSuccess<List<AdminExamPassCard>>) {
          passes = result.data.where((pass) => pass.allocationId > 0).toList();
        } else {
          passes = [];
          loadError = (result as HallError).message;
        }
      });
    } finally {
      if (mounted) setState(() => loadingPasses = false);
    }
  }

  Future<void> _individual(
    AdminExamPassCard pass, {
    required bool download,
  }) async {
    if (pdfBusy) return;
    setState(() => pdfBusy = true);
    try {
      final result = await s.individualExamPassPdf(pass.allocationId);
      if (!mounted) return;
      if (result is HallError) {
        _snack(context, result.message, error: true);
        return;
      }
      await _openPassPdf(
        context,
        (result as HallSuccess<PdfFileResult>).data,
        download: download,
        fallbackName: 'exam-pass-card.pdf',
      );
    } finally {
      if (mounted) setState(() => pdfBusy = false);
    }
  }

  Future<void> _bulk({required bool allFiltered}) async {
    if (pdfBusy) return;
    if (!allFiltered && selectedAllocationIds.isEmpty) {
      _snack(context, 'Select at least one allocation.', error: true);
      return;
    }
    final filters = _filters;
    if (allFiltered && filters == null) {
      _snack(context, 'Select an academic year and exam.', error: true);
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Print Exam Pass Cards'),
        content: Text(
          'Exam\n${exams.where((e) => e.id == examId).map((e) => e.name).firstOrNull ?? 'Selected exam'}\n\n'
          'Hall\n${halls.where((e) => e.id == hallId).map((e) => e.name).firstOrNull ?? 'All halls'}\n\n'
          '${allFiltered ? 'Filtered Students' : 'Selected Students'}\n${allFiltered ? passes.length : selectedAllocationIds.length}\n\n'
          'Layout\n3 cards per A4 page',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, 'preview'),
            child: const Text('Preview PDF'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: () => Navigator.pop(dialogContext, 'download'),
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    setState(() => pdfBusy = true);
    try {
      final result = allFiltered
          ? await s.filteredExamPassesPdf(filters!)
          : await s.selectedExamPassesPdf(selectedAllocationIds);
      if (!mounted) return;
      if (result is HallError) {
        _snack(context, result.message, error: true);
        return;
      }
      await _openPassPdf(
        context,
        (result as HallSuccess<PdfFileResult>).data,
        download: action == 'download',
        fallbackName: 'exam-pass-cards.pdf',
      );
    } finally {
      if (mounted) setState(() => pdfBusy = false);
    }
  }

  DropdownButtonFormField<int> _drop(
    String label,
    int? value,
    List<DropdownMenuItem<int>> items,
    ValueChanged<int?> change,
  ) => DropdownButtonFormField<int>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: items,
    onChanged: loadingPasses || pdfBusy ? null : change,
  );

  Widget _filtersCard() => AdminFilterBar(
    filters: [
      _drop(
        'Academic Year',
        yearId,
        years
            .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
            .toList(),
        (value) => setState(() {
          yearId = value;
          examId = null;
          _filtersChanged();
        }),
      ),
      _drop(
        'Exam',
        examId,
        exams
            .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
            .toList(),
        (value) => setState(() {
          examId = value;
          _filtersChanged();
        }),
      ),
      _drop(
        'Hall (optional)',
        hallId,
        halls
            .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
            .toList(),
        (value) => setState(() {
          hallId = value;
          _filtersChanged();
        }),
      ),
      _drop(
        'Level (optional)',
        levelId,
        levels
            .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
            .toList(),
        (value) {
          setState(() {
            levelId = value;
            classId = null;
            classes = [];
            _filtersChanged();
          });
          _loadClasses();
        },
      ),
      _drop(
        'Class (optional)',
        classId,
        classes
            .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
            .toList(),
        (value) => setState(() {
          classId = value;
          _filtersChanged();
        }),
      ),
      AdminFilterDropdown<int?>(
        label: 'Shift (optional)',
        value: shiftId,
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All Shifts')),
          ...context.watch<ShiftsProvider>().shifts.map(
            (e) => DropdownMenuItem<int?>(value: e.id, child: Text(e.name)),
          ),
        ],
        onChanged: loadingPasses || pdfBusy
            ? null
            : (value) => setState(() {
                shiftId = value;
                _filtersChanged();
              }),
      ),
    ],
    actions: [
      AdminPrimaryButton(
        label: 'Load Pass Cards',
        icon: Icons.search_rounded,
        onPressed: loadingPasses || pdfBusy ? null : _loadPasses,
      ),
    ],
  );

  Widget _searchField() => TextField(
    onChanged: (v) => setState(() => _search = v),
    decoration: InputDecoration(
      isDense: true,
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      hintText: 'Search students...',
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAdminBorder),
      ),
    ),
  );

  Widget _selectionBar() => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        '${_visiblePasses.length} students  ·  ${selectedAllocationIds.length} selected',
        style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
      ),
      TextButton(
        onPressed: _visiblePasses.isEmpty
            ? null
            : () => setState(() {
                selectedAllocationIds
                  ..clear()
                  ..addAll(selectLoadedPassAllocationIds(_visiblePasses));
              }),
        child: const Text('Select All'),
      ),
      TextButton(
        onPressed: selectedAllocationIds.isEmpty
            ? null
            : () => setState(selectedAllocationIds.clear),
        child: const Text('Clear'),
      ),
      OutlinedButton.icon(
        onPressed: selectedAllocationIds.isEmpty || pdfBusy
            ? null
            : () => _bulk(allFiltered: false),
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Preview Selected'),
      ),
      OutlinedButton.icon(
        onPressed: selectedAllocationIds.isEmpty || pdfBusy
            ? null
            : () => _bulk(allFiltered: false),
        icon: const Icon(Icons.download_outlined),
        label: const Text('Download Selected'),
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: _green),
        onPressed: passes.isEmpty || pdfBusy
            ? null
            : () => _bulk(allFiltered: true),
        icon: const Icon(Icons.print_outlined),
        label: const Text('Print All Filtered'),
      ),
    ],
  );

  Widget _mobileCard(AdminExamPassCard pass) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: _card,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          activeColor: _green,
          value: selectedAllocationIds.contains(pass.allocationId),
          onChanged: (checked) => setState(() {
            checked == true
                ? selectedAllocationIds.add(pass.allocationId)
                : selectedAllocationIds.remove(pass.allocationId);
          }),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pass.studentName,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'EMIS: ${pass.emis.isEmpty ? '—' : pass.emis}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text('Class: ${pass.className.isEmpty ? '—' : pass.className}'),
              Text(
                'Hall: ${pass.hallName.isEmpty ? '—' : pass.hallName}  ·  Seat: ${pass.seat.isEmpty ? '—' : pass.seat}',
              ),
              if (pass.levelName.isNotEmpty || pass.shift.isNotEmpty)
                Text(
                  '${pass.levelName}${pass.levelName.isNotEmpty && pass.shift.isNotEmpty ? '  ·  ' : ''}${pass.shift}',
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: pdfBusy
                        ? null
                        : () => _individual(pass, download: false),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Preview Pass'),
                  ),
                  TextButton.icon(
                    onPressed: pdfBusy
                        ? null
                        : () => _individual(pass, download: true),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download Pass'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _desktopTable() => AdminTableCard(
    columns: const [
      AdminTableColumn('', flex: 1),
      AdminTableColumn('Student', flex: 3),
      AdminTableColumn('EMIS', flex: 2),
      AdminTableColumn('Class', flex: 2),
      AdminTableColumn('Level', flex: 2),
      AdminTableColumn('Hall', flex: 2),
      AdminTableColumn('Seat', flex: 1),
      AdminTableColumn('Shift', flex: 2),
      AdminTableColumn('Actions', flex: 3, align: TextAlign.right),
    ],
    rows: _visiblePasses
        .map(
          (pass) => AdminTableRow(
            flexes: const [1, 3, 2, 2, 2, 2, 1, 2, 3],
            cells: [
              Checkbox(
                activeColor: _green,
                value: selectedAllocationIds.contains(pass.allocationId),
                onChanged: (checked) => setState(() {
                  checked == true
                      ? selectedAllocationIds.add(pass.allocationId)
                      : selectedAllocationIds.remove(pass.allocationId);
                }),
              ),
              Text(pass.studentName),
              Text(pass.emis),
              Text(pass.className),
              Text(pass.levelName),
              Text(pass.hallName),
              Text(pass.seat),
              Text(pass.shift),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: pdfBusy
                        ? null
                        : () => _individual(pass, download: false),
                    child: const Text('Preview'),
                  ),
                  TextButton(
                    onPressed: pdfBusy
                        ? null
                        : () => _individual(pass, download: true),
                    child: const Text('Print'),
                  ),
                ],
              ),
            ],
          ),
        )
        .toList(),
  );

  @override
  Widget build(BuildContext context) => _page(
    context,
    embedded: widget.embedBodyOnly,
    title: 'Exam Pass Cards',
    subtitle: 'Find, preview and print student examination passes',
    headerAction: AdminPrimaryButton(
      label: 'Print Filtered',
      icon: Icons.print_outlined,
      onPressed: passes.isEmpty || pdfBusy
          ? null
          : () => _bulk(allFiltered: true),
    ),
    child: loadingFilters
        ? _loadingState('Loading pass card filters...')
        : ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _filtersCard(),
              const SizedBox(height: 16),
              _searchField(),
              const SizedBox(height: 12),
              _selectionBar(),
              const SizedBox(height: 10),
              if (loadingPasses || pdfBusy)
                const LinearProgressIndicator(color: _green),
              if (loadError != null)
                SizedBox(
                  height: 260,
                  child: _errorState(
                    'Unable to load exam pass cards',
                    loadError!,
                    _loadPasses,
                  ),
                )
              else if (!loadingPasses && passes.isEmpty)
                _empty(
                  Icons.badge_outlined,
                  'No pass cards found',
                  'Choose filters and load allocated students.',
                )
              else if (passes.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) =>
                      kIsWeb || constraints.maxWidth >= 760
                      ? _desktopTable()
                      : Column(
                          children: _visiblePasses.map(_mobileCard).toList(),
                        ),
                ),
            ],
          ),
  );
}

class AllocationDetailPage extends StatefulWidget {
  final int batchId;
  const AllocationDetailPage({super.key, required this.batchId});
  @override
  State<AllocationDetailPage> createState() => _AllocationDetailPageState();
}

class _AllocationDetailPageState extends State<AllocationDetailPage> {
  final s = ExamHallService();
  ExamHallAllocationBatch? b;
  String? error;
  bool pdfBusy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await s.allocation(widget.batchId);
    if (!mounted) return;
    setState(() {
      if (r is HallSuccess<ExamHallAllocationBatch>)
        b = r.data;
      else
        error = (r as HallError).message;
    });
  }

  Future<void> _cancelStudent(int id) async {
    final confirmed = await showAdminFeatureConfirmation(
      context,
      title: 'Cancel Student Allocation?',
      message: 'This student will be removed from the allocation batch.',
      confirmLabel: 'Cancel Allocation',
      icon: Icons.cancel_outlined,
      confirmColor: Colors.red,
    );
    if (confirmed != true || !mounted) return;
    final r = await s.cancelStudent(id);
    if (!mounted) return;
    if (r is HallError)
      _snack(context, r.message, error: true);
    else
      _load();
  }

  Future<void> _printPass(int allocationId) async {
    if (pdfBusy) return;
    setState(() => pdfBusy = true);
    try {
      final result = await s.individualExamPassPdf(allocationId);
      if (!mounted) return;
      if (result is HallError) {
        _snack(context, result.message, error: true);
      } else {
        await _openPassPdf(
          context,
          (result as HallSuccess<PdfFileResult>).data,
          download: false,
          fallbackName: 'exam-pass-card.pdf',
        );
      }
    } finally {
      if (mounted) setState(() => pdfBusy = false);
    }
  }

  Future<void> _printAllPasses() async {
    final ids =
        b?.students
            .map((student) => student.id)
            .where((id) => id > 0)
            .toSet() ??
        <int>{};
    if (ids.isEmpty || pdfBusy) return;
    setState(() => pdfBusy = true);
    try {
      final result = await s.selectedExamPassesPdf(ids);
      if (!mounted) return;
      if (result is HallError) {
        _snack(context, result.message, error: true);
      } else {
        await _openPassPdf(
          context,
          (result as HallSuccess<PdfFileResult>).data,
          download: false,
          fallbackName: 'exam-pass-cards.pdf',
        );
      }
    } finally {
      if (mounted) setState(() => pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _page(
    context,
    embedded: false,
    title: 'Allocation Details',
    child: error != null
        ? Center(child: Text(error!))
        : b == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _card,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    Text('Exam: ${b!.exam}'),
                    Text('Academic Year: ${b!.academicYear}'),
                    Text('Level: ${b!.level}'),
                    Text('Class: ${b!.className}'),
                    Text('Mode: ${b!.mode}'),
                    Text('Shift: ${b!.shift}'),
                    Text('Created by: ${b!.createdBy}'),
                    Text('Status: ${b!.status}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...b!.students.map(
                (a) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(a.seat)),
                    title: Text(a.name),
                    subtitle: Text(
                      '${a.emis} · ${a.className} · ${a.hallName}',
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Print Pass',
                          onPressed: pdfBusy ? null : () => _printPass(a.id),
                          icon: const Icon(Icons.badge_outlined, color: _green),
                        ),
                        IconButton(
                          tooltip: 'Cancel student allocation',
                          onPressed: () => _cancelStudent(a.id),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    action: Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: pdfBusy ? null : _printAllPasses,
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print All Pass Cards'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final confirmed = await showAdminFeatureConfirmation(
              context,
              title: 'Cancel Allocation Batch?',
              message:
                  'All active student allocations in this batch will be cancelled.',
              confirmLabel: 'Cancel Batch',
              icon: Icons.cancel_outlined,
              confirmColor: Colors.red,
            );
            if (confirmed != true || !mounted) return;
            final r = await s.cancelBatch(widget.batchId);
            if (!mounted) return;
            if (r is HallError)
              _snack(context, r.message, error: true);
            else {
              _snack(context, 'Allocation cancelled.');
              _load();
            }
          },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Batch'),
        ),
      ],
    ),
  );
}

class HallReportsPage extends StatefulWidget {
  final bool embedBodyOnly;
  const HallReportsPage({super.key, this.embedBodyOnly = false});
  @override
  State<HallReportsPage> createState() => _HallReportsPageState();
}

class _HallReportsPageState extends State<HallReportsPage> {
  final s = ExamHallService();
  List<ExamHall> halls = [];
  List<AcademicYear> years = [];
  List<ExamModel> exams = [];
  List<ExamHallReportRow> rows = [];
  int? yearId, examId, hallId, shiftId;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _init();
    Future.microtask(() => context.read<ShiftsProvider>().ensureLoaded());
  }

  Future<void> _init() async {
    final r = await Future.wait([
      s.halls(),
      AcademicYearsService().list(),
      ExamsService().listExams(),
    ]);
    if (!mounted) return;
    setState(() {
      if (r[0] is HallSuccess<List<ExamHall>>)
        halls = (r[0] as HallSuccess<List<ExamHall>>).data;
      if (r[1] is AcademicYearSuccess<List<AcademicYear>>)
        years = (r[1] as AcademicYearSuccess<List<AcademicYear>>).data;
      if (r[2] is ExamSuccess<List<ExamModel>>)
        exams = (r[2] as ExamSuccess<List<ExamModel>>).data;
    });
  }

  Map<String, String> get q => {
    if (yearId != null) 'academic_year_id': '$yearId',
    if (examId != null) 'exam_id': '$examId',
    if (hallId != null) 'hall_id': '$hallId',
    if (shiftId != null) 'shift_id': '$shiftId',
  };
  Future<void> _load() async {
    setState(() => busy = true);
    final r = await s.report(q);
    if (!mounted) return;
    setState(() => busy = false);
    if (r is HallError)
      _snack(context, r.message, error: true);
    else
      setState(() => rows = (r as HallSuccess<List<ExamHallReportRow>>).data);
  }

  Future<void> _pdf(bool download) async {
    setState(() => busy = true);
    final r = await s.reportPdf(q, download: download);
    if (!mounted) return;
    setState(() => busy = false);
    if (r is HallError) {
      _snack(context, r.message, error: true);
      return;
    }
    final f = (r as HallSuccess<PdfFileResult>).data;
    if (download)
      await savePdfWithFeedback(
        context,
        bytes: f.bytes,
        filename: f.filename ?? 'exam-hall-report.pdf',
      );
    else
      await previewStudentPdf(f.bytes, f.filename ?? 'exam-hall-report.pdf');
  }

  Future<void> _passCards() async {
    if (yearId == null || examId == null) {
      _snack(context, 'Select an academic year and exam.', error: true);
      return;
    }
    setState(() => busy = true);
    try {
      final result = await s.filteredExamPassesPdf(q);
      if (!mounted) return;
      if (result is HallError) {
        _snack(context, result.message, error: true);
      } else {
        await _openPassPdf(
          context,
          (result as HallSuccess<PdfFileResult>).data,
          download: false,
          fallbackName: 'exam-pass-cards.pdf',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _summaryTile(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color ?? _navy,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hallMatches = hallId == null
        ? const <ExamHall>[]
        : halls.where((h) => h.id == hallId).toList();
    final selectedHallObj = hallMatches.isEmpty ? null : hallMatches.first;
    final shiftMatches = shiftId == null
        ? const <Shift>[]
        : context
              .watch<ShiftsProvider>()
              .shifts
              .where((s) => s.id == shiftId)
              .toList();
    final selectedShiftName = shiftMatches.isEmpty
        ? null
        : shiftMatches.first.name;
    return _page(
      context,
      embedded: widget.embedBodyOnly,
      title: 'Exam Hall Reports',
      subtitle: 'View and print examination hall assignments',
      headerAction: AdminPrimaryButton(
        label: 'Print Report',
        icon: Icons.print_outlined,
        onPressed: busy ? null : () => _pdf(false),
      ),
      child: ListView(
        children: [
          AdminFilterBar(
            filters: [
              AdminFilterDropdown<int>(
                label: 'Academic Year',
                value: yearId,
                items: years
                    .map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => yearId = v),
              ),
              AdminFilterDropdown<int>(
                label: 'Exam',
                value: examId,
                items: exams
                    .map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => examId = v),
              ),
              AdminFilterDropdown<int>(
                label: 'Hall',
                value: hallId,
                items: halls
                    .map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => hallId = v),
              ),
              AdminFilterDropdown<int?>(
                label: 'Shift',
                value: shiftId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Shifts'),
                  ),
                  ...context.watch<ShiftsProvider>().shifts.map(
                    (e) => DropdownMenuItem<int?>(
                      value: e.id,
                      child: Text(e.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => shiftId = v),
              ),
            ],
            actions: [
              AdminPrimaryButton(
                label: 'Generate Report',
                icon: Icons.search,
                onPressed: busy ? null : _load,
              ),
              AdminSecondaryButton(
                label: 'Preview PDF',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: busy ? null : () => _pdf(false),
              ),
              AdminSecondaryButton(
                label: 'Download PDF',
                icon: Icons.download,
                onPressed: busy ? null : () => _pdf(true),
              ),
              AdminSecondaryButton(
                label: 'Print Pass Cards',
                icon: Icons.badge_outlined,
                onPressed: busy ? null : _passCards,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (busy) const LinearProgressIndicator(),
          if (!busy && rows.isEmpty)
            AdminEmptyState(
              icon: Icons.summarize_outlined,
              title: 'No hall report yet',
              message: 'Choose filters above and generate the report.',
            ),
          if (rows.isNotEmpty) ...[
            if (selectedHallObj != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAdminBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedHallObj.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    _summaryTile('Capacity', '${selectedHallObj.capacity}'),
                    const SizedBox(width: 20),
                    _summaryTile('Allocated', '${rows.length}', color: _green),
                    const SizedBox(width: 20),
                    _summaryTile(
                      'Available',
                      '${(selectedHallObj.capacity - rows.length).clamp(0, selectedHallObj.capacity)}',
                    ),
                    if (selectedShiftName != null) ...[
                      const SizedBox(width: 20),
                      _summaryTile('Shift', selectedShiftName),
                    ],
                  ],
                ),
              ),
            if (kIsWeb || MediaQuery.sizeOf(context).width >= 760)
              AdminTableCard(
                columns: const [
                  AdminTableColumn('No.', flex: 1),
                  AdminTableColumn('Seat', flex: 1),
                  AdminTableColumn('Student Name', flex: 4),
                  AdminTableColumn('EMIS', flex: 2),
                  AdminTableColumn('Class', flex: 2),
                  AdminTableColumn('Level', flex: 2),
                  AdminTableColumn('Shift', flex: 2),
                  AdminTableColumn('Hall', flex: 2),
                ],
                rows: rows.indexed
                    .map(
                      (entry) => AdminTableRow(
                        flexes: const [1, 1, 4, 2, 2, 2, 2, 2],
                        cells: [
                          Text('${entry.$1 + 1}'),
                          Text(entry.$2.seat),
                          Text(entry.$2.name),
                          Text(entry.$2.emis),
                          Text(entry.$2.className),
                          Text(entry.$2.levelName),
                          Text(entry.$2.shiftName),
                          Text(entry.$2.hallName),
                        ],
                      ),
                    )
                    .toList(),
              )
            else
              ...rows.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: _card,
                  child: ListTile(
                    leading: CircleAvatar(child: Text(r.seat)),
                    title: Text(r.name),
                    subtitle: Text('${r.emis} · ${r.className}'),
                    trailing: Text(r.hallName),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
