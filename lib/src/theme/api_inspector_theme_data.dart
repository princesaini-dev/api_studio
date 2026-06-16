import 'package:flutter/material.dart';
import 'app_colors.dart';

class ApiInspectorThemeData {
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color borderColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final double borderRadius;
  final bool isDark;

  const ApiInspectorThemeData({
    this.primaryColor = AppColors.primary,
    this.backgroundColor = AppColors.backgroundLight,
    this.surfaceColor = AppColors.surfaceLight,
    this.cardColor = AppColors.cardLight,
    this.borderColor = AppColors.borderLight,
    this.successColor = AppColors.success,
    this.errorColor = AppColors.error,
    this.warningColor = AppColors.warning,
    this.textPrimaryColor = AppColors.textPrimaryLight,
    this.textSecondaryColor = AppColors.textSecondaryLight,
    this.borderRadius = 12.0,
    this.isDark = false,
  });

  factory ApiInspectorThemeData.dark() {
    return const ApiInspectorThemeData(
      backgroundColor: AppColors.backgroundDark,
      surfaceColor: AppColors.surfaceDark,
      cardColor: AppColors.cardDark,
      borderColor: AppColors.borderDark,
      textPrimaryColor: AppColors.textPrimaryDark,
      textSecondaryColor: AppColors.textSecondaryDark,
      isDark: true,
    );
  }

  factory ApiInspectorThemeData.fromBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? ApiInspectorThemeData.dark()
        : const ApiInspectorThemeData();
  }

  ApiInspectorThemeData copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? cardColor,
    Color? borderColor,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    double? borderRadius,
    bool? isDark,
  }) {
    return ApiInspectorThemeData(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardColor: cardColor ?? this.cardColor,
      borderColor: borderColor ?? this.borderColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      borderRadius: borderRadius ?? this.borderRadius,
      isDark: isDark ?? this.isDark,
    );
  }
}
