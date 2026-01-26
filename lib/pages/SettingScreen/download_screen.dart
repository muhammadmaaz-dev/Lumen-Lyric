import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/widgets/song_tile.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: BackButton(color: textColor),
        title: Text(
          "Downloads",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder<List<LocalSongModel>>(
        valueListenable: AudioController.instance.songs,
        builder: (context, allSongs, child) {
          // Filter logic: Sirf downloaded songs
          final downloadedSongs = allSongs
              .where((s) => s.isDownloaded)
              .toList();

          if (downloadedSongs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 60, color: Colors.grey),
                  SizedBox(height: 10.h),
                  Text(
                    "No downloads yet",
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: downloadedSongs.length,
            itemBuilder: (context, index) {
              final song = downloadedSongs[index];
              return SongTile(
                title: song.title,
                artist: song.artist,
                duration: song.duration,
                songId: song.id,
                isDarkTheme: isDarkTheme,
                onTap: () {
                  final mainIndex = allSongs.indexOf(song);
                  AudioController.instance.playSong(mainIndex);
                },
                onMenuTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
