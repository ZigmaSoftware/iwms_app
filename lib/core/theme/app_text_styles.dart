import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final String _fontFamily =
      GoogleFonts.roboto().fontFamily ?? 'Roboto';

  static final TextStyle titleLarge = GoogleFonts.roboto(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static final TextStyle bodyMedium = GoogleFonts.roboto(
    fontSize: 12.0,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static final TextStyle labelLarge = GoogleFonts.montserrat(
    fontWeight: FontWeight.w600,
    fontSize: 12.0,
    color: AppColors.white,
    letterSpacing: 0.2,
  );

  static final TextStyle heading2 = GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static final TextStyle subTitle = GoogleFonts.montserrat(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static String get fontFamily => _fontFamily;
}
