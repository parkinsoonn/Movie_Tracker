// ---------------------------------------------------------------------------
// app_theme.dart
// ---------------------------------------------------------------------------
// Central design system for the Cinephile app.
//
// All colors, typography, spacing, and shape values are extracted from the
// Stitch "Cinematic Noir" design spec (DESIGN.md). Every screen imports
// this file instead of hardcoding visual constants.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cinematic Noir design tokens extracted from Stitch DESIGN.md.
class CinephileTheme {
  CinephileTheme._();

  // ── Colors ────────────────────────────────────────────────────────────────

  /// Level 0 — deepest background (theater darkness)
  static const Color background = Color(0xFF131314);

  /// Level 1 — card / container surface
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);

  /// Level 1 lighter — form container
  static const Color surfaceContainer = Color(0xFF1F2020);

  /// Level 0.5 — subtle separation layer
  static const Color surfaceContainerLow = Color(0xFF1B1C1C);

  /// Level 2 - highest
  static const Color surfaceContainerHighest = Color(0xFF343535);

  /// Primary - Gray/Silver text
  static const Color primary = Color(0xFFC8C6C6);

  /// Primary Container - buttons, bottom nav active bg
  static const Color primaryContainer = Color(0xFF747474);
  static const Color onPrimaryContainer = Color(0xFFFEFBFB);

  /// Secondary - Salmon pink accent
  static const Color secondary = Color(0xFFFFB3AC);
  static const Color onSecondary = Color(0xFF680008);

  /// Tertiary - Blue accent
  static const Color tertiary = Color(0xFFB0C6FF);

  /// Star Color - Gold/Yellow for ratings
  static const Color starColor = Color(0xFFFFD700);

  /// On-surface — standard readable text
  static const Color onSurface = Color(0xFFE4E2E2);

  /// On-surface-variant — secondary / muted text
  static const Color onSurfaceVariant = Color(0xFFC4C7C7);

  /// Outline variant — subtle borders, dividers
  static const Color outlineVariant = Color(0xFF444748);

  /// Brand purple / dark red — gradient start, accent
  static const Color brandPurple = Color(0xFF8A1A1A); // secondary container tone

  /// Brand amber / pink — gradient end, links, highlights
  static const Color brandAmber = Color(0xFFFFB3AC); // secondary tone

  /// Error
  static const Color error = Color(0xFFFFB4AB);

  // ── Gradients ─────────────────────────────────────────────────────────────

  /// Primary CTA gradient (Sign In / Sign Up buttons)
  static const LinearGradient ctaGradient = LinearGradient(
    colors: [brandPurple, brandAmber],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// 135° diagonal CTA gradient variant
  static const LinearGradient ctaGradientDiagonal = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Spacing ───────────────────────────────────────────────────────────────

  static const double spacingBase = 8.0;
  static const double spacingStackSm = 12.0;
  static const double spacingStackMd = 24.0;
  static const double spacingStackLg = 40.0;
  static const double spacingGutter = 16.0;
  static const double spacingContainerPadding = 24.0;

  // ── Shapes ────────────────────────────────────────────────────────────────

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 24.0;

  // ── Typography Helpers ────────────────────────────────────────────────────

  /// Display Large — 48px, ExtraBold (movie titles, hero headings)
  static TextStyle displayLg({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.17,
        letterSpacing: -0.96,
        color: color ?? onSurface,
      );

  /// Headline Large — 32px, Bold
  static TextStyle headlineLg({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color ?? onSurface,
      );

  /// Headline Large Mobile — 24px, Bold
  static TextStyle headlineLgMobile({Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        color: color ?? onSurface,
      );

  /// Headline Medium — 20px, SemiBold
  static TextStyle headlineMd({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color ?? onSurface,
      );

  /// Body Large — 18px, Regular
  static TextStyle bodyLg({Color? color}) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.56,
        color: color ?? onSurfaceVariant,
      );

  /// Body Medium — 16px, Regular
  static TextStyle bodyMd({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color ?? onSurfaceVariant,
      );

  /// Label Medium — 14px, Medium
  static TextStyle labelMd({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.7,
        color: color ?? onSurface,
      );

  /// Label Small — 12px, Medium
  static TextStyle labelSm({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        color: color ?? onSurfaceVariant,
      );

  // ── ThemeData Builder ─────────────────────────────────────────────────────

  /// Returns a complete [ThemeData] configured with the Cinematic Noir system.
  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: primaryContainer,
        onPrimary: Color(0xFF3A3000),
        secondary: onSurfaceVariant,
        onSecondary: Color(0xFF2F3131),
        error: error,
        onSurface: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: primary,
        ),
        iconTheme: const IconThemeData(color: onSurfaceVariant),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primaryContainer,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
