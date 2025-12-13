import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumTheme {
  // Colors (Winter Chill Palette)
  static const Color primary = Color(0xFF4F7C82); // Deep Teal
  static const Color secondary = Color(0xFF93B1B5); // Muted Blue-Grey
  static const Color accent = Color(0xFF0B2E33); // Darkest Teal (High Contrast)
  static const Color warning = Color(0xFFF6D55C); // Keep Yellow for warnings
  static const Color background = Color(0xFFE8F6F8); // Very Light version of #B8E3E9 for BG
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0B2E33); // Deepest Teal
  static const Color textSecondary = Color(0xFF4F7C82); // Primary Teal for secondary text

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F7C82), Color(0xFF2E5E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF93B1B5), Color(0xFF4F7C82)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Theme
  static TextTheme get _textTheme => GoogleFonts.poppinsTextTheme().copyWith(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
    displayMedium: GoogleFonts.poppins(
      fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
    titleLarge: GoogleFonts.poppins(
      fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16, color: textPrimary, height: 1.5),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14, color: textSecondary, height: 1.4),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: textPrimary),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white, // Text color
          elevation: 10,
          shadowColor: primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: _textTheme.labelLarge,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 10,
        shadowColor: Color(0xFF7B66FF).withOpacity(0.15), // Colored Shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: _textTheme.bodyMedium?.copyWith(color: textSecondary.withOpacity(0.6)),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
