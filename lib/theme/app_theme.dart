import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color palette for ClassPulse.
/// Change values here to update colors across the entire app.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF1E6AF9);
  static const textDark = Color(0xFF1E293B);
  static const textMedium = Color(0xFF334155);
  static const textLight = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const surface = Color(0xFFF1F5F9);

  static const green = Color(0xFF22C55E);
  static const greenDark = Color(0xFF15803D);
  static const greenBg = Color(0xFFF0FDF4);

  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFB259);
  static const orangeDark = Color(0xFFEA580C);
  static const orangeText = Color(0xFF7C2D12);

  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const red = Color(0xFFEF4444);
}

/// Shorthand helper: squircle border radius with standard 0.6 smoothing.
SmoothBorderRadius squircleRadius(double radius) => SmoothBorderRadius.all(
      SmoothRadius(cornerRadius: radius, cornerSmoothing: 0.6),
    );

/// Shorthand helper: squircle border radius only on specific corners.
SmoothBorderRadius squircleRadiusOnly({
  double topLeft = 0,
  double topRight = 0,
  double bottomLeft = 0,
  double bottomRight = 0,
}) =>
    SmoothBorderRadius.only(
      topLeft: SmoothRadius(cornerRadius: topLeft, cornerSmoothing: 0.6),
      topRight: SmoothRadius(cornerRadius: topRight, cornerSmoothing: 0.6),
      bottomLeft: SmoothRadius(cornerRadius: bottomLeft, cornerSmoothing: 0.6),
      bottomRight: SmoothRadius(cornerRadius: bottomRight, cornerSmoothing: 0.6),
    );

/// Global ThemeData for ClassPulse.
ThemeData buildAppTheme(TextTheme base) => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.kanitTextTheme(base),
      cardTheme: CardThemeData(
        shape: SmoothRectangleBorder(borderRadius: squircleRadius(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 24, cornerSmoothing: 0.6),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: SmoothRectangleBorder(borderRadius: squircleRadius(12)),
        ),
      ),
    );
