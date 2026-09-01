import 'package:flutter/material.dart';
import 'package:kobac/services/class_subjects_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/school_admin/widgets/exam_subject_controls.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _borderGray = Color(0xFFE2E7ED);
const _subtleText = Color(0xFF64748B);

/// Opens the centered "Add Subjects" dialog for one class. Loads the full
/// school subject catalog itself — the caller (the normal Class Subjects
/// page) never has to — and only offers subjects not already in
/// [alreadyAssignedSubjectIds], preventing duplicates. Returns `true` if at
/// least one subject was successfully assigned, so the caller knows to
/// reload its class-subject list.
Future<bool?> showAddClassSubjectsDialog(
  BuildContext context, {
  required int classId,
  required String className,
  required Set<int> alreadyAssignedSubjectIds,
}) async {
  final width = MediaQuery.sizeOf(context).width;
  final maxWidth = width < 700 ? width - 32 : 520.0;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _AddSubjectsForm(
          classId: classId,
          className: className,
          alreadyAssignedSubjectIds: alreadyAssignedSubjectIds,
        ),
      ),
    ),
  );
}

class _AddSubjectsForm extends StatefulWidget {
  final int classId;
  final String className;
  final Set<int> alreadyAssignedSubjectIds;

  const _AddSubjectsForm({
    required this.classId,
    required this.className,
    required this.alreadyAssignedSubjectIds,
  });

  @override
  State<_AddSubjectsForm> createState() => _AddSubjectsFormState();
}

class _AddSubjectsFormState extends State<_AddSubjectsForm> {
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  List<SubjectModel> _availableSubjects = [];
  final Set<int> _selectedIds = {};
  final Map<int, bool> _examStatusBySubjectId = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await SubjectsService().listSubjects();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is SubjectSuccess<List<SubjectModel>>) {
        _availableSubjects = result.data
            .where((s) => !widget.alreadyAssignedSubjectIds.contains(s.id))
            .toList();
      } else {
        _loadError = 'Unable to load subjects. Please try again.';
      }
    });
  }

  Future<void> _save() async {
    if (_selectedIds.isEmpty || _saving) return;
    setState(() => _saving = true);
    final selections = _selectedIds
        .map(
          (id) => (
            subjectId: id,
            subjectName: _availableSubjects
                .firstWhere((s) => s.id == id)
                .name,
            isExamSubject: _examStatusBySubjectId[id] ?? true,
          ),
        )
        .toList();

    final result = await ClassSubjectsService().addSubjectsToClass(
      classId: widget.classId,
      selections: selections,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result is ClassSubjectError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final outcome = (result as ClassSubjectSuccess<AddSubjectsOutcome>).data;
    final addedCount = selections.length - outcome.failedSubjectNames.length;
    if (outcome.failedSubjectNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$addedCount subject${addedCount == 1 ? '' : 's'} added to ${widget.className}.',
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Subjects added, but the Non-Exam status could not be saved for '
            '${outcome.failedSubjectNames.join(', ')}. You can change this '
            'from the subject list.',
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          20,
          22,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.playlist_add_rounded, color: _blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Subjects',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _blue,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Assign subjects to ${widget.className}.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _subtleText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBody(),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _green.withOpacity(0.5),
                  ),
                  onPressed: (_selectedIds.isEmpty || _saving) ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Add Subjects'
                        : 'Add ${_selectedIds.length} Subject${_selectedIds.length == 1 ? '' : 's'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(_loadError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_availableSubjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          border: Border.all(color: _borderGray),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'All school subjects are already assigned to this class.',
          style: TextStyle(color: _subtleText),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _availableSubjects
              .map((subject) => _buildSubjectRow(subject))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSubjectRow(SubjectModel subject) {
    final checked = _selectedIds.contains(subject.id);
    final isExam = _examStatusBySubjectId[subject.id] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: checked ? _blue.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: checked ? _blue.withOpacity(0.3) : _borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                value: checked,
                activeColor: _green,
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(subject.id);
                            _examStatusBySubjectId.putIfAbsent(subject.id, () => true);
                          } else {
                            _selectedIds.remove(subject.id);
                          }
                        });
                      },
              ),
              Expanded(
                child: Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (checked)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 10, top: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ExamSubjectToggle(
                  isExamSubject: isExam,
                  enabled: !_saving,
                  onChanged: (value) =>
                      setState(() => _examStatusBySubjectId[subject.id] = value),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
