import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/playlist_model.dart';
import 'package:musicapp/pages/SettingScreen/playlist_detail_screen.dart';
import 'package:musicapp/pages/full_player.dart';
import 'package:musicapp/provider/playlist_provider.dart';
import 'package:musicapp/widgets/playlist_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  static const double _playerMinHeight = 70;
  final controller = AudioController.instance;
  final MiniplayerController _miniplayerController = MiniplayerController();

  Future<void> _createPlaylist() async {
    final name = await PlaylistDialog.show(context: context);
    if (name != null && name.isNotEmpty) {
      await ref.read(playlistProvider.notifier).createPlaylist(name);
    }
  }

  void _openPlaylistDetail(PlaylistModel playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlistId: playlist.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistProvider);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xfff0f0f0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Playlists',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: textColor),
            onPressed: _createPlaylist,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          playlists.isEmpty
              ? _buildEmptyState(textColor)
              : _buildPlaylistGrid(playlists, cardColor, textColor),

          // Mini Player with Miniplayer package
          ValueListenableBuilder<int>(
            valueListenable: controller.currentIndex,
            builder: (context, currentIndex, child) {
              if (currentIndex == -1) {
                return const SizedBox.shrink();
              }

              final song = controller.currentsong;
              if (song == null) return const SizedBox.shrink();

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
                  controller.clearQueue();
                },
                builder: (height, percentage) {
                  // Show full player when expanded (percentage > 0.2)
                  if (percentage > 0.2) {
                    return FullPlayer(
                      miniplayerController: _miniplayerController,
                    );
                  }

                  // Collapsed mini player content
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

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 80,
            color: textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Playlists Yet',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first playlist',
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 80), // Space for miniplayer
        ],
      ),
    );
  }

  Widget _buildPlaylistGrid(
    List<PlaylistModel> playlists,
    Color cardColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: playlists.length,
        padding: const EdgeInsets.only(bottom: 80), // Space for miniplayer
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _buildPlaylistCard(playlist, cardColor, textColor);
        },
      ),
    );
  }

  Widget _buildPlaylistCard(
    PlaylistModel playlist,
    Color cardColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () => _openPlaylistDetail(playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card with icon
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.queue_music_rounded,
                  size: 48,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Playlist name
          Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayerContent({
    required dynamic song,
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
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: QueryArtworkWidget(
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
}
