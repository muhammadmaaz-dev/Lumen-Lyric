import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicapp/provider/audio_provider.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FullPlayer extends ConsumerStatefulWidget {
  final MiniplayerController? miniplayerController;

  const FullPlayer({super.key, this.miniplayerController});

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool isExpanded = false;
  late bool _showLottie;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _showLottie = prefs.getBool('show_lottie_convert') ?? false;

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
    final controller = AudioController.instance;

    return ValueListenableBuilder<int>(
      valueListenable: controller.currentIndex,
      builder: (context, index, _) {
        final song = controller.currentsong;
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
            automaticallyImplyLeading: false,
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: iconColor,
                    size: 31.sp,
                  ),
                  onPressed: _minimizePlayer,
                ),
                Text(
                  'Now Playing',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final newValue = !_showLottie;
                    setState(() {
                      _showLottie = newValue;
                    });
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setBool('show_lottie_convert', newValue);
                  },
                  icon: Icon(
                    Icons.change_circle_outlined,
                    color: textColor,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    SizedBox(height: 18.h),

                    // ********** ARTWORK / LOTTIE TOGGLE **********
                    Expanded(
                      flex: 5,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeInOutBack,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                        child: _showLottie
                            ? Container(
                                key: const ValueKey('lottie_view'),
                                child: Center(
                                  child: Container(
                                    width: 300.w,
                                    height: 300.h,
                                    padding: EdgeInsets.zero,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: controller.isPlaying,
                                      builder: (context, isPlaying, _) {
                                        return Lottie.asset(
                                          isDarkTheme
                                              ? 'assets/animation/Astornaut-White.json'
                                              : 'assets/animation/Astornaut-Music.json',
                                          fit: BoxFit.contain,
                                          animate: isPlaying,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                key: const ValueKey('artwork_view'),
                                child: AlbumArtWidget(
                                  key: ValueKey(song.id),
                                  songId: song.id,
                                  artworkUrl:
                                      song.artworkUrl, // ✅ PASS URL HERE
                                  isDarkTheme: isDarkTheme,
                                  heartBgColor: heartBgColor,
                                ),
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
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            song.artist.isEmpty ? "Unknown" : song.artist,
                            style: TextStyle(
                              fontSize: 15.sp,
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

                    SizedBox(height: 5.h),

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
                                    padding: EdgeInsets.all(10.r),
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
                                  SizedBox(height: 45.h),
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

// ✅ UPDATED AlbumArtWidget Logic
class AlbumArtWidget extends StatefulWidget {
  final int songId;
  final String? artworkUrl; // ✅ ADD THIS
  final bool isDarkTheme;
  final Color heartBgColor;

  const AlbumArtWidget({
    Key? key,
    required this.songId,
    this.artworkUrl, // ✅ Receive it
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
              borderRadius: BorderRadius.circular(45.r),
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
              // ✅ Logic to prioritize downloaded artwork (local file first)
              child: _buildArtworkImage(),
            ),
          ),

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

  /// Build artwork image - handles both local file paths and network URLs
  Widget _buildArtworkImage() {
    if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty) {
      final artworkPath = widget.artworkUrl!;

      // Check if it's a local file or network URL
      if (artworkPath.startsWith('http://') ||
          artworkPath.startsWith('https://')) {
        return Image.network(
          artworkPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildLocalArtwork();
          },
        );
      } else {
        // Local file path
        final file = File(artworkPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildLocalArtwork();
            },
          );
        }
      }
    }
    return _buildLocalArtwork();
  }

  Widget _buildLocalArtwork() {
    return QueryArtworkWidget(
      id: widget.songId,
      type: ArtworkType.AUDIO,
      artworkHeight: 264.h,
      artworkWidth: 264.w,
      artworkFit: BoxFit.cover,
      keepOldArtwork: true,
      nullArtworkWidget: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45.r),
          gradient: const LinearGradient(
            colors: [Color(0xFF8E97FD), Color(0xFFC2E9FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.music_note, size: 70.sp, color: Colors.white),
      ),
    );
  }
}

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
