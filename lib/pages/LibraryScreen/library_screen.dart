import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:musicapp/controller/audio_controller.dart';

import 'package:musicapp/models/local_song_model.dart';

import 'package:musicapp/widgets/bottom_bar.dart' show SongOptionsWidget;

import 'package:musicapp/widgets/custom_text_field.dart';

import 'package:musicapp/widgets/filter_button.dart';

import 'package:musicapp/widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // State Variable

  String _searchQuery = '';

  // Filter Logic

  List<LocalSongModel> _getFilteredSongs(List<LocalSongModel> allSongs) {
    List<LocalSongModel> filteredSongs = allSongs;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredSongs = filteredSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query);
      }).toList();
    }

    return filteredSongs;
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
    debugPrint('🔄 LibraryScreen rebuilt');

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);

    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,

      body: Stack(
        children: [
          // CustomScrollView with proper sliver structure
          CustomScrollView(
            slivers: [
              // Header Section (Search + Filters)
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 14.h),

                        // Search Bar
                        CustomTextField(
                          hintText: 'Search songs...',
                          prefixIcon: Icons.search,
                          onPrefixTap: () {},
                          isDarkTheme: isDarkTheme,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),

                        SizedBox(height: 21.h),

                        // Filter Buttons Row
                        Row(
                          children: [
                            FilterButton(
                              text: 'Local Media',
                              isActive: true,
                              onTap: () {},
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
                                    fontSize: 15,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Songs List - Now properly placed as a direct sliver child
              ValueListenableBuilder(
                valueListenable: AudioController.instance.songs,
                builder: (context, allSongs, _) {
                  final displaySongs = _getFilteredSongs(allSongs);

                  // Empty state
                  if (displaySongs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.music_off,
                              size: 48,
                              color: isDarkTheme
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No results for "$_searchQuery"'
                                  : "No $allSongs Songs Found",
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Songs list
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final song = displaySongs[index];

                        return SongTile(
                          title: song.title,
                          artist: song.artist,
                          duration: song.duration,
                          songId: song.id,
                          onTap: () {
                            final originalIndex = allSongs.indexOf(song);
                            AudioController.instance.playSong(originalIndex);
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
                      }, childCount: displaySongs.length),
                    ),
                  );
                },
              ),

              // Extra space at bottom for MiniPlayer
              SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ],
      ),
    );
  }
}
