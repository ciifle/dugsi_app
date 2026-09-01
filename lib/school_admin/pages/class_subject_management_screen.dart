import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
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

/// Displays only the subjects already assigned to [classId]. New subjects
/// are added through the separate Add Subjects dialog, which loads the full
/// school catalog itself — the catalog never appears on this page.
class ClassSubjectManagementScreen extends StatefulWidget {
  final int classId;
  final String className;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const ClassSubjectManagementScreen({
    Key? key,
    required this.classId,
    required this.className,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<ClassSubjectManagementScreen> createState() => _ClassSubjectManagementScreenState();
}

class _ClassSubjectManagementScreenState extends State<ClassSubjectManagementScreen> {
  List<ClassSubjectModel> _classSubjects = [];
  final Map<int, String> _subjectNamesById = {};

  _TypeFilter _filter = _TypeFilter.all;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ClassSubjectsService().listClassSubjects(classId: widget.classId);
      if (!mounted) return;

      if (result is ClassSubjectError) {
        setState(() {
          _loading = false;
          _error = 'Unable to load class subjects.';
        });
        return;
      }

      final classSubjects = (result as ClassSubjectSuccess<List<ClassSubjectModel>>).data;
      setState(() {
        _classSubjects = classSubjects;
        _loading = false;
        _error = null;
      });

      // Defensive fallback only: resolve any missing subject name quietly
      // from the catalog. Never rendered as a selectable catalog itself.
      if (classSubjects.any((cs) => cs.subjectName.isEmpty)) {
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
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFriendlyMessage(e, st, 'ClassSubjectManagementScreen');
      });
    }
  }

  Future<void> _openAddSubjects() async {
    final added = await showAddClassSubjectsDialog(
      context,
      classId: widget.classId,
      className: widget.className,
      alreadyAssignedSubjectIds: _classSubjects.map((cs) => cs.subjectId).toSet(),
    );
    if (added == true) _loadData();
  }

  Future<void> _editSubjectType(ClassSubjectModel classSubject) async {
    final updated = await showEditSubjectTypeDialog(
      context,
      classId: classSubject.classId,
      subjectId: classSubject.subjectId,
      subjectName: _subjectNameFor(classSubject),
      className: widget.className,
      currentIsExamSubject: classSubject.isExamSubject,
    );
    if (updated == null || !mounted) return;
    _loadData();
  }

  Future<void> _removeSubject(ClassSubjectModel classSubject) async {
    final subjectName = _subjectNameFor(classSubject);
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Remove Subject?',
      message:
          '$subjectName will no longer be taught by ${widget.className}. '
          'This removes the class-subject assignment entirely — it is not '
          'the same as marking it Non-Exam.',
      confirmLabel: 'Remove',
    );
    if (confirmed != true || !mounted) return;

    final result = await ClassSubjectsService().deleteClassSubject(
      widget.classId,
      classSubject.subjectId,
    );
    if (!mounted) return;
    if (result is ClassSubjectSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$subjectName removed from ${widget.className}.'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
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
    final body = Container(
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
          if (!isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final isDesktop = isDesktopWebAdminLayout(context);
                      if (isDesktop && widget.onNavigateToPage != null) {
                        widget.onNavigateToPage!('classDetail', arguments: {
                          'classId': widget.classId,
                          'className': widget.className,
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Subjects',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.className,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openAddSubjects,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, color: kTextSecondaryColor),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${widget.className} Subjects',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimaryBlue,
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
                              ),
                            if (_classSubjects.isEmpty)
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
                              else
                                ..._visibleSubjects.map((cs) => _buildSubjectCard(cs)),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) return body;
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(child: body),
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
