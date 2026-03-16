import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/teacher_classes_screen.dart';
import 'package:kobac/teacher/pages/teacher_marks_screen.dart';
import 'package:kobac/teacher/pages/teacher_students_list_screen.dart';
import 'package:kobac/teacher/pages/teacher_drawer.dart';
import 'package:kobac/teacher/pages/weakly_schedule.dart';
import 'package:kobac/services/teacher_service.dart';
import 'package:kobac/services/auth_provider.dart';

// =======================
//  TEACHER DASHBOARD — Same layout/colors/widgets as before; dummy sections removed; real data from APIs.
// =======================
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

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TeacherDashboardModel? _dashboard;
  bool _loading = true;
  String? _error;

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

  int get _uniqueClassesCount {
    if (_dashboard == null) return 0;
    if (_dashboard!.assignedClasses.isNotEmpty) {
      return _dashboard!.assignedClasses.map((c) => c.displayName).toSet().length;
    }
    return _dashboard!.assignments.map((a) => a.classDisplayName).toSet().length;
  }

  List<TeacherAssignmentModel> get _assignments => _dashboard?.assignments ?? [];
  List<TeacherAssignedClassModel> get _assignedClasses => _dashboard?.assignedClasses ?? [];
  List<TeacherTimetableEntryModel> get _timetables => _dashboard?.timetables ?? [];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = auth.teacherProfile?.fullName?.trim().isNotEmpty == true
        ? auth.teacherProfile!.fullName!.trim()
        : (user?.name?.trim().isNotEmpty == true ? user!.name.trim() : 'Teacher');
    final initials = name.isNotEmpty ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase() : 'T';
    final roleLabel = user != null ? user.role.replaceAll('_', ' ') : 'Teacher';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kSoftBlue,
      drawer: const TeacherDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSoftBlue, kSoftGreen],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ---------- Header (same as original) ----------
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Welcome back! 👋",
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Teacher Dashboard",
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    roleLabel,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Text(
                                initials.isEmpty ? 'T' : initials,
                                style: const TextStyle(color: kPrimaryBlue, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading) ...[
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)))),
              ] else if (_error != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: kErrorColor.withOpacity(0.8)),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: kTextPrimary)),
                          const SizedBox(height: 16),
                          TextButton.icon(onPressed: _loadDashboard, icon: const Icon(Icons.refresh_rounded, size: 20), label: const Text('Retry'), style: TextButton.styleFrom(foregroundColor: kPrimaryBlue)),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // ---------- Four touchable cards (Total Classes, Assignments, Students, Schedule) — same layout as admin top cards ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          icon: Icons.class_rounded,
                          value: '$_uniqueClassesCount',
                          label: 'Total Classes',
                          color: kPrimaryBlue,
                          onTap: () => _navigateToScreen(context, const TeacherClassesScreen()),
                        ),
                        _StatCard(
                          icon: Icons.assignment_rounded,
                          value: '${_assignments.length}',
                          label: 'Assignments',
                          color: kPrimaryGreen,
                          onTap: () => _navigateToScreen(context, TeacherAssignmentsScreen(initialDashboard: _dashboard)),
                        ),
                        _StatCard(
                          icon: Icons.people_rounded,
                          value: _dashboard != null ? '${_assignedClasses.length}' : '—',
                          label: 'Students',
                          color: kSoftOrange,
                          onTap: () => _navigateToScreen(context, TeacherStudentsListScreen(initialDashboard: _dashboard)),
                        ),
                        _StatCard(
                          icon: Icons.calendar_month_rounded,
                          value: '—',
                          label: 'Timetable',
                          color: kDarkBlue,
                          onTap: () => _navigateToScreen(context, const TeacherWeeklyScheduleScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 24)),
                // ---------- Quick Actions (admin-style layout: GridView 2 cols, horizontal card per item) ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Quick Actions",
                          style: TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.45,
                          children: [
                            _TeacherQuickActionButton(
                              icon: Icons.how_to_reg_rounded,
                              label: 'Take Attendance',
                              color: kPrimaryBlue,
                              onTap: () => _navigateToScreen(context, const TeacherAttendanceScreen()),
                            ),
                            _TeacherQuickActionButton(
                              icon: Icons.edit_note_rounded,
                              label: 'Enter Marks',
                              color: kPrimaryGreen,
                              onTap: () => _navigateToScreen(context, const TeacherMarksScreen()),
                            ),
                            _TeacherQuickActionButton(
                              icon: Icons.grade_rounded,
                              label: 'View Marks',
                              color: kSoftOrange,
                              onTap: () => _navigateToScreen(context, const TeacherMarksScreen()),
                            ),
                            _TeacherQuickActionButton(
                              icon: Icons.assignment_rounded,
                              label: 'My Assignments',
                              color: kDarkBlue,
                              onTap: () => _navigateToScreen(context, TeacherAssignmentsScreen(initialDashboard: _dashboard)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ---------- Assigned classes (from dashboard) ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Assigned classes",
                          style: TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildAssignedClassesSection(),
                      ],
                    ),
                  ),
                ),
                // ---------- Assignments (subject — class) ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Assignments",
                          style: TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildAssignmentsSection(),
                      ],
                    ),
                  ),
                ),
                // ---------- Timetable (only when API returns data; empty state when truly none) ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Timetable",
                          style: TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildTimetableSection(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedClassesSection() {
    final classes = _assignedClasses.isNotEmpty
        ? _assignedClasses.map((c) => c.displayName).toSet().toList()
        : _assignments.map((a) => a.classDisplayName).toSet().toList();
    if (classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: const Text('No classes assigned.', style: TextStyle(fontSize: 14, color: kTextSecondary)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: classes.map((name) => Chip(
          label: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          backgroundColor: kSoftBlue,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        )).toList(),
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    if (_assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: const Text('No assignments yet.', style: TextStyle(fontSize: 14, color: kTextSecondary)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _assignments.take(8).map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.subject_rounded, size: 18, color: kPrimaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${a.subjectName.isEmpty ? "—" : a.subjectName} — ${a.classDisplayName}',
                  style: const TextStyle(fontSize: 14, color: kTextPrimary),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTimetableSection() {
    if (_timetables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: const Text('No timetable entries.', style: TextStyle(fontSize: 14, color: kTextSecondary)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _timetables.take(6).map((t) {
          final timeStr = t.period != null 
              ? (t.period!.name.isNotEmpty ? t.period!.name : 'P${t.period!.periodNumber}') 
              : t.timeRange;
          
          String shiftStr = '';
          if (t.period?.shift.isNotEmpty == true) {
            final s = t.period!.shift.toLowerCase();
            shiftStr = ' (${s == 'morning' ? 'Morning' : (s == 'afternoon' ? 'Afternoon' : s)})';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${t.day} $timeStr$shiftStr — ${t.subjectDisplayName} — ${t.classDisplayName}',
              style: const TextStyle(fontSize: 13, color: kTextPrimary),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen)).then((_) => _loadDashboard());
  }
}

/// Touchable stat card (4 cards: Total Classes, Assignments, Students, Today's) — admin-style 3D card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.white, blurRadius: 14, offset: const Offset(-4, -4), spreadRadius: 0.5),
              BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 24, offset: const Offset(6, 8)),
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(3, 5)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.white, blurRadius: 8, offset: const Offset(-2, -2), spreadRadius: 0.5),
                        BoxShadow(color: color.withOpacity(0.22), blurRadius: 10, offset: const Offset(3, 3)),
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 2)),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: kTextSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action button — same layout as admin (horizontal card, icon + label)
class _TeacherQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TeacherQuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.white, blurRadius: 14, offset: const Offset(-4, -4), spreadRadius: 0.5),
              BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 24, offset: const Offset(6, 8)),
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(3, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.white, blurRadius: 8, offset: const Offset(-2, -2), spreadRadius: 0.5),
                    BoxShadow(color: color.withOpacity(0.22), blurRadius: 10, offset: const Offset(3, 3)),
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 2)),
                  ],
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: kPrimaryBlue, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
