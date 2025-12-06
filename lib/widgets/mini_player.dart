// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';
import 'package:musicapp/controller/audio_controller.dart';

class MiniPlayer extends StatelessWidget {
  // final bool isDarkTheme;

  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkTheme = themeCubit.isDarkMode;
    final controller = AudioController.instance;

    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);

    return ValueListenableBuilder(
      valueListenable: controller.currentIndex,
      builder: (context, index, _) {
        final song = controller.currentsong;

        if (song == null) {
          return SizedBox.shrink(); // mini player hidden when no song selected
        }

        return Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Song Thumbnail
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.music_note, color: Colors.white),
                      ),

                      const SizedBox(width: 10),

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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.white),
                        iconSize: 32,
                        onPressed: controller.previousSong,
                      ),

                      // Play / Pause Button
                      ValueListenableBuilder(
                        valueListenable: controller.isPlaying,
                        builder: (context, isPlaying, _) {
                          return IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: controller.tooglePlayPause,
                          );
                        },
                      ),

                      IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.white),
                        iconSize: 32,
                        onPressed: controller.nextSong,
                      ),
                    ],
                  ),
                ),
              ),
              //progressbar
              StreamBuilder<Duration>(
                stream: controller.audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration =
                      controller.audioPlayer.duration ?? Duration.zero;

                  final progress = duration.inMilliseconds == 0
                      ? 0.0
                      : position.inMilliseconds / duration.inMilliseconds;

                  return LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white12,
                    color: Colors.white,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
