import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/school_admin/widgets/web_admin_theme.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/widgets/form_3d/form_theme_3d.dart';

/// Shared small pieces reused across every Finance page (desktop + mobile).
/// Deliberately reuses [kAdminNavy]/[kAdminGreen]/[kAdminBg]/[kAdminBorder]
/// from admin_desktop_kit.dart instead of redeclaring the brand palette a
/// fourth time.

/// White bordered rounded card — the one shared content-block look for
/// Finance pages, on both mobile and desktop.
class FinanceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Tints the soft drop shadow (the Admin dashboard cards tint theirs with
  /// the icon colour). Defaults to the brand navy.
  final Color accent;
  const FinanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent = kAdminNavy,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kAdminBorder),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        const BoxShadow(
          color: Color(0x08000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
}

/// Mobile root-page header (menu button + title/subtitle), mirroring the
/// Teacher module's `TeacherRootPageHeader` shape/spirit for visual parity.
class FinanceRootPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onMenuTap;
  const FinanceRootPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      InkWell(
        onTap: onMenuTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kAdminNavy.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_rounded, color: kAdminNavy),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: kAdminNavy,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: kAdminTextSecondary,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Fee status colors: green = paid, amber = partial, red = unpaid.
Color feeStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PAID':
      return kAdminGreen;
    case 'PARTIAL':
      return const Color(0xFFF59E0B);
    case 'UNPAID':
      return FormTheme3D.errorRed;
    default:
      return kAdminTextSecondary;
  }
}

/// Generation per-class status colors: green = ready/configured, amber =
/// warning/skipped, neutral = already generated. Only actual request
/// failures should ever render as red errors — never these statuses.
Color generationStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIGURED':
      return kAdminGreen;
    case 'NOT_CONFIGURED':
    case 'TERM_UNSUPPORTED':
    case 'CYCLE_MISMATCH':
      return const Color(0xFFF59E0B);
    default:
      return kAdminTextSecondary;
  }
}

String generationStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIGURED':
      return 'Ready';
    case 'NOT_CONFIGURED':
      return 'Not configured';
    case 'TERM_UNSUPPORTED':
      return 'Term unsupported';
    case 'CYCLE_MISMATCH':
      return 'Different cycle';
    default:
      return financeLabel(status);
  }
}

/// Shown whenever a Finance call returns code FINANCE_NOT_ENABLED — a rare
/// mid-session state (school had payments disabled after login), not the
/// nav-level gate (that already hides Finance entirely — see
/// AuthProvider.feesEnabled). Never repeats as a dialog/snackbar; renders in
/// place of the page body.
class FinanceNotEnabledView extends StatelessWidget {
  const FinanceNotEnabledView({super.key});

  @override
  Widget build(BuildContext context) => const AdminEmptyState(
    icon: Icons.lock_outline_rounded,
    title: 'Finance is not enabled',
    message:
        'Finance is not enabled for this school. Contact your school '
        'administrator or Dugsi support if you believe this is a mistake.',
  );
}

/// Academic-year picker every Finance page needs (dashboard, class fees,
/// discounts, ledger, generation). Reads the shared global
/// [AcademicYearsProvider] — never a page-local parallel list — so every
/// Finance page and every other role's page stay in sync on the same years.
class FinanceYearSelector extends StatelessWidget {
  final int? selectedYearId;
  final ValueChanged<int?> onChanged;
  const FinanceYearSelector({
    super.key,
    required this.selectedYearId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    final years = provider.years;
    if (provider.loading) return const LinearProgressIndicator();
    if (provider.error != null)
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Academic years could not be loaded.'),
          TextButton(onPressed: provider.refresh, child: const Text('Retry')),
        ],
      );
    if (years.isEmpty) return const Text('No academic years available.');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: AdminFilterDropdown<int>(
        label: 'Academic Year',
        value: years.any((y) => y.id == selectedYearId) ? selectedYearId : null,
        items: years
            .map((y) => DropdownMenuItem(value: y.id, child: Text(y.name)))
            .toList(),
        onChanged: (value) {
          rememberFinanceYear(context.read<AcademicYearsProvider>(), value);
          onChanged(value);
        },
      ),
    );
  }
}

/// Page spacing and input styling come from the established Admin theme:
/// outlined 10px-radius inputs with the Admin border, matching
/// [AdminFilterDropdown], so raw text fields on Finance pages look like
/// every other Admin filter/search control.
/// Shell navigation rendered above the page content's scroll viewport.
class FinancePageChrome extends InheritedWidget {
  final Widget header;
  const FinancePageChrome({
    super.key,
    required this.header,
    required super.child,
  });
  static Widget? headerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FinancePageChrome>()?.header;
  @override
  bool updateShouldNotify(FinancePageChrome oldWidget) =>
      header != oldWidget.header;
}

class FinancePageSurface extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final ScrollController? controller;
  const FinancePageSurface({
    super.key,
    required this.child,
    this.header,
    this.controller,
  });

  static ThemeData _theme(ThemeData base) {
    final admin = webAdminTheme(base);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );
    return admin.copyWith(
      inputDecorationTheme: admin.inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: border(kAdminBorder),
        enabledBorder: border(kAdminBorder),
        disabledBorder: border(kAdminBorder),
        focusedBorder: border(kAdminNavy, 1.6),
        errorBorder: border(FormTheme3D.errorRed),
        focusedErrorBorder: border(FormTheme3D.errorRed, 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _theme(Theme.of(context)),
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (FinancePageChrome.headerOf(context) ?? header case final chrome?)
            chrome,
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('finance-page-scroll'),
              controller: controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 600 ? 16 : 24,
                      16,
                      constraints.maxWidth < 600 ? 16 : 24,
                      32,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One page frame for every Finance page. Embedded in the Admin/Finance shell
/// it is just the padded surface (the shell already owns the navigation and
/// top bar). Pushed on its own (mobile) it adds only a back button, so the
/// page title appears exactly once - in [FinancePageHeader].
class FinancePageFrame extends StatelessWidget {
  final bool embedBodyOnly;
  final Widget child;

  /// Whether the surrounding shell already shows the page title. Defaults to
  /// true on the desktop web layout (overridable for tests).
  final bool? titleInShell;
  final ScrollController? scrollController;
  const FinancePageFrame({
    super.key,
    required this.embedBodyOnly,
    required this.child,
    this.titleInShell,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (embedBodyOnly) {
      return _FinanceHeaderMode(
        titleInShell:
            titleInShell ??
            (FinancePageChrome.headerOf(context) == null &&
                isDesktopWebAdminLayout(context)),
        child: FinancePageSurface(controller: scrollController, child: child),
      );
    }
    return Scaffold(
      backgroundColor: kAdminBg,
      body: SafeArea(
        child: FinancePageSurface(
          controller: scrollController,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: 'Back',
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kAdminBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: kAdminNavy,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

const List<String> kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

// Selection is scoped to the existing global year provider, so a new authenticated
// provider/session cannot inherit another school's selection. No parallel year list.
final _financeYears = Expando<int>('financeSelectedYear');
int? selectedFinanceYear(AcademicYearsProvider provider) {
  final selected = _financeYears[provider];
  if (selected != null) {
    return provider.years.any((y) => y.id == selected) ? selected : null;
  }
  // No explicit choice yet: the active year, else the newest active-flagged
  // year, else the newest year (the list is ordered newest first).
  final active =
      provider.activeYear ??
      provider.years.cast<AcademicYear?>().firstWhere(
        (y) => y!.isActive,
        orElse: () => null,
      );
  return active?.id ??
      (provider.years.isEmpty ? null : provider.years.first.id);
}

void rememberFinanceYear(AcademicYearsProvider provider, int? id) {
  _financeYears[provider] = id;
}

Future<void> ensureFinanceYears(AcademicYearsProvider provider) async {
  if (!provider.loading) {
    await provider.ensureLoaded();
    return;
  }
  final ready = Completer<void>();
  void listener() {
    if (!provider.loading && !ready.isCompleted) ready.complete();
  }

  provider.addListener(listener);
  try {
    await ready.future;
  } finally {
    provider.removeListener(listener);
  }
}

String financeLabel(String value) => value.isEmpty
    ? '—'
    : value
          .split('_')
          .map(
            (word) => word.isEmpty
                ? ''
                : word[0].toUpperCase() + word.substring(1).toLowerCase(),
          )
          .join(' ');

/// Set by [FinancePageFrame] when the page sits inside the desktop Admin
/// shell, whose top bar already shows the page title.
class _FinanceHeaderMode extends InheritedWidget {
  final bool titleInShell;
  const _FinanceHeaderMode({required this.titleInShell, required super.child});

  static bool titleInShellOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_FinanceHeaderMode>()
          ?.titleInShell ??
      false;

  @override
  bool updateShouldNotify(_FinanceHeaderMode old) =>
      titleInShell != old.titleInShell;
}

/// The Finance page header. On mobile / standalone it is the Admin title +
/// subtitle + actions. Inside the desktop shell the top bar already shows the
/// title, so only the subtitle and the actions are drawn (no duplicate title).
class FinancePageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? primaryAction;
  final List<Widget>? secondaryActions;
  const FinancePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.primaryAction,
    this.secondaryActions,
  });

  bool get _hasActions =>
      primaryAction != null || (secondaryActions?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    if (_FinanceHeaderMode.titleInShellOf(context)) {
      if (subtitle == null && !_hasActions) return const SizedBox.shrink();
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                color: kAdminTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_hasActions)
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ...?secondaryActions,
                if (primaryAction != null) primaryAction!,
              ],
            ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700)
          return AdminPageHeader(
            title: title,
            subtitle: subtitle,
            primaryAction: primaryAction,
            secondaryActions: secondaryActions,
          );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: kAdminNavy,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: kAdminTextSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            if (_hasActions) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...?secondaryActions,
                  if (primaryAction != null) primaryAction!,
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The Admin table on wide screens; compact labelled record cards on narrow
/// screens. Uses exactly the same supplied cells and actions in both layouts.
/// In card form the first cell is the card title, an `Action` column becomes
/// a footer row, and every other cell sits in a two-column label/value grid.
class FinanceTableCard extends StatelessWidget {
  final List<AdminTableColumn> columns;
  final List<AdminTableRow> rows;
  const FinanceTableCard({
    super.key,
    required this.columns,
    required this.rows,
  });

  static bool _isAction(AdminTableColumn c) =>
      c.label.isEmpty || c.label.toLowerCase().startsWith('action');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minimum = columns.length > 7
          ? 1000.0
          : columns.length > 5
          ? 820.0
          : 640.0;
      if (constraints.maxWidth >= 720) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < minimum
                ? minimum
                : constraints.maxWidth,
            child: AdminTableCard(columns: columns, rows: rows),
          ),
        );
      }
      final actionIndex = columns.indexWhere(_isAction);
      bool menuInHeader(AdminTableRow row) {
        if (actionIndex <= 0) return false;
        final cell = row.cells[actionIndex];
        return cell is FinanceActionMenu ||
            (cell is Align && cell.child is FinanceActionMenu);
      }

      return Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FinanceCard(
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: row.onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: row.cells.first is Text
                                ? DefaultTextStyle.merge(
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: kAdminNavy,
                                    ),
                                    child: row.cells.first,
                                  )
                                : row.cells.first,
                          ),
                          if (menuInHeader(row)) row.cells[actionIndex],
                        ],
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, card) {
                          final cell = (card.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              for (var i = 1; i < row.cells.length; i++)
                                if (i != actionIndex)
                                  SizedBox(
                                    width: cell,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          columns[i].label,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: kAdminTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        DefaultTextStyle.merge(
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: Color(0xFF1F2937),
                                          ),
                                          child: row.cells[i],
                                        ),
                                      ],
                                    ),
                                  ),
                            ],
                          );
                        },
                      ),
                      if (actionIndex > 0 && !menuInHeader(row)) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: kAdminBorder),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: row.cells[actionIndex],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class FinanceFilterBar extends StatelessWidget {
  final List<Widget> filters;
  final List<Widget>? actions;
  const FinanceFilterBar({super.key, required this.filters, this.actions});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final bar = AdminFilterBar(filters: filters, actions: actions);
      if (c.maxWidth >= 600) return bar;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kAdminBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const Icon(
              Icons.tune_rounded,
              size: 20,
              color: kAdminNavy,
            ),
            title: const Text(
              'Search & filters',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kAdminNavy,
              ),
            ),
            children: [bar],
          ),
        ),
      );
    },
  );
}

/// Compact summaries with the same Admin card border, palette and typography:
/// four across on desktop, two across everywhere else (never one giant card
/// per row on a phone).
class FinanceSummaryGrid extends StatelessWidget {
  final List<AdminStatTile> tiles;
  const FinanceSummaryGrid({super.key, required this.tiles});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final count = c.maxWidth >= 900 && tiles.length >= 4
          ? 4
          : c.maxWidth >= 640 && tiles.length >= 3
          ? 3
          : 2;
      final gap = c.maxWidth < 480 ? 10.0 : 12.0;
      final width = (c.maxWidth - (count - 1) * gap) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final tile in tiles)
            SizedBox(
              width: width,
              child: _HoverLift(
                child: FinanceCard(
                  accent: tile.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tile.color.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(tile.icon, size: 15, color: tile.color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tile.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                color: kAdminTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tile.value,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: kAdminNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Subtle raise on hover (web/desktop pointers only), like the Admin cards.
class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});
  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
      child: widget.child,
    ),
  );
}

/// Paid / Partial / Unpaid badge - the one status pill for fee statuses.
class FinanceStatusBadge extends StatelessWidget {
  final String status;
  const FinanceStatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) => AdminStatusPill(
    label: financeLabel(status),
    color: feeStatusColor(status),
  );
}

/// Compact mobile list card used by Finance lists that have a natural
/// "person + details + actions" shape (avatar/icon, title, subtitle, trailing
/// menu, optional label/value details). Same radius, border and shadow as the
/// other Finance cards.
class FinanceRecordCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<(String, String)> details;
  final VoidCallback? onTap;
  const FinanceRecordCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.details = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FinanceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kAdminNavy,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: kAdminTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing! else const SizedBox(width: 8),
                ],
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 6,
                    children: [
                      for (final d in details)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${d.$1}: ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: kAdminTextSecondary,
                              ),
                            ),
                            Text(
                              d.$2,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Round initial avatar - same look as the Admin Students/Teachers lists.
class FinanceInitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  const FinanceInitialAvatar(this.name, {super.key, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: kAdminNavy.withValues(alpha: .1),
      shape: BoxShape.circle,
    ),
    child: Text(
      name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
      style: TextStyle(
        fontSize: size * .4,
        fontWeight: FontWeight.w700,
        color: kAdminNavy,
      ),
    ),
  );
}

/// Cancel / primary action row for Finance dialogs - the same two-button
/// footer as the Admin confirmation dialogs (48px, equal width, Cancel is
/// outlined, the primary is filled; [destructive] turns it red).
class FinanceDialogActions extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool busy;
  final bool destructive;
  const FinanceDialogActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.busy = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: busy
              ? null
              : (onCancel ?? () => Navigator.pop(context, false)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: kAdminNavy,
            side: const BorderSide(color: kAdminBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(cancelLabel),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: FilledButton(
          onPressed: busy ? null : onPrimary,
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? FormTheme3D.errorRed : kAdminGreen,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(primaryLabel),
        ),
      ),
    ],
  );
}

/// Inline, human-readable error banner for forms and dialogs.
class FinanceInlineError extends StatelessWidget {
  final String message;
  const FinanceInlineError(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: FormTheme3D.errorRed.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: FormTheme3D.errorRed.withValues(alpha: .35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: FormTheme3D.errorRed,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: FormTheme3D.errorRed),
          ),
        ),
      ],
    ),
  );
}

/// Informational / error message dialog in the Admin dialog style.
Future<void> showFinanceMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.info_outline_rounded,
  Color? iconColor,
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black38,
  builder: (dialogContext) => AdminFeatureDialog(
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor ?? kAdminNavy, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(height: 1.4, color: kAdminNavy),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: FilledButton.styleFrom(
            backgroundColor: kAdminGreen,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  ),
);

/// dd/mm/yyyy - the one Finance date format. Unparseable input is returned
/// unchanged; null/empty renders as an em dash.
String formatFinanceDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.isUtc ? dt.toLocal() : dt;
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

/// dd/mm/yyyy hh:mm.
String formatFinanceDateTime(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.isUtc ? dt.toLocal() : dt;
  return '${formatFinanceDate(iso)} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// Small section heading used between blocks on Finance pages.
class FinanceSectionTitle extends StatelessWidget {
  final String title;
  const FinanceSectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: kAdminNavy,
      ),
    ),
  );
}

/// One entry of a [FinanceActionMenu].
class FinanceMenuAction {
  final String label;
  final IconData icon;
  final bool destructive;
  final VoidCallback onSelected;
  const FinanceMenuAction(
    this.label,
    this.icon,
    this.onSelected, {
    this.destructive = false,
  });
}

/// The row/card action menu (three dots) used by every Finance list, instead
/// of loose per-row buttons and icons.
class FinanceActionMenu extends StatelessWidget {
  final List<FinanceMenuAction> actions;
  const FinanceActionMenu({super.key, required this.actions});

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    tooltip: 'Actions',
    icon: const Icon(Icons.more_vert_rounded, color: kAdminNavy),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: (i) => actions[i].onSelected(),
    itemBuilder: (_) => [
      for (var i = 0; i < actions.length; i++)
        PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              Icon(
                actions[i].icon,
                size: 18,
                color: actions[i].destructive ? Colors.red : kAdminNavy,
              ),
              const SizedBox(width: 10),
              Text(
                actions[i].label,
                style: TextStyle(
                  color: actions[i].destructive ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Admin-style search box (white, bordered, search icon) used inside Finance
/// dialogs, where the page-level input theme does not apply.
class FinanceSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  const FinanceSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kAdminBorder),
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(Icons.search_rounded, color: kAdminNavy),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

/// Gate for every Finance page that is scoped to an academic year. Loads the
/// years for the signed-in role through the [AcademicYearsProvider] in scope
/// (School Admin: school-admin API; FINANCE: the read-only finance API) and
/// only builds [child] once at least one year is available. Genuine failures
/// get the Admin error state with a working Retry.
class FinanceYearsGate extends StatefulWidget {
  final Widget child;
  const FinanceYearsGate({super.key, required this.child});

  @override
  State<FinanceYearsGate> createState() => _FinanceYearsGateState();
}

class _FinanceYearsGateState extends State<FinanceYearsGate> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ensureFinanceYears(context.read<AcademicYearsProvider>());
      if (mounted) setState(() => _requested = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    if (provider.years.isNotEmpty) return widget.child;
    if (!_requested || provider.loading) return const FinanceSkeleton();
    if (provider.errorCode == 'FINANCE_NOT_ENABLED')
      return const FinanceNotEnabledView();
    if (provider.error != null) {
      return FinancePageSurface(
        child: AdminErrorState(
          title: 'Could not load academic years.',
          message: 'Check your connection and try again.',
          onRetry: provider.refresh,
        ),
      );
    }
    return const FinancePageSurface(
      child: AdminEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No academic years',
        message: 'No academic years have been configured for this school.',
      ),
    );
  }
}

/// Raised placeholder cards shown while summary data loads, keeping the page
/// structure (header, year selector) stable instead of a full-page spinner.
class FinanceCardsSkeleton extends StatelessWidget {
  const FinanceCardsSkeleton({super.key});

  Widget _block(double height, {double? width}) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: kAdminNavy.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  Widget _card() => FinanceCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _block(26, width: 26),
            const SizedBox(width: 8),
            Expanded(child: _block(12)),
          ],
        ),
        const SizedBox(height: 10),
        _block(20, width: 90),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _card()),
            const SizedBox(width: 10),
            Expanded(child: _card()),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _card()),
            const SizedBox(width: 10),
            Expanded(child: _card()),
          ],
        ),
      ],
    ),
  );
}

/// Full-page loading placeholder: header bar plus [FinanceCardsSkeleton].
class FinanceSkeleton extends StatelessWidget {
  const FinanceSkeleton({super.key});

  Widget _block(double height, double width) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: kAdminNavy.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  @override
  Widget build(BuildContext context) => FinancePageSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(26, 180),
        const SizedBox(height: 8),
        _block(14, 280),
        const SizedBox(height: 20),
        const FinanceCardsSkeleton(),
      ],
    ),
  );
}

/// Mobile bottom navigation in the Admin `_BottomNav` style (raised, rounded
/// top, navy active item, safe-area aware).
class FinanceBottomNav extends StatelessWidget {
  final List<({IconData icon, String label})> items;
  final int index;
  final ValueChanged<int> onChange;
  const FinanceBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      elevation: 12,
      shadowColor: Colors.black38,
      color: Colors.transparent,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: items[i].label,
                  child: InkWell(
                    onTap: () => onChange(i),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 44,
                            height: 30,
                            decoration: BoxDecoration(
                              color: i == index
                                  ? kAdminNavy
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: i == index
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x32023471),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              items[i].icon,
                              size: 22,
                              color: i == index
                                  ? Colors.white
                                  : const Color(0xFF5C5C5C),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: i == index
                                  ? kAdminNavy
                                  : const Color(0xFF5C5C5C),
                            ),
                          ),
                        ],
                      ),
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
