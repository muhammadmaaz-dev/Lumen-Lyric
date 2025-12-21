import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_animate/flutter_animate.dart'; // <--- IMPORT THIS

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

        if (song == null) return const SizedBox.shrink();

        // **** SLIDE UP ANIMATION FOR PLAYER ENTRANCE ****

        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -12) {
              _openFullPlayer(context);
            }

            if (details.primaryDelta! > 12) {
              controller.audioPlayer.stop();

              controller.currentIndex.value = -1;
            }
          },

          onTap: () => _openFullPlayer(context),

          child:
              Container(
                    height: 75,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),

                          blurRadius: 10,
                        ),
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

                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

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

                                // ********** Previous Button **********
                                IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous,

                                        color: Colors.white,
                                      ),

                                      iconSize: 32,

                                      onPressed: controller.previousSong,
                                    )
                                    // Button Entrance Animation
                                    .animate()
                                    .scale(delay: 200.ms, duration: 300.ms),

                                // ********** Play / Pause Button (With BOUNCE Effect) **********
                                ValueListenableBuilder(
                                  valueListenable: controller.isPlaying,

                                  builder: (context, isPlaying, _) {
                                    return IconButton(
                                      // Key zaroori hai taake jab icon change ho tab animation trigger ho
                                      icon:
                                          Icon(
                                                isPlaying
                                                    ? Icons.pause_circle
                                                    : Icons.play_circle,

                                                key: ValueKey(isPlaying),

                                                color: Colors.white,

                                                size: 40,
                                              )
                                              .animate(
                                                key: ValueKey(
                                                  isPlaying,
                                                ), // Trigger on state change
                                              )
                                              // 1. Fade in hoga
                                              .fadeIn(duration: 300.ms)
                                              // 2. Chota ho kar bara hoga (Bounce/Pop Effect)
                                              .scale(
                                                duration: 400.ms,

                                                begin: const Offset(
                                                  0.5,

                                                  0.5,
                                                ), // Start size (50%)

                                                end: const Offset(
                                                  1.0,

                                                  1.0,
                                                ), // End size (100%)

                                                curve: Curves
                                                    .elasticOut, // <--- YE HAI BOUNCE LOGIC
                                              )
                                              // 3. Thora sa rotate bhi karega maza ke liye
                                              .rotate(
                                                duration: 400.ms,

                                                begin:
                                                    -0.1, // Thora left se start

                                                end: 0,

                                                curve: Curves.easeOutBack,
                                              ),

                                      onPressed: controller.tooglePlayPause,
                                    );
                                  },
                                ),

                                // ********** Next Button **********
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,

                                    color: Colors.white,
                                  ),

                                  iconSize: 32,

                                  onPressed: controller.nextSong,
                                ).animate().scale(
                                  delay: 200.ms,

                                  duration: 300.ms,
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
                                controller.audioPlayer.duration ??
                                Duration.zero;

                            final progress = duration.inMilliseconds == 0
                                ? 0.0
                                : position.inMilliseconds /
                                      duration.inMilliseconds;

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
                  )
                  // Player slide-in logic (jo pichle step mein lagaya tha)
                  .animate()
                  .slideY(
                    begin: 1.0,

                    end: 0.0,

                    duration: 500.ms,

                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 300.ms),
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
