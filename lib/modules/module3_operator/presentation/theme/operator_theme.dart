import 'package:flutter/material.dart';
import 'package:iwms_citizen_app/core/constants.dart';
import 'package:iwms_citizen_app/core/theme/app_colors.dart';

/// Shared color + spacing tokens reused across the revamped operator UI.
class OperatorTheme {
  static const Color primary = kPrimaryColor;
  static const Color primaryAccent = AppColors.primaryVariant;
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color accentLight = AppColors.accentLight;
  static const Color mutedText = AppColors.textSecondary;
  static const Color strongText = AppColors.textPrimary;
  static const Color cardBorder = Color(0x1A1B5E20);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(18));

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primary, primaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient quickActionGradient = LinearGradient(
    colors: [Color(0xFF2E7D5A), Color(0xFF5DB075)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
}
