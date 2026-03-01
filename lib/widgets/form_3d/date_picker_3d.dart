import 'package:flutter/material.dart';
import 'form_theme_3d.dart';

/// 3D elevated date picker field. Shows selected date and opens date picker on tap.
class DatePicker3D extends StatefulWidget {
  final String label;
  final String value;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final void Function(DateTime) onDatePicked;
  final String? errorText;

  const DatePicker3D({
    Key? key,
    required this.label,
    required this.value,
    required this.onDatePicked,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.errorText,
  }) : super(key: key);

  @override
  State<DatePicker3D> createState() => _DatePicker3DState();
}

class _DatePicker3DState extends State<DatePicker3D> {
  bool _focused = false;

  Future<void> _openPicker() async {
    setState(() => _focused = true);
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: FormTheme3D.primaryBlue,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    setState(() => _focused = false);
    if (picked != null) widget.onDatePicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: GestureDetector(
            onTap: _openPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: FormTheme3D.inputBg,
                borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
                border: Border.all(
                  color: hasError
                      ? FormTheme3D.errorRed.withOpacity(0.6)
                      : _focused
                          ? FormTheme3D.primaryBlue.withOpacity(0.5)
                          : Colors.transparent,
                  width: _focused || hasError ? 2 : 0,
                ),
                boxShadow: _focused
                    ? FormTheme3D.focusGlow(FormTheme3D.primaryBlue)
                    : FormTheme3D.inputShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: widget.value.isEmpty ? 16 : 12,
                            color: hasError
                                ? FormTheme3D.errorRed
                                : _focused
                                    ? FormTheme3D.primaryBlue
                                    : FormTheme3D.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.value.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: FormTheme3D.textPrimary,
                            ),
                          ),
                        ] else
                          const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 22,
                    color: FormTheme3D.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: FormTheme3D.errorRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
