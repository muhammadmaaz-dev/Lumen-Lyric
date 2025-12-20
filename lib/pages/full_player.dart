import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicapp/provider/audio_provider.dart';

// Upar wale providers file ko import karna mat bhoolna
// import 'path/to/audio_providers.dart';

class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({super.key});

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer> {
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

  @override
  Widget build(BuildContext context) {
    final controller =
        AudioController.instance; // Actions perform karne ke liye

    // --- RIVERPOD WATCHERS (State yahan se aayegi) ---
    final themeMode = ref.watch(themeProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final lyricsAsync = ref.watch(lyricsProvider);

    // Song update ke liye current song fetch kar rahe hain
    final song = controller.currentsong;

    final isDarkTheme = themeMode == ThemeMode.dark;

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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 12) Navigator.pop(context);
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
              child: song == null
                  ? const SizedBox()
                  : Column(
                      children: [
                        const SizedBox(height: 20),
                        // ********** ALBUM ART **********
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
                                          borderRadius: BorderRadius.circular(
                                            30,
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
                                song.title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist ?? "Unknown",
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
                          child: Consumer(
                            builder: (context, ref, child) {
                              final progressAsync = ref.watch(progressProvider);

                              return progressAsync.when(
                                data: (progress) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        child: SliderTheme(
                                          data: SliderTheme.of(context)
                                              .copyWith(
                                                activeTrackColor: trackColors,
                                                thumbColor: thumbColor,
                                                trackHeight: 9,
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 10,
                                                    ),
                                                overlayShape:
                                                    SliderComponentShape
                                                        .noOverlay,
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
                                                Duration(
                                                  seconds: value.toInt(),
                                                ),
                                              );
                                              setState(() {
                                                isDragging = false;
                                                dragValue = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Timer Text
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _format(
                                              progress.current,
                                            ), // Current Time
                                            style: TextStyle(
                                              color: subTextColor,
                                            ),
                                          ),
                                          Text(
                                            _format(
                                              progress.total,
                                            ), // Total Time
                                            style: TextStyle(
                                              color: subTextColor,
                                            ),
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
                                iconSize: 36,
                                color: iconColor,
                                onPressed: controller.previousSong,
                              ),
                              const SizedBox(width: 25),

                              // Play/Pause Button
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: playpause,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    (isPlayingAsync.value ?? false)
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: playpauseicon,
                                  ),
                                  iconSize: 36,
                                  onPressed: controller.tooglePlayPause,
                                ),
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
                        const SizedBox(height: 80),
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: (containerColor).withOpacity(0.6),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30),
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
                                      IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(4),
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
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    lyricsAsync.value ?? "No Lyrics Found",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "Metropolis",
                                      height: 1.5,
                                      color: textColor,
                                    ),
                                    textAlign: TextAlign.center,
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
