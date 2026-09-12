import 'package:flutter/material.dart';
import 'package:kobac/widgets/form_3d/form_theme_3d.dart';

/// Applied above the navigator only at the desktop-web breakpoint, including
/// route overlays (dialogs, menus and date pickers). Native themes stay intact.
ThemeData webAdminTheme(ThemeData base) {
  const navy = FormTheme3D.primaryBlue;
  const green = FormTheme3D.primaryGreen;
  final scheme = ColorScheme.fromSeed(seedColor: navy).copyWith(
    primary: navy,
    onPrimary: Colors.white,
    secondary: green,
    onSecondary: Colors.white,
    tertiary: green,
    onTertiary: Colors.white,
    surface: Colors.white,
    surfaceTint: Colors.transparent,
    error: FormTheme3D.errorRed,
  );
  return base.copyWith(
    colorScheme: scheme,
    primaryColor: navy,
    scaffoldBackgroundColor: FormTheme3D.bgColor,
    focusColor: navy.withValues(alpha: .12),
    hoverColor: navy.withValues(alpha: .06),
    splashColor: navy.withValues(alpha: .12),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: navy,
      selectionColor: navy.withValues(alpha: .2),
      selectionHandleColor: navy,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: navy),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: navy),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: navy),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? null
            : states.contains(WidgetState.selected)
            ? navy
            : null,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? null
            : states.contains(WidgetState.selected)
            ? navy
            : null,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? null
            : states.contains(WidgetState.selected)
            ? green
            : null,
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: navy, width: 2),
      ),
      floatingLabelStyle: const TextStyle(color: navy),
    ),
  );
}
