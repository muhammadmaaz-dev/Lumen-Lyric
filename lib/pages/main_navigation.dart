import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/pages/full_player.dart';
import 'package:musicapp/pages/home_screen.dart';
import 'package:musicapp/pages/LibraryScreen/library_screen.dart';
import 'package:musicapp/pages/music_screen.dart';
import 'package:musicapp/pages/SettingScreen/setting_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  double get _playerMinHeight => 62.h;
  int _selectedIndex = 0;
  double _playerPercentage = 0;
  final controller = AudioController.instance;
  final MiniplayerController _playerController = MiniplayerController();

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    MusicScreen(),
    SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 MainNavigation rebuilt');

    // Use Theme.of(context) instead of watching provider
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final bottomNavColor = isDarkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255);
    final selectedColor = isDarkTheme ? Colors.white : Colors.black;
    final barColor = isDarkTheme
        ? const Color.fromARGB(255, 155, 155, 155)
        : const Color.fromARGB(255, 117, 117, 117);
    final miniPlayerBgColor = isDarkTheme
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final miniPlayerTextColor = isDarkTheme ? Colors.white : Colors.black;
    final miniPlayerSubTextColor = isDarkTheme
        ? Colors.white70
        : Colors.black54;
    final miniPlayerIconColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      body: Stack(
        children: [
          // Main screens - using ValueListenableBuilder for proper reactivity
          ValueListenableBuilder<int>(
            valueListenable: controller.currentIndex,
            builder: (context, currentIndex, child) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: currentIndex != -1 ? _playerMinHeight : 0,
                ),
                child: IndexedStack(index: _selectedIndex, children: _screens),
              );
            },
          ),

          // Miniplayer - Only show when a song is selected
          ValueListenableBuilder<int>(
            valueListenable: controller.currentIndex,
            builder: (context, currentIndex, child) {
              // Don't show miniplayer if no song is selected
              if (currentIndex == -1) {
                return const SizedBox.shrink();
              }

              return Miniplayer(
                controller: _playerController,
                minHeight: _playerMinHeight,
                maxHeight: MediaQuery.of(context).size.height,
                elevation: 8,
                curve: Curves.easeOutQuart,
                onDismiss: () {
                  // Stop playback and hide miniplayer when dragged down
                  controller.audioPlayer.stop();
                  controller.currentIndex.value = -1;
                  controller.isPlaying.value = false;
                },
                builder: (height, percentage) {
                  // Update percentage state for hiding bottom nav
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_playerPercentage != percentage) {
                      setState(() => _playerPercentage = percentage);
                    }
                  });

                  final song = controller.currentsong;
                  if (song == null) return const SizedBox.shrink();

                  // Show full player when expanded (percentage > 0.2)
                  if (percentage > 0.2) {
                    return FullPlayer(miniplayerController: _playerController);
                  }

                  // Mini player UI when collapsed
                  return _buildMiniPlayerContent(
                    song: song,
                    isDarkTheme: isDarkTheme,
                    miniPlayerBgColor: miniPlayerBgColor,
                    miniPlayerTextColor: miniPlayerTextColor,
                    miniPlayerSubTextColor: miniPlayerSubTextColor,
                    miniPlayerIconColor: miniPlayerIconColor,
                  );
                },
              );
            },
          ),
        ],
      ),
      // Hide bottom nav bar when full player is shown
      bottomNavigationBar: _playerPercentage > 0.2
          ? null
          : Container(
              height: 60.h,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: barColor)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
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
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_filled),
                      label: "Home",
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

  Widget _buildMiniPlayerContent({
    required dynamic song,
    required bool isDarkTheme,
    required Color miniPlayerBgColor,
    required Color miniPlayerTextColor,
    required Color miniPlayerSubTextColor,
    required Color miniPlayerIconColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _playerController.animateToHeight(state: PanelState.MAX);
      },
      child: Container(
        height: _playerMinHeight,
        decoration: BoxDecoration(
          color: miniPlayerBgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 9.r,
              offset: Offset(0, -2.h),
            ),
          ],
          // borderRadius: const BorderRadius.only(
          //   topLeft: Radius.circular(18),
          //   topRight: Radius.circular(18),
          // ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 11.w),
                child: Row(
                  children: [
                    // Song Thumbnail
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.r),
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkHeight: 44.h,
                          artworkWidth: 44.w,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Icon(
                            Icons.music_note,
                            color: miniPlayerTextColor,
                            size: 26.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 11.w),

                    // Song Title + Artist
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: miniPlayerTextColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            song.artist ?? "Unknown",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: miniPlayerSubTextColor,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Previous Button
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous,
                        color: miniPlayerIconColor,
                      ),
                      onPressed: controller.previousSong,
                    ),

                    // Play/Pause Button - Using ValueListenableBuilder for reactivity
                    ValueListenableBuilder<bool>(
                      valueListenable: controller.isPlaying,
                      builder: (context, isPlaying, child) {
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: miniPlayerIconColor,
                          ),
                          onPressed: controller.tooglePlayPause,
                        );
                      },
                    ),

                    // Next Button
                    IconButton(
                      icon: Icon(Icons.skip_next, color: miniPlayerIconColor),
                      onPressed: controller.nextSong,
                    ),
                  ],
                ),
              ),
            ),

            // Progress Bar
            StreamBuilder<Duration>(
              stream: controller.audioPlayer.positionStream,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration?>(
                  stream: controller.audioPlayer.durationStream,
                  builder: (context, durationSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration =
                        durationSnapshot.data ?? const Duration(seconds: 1);
                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;

                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: isDarkTheme
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkTheme ? Colors.white : Colors.black,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
