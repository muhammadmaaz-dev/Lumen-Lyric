import 'dart:async';
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
        0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _sheetController.animateTo(
        0.8,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    isExpanded = !isExpanded;
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

        return GestureDetector(
          onTap: () {},
          child: Scaffold(
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
                                    artworkUrl: song.artworkUrl,
                                    isDarkTheme: isDarkTheme,
                                    heartBgColor: heartBgColor,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 26.h),

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

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 21.w),
                        child: const PlayerProgressBar(),
                      ),

                      SizedBox(height: 5.h),

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

                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.1,
                  minChildSize: 0.1,
                  maxChildSize: 0.9,
                  builder: (BuildContext context, ScrollController scrollController) {
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

                              Expanded(
                                child: ValueListenableBuilder<String?>(
                                  valueListenable: AudioController
                                      .instance
                                      .currentLrcContent,
                                  builder: (context, lrcContent, child) {
                                    bool isSynced =
                                        lrcContent != null &&
                                        lrcContent.contains(
                                          RegExp(r'\[\d{2}:\d{2}'),
                                        );

                                    if (isSynced) {
                                      return SyncedLyricsWidget(
                                        key: ValueKey(
                                          'synced_lyrics_${lrcContent.hashCode}',
                                        ),
                                        lrcContent: lrcContent!,
                                        scrollController: scrollController,
                                        highlightColor: isDarkTheme
                                            ? Colors.white
                                            : const Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              ),
                                        defaultColor:
                                            subTextColor ?? Colors.grey,
                                        textColor: textColor,
                                        isDarkTheme: isDarkTheme,
                                      );
                                    } else {
                                      return ValueListenableBuilder<String>(
                                        valueListenable: AudioController
                                            .instance
                                            .currentLyrics,
                                        builder: (context, plainLyrics, _) {
                                          String textToShow =
                                              lrcContent ?? plainLyrics;

                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: EdgeInsets.fromLTRB(
                                              20.r,
                                              0,
                                              20.r,
                                              40.r,
                                            ),
                                            child: Text(
                                              textToShow,
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "Metropolis",
                                                height: 1.6,
                                                color: textColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
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
      },
    );
  }
}

class AlbumArtWidget extends StatefulWidget {
  final int songId;
  final String? artworkUrl;
  final bool isDarkTheme;
  final Color heartBgColor;

  const AlbumArtWidget({
    Key? key,
    required this.songId,
    this.artworkUrl,
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

  Widget _buildArtworkImage() {
    if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty) {
      final artworkPath = widget.artworkUrl!;

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

/// Parsed LRC line: timestamp in ms + text
class _LrcLine {
  final int timeMs;
  final String text;
  const _LrcLine(this.timeMs, this.text);
}

/// Custom synced lyrics widget with real-time line highlighting & auto-scroll.
class SyncedLyricsWidget extends StatefulWidget {
  final String lrcContent;
  final ScrollController scrollController;
  final Color highlightColor;
  final Color defaultColor;
  final Color textColor;
  final bool isDarkTheme;

  const SyncedLyricsWidget({
    Key? key,
    required this.lrcContent,
    required this.scrollController,
    required this.highlightColor,
    required this.defaultColor,
    required this.textColor,
    required this.isDarkTheme,
  }) : super(key: key);

  @override
  State<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends State<SyncedLyricsWidget> {
  List<_LrcLine> _lines = [];
  int _currentLineIndex = -1;
  StreamSubscription<Duration>? _positionSub;

  // Auto-scroll logic variables
  bool _isUserScrolling = false;
  Timer? _resumeTimer;

  // GlobalKeys for each lyric line to enable auto-scroll
  final Map<int, GlobalKey> _lineKeys = {};

  @override
  void initState() {
    super.initState();
    _lines = _parseLrc(widget.lrcContent);
    _initLineKeys();
    _startListening();
  }

  void _initLineKeys() {
    _lineKeys.clear();
    for (int i = 0; i < _lines.length; i++) {
      _lineKeys[i] = GlobalKey();
    }
  }

  void _startListening() {
    _positionSub?.cancel();
    _positionSub = AudioController.instance.audioPlayer.positionStream.listen(
      _onPositionChanged,
    );
  }

  @override
  void didUpdateWidget(covariant SyncedLyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lrcContent != widget.lrcContent) {
      setState(() {
        _lines = _parseLrc(widget.lrcContent);
        _currentLineIndex = -1;
        _initLineKeys();
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }

  List<_LrcLine> _parseLrc(String lrc) {
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]\s*(.*)');
    final List<_LrcLine> result = [];

    for (final line in lrc.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final min = int.tryParse(match.group(1) ?? '') ?? 0;
        final sec = int.tryParse(match.group(2) ?? '') ?? 0;
        final msStr = match.group(3);
        int ms = 0;
        if (msStr != null && msStr.isNotEmpty) {
          final msVal = int.tryParse(msStr) ?? 0;
          if (msStr.length == 1) {
            ms = msVal * 100;
          } else if (msStr.length == 2) {
            ms = msVal * 10;
          } else {
            ms = msVal;
          }
        }
        final totalMs = min * 60000 + sec * 1000 + ms;
        final text = match.group(4)?.trim() ?? '';
        if (text.isNotEmpty) {
          result.add(_LrcLine(totalMs, text));
        }
      }
    }
    result.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return result;
  }

  void _onPositionChanged(Duration position) {
    if (_lines.isEmpty || !mounted) return;

    final posMs = position.inMilliseconds;
    int newIndex = -1;

    for (int i = _lines.length - 1; i >= 0; i--) {
      if (posMs >= _lines[i].timeMs) {
        newIndex = i;
        break;
      }
    }

    if (newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
      });
      // Sirf tab scroll karega jab user khud ungli se na rok raha ho
      if (!_isUserScrolling) {
        _scrollToLine(newIndex);
      }
    }
  }

  void _scrollToLine(int index) {
    if (index < 0 || !_lineKeys.containsKey(index)) return;
    final key = _lineKeys[index];

    if (key?.currentContext == null) return;

    Scrollable.ensureVisible(
      key!.currentContext!,
      alignment: 0.35,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return Center(
        child: Text(
          "No Lyrics",
          style: TextStyle(color: widget.textColor, fontSize: 18.sp),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          if (notification.dragDetails != null) {
            _isUserScrolling = true;
            _resumeTimer?.cancel();
          }
        } else if (notification is ScrollEndNotification) {
          _resumeTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) _isUserScrolling = false;
          });
        }
        return false;
      },
      child: ListView.builder(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        cacheExtent: 1500,
        padding: EdgeInsets.only(
          top: 20.h,
          bottom: 100.h,
          left: 16.w,
          right: 16.w,
        ),
        itemCount: _lines.length,
        itemBuilder: (context, index) {
          final isActive = index == _currentLineIndex;
          final isPrevious = index == _currentLineIndex - 1;
          final isNext = index == _currentLineIndex + 1;

          double opacity;
          if (isActive) {
            opacity = 1.0;
          } else if (isPrevious || isNext) {
            opacity = 0.7;
          } else {
            opacity = 0.5;
          }

          return Container(
            key: _lineKeys[index],
            margin: EdgeInsets.symmetric(vertical: isActive ? 8.h : 4.h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                vertical: isActive ? 14.h : 8.h,
                horizontal: 12.w,
              ),
              decoration: isActive
                  ? BoxDecoration(
                      color: widget.highlightColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    )
                  : null,
              child: AnimatedScale(
                scale: isActive ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _lines[index].text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isActive ? 22.sp : 16.sp,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      fontFamily: "Metropolis",
                      color: isActive
                          ? widget.highlightColor
                          : widget.defaultColor,
                      height: 1.5,
                      letterSpacing: isActive ? 0.5 : 0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
