import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';

// ---------- COLOR PALETTE (same as other teacher screens) ----------
const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kSoftBlue = Color(0xFFE6F0FF);
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF636E72);
const Color _kErrorColor = Color(0xFFEF4444);

/// One student row with class name (for display).
class _StudentWithClass {
  final TeacherStudentModel student;
  final String className;

  _StudentWithClass(this.student, this.className);
}

/// Shows all students from the teacher's assigned classes.
/// Data: GET /api/teacher/dashboard for classes, then GET /api/teacher/classes/{class_id}/students per class.
class TeacherStudentsListScreen extends StatefulWidget {
  /// When provided (e.g. from dashboard), classes are used immediately; students are still fetched per class.
  final TeacherDashboardModel? initialDashboard;

  const TeacherStudentsListScreen({Key? key, this.initialDashboard}) : super(key: key);

  @override
  State<TeacherStudentsListScreen> createState() => _TeacherStudentsListScreenState();
}

class _TeacherStudentsListScreenState extends State<TeacherStudentsListScreen> {
  TeacherDashboardModel? _dashboard;
  List<_StudentWithClass> _students = [];
  bool _loading = true;
  String? _error;

  List<TeacherAssignedClassModel> get _assignedClasses {
    if (_dashboard?.assignedClasses != null && _dashboard!.assignedClasses.isNotEmpty) {
      return _dashboard!.assignedClasses;
    }
    // Derive from assignments
    final seen = <int>{};
    final out = <TeacherAssignedClassModel>[];
    for (final a in _dashboard?.assignments ?? []) {
      if (a.classId > 0 && seen.add(a.classId)) {
        out.add(TeacherAssignedClassModel(id: a.classId, name: a.classDisplayName));
      }
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDashboard != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _dashboard = widget.initialDashboard);
        _loadStudents();
      });
    } else {
      _loadDashboardThenStudents();
    }
  }

  Future<void> _loadDashboardThenStudents() async {
    setState(() {
      _loading = true;
      _error = null;
      _students = [];
    });
    final result = await TeacherService().getDashboard();
    if (!mounted) return;
    if (result is TeacherError) {
      setState(() {
        _loading = false;
        _dashboard = null;
        _error = result.message;
      });
      return;
    }
    _dashboard = (result as TeacherSuccess<TeacherDashboardModel>).data;
    debugPrint('TeacherStudentsListScreen: assigned classes: ${_assignedClasses.length}');
    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (_dashboard == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _students = [];
    });
    final classes = _assignedClasses;
    if (classes.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    final combined = <int, _StudentWithClass>{};
    for (final c in classes) {
      final result = await TeacherService().listStudentsByClass(c.id);
      if (!mounted) return;
      if (result is TeacherError) continue;
      final list = (result as TeacherSuccess<List<TeacherStudentModel>>).data;
      for (final s in list) {
        combined.putIfAbsent(s.id, () => _StudentWithClass(s, c.displayName));
      }
    }
    if (!mounted) return;
    debugPrint('TeacherStudentsListScreen: students fetched: ${combined.length}');
    setState(() {
      _loading = false;
      _students = combined.values.toList();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _kPrimaryBlue,
            leading: Container(
              margin: const EdgeInsets.only(left: 12, top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(10),
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kPrimaryBlue, _kPrimaryBlue, _kPrimaryGreen],
                  stops: const [0.3, 0.7, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(bottom: 20),
                centerTitle: true,
                title: Text(
                  'My Students',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _kPrimaryBlue),
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 56, color: _kErrorColor.withOpacity(0.8)),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: _kTextPrimary),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _loadDashboardThenStudents,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(foregroundColor: _kPrimaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_students.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 56, color: _kTextSecondary),
                      const SizedBox(height: 16),
                      Text(
                        _assignedClasses.isEmpty
                            ? 'No classes assigned. Contact school admin.'
                            : 'No students found in your assigned classes.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: _kTextPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _students[index];
                    final name = item.student.name?.trim().isNotEmpty == true
                        ? item.student.name!
                        : 'Student ${item.student.id}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimaryBlue.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _kPrimaryBlue.withOpacity(0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                if (item.student.emisNumber != null && item.student.emisNumber!.isNotEmpty)
                                  Text(
                                    'EMIS: ${item.student.emisNumber}',
                                    style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kPrimaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.className,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kPrimaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _students.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
