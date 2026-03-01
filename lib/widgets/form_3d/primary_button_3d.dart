import 'package:flutter/material.dart';
import 'form_theme_3d.dart';

/// 3D elevated primary button with press animation and loading spinner.
class PrimaryButton3D extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  const PrimaryButton3D({
    Key? key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.height = 54,
  }) : super(key: key);

  @override
  State<PrimaryButton3D> createState() => _PrimaryButton3DState();
}

class _PrimaryButton3DState extends State<PrimaryButton3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = (widget.onPressed != null && !widget.loading);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: FormTheme3D.transitionDuration,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FormTheme3D.primaryGreen,
                      FormTheme3D.primaryGreen.withOpacity(0.85),
                    ],
                  )
                : null,
            color: enabled ? null : FormTheme3D.primaryGreen.withOpacity(0.5),
            borderRadius: BorderRadius.circular(FormTheme3D.radiusButton),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: enabled ? FormTheme3D.buttonShadow : null,
          ),
          child: Center(
                child: widget.loading
                    ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
