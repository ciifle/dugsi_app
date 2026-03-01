import 'package:flutter/material.dart';
import 'form_theme_3d.dart';

/// Wraps form content in an elevated card with 3D shadow.
class FormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const FormCard({Key? key, required this.child, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FormTheme3D.cardBg,
        borderRadius: BorderRadius.circular(FormTheme3D.radiusCard),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: FormTheme3D.cardShadow,
      ),
      child: child,
    );
  }
}

/// Section with title and optional subtitle. Groups related fields.
class FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const FormSection({
    Key? key,
    required this.title,
    this.subtitle,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FormTheme3D.primaryBlue,
            letterSpacing: 0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: FormTheme3D.textHint,
            ),
          ),
        ],
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}
