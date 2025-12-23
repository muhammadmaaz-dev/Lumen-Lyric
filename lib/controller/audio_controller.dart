import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- 1. NEW IMPORT

class AudioController {
  static final AudioController instance = AudioController._instance();
  factory AudioController() => instance;
  AudioController._instance() {
    _setupAudioPlayer();
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();
  final FlutterAudioTagger _tagger = FlutterAudioTagger();

  final ValueNotifier<List<LocalSongModel>> songs =
      ValueNotifier<List<LocalSongModel>>([]);

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(-1);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<String> currentLyrics = ValueNotifier<String>(
    "No Lyrics",
  );

  LocalSongModel? get currentsong =>
      currentIndex.value != -1 && currentIndex.value < songs.value.length
      ? songs.value[currentIndex.value]
      : null;

  // **********************************************************************
  // SETUP PLAYER STREAM LISTENERS
  // **********************************************************************
  void _setupAudioPlayer() {
    audioPlayer.playerStateStream.listen((playerState) {
      isPlaying.value = playerState.playing;

      // Auto play next song when current finishes
      if (playerState.processingState == ProcessingState.completed) {
        if (currentIndex.value < songs.value.length - 1) {
          nextSong();
        } else {
          isPlaying.value = false;
          audioPlayer.stop();
        }
      }
    });
  }

  // **********************************************************************
  // LOAD SONGS (UPDATED)
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

    songs.value = fetchSongs.map((s) {
      bool isFromMyApp = s.data.contains("MyMusicApp");
      return LocalSongModel(
        id: s.id,
        artist: s.artist ?? "Unknown Artist",
        title: s.title,
        uri: s.data,
        albumArt: s.album ?? "",
        duration: s.duration ?? 0,
        isDownloaded: isFromMyApp,
        isLiked: false, // Default false, hum neeche restore karenge
      );
    }).toList();

    // <--- 2. Yahan hum Likes ko restore karenge
    await _restoreLikes();
  }

  // **********************************************************************
  // LIKE FEATURE LOGIC (NEW)
  // **********************************************************************

  // 1. Toggle Like Function
  Future<void> toggleLike(int songId) async {
    final currentList = songs.value;
    final index = currentList.indexWhere((s) => s.id == songId);

    if (index != -1) {
      // List ki copy banayi (Immutability rule)
      final newList = List<LocalSongModel>.from(currentList);

      // Status flip kiya
      final newStatus = !newList[index].isLiked;
      newList[index] = newList[index].copyWith(isLiked: newStatus);

      // UI Update
      songs.value = newList;

      // Save to Storage
      await _saveLikesToPrefs();
    }
  }

  // 2. Save Logic
  Future<void> _saveLikesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final likedIds = songs.value
        .where((s) => s.isLiked)
        .map((s) => s.id.toString())
        .toList();

    await prefs.setStringList('liked_songs', likedIds);
  }

  // 3. Restore Logic
  Future<void> _restoreLikes() async {
    final prefs = await SharedPreferences.getInstance();
    final likedIds = prefs.getStringList('liked_songs') ?? [];

    if (likedIds.isNotEmpty && songs.value.isNotEmpty) {
      final newList = List<LocalSongModel>.from(songs.value);

      for (int i = 0; i < newList.length; i++) {
        // Check agar current song ID saved list mein hai
        if (likedIds.contains(newList[i].id.toString())) {
          newList[i] = newList[i].copyWith(isLiked: true);
        }
      }
      songs.value = newList;
    }
  }

  // LibraryScreen State class ke andar

  // **********************************************************************
  // PLAY SONG
  // **********************************************************************
  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.value.length) return;

    try {
      currentIndex.value = index;
      final song = songs.value[index];

      _fetchLyrics(song.uri);

      final uri = _buildUri(song.uri);
      await audioPlayer.setAudioSource(AudioSource.uri(uri), preload: true);
      await audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      if (e.toString().contains("PlayerInterruptedException") ||
          e.toString().contains("aborted")) {
        print("Loading interrupted by new request (Normal behavior)");
      } else {
        print("Error While Playing Song : $e");
      }
    }
  }

  Uri _buildUri(String uri) {
    if (uri.startsWith("/storage") || uri.startsWith("/sdcard")) {
      return Uri.file(uri);
    }
    return Uri.parse(uri);
  }

  // **********************************************************************
  // CONTROLS
  // **********************************************************************
  Future<void> pauseSong() async {
    await audioPlayer.pause();
    isPlaying.value = false;
  }

  Future<void> resumeSong() async {
    await audioPlayer.play();
    isPlaying.value = true;
  }

  void tooglePlayPause() async {
    if (currentIndex.value == -1) return;
    if (isPlaying.value) {
      await pauseSong();
    } else {
      await resumeSong();
    }
  }

  Future<void> nextSong() async {
    if (currentIndex.value < songs.value.length - 1) {
      await playSong(currentIndex.value + 1);
    } else {
      await audioPlayer.stop();
      currentIndex.value = -1;
      isPlaying.value = false;
    }
  }

  Future<void> previousSong() async {
    if (currentIndex.value <= 0) {
      await audioPlayer.stop();
      currentIndex.value = -1;
      isPlaying.value = false;
      return;
    }
    await playSong(currentIndex.value - 1);
  }

  // **********************************************************************
  // FETCH LYRICS
  // **********************************************************************
  Future<void> _fetchLyrics(String path) async {
    currentLyrics.value = "Loading Lyrics...";

    if (path.startsWith("content://")) {
      currentLyrics.value = "Cannot read lyrics from Content URI";
      return;
    }

    if (path.toLowerCase().endsWith(".opus")) {
      currentLyrics.value = "Lyrics not supported for .opus files";
      return;
    }

    try {
      final tag = await _tagger.getAllTags(path);
      if (tag != null && tag.lyrics != null && tag.lyrics!.isNotEmpty) {
        currentLyrics.value = tag.lyrics!;
      } else {
        currentLyrics.value = "No Lyrics Found";
      }
    } catch (e) {
      print("Lyrics Error: $e");
      currentLyrics.value = "No Lyrics Available";
    }
  }

  // **********************************************************************
  // DELETE SONG
  // **********************************************************************
  Future<void> deleteSong(int songId, String filePath) async {
    bool deleted = false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print("File deleted from storage");
        deleted = true;
      } else {
        print("File not found, removing from list");
        deleted = true;
      }
    } catch (e) {
      print("Error deleting song: $e");
      if (e.toString().contains("PathNotFoundException") ||
          e.toString().contains("No such file")) {
        deleted = true;
      }
    }

    if (deleted) {
      songs.value = songs.value.where((song) => song.id != songId).toList();
      if (currentsong?.id == songId) {
        audioPlayer.stop();
        currentIndex.value = -1;
      }

      // NEW: Agar liked song delete hua to prefs bhi update karo
      _saveLikesToPrefs();
    }
  }

  void dispose() {
    audioPlayer.dispose();
  }
}
