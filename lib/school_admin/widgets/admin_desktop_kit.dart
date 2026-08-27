import 'package:flutter/material.dart';

/// Shared desktop/PWA design-system primitives for the School Admin
/// "Examinations" pages (Exams, Marks, Exam Halls, Hall Allocation,
/// Hall Report, Exam Pass Cards). Matches the existing shell palette used in
/// `web_dashboard.dart` / `web_sidebar.dart` / `web_top_bar.dart` — no new
/// colors introduced.
const Color kAdminNavy = Color(0xFF023471);
const Color kAdminGreen = Color(0xFF5AB04B);
const Color kAdminBg = Color(0xFFF0F3F7);
const Color kAdminBorder = Color(0xFFE8ECF2);
const Color kAdminHeaderBg = Color(0xFFF8FAFC);
const Color kAdminTextSecondary = Color(0xFF6B7280);

/// Page title + subtitle on the left, primary/secondary actions on the
/// right. Used at the top of every desktop Examinations page instead of a
/// floating action button.
class AdminPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? primaryAction;
  final List<Widget>? secondaryActions;

  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.primaryAction,
    this.secondaryActions,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions =
        primaryAction != null ||
        (secondaryActions != null && secondaryActions!.isNotEmpty);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: kAdminNavy,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kAdminTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasActions) ...[
          const SizedBox(width: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...?secondaryActions,
              if (primaryAction != null) primaryAction!,
            ],
          ),
        ],
      ],
    );
  }
}

/// Standard height (~44px) primary/secondary/destructive action buttons
/// matching the section 27 button-hierarchy guidance (green = primary,
/// outlined = secondary, red = destructive; never every button green).
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const AdminPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: kAdminGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

class AdminSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const AdminSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: kAdminNavy,
      side: const BorderSide(color: kAdminBorder),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

/// Compact KPI tile — icon chip + value + label. Deliberately has no
/// growth/trend row (unlike `DashboardStatCard`) since Examinations totals
/// (Total Halls, Active, Inactive, ...) have no honest month-over-month
/// comparison to show.
class AdminStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const AdminStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kAdminBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kAdminNavy,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: kAdminTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Responsive row of [AdminStatTile]s — wraps to fewer columns on narrower
/// desktop widths, never fetches data itself (values passed in already
/// computed from data already in memory).
class AdminStatRow extends StatelessWidget {
  final List<AdminStatTile> tiles;
  const AdminStatRow({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final perRow = constraints.maxWidth >= 900
          ? tiles.length.clamp(1, 4)
          : constraints.maxWidth >= 600
          ? 2
          : 1;
      final spacing = 12.0;
      final width = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final tile in tiles) SizedBox(width: width, child: tile),
        ],
      );
    },
  );
}

/// Bordered white toolbar container for filters/search, with an optional
/// trailing action row (Refresh / Generate Report / Apply Filters).
class AdminFilterBar extends StatelessWidget {
  final List<Widget> filters;
  final List<Widget>? actions;
  const AdminFilterBar({super.key, required this.filters, this.actions});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kAdminBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 760
                ? (constraints.maxWidth - 12 * 2) / 3
                : constraints.maxWidth >= 480
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final f in filters) SizedBox(width: width, child: f),
              ],
            );
          },
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 8, children: actions!),
        ],
      ],
    ),
  );
}

/// One column definition shared between [AdminTableHeader] and every
/// [AdminTableRow] on the same table — keeps header/cell widths in sync.
class AdminTableColumn {
  final String label;
  final int flex;
  final TextAlign align;
  const AdminTableColumn(
    this.label, {
    this.flex = 1,
    this.align = TextAlign.left,
  });
}

/// Full-width table header — a `Row` of flexed cells (unlike `DataTable`,
/// this genuinely stretches to the parent's width).
class AdminTableHeader extends StatelessWidget {
  final List<AdminTableColumn> columns;
  const AdminTableHeader({super.key, required this.columns});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: kAdminHeaderBg,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      border: Border(bottom: BorderSide(color: kAdminBorder)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      children: [
        for (final c in columns)
          Expanded(
            flex: c.flex,
            child: Text(
              c.label,
              textAlign: c.align,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kAdminTextSecondary,
                letterSpacing: .2,
              ),
            ),
          ),
      ],
    ),
  );
}

/// One data row matching an [AdminTableHeader]'s column flexes. Hover tint
/// only applies on web/desktop pointer devices.
class AdminTableRow extends StatefulWidget {
  final List<Widget> cells;
  final List<int> flexes;
  final VoidCallback? onTap;
  final bool showBottomBorder;
  const AdminTableRow({
    super.key,
    required this.cells,
    required this.flexes,
    this.onTap,
    this.showBottomBorder = true,
  }) : assert(cells.length == flexes.length);

  @override
  State<AdminTableRow> createState() => _AdminTableRowState();
}

class _AdminTableRowState extends State<AdminTableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap != null
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: InkWell(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hover ? kAdminHeaderBg : Colors.white,
          border: widget.showBottomBorder
              ? const Border(bottom: BorderSide(color: kAdminBorder))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.cells.length; i++)
              Expanded(flex: widget.flexes[i], child: widget.cells[i]),
          ],
        ),
      ),
    ),
  );
}

/// White bordered card wrapping an [AdminTableHeader] + [AdminTableRow]
/// list — the one shared table look for every Examination page.
class AdminTableCard extends StatelessWidget {
  final List<AdminTableColumn> columns;
  final List<AdminTableRow> rows;
  const AdminTableCard({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kAdminBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        AdminTableHeader(columns: columns),
        ...List.generate(
          rows.length,
          (i) => i == rows.length - 1
              ? AdminTableRow(
                  cells: rows[i].cells,
                  flexes: rows[i].flexes,
                  onTap: rows[i].onTap,
                  showBottomBorder: false,
                )
              : rows[i],
        ),
      ],
    ),
  );
}

/// Small colored status pill — generalized version of the
/// active/inactive badge used throughout Examinations (allocation status,
/// pass/fail, etc.).
class AdminStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const AdminStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory AdminStatusPill.active(bool active) => AdminStatusPill(
    label: active ? 'ACTIVE' : 'INACTIVE',
    color: active ? kAdminGreen : Colors.grey.shade600,
    icon: active
        ? Icons.check_circle_rounded
        : Icons.pause_circle_outline_rounded,
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );
}

/// Professional empty state with an optional primary action
/// (e.g. "+ Add First Hall").
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: kAdminNavy.withValues(alpha: .3)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kAdminNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kAdminTextSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

/// Inline error state with a Retry action — never shows a raw
/// exception/stack trace to the user.
class AdminErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const AdminErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.cloud_off_rounded, color: Colors.red.shade700),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kAdminNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kAdminTextSecondary),
          ),
          const SizedBox(height: 14),
          AdminSecondaryButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    ),
  );
}

/// Compact, dense filter dropdown (~44px) matching section 20's sizing
/// guidance. Thin wrapper so every Examination filter bar looks identical.
class AdminFilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  const AdminFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    isDense: true,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAdminBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAdminBorder),
      ),
    ),
    items: items,
    onChanged: onChanged,
  );
}
