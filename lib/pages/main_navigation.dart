import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:musicapp/pages/home_screen.dart';
import 'package:musicapp/pages/library_screen.dart';
import 'package:musicapp/pages/music_screen.dart';
import 'package:musicapp/pages/setting_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

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
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final selectedColor = isDarkTheme ? Colors.white : Colors.black;
    final unselectedColor = isDarkTheme ? Colors.grey[600] : Colors.grey[400];

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  index: 0,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor!,
                ),
                _buildNavItem(
                  icon: Icons.folder_outlined,
                  selectedIcon: Icons.folder,
                  index: 1,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                ),
                _buildNavItem(
                  icon: Icons.music_note_outlined,
                  selectedIcon: Icons.music_note,
                  index: 2,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  index: 3,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required int index,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? selectedColor : unselectedColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}
