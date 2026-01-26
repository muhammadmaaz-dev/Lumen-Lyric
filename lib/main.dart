import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:musicapp/core/configs/theme/app_theme.dart';
import 'package:musicapp/pages/onboarding/onboarding_wrapper.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:musicapp/controller/download_controller.dart'; // ✅ Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. Lock Orientation to Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ 2. Load SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // ✅ 3. Initialize Download Controller
  await DownloadController.instance.init();

  // ✅ 4. Get the saved theme immediately (Sync)
  final savedThemeString = prefs.getString('theme_mode');
  final initialTheme = ThemeMode.values.firstWhere(
    (e) => e.toString() == savedThemeString,
    orElse: () => ThemeMode.light,
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        themeModeProvider.overrideWith((ref) => initialTheme),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Music App',
          theme: AppTheme.lighttheme,
          darkTheme: AppTheme.darktheme,
          themeMode: themeMode,
          themeAnimationDuration: Duration.zero,
          home: child,
        );
      },
      child: const OnboardingWrapper(),
    );
  }
}
