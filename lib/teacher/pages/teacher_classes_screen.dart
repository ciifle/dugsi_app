import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';

// ---------- COLOR PALETTE (same as other teacher screens) ----------
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftGreen = Color(0xFFEDF7EB);
const Color kDarkBlue = Color(0xFF01255C);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSoftOrange = Color(0xFFF59E0B);

/// Teacher Classes screen: unique classes from assignments; tap class to see students.
class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({Key? key}) : super(key: key);

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  List<TeacherAssignmentModel> _assignments = [];
  bool _loading = true;
  String? _error;

  /// Unique classes from assignments (by classId). Never show "class 0"; use Unassigned.
  List<({int id, String name})> get _uniqueClasses {
    final seen = <int>{};
    final out = <({int id, String name})>[];
    for (final a in _assignments) {
      if (seen.add(a.classId)) {
        out.add((id: a.classId, name: a.classDisplayName));
      }
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await TeacherService().listAssignments();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is TeacherSuccess<List<TeacherAssignmentModel>>) {
        _assignments = result.data;
        _error = null;
      } else {
        _assignments = [];
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
              const Icon(Icons.info_outline_rounded, size: 48, color: kTextSecondary),
              const SizedBox(height: 12),
              const Text('No class assigned. Students are linked to assigned classes.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: kTextPrimary)),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        ),
      );
      return;
    }
    final result = await TeacherService().listStudentsByClass(classId);
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: kPrimaryBlue,
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
                  colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                  stops: const [0.3, 0.7, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 20),
                centerTitle: true,
                title: const Text(
                  'Classes',
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
                  child: CircularProgressIndicator(color: kPrimaryBlue),
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
                      Icon(
                        _error!.toLowerCase().contains('profile') ? Icons.person_off_rounded : Icons.error_outline_rounded,
                        size: 56,
                        color: kTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: kTextPrimary),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _loadAssignments,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_uniqueClasses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_rounded, size: 56, color: kTextSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No assignments yet. Contact school admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: kTextPrimary),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _loadAssignments,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
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
                    final c = _uniqueClasses[index];
                    return _ClassCard(
                      classId: c.id,
                      className: c.name,
                      onTap: () => _showStudentsForClass(c.id, c.name),
                    );
                  },
                  childCount: _uniqueClasses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final int classId;
  final String className;
  final VoidCallback onTap;

  const _ClassCard({required this.classId, required this.className, required this.onTap});

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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.class_rounded, color: kPrimaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    className,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: kTextSecondary, size: 28),
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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
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
          Flexible(
            child: _buildContent(context),
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded, size: 48, color: kTextSecondary),
              SizedBox(height: 12),
              Text(
                'No students found in this class.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: kTextPrimary),
              ),
            ],
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
            color: kSoftBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryBlue.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPrimaryBlue.withOpacity(0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
                    Text('EMIS: $emis', style: TextStyle(fontSize: 12, color: kTextSecondary)),
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
