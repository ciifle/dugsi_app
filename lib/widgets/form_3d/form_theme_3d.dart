import 'package:flutter/material.dart';

/// Central theme for 3D form components. Matches School Admin brand.
class FormTheme3D {
  FormTheme3D._();

  static const Color primaryBlue = Color(0xFF023471);
  static const Color primaryGreen = Color(0xFF5AB04B);
  static const Color bgColor = Color(0xFFF0F3F7);
  static const Color cardBg = Color(0xFFFAFBFD);
  static const Color inputBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textHint = Color(0xFF6B7280);
  static const Color errorRed = Color(0xFFDC2626);

  static const double radiusInput = 16.0;
  static const double radiusCard = 20.0;
  static const double radiusButton = 16.0;

  static const Duration transitionDuration = Duration(milliseconds: 250);
  static const Curve transitionCurve = Curves.easeOutCubic;

  /// Layered shadows for elevated inputs (soft neumorphic).
  static List<BoxShadow> get inputShadow => [
        BoxShadow(
          color: Colors.white,
          blurRadius: 12,
          offset: const Offset(-4, -4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: primaryBlue.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(4, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(2, 2),
          spreadRadius: 0,
        ),
      ];

  /// Focus glow for inputs.
  static List<BoxShadow> focusGlow(Color color) => [
        ...inputShadow,
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 14,
          offset: const Offset(0, 0),
          spreadRadius: 0,
        ),
      ];

  /// Card section shadow.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.white,
          blurRadius: 20,
          offset: const Offset(-6, -6),
          spreadRadius: 0.5,
        ),
        BoxShadow(
          color: primaryBlue.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(6, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(3, 4),
          spreadRadius: 0,
        ),
      ];

  /// Primary button shadow (elevated).
  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: Colors.white.withOpacity(0.4),
          blurRadius: 10,
          offset: const Offset(-3, -3),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: primaryGreen.withOpacity(0.35),
          blurRadius: 16,
          offset: const Offset(4, 6),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(2, 3),
          spreadRadius: 0,
        ),
      ];
}
