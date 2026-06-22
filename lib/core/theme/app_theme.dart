import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const brand = Color(0xff0b845c);
  static const brandDark = Color(0xff064d37);
  static const surface = Color(0xfff4f6f5);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xff1a1a1a);
  static const textSecondary = Color(0xff6b7280);
  static const textMuted = Color(0xff9ca3af);
  static const divider = Color(0xffe5e7eb);
  static const error = Color(0xffe74c3c);
  static const success = Color(0xff27ae60);
  static const warning = Color(0xffe67e22);
  static const info = Color(0xff4a90d9);

  // VAS accent colours
  static const airtime = Color(0xff4a90d9);
  static const data = Color(0xff9b59b6);
  static const electricity = Color(0xffe67e22);
  static const betting = Color(0xffe74c3c);
  static const tvCable = Color(0xff16213e);
  static const transfer = Color(0xff2ecc71);
}

// ─── Text Styles ──────────────────────────────────────────────────────────────

class AppText {
  AppText._();

  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w800, color: color);

  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w700, color: color);

  static TextStyle h3({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: color);

  static TextStyle body({Color color = AppColors.textPrimary, double size = 14}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: size, fontWeight: FontWeight.w500, color: color);

  static TextStyle label({Color color = AppColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: color);

  static TextStyle caption({Color color = AppColors.textMuted}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500, color: color);

  static TextStyle button({Color color = Colors.white}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w700, color: color);

  static TextStyle amount({Color color = AppColors.textPrimary, double size = 32}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: size, fontWeight: FontWeight.w800, color: color,
          letterSpacing: -0.5);
}

// ─── Decoration Helpers ───────────────────────────────────────────────────────

class AppCard {
  AppCard._();

  static BoxDecoration standard({
    Color color = AppColors.cardBg,
    double radius = 16,
    double elevation = 0.04,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevation),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration gradient({
    List<Color> colors = const [AppColors.brand, AppColors.brandDark],
    double radius = 24,
  }) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );
}

// ─── Button Styles ────────────────────────────────────────────────────────────

class AppButtonStyle {
  AppButtonStyle._();

  static ButtonStyle primary({Color bg = AppColors.brand}) =>
      ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: AppText.button(),
      );

  static ButtonStyle secondary() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppColors.brand, width: 1.5),
        textStyle: AppText.button(color: AppColors.brand),
      );
}

// ─── Input Decoration ────────────────────────────────────────────────────────

class AppInput {
  AppInput._();

  static InputDecoration field({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        labelStyle: AppText.body(color: AppColors.textSecondary),
        hintStyle: AppText.body(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}

// ─── MaterialTheme ────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.brand,
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          titleTextStyle: AppText.h3(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppButtonStyle.primary(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      );
}
