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
  TeacherDashboardModel? _dashboard;
  Map<int, String> _classNamesById = {};
  List<TeacherAssignmentModel> _assignments = [];
  List<({int id, String name})> _exams = [];
  List<({int id, String name})> _students = [];
  List<TeacherMarkModel> _marks = [];
  bool _loading = true;
  bool _initialLoadComplete = false;
  String? _error;
  
  int? _filterClassId;
  int? _filterSubjectId;
  int? _filterStudentId;
  int? _filterExamId;

  @override
  void initState() {
    super.initState();
    debugPrint('[Teacher Marks] Initial load started');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    debugPrint('[Teacher Marks] Loading dashboard data');
    
    final results = await Future.wait([
      TeacherService().getDashboard(),
      TeacherService().listExams(),
    ]);
    
    final dashboardResult = results[0];
    final examsResult = results[1];
    
    if (!mounted) return;
    setState(() {
      _loading = false;
      _initialLoadComplete = true;
      
      if (dashboardResult is TeacherSuccess<TeacherDashboardModel>) {
        _dashboard = dashboardResult.data;
        _assignments = _dashboard!.assignments;
        
        // Build class name mapping from dashboard
        _classNamesById.clear();
        for (final assignedClass in _dashboard!.assignedClasses) {
          _classNamesById[assignedClass.id] = assignedClass.name;
        }
        // Also add class names from assignments
        for (final assignment in _dashboard!.assignments) {
          final classId = assignment.classId;
          final className = assignment.classDisplayName;
          if (!_classNamesById.containsKey(classId) && className.isNotEmpty) {
            _classNamesById[classId] = className;
          }
        }
        
        debugPrint('[Teacher Marks] Loaded ${_assignments.length} assignments and ${_classNamesById.length} class names');
        if (_assignments.isNotEmpty && _filterClassId == null) {
          _filterClassId = _assignments.first.classId;
          _filterSubjectId = _assignments.first.subjectId;
          debugPrint('[Teacher Marks] Auto-selected class: $_filterClassId, subject: $_filterSubjectId');
        }
      }
      
      if (examsResult is TeacherSuccess<List<ExamModel>>) {
        _exams = examsResult.data.map((e) => (id: e.id, name: e.name)).toList();
        debugPrint('[Teacher Marks] Loaded ${_exams.length} exams');
      }
      
      _error = (dashboardResult is TeacherError) ? dashboardResult.message : null;
      _error = (_error ?? (examsResult is TeacherError)) ? examsResult.message : _error;
    });
    
    // Load marks after setting initial filters
    if (_filterClassId != null) {
      debugPrint('[Teacher Marks] Loading marks with initial filters');
      _loadMarks();
    } else {
      debugPrint('[Teacher Marks] No class assigned, loading all marks');
      _loadAllMarks();
    }
  }

  // Helper method to get class name by ID
  String _getClassName(int? classId) {
    if (classId == null) return 'No Class';
    return _classNamesById[classId] ?? 'Class #$classId';
  }

  void _showAddMark() async {
    if (_filterClassId == null) return;
    
    await showDialog(
      context: context,
      builder: (ctx) => _AddMarkDialog(
        classId: _filterClassId!,
        className: _getClassName(_filterClassId),
        dashboard: _dashboard,
        onSaved: () {
          _loadMarks();
        },
        assignments: _assignments,
      ),
    );
  }

  Future<void> _loadAllMarks() async {
    debugPrint('[Teacher Marks] Loading all marks without filters');
    setState(() => _loading = true);
    
    final result = await TeacherService().listMarks();
    
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is TeacherSuccess<List<TeacherMarkModel>>) {
        _marks = result.data;
        debugPrint('[Teacher Marks] Loaded ${_marks.length} marks');
      } else {
        _error = (result as TeacherError).message;
        _marks = [];
      }
    });
  }

  Future<void> _loadMarks() async {
    debugPrint('[Teacher Marks] Selected filters: class=$_filterClassId, subject=$_filterSubjectId, exam=$_filterExamId, student=$_filterStudentId');
    
    if (_filterClassId == null) {
      debugPrint('[Teacher Marks] No class filter, loading all marks');
      _loadAllMarks();
      return;
    }
    
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
        debugPrint('[Teacher Marks] Loaded ${_marks.length} marks');
      } else {
        _error = (result as TeacherError).message;
        _marks = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Marks'),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const TeacherDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Filters Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    items: _classNamesById.entries
                      .map((entry) => DropdownMenuItem<int?>(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                    onChanged: (value) {
                      debugPrint('[Teacher Marks] Class filter changed: $_filterClassId -> $value');
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
                      debugPrint('[Teacher Marks] Subject filter changed: $_filterSubjectId -> $value');
                      setState(() {
                        _filterSubjectId = value;
                        _filterExamId = null;
                      });
                      _loadMarks();
                    },
                  ),
                  const SizedBox(height: 8),
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
                    items: _exams
                        .map((e) => DropdownMenuItem<int?>(
                              value: e.id,
                              child: Text(e.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      debugPrint('[Teacher Marks] Exam filter changed: $_filterExamId -> $value');
                      setState(() {
                        _filterExamId = value;
                      });
                      _loadMarks();
                    },
                  ),
                ],
              ),
            ),
            // Marks List
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
                                Icon(Icons.error_outline_rounded, color: kErrorColor, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: kErrorColor, fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadInitialData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _marks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assessment_outlined, color: kTextSecondary, size: 64),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No marks found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: kTextSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting filters or add new marks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMarks,
                              color: kPrimaryBlue,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _marks.length,
                                itemBuilder: (context, index) {
                                  final mark = _marks[index];
                                  return _MarkCard(
                                    mark: mark,
                                    onUpdated: () => _loadMarks(),
                                  );
                                },
                              ),
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

class _MarkCard extends StatelessWidget {
  final TeacherMarkModel mark;
  final VoidCallback onUpdated;

  const _MarkCard({
    required this.mark,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => _EditMarkDialog(
                mark: mark,
                onUpdated: onUpdated,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.assessment,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mark.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mark.subjectName} - ${mark.examName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${mark.marksObtained}/${mark.maxMarks}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((mark.marksObtained / mark.maxMarks) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMarkDialog extends StatefulWidget {
  final int classId;
  final String className;
  final TeacherDashboardModel? dashboard;
  final VoidCallback onSaved;
  final List<TeacherAssignmentModel> assignments;

  const _AddMarkDialog({
    required this.classId,
    required this.className,
    required this.dashboard,
    required this.onSaved,
    required this.assignments,
  });

  @override
  State<_AddMarkDialog> createState() => _AddMarkDialogState();
}

class _AddMarkDialogState extends State<_AddMarkDialog> {
  int? _subjectId;
  int? _examId;
  final TextEditingController _maxMarks = TextEditingController();
  bool _submitting = false;
  bool _loading = true;
  List<TeacherStudentModel> _students = [];
  Map<int, TextEditingController> _marksControllers = {};
  List<({int id, String name})> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint('[AddMarkDialog] Loading data for class ${widget.classId}');
    setState(() => _loading = true);
    
    try {
      final results = await Future.wait([
        TeacherService().listStudentsByClass(widget.classId),
        TeacherService().listExams(),
      ]);
      
      final studentsResult = results[0];
      final examsResult = results[1];
      
      if (!mounted) return;
      
      setState(() {
        _loading = false;
        if (studentsResult is TeacherSuccess<List<TeacherStudentModel>>) {
          _students = studentsResult.data;
          // Initialize marks controllers for each student
          _marksControllers = {
            for (final student in _students) 
              student.id: TextEditingController(text: '0')
          };
          debugPrint('[AddMarkDialog] Loaded ${_students.length} students');
        }
        
        if (examsResult is TeacherSuccess<List<ExamModel>>) {
          _exams = examsResult.data.map((e) => (id: e.id, name: e.name)).toList();
          debugPrint('[AddMarkDialog] Loaded ${_exams.length} exams');
        }
      });
    } catch (e) {
      debugPrint('[AddMarkDialog] Error loading data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_subjectId == null || _examId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select subject and exam'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    final maxMarksText = _maxMarks.text.trim();
    if (maxMarksText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter max marks'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    final maxMarks = int.tryParse(maxMarksText);
    if (maxMarks == null || maxMarks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Max marks must be greater than 0'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    // Build records for students with entered marks
    final records = <Map<String, dynamic>>[];
    for (final student in _students) {
      final controller = _marksControllers[student.id];
      if (controller != null) {
        final marksText = controller.text.trim();
        if (marksText.isNotEmpty) {
          final marksObtained = int.tryParse(marksText);
          if (marksObtained != null && marksObtained >= 0 && marksObtained <= maxMarks) {
            records.add({
              'student_id': student.id,
              'marks_obtained': marksObtained,
            });
          } else if (marksObtained != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid marks for ${student.name}. Must be between 0 and $maxMarks'),
                backgroundColor: kErrorColor,
              ),
            );
            return;
          }
        }
      }
    }

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter marks for at least one student'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    
    try {
      final result = await TeacherService().createBulkMarks(
        examId: _examId!,
        classId: widget.classId,
        subjectId: _subjectId!,
        maxMarks: maxMarks,
        records: records,
      );
      
      if (!mounted) return;
      
      if (result is TeacherSuccess<List<TeacherMarkModel>>) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marks created successfully for ${records.length} students'),
            backgroundColor: kPrimaryGreen,
          ),
        );
        widget.onSaved();
      } else if (result is TeacherError) {
        String message = result.message;
        if (result.statusCode == 409) {
          message = 'Marks already exist for one or more students';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while saving marks'),
          backgroundColor: kErrorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classAssignments = widget.assignments.where((a) => a.classId == widget.classId).toList();
    final subjectList = classAssignments.map((a) => (
      id: a.subjectId, 
      name: a.subjectName
    )).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kDarkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add marks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Subject dropdown
                          DropdownButtonFormField<int?>(
                            value: _subjectId,
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              filled: true,
                              fillColor: kSoftBlue.withOpacity(0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: subjectList
                                .map((s) => DropdownMenuItem<int?>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _subjectId = value);
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Exam dropdown
                          DropdownButtonFormField<int?>(
                            value: _examId,
                            decoration: InputDecoration(
                              labelText: 'Exam',
                              filled: true,
                              fillColor: kSoftBlue.withOpacity(0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _exams
                                .map((e) => DropdownMenuItem<int?>(
                                      value: e.id,
                                      child: Text(e.name),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _examId = value);
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Max Marks input
                          TextFormField(
                            controller: _maxMarks,
                            decoration: InputDecoration(
                              labelText: 'Max Marks',
                              filled: true,
                              fillColor: kSoftBlue.withOpacity(0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Students list
                          if (_students.isNotEmpty) ...[
                            const Text(
                              'Students',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._students.map((student) {
                              final controller = _marksControllers[student.id];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: kTextPrimary,
                                            ),
                                          ),
                                          if (student.emisNumber?.isNotEmpty == true)
                                            Text(
                                              'EMIS: ${student.emisNumber}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: kTextSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          labelText: 'Marks',
                                          filled: true,
                                          fillColor: kSoftBlue.withOpacity(0.3),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ] else if (!_loading) ...[
                            const SizedBox(height: 40),
                            Icon(Icons.info_outline_rounded, color: kTextSecondary, size: 24),
                            const SizedBox(height: 8),
                            const Text(
                              'No students found in this class.',
                              style: TextStyle(color: kTextSecondary, fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save All'),
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
    
    try {
      final result = await TeacherService().updateMark(
        widget.mark.id,
        marksObtained: double.tryParse(marksObtained) ?? 0,
        maxMarks: double.tryParse(maxMarks) ?? 0,
      );
      
      if (!mounted) return;
      setState(() => _submitting = false);
      
      if (result is TeacherSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mark updated successfully'),
            backgroundColor: kPrimaryGreen,
          ),
        );
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result as TeacherError).message),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while updating mark'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Mark',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _marksObtained,
              decoration: InputDecoration(
                labelText: 'Marks Obtained',
                filled: true,
                fillColor: kSoftBlue.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxMarks,
              decoration: InputDecoration(
                labelText: 'Max Marks',
                filled: true,
                fillColor: kSoftBlue.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
