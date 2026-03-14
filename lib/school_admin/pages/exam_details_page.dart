import 'package:flutter/material.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/admin_marks_screen.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class _ExamDetailData {
  final ExamResult<ExamModel> examResult;
  final List<ClassModel> classes;
  final List<SubjectModel> subjects;
  _ExamDetailData({required this.examResult, required this.classes, required this.subjects});
}

/// Exam detail page — loads exam by id and shows name, class, subject, date.
/// Matches app design: cards, spacing, typography, action buttons.
class ExamDetailsPage extends StatefulWidget {
  final int examId;

  const ExamDetailsPage({Key? key, required this.examId}) : super(key: key);

  @override
  State<ExamDetailsPage> createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends State<ExamDetailsPage> {
  late Future<_ExamDetailData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadExamWithRefData();
  }

  /// Load exam and lookup data together so class/subject names are available when we render.
  Future<_ExamDetailData> _loadExamWithRefData() async {
    final examFuture = ExamsService().getExam(widget.examId);
    final classesR = await ClassesService().listClasses();
    final subjectsR = await SubjectsService().listSubjects();
    final examResult = await examFuture;
    if (!mounted) return _ExamDetailData(examResult: examResult, classes: [], subjects: []);
    final classes = classesR is ClassSuccess<List<ClassModel>> ? classesR.data : <ClassModel>[];
    final subjects = subjectsR is SubjectSuccess<List<SubjectModel>> ? subjectsR.data : <SubjectModel>[];
    return _ExamDetailData(examResult: examResult, classes: classes, subjects: subjects);
  }

  String _className(List<ClassModel> classes, int? id) {
    if (id == null || id <= 0) return '—';
    for (final c in classes) { if (c.id == id) return c.name; }
    return '—';
  }

  String _subjectName(List<SubjectModel> subjects, int? id) {
    if (id == null || id <= 0) return '—';
    for (final s in subjects) { if (s.id == id) return s.name; }
    return '—';
  }

  Future<void> _openEdit(ExamModel exam) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ExamFormDialog(
        title: 'Edit Exam',
        initialName: exam.name,
        initialClassId: exam.classId,
        initialSubjectId: exam.subjectId,
        initialDate: exam.date,
        submitLabel: 'Save',
        isCreate: false,
        examId: exam.id,
        onSave: (data) async {
          final result = await ExamsService().updateExam(exam.id, data);
          if (result is ExamSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text((result as ExamError).message), backgroundColor: Colors.red),
            );
          }
          return false;
        },
      ),
    );
    if (updated == true && mounted) {
      setState(() => _dataFuture = _loadExamWithRefData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam updated'), backgroundColor: kPrimaryGreen),
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
                      child: Text(
                        'Exam Details',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<_ExamDetailData>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                    }
                    if (snapshot.hasError) {
                      final msg = userFriendlyMessage(snapshot.error!, null, 'ExamDetailsPage');
                      return _ErrorState(message: msg, onRetry: () => setState(() => _dataFuture = _loadExamWithRefData()));
                    }
                    final data = snapshot.data;
                    if (data == null) return const Center(child: Text('No data'));
                    if (data.examResult is ExamError) {
                      return _ErrorState(message: (data.examResult as ExamError).message, onRetry: () => setState(() => _dataFuture = _loadExamWithRefData()));
                    }
                    final exam = (data.examResult as ExamSuccess<ExamModel>).data;
                    final className = (exam.className != null && exam.className!.isNotEmpty)
                        ? exam.className!
                        : _className(data.classes, exam.classId);
                    final subjectName = (exam.subjectName != null && exam.subjectName!.isNotEmpty)
                        ? exam.subjectName!
                        : _subjectName(data.subjects, exam.subjectId);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OverviewCard(
                            exam: exam,
                            className: className,
                            subjectName: subjectName,
                            onEdit: () => _openEdit(exam),
                          ),
                          const SizedBox(height: 20),
                          _SectionTitle(title: 'Actions'),
                          const SizedBox(height: 12),
                          _ActionButton(
                            label: 'View Marks',
                            icon: Icons.grade_rounded,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminMarksScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _ActionButton(
                            label: 'Add / Update Marks',
                            icon: Icons.add_circle_outline_rounded,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminMarksScreen(openCreateOnLoad: true),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final ExamModel exam;
  final String className;
  final String subjectName;
  final VoidCallback onEdit;

  const _OverviewCard({
    required this.exam,
    required this.className,
    required this.subjectName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: kPrimaryGreen),
                onPressed: onEdit,
                tooltip: 'Edit exam',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.menu_book_rounded, label: 'Subject', value: subjectName),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.class_rounded, label: 'Class', value: className),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.calendar_today_rounded, label: 'Date', value: exam.date ?? '—'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kPrimaryGreen, size: 22),
        const SizedBox(width: 12),
        Text('$label: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 14)),
        Expanded(
          child: Text(value, style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w500, fontSize: 15)),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimaryBlue),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        onPressed: onPressed,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
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

/// Inline exam form dialog used from detail page (same contract as admin_exams_screen).
class _ExamFormDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final int? initialClassId;
  final int? initialSubjectId;
  final String? initialDate;
  final String submitLabel;
  final bool isCreate;
  final int? examId;
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const _ExamFormDialog({
    required this.title,
    required this.initialName,
    this.initialClassId,
    this.initialSubjectId,
    this.initialDate,
    required this.submitLabel,
    required this.isCreate,
    this.examId,
    required this.onSave,
  });

  @override
  State<_ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends State<_ExamFormDialog> {
  late TextEditingController _nameController;
  bool _submitting = false;
  List<ClassModel> _classes = [];
  List<ClassSubjectItem> _subjects = [];
  int? _selectedClassId;
  int? _selectedSubjectId;
  String _dateStr = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _dateStr = widget.initialDate?.isNotEmpty == true ? widget.initialDate! : _formatDate(DateTime.now());
    _selectedClassId = widget.initialClassId;
    _selectedSubjectId = widget.initialSubjectId;
    _loadClasses();
    if (widget.initialClassId != null && widget.initialClassId! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubjectsForClass(widget.initialClassId!));
    }
  }

  String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _loadClasses() async {
    final result = await ClassesService().listClasses();
    if (!mounted) return;
    if (result is ClassSuccess<List<ClassModel>>) {
      setState(() => _classes = result.data);
    }
  }

  Future<void> _loadSubjectsForClass(int classId) async {
    final result = await SchoolAdminAssignmentsService().listClassSubjects(classId);
    if (!mounted) return;
    if (result is AssignmentSuccess<List<ClassSubjectItem>>) {
      setState(() {
        _subjects = result.data;
        final keepId = (classId == widget.initialClassId) ? widget.initialSubjectId : null;
        final inList = keepId != null && _subjects.any((s) => s.id == keepId);
        _selectedSubjectId = inList ? keepId : (_subjects.isNotEmpty ? _subjects.first.id : null);
      });
    } else {
      setState(() {
        _subjects = [];
        _selectedSubjectId = null;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedClassId == null || _selectedClassId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedSubjectId == null || _selectedSubjectId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_dateStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final data = <String, dynamic>{
      'name': name,
      'class_id': _selectedClassId,
      'subject_id': _selectedSubjectId,
      'date': _dateStr,
    };
    final ok = await widget.onSave(data);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
              ),
              const SizedBox(height: 20),
              Input3D(
                controller: _nameController,
                label: 'Exam name',
                hint: 'e.g. Mid-term 2024',
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _selectedClassId,
                label: 'Class',
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select class')),
                  ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedClassId = v;
                    _subjects = [];
                    _selectedSubjectId = null;
                  });
                  if (v != null && v > 0) _loadSubjectsForClass(v);
                },
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _selectedSubjectId != null && _subjects.any((s) => s.id == _selectedSubjectId) ? _selectedSubjectId : null,
                label: 'Subject',
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select subject')),
                  ..._subjects.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _selectedSubjectId = v),
              ),
              const SizedBox(height: 16),
              DatePicker3D(
                label: 'Date',
                value: _dateStr,
                initialDate: DateTime.tryParse(_dateStr) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDatePicked: (d) => setState(() => _dateStr = _formatDate(d)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton3D(
                      label: widget.submitLabel,
                      onPressed: _submit,
                      loading: _submitting,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

