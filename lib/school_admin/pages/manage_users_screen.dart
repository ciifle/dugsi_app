import 'package:flutter/material.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/parents_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/edit_student_screen.dart';
import 'package:kobac/school_admin/pages/edit_teacher_screen.dart';
import 'package:kobac/school_admin/pages/edit_parent_screen.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

enum UserRoleFilter { all, students, teachers, parents }

/// One row in the combined "manage users" list.
class ManagedUserItem {
  final String role; // 'student' | 'teacher' | 'parent'
  final int id;
  final String name;
  final String subtitle;

  const ManagedUserItem({
    required this.role,
    required this.id,
    required this.name,
    required this.subtitle,
  });
}

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  UserRoleFilter _roleFilter = UserRoleFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late Future<List<ManagedUserItem>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _usersFuture = _fetchAllUsers();
    });
  }

  Future<List<ManagedUserItem>> _fetchAllUsers() async {
    final list = <ManagedUserItem>[];

    final studentsResult = await StudentsService().listStudents();
    if (studentsResult is StudentSuccess<List<StudentModel>>) {
      for (final s in studentsResult.data) {
        list.add(ManagedUserItem(
          role: 'student',
          id: s.id,
          name: s.studentName,
          subtitle: s.emisNumber.trim().isEmpty ? '—' : s.emisNumber,
        ));
      }
    }

    final teachersResult = await TeachersService().listTeachers();
    if (teachersResult is TeacherSuccess<List<TeacherModel>>) {
      for (final t in teachersResult.data) {
        list.add(ManagedUserItem(
          role: 'teacher',
          id: t.id,
          name: t.fullName,
          subtitle: t.email,
        ));
      }
    }

    final parentsResult = await ParentsService().listParents();
    if (parentsResult is ParentSuccess<List<ParentModel>>) {
      for (final p in parentsResult.data) {
        list.add(ManagedUserItem(
          role: 'parent',
          id: p.id,
          name: p.name,
          subtitle: p.email,
        ));
      }
    }

    return list;
  }

  List<ManagedUserItem> _filter(List<ManagedUserItem> list) {
    List<ManagedUserItem> byRole = list;
    switch (_roleFilter) {
      case UserRoleFilter.students:
        byRole = list.where((u) => u.role == 'student').toList();
        break;
      case UserRoleFilter.teachers:
        byRole = list.where((u) => u.role == 'teacher').toList();
        break;
      case UserRoleFilter.parents:
        byRole = list.where((u) => u.role == 'parent').toList();
        break;
      case UserRoleFilter.all:
        break;
    }
    if (_searchQuery.isEmpty) return byRole;
    final q = _searchQuery.toLowerCase();
    return byRole.where((u) {
      return u.name.toLowerCase().contains(q) || u.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  void _onEditUser(ManagedUserItem user) {
    final Widget page;
    switch (user.role) {
      case 'student':
        page = EditStudentScreen(studentId: user.id);
        break;
      case 'teacher':
        page = EditTeacherScreen(teacherId: user.id);
        break;
      case 'parent':
        page = EditParentScreen(parentId: user.id);
        break;
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) _loadUsers();
    });
  }

  Future<void> _onDeleteUser(ManagedUserItem user) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete user?',
      message: 'Delete ${user.name}? This action cannot be undone.',
    );
    if (confirmed != true || !mounted) return;
    bool ok = false;
    String errorMsg = 'Could not delete. Please try again.';
    switch (user.role) {
      case 'student':
        final r = await StudentsService().deleteStudent(user.id);
        if (r is StudentSuccess) ok = true; else if (r is StudentError) errorMsg = r.message;
        break;
      case 'teacher':
        final r = await TeachersService().deleteTeacher(user.id);
        if (r is TeacherSuccess) ok = true; else if (r is TeacherError) errorMsg = r.message;
        break;
      case 'parent':
        final r = await ParentsService().deleteParent(user.id);
        if (r is ParentSuccess) ok = true; else if (r is ParentError) errorMsg = r.message;
        break;
    }
    if (!mounted) return;
    if (ok) {
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  String _roleFilterLabel(UserRoleFilter f) {
    switch (f) {
      case UserRoleFilter.all:
        return 'All';
      case UserRoleFilter.students:
        return 'Students';
      case UserRoleFilter.teachers:
        return 'Teachers';
      case UserRoleFilter.parents:
        return 'Parents';
    }
  }

  IconData _roleFilterIcon(UserRoleFilter f) {
    switch (f) {
      case UserRoleFilter.all:
        return Icons.filter_list_rounded;
      case UserRoleFilter.students:
        return Icons.person_rounded;
      case UserRoleFilter.teachers:
        return Icons.school_rounded;
      case UserRoleFilter.parents:
        return Icons.family_restroom_rounded;
    }
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
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Manage Users",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: "Search users...",
                            prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryBlue),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: kPrimaryBlue.withOpacity(0.15),
                      child: PopupMenuButton<UserRoleFilter>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 120),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        icon: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(_roleFilterIcon(_roleFilter), color: kPrimaryBlue, size: 22),
                        ),
                        tooltip: _roleFilterLabel(_roleFilter),
                        onSelected: (v) => setState(() => _roleFilter = v),
                        itemBuilder: (context) => UserRoleFilter.values.map((f) {
                          return PopupMenuItem(
                            value: f,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_roleFilterIcon(f), size: 18, color: kPrimaryBlue),
                                const SizedBox(width: 8),
                                Text(_roleFilterLabel(f), style: const TextStyle(fontSize: 13, color: kPrimaryBlue)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: kPrimaryGreen,
                  child: FutureBuilder<List<ManagedUserItem>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                      }
                      if (snapshot.hasError) {
                        final msg = userFriendlyMessage(snapshot.error!, null, 'ManageUsersScreen');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _loadUsers,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final all = snapshot.data ?? [];
                      final filtered = _filter(all);
                      if (filtered.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty ? 'No users found' : 'No users match your search',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          return _UserCard(
                            item: user,
                            onEdit: () => _onEditUser(user),
                            onDelete: () => _onDeleteUser(user),
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

/// 3D-style action button for Edit/Delete on user cards.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final ManagedUserItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
            BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-3, -3), spreadRadius: 0.2),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(_iconForRole(item.role), color: kPrimaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _roleDisplayName(item.role),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            _ActionButton(
              icon: Icons.edit_outlined,
              color: kPrimaryGreen,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForRole(String role) {
    switch (role) {
      case 'student':
        return Icons.person_rounded;
      case 'teacher':
        return Icons.school_rounded;
      case 'parent':
        return Icons.family_restroom_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _roleDisplayName(String role) {
    switch (role) {
      case 'student':
        return 'Student';
      case 'teacher':
        return 'Teacher';
      case 'parent':
        return 'Parent';
      default:
        return role;
    }
  }
}
