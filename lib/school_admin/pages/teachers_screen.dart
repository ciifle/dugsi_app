import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/teacher_screen.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/school_admin/pages/create_teacher_screen.dart';
import 'package:kobac/school_admin/pages/edit_teacher_screen.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kTeacherCardRadius = 12.0;

class TeacherListScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const TeacherListScreen({
    super.key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  late Future<TeacherResult<List<TeacherModel>>> _teachersFuture;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  void _loadTeachers() {
    setState(() {
      _teachersFuture = TeachersService().listTeachers();
    });
  }

  List<TeacherModel> _filter(List<TeacherModel> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((t) {
      return t.fullName.toLowerCase().contains(q) ||
          (t.email.toLowerCase().contains(q)) ||
          (t.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _navigateToCreate() async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('addTeacher');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTeacherScreen()),
    );
    if (result == true) _loadTeachers();
  }

  void _navigateToDetail(TeacherModel teacher) {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('teacherDetail', arguments: teacher.id);
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TeacherDetailsPage(teacherId: teacher.id),
          ),
        )
        .then((_) => _loadTeachers());
  }

  void _navigateToEdit(TeacherModel teacher) async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('editTeacher', arguments: teacher.id);
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTeacherScreen(teacherId: teacher.id),
      ),
    );
    if (result == true) _loadTeachers();
  }

  void _deleteTeacher(TeacherModel teacher) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete teacher?',
      message:
          'Delete teacher ${teacher.fullName}? This will also delete the linked user.',
    );
    if (confirmed != true) return;
    final result = await TeachersService().deleteTeacher(teacher.id);
    if (!mounted) return;
    if (result is TeacherSuccess) {
      _loadTeachers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${teacher.fullName} deleted'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as TeacherError).message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context)
        : _buildMobilePageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) return body;
    return Scaffold(backgroundColor: kBgColor, body: body);
  }

  Widget _buildMobilePageBody(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgColor, kPrimaryBlue.withValues(alpha: 0.02)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPremiumHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: kPrimaryBlue.withValues(alpha: 0.03),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search teachers...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: kPrimaryBlue,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadTeachers(),
                color: kPrimaryGreen,
                child: FutureBuilder<TeacherResult<List<TeacherModel>>>(
                  future: _teachersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _TeacherCardSkeletonList();
                    }
                    if (snapshot.hasError) {
                      final userMsg = userFriendlyMessage(
                        snapshot.error!,
                        null,
                        'TeacherListScreen',
                      );
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _loadTeachers,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final result = snapshot.data;
                    if (result == null) {
                      return const Center(child: Text('No data'));
                    }
                    if (result is TeacherError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _loadTeachers,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final teachers = _filter(
                      (result as TeacherSuccess<List<TeacherModel>>).data,
                    );
                    if (teachers.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                          ),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No teachers yet'
                                      : 'No teachers match your search',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        return _TeacherCard(
                          teacher: teacher,
                          onTap: () => _navigateToDetail(teacher),
                          onEdit: () => _navigateToEdit(teacher),
                          onDelete: () => _deleteTeacher(teacher),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              _BackButton(onPressed: () => Navigator.of(context).pop()),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teachers',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: kPrimaryBlue,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage all teacher records and information',
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
                  Icons.person_rounded,
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
                        'Teacher records',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Manage your teachers',
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPageBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE8ECF2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search teachers...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade500,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Teacher Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Phone',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<TeacherResult<List<TeacherModel>>>(
              future: _teachersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryBlue),
                  );
                }
                if (snapshot.hasError) {
                  final userMsg = userFriendlyMessage(
                    snapshot.error!,
                    null,
                    'TeacherListScreen',
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
                          onPressed: _loadTeachers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final result = snapshot.data;
                if (result == null) return const Center(child: Text('No data'));
                if (result is TeacherError) {
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
                          onPressed: _loadTeachers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final teachers = _filter(
                  (result as TeacherSuccess<List<TeacherModel>>).data,
                );
                if (teachers.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No teachers yet'
                                  : 'No teachers match your search',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return _TeacherRow(
                      teacher: teacher,
                      onTap: () => _navigateToDetail(teacher),
                      onEdit: () => _navigateToEdit(teacher),
                      onDelete: () => _deleteTeacher(teacher),
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
}

class _TeacherRow extends StatelessWidget {
  final TeacherModel teacher;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherRow({
    required this.teacher,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      teacher.fullName.isNotEmpty
                          ? teacher.fullName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      teacher.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kPrimaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                teacher.email,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                teacher.phone ?? '—',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                teacher.gender ?? '—',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: kPrimaryGreen,
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

// ignore: unused_element
class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGreen.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final TeacherModel teacher;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard({
    required this.teacher,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
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
                      teacher.fullName.isNotEmpty
                          ? teacher.fullName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
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
                          teacher.fullName,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            teacher.email.isEmpty
                                ? 'Email not available'
                                : teacher.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: kPrimaryBlue,
                    size: 25,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE8ECF2)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TeacherInfo(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: (teacher.phone?.trim().isNotEmpty ?? false)
                          ? teacher.phone!
                          : 'Not available',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TeacherInfo(
                      icon: Icons.school_rounded,
                      label: 'University',
                      value:
                          (teacher.graduatedUniversity?.trim().isNotEmpty ??
                              false)
                          ? teacher.graduatedUniversity!
                          : 'Not available',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TeacherAction(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      color: kPrimaryGreen,
                      background: const Color(0xFFEDF8EF),
                      border: const Color(0xFFD4EBD8),
                      onPressed: onEdit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TeacherAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: const Color(0xFFE53945),
                      background: const Color(0xFFFFF0F2),
                      border: const Color(0xFFFFD8DC),
                      onPressed: onDelete,
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

class _TeacherInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TeacherInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

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
            child: Icon(icon, color: kPrimaryBlue, size: 17),
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

class _TeacherAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Color border;
  final VoidCallback onPressed;

  const _TeacherAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.border,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: color,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}

class _TeacherCardSkeletonList extends StatelessWidget {
  const _TeacherCardSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 256,
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3EAF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12023471),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TeacherSkeleton(width: 58, height: 58, circular: true),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TeacherSkeleton(width: 150, height: 15),
                      SizedBox(height: 9),
                      _TeacherSkeleton(width: 120, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _TeacherSkeleton(width: double.infinity, height: 70),
            SizedBox(height: 14),
            _TeacherSkeleton(width: double.infinity, height: 48),
          ],
        ),
      ),
    );
  }
}

class _TeacherSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final bool circular;

  const _TeacherSkeleton({
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
