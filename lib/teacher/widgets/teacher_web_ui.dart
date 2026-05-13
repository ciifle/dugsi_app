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

  const TeacherWebTableRow({
    super.key,
    required this.cells,
    this.onTap,
  });

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
            Expanded(
              flex: i == cells.length - 1 ? 2 : 3,
              child: cells[i],
            ),
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
