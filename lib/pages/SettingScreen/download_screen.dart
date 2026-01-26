import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/pages/full_player.dart';
import 'package:musicapp/widgets/bottom_sheet_lib.dart' show SongOptionsWidget;
import 'package:musicapp/widgets/custom_text_field.dart';
import 'package:musicapp/widgets/song_tile.dart';
import 'package:on_audio_query/on_audio_query.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  double get _playerMinHeight => 62.h;
  final TextEditingController _searchController = TextEditingController();
  final MiniplayerController _miniplayerController = MiniplayerController();
  final controller = AudioController.instance;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ensure songs are loaded
    if (controller.songs.value.isEmpty) {
      controller.loadSongs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter downloaded songs based on search query
  List<LocalSongModel> _getFilteredDownloadedSongs(
    List<LocalSongModel> allSongs,
  ) {
    // First filter only downloaded songs
    final downloadedSongs = allSongs
        .where((song) => song.isDownloaded)
        .toList();

    // Then filter by search query if not empty
    if (_searchQuery.isEmpty) {
      return downloadedSongs;
    }

    final query = _searchQuery.toLowerCase();
    return downloadedSongs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,

      body: Stack(
        children: [
          Column(
            children: [
              // Custom App Bar
              _buildAppBar(textColor, backgroundColor),

              // Songs List
              Expanded(
                child: ValueListenableBuilder<List<LocalSongModel>>(
                  valueListenable: controller.songs,
                  builder: (context, allSongs, _) {
                    final downloadedSongs = _getFilteredDownloadedSongs(
                      allSongs,
                    );

                    // Empty state
                    if (downloadedSongs.isEmpty) {
                      return _buildEmptyState(textColor, isDarkTheme);
                    }

                    // Songs list
                    return CustomScrollView(
                      slivers: [
                        // Search bar section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15.w),
                            child: Column(
                              children: [
                                SizedBox(height: 14.h),
                                // Search Bar
                                CustomTextField(
                                  hintText: 'Search downloads',
                                  prefixIcon: Icons.search,
                                  onPrefixTap: () {},
                                  isDarkTheme: isDarkTheme,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                                SizedBox(height: 14.h),
                                // Songs count row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.download_done,
                                          color: Colors.green,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 7.w),
                                        Text(
                                          '${downloadedSongs.length} Downloads',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Play all button
                                    if (downloadedSongs.isNotEmpty)
                                      _buildPlayAllButton(
                                        allSongs,
                                        downloadedSongs,
                                        isDarkTheme,
                                      ),
                                  ],
                                ),
                                SizedBox(height: 18.h),
                              ],
                            ),
                          ),
                        ),

                        ValueListenableBuilder<int>(
                          valueListenable:
                              AudioController.instance.currentIndex,
                          builder: (context, currentIndex, _) {
                            return ValueListenableBuilder<List<LocalSongModel>>(
                              valueListenable: AudioController.instance.songs,
                              builder: (context, allSongs, _) {
                                return // Songs List
                                SliverPadding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 15.w,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final song = downloadedSongs[index];
                                      final isPlaying =
                                          song.id ==
                                          AudioController
                                              .instance
                                              .currentsong
                                              ?.id;

                                      return SongTile(
                                        key: ValueKey(song.id),
                                        title: song.title,
                                        artist: song.artist,
                                        duration: song.duration,
                                        songId: song.id,
                                        isPlaying: isPlaying,
                                        imageUrl: song.artworkUrl,
                                        onTap: () {
                                          // Play from downloaded songs queue only
                                          controller.playFromPlaylist(
                                            downloadedSongs,
                                            index,
                                          );
                                        },
                                        onMenuTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                SongOptionsWidget(
                                                  songId: song.id,
                                                  title: song.title,
                                                  artist: song.artist,
                                                  filePath: song.uri,
                                                  imageUrl: song.artworkUrl,
                                                ),
                                          );
                                        },
                                        isDarkTheme: isDarkTheme,
                                      );
                                    }, childCount: downloadedSongs.length),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // Extra space at bottom for MiniPlayer
                        SliverToBoxAdapter(child: SizedBox(height: 88.h)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Mini Player with Miniplayer package
          ValueListenableBuilder<int>(
            valueListenable: controller.currentIndex,
            builder: (context, currentIndex, child) {
              if (currentIndex == -1) {
                return const SizedBox.shrink();
              }

              return Miniplayer(
                controller: _miniplayerController,
                minHeight: _playerMinHeight,
                maxHeight: MediaQuery.of(context).size.height,
                elevation: 8,
                curve: Curves.easeOutQuart,
                onDismiss: () {
                  controller.audioPlayer.stop();
                  controller.currentIndex.value = -1;
                  controller.isPlaying.value = false;
                  // ✅ 1. Clear queue FIRST (Resets flags like _isPlayingFromQueue)
                  controller.clearQueue();

                  // ✅ 2. Then update index (Triggers UI rebuild with correct state)
                  controller.currentIndex.value = -1;
                },
                builder: (height, percentage) {
                  final song = controller.currentsong;
                  if (song == null) return const SizedBox.shrink();

                  // Show full player when expanded
                  if (percentage > 0.2) {
                    return FullPlayer(
                      miniplayerController: _miniplayerController,
                    );
                  }

                  // Mini player UI when collapsed
                  return _buildMiniPlayerContent(
                    song: song,
                    isDarkTheme: isDarkTheme,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayerContent({
    required LocalSongModel song,
    required bool isDarkTheme,
  }) {
    final miniPlayerBgColor = isDarkTheme
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final miniPlayerTextColor = isDarkTheme ? Colors.white : Colors.black;
    final miniPlayerSubTextColor = isDarkTheme
        ? Colors.white70
        : Colors.black54;
    final miniPlayerIconColor = isDarkTheme ? Colors.white : Colors.black;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _miniplayerController.animateToHeight(state: PanelState.MAX);
      },
      child: Container(
        height: _playerMinHeight,
        decoration: BoxDecoration(
          color: miniPlayerBgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: _buildMiniPlayerArtwork(
                          song,
                          miniPlayerTextColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Title & Artist
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
                            song.artist,
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
                    // Play/Pause Button
                    ValueListenableBuilder<bool>(
                      valueListenable: controller.isPlaying,
                      builder: (context, isPlaying, _) {
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

  /// Build the custom app bar with back button and title
  Widget _buildAppBar(Color textColor, Color backgroundColor) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 7.h),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Back button on left
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Title in center
            Text(
              'Downloads',
              style: TextStyle(
                color: textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(Color textColor, bool isDarkTheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 106.w,
              height: 106.h,
              decoration: BoxDecoration(
                color: isDarkTheme
                    ? const Color(0xff1a1a1a)
                    : const Color(0xffe5e7eb),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_outlined,
                size: 53.sp,
                color: isDarkTheme ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            SizedBox(height: 21.h),
            Text(
              _searchQuery.isEmpty ? 'No Downloads Yet' : 'No Results Found',
              style: TextStyle(
                color: textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              _searchQuery.isEmpty
                  ? 'Downloaded songs will appear here.\nGo to Music screen to download songs.'
                  : 'Try searching with different keywords.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12.sp,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build play all button
  Widget _buildPlayAllButton(
    List<LocalSongModel> allSongs,
    List<LocalSongModel> downloadedSongs,
    bool isDarkTheme,
  ) {
    return GestureDetector(
      onTap: () {
        if (downloadedSongs.isNotEmpty) {
          // Play from downloaded songs queue starting from first song
          controller.playFromPlaylist(downloadedSongs, 0);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff4CAF50), Color(0xff66BB6A)],
          ),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 18.sp),
            SizedBox(width: 3.w),
            Text(
              'Play All',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerArtwork(
    LocalSongModel song,
    Color miniPlayerTextColor,
  ) {
    // 1. Check if artworkUrl exists (for downloaded songs)
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      return Image.network(
        song.artworkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local artwork if network fails
          return QueryArtworkWidget(
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
          );
        },
      );
    }

    // 2. Fallback to local artwork
    return QueryArtworkWidget(
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
    );
  }
}
