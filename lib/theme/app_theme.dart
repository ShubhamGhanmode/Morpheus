import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'theme_contrast.dart';
import 'typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(BuildContext context, {AppContrast contrast = AppContrast.normal}) {
    return _buildTheme(context, _schemeFor(Brightness.light, contrast));
  }

  static ThemeData dark(BuildContext context, {AppContrast contrast = AppContrast.normal}) {
    return _buildTheme(context, _schemeFor(Brightness.dark, contrast));
  }

  static ColorScheme _schemeFor(Brightness brightness, AppContrast contrast) {
    switch (contrast) {
      case AppContrast.medium:
        return brightness == Brightness.dark ? darkMediumContrastColorScheme : lightMediumContrastColorScheme;
      case AppContrast.high:
        return brightness == Brightness.dark ? darkHighContrastColorScheme : lightHighContrastColorScheme;
      case AppContrast.normal:
      default:
        return brightness == Brightness.dark ? darkColorScheme : lightColorScheme;
    }
  }

  static ThemeData _buildTheme(BuildContext context, ColorScheme colors) {
    final textTheme = createTextTheme(context, "Manrope", "Manrope");
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      textTheme: textTheme.apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
    );
    final themedText = baseTheme.textTheme;

    return baseTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surfaceTint,
        foregroundColor: colors.onSurface,
        elevation: 0,
        titleTextStyle: themedText.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => themedText.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? colors.tertiary : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
            fontSize: states.contains(WidgetState.selected) ? 13 : 12,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedColor: colors.primaryContainer,
        backgroundColor: colors.surfaceContainerLowest,
        labelStyle: TextStyle(color: colors.onSurface),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
