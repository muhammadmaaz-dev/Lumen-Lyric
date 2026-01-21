import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicapp/provider/audio_provider.dart';

class FullPlayer extends StatefulWidget {
  final MiniplayerController? miniplayerController;

  const FullPlayer({super.key, this.miniplayerController});

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Is choti si local UI state ke liye 'setState' theek hai
  bool isExpanded = false;
  bool isDragging = false; // Kya user slider ghuma raha hai?
  double? dragValue;

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

  /// Minimize the full player back to mini player
  void _minimizePlayer() {
    if (widget.miniplayerController != null) {
      widget.miniplayerController!.animateToHeight(state: PanelState.MIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 FullPlayer rebuilt');

    final controller =
        AudioController.instance; // Actions perform karne ke liye

    // Song update ke liye current song fetch kar rahe hain
    final song = controller.currentsong;

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // Colors Setup
    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final subTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDarkTheme ? Colors.white : Colors.black;
    final thumbColor = isDarkTheme ? Colors.black : Colors.white;
    final trackColors = isDarkTheme ? Colors.white : Colors.black;
    final playpause = isDarkTheme ? Colors.white : Colors.black;
    final playpauseicon = isDarkTheme ? Colors.black : Colors.white;
    final containerColor = isDarkTheme
        ? const Color.fromARGB(225, 0, 0, 0)
        : const Color.fromARGB(226, 255, 255, 255);
    final placeholderColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];
    final heartBgColor = isDarkTheme ? const Color(0xff1a1a1a) : Colors.white;

    return Scaffold(
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
            fontSize: 22.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: iconColor,
            size: 31.sp,
          ),
          onPressed: _minimizePlayer,
        ),
      ),
      body: Stack(
        children: [
          // MAIN PLAYER CONTENT
          Positioned.fill(
            child: song == null
                ? const SizedBox()
                : Column(
                    children: [
                      SizedBox(height: 18.h),
                      // ********** ALBUM ART **********
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 264.w,
                                height: 264.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26.r),
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
                                  borderRadius: BorderRadius.circular(26.r),
                                  child: QueryArtworkWidget(
                                    id: song.id,
                                    type: ArtworkType.AUDIO,
                                    artworkHeight: 264.h,
                                    artworkWidth: 264.w,
                                    artworkFit: BoxFit.cover,
                                    nullArtworkWidget: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          26.r,
                                        ),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF8E97FD),
                                            Color(0xFFC2E9FB),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.music_note,
                                        size: 70.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -22.h,
                                child: Container(
                                  padding: EdgeInsets.all(10.r),
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
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 25.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 26.h),

                      // ********** TITLE + ARTIST **********
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Text(
                              song.title,
                              style: TextStyle(
                                fontSize: 21.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              song.artist.isEmpty ? "Unknown" : song.artist,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: subTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 22.h),

                      // ********** PROGRESS BAR **********
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 21.w),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final progressAsync = ref.watch(progressProvider);

                            return progressAsync.when(
                              data: (progress) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: 18.h,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: trackColors,
                                          thumbColor: thumbColor,
                                          trackHeight: 8.h,
                                          thumbShape: RoundSliderThumbShape(
                                            enabledThumbRadius: 9.r,
                                          ),
                                          overlayShape:
                                              SliderComponentShape.noOverlay,
                                        ),
                                        child: Slider(
                                          value: isDragging
                                              ? dragValue ?? 0
                                              : progress
                                                    .safeValue, // Ensure this getter exists in your provider
                                          max: progress
                                              .totalSeconds, // Ensure this getter exists
                                          // Step 1: Drag Start
                                          onChangeStart: (value) {
                                            setState(() {
                                              isDragging = true;
                                              dragValue = value;
                                            });
                                          },

                                          // Step 2: Dragging
                                          onChanged: (value) {
                                            setState(() {
                                              dragValue = value;
                                            });
                                          },

                                          // Step 3: Drag End (Seek)
                                          onChangeEnd: (value) {
                                            controller.audioPlayer.seek(
                                              Duration(seconds: value.toInt()),
                                            );
                                            setState(() {
                                              isDragging = false;
                                              dragValue = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 9.h),

                                    // Timer Text
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _format(
                                            progress.current,
                                          ), // Current Time
                                          style: TextStyle(color: subTextColor),
                                        ),
                                        Text(
                                          _format(progress.total), // Total Time
                                          style: TextStyle(color: subTextColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (err, stack) => const Text("Error"),
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
                              iconSize: 32.sp,
                              color: iconColor,
                              onPressed: controller.previousSong,
                            ),
                            SizedBox(width: 22.w),

                            // Play/Pause Button - Isolated Consumer
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  AudioController.instance.isPlaying,
                              builder: (context, isPlaying, child) {
                                return Container(
                                  width: 62.w,
                                  height: 62.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: playpause, // آپ کا color variable
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color:
                                          playpauseicon, //پ کicon color variable
                                    ),
                                    iconSize: 32.sp,
                                    onPressed: () {
                                      AudioController.instance
                                          .tooglePlayPause();
                                    },
                                  ),
                                );
                              },
                            ),

                            SizedBox(width: 26.w),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded),
                              iconSize: 32.sp,
                              color: iconColor,
                              onPressed: controller.nextSong,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 70.h),
                    ],
                  ),
          ),

          // ********** LYRICS SHEET **********
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              return ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (containerColor).withOpacity(0.6),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26.r),
                      ),
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
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 21.w,
                              vertical: 14.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.music_note_outlined,
                                      color: subTextColor,
                                      size: 26.sp,
                                    ),
                                    SizedBox(width: 9.w),
                                    Text(
                                      "Lyrics",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: isDarkTheme
                                          ? Colors.white.withOpacity(0.1)
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final lyricsAsync = ref.watch(lyricsProvider);
                                return Text(
                                  lyricsAsync.value ?? "No Lyrics Found",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Metropolis",
                                    height: 1.5,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
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
    );
  }

  // Yahan Maine 'format' function ko clean rakha hai.
  // Sirf MM:SS return karega, koi "~" nahi aayega.
  String _format(Duration d) {
    // Negative duration protection
    if (d.isNegative) return "00:00";

    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
