import 'package:flutter/material.dart';

class TColor {
  // Primary Colors (ShadCN)
  static Color get primaryColor1 =>
      const Color.fromARGB(255, 255, 158, 55); // oklch(0.606 0.25 292.717)
  static Color get primaryColor2 =>
      const Color(0xFFF8F5FF); // oklch(0.969 0.016 293.756)

  // Secondary Colors (ShadCN)
  static Color get secondaryColor1 =>
      const Color(0xFFF7F7F7); // oklch(0.967 0.001 286.375)
  static Color get secondaryColor2 =>
      const Color(0xFFC8C6D6); // oklch(0.21 0.006 285.885)

  static List<Color> get primaryG => [primaryColor2, primaryColor1];
  static List<Color> get secondaryG => [secondaryColor2, secondaryColor1];

  // Base Colors
  static Color get black =>
      const Color(0xFF1F1B24); // oklch(0.141 0.005 285.823)
  static Color get gray => const Color(0xFFC8C6D6); // same as secondaryColor2
  static Color get white => const Color(0xFFFFFFFF); // oklch(1 0 0)
  static Color get lightGray =>
      const Color(0xFFF7F7F7); // oklch(0.967 0.001 286.375)

  // Dark mode colors (ShadCN)
  static Color get darkBackground =>
      const Color(0xFF1F1B24); // oklch(0.141 0.005 285.823)
  static Color get darkSurface =>
      const Color(0xFF3A3941); // oklch(0.21 0.006 285.885)
  static Color get darkGray =>
      const Color(0xFFB3B0BD); // oklch(0.705 0.015 286.067)
  static Color get darkWhite => const Color(0xFFF7F7F7); // oklch(0.985 0 0)

  // Accent Colors (Keep or match to ShadCN chart colors if desired)
  static Color accentCoral = const Color(0xFFFF7F50); // Coral
  static Color accentYellow = const Color(0xFFFFD700); // Soft Yellow

  // Semantic Colors (Optional: customize to match ShadCN destructive/muted)
  static Color success = const Color(0xFF4CAF50);
  static Color warning = const Color(0xFFFFC107);
  static Color error = const Color(0xFFE53935);
  static Color info = const Color(0xFF2196F3);

  // Theme state variables
  static Color cardColor = white;
  static Color textColor = black;
  static Color subTextColor = gray;
  static Color bgColor = white;

  static void toggleDarkMode(bool isDark) {
    if (isDark) {
      bgColor = darkBackground;
      cardColor = darkSurface;
      textColor = darkWhite;
      subTextColor = darkGray;
    } else {
      bgColor = white;
      cardColor = white;
      textColor = black;
      subTextColor = gray;
    }
  }
}
