import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_theme_3d.dart';

/// 3D elevated text input with floating label, focus glow, and error state.
class Input3D extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onSubmitted;
  final Widget? suffixIcon;

  const Input3D({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
    this.suffixIcon,
  }) : super(key: key);

  @override
  State<Input3D> createState() => _Input3DState();
}

class _Input3DState extends State<Input3D> with SingleTickerProviderStateMixin {
  bool _focused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() => setState(() => _focused = _focusNode.hasFocus);
  void _onTextChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasValue => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.validator?.call(widget.controller.text) != null &&
        widget.validator!(widget.controller.text) != null;
    final isFloating = _focused || _hasValue;

    return AnimatedContainer(
      duration: FormTheme3D.transitionDuration,
      curve: FormTheme3D.transitionCurve,
      transform: Matrix4.identity()..scale(_focused ? 1.01 : 1.0),
      transformAlignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
            child: widget.suffixIcon != null
                ? Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          validator: widget.validator,
                          obscureText: widget.obscureText,
                          keyboardType: widget.keyboardType,
                          textCapitalization: widget.textCapitalization,
                          inputFormatters: widget.inputFormatters,
                          onFieldSubmitted: widget.onSubmitted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: FormTheme3D.textPrimary,
                          ),
                          decoration: _buildDecoration(0),
                        ),
                      ),
                      widget.suffixIcon!,
                    ],
                  )
                : TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    validator: widget.validator,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    textCapitalization: widget.textCapitalization,
                    inputFormatters: widget.inputFormatters,
                    onFieldSubmitted: widget.onSubmitted,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: FormTheme3D.textPrimary,
                    ),
                    decoration: _buildDecoration(18),
                  ),
          ),
          AnimatedSize(
            duration: FormTheme3D.transitionDuration,
            curve: FormTheme3D.transitionCurve,
            child: const SizedBox(height: 4),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildDecoration(double rightPadding) {
    final isFloating = _focused || _hasValue;
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hint ?? widget.label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(
        fontSize: isFloating ? 12 : 16,
        color: widget.validator?.call(widget.controller.text) != null
            ? FormTheme3D.errorRed
            : _focused
                ? FormTheme3D.primaryBlue
                : FormTheme3D.textHint,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        fontSize: 16,
        color: FormTheme3D.textHint.withOpacity(0.8),
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: EdgeInsets.only(left: 18, top: 18, bottom: 18, right: rightPadding),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
  }
}
