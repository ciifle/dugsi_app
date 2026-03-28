import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/class_subjects_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/printing/class_letter_pdf.dart';
import 'package:kobac/school_admin/pages/create_student_screen.dart';
import 'package:kobac/school_admin/pages/student_detail_screen.dart';
import 'package:kobac/school_admin/pages/class_subject_management_screen.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminClassDetailsScreen extends StatefulWidget {
  final int classId;
  final String className;

  const AdminClassDetailsScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<AdminClassDetailsScreen> createState() => _AdminClassDetailsScreenState();
}

class _AdminClassDetailsScreenState extends State<AdminClassDetailsScreen> {
  /// Single source of truth: the exact list displayed in the UI. Print uses this list.
  List<StudentModel> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _manageClassSubjects() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClassSubjectManagementScreen(
          classId: widget.classId,
          className: widget.className,
        ),
      ),
    );
    if (result == true && mounted) {
      // No need to reload students, just show success message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class subjects updated'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await StudentsService().listStudents(classId: widget.classId);
    if (!mounted) return;
    if (result is StudentError) {
      setState(() {
        _loading = false;
        _error = result.message;
        _students = [];
      });
      return;
    }
    var list = (result as StudentSuccess<List<StudentModel>>).data;
    // Filter by classId (snake_case class_id is mapped to classId in model); backend may already filter by class_id
    list = list.where((s) => s.classId == widget.classId).toList();
    if (kDebugMode) {
      debugPrint('[ClassDetails] schoolId=(see Print log) classId=${widget.classId} students=${list.length}');
    }
    setState(() {
      _students = list;
      _loading = false;
      _error = null;
    });
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
                    _BackButton(onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Class',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.className,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : () async {
                          final created = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => CreateStudentScreen(initialClassId: widget.classId),
                            ),
                          );
                          if (created == true && mounted) _loadStudents();
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 20),
                        label: const Text('Add student'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          side: const BorderSide(color: kPrimaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : () => _manageClassSubjects(),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                        label: const Text('Manage subjects'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_loading || _students.isEmpty) ? null : () => _printClassLetter(context),
                        icon: const Icon(Icons.print_rounded, size: 20),
                        label: const Text('Print class letter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadStudents(),
                  color: kPrimaryGreen,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _loadStudents);
    }
    if (_students.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No students in this class',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => CreateStudentScreen(initialClassId: widget.classId),
                      ),
                    );
                    if (created == true && mounted) _loadStudents();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add student'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _students.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_students.length} student${_students.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          );
        }
        final student = _students[index - 1];
        return _StudentRow(
          student: student,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudentDetailPage(studentId: student.id),
            ),
          ).then((_) => _loadStudents()),
        );
      },
    );
  }

  Future<void> _printClassLetter(BuildContext context) async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to print'), backgroundColor: kPrimaryBlue),
      );
      return;
    }
    // Use the exact list displayed (single source of truth); do NOT refetch.
    final studentsToPrint = List<StudentModel>.from(_students);
    if (kDebugMode) {
      final schoolId = context.read<AuthProvider>().user?.schoolId;
      debugPrint('[Print] schoolId=$schoolId classId=${widget.classId} students=${studentsToPrint.length} first=${studentsToPrint.isNotEmpty ? studentsToPrint.first.id : 'none'}');
    }
    try {
      final classModel = ClassModel(id: widget.classId, name: widget.className);
      final pdfBytes = await buildClassLetterPdf(
        classModel: classModel,
        students: studentsToPrint,
        schoolName: null,
      );
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                const SizedBox(height: 16),
                TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;

  const _StudentRow({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPrimaryBlue.withOpacity(0.1),
                child: Text(
                  student.studentName.isNotEmpty ? student.studentName.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kPrimaryBlue),
                    ),
                    Text(
                      student.emisNumber.trim().isEmpty ? '—' : student.emisNumber,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
