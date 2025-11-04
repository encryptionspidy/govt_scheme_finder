import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: secondaryBlue,
      surface: surfaceCard,
      onPrimary: Colors.white,
      onSurface: neutralText,
    );

    final TextTheme baseTextTheme = TextTheme(
      displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500),
    ).apply(
      displayColor: neutralText,
      bodyColor: neutralText,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(letterSpacing: 0.2),
        titleLarge: baseTextTheme.titleLarge?.copyWith(letterSpacing: 0.15),
        titleMedium: baseTextTheme.titleMedium?.copyWith(letterSpacing: 0.1),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryBlue,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
  shadowColor: Colors.black.withAlpha(13),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(color: mutedText),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accentLightBlue,
        selectedColor: primaryBlue,
        secondarySelectedColor: secondaryBlue,
        labelStyle: baseTextTheme.titleSmall?.copyWith(color: neutralText, fontWeight: FontWeight.w600),
        secondaryLabelStyle: baseTextTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 12,
        indicatorColor: primaryBlue.withAlpha(26),
        backgroundColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) => baseTextTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primaryBlue : mutedText,
            letterSpacing: 0.1,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primaryBlue : mutedText,
            size: states.contains(WidgetState.selected) ? 28 : 26,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1, color: dividerColor),
    );
  }
}
