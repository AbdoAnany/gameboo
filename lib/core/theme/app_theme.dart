import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Glassmorphism Colors - Light Mode
  static const Color lightGlassBackground = Color(0xFFF8F9FA);
  static const Color lightGlassContainer = Color(0xFFFFFFFF);
  static const Color lightGlassBorder = Color(0x33FFFFFF);
  static const Color lightPrimary = Color(0xFF6366F1);
  static const Color lightSecondary = Color(0xFF8B5CF6);
  static const Color lightAccent = Color(0xFFEC4899);
  static const Color lightSuccess = Color(0xFF10B981);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightError = Color(0xFFEF4444);

  // Glassmorphism Colors - Dark Mode
  static const Color darkGlassBackground = Color(0xFF0F0F23);
  static const Color darkGlassContainer = Color(0xFF1A1A2E);
  static const Color darkGlassBorder = Color(0x1AFFFFFF);
  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkSecondary = Color(0xFFA78BFA);
  static const Color darkAccent = Color(0xFFF472B6);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkError = Color(0xFFF87171);

  // Gradients
  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F9FA), Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0F23), Color(0xFF16213E), Color(0xFF1A1A2E)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  // Text Styles
  static TextStyle _baseTextStyle = GoogleFonts.poppins();

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightGlassBackground,
    fontFamily: GoogleFonts.poppins().fontFamily,

    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      tertiary: lightAccent,
      surface: lightGlassContainer,
      background: lightGlassBackground,
      error: lightError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1F2937),
      onBackground: Color(0xFF1F2937),
      onError: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFF1F2937),
      titleTextStyle: _baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: lightGlassContainer.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: lightGlassBorder, width: 1),
      ),
    ),

    textTheme: TextTheme(
      displayLarge: _baseTextStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2937),
      ),
      displayMedium: _baseTextStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2937),
      ),
      displaySmall: _baseTextStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
      headlineLarge: _baseTextStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
      headlineMedium: _baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
      headlineSmall: _baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
      titleLarge: _baseTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
      titleMedium: _baseTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
      ),
      bodyLarge: _baseTextStyle.copyWith(
        fontSize: 16,
        color: const Color(0xFF374151),
      ),
      bodyMedium: _baseTextStyle.copyWith(
        fontSize: 14,
        color: const Color(0xFF374151),
      ),
      bodySmall: _baseTextStyle.copyWith(
        fontSize: 12,
        color: const Color(0xFF6B7280),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkGlassBackground,
    fontFamily: GoogleFonts.poppins().fontFamily,

    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      tertiary: darkAccent,
      surface: darkGlassContainer,
      background: darkGlassBackground,
      error: darkError,
      onPrimary: Color(0xFF1F2937),
      onSecondary: Color(0xFF1F2937),
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Color(0xFF1F2937),
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: _baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: darkPrimary,
        foregroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkGlassContainer.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: darkGlassBorder, width: 1),
      ),
    ),

    textTheme: TextTheme(
      displayLarge: _baseTextStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: _baseTextStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displaySmall: _baseTextStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineLarge: _baseTextStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineMedium: _baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineSmall: _baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: _baseTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: _baseTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: _baseTextStyle.copyWith(
        fontSize: 16,
        color: const Color(0xFFD1D5DB),
      ),
      bodyMedium: _baseTextStyle.copyWith(
        fontSize: 14,
        color: const Color(0xFFD1D5DB),
      ),
      bodySmall: _baseTextStyle.copyWith(
        fontSize: 12,
        color: const Color(0xFF9CA3AF),
      ),
    ),
  );
}
