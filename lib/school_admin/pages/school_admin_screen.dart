import 'package:flutter/material.dart';

import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';
import 'package:kobac/school_admin/pages/admin_profile.dart';
import 'package:kobac/school_admin/pages/admin_students.dart';
import 'package:kobac/school_admin/pages/mesaage_screen.dart';
import 'package:kobac/school_admin/pages/notifications_page.dart';
import 'package:kobac/school_admin/pages/notices_page.dart';
import 'package:kobac/school_admin/pages/payments_screen.dart';
import 'package:kobac/school_admin/pages/teachers_screen.dart';
import 'package:kobac/school_admin/widgets/drawer_widget.dart';
import 'package:kobac/services/dummy_school_service.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/school_admin/pages/messages_inbox_screen.dart';

/// --- Brand / Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471); // #023471
const Color kPrimaryGreen = Color(0xFF5AB04B); // #5AB04B
const Color kBgColor = Color(0xFFF0F3F7);
const Color kCardColor = Colors.white;

const double kCardRadius = 28.0;
const double kPadding = 20.0;

class SchoolAdminScreen extends StatefulWidget {
  const SchoolAdminScreen({Key? key}) : super(key: key);

  @override
  State<SchoolAdminScreen> createState() => _SchoolAdminScreenState();
}

class _SchoolAdminScreenState extends State<SchoolAdminScreen> {
  int? _studentCount;
  int? _teacherCount;
  bool _loading = true;
  String _userName = "School Admin";

  /// 0=Dashboard, 1=Messages, 2=Finance, 3=Profile
  int _bottomNavIndex = 0;

  final GlobalKey<NavigatorState> _nestedNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await LocalAuthService().getCurrentUser();

    if (user != null && user.role == UserRole.schoolAdmin) {
      final studentCount = await DummySchoolService().getStudentCount();
      final teacherCount = await DummySchoolService().getTeacherCount();

      if (!mounted) return;
      setState(() {
        _studentCount = studentCount;
        _teacherCount = teacherCount;
        _userName = user.name;
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _studentCount = 0;
        _teacherCount = 0;
        _userName = "School Admin";
        _loading = false;
      });
    }
  }

  Widget _buildTabView() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _bottomNavIndex == 0
              ? _TopHeaderCard(
                  title: _headerTitle(),
                  subtitle: "ADMIN PORTAL",
                  leading: Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: const _NeumorphicCircle(
                        child: Icon(Icons.menu_rounded, color: kPrimaryBlue, size: 22),
                      ),
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () => _nestedNavKey.currentState?.push(
                      MaterialPageRoute(builder: (_) => const NotificationsPage()),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const _NeumorphicCircle(
                          child: Icon(Icons.notifications_outlined, color: kPrimaryBlue, size: 22),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: kPrimaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: kCardColor, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _SimpleWhiteAppBar(title: _headerTitle()),
          Expanded(
            child: _buildBodyForIndex(context),
          ),
        ],
      ),
    );
  }

  void _onBottomNavChange(int i) {
    if (_nestedNavKey.currentState?.canPop() == true) {
      _nestedNavKey.currentState?.popUntil((route) => route.isFirst);
    }
    setState(() => _bottomNavIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      drawer: _bottomNavIndex == 0
          ? AppDrawer(
              onProfileTap: () {
                if (_nestedNavKey.currentState?.canPop() == true) {
                  _nestedNavKey.currentState?.popUntil((route) => route.isFirst);
                }
                setState(() => _bottomNavIndex = 3);
              },
              onNavigateToPage: (page) {
                _nestedNavKey.currentState?.push(
                  MaterialPageRoute(builder: (_) => page),
                );
              },
            )
          : null,
      body: Navigator(
        key: _nestedNavKey,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (_) => _buildTabView(),
            );
          }
          return null;
        },
      ),
      bottomNavigationBar: _BottomNav(
        index: _bottomNavIndex,
        onChange: _onBottomNavChange,
      ),
    );
  }

  String _headerTitle() {
    switch (_bottomNavIndex) {
      case 0:
        return _userName.isEmpty ? "School Admin" : _userName;
      case 1:
        return "Messages";
      case 2:
        return "Finance";
      case 3:
        return "My Profile";
      default:
        return "School Admin";
    }
  }

  Widget _buildBodyForIndex(BuildContext context) {
    switch (_bottomNavIndex) {
      case 1:
        return const MessagesInboxScreen(embedInParent: true);
      case 2:
        return const PaymentsScreen(embedInParent: true);
      case 3:
        return const AdminProfilePage(embedBodyOnly: true);
      default:
        return _buildDashboardBody(context);
    }
  }

  Widget _buildDashboardBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          _buildStatCards2x2(context),
          const SizedBox(height: 22),
          _buildFeesOverviewSection(context),
          const SizedBox(height: 22),
          _buildQuickActionsSection(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCards2x2(BuildContext context) {
    const parents = 0;
    const classes = 12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPadding),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.10,
        children: [
          _NeumorphicStatCard(
            icon: Icons.people_alt_rounded,
            iconBgColor: kPrimaryBlue.withOpacity(0.12),
            iconColor: kPrimaryBlue,
            label: "STUDENTS",
            value: _loading ? "..." : _formatCount(_studentCount ?? 0),
            growth: "+12%",
            onTap: () => _nestedNavKey.currentState?.push(MaterialPageRoute(builder: (_) => const AdminStudentsScreen())),
          ),
          _NeumorphicStatCard(
            icon: Icons.school_rounded,
            iconBgColor: kPrimaryGreen.withOpacity(0.12),
            iconColor: kPrimaryGreen,
            label: "TEACHERS",
            value: _loading ? "..." : "${_teacherCount ?? 0}",
            growth: "+2%",
            onTap: () => _nestedNavKey.currentState?.push(MaterialPageRoute(builder: (_) => const TeacherListScreen())),
          ),
          _NeumorphicStatCard(
            icon: Icons.family_restroom_rounded,
            iconBgColor: kPrimaryBlue.withOpacity(0.12),
            iconColor: kPrimaryBlue,
            label: "PARENTS",
            value: "$parents",
            growth: "+0%",
            onTap: () {},
          ),
          _NeumorphicStatCard(
            icon: Icons.class_rounded,
            iconBgColor: kPrimaryGreen.withOpacity(0.12),
            iconColor: kPrimaryGreen,
            label: "CLASSES",
            value: "$classes",
            growth: "+0%",
            onTap: () => _nestedNavKey.currentState?.push(MaterialPageRoute(builder: (_) => const AdminClassesPage())),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}k";
    return "$n";
  }

  Widget _buildFeesOverviewSection(BuildContext context) {
    const paidPercent = 0.75;
    const collected = 124;
    const pending = 42;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Fees Overview",
                style: TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => _nestedNavKey.currentState?.push(
                  MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                ),
                child: const Text(
                  "View Details",
                  style: TextStyle(fontSize: 14, color: kPrimaryBlue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NeumorphicCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 98,
                  height: 98,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 98,
                        height: 98,
                        child: CircularProgressIndicator(
                          value: paidPercent,
                          strokeWidth: 12,
                          backgroundColor: const Color(0xFFE8ECF2),
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryGreen),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "PAID",
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "${(paidPercent * 100).toInt()}%",
                            style: const TextStyle(fontSize: 20, color: kPrimaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _feesRowDot(
                        dotColor: kPrimaryGreen,
                        label: "Collected",
                        value: "\$$collected k",
                        valueColor: kPrimaryGreen,
                      ),
                      const SizedBox(height: 10),
                      _feesRowDot(
                        dotColor: Colors.grey.shade400,
                        label: "Pending",
                        value: "\$$pending k",
                        valueColor: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: paidPercent,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE8ECF2),
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feesRowDot({
    required Color dotColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ),
        Text(value, style: TextStyle(fontSize: 15, color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPadding),
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
              _QuickActionButton(
                icon: Icons.person_add_rounded,
                label: "Add Student",
                color: kPrimaryBlue,
                onTap: () => _nestedNavKey.currentState?.push(MaterialPageRoute(builder: (_) => const AdminStudentsScreen())),
              ),
              _QuickActionButton(
                icon: Icons.school_rounded,
                label: "Add Teacher",
                color: kPrimaryGreen,
                onTap: () => _nestedNavKey.currentState?.push(MaterialPageRoute(builder: (_) => const TeacherListScreen())),
              ),
              _QuickActionButton(
                icon: Icons.account_balance_wallet_rounded,
                label: "Manage Fees",
                color: kPrimaryGreen,
                onTap: () => _nestedNavKey.currentState?.push(MaterialPageRoute(builder: (_) => const PaymentsScreen())),
              ),
              _QuickActionButton(
                icon: Icons.bar_chart_rounded,
                label: "Reports",
                color: kPrimaryBlue,
                onTap: () => _nestedNavKey.currentState?.push(MaterialPageRoute(builder: (_) => NoticesPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ======= TOP HEADER CARD (same style as your dashboard image) =======
class _TopHeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final Widget trailing;

  const _TopHeaderCard({
    required this.title,
    required this.leading,
    required this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(kPadding, top + 8, kPadding, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.white, blurRadius: 18, offset: const Offset(-5, -5), spreadRadius: 0.5),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.15), blurRadius: 32, offset: const Offset(10, 12)),
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 18, offset: const Offset(5, 8)),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Same floating container as dashboard header, but title only (no menu, no notification) for Messages, Finance, Profile.
class _SimpleWhiteAppBar extends StatelessWidget {
  final String title;

  const _SimpleWhiteAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(kPadding, top + 8, kPadding, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.white, blurRadius: 18, offset: const Offset(-5, -5), spreadRadius: 0.5),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.15), blurRadius: 32, offset: const Offset(10, 12)),
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 18, offset: const Offset(5, 8)),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// ======= BOTTOM NAV (same 3D style) =======
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;

  const _BottomNav({required this.index, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.grid_view_rounded,
      Icons.chat_bubble_outline_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.person_rounded,
    ];
    const labels = ["Dashboard", "Messages", "Finance", "Profile"];

    return SafeArea(
      top: false,
      child: Material(
        elevation: 12,
        shadowColor: Colors.black38,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kCardRadius),
          topRight: Radius.circular(kCardRadius),
        ),
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kCardRadius),
              topRight: Radius.circular(kCardRadius),
            ),
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (i) {
              return _BottomNavItem(
                icon: icons[i],
                label: labels[i],
                isActive: index == i,
                onTap: () => onChange(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? kPrimaryBlue : const Color(0xFF5C5C5C);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======= Reusable Neumorphic Card =======
class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _NeumorphicCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 20, offset: const Offset(-6, -6), spreadRadius: 0.5),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 32, offset: const Offset(10, 12)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(5, 8)),
        ],
      ),
      child: child,
    );
  }
}

/// Header circular button style (3D)
class _NeumorphicCircle extends StatelessWidget {
  final Widget child;
  const _NeumorphicCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 12, offset: const Offset(-4, -4), spreadRadius: 0.5),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.22), blurRadius: 16, offset: const Offset(4, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(2, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Dashboard stat card (2x2)
class _NeumorphicStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;
  final String growth;
  final VoidCallback? onTap;

  const _NeumorphicStatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.growth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 18, offset: const Offset(-6, -6), spreadRadius: 0.5),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 30, offset: const Offset(10, 12)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(5, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-3, -3), spreadRadius: 0.5),
                BoxShadow(color: iconColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(3, 3)),
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(2, 2)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, color: kPrimaryBlue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            growth,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
    }
    return card;
  }
}

/// Quick action button (3D)
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
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
