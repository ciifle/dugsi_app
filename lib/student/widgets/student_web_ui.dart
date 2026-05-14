import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const Color studentWebBg = Color(0xFFF0F3F7);
const Color studentWebBlue = Color(0xFF023471);
const Color studentWebGreen = Color(0xFF5AB04B);
const Color studentWebTextPrimary = Color(0xFF2D3436);
const Color studentWebTextSecondary = Color(0xFF6B7280);
const Color studentWebBorder = Color(0xFFE8ECF2);

bool isStudentDesktopWeb(BuildContext context) {
  return kIsWeb && MediaQuery.sizeOf(context).width >= 1024;
}

class StudentWebSurface extends StatelessWidget {
  final Widget child;

  const StudentWebSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: studentWebBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class StudentWebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const StudentWebCard({
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
        border: Border.all(color: studentWebBorder),
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

class StudentWebInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const StudentWebInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: studentWebTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: studentWebTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentWebTableHeader extends StatelessWidget {
  final List<String> columns;
  final List<int> flex;

  const StudentWebTableHeader({
    super.key,
    required this.columns,
    this.flex = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: studentWebBlue.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: List.generate(columns.length, (index) {
          final f = flex.length > index ? flex[index] : 1;
          return Expanded(
            flex: f,
            child: Text(
              columns[index],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: studentWebBlue,
                letterSpacing: 0.3,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StudentWebTableRow extends StatelessWidget {
  final List<Widget> cells;
  final List<int> flex;
  final VoidCallback? onTap;

  const StudentWebTableRow({
    super.key,
    required this.cells,
    this.flex = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: List.generate(cells.length, (index) {
        final f = flex.length > index ? flex[index] : 1;
        return Expanded(flex: f, child: cells[index]);
      }),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: studentWebBorder)),
          ),
          child: row,
        ),
      ),
    );
  }
}

class StudentWebDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final Widget? hint;

  const StudentWebDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
        splashColor: studentWebBlue.withValues(alpha: 0.06),
        highlightColor: studentWebBlue.withValues(alpha: 0.06),
        hoverColor: studentWebBlue.withValues(alpha: 0.04),
        colorScheme: Theme.of(context).colorScheme.copyWith(
          surface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: studentWebBorder),
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
            isExpanded: isExpanded,
            dropdownColor: Colors.white,
            focusColor: studentWebBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: studentWebTextSecondary,
              size: 20,
            ),
            style: const TextStyle(
              color: studentWebBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
