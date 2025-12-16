import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';

class FullPlayer extends StatefulWidget {
  const FullPlayer({super.key});

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      if (_sheetController.size > 0.2 && !isExpanded) {
        setState(() => isExpanded = true);
      } else if (_sheetController.size <= 0.2 && isExpanded) {
        setState(() => isExpanded = false);
      }
    });
  }

  void toggleSheet() {
    if (isExpanded) {
      _sheetController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _sheetController.animateTo(
        0.7,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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

    final thumbColor = isDarkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255);
    final trackColors = isDarkTheme ? Colors.white : Colors.black;
    final playpause = isDarkTheme ? Colors.white : Colors.black;
    final playpauseicon = isDarkTheme ? Colors.black : Colors.white;
    final containerColor = isDarkTheme
        ? const Color.fromARGB(225, 0, 0, 0)
        : const Color.fromARGB(226, 255, 255, 255);
    final placeholderColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];
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
              fontSize: 25,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: iconColor,
              size: 35,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            // MAIN PLAYER CONTENT
            Positioned.fill(
              child: ValueListenableBuilder<int>(
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

                      const SizedBox(height: 30),

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
                              style: TextStyle(
                                fontSize: 13,
                                color: subTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ********** PROGRESS BAR **********
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: StreamBuilder<Duration>(
                          stream: controller.audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration =
                                controller.audioPlayer.duration ??
                                Duration.zero;

                            double max = duration.inSeconds.toDouble();
                            if (max < 1) max = 1;
                            double value = position.inSeconds.toDouble();
                            if (value > max) value = max;

                            return Column(
                              children: [
                                SizedBox(
                                  height: 20,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: trackColors,
                                      inactiveTrackColor: sliderInactiveColor,
                                      thumbColor: thumbColor,
                                      overlayShape:
                                          SliderComponentShape.noOverlay,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 10,
                                      ),
                                      trackHeight: 9,
                                    ),
                                    child: Slider(
                                      value: value,
                                      max: max,
                                      onChanged: (v) {
                                        controller.audioPlayer.seek(
                                          Duration(
                                            milliseconds: (v * 1000).round(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _format(position),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      _format(duration),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 15,
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
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded),
                              iconSize: 36,
                              color: iconColor,
                              onPressed: controller.previousSong,
                            ),
                            const SizedBox(width: 25),
                            ValueListenableBuilder<bool>(
                              valueListenable: controller.isPlaying,
                              builder: (context, isPlaying, _) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: playpause,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: playpauseicon,
                                    ),
                                    iconSize: 36,
                                    onPressed: controller.tooglePlayPause,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 30),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded),
                              iconSize: 36,
                              color: iconColor,
                              onPressed: controller.nextSong,
                            ),
                          ],
                        ),
                      ),

                      // Space for the lyrics sheet
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),

            // ********** DRAGGABLE LYRICS SHEET **********
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.1,
              minChildSize: 0.1,
              maxChildSize: 0.8,
              builder: (BuildContext context, ScrollController scrollController) {
                return ClipRRect(
                  // 1. Shape ko Clip karna zaroori hai taake blur bahar na nikle
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    // 2. Asli Blur Effect yahan hai
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        // 3. Color ko thoda transparent rakhna (0.5 to 0.7 opacity best hai)
                        // Agar 'containerColor' solid hai to .withOpacity use karo,
                        // ya direct Colors.black.withOpacity(0.6) use karo.
                        color: (containerColor ?? Colors.black).withOpacity(
                          0.6,
                        ),

                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        // Glass effect ko enhance karne ke liye halka sa border
                        border: Border(
                          top: BorderSide(
                            color: isDarkTheme
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            // --- Header (Lyrics Title + Arrow Button) ---
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.music_note_outlined,
                                        color: subTextColor,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Lyrics",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Arrow Button
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDarkTheme
                                            ? Colors.white.withOpacity(
                                                0.1,
                                              ) // Button bg bhi thoda glass type
                                            : Colors.black.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_down
                                            : Icons.keyboard_arrow_up,
                                        color: textColor,
                                        size: 30,
                                      ),
                                    ),
                                    onPressed: toggleSheet,
                                  ),
                                ],
                              ),
                            ),

                            // --- Lyrics Content ---
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ValueListenableBuilder<String>(
                                valueListenable:
                                    AudioController.instance.currentLyrics,
                                builder: (context, lyrics, child) {
                                  return Text(
                                    lyrics, // Yahan ab dynamic lyrics ayenge
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "Metropolis",
                                      height: 1.5,
                                      color: textColor,
                                    ),
                                    textAlign: TextAlign
                                        .center, // Lyrics center mein ache lagte hain
                                  );
                                },
                              ),
                            ),
                            // Extra space bottom
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
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
