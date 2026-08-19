import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

// ---------- COLOR PALETTE (same as other teacher screens) ----------
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);

/// Teacher Classes screen: unique classes from assignments; tap class to see students.
class TeacherClassesScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  /// When false, renders bare content with no Scaffold/AppBar/back arrow —
  /// used when this screen is hosted as a tab inside the Teacher mobile
  /// shell (which owns the single persistent header + bottom nav).
  final bool showAppBar;

  const TeacherClassesScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  TeacherDashboardModel? _dashboard;
  bool _loading = true;
  String? _error;

  List<TeacherAssignmentModel> get _assignments =>
      _dashboard?.assignments ?? [];

  /// Unique classes: prefer dashboard.assignedClasses, else derive from assignments. Never show "class 0".
  List<({int id, String name})> get _uniqueClasses {
    final assigned = _dashboard?.assignedClasses ?? [];
    if (assigned.isNotEmpty) {
      return assigned.map((c) => (id: c.id, name: c.displayName)).toList();
    }
    final seen = <int>{};
    final out = <({int id, String name})>[];
    for (final a in _assignments) {
      if (a.classId > 0 && seen.add(a.classId)) {
        out.add((id: a.classId, name: a.classDisplayName));
      }
    }
    return out;
  }

  /// Subjects taught in a class, joined from the already-loaded assignments —
  /// no extra API call, no invented data.
  String _subjectsFor(String className) {
    final subjects = _assignments
        .where((a) => a.classDisplayName == className)
        .map((a) => a.subjectName)
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(', ');
    return subjects.isEmpty ? '—' : subjects;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await TeacherService().getDashboard();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is TeacherSuccess<TeacherDashboardModel>) {
        _dashboard = result.data;
        _error = null;
      } else {
        _dashboard = null;
        _error = (result as TeacherError).message;
      }
    });
  }

  Future<void> _showStudentsForClass(int classId, String className) async {
    if (classId == 0) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 48,
                color: kTextSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                'No class assigned. Students are linked to assigned classes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: kTextPrimary),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
      return;
    }
    final result = await TeacherService().listStudentsByClass(classId);
    if (!mounted) return;
    if (widget.embedBodyOnly) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
            ),
            child: _StudentsBottomSheet(
              className: className,
              result: result,
              onClose: () => Navigator.pop(ctx),
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentsBottomSheet(
        className: className,
        result: result,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildDesktopBody() {
    if (_loading) {
      return const TeacherWebSurface(
        child: TeacherWebCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: kPrimaryBlue),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return TeacherWebSurface(
        child: TeacherWebCard(
          child: TeacherErrorState(message: _error!, onRetry: _loadDashboard),
        ),
      );
    }
    if (_uniqueClasses.isEmpty) {
      return TeacherWebSurface(
        child: TeacherWebCard(
          child: TeacherEmptyState(
            icon: Icons.class_outlined,
            title: 'No assignments yet',
            message: 'Contact your school admin to get classes assigned.',
          ),
        ),
      );
    }

    return TeacherWebSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TeacherWebSectionTitle(
            title: 'My Classes',
            subtitle: 'View and manage your assigned classes.',
          ),
          const SizedBox(height: 16),
          TeacherWebCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const TeacherWebTableHeader(
                  columns: ['Class', 'Subject(s)', ''],
                ),
                ...List.generate(_uniqueClasses.length, (index) {
                  final classItem = _uniqueClasses[index];
                  return TeacherWebTableRow(
                    onTap: () =>
                        _showStudentsForClass(classItem.id, classItem.name),
                    cells: [
                      Text(
                        classItem.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kPrimaryBlue,
                        ),
                      ),
                      Text(
                        _subjectsFor(classItem.name),
                        style: const TextStyle(color: teacherWebTextSecondary),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showStudentsForClass(
                            classItem.id,
                            classItem.name,
                          ),
                          child: const Text('View Students'),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedBodyOnly) {
      return _buildDesktopBody();
    }

    final listSlivers = <Widget>[
      if (_loading)
        const SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: kPrimaryBlue),
            ),
          ),
        )
      else if (_error != null)
        SliverFillRemaining(
          child: Center(
            child: TeacherErrorState(message: _error!, onRetry: _loadDashboard),
          ),
        )
      else if (_uniqueClasses.isEmpty)
        const SliverFillRemaining(
          child: Center(
            child: TeacherEmptyState(
              icon: Icons.class_outlined,
              title: 'No assignments yet',
              message: 'Contact your school admin to get classes assigned.',
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final c = _uniqueClasses[index];
              return _ClassCard(
                className: c.name,
                subjects: _subjectsFor(c.name),
                onTap: () => _showStudentsForClass(c.id, c.name),
              );
            }, childCount: _uniqueClasses.length),
          ),
        ),
    ];

    if (!widget.showAppBar) {
      return ColoredBox(
        color: teacherWebBg,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: listSlivers,
        ),
      );
    }

    final body = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 96,
          pinned: true,
          backgroundColor: kPrimaryBlue,
          leading: Container(
            margin: const EdgeInsets.only(left: 12, top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(10),
            ),
          ),
          flexibleSpace: const FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: 56, bottom: 16),
            centerTitle: false,
            title: Text(
              'My Classes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        ...listSlivers,
      ],
    );

    return Scaffold(backgroundColor: teacherWebBg, body: body);
  }
}

class _ClassCard extends StatelessWidget {
  final String className;
  final String subjects;
  final VoidCallback onTap;

  const _ClassCard({
    required this.className,
    required this.subjects,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: teacherWebBorder),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.class_rounded,
                    color: kPrimaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Subjects: $subjects',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentsBottomSheet extends StatelessWidget {
  final String className;
  final TeacherResult<List<TeacherStudentModel>> result;
  final VoidCallback onClose;

  const _StudentsBottomSheet({
    required this.className,
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.people_rounded, color: kPrimaryBlue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Students — $className',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                  color: kTextSecondary,
                ),
              ],
            ),
          ),
          Flexible(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (result is TeacherError) {
      final err = result as TeacherError;
      final is403 = err.statusCode == 403;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              is403 ? Icons.block_rounded : Icons.error_outline_rounded,
              size: 48,
              color: kErrorColor,
            ),
            const SizedBox(height: 12),
            Text(
              is403 ? 'You are not assigned to this class.' : err.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: kTextPrimary),
            ),
          ],
        ),
      );
    }
    final students = (result as TeacherSuccess<List<TeacherStudentModel>>).data;
    if (students.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: TeacherEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No students found in this class',
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final name = s.name?.isNotEmpty == true ? s.name! : 'Student ${s.id}';
        final emis = s.emisNumber?.isNotEmpty == true ? s.emisNumber! : '—';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: teacherWebBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPrimaryBlue.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    Text(
                      'EMIS: $emis',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
