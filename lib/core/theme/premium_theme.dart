import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumTheme {
  // Colors (Modern Minimalist)
  static const Color primary = Color(0xFF1A1A1A); // Jet Black
  static const Color secondary = Color(0xFF2E3A59); // Deep Navy Accents
  static const Color background = Color(0xFFF8F9FE); // Soft Blue-White
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF8F9BB3);
  static const Color accent = Color(0xFF4E5D78); // Steel Blue

  // Text Theme
  static TextTheme get _textTheme => GoogleFonts.montserratTextTheme().copyWith(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 36, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
    titleLarge: GoogleFonts.montserrat(
      fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, color: textPrimary, height: 1.5),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, color: textSecondary, height: 1.4),
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        background: background,
        surface: surface,
        brightness: Brightness.light,
      ),
      textTheme: _textTheme,
      
      // Components
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: primary),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white, // Text color
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill Shape
          textStyle: _textTheme.labelLarge,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: _textTheme.bodyMedium?.copyWith(color: textSecondary.withOpacity(0.6)),
      ),
      
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
