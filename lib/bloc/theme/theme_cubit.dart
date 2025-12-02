import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'theme_state.dart';

class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeInitial());

  void toggleTheme() {
    final newThemeMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    emit(ThemeChanged(newThemeMode));
  }

  void setTheme(ThemeMode themeMode) {
    emit(ThemeChanged(themeMode));
  }

  bool get isDarkMode => state.themeMode == ThemeMode.dark;

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final themeModeString = json['themeMode'] as String?;
      if (themeModeString == null) return const ThemeInitial();

      final themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.light,
      );

      return ThemeChanged(themeMode);
    } catch (_) {
      return const ThemeInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return {'themeMode': state.themeMode.toString()};
  }
}
