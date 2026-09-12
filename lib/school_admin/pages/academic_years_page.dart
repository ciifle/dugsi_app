import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/school_admin/widgets/dependency_delete_dialog.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _background = Color(0xFFF0F3F7);

class AcademicYearsPage extends StatefulWidget {
  final bool embedBodyOnly;
  const AcademicYearsPage({super.key, this.embedBodyOnly = false});

  @override
  State<AcademicYearsPage> createState() => _AcademicYearsPageState();
}

class _AcademicYearsPageState extends State<AcademicYearsPage> {
  bool _deleteDialogOpen = false;

  Future<void> _delete(AcademicYear year) async {
    if (_deleteDialogOpen) return;
    final provider = context.read<AcademicYearsProvider>();
    setState(() => _deleteDialogOpen = true);
    try {
      final deleted = await showAdminDeletionFlow(
        context,
        kind: DeleteItemKind.academicYear,
        id: year.id,
        name: year.name,
        onDeleted: (_) async {
          provider.removeDeletedYear(year.id);
          await provider.refresh();
        },
      );
      if (!mounted || deleted != true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic year deleted successfully.'),
          backgroundColor: _green,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleteDialogOpen = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AcademicYearsProvider>().ensureLoaded(),
    );
  }

  Future<void> _create() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _AcademicYearDialog(),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic year created'),
          backgroundColor: _green,
        ),
      );
    }
  }

  Future<void> _edit(AcademicYear year) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AcademicYearDialog(existing: year),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic year updated successfully.'),
          backgroundColor: _green,
        ),
      );
    }
  }

  Future<void> _activate(AcademicYear year) async {
    final confirmed = await showAdminFeatureConfirmation(
      context,
      title: 'Activate academic year?',
      message: 'Activate ${year.name} as the current academic year?',
      confirmLabel: 'Activate',
      icon: Icons.calendar_month_rounded,
    );
    if (confirmed != true || !mounted) return;
    final result = await context.read<AcademicYearsProvider>().activate(
      year.id,
    );
    if (!mounted) return;
    final message = result is AcademicYearError
        ? result.message
        : '${year.name} is now active';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result is AcademicYearError ? Colors.red : _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    final content = RefreshIndicator(
      onRefresh: provider.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  if (!widget.embedBodyOnly) ...[
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: _blue),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Expanded(
                    child: Text(
                      'Academic Years',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _blue,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: provider.submitting || _deleteDialogOpen
                        ? null
                        : _create,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New year'),
                    style: FilledButton.styleFrom(backgroundColor: _green),
                  ),
                ],
              ),
            ),
          ),
          if (provider.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.error != null && provider.years.isEmpty)
            SliverFillRemaining(
              child: _Message(
                icon: Icons.error_outline_rounded,
                text: provider.error!,
                action: TextButton(
                  onPressed: provider.refresh,
                  child: const Text('Retry'),
                ),
              ),
            )
          else if (provider.years.isEmpty)
            const SliverFillRemaining(
              child: _Message(
                icon: Icons.calendar_month_outlined,
                text: 'No academic years yet',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList.separated(
                itemCount: provider.years.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final year = provider.years[index];
                  return _YearCard(
                    year: year,
                    busy: provider.submitting || _deleteDialogOpen,
                    onEdit: () => _edit(year),
                    onActivate: () => _activate(year),
                    onDelete: () => _delete(year),
                  );
                },
              ),
            ),
        ],
      ),
    );
    if (widget.embedBodyOnly)
      return ColoredBox(color: _background, child: content);
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(child: content),
    );
  }
}

class _YearCard extends StatelessWidget {
  final AcademicYear year;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onActivate;
  final VoidCallback onDelete;
  const _YearCard({
    required this.year,
    required this.busy,
    required this.onEdit,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(.10),
            blurRadius: 24,
            offset: const Offset(8, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8EEF5),
                child: Icon(Icons.calendar_month_rounded, color: _blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      year.startDate == null || year.endDate == null
                          ? 'Dates unavailable'
                          : '${format.format(year.startDate!)} — ${format.format(year.endDate!)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: Icon(
                  year.isActive ? Icons.check_circle : Icons.circle_outlined,
                  size: 15,
                  color: year.isActive ? _green : Colors.grey,
                ),
                label: Text(year.isActive ? 'Active' : 'Inactive'),
                labelPadding: const EdgeInsets.only(right: 4),
                backgroundColor: year.isActive
                    ? _green.withOpacity(.12)
                    : Colors.grey.shade100,
                side: BorderSide.none,
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              if (!year.isActive)
                OutlinedButton(
                  onPressed: busy ? null : onActivate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: _blue),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Activate'),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                  side: const BorderSide(color: Color(0xFFB42318)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const _Message({required this.icon, required this.text, this.action});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 46, color: Colors.grey),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        if (action != null) action!,
      ],
    ),
  );
}

class _AcademicYearDialog extends StatefulWidget {
  final AcademicYear? existing;
  const _AcademicYearDialog({this.existing});
  @override
  State<_AcademicYearDialog> createState() => _AcademicYearDialogState();
}

class _AcademicYearDialogState extends State<_AcademicYearDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  DateTime? _start;
  DateTime? _end;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _start = widget.existing?.startDate;
    _end = widget.existing?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: (start ? _start : _end) ?? DateTime.now(),
    );
    if (value != null) setState(() => start ? _start = value : _end = value);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start and end dates are required')),
      );
      return;
    }
    if (!_start!.isBefore(_end!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date must be before end date.')),
      );
      return;
    }
    final provider = context.read<AcademicYearsProvider>();
    final result = _isEdit
        ? await provider.update(
            id: widget.existing!.id,
            name: _name.text,
            start: _start!,
            end: _end!,
          )
        : await provider.create(name: _name.text, start: _start!, end: _end!);
    if (!mounted) return;
    if (result is AcademicYearError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AcademicYearsProvider>().submitting;
    final date = DateFormat('dd MMM yyyy');
    return AdminFeatureDialog(
      title: _isEdit ? 'Edit Academic Year' : 'New academic year',
      onClose: busy ? () {} : () => Navigator.pop(context),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isEdit) ...[
              Text(
                'Update the academic year name and dates.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: _isEdit ? 'Academic Year Name *' : 'Name',
                hintText: '2026-2027',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isEdit ? 'Start Date *' : 'Start date'),
              subtitle: Text(
                _start == null ? 'Select date' : date.format(_start!),
              ),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: busy ? null : () => _pick(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isEdit ? 'End Date *' : 'End date'),
              subtitle: Text(_end == null ? 'Select date' : date.format(_end!)),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: busy ? null : () => _pick(false),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      minimumSize: const Size(0, 48),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEdit ? 'Save Changes' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
