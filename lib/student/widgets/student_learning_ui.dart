import 'package:flutter/material.dart';

const studentBlue = Color(0xFF023471);
const studentGreen = Color(0xFF5AB04B);
const studentCanvas = Color(0xFFF0F3F7);
const studentInk = Color(0xFF2D3436);
const studentMuted = Color(0xFF6B7280);
const studentLine = Color(0xFFE8ECF2);
const studentBlueTint = Color(0xFFE6F0FF);

const _studentShadow = [
  BoxShadow(
    color: Color(0x12023471),
    blurRadius: 20,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x8AFFFFFF),
    blurRadius: 1,
    offset: Offset(0, -1),
  ),
];

class StudentPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final Widget? trailing;

  const StudentPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onMenu,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderControl(
          icon: onBack != null ? Icons.arrow_back_rounded : Icons.menu_rounded,
          onTap: onBack ?? onMenu,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: studentBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: studentMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _HeaderControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderControl({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMenu = icon == Icons.menu_rounded;
    return Material(
      color: isMenu ? studentBlue : Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            border: Border.all(
              color: isMenu ? studentBlue : studentLine,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: _studentShadow,
          ),
          child: Icon(
            icon,
            color: isMenu ? Colors.white : studentBlue,
            size: 23,
          ),
        ),
      ),
    );
  }
}

class StudentIdentityCard extends StatelessWidget {
  final String name;
  final String className;
  final String emis;
  final VoidCallback? onTap;

  const StudentIdentityCard({
    super.key,
    required this.name,
    required this.className,
    required this.emis,
    this.onTap,
  });

  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return words.take(2).map((e) => e[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return _StudentSurface(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: Container(
              width: 7,
              decoration: const BoxDecoration(
                color: studentBlue,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(22),
                ),
              ),
            ),
          ),
          Row(
            children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: studentBlue,
              shape: BoxShape.circle,
              border: Border.all(color: studentGreen, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14023471),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isEmpty ? 'S' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: studentBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _MetaChip(icon: Icons.school_rounded, label: className),
                    _MetaChip(icon: Icons.badge_outlined, label: 'EMIS $emis'),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.chevron_right_rounded, color: studentMuted),
            ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: studentCanvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: studentLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: studentBlue, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: studentMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StudentSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: studentInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: studentBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class StudentActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color accent;

  const StudentActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.accent = studentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return _StudentSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26023471),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_outward_rounded,
                color: studentMuted,
                size: 17,
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: studentInk,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: studentMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class StudentScheduleCard extends StatelessWidget {
  final String time;
  final String subject;
  final String teacher;
  final bool emphasized;

  const StudentScheduleCard({
    super.key,
    required this.time,
    required this.subject,
    required this.teacher,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 58,
          child: Column(
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: studentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: emphasized ? studentGreen : studentBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [_StudentDotShadow()],
                ),
              ),
              Expanded(
                child: Container(width: 2, color: studentLine),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StudentSurface(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: emphasized ? studentGreen : studentBlueTint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: emphasized ? Colors.white : studentBlue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: studentInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teacher,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: studentMuted,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StudentNextClassCard extends StatelessWidget {
  final String time;
  final String subject;
  final String teacher;
  final VoidCallback? onViewTimetable;

  const StudentNextClassCard({
    super.key,
    required this.time,
    required this.subject,
    required this.teacher,
    this.onViewTimetable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: studentLine),
        boxShadow: _studentShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: const BoxDecoration(
              color: studentBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Next Class',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: studentGreen,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: SizedBox(width: 14, height: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: studentBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              time,
                              style: const TextStyle(
                                color: studentBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: studentInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        teacher,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: studentMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 13),
                      OutlinedButton.icon(
                        onPressed: onViewTimetable,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: studentBlue,
                          side: const BorderSide(color: studentLine),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 17,
                        ),
                        label: const Text('View Timetable'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: studentBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: studentGreen, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30023471),
                        blurRadius: 14,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentDotShadow extends BoxShadow {
  const _StudentDotShadow()
      : super(
          color: const Color(0x26023471),
          blurRadius: 5,
          offset: const Offset(0, 2),
        );
}

class StudentMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StudentMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = studentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return _StudentSurface(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: studentInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: studentMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudentSubjectResultCard extends StatelessWidget {
  final String subject;
  final String score;
  final String? status;
  final Color statusColor;

  const StudentSubjectResultCard({
    super.key,
    required this.subject,
    required this.score,
    this.status,
    this.statusColor = studentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return _StudentSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: studentBlueTint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              subject.trim().isEmpty ? 'S' : subject.trim()[0].toUpperCase(),
              style: const TextStyle(
                color: studentBlue,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: studentInk,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  color: studentBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (status != null)
                Text(
                  status!,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudentNoticeCard extends StatelessWidget {
  final String title;
  final String excerpt;
  final String date;
  final VoidCallback? onTap;
  final bool important;

  const StudentNoticeCard({
    super.key,
    required this.title,
    required this.excerpt,
    required this.date,
    this.onTap,
    this.important = false,
  });

  @override
  Widget build(BuildContext context) {
    return _StudentSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: important ? studentBlue : studentGreen,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(23),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: studentInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          color: studentMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: studentMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;

  const StudentDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.accent = studentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? studentBlue : studentLine,
            ),
            boxShadow: _studentShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? studentBlue : Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: studentLine),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18023471),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? studentBlue : studentInk,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? studentBlue : studentMuted,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const StudentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _StudentSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: studentBlueTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: studentBlue, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: studentInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 5),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: studentMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class StudentErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const StudentErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StudentSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: studentInk, fontSize: 13),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _StudentSurface({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: studentLine),
        boxShadow: _studentShadow,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: content,
      ),
    );
  }
}
