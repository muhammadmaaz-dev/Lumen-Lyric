import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioController {
  static final AudioController instance = AudioController._instance();
  factory AudioController() => instance;
  AudioController._instance() {
    _setupAudioPlayer();
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();

  final ValueNotifier<List<LocalSongModel>> songs =
      ValueNotifier<List<LocalSongModel>>([]);

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(-1);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  LocalSongModel? get currentsong =>
      currentIndex.value != -1 && currentIndex.value < songs.value.length
      ? songs.value[currentIndex.value]
      : null;

  // **********************************************************************
  // SETUP PLAYER STREAM LISTENERS
  // **********************************************************************
  // **********************************************************************
  // SETUP PLAYER STREAM LISTENERS
  // **********************************************************************
  void _setupAudioPlayer() {
    audioPlayer.playerStateStream.listen((playerState) {
      isPlaying.value = playerState.playing;

      // Auto play next song when current finishes
      if (playerState.processingState == ProcessingState.completed) {
        // Yahan check karein ke kya hum already last song par tou nahi hain
        // Taa ke unnecessary next calls na hon
        if (currentIndex.value < songs.value.length - 1) {
          nextSong();
        } else {
          // Agar playlist khatam ho gayi hai
          isPlaying.value = false;
          audioPlayer.stop();
        }
      }
    });
  }

  // **********************************************************************
  // LOAD SONGS
  // **********************************************************************
  Future<void> loadSongs() async {
    if (songs.value.isNotEmpty) return; // already loaded

    bool hasPermission = await audioQuery.permissionsStatus();
    if (!hasPermission) {
      hasPermission = await audioQuery.permissionsRequest();
    }
    if (!hasPermission) return;

    final fetchSongs = await audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    songs.value = fetchSongs
        .map(
          (s) => LocalSongModel(
            id: s.id,
            artist: s.artist ?? "Unknown Artist",
            title: s.title,
            uri: s.uri ?? "",
            albumArt: s.album ?? "",
            duration: s.duration ?? 0,
          ),
        )
        .toList();
  }

  // **********************************************************************
  // PLAY SONG (FIXED)
  // **********************************************************************
  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.value.length) return;

    try {
      currentIndex.value = index;
      final song = songs.value[index];

      // ERROR FIX: Ye line hata dein, iski waja se interruption error ata hai
      // await audioPlayer.stop();  <-- COMMENTED OUT / REMOVED

      // FIX: Local files require Uri.file(...) instead of Uri.parse(...)
      final uri = _buildUri(song.uri);

      // Try setting source
      await audioPlayer.setAudioSource(AudioSource.uri(uri), preload: true);

      //---------------------------------------------------------------------

      await audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      // Agar error PlayerInterruptedException hai to usay ignore karein
      // kyunke iska matlab hai naya song load hona shuru ho gaya hai.
      if (e.toString().contains("PlayerInterruptedException") ||
          e.toString().contains("aborted")) {
        print("Loading interrupted by new request (Normal behavior)");
      } else {
        print("Error While Playing Song : $e");
      }
    }
  }

  // Detect correct URI type
  Uri _buildUri(String uri) {
    if (uri.startsWith("/storage") || uri.startsWith("/sdcard")) {
      return Uri.file(uri);
    }
    return Uri.parse(uri);
  }

  // **********************************************************************
  // PAUSE SONG
  // **********************************************************************
  Future<void> pauseSong() async {
    await audioPlayer.pause();
    isPlaying.value = false;
  }

  // **********************************************************************
  // RESUME SONG
  // **********************************************************************
  Future<void> resumeSong() async {
    await audioPlayer.play();
    isPlaying.value = true;
  }

  // **********************************************************************
  // PLAY/PAUSE TOGGLE
  // **********************************************************************
  void tooglePlayPause() async {
    if (currentIndex.value == -1) return;

    if (isPlaying.value) {
      await pauseSong();
    } else {
      await resumeSong();
    }
  }

  // **********************************************************************
  // NEXT SONG
  // **********************************************************************
  Future<void> nextSong() async {
    if (currentIndex.value < songs.value.length - 1) {
      await playSong(currentIndex.value + 1);
    } else {
      // last song → stop playback and hide mini player
      await audioPlayer.stop();
      currentIndex.value = -1;
      isPlaying.value = false;
    }
  }

  // **********************************************************************
  // PREVIOUS SONG (FIXED CRASH)
  // **********************************************************************
  Future<void> previousSong() async {
    if (currentIndex.value <= 0) {
      // First song → stop + hide mini player (prevent crash)
      await audioPlayer.stop();
      currentIndex.value = -1;
      isPlaying.value = false;
      return;
    }

    await playSong(currentIndex.value - 1);
  }

  // **********************************************************************
  // DISPOSE PLAYER
  // **********************************************************************
  void dispose() {
    audioPlayer.dispose();
  }
}
