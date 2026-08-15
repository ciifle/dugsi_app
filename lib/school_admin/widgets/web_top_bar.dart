import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kBorderGray = Color(0xFFE5E7EB);
const Color _kTextSecondary = Color(0xFF6B7280);
const double _kUserMenuWidth = 240;

/// Desktop top header bar
class WebTopBar extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? actions;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final Function(String)? onSearch;
  final void Function(String, {Object? arguments})? onNavigateToPage;
  final VoidCallback? onLogout;

  const WebTopBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.onSearch,
    this.onNavigateToPage,
    this.onLogout,
  }) : super(key: key);

  @override
  State<WebTopBar> createState() => _WebTopBarState();
}

class _WebTopBarState extends State<WebTopBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _userMenuHovered = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (widget.onSearch != null) {
        widget.onSearch!(_searchController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = user?.name ?? 'School Admin';
    final userRole =
        user?.role.replaceAll('_', ' ').toUpperCase() ?? 'SCHOOL ADMIN';
    final userEmail = user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : (user?.emisNumber?.trim().isNotEmpty == true
              ? user!.emisNumber!.trim()
              : null);
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'SA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 12),
                    _buildUserMenu(
                      userInitials: userInitials,
                      userName: userName,
                      userRole: userRole,
                      userEmail: userEmail,
                    ),
                  ],
                ),
                if (widget.actions != null) ...[
                  const SizedBox(height: 12),
                  widget.actions!,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 260, child: _buildTitleBlock()),
              const SizedBox(width: 16),
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 16),
              _topAction(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                badge: '3',
                onPressed: () => widget.onNavigateToPage?.call('notifications'),
              ),
              const SizedBox(width: 10),
              const SizedBox(width: 16),
              _buildUserMenu(
                userInitials: userInitials,
                userName: userName,
                userRole: userRole,
                userEmail: userEmail,
              ),
              if (widget.actions != null) ...[
                const SizedBox(width: 16),
                widget.actions!,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Row(
      children: [
        if (widget.showBackButton) ...[
          IconButton(
            onPressed: widget.onBackButtonPressed,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF023471),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
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
                  color: Color(0xFF023471),
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
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8ECF2), width: 1),
        ),
        child: TextField(
          controller: _searchController,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: 'Search anything...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade500,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _topAction({
    required IconData icon,
    required String tooltip,
    required String badge,
    required VoidCallback onPressed,
  }) => Stack(
    clipBehavior: Clip.none,
    children: [
      Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF8F9FC),
            foregroundColor: _kPrimaryBlue,
            side: const BorderSide(color: _kBorderGray),
            minimumSize: const Size(44, 44),
          ),
          icon: Icon(icon, size: 20),
        ),
      ),
      Positioned(
        right: -2,
        top: -3,
        child: Container(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: tooltip == 'Notifications'
                ? const Color(0xFFEF4444)
                : const Color(0xFF1267D8),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );

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
        shadowColor: const Color(0x1F000000),
        elevation: 10,
        offset: const Offset(0, 10),
        padding: EdgeInsets.zero,
        menuPadding: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
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
                        const SizedBox(height: 2),
                        Text(
                          userEmail ?? userRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTextSecondary,
                            fontWeight: FontWeight.w500,
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
          PopupMenuItem<String>(
            value: 'profile',
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: _kUserMenuWidth,
              child: const Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: _kPrimaryBlue,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuItem<String>(
            value: 'logout',
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: _kUserMenuWidth,
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
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
                color: _userMenuHovered
                    ? const Color(0xFFD1D5DB)
                    : _kBorderGray,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _userMenuHovered ? 0.08 : 0.04,
                  ),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
