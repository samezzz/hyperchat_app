import 'package:flutter/material.dart';

class AppTheme {
  static ColorScheme get lighAppThemeScheme => const ColorScheme(
    primary: Color(0xff92A3FD),
    onPrimary: Colors.white,
    secondary: Color(0xffC58BF2),
    onSecondary: Colors.white,
    background: Colors.white,
    onBackground: Color(0xff1D1617),
    surface: Colors.white,
    onSurface: Color(0xff1D1617),
    error: Color(0xFFE53935),
    onError: Colors.white,
    brightness: Brightness.light,
  );

  static ColorScheme get darkColorScheme => const ColorScheme(
    primary: Color(0xff92A3FD),
    onPrimary: Colors.white,
    secondary: Color(0xffC58BF2),
    onSecondary: Colors.white,
    background: Color(0xff121212),
    onBackground: Color(0xffE0E0E0),
    surface: Color(0xff1E1E1E),
    onSurface: Color(0xffE0E0E0),
    error: Color(0xFFE53935),
    onError: Colors.white,
    brightness: Brightness.dark,
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: lighAppThemeScheme,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xff1D1617),
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xff1D1617),
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xff1D1617),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xff1D1617),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xff1D1617),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xff1D1617),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xffE0E0E0),
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xffE0E0E0),
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xffE0E0E0),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xffE0E0E0),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xffE0E0E0),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xffE0E0E0),
      ),
    ),
  );

  // Helper methods to get colors from the current theme
  static Color primaryColor(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color secondaryColor(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color backgroundColor(BuildContext context) => Theme.of(context).colorScheme.background;
  static Color surfaceColor(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color texAppTheme(BuildContext context) => Theme.of(context).colorScheme.onBackground;
  static Color subTexAppTheme(BuildContext context) => Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
} 