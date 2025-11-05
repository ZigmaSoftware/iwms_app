import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final String _fontFamily = GoogleFonts.poppins().fontFamily ?? 'Poppins';

  static final TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 16.0,
    color: AppColors.textPrimary,
  );

  static final TextStyle labelLarge = GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontSize: 16.0, 
    color: AppColors.white,
  );

  static final TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle subTitle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static String get fontFamily => _fontFamily;
}