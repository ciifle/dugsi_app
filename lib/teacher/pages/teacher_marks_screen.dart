import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';
import 'package:kobac/teacher/pages/teacher_drawer.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftGreen = Color(0xFFEDF7EB);
const Color kDarkGreen = Color(0xFF3A7A30);
const Color kDarkBlue = Color(0xFF01255C);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSoftOrange = Color(0xFFF59E0B);
const Color kCardColor = Colors.white;
const double kTopPadding = 40.0;

class TeacherMarksScreen extends StatefulWidget {
  const TeacherMarksScreen({Key? key}) : super(key: key);

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen> {
  List<TeacherAssignmentModel> _assignments = [];
  List<({int id, String name})> _exams = [];
  List<({int id, String name})> _students = [];
  List<TeacherMarkModel> _marks = [];
  bool _loading = true;
  String? _error;
  
  int? _filterClassId;
  int? _filterSubjectId;
  int? _filterStudentId;
  int? _filterExamId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      TeacherService().listAssignments(),
      TeacherService().listExams(),
    ]);
    
    if (!mounted) return;
    setState(() {
      _loading = false;
      final assignmentsResult = results[0];
      final examsResult = results[1];

      if (assignmentsResult is TeacherSuccess<List<TeacherAssignmentModel>>) {
        _assignments = assignmentsResult.data;
        if (_assignments.isNotEmpty && _filterClassId == null) {
          _filterClassId = _assignments.first.classId;
          _filterSubjectId = _assignments.first.subjectId;
        }
      }

      if (examsResult is TeacherSuccess<List<({int id, String name})>>) {
        _exams = examsResult.data;
      }
    });
  }

  void _showAddMark() async {
    if (_filterClassId == null) return;
    
    await showDialog(
      context: context,
      builder: (ctx) => _AddMarkDialog(
        classId: _filterClassId!,
        className: 'Class $_filterClassId',
        onSaved: () {
          _loadMarks();
        },
        assignments: _assignments,
      ),
    );
  }

  Future<void> _loadMarks() async {
    if (_filterClassId == null) return;
    
    setState(() => _loading = true);
    final result = await TeacherService().listMarks(
      classId: _filterClassId!,
      subjectId: _filterSubjectId,
      examId: _filterExamId,
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

  void _showEditMarkDialog(TeacherMarkModel mark) {
    showDialog(
      context: context,
      builder: (ctx) => _EditMarkDialog(
        mark: mark,
        onUpdated: () {
          _loadMarks();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(TeacherMarkModel mark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mark'),
        content: Text('Are you sure you want to delete the mark for ${mark.studentName ?? 'Student ${mark.studentId}'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await TeacherService().deleteMark(mark.id);
              if (!mounted) return;
              
              if (result is TeacherSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mark deleted successfully'),
                    backgroundColor: kPrimaryGreen,
                  ),
                );
                _loadMarks();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text((result as TeacherError).message),
                    backgroundColor: kErrorColor,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      appBar: AppBar(
        title: const Text('Marks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
              stops: [0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filters section
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  // Class filter
                  DropdownButtonFormField<int?>(
                    value: _filterClassId,
                    decoration: InputDecoration(
                      labelText: 'Class',
                      filled: true,
                      fillColor: kSoftBlue.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _assignments
                      .map((a) => (id: a.classId, name: 'Class ${a.classId}'))
                      .toSet()
                      .map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filterClassId = value;
                        _filterSubjectId = null;
                        _filterExamId = null;
                      });
                      _loadMarks();
                    },
                  ),
                  const SizedBox(height: 8),
                  // Subject filter
                  DropdownButtonFormField<int?>(
                    value: _filterSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      filled: true,
                      fillColor: kSoftBlue.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _filterClassId != null
                        ? _assignments
                            .where((a) => a.classId == _filterClassId)
                            .map((a) => DropdownMenuItem<int?>(
                                  value: a.subjectId,
                                  child: Text(a.subjectName),
                                ))
                            .toSet()
                            .toList()
                        : [],
                    onChanged: (value) {
                      setState(() {
                        _filterSubjectId = value;
                        _filterExamId = null;
                      });
                      _loadMarks();
                    },
                  ),
                  const SizedBox(height: 6),
                  // Exam filter
                  DropdownButtonFormField<int?>(
                    value: _filterExamId,
                    decoration: InputDecoration(
                      labelText: 'Exam',
                      filled: true,
                      fillColor: kSoftBlue.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _exams.map((e) => DropdownMenuItem<int?>(
                      value: e.id,
                      child: Text(e.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filterExamId = value;
                      });
                      _loadMarks();
                    },
                  ),
                ],
              ),
            ),
            // Marks list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _marks.isEmpty
                          ? const Center(
                              child: Text(
                                'No marks found for selected filters',
                                style: TextStyle(fontSize: 16, color: kTextSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _marks.length,
                              itemBuilder: (ctx, i) {
                                final mark = _marks[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    mark.studentName ?? 'Student ${mark.studentId}',
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    mark.subjectName ?? 'Subject ${mark.subjectId}',
                                                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    mark.examName ?? 'Exam ${mark.examId}',
                                                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${mark.marksObtained}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: kPrimaryBlue,
                                                  ),
                                                ),
                                                Text(
                                                  '/${mark.maxMarks}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: kTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              onPressed: () => _showEditMarkDialog(mark),
                                              icon: const Icon(Icons.edit_outlined, size: 20, color: kPrimaryGreen),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              onPressed: () => _showDeleteConfirmDialog(mark),
                                              icon: Icon(Icons.delete_outline, size: 20, color: kErrorColor),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ),
          ],
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
}

class _AddMarkDialog extends StatefulWidget {
  final int classId;
  final String className;
  final VoidCallback onSaved;
  final List<TeacherAssignmentModel> assignments;

  const _AddMarkDialog({
    required this.classId,
    required this.className,
    required this.onSaved,
    required this.assignments,
  });

  @override
  State<_AddMarkDialog> createState() => _AddMarkDialogState();
}

class _AddMarkDialogState extends State<_AddMarkDialog> {
  int? _subjectId;
  int? _studentId;
  int? _examId;
  
  bool _loadingSubjects = true;
  bool _loadingStudents = true;
  bool _loadingExams = false;
  
  List<({int id, String name})> _subjects = [];
  List<({int id, String name})> _students = [];
  List<TeacherExamModel> _exams = [];
  
  String? _subjectsError;
  String? _studentsError;
  String? _examsError;

  final _marksObtained = TextEditingController();
  final _maxMarks = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadSubjects(),
      _loadStudents(),
      _fetchExams(),
    ]);
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _subjectsError = null;
      _subjects = [];
      _subjectId = null;
    });
    
    try {
      final classAssignments = widget.assignments.where((a) => a.classId == widget.classId).toList();
      final subjectList = classAssignments.map((a) => (
        id: a.subjectId, 
        name: a.subjectName
      )).toList();
      
      setState(() {
        _loadingSubjects = false;
        _subjects = subjectList;
        if (_subjects.isNotEmpty) {
          _subjectId = _subjects.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSubjects = false;
        _subjectsError = 'Failed to load subjects: $e';
      });
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loadingStudents = true;
      _studentsError = null;
      _students = [];
      _studentId = null;
    });
    
    try {
      final result = await TeacherService().listStudentsByClass(widget.classId);
      
      if (!mounted) return;
      
      if (result is TeacherSuccess<List<TeacherStudentModel>>) {
        setState(() {
          _loadingStudents = false;
          _students = result.data.map((s) => (id: s.id, name: s.name ?? 'Student ${s.id}')).toList();
          if (_students.isNotEmpty) {
            _studentId = _students.first.id;
          }
        });
      } else {
        final error = result as TeacherError;
        setState(() {
          _loadingStudents = false;
          _studentsError = error.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStudents = false;
        _studentsError = 'Failed to load students: $e';
      });
    }
  }

  Future<void> _fetchExams() async {
    setState(() {
      _loadingExams = true;
      _examsError = null;
      _exams = [];
      _examId = null;
    });
    
    final result = await TeacherService().listExams();
    
    if (!mounted) return;
    
    setState(() {
      _loadingExams = false;
      if (result is TeacherSuccess<List<TeacherExamModel>>) {
        _exams = result.data;
        if (_exams.isNotEmpty) {
          _examId = _exams.first.id;
        }
      } else {
        _examsError = (result as TeacherError).message;
      }
    });
  }

  Future<void> _submit() async {
    if (_subjectId == null || _studentId == null || _examId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select exam, student, and subject'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    final marksObtained = _marksObtained.text.trim();
    final maxMarks = _maxMarks.text.trim();
    
    if (marksObtained.isEmpty || maxMarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both marks obtained and max marks'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    
    final result = await TeacherService().createMark(
      examId: _examId!,
      studentId: _studentId!,
      subjectId: _subjectId!,
      marksObtained: double.tryParse(marksObtained) ?? 0,
      maxMarks: double.tryParse(maxMarks) ?? 0,
    );
    
    if (!mounted) return;
    setState(() => _submitting = false);
    
    if (result is TeacherSuccess) {
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mark added successfully'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as TeacherError).message),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.white, blurRadius: 14, offset: const Offset(-4, -4), spreadRadius: 0.5),
              BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 24, offset: const Offset(6, 8)),
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(3, 5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                    stops: [0.3, 0.7, 1.0],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: kPrimaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add marks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Class: ${widget.className}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loadingSubjects)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: kPrimaryBlue, strokeWidth: 2)),
                      )
                    else if (_subjectsError != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kErrorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kErrorColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline_rounded, color: kErrorColor, size: 24),
                            const SizedBox(height: 8),
                            Text(_subjectsError!, style: TextStyle(color: kErrorColor, fontSize: 14)),
                          ],
                        ),
                      )
                    else if (_subjects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kTextSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline_rounded, color: kTextSecondary, size: 24),
                            const SizedBox(height: 8),
                            const Text(
                              'No subjects found for this class.',
                              style: TextStyle(color: kTextSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _subjectId,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          filled: true,
                          fillColor: kSoftBlue.withOpacity(0.4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _subjects.map((s) => DropdownMenuItem<int>(
                          value: s.id, 
                          child: Text(s.name)
                        )).toList(),
                        onChanged: (v) => setState(() => _subjectId = v),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    if (_loadingStudents)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: kPrimaryBlue, strokeWidth: 2)),
                      )
                    else if (_studentsError != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kErrorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kErrorColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline_rounded, color: kErrorColor, size: 24),
                            const SizedBox(height: 8),
                            Text(_studentsError!, style: TextStyle(color: kErrorColor, fontSize: 14)),
                          ],
                        ),
                      )
                    else if (_students.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kTextSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline_rounded, color: kTextSecondary, size: 24),
                            const SizedBox(height: 8),
                            const Text(
                              'No students found in this class.',
                              style: TextStyle(color: kTextSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _studentId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Student',
                          filled: true,
                          fillColor: kSoftBlue.withOpacity(0.4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _students.map((s) => DropdownMenuItem<int>(
                          value: s.id, 
                          child: Text(
                            s.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        )).toList(),
                        onChanged: (v) => setState(() => _studentId = v),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    if (_loadingExams)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: kPrimaryBlue, strokeWidth: 2)),
                      )
                    else if (_examsError != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kErrorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kErrorColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline_rounded, color: kErrorColor, size: 24),
                            const SizedBox(height: 8),
                            Text(_examsError!, style: TextStyle(color: kErrorColor, fontSize: 14)),
                          ],
                        ),
                      )
                    else if (_exams.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kTextSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline_rounded, color: kTextSecondary, size: 24),
                            const SizedBox(height: 8),
                            const Text(
                              'No exams available.',
                              style: TextStyle(color: kTextSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _examId,
                        decoration: InputDecoration(
                          labelText: 'Exam',
                          filled: true,
                          fillColor: kSoftBlue.withOpacity(0.4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _exams.map((e) => DropdownMenuItem<int>(
                          value: e.id, 
                          child: Text(e.name)
                        )).toList(),
                        onChanged: (v) => setState(() => _examId = v),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _marksObtained,
                            decoration: InputDecoration(
                              labelText: 'Marks Obtained',
                              filled: true,
                              fillColor: kSoftBlue.withOpacity(0.4),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxMarks,
                            decoration: InputDecoration(
                              labelText: 'Max Marks',
                              filled: true,
                              fillColor: kSoftBlue.withOpacity(0.4),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _submitting ? null : () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kPrimaryBlue.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _submitting ? null : _submit,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPrimaryGreen, kPrimaryGreen],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: kPrimaryGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Center(
                              child: _submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),
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
}

class _EditMarkDialog extends StatefulWidget {
  final TeacherMarkModel mark;
  final VoidCallback onUpdated;

  const _EditMarkDialog({
    required this.mark,
    required this.onUpdated,
  });

  @override
  State<_EditMarkDialog> createState() => _EditMarkDialogState();
}

class _EditMarkDialogState extends State<_EditMarkDialog> {
  late final TextEditingController _marksObtained;
  late final TextEditingController _maxMarks;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _marksObtained = TextEditingController(text: widget.mark.marksObtained.toString());
    _maxMarks = TextEditingController(text: widget.mark.maxMarks.toString());
  }

  @override
  void dispose() {
    _marksObtained.dispose();
    _maxMarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final marksObtained = _marksObtained.text.trim();
    final maxMarks = _maxMarks.text.trim();
    
    if (marksObtained.isEmpty || maxMarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both marks obtained and max marks'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    
    final result = await TeacherService().updateMark(
      widget.mark.id,
      marksObtained: double.tryParse(marksObtained) ?? 0,
      maxMarks: double.tryParse(maxMarks) ?? 0,
    );
    
    if (!mounted) return;
    setState(() => _submitting = false);
    
    if (result is TeacherSuccess) {
      widget.onUpdated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mark updated successfully'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as TeacherError).message),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.white, blurRadius: 14, offset: const Offset(-4, -4), spreadRadius: 0.5),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 24, offset: const Offset(6, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(3, 5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                  stops: [0.3, 0.7, 1.0],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: kPrimaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit marks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Student: ${widget.mark.studentName ?? 'Student ${widget.mark.studentId}'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Subject: ${widget.mark.subjectName ?? 'Subject ${widget.mark.subjectId}'}',
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                  ),
                  Text(
                    'Exam: ${widget.mark.examName ?? 'Exam ${widget.mark.examId}'}',
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marksObtained,
                          decoration: InputDecoration(
                            labelText: 'Marks Obtained',
                            filled: true,
                            fillColor: kSoftBlue.withOpacity(0.4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxMarks,
                          decoration: InputDecoration(
                            labelText: 'Max Marks',
                            filled: true,
                            fillColor: kSoftBlue.withOpacity(0.4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitting ? null : () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kPrimaryBlue.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: kPrimaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitting ? null : _submit,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimaryGreen, kPrimaryGreen],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: kPrimaryGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Update',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
