import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/models/playlist_model.dart';
import 'package:musicapp/pages/full_player.dart';
// Ensure this path matches where you saved the previous file
import 'package:musicapp/pages/SettingScreen/song_picker_screen.dart';
import 'package:musicapp/provider/playlist_provider.dart';
import 'package:musicapp/widgets/playlist_dialog.dart';
import 'package:musicapp/widgets/song_tile.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  double get _playerMinHeight => 62.h;
  final controller = AudioController.instance;
  final MiniplayerController _miniplayerController = MiniplayerController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editPlaylistName(PlaylistModel playlist) async {
    final newName = await PlaylistDialog.show(
      context: context,
      initialName: playlist.name,
      isEditing: true,
    );
    if (newName != null && newName.isNotEmpty && newName != playlist.name) {
      await ref
          .read(playlistProvider.notifier)
          .updatePlaylistName(widget.playlistId, newName);
    }
  }

  Future<void> _deletePlaylist(PlaylistModel playlist) async {
    final confirmed = await DeletePlaylistDialog.show(
      context: context,
      playlistName: playlist.name,
    );
    if (confirmed) {
      await ref
          .read(playlistProvider.notifier)
          .deletePlaylist(widget.playlistId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // UPDATED: Now calls the static show method for the Bottom Sheet
  Future<void> _addSongs() async {
    // This calls the static method we created in the previous step
    // which handles the showCupertinoModalBottomSheet logic
    final selectedSongIds = await SongPickerScreen.show(
      context,
      widget.playlistId,
    );

    if (selectedSongIds != null && selectedSongIds.isNotEmpty) {
      await ref
          .read(playlistProvider.notifier)
          .addSongsToPlaylist(widget.playlistId, selectedSongIds);
    }
  }

  Future<void> _removeSong(int songId) async {
    await ref
        .read(playlistProvider.notifier)
        .removeSongFromPlaylist(widget.playlistId, songId);
  }

  List<LocalSongModel> _getPlaylistSongs(PlaylistModel playlist) {
    final allSongs = controller.songs.value;
    final playlistSongs = <LocalSongModel>[];

    for (final songId in playlist.songIds) {
      final song = allSongs.firstWhere(
        (s) => s.id == songId,
        orElse: () => LocalSongModel(
          id: songId,
          title: 'Unknown Song',
          artist: 'Unknown Artist',
          uri: '',
          albumArt: '',
          duration: 0,
        ),
      );
      if (song.uri.isNotEmpty) {
        playlistSongs.add(song);
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      return playlistSongs.where((song) {
        return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            song.artist.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return playlistSongs;
  }

  void _playSong(LocalSongModel song, List<LocalSongModel> playlistSongs) {
    // Find the song index within the playlist
    final index = playlistSongs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      // Play from playlist queue - only playlist songs will play in sequence
      controller.playFromPlaylist(playlistSongs, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlist = ref.watch(playlistByIdProvider(widget.playlistId));
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    if (playlist == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Playlist not found',
            style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xfff0f0f0);
    final iconColor = isDarkTheme ? Colors.white70 : Colors.black54;

    final playlistSongs = _getPlaylistSongs(playlist);

    return Scaffold(
      backgroundColor: backgroundColor,

      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 44.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: textColor,
                            size: 26.sp,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Playlist',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22.sp,
                          ),
                        ),

                        IconButton(
                          icon: Icon(Icons.search, color: textColor),
                          onPressed: () {
                            showSearch(
                              context: context,
                              delegate: _PlaylistSongSearchDelegate(
                                playlistSongs: _getPlaylistSongs(playlist),
                                isDarkTheme: isDarkTheme,
                                onSongTap: (song) =>
                                    _playSong(song, playlistSongs),
                                onRemoveSong: _removeSong,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          // Playlist thumbnail
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.queue_music_rounded,
                                size: 40,
                                color: iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Playlist info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${playlist.songCount} Songs',
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Action buttons
                                Row(
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.delete_outline,
                                      onTap: () => _deletePlaylist(playlist),
                                      isDarkTheme: isDarkTheme,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildActionButton(
                                      icon: Icons.edit_outlined,
                                      onTap: () => _editPlaylistName(playlist),
                                      isDarkTheme: isDarkTheme,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildActionButton(
                                      icon: Icons.add,
                                      onTap: _addSongs,
                                      isDarkTheme: isDarkTheme,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Songs List
              if (playlistSongs.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 48,
                          color: iconColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No songs in this playlist',
                          style: TextStyle(color: iconColor, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _addSongs,
                          icon: Icon(Icons.add, color: textColor),
                          label: Text(
                            'Add Songs',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = playlistSongs[index];

                      // ✅ 1. Wrap in ValueListenableBuilder to listen for song changes
                      return ValueListenableBuilder<int>(
                        valueListenable: controller.currentIndex,
                        builder: (context, currentIndex, _) {
                          final isPlaying =
                              song.id == controller.currentsong?.id;

                          return SongTile(
                            title: song.title,
                            artist: song.artist,
                            duration: song.duration,
                            songId: song.id,
                            isDarkTheme: isDarkTheme,
                            isPlaying: isPlaying,
                            imageUrl: song.artworkUrl,
                            onTap: () => _playSong(song, playlistSongs),
                            // ✅ NEW: Pass menu items here directly
                            menuItems: [
                              PopupMenuItem<String>(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                      color: Colors.red[400],
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Remove from playlist'),
                                  ],
                                ),
                              ),
                            ],
                            // ✅ NEW: Handle selection here
                            onMenuItemSelected: (value) {
                              if (value == 'remove') {
                                _removeSong(song.id);
                              }
                            },
                          );
                        },
                      );
                    }, childCount: playlistSongs.length),
                  ),
                ),

              // Bottom padding for miniplayer
              SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                  // Stop playback and hide miniplayer when dragged down
                  controller.closePlayer();
                },
                builder: (height, percentage) {
                  final song = controller.currentsong;
                  if (song == null) return const SizedBox.shrink();

                  // Show full player when expanded (percentage > 0.2)
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildMiniPlayerArtwork(
                          song,
                          miniPlayerTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: miniPlayerSubTextColor,
                              fontSize: 13,
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

  Widget _buildMiniPlayerArtwork(
    LocalSongModel song,
    Color miniPlayerTextColor,
  ) {
    // 1. Check if artworkUrl exists (for downloaded songs)
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      final artworkPath = song.artworkUrl!;

      // Check if it's a local file or network URL
      if (artworkPath.startsWith('http://') ||
          artworkPath.startsWith('https://')) {
        return Image.network(
          artworkPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultArtwork(song, miniPlayerTextColor);
          },
        );
      } else {
        // Local file path
        final file = File(artworkPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultArtwork(song, miniPlayerTextColor);
            },
          );
        }
      }
    }

    // 2. Fallback to local artwork
    return _buildDefaultArtwork(song, miniPlayerTextColor);
  }

  Widget _buildDefaultArtwork(LocalSongModel song, Color miniPlayerTextColor) {
    return QueryArtworkWidget(
      id: song.id,
      type: ArtworkType.AUDIO,
      artworkHeight: 50,
      artworkWidth: 50,
      artworkFit: BoxFit.cover,
      nullArtworkWidget: Icon(
        Icons.music_note,
        color: miniPlayerTextColor,
        size: 30,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

// Search delegate for searching songs within playlist
class _PlaylistSongSearchDelegate extends SearchDelegate<LocalSongModel?> {
  final List<LocalSongModel> playlistSongs;
  final bool isDarkTheme;
  final Function(LocalSongModel) onSongTap;
  final Function(int) onRemoveSong;

  _PlaylistSongSearchDelegate({
    required this.playlistSongs,
    required this.isDarkTheme,
    required this.onSongTap,
    required this.onRemoveSong,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDarkTheme ? Colors.grey : Colors.grey[600],
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = playlistSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase());
    }).toList();

    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

    return Container(
      color: isDarkTheme ? Colors.black : Colors.white,
      child: ListView.builder(
        itemCount: results.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final song = results[index];
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDarkTheme
                    ? const Color(0xff2a2a2a)
                    : const Color(0xfff0f0f0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Icon(
                    Icons.music_note,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ),
            title: Text(song.title, style: TextStyle(color: textColor)),
            subtitle: Text(
              song.artist,
              style: TextStyle(color: secondaryTextColor),
            ),
            onTap: () {
              close(context, song);
              onSongTap(song);
            },
          );
        },
      ),
    );
  }
}
