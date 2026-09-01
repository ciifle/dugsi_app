import 'package:flutter/material.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teacher_subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const _navy = Color(0xFF023471);
const _green = Color(0xFF5AB04B);

class AssignTeacherClassesDialog extends StatefulWidget {
  final List<ClassModel> classes;
  final List<AcademicYear> years;
  final int? initialAcademicYearId;

  const AssignTeacherClassesDialog({
    super.key,
    required this.classes,
    required this.years,
    this.initialAcademicYearId,
  });

  @override
  State<AssignTeacherClassesDialog> createState() =>
      _AssignTeacherClassesDialogState();
}

class _AssignTeacherClassesDialogState
    extends State<AssignTeacherClassesDialog> {
  late int? _yearId;
  int? _teacherId;
  List<TeacherModel> _teachers = [];
  TeacherSubjectsConfig? _config;
  List<_CompatibleClass> _compatible = [];
  Set<String> _existingKeys = {};
  bool _teachersLoading = true;
  bool _loadingClasses = false;
  bool _saving = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialAcademicYearId;
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final result = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      _teachersLoading = false;
      if (result is TeacherSuccess<List<TeacherModel>>) {
        _teachers = result.data;
      } else {
        _error = (result as TeacherError).message;
      }
    });
  }

  Future<void> _onTeacherChanged(int? teacherId) async {
    setState(() {
      _teacherId = teacherId;
      _config = null;
      _compatible = [];
      _existingKeys = {};
      _error = null;
      _loadingClasses = teacherId != null;
    });
    if (teacherId == null) return;
    await _reloadTeacherData(teacherId);
  }

  Future<void> _onYearChanged(int? yearId) async {
    setState(() {
      _yearId = yearId;
      _error = null;
      for (final item in _compatible) {
        item.selected = false;
      }
    });
    if (_teacherId != null) await _loadExisting(_teacherId!);
  }

  Future<void> _reloadTeacherData(int teacherId) async {
    final subjectResult = await TeacherSubjectsService().getSubjects(teacherId);
    if (!mounted || _teacherId != teacherId) return;
    if (subjectResult is TeacherSubjectsError) {
      setState(() {
        _loadingClasses = false;
        _error = subjectResult.message;
      });
      return;
    }
    final config =
        (subjectResult as TeacherSubjectsSuccess<TeacherSubjectsConfig>).data;
    setState(() => _config = config);
    if (config.subjects.isEmpty) {
      setState(() => _loadingClasses = false);
      return;
    }

    final results = await Future.wait(
      widget.classes.map(
        (schoolClass) async => MapEntry(
          schoolClass,
          await SchoolAdminAssignmentsService().listClassSubjects(
            schoolClass.id,
          ),
        ),
      ),
    );
    if (!mounted || _teacherId != teacherId) return;
    final compatible = <_CompatibleClass>[];
    for (final entry in results) {
      final result = entry.value;
      if (result is! AssignmentSuccess<List<ClassSubjectItem>>) continue;
      final classSubjectIds = result.data.map((subject) => subject.id).toSet();
      final matches = config.subjects
          .where((subject) => classSubjectIds.contains(subject.id))
          .toList();
      if (matches.isNotEmpty) {
        compatible.add(
          _CompatibleClass(
            schoolClass: entry.key,
            subjects: matches,
            subjectId: matches.length == 1 ? matches.first.id : null,
          ),
        );
      }
    }
    compatible.sort(
      (a, b) => a.schoolClass.name.toLowerCase().compareTo(
        b.schoolClass.name.toLowerCase(),
      ),
    );
    setState(() {
      _compatible = compatible;
      _loadingClasses = false;
    });
    await _loadExisting(teacherId);
  }

  Future<void> _loadExisting(int teacherId) async {
    final yearId = _yearId;
    if (yearId == null) {
      setState(() => _existingKeys = {});
      return;
    }
    final result = await SchoolAdminAssignmentsService().listAssignments(
      teacherId: teacherId,
      academicYearId: yearId,
    );
    if (!mounted || _teacherId != teacherId || _yearId != yearId) return;
    if (result is AssignmentSuccess<List<AssignmentModel>>) {
      setState(() {
        _existingKeys = result.data
            .map((item) => '${item.classId}:${item.subjectId}')
            .toSet();
        for (final item in _compatible) {
          if (item.subjectId != null &&
              _existingKeys.contains(
                '${item.schoolClass.id}:${item.subjectId}',
              )) {
            item.selected = false;
          }
        }
      });
    }
  }

  bool _alreadyAssigned(_CompatibleClass item, int subjectId) =>
      _existingKeys.contains('${item.schoolClass.id}:$subjectId');

  List<SubjectModel> _availableSubjects(_CompatibleClass item) => item.subjects
      .where((subject) => !_alreadyAssigned(item, subject.id))
      .toList();

  void _toggle(_CompatibleClass item, bool selected) {
    final available = _availableSubjects(item);
    if (available.isEmpty) return;
    setState(() {
      item.selected = selected;
      if (selected) {
        if (available.length == 1) {
          item.subjectId = available.first.id;
        } else if (!available.any((subject) => subject.id == item.subjectId)) {
          item.subjectId = null;
        }
      }
    });
  }

  List<_CompatibleClass> get _visible => _compatible
      .where(
        (item) =>
            item.schoolClass.name.toLowerCase().contains(_search.toLowerCase()),
      )
      .toList();

  List<_CompatibleClass> get _selected =>
      _compatible.where((item) => item.selected).toList();

  bool get _canSave =>
      !_saving &&
      !_loadingClasses &&
      _yearId != null &&
      _teacherId != null &&
      _selected.isNotEmpty &&
      _selected.every((item) => item.subjectId != null);

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final assignments = _selected
        .map(
          (item) => {
            'class_id': item.schoolClass.id,
            'subject_id': item.subjectId!,
          },
        )
        .toList();
    final result = await SchoolAdminAssignmentsService().createBulkAssignments(
      teacherId: _teacherId!,
      academicYearId: _yearId!,
      assignments: assignments,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is AssignmentSuccess<BulkAssignmentResponse>) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = (result as AssignmentError).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _config?.subjects ?? const <SubjectModel>[];
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: FormCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _header(),
              const Divider(height: 1, color: Color(0xFFE5EAF1)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Select3D<int?>(
                      value: widget.years.any((year) => year.id == _yearId)
                          ? _yearId
                          : null,
                      label: 'Academic Year *',
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Select academic year'),
                        ),
                        ...widget.years.map(
                          (year) => DropdownMenuItem<int?>(
                            value: year.id,
                            child: Text(
                              year.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: _saving ? null : _onYearChanged,
                    ),
                    const SizedBox(height: 14),
                    Select3D<int?>(
                      value: _teacherId,
                      label: 'Teacher *',
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Select teacher'),
                        ),
                        ..._teachers.map(
                          (teacher) => DropdownMenuItem<int?>(
                            value: teacher.id,
                            child: Text(
                              teacher.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: _teachersLoading || _saving
                          ? null
                          : _onTeacherChanged,
                    ),
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Teaching Subjects',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subjects
                            .map(
                              (subject) => Chip(
                                avatar: const Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: _navy,
                                ),
                                label: Text(subject.name),
                                backgroundColor: const Color(0xFFEAF1FF),
                                side: const BorderSide(
                                  color: Color(0xFFD6E2F5),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (_teacherId != null &&
                        !_loadingClasses &&
                        subjects.isEmpty) ...[
                      const SizedBox(height: 16),
                      _notice(
                        'No teaching subjects are assigned to this teacher. Manage Teaching Subjects from the Teachers page.',
                      ),
                    ],
                    if (_loadingClasses) ...[
                      const SizedBox(height: 28),
                      const Center(
                        child: CircularProgressIndicator(color: _green),
                      ),
                    ] else if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assign Classes',
                                  style: TextStyle(
                                    color: _navy,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Select the classes this teacher teaches.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_selected.length} selected',
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => setState(() => _search = value),
                        decoration: InputDecoration(
                          hintText: 'Search classes...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5EAF1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5EAF1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_compatible.isEmpty)
                        _notice(
                          'No classes contain any of this teacher’s teaching subjects.',
                        )
                      else
                        ..._visible.map(_classCard),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5EAF1)),
              Padding(
                padding: const EdgeInsets.all(18),
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
                        label: 'Save Assignments',
                        onPressed: _canSave ? _save : null,
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

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.assignment_ind_rounded, color: _navy),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Assign Teacher',
            style: TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );

  Widget _classCard(_CompatibleClass item) {
    final available = _availableSubjects(item);
    final fullyAssigned = available.isEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.selected
            ? _green.withValues(alpha: .07)
            : fullyAssigned
            ? const Color(0xFFF3F4F6)
            : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: item.selected
              ? _green.withValues(alpha: .5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: fullyAssigned ? null : () => _toggle(item, !item.selected),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Checkbox(
                  value: item.selected,
                  activeColor: _green,
                  onChanged: fullyAssigned
                      ? null
                      : (value) => _toggle(item, value ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.schoolClass.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        fullyAssigned
                            ? 'Already assigned'
                            : available.map((s) => s.name).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fullyAssigned
                              ? const Color(0xFF64748B)
                              : _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fullyAssigned)
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
          if (item.selected && available.length > 1) ...[
            const SizedBox(height: 10),
            Select3D<int?>(
              value: available.any((subject) => subject.id == item.subjectId)
                  ? item.subjectId
                  : null,
              label: 'Subject *',
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Select subject'),
                ),
                ...available.map(
                  (subject) => DropdownMenuItem<int?>(
                    value: subject.id,
                    child: Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => item.subjectId = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _notice(String message) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF4D58A)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF9A6700)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF7A5200)),
          ),
        ),
      ],
    ),
  );
}

class _CompatibleClass {
  final ClassModel schoolClass;
  final List<SubjectModel> subjects;
  int? subjectId;
  bool selected;

  _CompatibleClass({
    required this.schoolClass,
    required this.subjects,
    this.subjectId,
  }) : selected = false;
}
