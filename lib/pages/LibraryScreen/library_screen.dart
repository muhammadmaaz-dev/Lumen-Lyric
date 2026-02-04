import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/widgets/bottom_sheet_lib.dart' show SongOptionsWidget;
import 'package:musicapp/widgets/custom_text_field.dart';
import 'package:musicapp/widgets/filter_button.dart';
import 'package:musicapp/widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter Logic
  List<LocalSongModel> _getFilteredSongs(List<LocalSongModel> allSongs) {
    List<LocalSongModel> filteredSongs = allSongs;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          // ---------------------------------------------------------
          // 1. FIXED SEARCH BAR ONLY (Ye Scroll Nahi Hoga)
          // ---------------------------------------------------------
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 14.h),
                  CustomTextField(
                    controller: _searchController,
                    hintText: 'Search songs...',
                    prefixIcon: Icons.search,
                    isDarkTheme: isDarkTheme,
                    suffixIcon: _searchQuery.isNotEmpty ? Icons.close : null,
                    onSuffixTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      FocusScope.of(context).unfocus();
                    },
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 10.h), // Thora gap search bar ke neeche
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 2. SCROLLABLE AREA (Filter Buttons + List)
          // ---------------------------------------------------------
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: AudioController.instance.currentIndex,
              builder: (context, currentIndex, _) {
                return ValueListenableBuilder<List<LocalSongModel>>(
                  valueListenable: AudioController.instance.songs,
                  builder: (context, allSongs, _) {
                    final displaySongs = _getFilteredSongs(allSongs);

                    return CustomScrollView(
                      slivers: [
                        // ✅ Filter Row (Ab ye ScrollView ka hissa hai, isliye scroll hoga)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            child: Row(
                              children: [
                                FilterButton(
                                  text: 'Local Media',
                                  isActive: true,
                                  onTap: () {},
                                  isDarkTheme: isDarkTheme,
                                ),
                                const Spacer(),
                                Text(
                                  '${displaySongs.length} Songs',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // List Empty Check
                        if (displaySongs.isEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              height: 200.h,
                              alignment: Alignment.center,
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No results for "$_searchQuery"'
                                    : "No Songs Found",
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final song = displaySongs[index];
                                final isPlaying =
                                    song.id ==
                                    AudioController.instance.currentsong?.id;

                                return SongTile(
                                  key: ValueKey(song.id),
                                  title: song.title,
                                  artist: song.artist,
                                  duration: song.duration,
                                  songId: song.id,
                                  imageUrl: song.artworkUrl,
                                  isDarkTheme: isDarkTheme,
                                  isPlaying: isPlaying,
                                  onTap: () {
                                    final originalIndex = allSongs.indexOf(
                                      song,
                                    );
                                    AudioController.instance.playSong(
                                      originalIndex,
                                    );
                                    FocusScope.of(context).unfocus();
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
                                        imageUrl: song.artworkUrl,
                                      ),
                                    );
                                    FocusScope.of(context).unfocus();
                                  },
                                );
                              }, childCount: displaySongs.length),
                            ),
                          ),

                        // Extra space for MiniPlayer
                        SliverToBoxAdapter(child: SizedBox(height: 72.h)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
