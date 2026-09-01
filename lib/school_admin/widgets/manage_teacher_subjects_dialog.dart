import 'package:flutter/material.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teacher_subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const _navy = Color(0xFF023471);
const _green = Color(0xFF5AB04B);

Future<bool?> showManageTeacherSubjectsDialog(
  BuildContext context, {
  required TeacherModel teacher,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ManageTeacherSubjectsDialog(teacher: teacher),
  );
}

class _ManageTeacherSubjectsDialog extends StatefulWidget {
  final TeacherModel teacher;
  const _ManageTeacherSubjectsDialog({required this.teacher});

  @override
  State<_ManageTeacherSubjectsDialog> createState() =>
      _ManageTeacherSubjectsDialogState();
}

class _ManageTeacherSubjectsDialogState
    extends State<_ManageTeacherSubjectsDialog> {
  List<SubjectModel> _catalog = [];
  Set<int> _selected = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      SubjectsService().listSubjects(),
      TeacherSubjectsService().getSubjects(widget.teacher.id),
    ]);
    if (!mounted) return;
    final catalog = values[0];
    final configured = values[1];
    setState(() {
      _loading = false;
      if (catalog is SubjectSuccess<List<SubjectModel>>) {
        _catalog = catalog.data;
      } else {
        _error = (catalog as SubjectError).message;
      }
      if (configured is TeacherSubjectsSuccess<TeacherSubjectsConfig>) {
        _selected = configured.data.subjects.map((s) => s.id).toSet();
      } else {
        _error = (configured as TeacherSubjectsError).message;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await TeacherSubjectsService().replaceSubjects(
      widget.teacher.id,
      _selected,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is TeacherSubjectsSuccess<TeacherSubjectsConfig>) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = (result as TeacherSubjectsError).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: FormCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _navy.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: _navy),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Teaching Subjects',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.teacher.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5EAF1)),
              Flexible(
                child: _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(color: _green),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Select every subject this teacher teaches. This configuration is not tied to an academic year.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_catalog.isEmpty && _error == null)
                            const Text(
                              'No subjects are available in the school catalog.',
                            ),
                          ..._catalog.map(
                            (subject) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _selected.contains(subject.id)
                                    ? _green.withValues(alpha: .07)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selected.contains(subject.id)
                                      ? _green.withValues(alpha: .45)
                                      : const Color(0xFFE5EAF1),
                                ),
                              ),
                              child: CheckboxListTile(
                                value: _selected.contains(subject.id),
                                activeColor: _green,
                                title: Text(
                                  subject.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onChanged: _saving
                                    ? null
                                    : (checked) => setState(() {
                                        if (checked == true) {
                                          _selected.add(subject.id);
                                        } else {
                                          _selected.remove(subject.id);
                                        }
                                      }),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const Divider(height: 1, color: Color(0xFFE5EAF1)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton3D(
                        label: 'Save Subjects',
                        onPressed: _loading || _error != null ? null : _save,
                        loading: _saving,
                        height: 48,
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
}
