import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:musicapp/core/configs/theme/app_theme.dart';
import 'package:musicapp/pages/onboarding/onboarding_wrapper.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:musicapp/controller/download_controller.dart';
import 'package:musicapp/controller/audio_controller.dart'; // ✅ Audio controller for centralized song loading

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. Lock Orientation to Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ 2. Load SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // ✅ 3. Initialize Download Controller (includes metadata database sync)
  await DownloadController.instance.init();

  // ✅ 4. Get the saved theme immediately (Sync)
  final savedThemeString = prefs.getString('theme_mode');
  final initialTheme = ThemeMode.values.firstWhere(
    (e) => e.toString() == savedThemeString,
    orElse: () => ThemeMode.light,
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ 5. CENTRAL SONG LOADING - COLD START METADATA RESOLUTION
  // ═══════════════════════════════════════════════════════════════════════════
  // Load songs ONCE at startup after all services are initialized.
  // This ensures ID3 tags are read reliably before any screen displays them.
  // The loadSongs() method handles cold start stabilization internally.
  debugPrint('🎵 [STARTUP] Beginning centralized song loading...');
  await AudioController.instance.loadSongs();
  debugPrint('🎵 [STARTUP] Centralized song loading complete');

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
