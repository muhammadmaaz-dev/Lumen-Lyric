import 'package:flutter/material.dart';
import 'package:musicapp/core/configs/theme/app_colors.dart';

class AppTheme {
  // Light Theme
  static final lighttheme = ThemeData(
    primaryColor: Color.fromARGB(255, 0, 0, 0),
    fontFamily: 'Metropolis',
    scaffoldBackgroundColor: AppColors.lighttheme,
    brightness: Brightness.light,
  );

  // Dark Theme
  static final darktheme = ThemeData(
    primaryColor: Color.fromARGB(255, 255, 255, 255),
    fontFamily: 'Metropolis',
    scaffoldBackgroundColor: AppColors.darktheme,
    brightness: Brightness.dark,
  );
}
