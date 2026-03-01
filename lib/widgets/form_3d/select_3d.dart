import 'package:flutter/material.dart';
import 'form_theme_3d.dart';

/// 3D elevated dropdown with same shadow and focus style as Input3D.
class Select3D<T> extends StatefulWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const Select3D({
    Key? key,
    required this.value,
    required this.label,
    required this.items,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<Select3D<T>> createState() => _Select3DState<T>();
}

class _Select3DState<T> extends State<Select3D<T>> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: Container(
        decoration: BoxDecoration(
          color: FormTheme3D.inputBg,
          borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
          border: Border.all(color: Colors.transparent, width: 2),
          boxShadow: FormTheme3D.inputShadow,
        ),
        child: DropdownButtonFormField<T>(
          value: widget.value,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontSize: (widget.value != null) ? 12 : 16,
              color: FormTheme3D.textHint,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            errorStyle: const TextStyle(fontSize: 12, color: FormTheme3D.errorRed),
          ),
          items: widget.items,
          onChanged: widget.onChanged,
          isExpanded: true,
          icon: AnimatedRotation(
            turns: _focused ? 0.5 : 0,
            duration: FormTheme3D.transitionDuration,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: FormTheme3D.primaryBlue,
            ),
          ),
          dropdownColor: FormTheme3D.inputBg,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: FormTheme3D.textPrimary,
          ),
        ),
      ),
    );
  }
}
