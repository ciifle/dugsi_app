import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/student/pages/academic_activity.dart';
import 'package:kobac/student/pages/exam_schedule.dart';
import 'package:kobac/student/pages/student_attendance.dart';
import 'package:kobac/student/pages/student_fees.dart';
import 'package:kobac/student/pages/student_notices.dart';
import 'package:kobac/student/pages/student_profile.dart';
import 'package:kobac/student/pages/student_quizzes.dart';
import 'package:kobac/student/pages/student_result.dart';
import 'package:kobac/student/pages/student_marks_screen.dart';
import 'package:kobac/student/pages/student_timetable_screen.dart';
import 'package:kobac/student/pages/student_payments_screen.dart';
import 'package:kobac/student/pages/student_pay_fee_screen.dart';
import 'package:kobac/messages/messages_screen.dart';

// ---------- COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kDarkGreen = Color(0xFF3D8C30);
const Color kDarkBlue = Color(0xFF011A3D);
const Color kSoftPurple = Color(0xFF4A6FA5);
const Color kSoftPink = Color(0xFF7CB86E);
const Color kSoftOrange = Color(0xFFF59E0B);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

// ==================== DRAWER ITEM MODEL ====================
class DrawerItem {
  final String label;
  final IconData icon;
  final Widget? screen;
  final bool isLogout;

  const DrawerItem({
    required this.label,
    required this.icon,
    this.screen,
    this.isLogout = false,
  });
}

// ==================== CLEAN WHITE APP DRAWER ====================
class AppDrawer extends StatelessWidget {
  AppDrawer({Key? key}) : super(key: key);

  static const List<DrawerItem> _allItems = [
    DrawerItem(label: "Dashboard", icon: Icons.dashboard_rounded),
    DrawerItem(
      label: "Timetable",
      icon: Icons.schedule_rounded,
      screen: StudentTimetableScreen(),
    ),
    DrawerItem(
      label: "Marks",
      icon: Icons.grade_rounded,
      screen: StudentMarksScreen(),
    ),
    DrawerItem(
      label: "Results",
      icon: Icons.stars_rounded,
      screen: StudentResultsScreen(),
    ),
    DrawerItem(
      label: "Fees",
      icon: Icons.account_balance_wallet_rounded,
      screen: StudentFeesScreen(),
    ),
    DrawerItem(
      label: "Payments",
      icon: Icons.payment_rounded,
      screen: StudentPaymentsScreen(),
    ),
    DrawerItem(
      label: "Attendance",
      icon: Icons.calendar_month_rounded,
      screen: StudentAttendanceScreen(),
    ),
    DrawerItem(
      label: "Academic Activity",
      icon: Icons.auto_stories_rounded,
      screen: StudentAcademicActivityScreen(),
    ),
    DrawerItem(
      label: "Quizzes",
      icon: Icons.quiz_rounded,
      screen: StudentQuizzesScreen(),
    ),
    DrawerItem(
      label: "Exam Schedule",
      icon: Icons.event_available_rounded,
      screen: StudentExamScheduleScreen(),
    ),
    DrawerItem(
      label: "Notices",
      icon: Icons.notifications_rounded,
      screen: AllNoticesScreen(),
    ),
    DrawerItem(
      label: "Messages",
      icon: Icons.message_rounded,
      screen: const MessagesScreen(),
    ),
    DrawerItem(
      label: "Profile",
      icon: Icons.person_rounded,
      screen: StudentProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(3, 0),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildMenuItems(context),
                    _buildLogoutButton(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.name ?? 'Student';
    final initials = name.isNotEmpty ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase() : 'S';
    final idOrEmail = user?.emisNumber ?? user?.email ?? '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
          stops: const [0.2, 0.6, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials.isEmpty ? 'S' : initials,
                    style: const TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Student',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        idOrEmail.contains('@') ? idOrEmail : 'ID: $idOrEmail',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final feesEnabled = context.watch<AuthProvider>().feesEnabled;
    final items = feesEnabled
        ? _allItems
        : _allItems.where((i) => i.label != 'Fees' && i.label != 'Payments').toList();
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItem(context, item, index);
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, DrawerItem item, int index) {
    final bool isDashboard = item.label == "Dashboard";
    final bool isNotices = item.label == "Notices";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (isDashboard) return;
            if (item.screen != null) {
              Future.delayed(const Duration(milliseconds: 200), () {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => item.screen!,
                    ),
                  );
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDashboard ? kPrimaryGreen.withOpacity(0.08) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getItemColor(index),
                        _getItemColor(index).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getItemColor(index).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isDashboard
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isDashboard ? kPrimaryBlue : kTextPrimary,
                    ),
                  ),
                ),
                if (isNotices)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: kErrorColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (!isDashboard)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kTextSecondary.withOpacity(0.4),
                    size: 12,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FIXED LOGOUT BUTTON ====================
  // This button now directly navigates to the login page
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Navigator.pop(context);
            await context.read<AuthProvider>().logout();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  kErrorColor.withOpacity(0.05),
                  kErrorColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: kErrorColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kErrorColor, kErrorColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kErrorColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kErrorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Kobac Student v1.0.0',
            style: TextStyle(
              color: kTextSecondary.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemColor(int index) {
    final colors = [
      kPrimaryBlue,
      kPrimaryGreen,
      kSoftOrange,
      kSoftPurple,
      kSoftPink,
    ];
    return colors[index % colors.length];
  }
}
