import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kobac/services/marks_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminMarksScreen extends StatefulWidget {
  final bool openCreateOnLoad;

  const AdminMarksScreen({Key? key, this.openCreateOnLoad = false}) : super(key: key);

  @override
  State<AdminMarksScreen> createState() => _AdminMarksScreenState();
}

class _AdminMarksScreenState extends State<AdminMarksScreen> {
  int? _filterExamId;
  int? _filterClassId;
  int? _filterSubjectId;
  int? _filterStudentId;
  late Future<MarkResult<List<MarkModel>>> _marksFuture;
  List<ExamModel> _exams = [];
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<StudentModel> _students = [];
  List<TeacherModel> _teachers = [];
  bool _refDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRefData();
    _loadMarks();
  }

  Future<void> _loadRefData() async {
    final examsR = await ExamsService().listExams();
    final classesR = await ClassesService().listClasses();
    final subjectsR = await SubjectsService().listSubjects();
    final studentsR = await StudentsService().listStudents();
    final teachersR = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      if (examsR is ExamSuccess<List<ExamModel>>) _exams = examsR.data;
      if (classesR is ClassSuccess<List<ClassModel>>) _classes = classesR.data;
      if (subjectsR is SubjectSuccess<List<SubjectModel>>) _subjects = subjectsR.data;
      if (studentsR is StudentSuccess<List<StudentModel>>) _students = studentsR.data;
      if (teachersR is TeacherSuccess<List<TeacherModel>>) _teachers = teachersR.data;
      _refDataLoaded = true;
    });
    if (widget.openCreateOnLoad && mounted) _openAddMarks();
  }

  void _loadMarks() {
    setState(() {
      _marksFuture = MarksService().listMarks(
        examId: _filterExamId,
        classId: _filterClassId,
        subjectId: _filterSubjectId,
        studentId: _filterStudentId,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _filterExamId = null;
      _filterClassId = null;
      _filterSubjectId = null;
      _filterStudentId = null;
      _loadMarks();
    });
  }

  String _examName(int id) {
    for (final e in _exams) { if (e.id == id) return e.name; }
    return '—';
  }
  String _className(int id) {
    for (final c in _classes) { if (c.id == id) return c.name; }
    return '—';
  }
  String _subjectName(int id) {
    for (final s in _subjects) { if (s.id == id) return s.name; }
    return '—';
  }
  String _studentName(int id) {
    for (final s in _students) { if (s.id == id) return s.studentName; }
    return '—';
  }
  String _studentEmis(int id) {
    for (final s in _students) { if (s.id == id) return s.emisNumber; }
    return '—';
  }
  String _studentClass(int id) {
    for (final s in _students) {
      if (s.id == id) return s.classDisplayName;
    }
    return '—';
  }
  String _teacherName(int id) {
    if (id == 0) return '—';
    for (final t in _teachers) { if (t.id == id) return t.fullName; }
    return '—';
  }

  List<StudentModel> get _studentsFilteredByClass {
    if (_filterClassId == null) return _students;
    return _students.where((s) => s.classId == _filterClassId).toList();
  }

  Future<void> _openAddMarks() async {
    if (!_refDataLoaded) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddMarksDialog(
        exams: _exams,
        classes: _classes,
        subjects: _subjects,
        students: _students,
        teachers: _teachers,
        selectedClassId: _filterClassId,
        onSave: (payload) => _createMarkFromDialog(ctx, payload),
      ),
    );
    if (created == true && mounted) {
      _loadMarks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks saved'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<bool> _createMarkFromDialog(BuildContext ctx, Map<String, dynamic> payload) async {
    final result = await MarksService().createMark(payload);
    if (result is MarkSuccess) return true;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text((result as MarkError).message), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  Future<void> _openEditMark(MarkModel mark) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditMarksDialog(
        mark: mark,
        teachers: _teachers,
        onSave: (payload) => _updateMarkFromDialog(ctx, mark.id, payload),
      ),
    );
    if (updated == true && mounted) {
      _loadMarks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks updated'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<bool> _updateMarkFromDialog(BuildContext ctx, int id, Map<String, dynamic> payload) async {
    final result = await MarksService().updateMark(id, payload);
    if (result is MarkSuccess) return true;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text((result as MarkError).message), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  Future<void> _deleteMark(MarkModel mark) async {
    final studentName = _studentName(mark.studentId);
    final subjectName = _subjectName(mark.subjectId);
    final examName = _examName(mark.examId);
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete marks entry?',
      message: 'Delete this marks entry for $studentName / $subjectName / $examName?',
    );
    if (confirmed != true) return;
    final result = await MarksService().deleteMark(mark.id);
    if (!mounted) return;
    if (result is MarkSuccess) {
      _loadMarks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks entry deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as MarkError).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('Marks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                    ),
                    _AddButton(onPressed: _openAddMarks),
                  ],
                ),
              ),
              if (_refDataLoaded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FormCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _FilterDropdown<int?>(
                                value: _filterExamId,
                                label: 'Exam',
                                items: [
                                  const DropdownMenuItem<int?>(value: null, child: Text('All')),
                                  ..._exams.map((e) => DropdownMenuItem<int?>(value: e.id, child: Text(e.name))),
                                ],
                                onChanged: (v) => setState(() { _filterExamId = v; _loadMarks(); }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FilterDropdown<int?>(
                                value: _filterClassId,
                                label: 'Class',
                                items: [
                                  const DropdownMenuItem<int?>(value: null, child: Text('All')),
                                  ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                                ],
                                onChanged: (v) => setState(() { _filterClassId = v; _loadMarks(); }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _FilterDropdown<int?>(
                                value: _filterSubjectId,
                                label: 'Subject',
                                items: [
                                  const DropdownMenuItem<int?>(value: null, child: Text('All')),
                                  ..._subjects.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                                ],
                                onChanged: (v) => setState(() { _filterSubjectId = v; _loadMarks(); }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FilterDropdown<int?>(
                                value: _filterStudentId,
                                label: 'Student',
                                items: [
                                  const DropdownMenuItem<int?>(value: null, child: Text('All')),
                                  ..._studentsFilteredByClass.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text('${s.studentName} (${s.emisNumber})'))),
                                ],
                                onChanged: (v) => setState(() { _filterStudentId = v; _loadMarks(); }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadMarks(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<MarkResult<List<MarkModel>>>(
                    future: _marksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(
                                  userFriendlyMessage(snapshot.error!, null, 'AdminMarksScreen'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(onPressed: _loadMarks, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                              ],
                            ),
                          ),
                        );
                      }
                      final result = snapshot.data;
                      if (result == null) return const Center(child: Text('No data'));
                      if (result is MarkError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(result.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                TextButton.icon(onPressed: _loadMarks, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                              ],
                            ),
                          ),
                        );
                      }
                      final marks = (result as MarkSuccess<List<MarkModel>>).data;
                      marks.sort((a, b) {
                        if (a.createdAt != null && b.createdAt != null) return b.createdAt!.compareTo(a.createdAt!);
                        return b.id.compareTo(a.id);
                      });
                      if (marks.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.grade_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('No marks entries', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                  const SizedBox(height: 16),
                                  TextButton.icon(onPressed: _openAddMarks, icon: const Icon(Icons.add_rounded), label: const Text('Add Marks Entry')),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: marks.length,
                        itemBuilder: (context, index) {
                          final mark = marks[index];
                          final pct = mark.maxMarks > 0 ? (mark.marksObtained / mark.maxMarks * 100).toStringAsFixed(1) : '—';
                          return _MarkCard(
                            mark: mark,
                            studentName: _studentName(mark.studentId),
                            emis: _studentEmis(mark.studentId),
                            className: _studentClass(mark.studentId),
                            subjectName: _subjectName(mark.subjectId),
                            examName: _examName(mark.examId),
                            teacherName: _teacherName(mark.teacherId ?? 0),
                            percentage: pct,
                            onEdit: () => _openEditMark(mark),
                            onDelete: () => _deleteMark(mark),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  const _FilterDropdown({required this.value, required this.label, required this.items, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}

class _MarkCard extends StatelessWidget {
  final MarkModel mark;
  final String studentName;
  final String emis;
  final String className;
  final String subjectName;
  final String examName;
  final String teacherName;
  final String percentage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MarkCard({
    required this.mark,
    required this.studentName,
    required this.emis,
    required this.className,
    required this.subjectName,
    required this.examName,
    required this.teacherName,
    required this.percentage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.grade_rounded, color: kPrimaryBlue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                  Text('$subjectName · $examName', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  Text('${mark.marksObtained} / ${mark.maxMarks} ($percentage%)', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  if (mark.grade != null && mark.grade!.isNotEmpty) Text('Grade: ${mark.grade}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryGreen)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 22, color: kPrimaryGreen), onPressed: onEdit, tooltip: 'Edit'),
            IconButton(icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]), onPressed: onDelete, tooltip: 'Delete'),
          ],
        ),
      ),
    );
  }
}

class _AddMarksDialog extends StatefulWidget {
  final List<ExamModel> exams;
  final List<ClassModel> classes;
  final List<SubjectModel> subjects;
  final List<StudentModel> students;
  final List<TeacherModel> teachers;
  final int? selectedClassId;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;

  const _AddMarksDialog({
    required this.exams,
    required this.classes,
    required this.subjects,
    required this.students,
    required this.teachers,
    this.selectedClassId,
    required this.onSave,
  });

  @override
  State<_AddMarksDialog> createState() => _AddMarksDialogState();
}

class _AddMarksDialogState extends State<_AddMarksDialog> {
  int? _examId;
  int? _classId;
  int? _studentId;
  int? _subjectId;
  int? _teacherId;
  final _marksObtained = TextEditingController(text: '0');
  final _maxMarks = TextEditingController(text: '100');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _classId = widget.selectedClassId;
  }

  @override
  void dispose() {
    _marksObtained.dispose();
    _maxMarks.dispose();
    super.dispose();
  }

  List<StudentModel> get _studentsForClass {
    if (_classId == null) return widget.students;
    final filtered = widget.students.where((s) => s.classId == _classId).toList();
    // If no students match the class (e.g. API doesn't return class_id in list), show all so user can still select
    return filtered.isEmpty ? widget.students : filtered;
  }

  Future<void> _submit() async {
    if (_examId == null || _studentId == null || _subjectId == null || _teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select exam, student, subject and teacher'), backgroundColor: Colors.red),
      );
      return;
    }
    final obtained = int.tryParse(_marksObtained.text.trim()) ?? 0;
    final max = int.tryParse(_maxMarks.text.trim()) ?? 100;
    if (obtained < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks obtained must be >= 0'), backgroundColor: Colors.red));
      return;
    }
    if (max <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max marks must be > 0'), backgroundColor: Colors.red));
      return;
    }
    if (obtained > max) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks obtained cannot exceed max marks'), backgroundColor: Colors.red));
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onSave({
      'exam_id': _examId,
      'student_id': _studentId,
      'subject_id': _subjectId,
      'teacher_id': _teacherId,
      'marks_obtained': obtained,
      'max_marks': max,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Marks Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              const SizedBox(height: 20),
              Select3D<int?>(
                value: _examId,
                label: 'Exam',
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Select exam')), ...widget.exams.map((e) => DropdownMenuItem<int?>(value: e.id, child: Text(e.name)))],
                onChanged: (v) => setState(() => _examId = v),
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _classId,
                label: 'Class (filter)',
                items: [const DropdownMenuItem<int?>(value: null, child: Text('All')), ...widget.classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)))],
                onChanged: (v) => setState(() { _classId = v; _studentId = null; }),
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _studentId,
                label: 'Student',
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Select student')), ..._studentsForClass.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text('${s.studentName} (${s.emisNumber})')))],
                onChanged: (v) => setState(() => _studentId = v),
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _subjectId,
                label: 'Subject',
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Select subject')), ...widget.subjects.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name)))],
                onChanged: (v) => setState(() => _subjectId = v),
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _teacherId,
                label: 'Teacher',
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Select teacher')), ...widget.teachers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)))],
                onChanged: (v) => setState(() => _teacherId = v),
              ),
              const SizedBox(height: 16),
              Input3D(
                controller: _marksObtained,
                label: 'Marks obtained',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Input3D(
                controller: _maxMarks,
                label: 'Max marks',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: PrimaryButton3D(label: 'Save', onPressed: _submit, loading: _submitting, height: 48)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditMarksDialog extends StatefulWidget {
  final MarkModel mark;
  final List<TeacherModel> teachers;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;

  const _EditMarksDialog({required this.mark, required this.teachers, required this.onSave});

  @override
  State<_EditMarksDialog> createState() => _EditMarksDialogState();
}

class _EditMarksDialogState extends State<_EditMarksDialog> {
  late TextEditingController _marksObtained;
  late TextEditingController _maxMarks;
  int? _teacherId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _marksObtained = TextEditingController(text: widget.mark.marksObtained.toString());
    _maxMarks = TextEditingController(text: widget.mark.maxMarks.toString());
    _teacherId = widget.mark.teacherId;
  }

  @override
  void dispose() {
    _marksObtained.dispose();
    _maxMarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final obtained = int.tryParse(_marksObtained.text.trim()) ?? 0;
    final max = int.tryParse(_maxMarks.text.trim()) ?? 100;
    if (obtained < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks obtained must be >= 0'), backgroundColor: Colors.red));
      return;
    }
    if (max <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max marks must be > 0'), backgroundColor: Colors.red));
      return;
    }
    if (obtained > max) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks obtained cannot exceed max marks'), backgroundColor: Colors.red));
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final payload = <String, dynamic>{'marks_obtained': obtained, 'max_marks': max};
    if (_teacherId != null) payload['teacher_id'] = _teacherId;
    final ok = await widget.onSave(payload);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit Marks Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            const SizedBox(height: 20),
            Input3D(
              controller: _marksObtained,
              label: 'Marks obtained',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Input3D(
              controller: _maxMarks,
              label: 'Max marks',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Select3D<int?>(
              value: _teacherId,
              label: 'Teacher',
              items: [const DropdownMenuItem<int?>(value: null, child: Text('Unchanged')), ...widget.teachers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)))],
              onChanged: (v) => setState(() => _teacherId = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: PrimaryButton3D(label: 'Save', onPressed: _submit, loading: _submitting, height: 48)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}
