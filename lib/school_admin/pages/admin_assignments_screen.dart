import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart'
    show showDeleteConfirmDialog;
import 'package:kobac/school_admin/widgets/manage_assignments_dialog.dart'
    show showManageAssignmentsDialog;
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:provider/provider.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kCardColor = Colors.white;
const double kCardRadius = 28.0;

class AdminAssignmentsScreen extends StatefulWidget {
  final bool openCreateOnLoad;
  final bool embedBodyOnly;

  const AdminAssignmentsScreen({
    Key? key,
    this.openCreateOnLoad = false,
    this.embedBodyOnly = false,
  }) : super(key: key);

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
  int? _selectedAcademicYearId;
  bool _filterSubjectsLoading = false;
  bool _filterTeachersLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAcademicYear());
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  Future<void> _initAcademicYear() async {
    final provider = context.read<AcademicYearsProvider>();
    await provider.ensureLoaded();
    if (!mounted) return;
    setState(() => _selectedAcademicYearId ??= provider.activeYear?.id);
    _loadAssignments();
  }

  Future<void> _onAcademicYearChanged(int? yearId) async {
    setState(() => _selectedAcademicYearId = yearId);
    _loadAssignments();
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
      academicYearId: _selectedAcademicYearId,
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
      final result = await SchoolAdminAssignmentsService().listClassSubjects(
        classId,
      );
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
              content: Text(
                error.statusCode == 404
                    ? 'No subjects assigned to this class.'
                    : 'Failed to load subjects: ${error.message}',
              ),
              backgroundColor: error.statusCode == 404
                  ? Colors.orange
                  : Colors.red,
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
      final result = await SchoolAdminAssignmentsService()
          .listClassSubjectTeachers(_filterClassId!, subjectId);
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
              content: Text(
                error.statusCode == 404
                    ? 'No teachers assigned to this class-subject.'
                    : 'Failed to load teachers: ${error.message}',
              ),
              backgroundColor: error.statusCode == 404
                  ? Colors.orange
                  : Colors.red,
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
    final years = context.read<AcademicYearsProvider>().years;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CreateAssignmentDialog(
        classes: _classes,
        years: years,
        initialAcademicYearId: _selectedAcademicYearId,
        onSaved: () => _loadAssignments(),
      ),
    );
    if (created == true && mounted) {
      _loadAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment created'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEdit(AssignmentModel a) async {
    final years = context.read<AcademicYearsProvider>().years;
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditAssignmentDialog(
        assignment: a,
        classes: _classes,
        years: years,
        onSaved: () => _loadAssignments(),
      ),
    );
    if (updated == true && mounted) {
      _loadAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment updated'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAssignment(AssignmentModel a) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Assignment?',
      message:
          'Teacher: ${a.teacherName}\n'
          'Class: ${a.className}\n'
          'Subject: ${a.subjectName}\n'
          'Academic Year: ${a.academicYearName.isNotEmpty ? a.academicYearName : '—'}',
    );
    if (confirmed != true || !mounted) return;
    final result = await SchoolAdminAssignmentsService().deleteAssignment(a.id);
    if (!mounted) return;
    if (result is AssignmentSuccess) {
      _loadAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment removed'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as AssignmentError).message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Opens the Manage Assignments dialog, where the admin explicitly picks
  /// the academic year (and teacher, for the clear-teacher flow) to act on —
  /// nothing here is pre-submitted from the page's active-year filter.
  Future<void> _openManageDialog() async {
    final changed = await showManageAssignmentsDialog(
      context,
      initialAcademicYearId: _selectedAcademicYearId,
    );
    // Keep the page's own Academic Year filter unchanged; only refresh the
    // list so a reset/clear performed on another year doesn't affect what's
    // currently displayed unless it was the same year.
    if (changed == true && mounted) {
      _loadAssignments();
    }
  }

  Widget _buildAcademicYearMiniField() {
    final years = context.watch<AcademicYearsProvider>().years;
    return SizedBox(
      width: 190,
      child: Select3D<int?>(
        value: years.any((y) => y.id == _selectedAcademicYearId)
            ? _selectedAcademicYearId
            : null,
        label: 'Academic Year',
        items: years
            .map(
              (y) => DropdownMenuItem<int?>(
                value: y.id,
                child: Text(y.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _onAcademicYearChanged,
      ),
    );
  }

  Widget _buildManageButton() {
    final compact = MediaQuery.sizeOf(context).width < 380;
    if (compact) {
      return Tooltip(
        message: 'Manage Assignments',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: _openManageDialog,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.tune_rounded,
                color: kPrimaryBlue,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _openManageDialog,
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: const Text('Manage'),
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryBlue,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course Assign Teacher',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),
                          Text(
                            'Manage teacher subject assignments by academic year',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width >= 760) ...[
                      _buildAcademicYearMiniField(),
                      const SizedBox(width: 10),
                    ],
                    _buildManageButton(),
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
                        if (!_loading && _error == null && _assignments.isEmpty)
                          _buildEmpty(),
                        if (!_loading &&
                            _error == null &&
                            _assignments.isNotEmpty)
                          _buildAssignmentsList(),
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
    return widget.embedBodyOnly ? scaffold.body! : scaffold;
  }

  Widget _buildFiltersCard() {
    return FormCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
              ),
              if (_filterClassId != null ||
                  _filterSubjectId != null ||
                  _filterTeacherId != null)
                TextButton(
                  onPressed: _loading ? null : _clearFilters,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: kPrimaryBlue),
                  ),
                ),
            ],
          ),
          // The header already shows a compact Academic Year selector on
          // wide screens; avoid showing the same control twice.
          if (MediaQuery.sizeOf(context).width < 760) ...[
            Select3D<int?>(
              value: context.watch<AcademicYearsProvider>().years.any(
                    (y) => y.id == _selectedAcademicYearId,
                  )
                  ? _selectedAcademicYearId
                  : null,
              label: 'Academic Year',
              items: context
                  .watch<AcademicYearsProvider>()
                  .years
                  .map(
                    (y) => DropdownMenuItem<int?>(
                      value: y.id,
                      child: Text(
                        y.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _onAcademicYearChanged,
            ),
            const SizedBox(height: 14),
          ],
          Select3D<int?>(
            value: _filterClassId,
            label: 'Class',
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All classes'),
              ),
              ..._classes.map(
                (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: _onFilterClassChanged,
          ),
          const SizedBox(height: 14),
          Select3D<int?>(
            value: _filterSubjectId,
            label: 'Subject',
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All subjects'),
              ),
              ..._classSubjects.map(
                (s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
              ),
            ],
            onChanged: _filterSubjectsLoading ? null : _onFilterSubjectChanged,
          ),
          const SizedBox(height: 14),
          Select3D<int?>(
            value: _filterTeacherId,
            label: 'Teacher',
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All teachers'),
              ),
              ..._classSubjectTeachers.map(
                (t) => DropdownMenuItem<int?>(
                  value: t.id,
                  child: Text(t.fullName),
                ),
              ),
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
          Expanded(
            child: Text(
              _error ?? '',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          TextButton(onPressed: _loadAssignments, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return FormCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            height: 56,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return FormCard(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
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

  Widget _buildAssignmentsList() {
    final isWide = kIsWeb || MediaQuery.sizeOf(context).width >= 760;
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _assignments
            .map(
              (a) => _AssignmentCard(
                assignment: a,
                onEdit: () => _openEdit(a),
                onDelete: () => _deleteAssignment(a),
              ),
            )
            .toList(),
      );
    }
    return FormCard(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 900,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Teacher')),
              DataColumn(label: Text('Class')),
              DataColumn(label: Text('Subject')),
              DataColumn(label: Text('Academic Year')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _assignments
                .map(
                  (a) => DataRow(
                    cells: [
                      DataCell(Text(a.teacherName)),
                      DataCell(Text(a.className)),
                      DataCell(Text(a.subjectName)),
                      DataCell(
                        Text(a.academicYearName.isNotEmpty ? a.academicYearName : '—'),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: kPrimaryBlue,
                                size: 20,
                              ),
                              onPressed: () => _openEdit(a),
                              tooltip: 'Edit assignment',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red[400],
                                size: 22,
                              ),
                              onPressed: () => _deleteAssignment(a),
                              tooltip: 'Remove assignment',
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
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.assignment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.className,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.subjectName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                Text(
                  assignment.teacherName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                if (assignment.teacherEmail != null &&
                    assignment.teacherEmail!.isNotEmpty)
                  Text(
                    assignment.teacherEmail!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                if (assignment.academicYearName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      assignment.academicYearName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryGreen.withOpacity(0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: kPrimaryBlue, size: 22),
            onPressed: onEdit,
            tooltip: 'Edit assignment',
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red[400],
              size: 24,
            ),
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
  final List<AcademicYear> years;
  final int? initialAcademicYearId;
  final VoidCallback onSaved;

  const _CreateAssignmentDialog({
    required this.classes,
    required this.years,
    this.initialAcademicYearId,
    required this.onSaved,
  });

  @override
  State<_CreateAssignmentDialog> createState() =>
      _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  int? _classId;
  int? _subjectId;
  int? _teacherId;
  late int? _academicYearId;
  List<SubjectModel> _subjects = [];
  bool _subjectsLoading = true;
  bool _saving = false;
  List<TeacherModel> _allTeachers = [];
  bool _teachersLoading = true;
  bool _multi = false;
  final List<_BulkAssignmentRow> _bulkRows = [_BulkAssignmentRow()];
  String? _formError;

  @override
  void initState() {
    super.initState();
    _academicYearId = widget.initialAcademicYearId;
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
      if (result is TeacherSuccess<List<TeacherModel>>)
        _allTeachers = result.data;
    });
  }

  void _onClassChanged(int? v) => setState(() {
    _classId = v;
    _subjectId = null;
    _teacherId = null;
  });

  void _onSubjectChanged(int? v) => setState(() => _subjectId = v);

  Future<void> _submit() async {
    if (_multi) {
      await _submitBulk();
      return;
    }
    if (_academicYearId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an academic year.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_classId == null || _subjectId == null || _teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select class, subject and teacher'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await SchoolAdminAssignmentsService().createAssignment(
      teacherId: _teacherId!,
      classId: _classId!,
      subjectId: _subjectId!,
      academicYearId: _academicYearId!,
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
          const SnackBar(
            content: Text('Assignment already exists.'),
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
          SnackBar(
            content: Text(err.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitBulk() async {
    if (_academicYearId == null) {
      setState(() => _formError = 'Select an academic year.');
      return;
    }
    if (_teacherId == null ||
        _bulkRows.any((row) => row.classId == null || row.subjectId == null)) {
      setState(
        () => _formError = 'Select a teacher, class and subject for every row.',
      );
      return;
    }
    final keys = <String>{};
    for (final row in _bulkRows) {
      if (!keys.add('${row.classId}:${row.subjectId}')) {
        setState(
          () => _formError = 'This class and subject are already included.',
        );
        return;
      }
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final result = await SchoolAdminAssignmentsService().createBulkAssignments(
      teacherId: _teacherId!,
      academicYearId: _academicYearId!,
      assignments: _bulkRows
          .map(
            (row) => {'class_id': row.classId!, 'subject_id': row.subjectId!},
          )
          .toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is AssignmentError) {
      setState(() => _formError = result.message);
      return;
    }
    final created =
        (result as AssignmentSuccess<BulkAssignmentResponse>).data.createdCount;
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$created teacher assignment${created == 1 ? '' : 's'} created.',
        ),
        backgroundColor: kPrimaryGreen,
      ),
    );
    Navigator.pop(context, true);
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
              const Text(
                'Assign Teacher',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Single Assignment')),
                  ButtonSegment(value: true, label: Text('Multi Assignment')),
                ],
                selected: {_multi},
                onSelectionChanged: _saving
                    ? null
                    : (value) => setState(() {
                        _multi = value.first;
                        _formError = null;
                      }),
              ),
              const SizedBox(height: 20),
              Select3D<int?>(
                value: widget.years.any((y) => y.id == _academicYearId)
                    ? _academicYearId
                    : null,
                label: 'Academic Year *',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      widget.years.isEmpty
                          ? 'No academic years available'
                          : 'Select academic year',
                    ),
                  ),
                  ...widget.years.map(
                    (y) => DropdownMenuItem<int?>(value: y.id, child: Text(y.name)),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _academicYearId = v),
              ),
              const SizedBox(height: 16),
              if (_multi) ...[
                Select3D<int?>(
                  value: _teacherId,
                  label: 'Teacher',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select teacher'),
                    ),
                    ..._allTeachers.map(
                      (teacher) => DropdownMenuItem(
                        value: teacher.id,
                        child: Text(
                          teacher.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _teachersLoading
                      ? null
                      : (value) => setState(() => _teacherId = value),
                ),
                const SizedBox(height: 16),
                ...List.generate(_bulkRows.length, (index) {
                  final row = _bulkRows[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Assignment ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: kPrimaryBlue,
                              ),
                            ),
                            const Spacer(),
                            if (_bulkRows.length > 1)
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () =>
                                    setState(() => _bulkRows.removeAt(index)),
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                        Select3D<int?>(
                          value: row.classId,
                          label: 'Class',
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select class'),
                            ),
                            ...widget.classes.map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => row.classId = value),
                        ),
                        const SizedBox(height: 12),
                        Select3D<int?>(
                          value: row.subjectId,
                          label: 'Subject',
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select subject'),
                            ),
                            ..._subjects.map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            ),
                          ],
                          onChanged: _subjectsLoading
                              ? null
                              : (value) =>
                                    setState(() => row.subjectId = value),
                        ),
                      ],
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _bulkRows.add(_BulkAssignmentRow())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Assignment'),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Select3D<int?>(
                  value: _classId,
                  label: 'Class',
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Select class'),
                    ),
                    ...widget.classes.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: _onClassChanged,
                ),
                const SizedBox(height: 16),
                if (subjectHint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      subjectHint,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                Select3D<int?>(
                  value: _subjectId,
                  label: 'Subject',
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        _subjectsLoading
                            ? 'Loading...'
                            : _subjects.isEmpty
                            ? 'No subjects in school'
                            : 'Select subject',
                      ),
                    ),
                    ..._subjects.map(
                      (s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  onChanged: _subjectsLoading ? null : _onSubjectChanged,
                ),
                const SizedBox(height: 16),
                if (teacherHint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      teacherHint,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                Select3D<int?>(
                  value: _teacherId,
                  label: 'Teacher',
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        _teachersLoading
                            ? 'Loading...'
                            : _allTeachers.isEmpty
                            ? 'No teachers in school'
                            : 'Select teacher',
                      ),
                    ),
                    ..._allTeachers.map(
                      (t) => DropdownMenuItem<int?>(
                        value: t.id,
                        child: Text(t.fullName),
                      ),
                    ),
                  ],
                  onChanged: _teachersLoading
                      ? null
                      : (v) => setState(() => _teacherId = v),
                ),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(_formError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton3D(
                      label: _multi ? 'Save All Assignments' : 'Create',
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

class _BulkAssignmentRow {
  int? classId;
  int? subjectId;
}

/// Edit assignment: prefilled with current teacher, class, subject. PATCH /api/school-admin/assignments/:id.
class _EditAssignmentDialog extends StatefulWidget {
  final AssignmentModel assignment;
  final List<ClassModel> classes;
  final List<AcademicYear> years;
  final VoidCallback onSaved;

  const _EditAssignmentDialog({
    required this.assignment,
    required this.classes,
    required this.years,
    required this.onSaved,
  });

  @override
  State<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<_EditAssignmentDialog> {
  late int? _classId;
  late int? _subjectId;
  late int? _teacherId;
  late int? _academicYearId;
  List<SubjectModel> _subjects = [];
  bool _subjectsLoading = true;
  bool _saving = false;
  List<TeacherModel> _allTeachers = [];
  bool _teachersLoading = true;

  @override
  void initState() {
    super.initState();
    _classId = widget.assignment.classId > 0 ? widget.assignment.classId : null;
    _subjectId = widget.assignment.subjectId > 0
        ? widget.assignment.subjectId
        : null;
    _teacherId = widget.assignment.teacherId > 0
        ? widget.assignment.teacherId
        : null;
    _academicYearId = widget.assignment.academicYearId > 0
        ? widget.assignment.academicYearId
        : null;
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
      if (result is TeacherSuccess<List<TeacherModel>>)
        _allTeachers = result.data;
    });
  }

  void _onClassChanged(int? v) => setState(() {
    _classId = v;
    _subjectId = null;
    _teacherId = null;
  });

  void _onSubjectChanged(int? v) => setState(() => _subjectId = v);

  Future<void> _submit() async {
    if (_academicYearId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an academic year.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_classId == null || _subjectId == null || _teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select class, subject and teacher'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await SchoolAdminAssignmentsService().updateAssignment(
      widget.assignment.id,
      teacherId: _teacherId,
      classId: _classId,
      subjectId: _subjectId,
      academicYearId: _academicYearId,
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
            content: Text(
              'Duplicate assignment. That teacher/class/subject combination already exists.',
            ),
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
          SnackBar(
            content: Text(err.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
              const Text(
                'Edit Assignment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${widget.assignment.id}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Select3D<int?>(
                value: widget.years.any((y) => y.id == _academicYearId)
                    ? _academicYearId
                    : null,
                label: 'Academic Year *',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      widget.years.isEmpty
                          ? 'No academic years available'
                          : 'Select academic year',
                    ),
                  ),
                  ...widget.years.map(
                    (y) => DropdownMenuItem<int?>(value: y.id, child: Text(y.name)),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _academicYearId = v),
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _classId,
                label: 'Class',
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Select class'),
                  ),
                  ...widget.classes.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: _onClassChanged,
              ),
              const SizedBox(height: 16),
              if (subjectHint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    subjectHint,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              Select3D<int?>(
                value: _subjectId,
                label: 'Subject',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      _subjectsLoading
                          ? 'Loading...'
                          : _subjects.isEmpty
                          ? 'No subjects in school'
                          : 'Select subject',
                    ),
                  ),
                  ..._subjects.map(
                    (s) => DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: _subjectsLoading ? null : _onSubjectChanged,
              ),
              const SizedBox(height: 16),
              if (teacherHint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    teacherHint,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              Select3D<int?>(
                value: _teacherId,
                label: 'Teacher',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      _teachersLoading
                          ? 'Loading...'
                          : _allTeachers.isEmpty
                          ? 'No teachers in school'
                          : 'Select teacher',
                    ),
                  ),
                  ..._allTeachers.map(
                    (t) => DropdownMenuItem<int?>(
                      value: t.id,
                      child: Text(t.fullName),
                    ),
                  ),
                ],
                onChanged: _teachersLoading
                    ? null
                    : (v) => setState(() => _teacherId = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
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
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: kPrimaryBlue,
          size: 24,
        ),
      ),
    );
  }
}

