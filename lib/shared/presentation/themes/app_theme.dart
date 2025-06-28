import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class AppTheme {
  static const _primarySeedColor = Color(0xFF3B82F6); // Blue
  static const _secondarySeedColor = Color(0xFF14B8A6); // Teal
  static const _accentSeedColor = Color(0xFFF97316); // Orange

  static ThemeData lightTheme = _createTheme(Brightness.light);
  static ThemeData darkTheme = _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeedColor,
      brightness: brightness,
    ).copyWith(
      secondary: _secondarySeedColor,
      tertiary: _accentSeedColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      
      // Typography
      textTheme: _createTextTheme(colorScheme),
      
      // Components
      appBarTheme: _createAppBarTheme(colorScheme),
      cardTheme: _createCardTheme(colorScheme),
      elevatedButtonTheme: _createElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _createOutlinedButtonTheme(colorScheme),
      inputDecorationTheme: _createInputDecorationTheme(colorScheme),
      bottomNavigationBarTheme: _createBottomNavTheme(colorScheme),
      
      // Spacing
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static TextTheme _createTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      
      // Titles
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      
      // Body text
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      
      // Labels
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static AppBarTheme _createAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  static CardTheme _createCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surface,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
    );
  }

  static ElevatedButtonThemeData _createElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _createOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: colorScheme.outline),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static InputDecorationTheme _createInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
    );
  }

  static BottomNavigationBarThemeData _createBottomNavTheme(ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}