import 'package:flutter/material.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

/// Root-level Teacher mobile shell page header: menu/drawer button + title
/// (+ optional subtitle/action) — no back arrow. Used for pages hosted
/// directly inside the persistent Teacher mobile shell (Dashboard, My
/// Classes, Assignments), which are top-level destinations, not pushed
/// routes. Pushed/secondary pages (class students, change password, etc.)
/// keep their own back-arrow AppBar and do not use this widget.
class TeacherRootPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onMenuTap;
  final Widget? action;

  const TeacherRootPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onMenuTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: teacherWebBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: teacherWebBlue,
                size: 22,
              ),
            ),
          ),
        ),
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
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: teacherWebBlue,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: teacherWebTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 10), action!],
      ],
    );
  }
}

/// Teacher mobile drawer's Logout entry — pale red background, red icon,
/// red text, red border, rounded container, no gradient. Deliberately
/// distinct from the shared [TeacherLogoutCard] (solid dark-red, used by
/// the PWA sidebar and Teacher Profile page) which is left untouched;
/// this drawer-only treatment follows the explicit "pale red / no
/// gradient" spec given for the mobile drawer redesign.
class TeacherDrawerLogoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const TeacherDrawerLogoutCard({super.key, required this.onTap});

  static const _red = Color(0xFFC0392B);
  static const _paleRed = Color(0xFFFDECEC);
  static const _borderRed = Color(0xFFF3C7C7);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _paleRed,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderRed),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: _red,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: _red,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _red, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
