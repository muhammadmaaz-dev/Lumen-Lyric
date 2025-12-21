import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:musicapp/pages/home_screen.dart';
import 'package:musicapp/pages/LibraryScreen/device_local_media.dart';
import 'package:musicapp/pages/music_screen.dart';
import 'package:musicapp/pages/setting_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    MusicScreen(),
    SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkTheme = themeMode == ThemeMode.dark;

    final bottomNavColor = isDarkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255);
    final selectedColor = isDarkTheme ? Colors.white : Colors.black;
    final unselectedColor = isDarkTheme ? Colors.grey[600] : Colors.grey[400];
    final barColor = isDarkTheme
        ? const Color.fromARGB(255, 155, 155, 155)
        : const Color.fromARGB(255, 117, 117, 117);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: barColor)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: selectedColor,
          backgroundColor: bottomNavColor,
          currentIndex: _selectedIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,

          onTap: (i) => setState(() {
            _selectedIndex = i;
          }),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home_filled),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note_outlined),
              activeIcon: Icon(Icons.music_note),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined),
              activeIcon: Icon(Icons.person_2_rounded),
              label: "",
            ),
          ],
        ),
      ),

      // body: _screens[_currentIndex],
      // bottomNavigationBar: Container(
      //   decoration: BoxDecoration(
      //     color: bottomNavColor,
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black.withOpacity(0.1),
      //         blurRadius: 10,
      //         offset: const Offset(0, -2),
      //       ),
      //     ],
      //   ),
      //   child: SafeArea(
      //     child: Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           _buildNavItem(
      //             icon: Icons.home_outlined,
      //             selectedIcon: Icons.home,
      //             index: 0,
      //             selectedColor: selectedColor,
      //             unselectedColor: unselectedColor!,
      //           ),
      //           _buildNavItem(
      //             icon: Icons.folder_outlined,
      //             selectedIcon: Icons.folder,
      //             index: 1,
      //             selectedColor: selectedColor,
      //             unselectedColor: unselectedColor,
      //           ),
      //           _buildNavItem(
      //             icon: Icons.music_note_outlined,
      //             selectedIcon: Icons.music_note,
      //             index: 2,
      //             selectedColor: selectedColor,
      //             unselectedColor: unselectedColor,
      //           ),
      //           _buildNavItem(
      //             icon: Icons.person_outline,
      //             selectedIcon: Icons.person,
      //             index: 3,
      //             selectedColor: selectedColor,
      //             unselectedColor: unselectedColor,
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}
