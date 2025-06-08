import 'package:flutter/material.dart';

class TColor {
  // Primary Colors (ShadCN)
  static const Color primaryColor1 = Color(0xFF92A3FD);
  static const Color primaryColor2 = Color(0xFF9DCEFF);

  // Secondary Colors (ShadCN)
  static const Color secondaryColor1 = Color(0xFFC58BF2);
  static const Color secondaryColor2 = Color(0xFFEEA4CE);

  static List<Color> get primaryG => [primaryColor2, primaryColor1];
  static List<Color> get secondaryG => [secondaryColor2, secondaryColor1];

  // Base Colors
  static const Color black = Colors.black;
  static const Color gray = Color(0xFF786F72);
  static const Color white = Colors.white;
  static const Color lightGray = Color(0xFFF7F8F8);

  // Dark mode colors (ShadCN)
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkGray = Color(0xFF1D1617);
  static const Color darkWhite = Color(0xFFE0E0E0);

  // Accent Colors (Keep or match to ShadCN chart colors if desired)
  static Color accentCoral = const Color(0xFFFF7F50); // Coral
  static Color accentYellow = const Color(0xFFFFD700); // Soft Yellow

  // Semantic Colors (Optional: customize to match ShadCN destructive/muted)
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);

  // Theme state variables
  static Color cardColor = white;
  static Color textColor = const Color(0xFF1D1617);
  static Color subTextColor = const Color(0xFF786F72);
  static Color bgColor = white;

  static void toggleDarkMode(bool isDark) {
    if (isDark) {
      bgColor = darkBackground;
      cardColor = darkSurface;
      textColor = darkWhite;
      subTextColor = const Color.fromARGB(255, 240, 203, 209);
    } else {
      bgColor = white;
      cardColor = white;
      textColor = black;
      subTextColor = gray;
    }
  }

  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkSubText = Color(0xFFB0B0B0);
  static const Color darkPrimary = Color(0xFF7B8CDE);
  static const Color darkSecondary = Color(0xFFA78BC9);
  static const Color darkAccent = Color(0xFFD49AB8);
}
