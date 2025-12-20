// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/pages/full_player.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkTheme = themeMode == ThemeMode.dark;
    final controller = AudioController.instance;

    return ValueListenableBuilder(
      valueListenable: controller.currentIndex,
      builder: (context, index, _) {
        final song = controller.currentsong;

        // Hide mini player when no song is selected
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          // ********* SWIPE UP / DOWN GESTURES *********
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -12) {
              // Swipe UP → Open Full Player
              _openFullPlayer(context);
            }

            if (details.primaryDelta! > 12) {
              // Swipe DOWN → Stop + Hide Mini Player
              controller.audioPlayer.stop();
              controller.currentIndex.value = -1;
            }
          },

          // ********* TAP → OPEN FULL PLAYER *********
          onTap: () => _openFullPlayer(context),

          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // ********** Song Thumbnail **********
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              artworkHeight: 50,
                              artworkWidth: 50,
                              artworkFit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ********** Song Title + Artist **********
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

                        // ********** Previous **********
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                          ),
                          iconSize: 32,
                          onPressed: controller.previousSong,
                        ),

                        // ********** Play / Pause **********
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

                        // ********** Next **********
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                          ),
                          iconSize: 32,
                          onPressed: controller.nextSong,
                        ),
                      ],
                    ),
                  ),
                ),

                // ********** Progress Bar **********
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
          ),
        );
      },
    );
  }
}

void _openFullPlayer(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, animation, __) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 1),
                end: const Offset(0, 0),
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: const FullPlayer(),
        );
      },
    ),
  );
}
