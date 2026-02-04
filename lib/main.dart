//flutter install -d <device-id>

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
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/services/storage_path_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. Lock Orientation to Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ 2. Load SharedPreferences (fast, already cached by OS)
  final prefs = await SharedPreferences.getInstance();

  // ✅ 3. Get the saved theme immediately (Sync)
  final savedThemeString = prefs.getString('theme_mode');
  final initialTheme = ThemeMode.values.firstWhere(
    (e) => e.toString() == savedThemeString,
    orElse: () => ThemeMode.light,
  );

  // ✅ 4. Initialize audio background service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ 5. FAST STARTUP - LOAD FROM CACHE INSTANTLY
  // ═══════════════════════════════════════════════════════════════════════════
  // Load songs from cache for instant UI display.
  // This is O(1) and does not depend on song count.
  debugPrint('⚡ [STARTUP] Loading songs from cache...');
  final hasCachedSongs = await AudioController.instance.loadSongsFromCache();
  if (hasCachedSongs) {
    debugPrint('⚡ [STARTUP] Cache loaded - UI ready instantly');
  } else {
    debugPrint('⚡ [STARTUP] No cache - will load in background');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ 6. SHOW UI IMMEDIATELY - DON'T WAIT FOR HEAVY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        themeModeProvider.overrideWith((ref) => initialTheme),
      ],
      child: const MyApp(),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ 7. BACKGROUND INITIALIZATION (after UI is shown)
  // ═══════════════════════════════════════════════════════════════════════════
  // Run heavy operations in background after UI is displayed.
  // This ensures app launch time is constant regardless of song count.
  _initializeInBackground();
}

/// Run heavy initialization tasks in background after UI is shown
Future<void> _initializeInBackground() async {
  // Small delay to let UI render first
  await Future.delayed(const Duration(milliseconds: 100));

  debugPrint('🔄 [BACKGROUND] Starting background initialization...');

  // 1. Initialize storage paths and run migration
  final storagePaths = StoragePathService.instance;
  await storagePaths.initialize();
  final migrationResult = await storagePaths.migrateLegacyFiles();
  if (migrationResult.hasChanges) {
    debugPrint(
      '✅ [BACKGROUND] Migration: ${migrationResult.movedMp3s} MP3s moved',
    );
  }

  // 2. Initialize download controller (includes database sync)
  await DownloadController.instance.init();

  // 3. Run full MediaStore scan in background
  // This updates the song list and refreshes the cache
  AudioController.instance.loadSongsInBackground();

  debugPrint('🔄 [BACKGROUND] Background initialization complete');
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
