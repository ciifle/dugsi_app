import 'package:flutter/material.dart';
import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/parent/pages/parent_dashboard.dart';
import 'package:kobac/school_admin/pages/school_admin_screen.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/student/pages/student_dashboard.dart';
import 'package:kobac/teacher/pages/teacher_dashboard.dart';

// ---------- COLOR PALETTE ----------
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

// ---------- NOTICE MODEL ----------
class _NoticeData {
  final String title;
  final String description;
  final String time;
  final String date;

  const _NoticeData({
    required this.title,
    required this.description,
    required this.time,
    required this.date,
  });
}

// ---------------- ALL NOTICES SCREEN ----------------
class AllNoticesScreen extends StatelessWidget {
  const AllNoticesScreen({Key? key}) : super(key: key);

  final List<_NoticeData> _notices = const [
    _NoticeData(
      title: "🏛️ Campus Closure",
      description:
          "University will be closed for maintenance this Friday, June 12th.",
      time: "2 hours ago",
      date: "12 Jun",
    ),
    _NoticeData(
      title: "📝 Exam Registration",
      description:
          "Last date to submit exam forms is June 18th. Late fee applies after.",
      time: "Yesterday",
      date: "10 Jun",
    ),
    _NoticeData(
      title: "📚 New Arrivals",
      description: "Check out 50+ new books added to the library this week.",
      time: "2 days ago",
      date: "08 Jun",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSoftBlue, kSoftGreen],
            stops: [0.0, 1.0],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ---------------- HEADER ----------------
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
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
                      children: [
                        // FIXED: Back button with proper navigation
                        GestureDetector(
                          onTap: () {
                            // Check if can pop, if not, go to appropriate dashboard
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              // If can't pop, navigate to the appropriate dashboard based on user role
                              _navigateToDashboard(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Stay Updated",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "All Notices",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildNoticeStats(),
                  ],
                ),
              ),
            ),

            // ---------------- NOTICES LIST ----------------
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final notice = _notices[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildEnhancedNoticeCard(context, notice),
                  );
                }, childCount: _notices.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPER METHOD TO NAVIGATE TO DASHBOARD ----------------
  Future<void> _navigateToDashboard(BuildContext context) async {
    try {
      final user = await LocalAuthService().getCurrentUser();

      if (user == null) {
        // If no user, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return;
      }

      // Navigate to appropriate dashboard based on role
      Widget dashboard;
      switch (user.role) {
        case UserRole.student:
          dashboard = StudentDashboardScreen();
          break;
        case UserRole.parent:
          dashboard = const ParentDashboardScreen();
          break;
        case UserRole.teacher:
          dashboard = const TeacherDashboardScreen();
          break;
        case UserRole.schoolAdmin:
          dashboard = const SchoolAdminScreen();
          break;
        default:
          dashboard = const LoginPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
      );
    } catch (e) {
      // If error, go to login as fallback
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // ---------------- NOTICE STATS ----------------
  Widget _buildNoticeStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatChip(
            Icons.notifications_rounded,
            "Total",
            "${_notices.length}",
          ),
          Container(height: 20, width: 1, color: Colors.white30),
          _buildStatChip(Icons.new_releases_rounded, "New", "3"),
          Container(height: 20, width: 1, color: Colors.white30),
          _buildStatChip(Icons.priority_high_rounded, "Important", "1"),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- NOTICE CARD ----------------
  Widget _buildEnhancedNoticeCard(BuildContext context, _NoticeData notice) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _showNoticeDetails(context, notice),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notice.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  notice.date,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  notice.time,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- DIALOG ----------------
  void _showNoticeDetails(BuildContext context, _NoticeData notice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notice.title),
        content: Text(notice.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
