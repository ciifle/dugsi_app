import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftGreen = Color(0xFFEDF7EB);
const Color kDarkBlue = Color(0xFF01255C);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);

class TeacherMarksScreen extends StatefulWidget {
  const TeacherMarksScreen({Key? key}) : super(key: key);

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen> {
  List<TeacherAssignmentModel> _assignments = [];
  int? _filterClassId;
  int? _filterSubjectId;
  int? _filterExamId;
  List<TeacherMarkModel> _marks = [];
  bool _loading = false;
  String? _error;

  List<({int id, String name})> get _uniqueClasses {
    final seen = <int>{};
    final out = <({int id, String name})>[];
    for (final a in _assignments) {
      if (seen.add(a.classId)) {
        out.add((id: a.classId, name: a.classDisplayName));
      }
    }
    return out;
  }

  List<({int id, String name})> get _subjectsForSelectedClass {
    if (_filterClassId == null) return [];
    final out = <({int id, String name})>[];
    final seen = <int>{};
    for (final a in _assignments) {
      if (a.classId == _filterClassId! && seen.add(a.subjectId)) {
        out.add((id: a.subjectId, name: a.subjectName.isEmpty ? 'Subject ${a.subjectId}' : a.subjectName));
      }
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final result = await TeacherService().listAssignments();
    if (!mounted) return;
    setState(() {
      if (result is TeacherSuccess<List<TeacherAssignmentModel>>) {
        _assignments = result.data;
        if (_assignments.isNotEmpty && _filterClassId == null) {
          _filterClassId = _assignments.first.classId;
          _filterSubjectId = _assignments.first.subjectId;
        }
        _loadMarks();
      }
    });
  }

  Future<void> _loadMarks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await TeacherService().listMarks(
      examId: _filterExamId,
      classId: _filterClassId,
      subjectId: _filterSubjectId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is TeacherSuccess<List<TeacherMarkModel>>) {
        _marks = result.data;
        _error = null;
      } else {
        _marks = [];
        _error = (result as TeacherError).message;
      }
    });
  }

  void _showAddMark() async {
    if (_filterClassId == null) return;
    final studentsResult = await TeacherService().listStudentsByClass(_filterClassId!);
    if (!mounted) return;
    List<TeacherStudentModel> students = [];
    if (studentsResult is TeacherSuccess<List<TeacherStudentModel>>) {
      students = studentsResult.data;
    }
    final subjects = _subjectsForSelectedClass;
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subject selected'), backgroundColor: kErrorColor, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (ctx) => _AddMarkDialog(
        classId: _filterClassId!,
        className: _uniqueClasses.firstWhere((c) => c.id == _filterClassId, orElse: () => (id: _filterClassId!, name: 'Unassigned')).name,
        subjects: subjects,
        students: students,
        onSaved: () {
          _loadMarks();
        },
      ),
    );
  }

  void _showEditMark(TeacherMarkModel mark) async {
    await showDialog(
      context: context,
      builder: (ctx) => _EditMarkDialog(
        mark: mark,
        onSaved: () => _loadMarks(),
      ),
    );
  }

  void _confirmDelete(TeacherMarkModel mark) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete mark?'),
        content: Text(
          'Marks ${mark.marksObtained}/${mark.maxMarks} for student ${mark.studentId} will be removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kErrorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await TeacherService().deleteMark(mark.id);
    if (!mounted) return;
    if (result is TeacherSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mark deleted'), backgroundColor: kPrimaryGreen, behavior: SnackBarBehavior.floating),
      );
      _loadMarks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as TeacherError).message), backgroundColor: kErrorColor, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      appBar: AppBar(
        title: const Text('Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAssignments();
        },
        color: kPrimaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilters(),
              const SizedBox(height: 16),
              if (_error != null) _buildErrorCard(),
              if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: kPrimaryBlue))),
              if (!_loading && _error == null && _marks.isEmpty) _buildEmpty(),
              if (!_loading && _error == null && _marks.isNotEmpty) ..._marks.map((m) => _MarkTile(mark: m, onEdit: () => _showEditMark(m), onDelete: () => _confirmDelete(m))),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _filterClassId == null ? null : _showAddMark,
        backgroundColor: kPrimaryGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add marks'),
      ),
    );
  }

  Widget _buildFilters() {
    final classes = _uniqueClasses;
    final subjects = _subjectsForSelectedClass;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _filterClassId,
            decoration: InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [const DropdownMenuItem<int>(value: null, child: Text('All classes')), ...classes.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))],
            onChanged: (v) {
              setState(() {
                _filterClassId = v;
                _filterSubjectId = null;
                if (v != null) {
                  final first = _assignments.cast<TeacherAssignmentModel?>().firstWhere(
                        (e) => e?.classId == v,
                        orElse: () => null,
                      );
                  if (first != null) _filterSubjectId = first.subjectId;
                }
                _loadMarks();
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _filterSubjectId,
            decoration: InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('All subjects')),
              ...subjects.map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name))),
            ],
            onChanged: (v) {
              setState(() {
                _filterSubjectId = v;
                _loadMarks();
              });
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: _filterExamId?.toString() ?? '',
            decoration: InputDecoration(
              labelText: 'Exam ID (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            keyboardType: TextInputType.number,
            onChanged: (s) {
              final id = int.tryParse(s);
              setState(() {
                _filterExamId = (id != null && id > 0) ? id : null;
                _loadMarks();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kErrorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kErrorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kErrorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(_error ?? '', style: const TextStyle(color: kTextPrimary, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.assignment_rounded, size: 56, color: kTextSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          const Text('No marks found for selected filters', style: TextStyle(fontSize: 16, color: kTextPrimary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MarkTile extends StatelessWidget {
  final TeacherMarkModel mark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MarkTile({required this.mark, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final studentLabel = mark.studentName?.isNotEmpty == true ? mark.studentName! : 'Student ${mark.studentId}';
    final examLabel = mark.examName?.isNotEmpty == true ? mark.examName! : 'Exam ${mark.examId}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(examLabel, style: TextStyle(fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ),
          Text('${mark.marksObtained}/${mark.maxMarks}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kPrimaryBlue)),
          if (mark.grade != null && mark.grade!.isNotEmpty) ...[const SizedBox(width: 8), Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: kSoftGreen, borderRadius: BorderRadius.circular(8)),
            child: Text(mark.grade!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryGreen)),
          )],
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.edit_rounded, size: 20), onPressed: onEdit, color: kPrimaryBlue),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20), onPressed: onDelete, color: kErrorColor),
        ],
      ),
    );
  }
}

class _AddMarkDialog extends StatefulWidget {
  final int classId;
  final String className;
  final List<({int id, String name})> subjects;
  final List<TeacherStudentModel> students;
  final VoidCallback onSaved;

  const _AddMarkDialog({required this.classId, required this.className, required this.subjects, required this.students, required this.onSaved});

  @override
  State<_AddMarkDialog> createState() => _AddMarkDialogState();
}

class _AddMarkDialogState extends State<_AddMarkDialog> {
  int? _subjectId;
  int? _studentId;
  int? _examId;
  final _studentIdController = TextEditingController(text: '');
  final _marksController = TextEditingController(text: '');
  final _maxController = TextEditingController(text: '100');
  bool _saving = false;
  bool get _hasStudentList => widget.students.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) _subjectId = widget.subjects.first.id;
    if (widget.students.isNotEmpty) _studentId = widget.students.first.id;
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _marksController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  int? _resolveStudentId() {
    if (_hasStudentList) return _studentId;
    final s = _studentIdController.text.trim();
    if (s.isEmpty) return null;
    final id = int.tryParse(s);
    return (id != null && id > 0) ? id : null;
  }

  Future<void> _submit() async {
    final resolvedStudentId = _resolveStudentId();
    if (_subjectId == null || resolvedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hasStudentList ? 'Select student' : 'Enter a valid Student ID'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final examId = _examId ?? 0;
    if (examId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Exam ID'), backgroundColor: kErrorColor, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final marks = num.tryParse(_marksController.text);
    final max = num.tryParse(_maxController.text) ?? 100;
    if (marks == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter marks obtained'), backgroundColor: kErrorColor, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await TeacherService().createMark(
      examId: examId,
      studentId: resolvedStudentId,
      subjectId: _subjectId!,
      marksObtained: marks,
      maxMarks: max,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is TeacherSuccess) {
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks saved'), backgroundColor: kPrimaryGreen, behavior: SnackBarBehavior.floating),
      );
    } else {
      final err = result as TeacherError;
      if (err.statusCode == 409) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Marks already exist'),
            content: const Text('Marks already exist for this exam/student/subject. Edit instead.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message), backgroundColor: kErrorColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add marks'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Class: ${widget.className}', style: TextStyle(fontSize: 14, color: kTextSecondary)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _subjectId,
              decoration: InputDecoration(labelText: 'Subject', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: widget.subjects.map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _subjectId = v),
            ),
            const SizedBox(height: 10),
            if (_hasStudentList)
              DropdownButtonFormField<int>(
                value: _studentId,
                decoration: InputDecoration(labelText: 'Student', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: widget.students.map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name ?? '${s.emisNumber ?? s.id}'))).toList(),
                onChanged: (v) => setState(() => _studentId = v),
              )
            else ...[
              TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'Enter student ID',
                  helperText: 'Student list not available. Enter the student ID from your class.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              initialValue: _examId?.toString() ?? '',
              decoration: InputDecoration(labelText: 'Exam ID', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.number,
              onChanged: (s) => setState(() => _examId = int.tryParse(s)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _marksController,
              decoration: InputDecoration(labelText: 'Marks obtained', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _maxController,
              decoration: InputDecoration(labelText: 'Max marks', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }
}

class _EditMarkDialog extends StatefulWidget {
  final TeacherMarkModel mark;
  final VoidCallback onSaved;

  const _EditMarkDialog({required this.mark, required this.onSaved});

  @override
  State<_EditMarkDialog> createState() => _EditMarkDialogState();
}

class _EditMarkDialogState extends State<_EditMarkDialog> {
  late TextEditingController _marksController;
  late TextEditingController _maxController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _marksController = TextEditingController(text: widget.mark.marksObtained.toString());
    _maxController = TextEditingController(text: widget.mark.maxMarks.toString());
  }

  @override
  void dispose() {
    _marksController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final marks = num.tryParse(_marksController.text);
    final max = num.tryParse(_maxController.text) ?? 100;
    if (marks == null) return;
    setState(() => _saving = true);
    final result = await TeacherService().updateMark(widget.mark.id, marksObtained: marks, maxMarks: max);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is TeacherSuccess) {
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks updated'), backgroundColor: kPrimaryGreen, behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as TeacherError).message), backgroundColor: kErrorColor, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit marks'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Student ID: ${widget.mark.studentId}', style: TextStyle(fontSize: 14, color: kTextSecondary)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _marksController,
            decoration: InputDecoration(labelText: 'Marks obtained', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _maxController,
            decoration: InputDecoration(labelText: 'Max marks', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update'),
        ),
      ],
    );
  }
}
