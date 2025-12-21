import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';

// Isay hum sirf UI dikhane ke liye use karenge
class MiniPlayerUI extends ConsumerWidget {
  final double height;
  const MiniPlayerUI({super.key, required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = AudioController.instance;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        // Top corners rounded
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
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
                  // ********** Song Thumbnail **********
                  ValueListenableBuilder(
                    valueListenable: controller.currentIndex,
                    builder: (context, index, _) {
                      final song = controller.currentsong;
                      if (song == null) return const SizedBox();
                      return Container(
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
                            nullArtworkWidget: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 12),

                  // ********** Title & Artist **********
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: controller.currentIndex,
                      builder: (context, index, _) {
                        final song = controller.currentsong;
                        if (song == null) return const SizedBox();
                        return Column(
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
                        );
                      },
                    ),
                  ),

                  // ********** Play/Pause Button (With Animation) **********
                  ValueListenableBuilder(
                    valueListenable: controller.isPlaying,
                    builder: (context, isPlaying, _) {
                      return IconButton(
                        icon:
                            Icon(
                                  isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  key: ValueKey(isPlaying),
                                  color: Colors.white,
                                  size: 40,
                                )
                                .animate(key: ValueKey(isPlaying))
                                .fadeIn(duration: 300.ms)
                                .scale(
                                  duration: 400.ms,
                                  begin: const Offset(0.5, 0.5),
                                  end: const Offset(1.0, 1.0),
                                  curve: Curves.elasticOut, // BOUNCE EFFECT
                                ),
                        onPressed: controller.tooglePlayPause,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ********** Progress Bar (Bottom Line) **********
          StreamBuilder<Duration>(
            stream: controller.audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = controller.audioPlayer.duration ?? Duration.zero;

              double progress = 0.0;
              if (duration.inMilliseconds > 0) {
                progress = position.inMilliseconds / duration.inMilliseconds;
              }
              // Prevent overflow
              if (progress > 1.0) progress = 1.0;

              return LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.white12,
                color: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }
}
