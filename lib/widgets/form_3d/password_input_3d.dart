import 'package:flutter/material.dart';
import 'form_theme_3d.dart';
import 'input_3d.dart';

/// 3D password input with eye toggle. Wraps Input3D with visibility toggle.
class PasswordInput3D extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;

  const PasswordInput3D({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
  }) : super(key: key);

  @override
  State<PasswordInput3D> createState() => _PasswordInput3DState();
}

class _PasswordInput3DState extends State<PasswordInput3D> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Input3D(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint ?? widget.label,
      validator: widget.validator,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: FormTheme3D.primaryBlue,
          size: 22,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
        padding: const EdgeInsets.only(right: 12),
      ),
    );
  }
}
