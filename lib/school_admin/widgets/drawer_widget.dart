import 'package:flutter/material.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';
import 'package:kobac/school_admin/pages/admin_profile.dart';
import 'package:kobac/school_admin/pages/admin_students.dart';
import 'package:kobac/school_admin/pages/change_password_page.dart';
import 'package:kobac/school_admin/pages/notifications_page.dart';
import 'package:kobac/school_admin/pages/school_admin_screen.dart';
import 'package:kobac/school_admin/pages/teachers_screen.dart';
import 'package:kobac/school_admin/pages/messages_inbox_screen.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/services/local_auth_service.dart';

const Color kDrawerBlue = Color(0xFF023471);
const Color kDrawerBlueDark = Color(0xFF012752);
const Color kDrawerIconBlue = Color(0xFF5B9BD5);
const Color kDrawerTeal = Color(0xFF2DD4BF);
const Color kDrawerTextDark = Color(0xFF2D2D2D);
const Color kDrawerTextGray = Color(0xFF6B6B6B);

class AppDrawer extends StatelessWidget {
  /// When set, tapping profile header will pop the drawer and call this
  /// (e.g. switch to Profile tab) instead of pushing a new route.
  final VoidCallback? onProfileTap;
  /// When set, list items push onto this (e.g. nested Navigator) so bottom nav stays.
  final void Function(Widget page)? onNavigateToPage;

  const AppDrawer({Key? key, this.onProfileTap, this.onNavigateToPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FBFF),
              const Color(0xFFF0F6FC),
              Colors.white,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
            BoxShadow(
              color: kDrawerIconBlue.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _DrawerProfileHeader(onProfileTap: onProfileTap),
                    const SizedBox(height: 50),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _DrawerMenuCard(
                            icon: Icons.home_outlined,
                            label: 'Home',
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(height: 12),
                          _DrawerMenuCard(
                          icon: Icons.people_alt_outlined,
                          label: 'Students',
                          onTap: () => _navTo(context, const AdminStudentsScreen()),
                        ),
                        const SizedBox(height: 12),
                        _DrawerMenuCard(
                          icon: Icons.school_outlined,
                          label: 'Teachers',
                          onTap: () => _navTo(context, const TeacherListScreen()),
                        ),
                        const SizedBox(height: 12),
                        _DrawerMenuCard(
                          icon: Icons.class_outlined,
                          label: 'Classes',
                          onTap: () => _navTo(context, const AdminClassesPage()),
                        ),
                        const SizedBox(height: 12),
                        _DrawerMenuCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Message',
                          badgeCount: 3,
                          onTap: () => _navTo(context, const MessagesInboxScreen(embedInParent: true)),
                        ),
                        const SizedBox(height: 12),
                        _DrawerMenuCard(
                          icon: Icons.notifications_outlined,
                          label: 'Notification',
                          onTap: () => _navTo(context, const NotificationsPage()),
                        ),
                        const SizedBox(height: 12),
                        _DrawerMenuCard(
                          icon: Icons.lock_reset_rounded,
                          label: 'Change Password',
                          onTap: () => _navTo(context, const ChangePasswordPage()),
                        ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 28),
                    _LogOutButton(
                      onTap: () async {
                        await LocalAuthService().logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    if (onNavigateToPage != null) {
      onNavigateToPage!(page);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const _DrawerProfileHeader({this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: LocalAuthService().getCurrentUser(),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? 'School Admin';
        final email = snapshot.data?.email ?? snapshot.data?.emisNumber ?? 'admin@school.com';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _NeumorphicPillCard(
            raised: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                if (onProfileTap != null) {
                  onProfileTap!();
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfilePage()));
                }
              },
              borderRadius: BorderRadius.circular(999),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kDrawerTextDark.withOpacity(0.35), width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: kDrawerIconBlue.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              color: kDrawerBlue,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: kDrawerTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: kDrawerTeal.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: kDrawerTextDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: kDrawerTextGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kDrawerIconBlue,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NeumorphicPillCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;

  const _NeumorphicPillCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.raised = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: raised
            ? [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 8,
                  offset: const Offset(-3, -3),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 6,
                  offset: const Offset(-2, -2),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                  spreadRadius: 0,
                ),
              ],
      ),
      child: child,
    );
  }
}

class _DrawerMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? badgeCount;

  const _DrawerMenuCard({
    required this.icon,
    required this.label,
    this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return _NeumorphicPillCard(
      raised: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Row(
          children: [
            Icon(icon, color: kDrawerIconBlue, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: kDrawerTextDark,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  if (badgeCount != null && badgeCount! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kDrawerIconBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: kDrawerIconBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF4A9FE8), kDrawerBlueDark],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(-3, -3),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: kDrawerBlueDark.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(3, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kDrawerIconBlue.withOpacity(0.4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kDrawerIconBlue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
