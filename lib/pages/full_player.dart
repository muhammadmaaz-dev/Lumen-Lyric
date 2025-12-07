import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';

class FullPlayer extends StatelessWidget {
  const FullPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AudioController.instance;
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkTheme = themeCubit.isDarkMode;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final subTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDarkTheme ? Colors.white : Colors.black;
    final containerColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : Colors.grey[50];
    final placeholderColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];
    final controlBgColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xFFEef2fd);
    final sliderInactiveColor = isDarkTheme
        ? Colors.grey[800]
        : Colors.grey[200];
    final heartBgColor = isDarkTheme ? const Color(0xff1a1a1a) : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        // SWIPE DOWN TO CLOSE
        if (details.primaryDelta! > 12) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Now Playing',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: iconColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_horiz, color: iconColor),
              onPressed: () {},
            ),
          ],
        ),

        body: ValueListenableBuilder<int>(
          valueListenable: controller.currentIndex,
          builder: (context, index, _) {
            final song = controller.currentsong;
            if (song == null) return const SizedBox();

            final title = song.title;
            final artist = song.artist;

            return Column(
              children: [
                const SizedBox(height: 20),

                // ********** ALBUM ART + HEART BUTTON **********
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: placeholderColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              artworkHeight: 300,
                              artworkWidth: 300,
                              artworkFit: BoxFit.cover,
                              nullArtworkWidget: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8E97FD),
                                      Color(0xFFC2E9FB),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: -25,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: heartBgColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ********** TITLE + ARTIST **********
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: TextStyle(fontSize: 16, color: subTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // ********** PROGRESS BAR **********
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: StreamBuilder<Duration>(
                    stream: controller.audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration =
                          controller.audioPlayer.duration ?? Duration.zero;

                      double max = duration.inSeconds.toDouble();
                      if (max < 1) max = 1;
                      double value = position.inSeconds.toDouble();
                      if (value > max) value = max;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF8E97FD),
                              inactiveTrackColor: sliderInactiveColor,
                              thumbColor: Colors.transparent,
                              overlayShape: SliderComponentShape.noOverlay,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 0,
                              ),
                              trackHeight: 9,
                            ),
                            child: Slider(
                              value: value,
                              max: max,
                              onChanged: (v) {
                                controller.audioPlayer.seek(
                                  Duration(seconds: v.toInt()),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Time Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format(position),
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _format(duration),
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 5),

                // ********** CONTROLS **********
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 36,
                        color: iconColor,
                        onPressed: controller.previousSong,
                      ),

                      const SizedBox(width: 30),

                      // Play / Pause
                      ValueListenableBuilder<bool>(
                        valueListenable: controller.isPlaying,
                        builder: (context, isPlaying, _) {
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controlBgColor,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8E97FD,
                                  ).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: iconColor,
                              ),
                              iconSize: 36,
                              onPressed: controller.tooglePlayPause,
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 30),

                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 36,
                        color: iconColor,
                        onPressed: controller.nextSong,
                      ),
                    ],
                  ),
                ),

                // ********** LYRICS SECTION **********
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.music_note_outlined, color: subTextColor),
                          const SizedBox(width: 10),
                          Text(
                            "Lyrics",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: subTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
