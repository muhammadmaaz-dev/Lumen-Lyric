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

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

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

  await AudioController.instance.loadSongsFromCache();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        themeModeProvider.overrideWith((ref) => initialTheme),
      ],
      child: const MyApp(),
    ),
  );

  _initializeInBackground();
}

Future<void> _initializeInBackground() async {
  await Future.delayed(const Duration(milliseconds: 100));

  final storagePaths = StoragePathService.instance;
  await storagePaths.initialize();
  await storagePaths.migrateLegacyFiles();

  await DownloadController.instance.init();

  AudioController.instance.loadSongsInBackground();
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
