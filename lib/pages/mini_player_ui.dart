import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';

// Isay hum sirf UI dikhane ke liye use karenge
class MiniPlayerUI extends ConsumerWidget {
  final double height;
  const MiniPlayerUI({super.key, required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = AudioController.instance;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white : Colors.black;
    final progressBgColor = isDark ? Colors.white12 : Colors.black12;
    final progressColor = isDark ? Colors.white : Colors.black;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: containerColor,
        // Top corners rounded
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10.r),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  // ********** Song Thumbnail **********
                  ValueListenableBuilder(
                    valueListenable: controller.currentIndex,
                    builder: (context, index, _) {
                      final song = controller.currentsong;
                      if (song == null) return const SizedBox();
                      return Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            artworkHeight: 50,
                            artworkWidth: 50,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: Icon(
                              Icons.music_note,
                              color: iconColor,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(width: 12.w),

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
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13.sp,
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
                                  color: iconColor,
                                  size: 40.sp,
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
                minHeight: 1.8.h,
                backgroundColor: progressBgColor,
                color: progressColor,
              );
            },
          ),
        ],
      ),
    );
  }
}
