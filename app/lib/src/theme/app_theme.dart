import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

ThemeData getApplicationTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.primaryBackground,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent3,
      background: AppColors.primaryBackground,
      surface: AppColors.secondaryBackground,
      onPrimary: AppColors.secondaryText,
      onSecondary: AppColors.secondaryText,
      onBackground: AppColors.primaryText,
      onSurface: AppColors.primaryText,
    ),
    fontFamily: 'Kanit',

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.secondaryBackground,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.primaryText2,
      type: BottomNavigationBarType.fixed,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.accent,
      iconTheme: IconThemeData(color: AppColors.accent),
      titleTextStyle: TextStyle(
        fontFamily: 'Kanit',
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: AppColors.accent,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    textTheme: TextTheme(
      titleMedium: _getTextStyle(
        fontSize: 20,
        color: AppColors.secondaryText,
      ),
      titleSmall: _getTextStyle(
        fontSize: 18,
        color: AppColors.secondaryText,
      ),
      headlineSmall: _getTextStyle(fontSize: 15, color: AppColors.primaryText),
      bodyLarge: _getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
      ),
      bodyMedium: _getTextStyle(
        fontSize: 14,
        color: AppColors.secondaryText,
      ),
      bodySmall: _getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
      ),
    ),
  );
}

TextStyle _getTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  required Color color,
}) {
  return GoogleFonts.kanit(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}