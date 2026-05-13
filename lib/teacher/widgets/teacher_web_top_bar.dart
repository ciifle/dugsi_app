import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kBorderGray = Color(0xFFE5E7EB);
const Color _kTextSecondary = Color(0xFF6B7280);
const double _kUserMenuWidth = 240;

class TeacherWebTopBar extends StatefulWidget {
  final String title;
  final String? subtitle;
  final void Function(String, {Object? arguments})? onNavigateToPage;
  final VoidCallback? onLogout;

  const TeacherWebTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onNavigateToPage,
    this.onLogout,
  });

  @override
  State<TeacherWebTopBar> createState() => _TeacherWebTopBarState();
}

class _TeacherWebTopBarState extends State<TeacherWebTopBar> {
  bool _userMenuHovered = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final prof = auth.teacherProfile;
    final userName = prof?.fullName?.trim().isNotEmpty == true
        ? prof!.fullName!.trim()
        : (user?.name?.trim().isNotEmpty == true ? user!.name.trim() : 'Teacher');
    final userRole = user?.role.replaceAll('_', ' ').toUpperCase() ?? 'TEACHER';
    final userEmail = prof?.email?.trim().isNotEmpty == true
        ? prof!.email!.trim()
        : (user?.email?.trim().isNotEmpty == true
            ? user!.email!.trim()
            : (user?.emisNumber?.trim().isNotEmpty == true ? user!.emisNumber!.trim() : null));
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'T';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitleBlock(),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildUserMenu(
                    userInitials: userInitials,
                    userName: userName,
                    userRole: userRole,
                    userEmail: userEmail,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 260, child: _buildTitleBlock()),
              const Spacer(),
              _buildUserMenu(
                userInitials: userInitials,
                userName: userName,
                userRole: userRole,
                userEmail: userEmail,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _kPrimaryBlue,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserMenu({
    required String userInitials,
    required String userName,
    required String userRole,
    required String? userEmail,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 10,
          shadowColor: Color(0x1F000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: _kBorderGray),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        offset: const Offset(0, 10),
        padding: EdgeInsets.zero,
        menuPadding: const EdgeInsets.symmetric(vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: _kBorderGray),
        ),
        onSelected: (value) {
          if (value == 'profile') {
            widget.onNavigateToPage?.call('profile');
          } else if (value == 'logout') {
            widget.onLogout?.call();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: _kUserMenuWidth,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _kPrimaryBlue.withValues(alpha: 0.08),
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimaryBlue,
                          ),
                        ),
                        Text(
                          userEmail ?? userRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem<String>(
            value: 'profile',
            height: 48,
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 20, color: _kPrimaryBlue),
                SizedBox(width: 12),
                Text('Profile', style: TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'logout',
            height: 48,
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 20, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
        child: MouseRegion(
          onEnter: (_) => setState(() => _userMenuHovered = true),
          onExit: (_) => setState(() => _userMenuHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _kUserMenuWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _userMenuHovered ? const Color(0xFFD1D5DB) : _kBorderGray,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _userMenuHovered ? 0.08 : 0.04),
                  blurRadius: _userMenuHovered ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _kPrimaryBlue.withValues(alpha: 0.08),
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimaryBlue,
                        ),
                      ),
                      Text(
                        userRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
