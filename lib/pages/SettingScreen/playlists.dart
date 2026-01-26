import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/playlist_model.dart';
import 'package:musicapp/pages/SettingScreen/playlist_detail_screen.dart';
import 'package:musicapp/pages/SettingScreen/setting_screen.dart';
import 'package:musicapp/provider/playlist_provider.dart';
import 'package:musicapp/utils/slide_route.dart';
import 'package:musicapp/widgets/playlist_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  double get _playerMinHeight => 62.h;
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
      SlideRightToLeftRoute(
        page: PlaylistDetailScreen(playlistId: playlist.id),
      ), // Apni screen ka naam yahan likhein
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
        : const Color(0xffe5e7eb);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildFakeAppBar(textColor),
          Expanded(
            child: playlists.isEmpty
                ? _buildEmptyState(textColor)
                : _buildPlaylistGrid(playlists, cardColor, textColor),
          ),
        ],
      ),
    );
  }

  // ───────────────── Fake App Bar ─────────────────

  Widget _buildFakeAppBar(Color textColor) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 7.h),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: textColor),
                  onPressed: _createPlaylist,
                ),
              ],
            ),
            Text(
              'Playlists',
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

  // ───────────────── Empty State ─────────────────

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 70.sp,
            color: textColor.withOpacity(0.3),
          ),
          SizedBox(height: 14.h),
          Text(
            'No Playlists Yet',
            style: TextStyle(
              color: textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            'Tap + to create your first playlist',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 70.h),
        ],
      ),
    );
  }

  // ───────────────── Grid ─────────────────

  Widget _buildPlaylistGrid(
    List<PlaylistModel> playlists,
    Color cardColor,
    Color textColor,
  ) {
    return Padding(
      padding: EdgeInsets.all(14.r),
      child: GridView.builder(
        padding: EdgeInsets.only(bottom: 70.h),
        itemCount: playlists.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (_, index) {
          final playlist = playlists[index];
          return GestureDetector(
            onTap: () => _openPlaylistDetail(playlist),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 48.sp,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
