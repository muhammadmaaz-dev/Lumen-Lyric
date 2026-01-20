import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lighttheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lighttheme,
    fontFamily: 'Metropolis',
    useMaterial3: true,
  );

  static final ThemeData darktheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darktheme,
    fontFamily: 'Metropolis',
    useMaterial3: true,
  );
}
