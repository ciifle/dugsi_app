import 'package:flutter/material.dart';
import 'package:kobac/utils/school_logo_url.dart';

class SchoolBrandLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final BorderRadius borderRadius;
  final Color? backgroundColor;

  const SchoolBrandLogo({
    super.key,
    this.logoUrl,
    this.size = 56,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = normalizeSchoolLogoUrl(logoUrl);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF023471).withValues(alpha: .1),
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.school_rounded,
        color: const Color(0xFF023471),
        size: size * .52,
      ),
    );
    if (url == null) return fallback;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
