import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences provider (injected from main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// 🔥 Theme provider — MEMORY ONLY
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});

// 🔥 Async save — never blocks UI
Future<void> saveThemeToPrefs(WidgetRef ref, ThemeMode mode) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString('theme_mode', mode.toString());
}
