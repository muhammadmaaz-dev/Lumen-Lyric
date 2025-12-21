import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:musicapp/provider/theme_provider.dart';

import 'package:musicapp/controller/audio_controller.dart';

import 'package:musicapp/models/local_song_model.dart';

import 'package:musicapp/widgets/bottom_bar.dart' show SongOptionsWidget;

import 'package:musicapp/widgets/custom_text_field.dart';

import 'package:musicapp/widgets/filter_button.dart';

import 'package:musicapp/widgets/mini_player.dart';

import 'package:musicapp/widgets/song_tile.dart';

import 'package:flutter_animate/flutter_animate.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // State Variable

  String _selectedFilter = 'Local Media';

  // Filter Logic

  List<LocalSongModel> _getFilteredSongs(List<LocalSongModel> allSongs) {
    if (_selectedFilter == 'Liked') {
      return allSongs.where((s) => s.isLiked == true).toList();
    } else if (_selectedFilter == 'Downloaded') {
      return allSongs.where((s) => s.isDownloaded == true).toList();
    }

    return allSongs;
  }

  @override
  void initState() {
    super.initState();

    if (AudioController.instance.songs.value.isEmpty) {
      AudioController.instance.loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    final isDarkTheme = themeMode == ThemeMode.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);

    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,

      body: Stack(
        children: [
          // Change 1: SingleChildScrollView wapis lagaya taake sab scroll ho
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const SizedBox(height: 16),

                    // Search Bar (Ab ye bhi scroll karega)
                    CustomTextField(
                      hintText: 'Search',

                      prefixIcon: Icons.search,

                      onPrefixTap: () {},

                      isDarkTheme: isDarkTheme,
                    ),

                    const SizedBox(height: 24),

                    // Filter Buttons Row
                    Row(
                      children: [
                        FilterButton(
                          text: 'Downloaded',

                          isActive: _selectedFilter == 'Downloaded',

                          onTap: () {
                            setState(() {
                              _selectedFilter = "Downloaded";
                            });
                          },

                          isDarkTheme: isDarkTheme,
                        ),

                        const SizedBox(width: 12),

                        FilterButton(
                          text: 'Liked',

                          isActive: _selectedFilter == 'Liked',

                          onTap: () {
                            setState(() {
                              _selectedFilter = "Liked";
                            });
                          },

                          isDarkTheme: isDarkTheme,
                        ),

                        const SizedBox(width: 12),

                        FilterButton(
                          text: 'Local Media',

                          isActive: _selectedFilter == 'Local Media',

                          onTap: () {
                            setState(() {
                              _selectedFilter = "Local Media";
                            });
                          },

                          isDarkTheme: isDarkTheme,
                        ),

                        const Spacer(),

                        ValueListenableBuilder(
                          valueListenable: AudioController.instance.songs,

                          builder: (context, songs, child) {
                            final filteredCount = _getFilteredSongs(
                              songs,
                            ).length;

                            return Text(
                              '$filteredCount Songs',

                              style: TextStyle(
                                color: textColor,

                                fontWeight: FontWeight.w500,

                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Change 2: Expanded hata diya, direct ValueListenableBuilder
                    ValueListenableBuilder(
                      valueListenable: AudioController.instance.songs,

                      builder: (context, allSongs, _) {
                        final displaySongs = _getFilteredSongs(allSongs);

                        if (displaySongs.isEmpty) {
                          // Height deni paregi taake empty msg dikhe

                          return SizedBox(
                            height: 100,

                            child: Center(
                              child: Text(
                                "No $_selectedFilter Songs Found",

                                style: TextStyle(color: textColor),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          // Change 3: ShrinkWrap aur Physics zaroori hain
                          shrinkWrap: true,

                          physics: const NeverScrollableScrollPhysics(),

                          itemCount: displaySongs.length,

                          itemBuilder: (context, index) {
                            final song = displaySongs[index];

                            return SongTile(
                              title: song.title,

                              artist: song.artist,

                              songId: song.id,

                              onTap: () {
                                final originalIndex = allSongs.indexOf(song);

                                AudioController.instance.playSong(
                                  originalIndex,
                                );
                              },

                              onMenuTap: () {
                                showModalBottomSheet(
                                  context: context,

                                  isScrollControlled: true,

                                  backgroundColor: Colors.transparent,

                                  builder: (context) => SongOptionsWidget(
                                    songId: song.id,

                                    title: song.title,

                                    artist: song.artist,

                                    filePath: song.uri,
                                  ),
                                );
                              },

                              isDarkTheme: isDarkTheme,
                            );
                          },
                        );
                      },
                    ),

                    // Extra space taake last song MiniPlayer ke peeche na chupe
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // MiniPlayer Fixed rahega bottom par
          Positioned(
            left: 0,

            right: 0,

            bottom: 3,

            child: ValueListenableBuilder(
              valueListenable: AudioController.instance.songs,

              builder: (context, songs, child) {
                // Agar songs nahi hain to kuch mat dikhao (SizedBox)

                if (songs.isEmpty) return const SizedBox.shrink();

                return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),

                      child: MiniPlayer(),
                    )
                    .animate() // <--- Yahan se magic shuru
                    .slideY(
                      begin: 1.0, // Neeche se start hoga

                      end: 0.0, // Apni jagah par aayega

                      duration: 600.ms, // Duration

                      curve: Curves
                          .easeOutBack, // <--- YE HAI SECRET (Thora sa bounce karega)
                    )
                    .fadeIn(duration: 400.ms) // Sath mein fade in bhi hoga
                    .shimmer(
                      delay: 400.ms,

                      duration: 1500.ms,
                    ); // <--- Bonus: Ek chamak (shine) aayegi player par
              },
            ),
          ),
        ],
      ),
    );
  }
}
