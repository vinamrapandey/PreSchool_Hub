import 'package:flutter/material.dart';

class AppTheme {
  /// Default seed color of the application (soft slate/indigo blue).
  static const Color defaultSeedColor = Color(0xFF4A90D9);

  /// Generates a beautiful light theme configuration based on the school's dynamic seed color.
  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,

      // Custom premium typography settings (clean, modern look)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0),
        titleMedium: TextStyle(fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, letterSpacing: 0.15),
        bodyMedium: TextStyle(fontSize: 14, letterSpacing: 0.25),
      ),

      // Sleek Cards with rounded borders and soft shadows
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(128),
            width: 1,
          ),
        ),
        color: colorScheme.surface,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),

      // Modern Elevated & Outlined buttons with rounded shapes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text input fields decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(150)),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.primary,
        suffixIconColor: colorScheme.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(100),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}
