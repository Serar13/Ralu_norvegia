import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

ThemeData getApplicationTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.primaryBackground,
    primarySwatch: Colors.blue,
    fontFamily: 'Kanit',

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.secondaryBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.primaryText,
      type: BottomNavigationBarType.fixed,
    ),

    // app bar theme
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: Colors.white),
      color: Colors.deepPurpleAccent,
      foregroundColor: Colors.black,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0f1528),
        statusBarIconBrightness: Brightness.light,
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