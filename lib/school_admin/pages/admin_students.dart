import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/student_detail_screen.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/school_admin/pages/create_student_screen.dart';
import 'package:kobac/school_admin/pages/edit_student_screen.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kStudentCardRadius = 20.0;

class AdminStudentsScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminStudentsScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  late Future<StudentResult<List<StudentModel>>> _studentsFuture;
  String searchQuery = '';
  String? _studentStatus;
  int? _academicYearId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studentsFuture = Future.value(StudentSuccess(<StudentModel>[]));
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final years = context.read<AcademicYearsProvider>();
    await years.ensureLoaded();
    if (!mounted) return;
    _academicYearId = years.activeYear?.id;
    _loadStudents();
  }

  void _loadStudents() {
    setState(() {
      _studentsFuture = StudentsService().listStudents(
        academicYearId: _academicYearId,
        studentStatus: _studentStatus,
        search: searchQuery,
        page: 1,
        limit: 50,
      );
    });
  }

  List<StudentModel> _filter(List<StudentModel> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((s) {
      return s.studentName.toLowerCase().contains(q) ||
          (s.emisNumber.toLowerCase().contains(q)) ||
          (s.telephone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _navigateToCreate() async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('addStudent');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateStudentScreen()),
    );
    if (result == true) _loadStudents();
  }

  void _navigateToDetail(StudentModel student) {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('studentDetail', arguments: student.id);
      return;
    }

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

  void _navigateToEdit(StudentModel student) async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('editStudent', arguments: student.id);
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditStudentScreen(studentId: student.id),
      ),
    );
    if (result == true) _loadStudents();
  }

  void _deleteStudent(StudentModel student) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete student?',
      message:
          'Delete student ${student.studentName}? This will also delete the linked user.',
    );
    if (confirmed != true) return;
    final result = await StudentsService().deleteStudent(student.id);
    if (!mounted) return;
    if (result is StudentSuccess) {
      _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.studentName} deleted'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as StudentError).message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildPageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return body;
    }

    return Scaffold(backgroundColor: const Color(0xFFF8F9FC), body: body);
  }

  Widget _buildPageBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: Column(
        children: [
          if (!isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly))
            _buildPremiumHeader(context),
          // Search and filters section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 650;
                final search = _buildSearchField();
                final filters = Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [_buildAcademicYearFilter(), _buildStatusFilters()],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [search, const SizedBox(height: 12), filters],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 16),
                    filters,
                  ],
                );
              },
            ),
          ),
          // Students list
          Expanded(
            child: FutureBuilder<StudentResult<List<StudentModel>>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _StudentCardSkeletonList();
                }
                if (snapshot.hasError) {
                  final userMsg = userFriendlyMessage(
                    snapshot.error!,
                    null,
                    'AdminStudentsScreen',
                  );
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadStudents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF023471),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final result = snapshot.data;
                if (result == null) return const Center(child: Text('No data'));
                if (result is StudentError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadStudents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF023471),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final students = _filter(
                  (result as StudentSuccess<List<StudentModel>>).data,
                );
                if (students.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              kStudentCardRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 60,
                                color: kPrimaryBlue.withValues(alpha: 0.25),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No students found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kPrimaryBlue,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (searchQuery.isEmpty) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _navigateToCreate,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add First Student'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5AB04B),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _StudentCard(
                      student: student,
                      onTap: () => _navigateToDetail(student),
                      onEdit: () => _navigateToEdit(student),
                      onDelete: () => _deleteStudent(student),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2))),
        boxShadow: [
          BoxShadow(
            color: Color(0x16023471),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StudentsBackButton(onPressed: () => Navigator.of(context).pop()),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: kPrimaryBlue,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage all student records and information',
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3EAF4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18023471),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: kPrimaryBlue,
                  size: 27,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE3EAF4)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16023471),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FF),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: kPrimaryBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student records',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Manage your students',
                        maxLines: 2,
                        style: TextStyle(
                          color: kPrimaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _navigateToCreate,
                  icon: const Icon(Icons.add_rounded, size: 21),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(92, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    shadowColor: const Color(0x555AB04B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x18023471),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        onSubmitted: (_) => _loadStudents(),
        decoration: InputDecoration(
          hintText: 'Search students...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded, color: kPrimaryBlue),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                    _loadStudents();
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14023471),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in <String?>[null, 'Active', 'Inactive'])
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _studentStatus = value);
                _loadStudents();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _studentStatus == value ? kPrimaryBlue : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value ?? 'All',
                  style: TextStyle(
                    color: _studentStatus == value
                        ? Colors.white
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcademicYearFilter() {
    final years = context.watch<AcademicYearsProvider>().years;
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        value: years.any((year) => year.id == _academicYearId)
            ? _academicYearId
            : null,
        decoration: const InputDecoration(
          labelText: 'Academic Year',
          prefixIcon: Icon(Icons.calendar_month_rounded),
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: years
            .map(
              (year) => DropdownMenuItem(
                value: year.id,
                child: Text(
                  year.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null || value == _academicYearId) return;
          setState(() {
            _academicYearId = value;
            searchQuery = _searchController.text.trim();
          });
          _loadStudents();
        },
      ),
    );
  }
}

class _StudentsBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StudentsBackButton({required this.onPressed});

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
              color: kPrimaryBlue.withValues(alpha: 0.08),
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

class _StatusFilterLabel extends StatelessWidget {
  final String label;

  const _StatusFilterLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StudentRow extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentRow({
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
      ),
      child: Row(
        children: [
          // Avatar and Name
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF023471).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    student.studentName.isNotEmpty
                        ? student.studentName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023471),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF023471),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.sex ?? '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // EMIS Number
          Expanded(
            flex: 1,
            child: Text(
              student.emisNumber.trim().isEmpty ? '—' : student.emisNumber,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          // Class
          Expanded(
            flex: 1,
            child: Text(
              student.classDisplayName,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          // Phone
          Expanded(
            flex: 1,
            child: Text(
              student.telephone ?? '—',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (student.absenteeismStatus?.toLowerCase() == 'active'
                            ? const Color(0xFF5AB04B)
                            : Colors.orange)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.absenteeismStatus ?? 'Active',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: student.absenteeismStatus?.toLowerCase() == 'active'
                      ? const Color(0xFF5AB04B)
                      : Colors.orange[800],
                ),
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF5AB04B),
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red[400],
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active =
        (student.absenteeismStatus ?? 'Active').toLowerCase() == 'active';
    final statusColor = active ? kPrimaryGreen : Colors.red;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kStudentCardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE3EAF4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1C023471),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x0D023471),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F7FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6ABCEB),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18023471),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          student.studentName.isEmpty
                              ? '?'
                              : student.studentName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: 1,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.studentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EMIS: ${student.emisNumber.trim().isEmpty ? '—' : student.emisNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          active ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFFE8ECF2)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StudentInfo(
                      label: 'Class',
                      value: student.classDisplayName,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StudentInfo(
                      label: 'Phone',
                      value: (student.telephone?.trim().isNotEmpty ?? false)
                          ? student.telephone!
                          : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: const Color(0xFFE8ECF2)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 19),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFEDF8EF),
                        foregroundColor: kPrimaryGreen,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFD4EBD8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFFF0F2),
                        foregroundColor: const Color(0xFFE53945),
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFFFD8DC)),
                        ),
                      ),
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

class _StudentInfo extends StatelessWidget {
  final String label;
  final String value;

  const _StudentInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              label == 'Class' ? Icons.school_rounded : Icons.phone_rounded,
              color: kPrimaryBlue,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCardSkeletonList extends StatelessWidget {
  const _StudentCardSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 210,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kStudentCardRadius),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SkeletonBlock(width: 48, height: 48, circular: true),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBlock(width: 150, height: 14),
                      SizedBox(height: 8),
                      _SkeletonBlock(width: 90, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 28),
            _SkeletonBlock(width: 42, height: 9),
            SizedBox(height: 8),
            _SkeletonBlock(width: 120, height: 13),
            SizedBox(height: 24),
            _SkeletonBlock(width: double.infinity, height: 42),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final bool circular;

  const _SkeletonBlock({
    required this.width,
    required this.height,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF2),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(8),
      ),
    );
  }
}
