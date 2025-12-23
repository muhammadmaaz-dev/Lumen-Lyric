import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:musicapp/pages/home_screen.dart';
import 'package:musicapp/pages/LibraryScreen/device_local_media.dart';
import 'package:musicapp/pages/music_screen.dart';
import 'package:musicapp/pages/setting_screen.dart';

// 1. Define the provider to hold the selected index (starts at 0)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Watch the theme provider
    final themeMode = ref.watch(themeProvider);
    final isDarkTheme = themeMode == ThemeMode.dark;

    // 3. Watch the navigation index provider
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    // Define colors based on theme
    final bottomNavColor = isDarkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255);
    final selectedColor = isDarkTheme ? Colors.white : Colors.black;
    // Handle null safety for grey colors
    final unselectedColor = isDarkTheme ? Colors.grey[600]! : Colors.grey[400]!;
    final barColor = isDarkTheme
        ? const Color.fromARGB(255, 155, 155, 155)
        : const Color.fromARGB(255, 117, 117, 117);

    // List of Screens
    const List<Widget> screens = [
      HomeScreen(),
      LibraryScreen(),
      MusicScreen(),
      SettingScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex, // Uses the value from Riverpod
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: barColor)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: selectedColor,
            unselectedItemColor:
                unselectedColor, // Added explicitly for better style control
            backgroundColor: bottomNavColor,
            currentIndex: selectedIndex, // Uses the value from Riverpod
            showSelectedLabels: false,
            showUnselectedLabels: false,

            // 4. Update the provider on tap
            onTap: (index) {
              ref.read(bottomNavIndexProvider.notifier).state = index;
            },

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                activeIcon: Icon(Icons.home_filled),
                label:
                    "Home", // Good practice to have labels for accessibility, even if hidden
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: "Library",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note_outlined),
                activeIcon: Icon(Icons.music_note),
                label: "Music",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_2_outlined),
                activeIcon: Icon(Icons.person_2_rounded),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
