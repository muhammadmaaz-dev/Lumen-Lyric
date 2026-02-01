import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme
  static final ThemeData lighttheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color.fromRGBO(243, 244, 246, 1),
    fontFamily: 'SNPro',
    useMaterial3: true,
    primaryColor: const Color.fromARGB(255, 0, 0, 0),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(243, 244, 246, 1),
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
    ),

    // Card Theme
    cardColor: const Color(0xFFE8E8E8),
    cardTheme: CardThemeData(
      color: const Color(0xFFE8E8E8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: Colors.black87),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      headlineMedium: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      headlineSmall: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      titleLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      titleMedium: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
        fontFamily: 'SNPro',
      ),
      titleSmall: TextStyle(color: Colors.black87, fontFamily: 'SNPro'),
      bodyLarge: TextStyle(color: Colors.black87, fontFamily: 'SNPro'),
      bodyMedium: TextStyle(color: Colors.black54, fontFamily: 'SNPro'),
      bodySmall: TextStyle(color: Colors.black45, fontFamily: 'SNPro'),
      labelLarge: TextStyle(color: Colors.black87, fontFamily: 'SNPro'),
      labelMedium: TextStyle(color: Colors.black54, fontFamily: 'SNPro'),
      labelSmall: TextStyle(color: Colors.black45, fontFamily: 'SNPro'),
    ),

    // Divider Theme
    dividerColor: Colors.black12,
    dividerTheme: const DividerThemeData(color: Colors.black12),

    // Hint Color
    hintColor: Colors.black38,

    // Disabled Color
    disabledColor: Colors.grey,

    // Tab Bar Theme
    tabBarTheme: const TabBarThemeData(
      labelColor: Color.fromARGB(255, 0, 0, 0),
      unselectedLabelColor: Colors.grey,
      indicatorColor: Color.fromARGB(255, 0, 0, 0),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE8E8E8),
      labelStyle: const TextStyle(color: Colors.black87, fontFamily: 'SNPro'),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Snackbar Theme
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF323232),
      contentTextStyle: TextStyle(color: Colors.white, fontFamily: 'SNPro'),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color.fromARGB(255, 0, 0, 0),
    ),
  );

  // Dark Theme
  static final ThemeData darktheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darktheme,
    fontFamily: 'SNPro',
    useMaterial3: true,
    primaryColor: Colors.white,

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
    ),

    // Card Theme
    cardColor: const Color(0xFF1A1A1A),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: Colors.white),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontFamily: 'SNPro',
      ),
      titleMedium: TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        fontFamily: 'SNPro',
      ),
      titleSmall: TextStyle(color: Colors.white70, fontFamily: 'SNPro'),
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'SNPro'),
      bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'SNPro'),
      bodySmall: TextStyle(color: Colors.white60, fontFamily: 'SNPro'),
      labelLarge: TextStyle(color: Colors.white, fontFamily: 'SNPro'),
      labelMedium: TextStyle(color: Colors.white70, fontFamily: 'SNPro'),
      labelSmall: TextStyle(color: Colors.white60, fontFamily: 'SNPro'),
    ),

    // Divider Theme
    dividerColor: Colors.white12,
    dividerTheme: const DividerThemeData(color: Colors.white12),

    // Hint Color
    hintColor: Colors.white38,

    // Disabled Color
    disabledColor: Colors.grey,

    // Tab Bar Theme
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.white,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'SNPro'),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Snackbar Theme
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF323232),
      contentTextStyle: TextStyle(color: Colors.white, fontFamily: 'SNPro'),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.white,
    ),
  );
}
