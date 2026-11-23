import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// --------------------------------------------------------------
///  Paleta oficial Mirrify com as cores solicitadas:
///  [#ebf7ed] - Menta Claro / Brilho
///  [#CDB7ED] - Lavanda Suave
///  [#7897E4] - Azul Periwinkle
///  [#A688F1] - Roxo Violeta Vibrante
/// --------------------------------------------------------------
class AppPalette {
  static const Color mint = Color(0xFFEBF7ED);
  static const Color lavender = Color(0xFFCDB7ED);
  static const Color periwinkle = Color(0xFF7897E4);
  static const Color violet = Color(0xFFA688F1);

  // Cores semânticas
  static const Color primary = periwinkle;
  static const Color secondary = violet;
  static const Color accent = lavender;
  static const Color background = Color(0xFFF6F4FC);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF2C2448);
  static const Color textMuted = Color(0xFF6B6684);
  static const Color error = Color(0xFFE53935);
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF2C2448);

  // Gradientes principais Mirrify
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [periwinkle, violet],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      mint,
      Color(0xFFE9E5F8),
      Color(0xFFDDD2F5),
      lavender,
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF9F7FD),
    ],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.background,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppPalette.primary,
          onPrimary: AppPalette.onPrimary,
          secondary: AppPalette.secondary,
          onSecondary: Colors.white,
          background: AppPalette.background,
          onBackground: AppPalette.textDark,
          surface: AppPalette.surface,
          onSurface: AppPalette.textDark,
          error: AppPalette.error,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.montserrat(
            color: AppPalette.textDark,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.montserrat(
            color: AppPalette.textDark,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            color: AppPalette.textDark,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            color: AppPalette.textDark,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            color: AppPalette.textMuted,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppPalette.textMuted.withOpacity(0.7),
            fontSize: 14,
          ),
          labelStyle: GoogleFonts.plusJakartaSans(
            color: AppPalette.textMuted,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2DCF0), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2DCF0), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.secondary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.error, width: 2),
          ),
        ),
      );
}
