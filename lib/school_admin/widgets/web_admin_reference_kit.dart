import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';

const webNavy = Color(0xFF003E80);
const webGreen = Color(0xFF25A642);
const webMuted = Color(0xFF63799E);
const webBorder = Color(0xFFE3ECF6);

class WebAdminPageHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final String? year;
  const WebAdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.year,
  });
  @override
  Widget build(BuildContext context) {
    final activeYear =
        year ?? context.watch<AcademicYearsProvider?>()?.activeYear?.name;
    return LayoutBuilder(
      builder: (context, box) => Wrap(
        spacing: 20,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: box.maxWidth > 800 ? box.maxWidth - 370 : box.maxWidth,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: webNavy,
                  child: Icon(icon, color: Colors.white, size: 27),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: webNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 15, color: webMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_outlined, size: 18, color: webMuted),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right, color: webMuted, size: 18),
              ),
              Text(title, style: const TextStyle(color: webMuted)),
              if (activeYear != null) ...[
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF17A56C),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academic Year',
                            style: TextStyle(fontSize: 11, color: webNavy),
                          ),
                          Text(
                            activeYear,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: webNavy,
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
        ],
      ),
    );
  }
}

class WebAdminPage extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final String? year;
  final List<Widget> children;
  const WebAdminPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.year,
  });
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF4F8FC),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        WebAdminPageHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          year: year,
        ),
        const SizedBox(height: 24),
        for (final child in children) ...[child, const SizedBox(height: 18)],
      ],
    ),
  );
}

class WebAdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const WebAdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: webBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07003E80),
          blurRadius: 22,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}

class WebAdminStat {
  final String label, value;
  final IconData icon;
  final Color color;
  const WebAdminStat(this.label, this.value, this.icon, [this.color = webNavy]);
}

class WebAdminStats extends StatelessWidget {
  final List<WebAdminStat> items;
  const WebAdminStats({super.key, required this.items});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 900 ? items.length : 2;
      final width = (box.maxWidth - 14 * (columns - 1)) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: items
            .map(
              (item) => SizedBox(
                width: width,
                child: WebAdminCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: item.color.withValues(alpha: .09),
                        child: Icon(item.icon, size: 28, color: item.color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: webNavy,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.label,
                              style: const TextStyle(
                                color: webMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

InputDecoration webAdminInput(String label, {IconData? icon}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: webNavy, size: 21),
      labelStyle: const TextStyle(color: webNavy, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFFBFDFF),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: webBorder),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: webBorder),
      ),
    );

Widget webAdminAction(
  String label,
  IconData icon,
  VoidCallback? onPressed, {
  Color color = webGreen,
  bool outlined = false,
}) {
  final style = outlined
      ? OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .5)),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        )
      : FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        );
  return outlined
      ? OutlinedButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon, size: 18),
          label: Text(label),
        )
      : FilledButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon, size: 18),
          label: Text(label),
        );
}

Widget webAdminIcon(
  String label,
  IconData icon,
  VoidCallback? action, {
  bool destructive = false,
}) => IconButton(
  tooltip: label,
  onPressed: action,
  style: IconButton.styleFrom(
    minimumSize: const Size(34, 34),
    maximumSize: const Size(34, 34),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: destructive ? const Color(0xFFE3313D) : webNavy,
    side: BorderSide(color: destructive ? const Color(0xFFFFD2D7) : webBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
  ),
  icon: Icon(icon, size: 19),
);

Widget webAdminBadge(String text, {bool active = true}) => Align(
  alignment: Alignment.centerLeft,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFEAF7E9) : const Color(0xFFFFECEE),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: active ? const Color(0xFF249B31) : const Color(0xFFD53945),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  ),
);

class WebAdminRow {
  final String searchText;
  final List<Widget> cells;
  const WebAdminRow({required this.searchText, required this.cells});
}

/// Full-width table with a horizontal scroll boundary at compact desktop widths.
class WebAdminTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final Map<int, TableColumnWidth>? columnWidths;
  final double minWidth;
  const WebAdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.columnWidths,
    this.minWidth = 780,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(box.maxWidth, minWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              horizontalInside: BorderSide(color: webBorder),
              top: BorderSide(color: webBorder),
              bottom: BorderSide(color: webBorder),
              left: BorderSide(color: webBorder),
              right: BorderSide(color: webBorder),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFEDF4FB)),
                children: columns
                    .map(
                      (label) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 17,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF365078),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              for (var i = 0; i < rows.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i.isOdd ? const Color(0xFFFAFCFF) : Colors.white,
                  ),
                  children: rows[i]
                      .map(
                        (cell) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(
                              color: Color(0xFF233957),
                              fontSize: 13,
                            ),
                            child: cell,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WebAdminDataPanel extends StatefulWidget {
  final String title, subtitle, searchHint, noun;
  final IconData icon;
  final List<String> columns;
  final List<WebAdminRow> rows;
  final List<Widget> actions;
  final Map<int, TableColumnWidth>? columnWidths;
  final bool loading;
  final String? error;
  final VoidCallback? retry;
  const WebAdminDataPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.noun,
    required this.icon,
    required this.columns,
    required this.rows,
    this.actions = const [],
    this.columnWidths,
    this.loading = false,
    this.error,
    this.retry,
  });
  @override
  State<WebAdminDataPanel> createState() => _WebAdminDataPanelState();
}

class _WebAdminDataPanelState extends State<WebAdminDataPanel> {
  String _search = '';
  int _page = 0;
  static const _size = 10;
  @override
  Widget build(BuildContext context) {
    final filtered = widget.rows
        .where(
          (row) => row.searchText.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();
    final pages = math.max(1, (filtered.length / _size).ceil());
    _page = _page.clamp(0, pages - 1);
    final start = _page * _size;
    final visible = filtered.skip(start).take(_size).toList();
    return WebAdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: box.maxWidth >= 900 ? 460 : 300,
                  child: Row(
                    children: [
                      Icon(widget.icon, color: webNavy, size: 27),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: webNavy,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            if (widget.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: const TextStyle(
                                  color: webMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        onChanged: (value) => setState(() {
                          _search = value;
                          _page = 0;
                        }),
                        decoration: webAdminInput(
                          widget.searchHint,
                          icon: Icons.search,
                        ),
                      ),
                    ),
                    ...widget.actions,
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(widget.error!),
                  TextButton(
                    onPressed: widget.retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else ...[
            WebAdminTable(
              columns: widget.columns,
              rows: visible.map((row) => row.cells).toList(),
              columnWidths: widget.columnWidths,
            ),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No matching records.'),
              ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                Text(
                  'Showing ${filtered.isEmpty ? 0 : start + 1} to ${start + visible.length} of ${filtered.length} ${widget.noun}',
                  style: const TextStyle(color: webMuted, fontSize: 13),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    webAdminIcon(
                      'Previous page',
                      Icons.chevron_left,
                      _page > 0 ? () => setState(() => _page--) : null,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: webNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_page + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    webAdminIcon(
                      'Next page',
                      Icons.chevron_right,
                      _page + 1 < pages ? () => setState(() => _page++) : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
