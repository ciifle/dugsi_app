import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const Color teacherWebBg = Color(0xFFF0F3F7);
const Color teacherWebBlue = Color(0xFF023471);
const Color teacherWebGreen = Color(0xFF5AB04B);
const Color teacherWebTextPrimary = Color(0xFF2D3436);
const Color teacherWebTextSecondary = Color(0xFF6B7280);
const Color teacherWebBorder = Color(0xFFE8ECF2);

bool isTeacherDesktopWeb(BuildContext context) {
  return kIsWeb && MediaQuery.sizeOf(context).width >= 1024;
}

class TeacherWebSurface extends StatelessWidget {
  final Widget child;

  const TeacherWebSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: teacherWebBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class TeacherWebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TeacherWebCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: teacherWebBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TeacherWebSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const TeacherWebSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: teacherWebBlue,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: teacherWebTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class TeacherWebInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const TeacherWebInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: teacherWebTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: teacherWebTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherWebTableHeader extends StatelessWidget {
  final List<String> columns;

  const TeacherWebTableHeader({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(bottom: BorderSide(color: teacherWebBorder)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: i == columns.length - 1 ? 2 : 3,
              child: Text(
                columns[i],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: teacherWebTextSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TeacherWebTableRow extends StatelessWidget {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const TeacherWebTableRow({super.key, required this.cells, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: teacherWebBorder)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(flex: i == cells.length - 1 ? 2 : 3, child: cells[i]),
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Dashboard stat tile — mirrors the Admin PWA's DashboardStatCard visual
/// recipe (lib/school_admin/widgets/dashboard_stat_card.dart) minus the
/// hardcoded "growth vs last month" row, since Teacher has no trend data to
/// show honestly. Used by both the PWA and mobile dashboards.
class TeacherStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const TeacherStatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed, minimal internal structure (icon -> gap -> value -> label) sized
    // to fit comfortably within a 128px-tall mobile grid cell — no
    // spaceBetween/Spacer stretching that could overflow if the parent gives
    // less height than the content needs.
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: teacherWebBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: teacherWebBlue,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: teacherWebTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}

/// Compact "nothing to show" state — icon + title + optional message. No
/// blank pages, no infinite spinners left over.
class TeacherEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const TeacherEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: teacherWebBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: teacherWebBlue, size: 27),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: teacherWebTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 5),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: teacherWebTextSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact error state with an optional Retry action.
class TeacherErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TeacherErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: teacherWebTextPrimary, fontSize: 13),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(foregroundColor: teacherWebBlue),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared select field used across Teacher PWA filters (Marks/Attendance/
/// Classes) — mirrors StudentWebDropdown's visual recipe for consistency.
class TeacherWebDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final String? label;

  const TeacherWebDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final field = Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
        splashColor: teacherWebBlue.withValues(alpha: 0.06),
        highlightColor: teacherWebBlue.withValues(alpha: 0.06),
        hoverColor: teacherWebBlue.withValues(alpha: 0.04),
        colorScheme: Theme.of(context).colorScheme.copyWith(
          surface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teacherWebBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: hint,
            isExpanded: true,
            dropdownColor: Colors.white,
            focusColor: teacherWebBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: teacherWebTextSecondary,
              size: 20,
            ),
            style: const TextStyle(
              color: teacherWebBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label!,
            style: const TextStyle(
              fontSize: 12.5,
              color: teacherWebTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        field,
      ],
    );
  }
}

/// Destructive account-action card — matches the Admin PWA sidebar's Logout
/// treatment exactly (lib/school_admin/widgets/web_sidebar.dart _LogoutCard):
/// solid red fill, white icon chip, title + subtitle, trailing arrow. Used
/// by both the Teacher PWA sidebar and the Teacher mobile drawer so Teacher
/// has one consistent logout visual language across platforms.
class TeacherLogoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const TeacherLogoutCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFC73737),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC73737).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sign out of your account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFFFE4E4),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
