import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/class_subjects_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/exam_subject_controls.dart';
import 'package:kobac/school_admin/widgets/edit_subject_type_dialog.dart';
import 'package:kobac/school_admin/widgets/add_class_subjects_dialog.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kTextSecondaryColor = Color(0xFF636E72);
const double kCardRadius = 28.0;

enum _TypeFilter { all, exam, nonExam }

/// Displays only the subjects already assigned to the selected class.
/// New subjects are added through the separate Add Subjects dialog, which
/// loads the full school catalog itself and filters out subjects already
/// assigned here — the school-wide catalog never appears on this page.
class AdminClassSubjectsScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminClassSubjectsScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminClassSubjectsScreen> createState() => _AdminClassSubjectsScreenState();
}

class _AdminClassSubjectsScreenState extends State<AdminClassSubjectsScreen> {
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  List<ClassSubjectModel> _classSubjects = [];
  final Map<int, String> _subjectNamesById = {};

  _TypeFilter _filter = _TypeFilter.all;
  bool _loadingClasses = false;
  bool _loadingClassSubjects = false;
  String? _classesError;
  String? _classSubjectsError;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _classesError = null;
    });
    try {
      final classesResult = await ClassesService().listClasses();
      if (!mounted) return;
      setState(() {
        _loadingClasses = false;
        if (classesResult is ClassSuccess<List<ClassModel>>) {
          _classes = classesResult.data;
        } else {
          _classesError = 'Unable to load classes.';
        }
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loadingClasses = false;
        _classesError = userFriendlyMessage(e, st, 'AdminClassSubjectsScreen');
      });
    }
  }

  Future<void> _loadClassSubjects(int classId) async {
    setState(() {
      _loadingClassSubjects = true;
      _classSubjectsError = null;
    });

    final result = await ClassSubjectsService().listClassSubjects(classId: classId);
    if (!mounted) return;

    setState(() {
      _loadingClassSubjects = false;
      if (result is ClassSubjectSuccess<List<ClassSubjectModel>>) {
        _classSubjects = result.data;
      } else {
        _classSubjects = [];
        _classSubjectsError = 'Unable to load class subjects.';
      }
    });

    // Defensive fallback only: if the class-subjects endpoint didn't embed a
    // subject name for some row, resolve it quietly from the catalog. This
    // never renders the catalog itself — it only fills in display names.
    if (_classSubjects.any((cs) => cs.subjectName.isEmpty && !_subjectNamesById.containsKey(cs.subjectId))) {
      final catalog = await SubjectsService().listSubjects();
      if (!mounted) return;
      if (catalog is SubjectSuccess<List<SubjectModel>>) {
        setState(() {
          for (final s in catalog.data) {
            _subjectNamesById[s.id] = s.name;
          }
        });
      }
    }
  }

  Future<void> _openAddSubjects() async {
    final selectedClass = _selectedClass;
    if (selectedClass == null) return;
    final added = await showAddClassSubjectsDialog(
      context,
      classId: selectedClass.id,
      className: selectedClass.name,
      alreadyAssignedSubjectIds: _classSubjects.map((cs) => cs.subjectId).toSet(),
    );
    if (added == true) _loadClassSubjects(selectedClass.id);
  }

  Future<void> _editSubjectType(ClassSubjectModel classSubject) async {
    final selectedClass = _selectedClass;
    if (selectedClass == null) return;
    final updated = await showEditSubjectTypeDialog(
      context,
      classId: classSubject.classId,
      subjectId: classSubject.subjectId,
      subjectName: _subjectNameFor(classSubject),
      className: selectedClass.name,
      currentIsExamSubject: classSubject.isExamSubject,
    );
    if (updated == null || !mounted) return;
    _loadClassSubjects(selectedClass.id);
  }

  Future<void> _removeSubject(ClassSubjectModel classSubject) async {
    final selectedClass = _selectedClass;
    if (selectedClass == null) return;
    final subjectName = _subjectNameFor(classSubject);
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Remove Subject?',
      message:
          '$subjectName will no longer be taught by ${selectedClass.name}. '
          'This removes the class-subject assignment entirely — it is not '
          'the same as marking it Non-Exam.',
      confirmLabel: 'Remove',
    );
    if (confirmed != true || !mounted) return;

    final result = await ClassSubjectsService().deleteClassSubject(
      selectedClass.id,
      classSubject.subjectId,
    );
    if (!mounted) return;
    if (result is ClassSubjectSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$subjectName removed from ${selectedClass.name}.'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadClassSubjects(selectedClass.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as ClassSubjectError).message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _subjectNameFor(ClassSubjectModel cs) {
    if (cs.subjectName.isNotEmpty) return cs.subjectName;
    return _subjectNamesById[cs.subjectId] ?? 'Subject ${cs.subjectId}';
  }

  int get _totalCount => _classSubjects.length;
  int get _examCount => _classSubjects.where((cs) => cs.isExamSubject).length;
  int get _nonExamCount => _totalCount - _examCount;

  List<ClassSubjectModel> get _visibleSubjects {
    if (_filter == _TypeFilter.all) return _classSubjects;
    return _classSubjects
        .where((cs) => _filter == _TypeFilter.exam ? cs.isExamSubject : !cs.isExamSubject)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context)
        : _buildMobilePageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return body;
    }

    return Scaffold(
      backgroundColor: kBgColor,
      body: body,
    );
  }

  Widget _buildMobilePageBody(BuildContext context) {
    return SafeArea(
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Class Subjects',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildManagementContent(compact: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPageBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildManagementContent(compact: false),
        ),
      ),
    );
  }

  Widget _buildManagementContent({required bool compact}) {
    if (_loadingClasses) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
      );
    }
    if (_classesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(_classesError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: kTextSecondaryColor)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadClasses,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Class',
          style: TextStyle(
            fontSize: compact ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: compact ? kPrimaryBlue : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ClassModel?>(
              value: _selectedClass,
              hint: const Text('Choose a class'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<ClassModel?>(
                  value: null,
                  child: Text('Select a class'),
                ),
                ..._classes.map(
                  (classModel) => DropdownMenuItem<ClassModel?>(
                    value: classModel,
                    child: Text(
                      classModel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (ClassModel? value) {
                setState(() {
                  _selectedClass = value;
                  _classSubjects = [];
                  _filter = _TypeFilter.all;
                  _classSubjectsError = null;
                });
                if (value != null) _loadClassSubjects(value.id);
              },
            ),
          ),
        ),
        if (_selectedClass != null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedClass!.name} Subjects',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: compact ? kPrimaryBlue : Colors.grey.shade700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openAddSubjects,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Subjects'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingClassSubjects)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
            )
          else if (_classSubjectsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                  const SizedBox(height: 10),
                  Text(_classSubjectsError!, style: const TextStyle(color: kTextSecondaryColor)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _loadClassSubjects(_selectedClass!.id),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_classSubjects.isEmpty)
            _buildEmptyState()
          else ...[
            _buildSummary(),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 12),
            if (_visibleSubjects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No subjects match this filter.',
                  style: TextStyle(color: kTextSecondaryColor),
                ),
              )
            else if (!compact && (kIsWeb || MediaQuery.sizeOf(context).width >= 760))
              _buildDesktopTable()
            else
              ..._visibleSubjects.map((cs) => _buildSubjectCard(cs)),
          ],
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'No subjects have been assigned to this class yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondaryColor),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _openAddSubjects,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Subjects'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _SummaryCell(label: 'Total Subjects', value: _totalCount, color: kPrimaryBlue),
          _SummaryCell(label: 'Exam Subjects', value: _examCount, color: const Color(0xFF5AB04B)),
          _SummaryCell(label: 'Non-Exam Subjects', value: _nonExamCount, color: const Color(0xFFB07A1E)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, _TypeFilter value) {
      final selected = _filter == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: kPrimaryBlue.withOpacity(0.12),
        labelStyle: TextStyle(
          color: selected ? kPrimaryBlue : kTextSecondaryColor,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12.5,
        ),
        side: BorderSide(color: selected ? kPrimaryBlue : const Color(0xFFE5E7EB)),
        backgroundColor: Colors.white,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('All', _TypeFilter.all),
        chip('Exam', _TypeFilter.exam),
        chip('Non-Exam', _TypeFilter.nonExam),
      ],
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8ECF2)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 560),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Subject')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _visibleSubjects
                .map(
                  (cs) => DataRow(
                    cells: [
                      DataCell(Text(_subjectNameFor(cs))),
                      DataCell(ExamSubjectBadge(isExamSubject: cs.isExamSubject)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _editSubjectType(cs),
                              child: const Text('Change Type'),
                            ),
                            IconButton(
                              tooltip: 'Remove Subject',
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () => _removeSubject(cs),
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

  Widget _buildSubjectCard(ClassSubjectModel cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.menu_book_rounded, color: kPrimaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _subjectNameFor(cs),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ExamSubjectBadge(isExamSubject: cs.isExamSubject, compact: true),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Actions',
            icon: const Icon(Icons.more_vert_rounded, color: kTextSecondaryColor),
            onSelected: (value) {
              if (value == 'edit') _editSubjectType(cs);
              if (value == 'remove') _removeSubject(cs);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Change Type')),
              PopupMenuItem(value: 'remove', child: Text('Remove Subject')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$value',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: kTextSecondaryColor),
      ),
    ],
  );
}
