import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/widgets/class_roster_print_dialog.dart';
import 'package:kobac/school_admin/widgets/class_marks_print_dialog.dart';
import 'package:kobac/school_admin/pages/create_student_screen.dart';
import 'package:kobac/school_admin/pages/student_detail_screen.dart';
import 'package:kobac/school_admin/pages/class_subject_management_screen.dart';
import 'package:kobac/school_admin/pages/rankings_pages.dart';
import 'package:kobac/school_admin/pages/class_merge_page.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminClassDetailsScreen extends StatefulWidget {
  final int classId;
  final String className;
  final int? initialAcademicYearId;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminClassDetailsScreen({
    Key? key,
    required this.classId,
    required this.className,
    this.initialAcademicYearId,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminClassDetailsScreen> createState() =>
      _AdminClassDetailsScreenState();
}

class _AdminClassDetailsScreenState extends State<AdminClassDetailsScreen> {
  /// Single source of truth: the exact list displayed in the UI. Print uses this list.
  List<StudentModel> _students = [];
  bool _loading = true;
  String? _error;
  int? _academicYearId;
  int _studentCount = 0;

  @override
  void initState() {
    super.initState();
    _academicYearId = widget.initialAcademicYearId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeYear());
  }

  Future<void> _initializeYear() async {
    final years = context.read<AcademicYearsProvider>();
    await years.ensureLoaded();
    if (!mounted) return;
    final initialYearId = _academicYearId;
    final active = years.activeYear;
    if (initialYearId == null && active == null) {
      setState(() {
        _loading = false;
        _error = years.error ?? 'No active academic year set';
      });
      return;
    }
    _academicYearId ??= active!.id;
    await _loadStudents();
  }

  String get _selectedAcademicYearName {
    final years = context.read<AcademicYearsProvider>().years;
    for (final year in years) {
      if (year.id == _academicYearId) return year.name;
    }
    return 'the selected academic year';
  }

  Future<void> _manageClassSubjects() async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!(
        'classSubjects',
        arguments: {'classId': widget.classId, 'className': widget.className},
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClassSubjectManagementScreen(
          classId: widget.classId,
          className: widget.className,
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class subjects updated'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    }
  }

  Future<void> _openClassMerge(BuildContext context) async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!(
        'classMerge',
        arguments: {
          'classId': widget.classId,
          'className': widget.className,
          'academicYearId': _academicYearId,
        },
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassMergePage(
          classId: widget.classId,
          className: widget.className,
          initialAcademicYearId: _academicYearId,
        ),
      ),
    );
    if (mounted) await _loadStudents();
  }

  Future<void> _loadStudents() async {
    final yearId = _academicYearId;
    if (yearId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _students = [];
      _studentCount = 0;
    });
    final result = await ClassesService().getClass(
      widget.classId,
      academicYearId: yearId,
    );
    if (!mounted) return;
    if (result is ClassError) {
      setState(() {
        _loading = false;
        _error = result.message;
        _students = [];
        _studentCount = 0;
      });
      return;
    }
    final details = (result as ClassSuccess<ClassModel>).data;
    final list = details.students;
    setState(() {
      _students = list;
      _studentCount = details.studentCount;
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final yearsProvider = context.watch<AcademicYearsProvider>();
    final years = yearsProvider.years;
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
                  _BackButton(
                    onPressed: () {
                      final isDesktop = isDesktopWebAdminLayout(context);
                      if (isDesktop && widget.onNavigateToPage != null) {
                        widget.onNavigateToPage!('classes');
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
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
            child: DropdownButtonFormField<int>(
              key: ValueKey(_academicYearId),
              initialValue: _academicYearId,
              decoration: const InputDecoration(
                labelText: 'Academic year',
                prefixIcon: Icon(Icons.calendar_month_rounded),
                isDense: true,
              ),
              items: years
                  .map(
                    (year) => DropdownMenuItem<int>(
                      value: year.id,
                      child: Text(year.name),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (value) async {
                      if (value == null || value == _academicYearId) return;
                      setState(() {
                        _academicYearId = value;
                        _error = null;
                        _students = [];
                        _studentCount = 0;
                      });
                      await _loadStudents();
                    },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _academicYearId == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassRankingsPage(
                          classId: widget.classId,
                          className: widget.className,
                          academicYearId: _academicYearId!,
                        ),
                      ),
                    ),
              icon: const Icon(Icons.emoji_events_rounded),
              label: const Text('View Rankings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryBlue,
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 620;
                final buttonWidth = narrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 24) / 3;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () async {
                                final isDesktop = isDesktopWebAdminLayout(
                                  context,
                                );
                                if (isDesktop &&
                                    widget.onNavigateToPage != null) {
                                  widget.onNavigateToPage!(
                                    'addStudent',
                                    arguments: {
                                      'initialClassId': widget.classId,
                                      'initialAcademicYearId': _academicYearId,
                                    },
                                  );
                                } else {
                                  final created = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => CreateStudentScreen(
                                            initialClassId: widget.classId,
                                          ),
                                        ),
                                      );
                                  if (created == true && mounted)
                                    _loadStudents();
                                }
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
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _manageClassSubjects(),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                        label: const Text('Manage subjects'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton.icon(
                        onPressed: (_loading || _students.isEmpty)
                            ? null
                            : () => showClassRosterPrintDialog(
                                context,
                                classId: widget.classId,
                                className: widget.className,
                                studentCount: _studentCount,
                                initialAcademicYearId: _academicYearId,
                              ),
                        icon: const Icon(Icons.print_rounded, size: 20),
                        label: const Text('Print Class List'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton.icon(
                        onPressed: (_loading || _students.isEmpty)
                            ? null
                            : () => showClassMarksPrintDialog(
                                context,
                                classId: widget.classId,
                                className: widget.className,
                                studentCount: _studentCount,
                                initialAcademicYearId: _academicYearId,
                              ),
                        icon: const Icon(Icons.assessment_rounded, size: 20),
                        label: const Text('Print Class Marks'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _openClassMerge(context),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                        label: const Text('Move / Merge Students'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                          side: const BorderSide(color: kPrimaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
    );

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) return body;
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryGreen),
      );
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
                Icon(
                  Icons.people_outline_rounded,
                  size: 56,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No students enrolled in this class for '
                  '$_selectedAcademicYearName.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    final isDesktop = isDesktopWebAdminLayout(context);
                    if (isDesktop && widget.onNavigateToPage != null) {
                      widget.onNavigateToPage!(
                        'addStudent',
                        arguments: {
                          'initialClassId': widget.classId,
                          'initialAcademicYearId': _academicYearId,
                        },
                      );
                    } else {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CreateStudentScreen(
                            initialClassId: widget.classId,
                          ),
                        ),
                      );
                      if (created == true && mounted) _loadStudents();
                    }
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
              '$_studentCount student${_studentCount == 1 ? '' : 's'}',
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
          onTap: () {
            final isDesktop = isDesktopWebAdminLayout(context);
            if (isDesktop && widget.onNavigateToPage != null) {
              widget.onNavigateToPage!('studentDetail', arguments: student.id);
            } else {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => StudentDetailPage(
                        studentId: student.id,
                        initialAcademicYearId: _academicYearId,
                      ),
                    ),
                  )
                  .then((_) => _loadStudents());
            }
          },
        );
      },
    );
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
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
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
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPrimaryBlue.withOpacity(0.1),
                child: Text(
                  student.studentName.isNotEmpty
                      ? student.studentName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryBlue,
                      ),
                    ),
                    Text(
                      student.emisNumber.trim().isEmpty
                          ? '—'
                          : student.emisNumber,
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
