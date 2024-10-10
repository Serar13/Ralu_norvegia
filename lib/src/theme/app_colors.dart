import 'package:flutter/material.dart';

class AppColors {
  // Primary color (used for the main elements, such as navigation bars, buttons, and headers)
  static const primary = Color(0xFFADD8E6); // Light Blue (Primary, 60%)

  // Secondary color (used for backgrounds and large surfaces)
  static const secondary = Color(0xFFFFFFFF); // White (Secondary, 30%)

  // Accent color (used sparingly for call-to-action buttons, links, and highlights)
  static const accent = Color(0xFFFF4500); // Orange Red (Accent, 10%)
  static const accent2 = Color(0xFFe18178); // Orange Red (Accent, 10%)
  static const accent3 = Color(0xFF72c0b3); // Orange Red (Accent, 10%)

  // Text Colors
  static const primaryText = secondary;
  static const primaryText2 = Color(0xFFB0BEC5);
  static const secondaryText = primary;

  // Background Colors
  static const primaryBackground = primary; // Using secondary color (white) as the primary background
  static const secondaryBackground = secondary; // Light Steel Blue for less prominent background elements

  // Additional Accents and Warnings
  static const accentDark = Color(0xFF23767B); // Teal for darker accents (optional)
  static const warning = Color(0xFFCE522C); // Strong warning color
}
