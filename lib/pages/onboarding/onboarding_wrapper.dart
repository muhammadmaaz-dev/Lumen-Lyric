import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/pages/onboarding/welcome_screen.dart';
import 'package:musicapp/pages/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to check if onboarding is complete
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});

class OnboardingWrapper extends ConsumerWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    return onboardingComplete.when(
      data: (isComplete) {
        if (isComplete) {
          return const MainNavigation();
        } else {
          return const WelcomeScreen();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => const WelcomeScreen(),
    );
  }
}
