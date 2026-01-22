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

  void _minimizePlayer() {
    if (widget.miniplayerController != null) {
      widget.miniplayerController!.animateToHeight(state: PanelState.MIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Controller se direct song lene ki bajaye, hum ensure karenge ke
    // hum sirf zaroori widgets ko rebuild karein.
    final controller = AudioController.instance;

    // ValueListenableBuilder use karein taaki jab song change ho tabhi update ho
    return ValueListenableBuilder<int>(
      valueListenable: controller.currentIndex,
      builder: (context, index, _) {
        final song = controller.currentsong;

        // Agar song null hai to empty box dikhayein
        if (song == null) return const SizedBox();

        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

        // Colors Setup
        final backgroundColor = isDarkTheme
            ? const Color(0xff000000)
            : Colors.white;
        final textColor = isDarkTheme ? Colors.white : Colors.black;
        final subTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey[600];
        final iconColor = isDarkTheme ? Colors.white : Colors.black;
        final playpause = isDarkTheme ? Colors.white : Colors.black;
        final playpauseicon = isDarkTheme ? Colors.black : Colors.white;
        final containerColor = isDarkTheme
            ? const Color.fromARGB(225, 0, 0, 0)
            : const Color.fromARGB(226, 255, 255, 255);
        final heartBgColor = isDarkTheme
            ? const Color(0xff1a1a1a)
            : Colors.white;

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
              Positioned.fill(
                child: Column(
                  children: [
                    SizedBox(height: 18.h),

                    // ********** ALBUM ART (ISOLATED) **********
                    // Humne 'AlbumArtWidget' alag banaya hai aur 'key' pass ki hai.
                    // Jab tak song.id same rahega, ye rebuild nahi hoga -> NO FLICKER.
                    Expanded(
                      flex: 5,
                      child: AlbumArtWidget(
                        key: ValueKey(song.id), // YE LINE SABSE ZAROORI HAI
                        songId: song.id,
                        isDarkTheme: isDarkTheme,
                        heartBgColor: heartBgColor,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            song.artist.isEmpty ? "Unknown" : song.artist,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: subTextColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 22.h),

                    // ********** PROGRESS BAR **********
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 21.w),
                      child: const PlayerProgressBar(),
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

                          // Play/Pause Button
                          ValueListenableBuilder<bool>(
                            valueListenable: controller.isPlaying,
                            builder: (context, isPlaying, child) {
                              return Container(
                                width: 62.w,
                                height: 62.h,
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
                                  iconSize: 32.sp,
                                  onPressed: () {
                                    controller.tooglePlayPause();
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
                builder:
                    (BuildContext context, ScrollController scrollController) {
                      return ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26.r),
                        ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                  ? Colors.white.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.1,
                                                    ),
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
                                        final lyricsAsync = ref.watch(
                                          lyricsProvider,
                                        );
                                        return Text(
                                          lyricsAsync.value ??
                                              "No Lyrics Found",
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
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 1. ISOLATED ALBUM ART WIDGET (FIX FOR FLICKER)
// ---------------------------------------------------------------------------
class AlbumArtWidget extends StatefulWidget {
  final int songId;
  final bool isDarkTheme;
  final Color heartBgColor;

  const AlbumArtWidget({
    Key? key, // Key zaroori hai
    required this.songId,
    required this.isDarkTheme,
    required this.heartBgColor,
  }) : super(key: key);

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  @override
  Widget build(BuildContext context) {
    final placeholderColor = widget.isDarkTheme
        ? Colors.grey[800]
        : Colors.grey[300];

    return Center(
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
                id: widget.songId,
                type: ArtworkType.AUDIO,
                artworkHeight: 264.h,
                artworkWidth: 264.w,
                artworkFit: BoxFit.cover,
                // Keep artwork in cache if possible
                keepOldArtwork: true,
                nullArtworkWidget: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26.r),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E97FD), Color(0xFFC2E9FB)],
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

          // Like Button - Integrated here to stay with image layout
          Positioned(
            bottom: -22.h,
            child: GestureDetector(
              onTap: () {
                AudioController.instance.toggleLike(widget.songId);
              },
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: widget.heartBgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<List<dynamic>>(
                  // Listen to songs list to update heart icon without rebuilding image
                  valueListenable: AudioController.instance.songs,
                  builder: (context, songs, _) {
                    final isLiked = AudioController.instance.songs.value
                        .firstWhere(
                          (element) => element.id == widget.songId,
                          orElse: () => AudioController.instance.songs.value[0],
                        )
                        .isLiked;

                    return Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 25.sp,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. ISOLATED PROGRESS BAR (FROM PREVIOUS FIX)
// ---------------------------------------------------------------------------
class PlayerProgressBar extends ConsumerStatefulWidget {
  const PlayerProgressBar({super.key});

  @override
  ConsumerState<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends ConsumerState<PlayerProgressBar> {
  bool isDragging = false;
  double? dragValue;

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey[600];
    final thumbColor = isDarkTheme ? Colors.black : Colors.white;
    final trackColors = isDarkTheme ? Colors.white : Colors.black;

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
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: isDragging ? dragValue ?? 0 : progress.safeValue,
                  max: progress.totalSeconds,
                  onChangeStart: (value) {
                    setState(() {
                      isDragging = true;
                      dragValue = value;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      dragValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    AudioController.instance.audioPlayer.seek(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(progress.current),
                  style: TextStyle(color: subTextColor),
                ),
                Text(
                  _format(progress.total),
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
  }

  String _format(Duration d) {
    if (d.isNegative) return "00:00";
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
