import 'package:flutter/material.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/school_admin/pages/exam_details_page.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminExamsScreen extends StatefulWidget {
  final bool openCreateOnLoad;

  const AdminExamsScreen({Key? key, this.openCreateOnLoad = false}) : super(key: key);

  @override
  State<AdminExamsScreen> createState() => _AdminExamsScreenState();
}

class _AdminExamsScreenState extends State<AdminExamsScreen> {
  late Future<ExamResult<List<ExamModel>>> _examsFuture;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExams();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreateExam());
    }
  }

  void _loadExams() {
    setState(() {
      _examsFuture = ExamsService().listExams();
    });
  }

  List<ExamModel> _filter(List<ExamModel> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openCreateExam() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ExamFormDialog(
        title: 'Add Exam',
        initialName: '',
        submitLabel: 'Create',
        isCreate: true,
        onSave: (data) async {
          final result = await ExamsService().createExam(data);
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
    if (created == true) {
      _loadExams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam created'), backgroundColor: kPrimaryGreen),
        );
      }
    }
  }

  Future<void> _openEditExam(ExamModel exam) async {
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
    if (updated == true) {
      _loadExams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam updated'), backgroundColor: kPrimaryGreen),
        );
      }
    }
  }

  Future<void> _deleteExam(ExamModel exam) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete exam?',
      message: 'Delete exam ${exam.name}?',
    );
    if (confirmed != true) return;
    final result = await ExamsService().deleteExam(exam.id);
    if (!mounted) return;
    if (result is ExamSuccess) {
      _loadExams();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${exam.name} deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as ExamError).message), backgroundColor: Colors.red),
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
                        "Exams",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _AddButton(onPressed: _openCreateExam),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                      BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search exams...",
                      prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryBlue),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadExams(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<ExamResult<List<ExamModel>>>(
                    future: _examsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                      }
                      if (snapshot.hasError) {
                        final userMsg = userFriendlyMessage(snapshot.error!, null, 'AdminExamsScreen');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(userMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _loadExams,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final result = snapshot.data;
                      if (result == null) return const Center(child: Text('No data'));
                      if (result is ExamError) {
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
                                TextButton.icon(
                                  onPressed: _loadExams,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final exams = _filter((result as ExamSuccess<List<ExamModel>>).data);
                      if (exams.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.quiz_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    searchQuery.isEmpty ? 'No exams yet' : 'No exams match your search',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                  if (searchQuery.isEmpty) ...[
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      onPressed: _openCreateExam,
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Add Exam'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          return _ExamCard(
                            exam: exam,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExamDetailsPage(examId: exam.id),
                              ),
                            ),
                            onEdit: () => _openEditExam(exam),
                            onDelete: () => _deleteExam(exam),
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
    _dateStr = widget.initialDate?.isNotEmpty == true
        ? widget.initialDate!
        : _formatDate(DateTime.now());
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

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamCard({
    required this.exam,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.quiz_rounded, color: kPrimaryBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22, color: kPrimaryGreen),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
