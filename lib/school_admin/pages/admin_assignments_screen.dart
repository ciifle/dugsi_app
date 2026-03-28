import 'package:flutter/material.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart' show showDeleteConfirmDialog;
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kCardColor = Colors.white;
const double kCardRadius = 28.0;

class AdminAssignmentsScreen extends StatefulWidget {
  final bool openCreateOnLoad;

  const AdminAssignmentsScreen({Key? key, this.openCreateOnLoad = false}) : super(key: key);

  @override
  State<AdminAssignmentsScreen> createState() => _AdminAssignmentsScreenState();
}

class _AdminAssignmentsScreenState extends State<AdminAssignmentsScreen> {
  List<AssignmentModel> _assignments = [];
  bool _loading = true;
  String? _error;

  List<ClassModel> _classes = [];
  List<ClassSubjectItem> _classSubjects = [];
  List<TeacherModel> _classSubjectTeachers = [];
  int? _filterClassId;
  int? _filterSubjectId;
  int? _filterTeacherId;
  bool _filterSubjectsLoading = false;
  bool _filterTeachersLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadAssignments();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  Future<void> _loadClasses() async {
    final result = await ClassesService().listClasses();
    if (!mounted) return;
    setState(() {
      if (result is ClassSuccess<List<ClassModel>>) _classes = result.data;
    });
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await SchoolAdminAssignmentsService().listAssignments(
      teacherId: _filterTeacherId,
      classId: _filterClassId,
      subjectId: _filterSubjectId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is AssignmentSuccess<List<AssignmentModel>>) {
        _assignments = result.data;
        _error = null;
      } else {
        _assignments = [];
        _error = (result as AssignmentError).message;
      }
    });
  }

  Future<void> _onFilterClassChanged(int? classId) async {
    setState(() {
      _filterClassId = classId;
      _filterSubjectId = null;
      _filterTeacherId = null;
      _classSubjects = [];
      _classSubjectTeachers = [];
    });
    if (classId != null) {
      setState(() => _filterSubjectsLoading = true);
      final result = await SchoolAdminAssignmentsService().listClassSubjects(classId);
      if (!mounted) return;
      setState(() {
        _filterSubjectsLoading = false;
        if (result is AssignmentSuccess<List<ClassSubjectItem>>) {
          _classSubjects = result.data;
        } else {
          final error = result as AssignmentError;
          _classSubjects = [];
          // Show user-friendly error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.statusCode == 404 ? 
                'No subjects assigned to this class.' : 
                'Failed to load subjects: ${error.message}'
              ),
              backgroundColor: error.statusCode == 404 ? Colors.orange : Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
    _loadAssignments();
  }

  Future<void> _onFilterSubjectChanged(int? subjectId) async {
    setState(() {
      _filterSubjectId = subjectId;
      _filterTeacherId = null;
      _classSubjectTeachers = [];
    });
    if (subjectId != null && _filterClassId != null) {
      setState(() => _filterTeachersLoading = true);
      final result = await SchoolAdminAssignmentsService().listClassSubjectTeachers(_filterClassId!, subjectId);
      if (!mounted) return;
      setState(() {
        _filterTeachersLoading = false;
        if (result is AssignmentSuccess<List<TeacherModel>>) {
          _classSubjectTeachers = result.data;
        } else {
          final error = result as AssignmentError;
          _classSubjectTeachers = [];
          // Show user-friendly error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.statusCode == 404 ? 
                'No teachers assigned to this class-subject.' : 
                'Failed to load teachers: ${error.message}'
              ),
              backgroundColor: error.statusCode == 404 ? Colors.orange : Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
    _loadAssignments();
  }

  void _onFilterTeacherChanged(int? teacherId) {
    setState(() => _filterTeacherId = teacherId);
    _loadAssignments();
  }

  void _clearFilters() {
    setState(() {
      _filterClassId = null;
      _filterSubjectId = null;
      _filterTeacherId = null;
      _classSubjects = [];
      _classSubjectTeachers = [];
    });
    _loadAssignments();
  }

  Future<void> _openCreate() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CreateAssignmentDialog(
        classes: _classes,
        onSaved: () => _loadAssignments(),
      ),
    );
    if (created == true && mounted) {
      _loadAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment created'), backgroundColor: kPrimaryGreen, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _openEdit(AssignmentModel a) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditAssignmentDialog(
        assignment: a,
        classes: _classes,
        onSaved: () => _loadAssignments(),
      ),
    );
    if (updated == true && mounted) {
      _loadAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment updated'), backgroundColor: kPrimaryGreen, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _deleteAssignment(AssignmentModel a) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Remove teacher assignment?',
      message: '${a.teacherName} will no longer be assigned to ${a.className} - ${a.subjectName}.',
    );
    if (confirmed != true || !mounted) return;
    final result = await SchoolAdminAssignmentsService().deleteAssignment(a.id);
    if (!mounted) return;
    if (result is AssignmentSuccess) {
      _loadAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment removed'), backgroundColor: kPrimaryGreen, behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as AssignmentError).message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F5F9), Color(0xFFE8ECF2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Teacher Assignments',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _AddButton(onPressed: _loading ? null : _openCreate),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadClasses();
                    await _loadAssignments();
                  },
                  color: kPrimaryGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFiltersCard(),
                        const SizedBox(height: 20),
                        if (_error != null) _buildErrorCard(),
                        if (_loading) _buildSkeleton(),
                        if (!_loading && _error == null && _assignments.isEmpty) _buildEmpty(),
                        if (!_loading && _error == null && _assignments.isNotEmpty) ..._assignments.map((a) => _AssignmentCard(assignment: a, onEdit: () => _openEdit(a), onDelete: () => _deleteAssignment(a))),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openCreate,
        backgroundColor: kPrimaryGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Assignment'),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return FormCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue))),
              if (_filterClassId != null || _filterSubjectId != null || _filterTeacherId != null)
                TextButton(
                  onPressed: _loading ? null : _clearFilters,
                  child: const Text('Clear', style: TextStyle(color: kPrimaryBlue)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Select3D<int?>(
            value: _filterClassId,
            label: 'Class',
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All classes')),
              ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
            ],
            onChanged: _onFilterClassChanged,
          ),
          const SizedBox(height: 14),
          Select3D<int?>(
            value: _filterSubjectId,
            label: 'Subject',
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All subjects')),
              ..._classSubjects.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
            ],
            onChanged: _filterSubjectsLoading ? null : _onFilterSubjectChanged,
          ),
          const SizedBox(height: 14),
          Select3D<int?>(
            value: _filterTeacherId,
            label: 'Teacher',
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All teachers')),
              ..._classSubjectTeachers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName))),
            ],
            onChanged: _filterTeachersLoading ? null : _onFilterTeacherChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return FormCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(_error ?? '', style: const TextStyle(color: Colors.black87))),
          TextButton(onPressed: _loadAssignments, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return FormCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(4, (_) => Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        )),
      ),
    );
  }

  Widget _buildEmpty() {
    return FormCard(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No assignments yet. Create one to enable timetables & teacher features.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({required this.assignment, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                const SizedBox(height: 4),
                Text(assignment.subjectName, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                Text(assignment.teacherName, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                if (assignment.teacherEmail != null && assignment.teacherEmail!.isNotEmpty)
                  Text(assignment.teacherEmail!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: kPrimaryBlue, size: 22),
            onPressed: onEdit,
            tooltip: 'Edit assignment',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 24),
            onPressed: onDelete,
            tooltip: 'Remove assignment',
          ),
        ],
      ),
    );
  }
}

/// Create assignment: school-wide Class, Subject, Teacher (GET /classes, /subjects, /teachers).
class _CreateAssignmentDialog extends StatefulWidget {
  final List<ClassModel> classes;
  final VoidCallback onSaved;

  const _CreateAssignmentDialog({
    required this.classes,
    required this.onSaved,
  });

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  int? _classId;
  int? _subjectId;
  int? _teacherId;
  List<SubjectModel> _subjects = [];
  bool _subjectsLoading = true;
  bool _saving = false;
  List<TeacherModel> _allTeachers = [];
  bool _teachersLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSubjects();
    _loadAllTeachers();
  }

  Future<void> _loadAllSubjects() async {
    setState(() => _subjectsLoading = true);
    final result = await SubjectsService().listSubjects();
    if (!mounted) return;
    setState(() {
      _subjectsLoading = false;
      if (result is SubjectSuccess<List<SubjectModel>>) _subjects = result.data;
    });
  }

  Future<void> _loadAllTeachers() async {
    setState(() => _teachersLoading = true);
    final result = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      _teachersLoading = false;
      if (result is TeacherSuccess<List<TeacherModel>>) _allTeachers = result.data;
    });
  }

  void _onClassChanged(int? v) => setState(() {
    _classId = v;
    _subjectId = null;
    _teacherId = null;
  });

  void _onSubjectChanged(int? v) => setState(() => _subjectId = v);

  Future<void> _submit() async {
    if (_classId == null || _subjectId == null || _teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select class, subject and teacher'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await SchoolAdminAssignmentsService().createAssignment(
      teacherId: _teacherId!,
      classId: _classId!,
      subjectId: _subjectId!,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is AssignmentSuccess) {
      widget.onSaved();
      Navigator.pop(context, true);
    } else {
      final err = result as AssignmentError;
      if (err.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment already exists.'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
        );
      } else if (err.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectHint = _subjectsLoading
        ? 'Loading...'
        : _subjects.isEmpty
            ? 'No subjects in school. Add subjects first.'
            : null;
    final teacherHint = _teachersLoading
        ? null
        : _allTeachers.isEmpty
            ? 'No teachers available. Create teachers first.'
            : null;

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
              const Text('Create Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              const SizedBox(height: 20),
              Select3D<int?>(
                value: _classId,
                label: 'Class',
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select class')),
                  ...widget.classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: _onClassChanged,
              ),
              const SizedBox(height: 16),
              if (subjectHint != null) Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(subjectHint, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              Select3D<int?>(
                value: _subjectId,
                label: 'Subject',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(_subjectsLoading ? 'Loading...' : _subjects.isEmpty ? 'No subjects in school' : 'Select subject'),
                  ),
                  ..._subjects.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                ],
                onChanged: _subjectsLoading ? null : _onSubjectChanged,
              ),
              const SizedBox(height: 16),
              if (teacherHint != null) Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(teacherHint, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              Select3D<int?>(
                value: _teacherId,
                label: 'Teacher',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(_teachersLoading ? 'Loading...' : _allTeachers.isEmpty ? 'No teachers in school' : 'Select teacher'),
                  ),
                  ..._allTeachers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName))),
                ],
                onChanged: _teachersLoading ? null : (v) => setState(() => _teacherId = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton3D(
                      label: 'Create',
                      onPressed: _submit,
                      loading: _saving,
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

/// Edit assignment: prefilled with current teacher, class, subject. PATCH /api/school-admin/assignments/:id.
class _EditAssignmentDialog extends StatefulWidget {
  final AssignmentModel assignment;
  final List<ClassModel> classes;
  final VoidCallback onSaved;

  const _EditAssignmentDialog({
    required this.assignment,
    required this.classes,
    required this.onSaved,
  });

  @override
  State<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<_EditAssignmentDialog> {
  late int? _classId;
  late int? _subjectId;
  late int? _teacherId;
  List<SubjectModel> _subjects = [];
  bool _subjectsLoading = true;
  bool _saving = false;
  List<TeacherModel> _allTeachers = [];
  bool _teachersLoading = true;

  @override
  void initState() {
    super.initState();
    _classId = widget.assignment.classId > 0 ? widget.assignment.classId : null;
    _subjectId = widget.assignment.subjectId > 0 ? widget.assignment.subjectId : null;
    _teacherId = widget.assignment.teacherId > 0 ? widget.assignment.teacherId : null;
    _loadAllSubjects();
    _loadAllTeachers();
  }

  Future<void> _loadAllSubjects() async {
    setState(() => _subjectsLoading = true);
    final result = await SubjectsService().listSubjects();
    if (!mounted) return;
    setState(() {
      _subjectsLoading = false;
      if (result is SubjectSuccess<List<SubjectModel>>) _subjects = result.data;
    });
  }

  Future<void> _loadAllTeachers() async {
    setState(() => _teachersLoading = true);
    final result = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      _teachersLoading = false;
      if (result is TeacherSuccess<List<TeacherModel>>) _allTeachers = result.data;
    });
  }

  void _onClassChanged(int? v) => setState(() {
    _classId = v;
    _subjectId = null;
    _teacherId = null;
  });

  void _onSubjectChanged(int? v) => setState(() => _subjectId = v);

  Future<void> _submit() async {
    if (_classId == null || _subjectId == null || _teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select class, subject and teacher'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await SchoolAdminAssignmentsService().updateAssignment(
      widget.assignment.id,
      teacherId: _teacherId,
      classId: _classId,
      subjectId: _subjectId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is AssignmentSuccess<AssignmentModel>) {
      widget.onSaved();
      Navigator.pop(context, true);
    } else {
      final err = result as AssignmentError;
      if (err.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duplicate assignment. That teacher/class/subject combination already exists.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (err.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectHint = _subjectsLoading
        ? 'Loading...'
        : _subjects.isEmpty
            ? 'No subjects in school.'
            : null;
    final teacherHint = _teachersLoading
        ? null
        : _allTeachers.isEmpty
            ? 'No teachers available.'
            : null;

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
              const Text('Edit Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              const SizedBox(height: 8),
              Text(
                'ID: ${widget.assignment.id}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Select3D<int?>(
                value: _classId,
                label: 'Class',
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select class')),
                  ...widget.classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: _onClassChanged,
              ),
              const SizedBox(height: 16),
              if (subjectHint != null) Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(subjectHint, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              Select3D<int?>(
                value: _subjectId,
                label: 'Subject',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(_subjectsLoading ? 'Loading...' : _subjects.isEmpty ? 'No subjects in school' : 'Select subject'),
                  ),
                  ..._subjects.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                ],
                onChanged: _subjectsLoading ? null : _onSubjectChanged,
              ),
              const SizedBox(height: 16),
              if (teacherHint != null) Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(teacherHint, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              Select3D<int?>(
                value: _teacherId,
                label: 'Teacher',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(_teachersLoading ? 'Loading...' : _allTeachers.isEmpty ? 'No teachers in school' : 'Select teacher'),
                  ),
                  ..._allTeachers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName))),
                ],
                onChanged: _teachersLoading ? null : (v) => setState(() => _teacherId = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton3D(
                      label: 'Save',
                      onPressed: _submit,
                      loading: _saving,
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
  final VoidCallback? onPressed;

  const _AddButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (onPressed != null ? kPrimaryGreen : Colors.grey).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: (onPressed != null ? kPrimaryGreen : Colors.grey).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(Icons.add_rounded, color: onPressed != null ? kPrimaryGreen : Colors.grey, size: 24),
      ),
    );
  }
}
