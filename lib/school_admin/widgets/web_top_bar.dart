import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/school_admin/pages/notifications_page.dart';

/// Desktop top header bar
class WebTopBar extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? actions;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final Function(String)? onSearch;

  const WebTopBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.onSearch,
  }) : super(key: key);

  @override
  State<WebTopBar> createState() => _WebTopBarState();
}

class _WebTopBarState extends State<WebTopBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

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
    final userInitials = userName.isNotEmpty 
        ? userName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'SA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left side: Menu button + Welcome text
          Expanded(
            child: Row(
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
            ),
          ),
          
          // Right side: Search + Notifications + Profile
          Row(
            children: [
              // Search bar
              Container(
                width: 320,
                height: 40,
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
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
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
              
              const SizedBox(width: 24),
              
              // Notifications
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5AB04B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 24),
              
              // User profile section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8ECF2), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF023471).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          userInitials,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF023471),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF023471),
                          ),
                        ),
                        Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ],
                ),
              ),
              
              // Additional actions if provided
              if (widget.actions != null) ...[
                const SizedBox(width: 16),
                widget.actions!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
