import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Playlist-specific playback queue
  final ValueNotifier<List<LocalSongModel>> playbackQueue =
      ValueNotifier<List<LocalSongModel>>([]);
  final ValueNotifier<int> queueIndex = ValueNotifier<int>(-1);
  bool _isPlayingFromQueue = false;

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(-1);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<String> currentLyrics = ValueNotifier<String>(
    "No Lyrics",
  );

  bool _isFetching = false;

  LocalSongModel? get currentsong {
    if (_isPlayingFromQueue &&
        queueIndex.value != -1 &&
        queueIndex.value < playbackQueue.value.length) {
      return playbackQueue.value[queueIndex.value];
    }
    return currentIndex.value != -1 && currentIndex.value < songs.value.length
        ? songs.value[currentIndex.value]
        : null;
  }

  void _setupAudioPlayer() {
    audioPlayer.playerStateStream.listen((playerState) {
      isPlaying.value = playerState.playing;

      if (playerState.processingState == ProcessingState.completed) {
        if (_isPlayingFromQueue) {
          if (queueIndex.value < playbackQueue.value.length - 1) {
            _playFromQueue(queueIndex.value + 1);
          } else {
            isPlaying.value = false;
            audioPlayer.stop();
          }
        } else {
          if (currentIndex.value < songs.value.length - 1) {
            nextSong();
          } else {
            isPlaying.value = false;
            audioPlayer.stop();
          }
        }
      }
    });
  }

  // **********************************************************************
  // LOAD SONGS (Updated: Filters out Blacklisted IDs)
  // **********************************************************************
  Future<void> loadSongs() async {
    if (_isFetching || songs.value.isNotEmpty) return;
    _isFetching = true;

    try {
      // --- PERMISSION LOGIC ---
      bool permissionGranted = false;
      var statusAudio = await Permission.audio.status;
      var statusStorage = await Permission.storage.status;

      if (statusAudio.isGranted || statusStorage.isGranted) {
        permissionGranted = true;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.audio,
        ].request();

        if (statuses[Permission.audio] == PermissionStatus.granted ||
            statuses[Permission.storage] == PermissionStatus.granted) {
          permissionGranted = true;
        }
      }

      if (!permissionGranted) {
        debugPrint("Permission not granted");
        return;
      }

      // --- QUERY LOGIC ---
      final fetchSongs = await audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // ✅ 1. Load Blacklist (Deleted Songs) from Prefs
      final prefs = await SharedPreferences.getInstance();
      final blockedIds = prefs.getStringList('blocked_song_ids') ?? [];

      // ✅ 2. Filter List: Exclude any song inside blockedIds
      songs.value = fetchSongs
          .where((s) => !blockedIds.contains(s.id.toString()))
          .map((s) {
            bool isFromMyApp = s.data.contains("MyMusicApp");
            String songUri = s.uri ?? s.data;

            return LocalSongModel(
              id: s.id,
              artist: s.artist ?? "Unknown Artist",
              title: s.title,
              uri: songUri,
              albumArt: s.album ?? "",
              duration: s.duration ?? 0,
              isDownloaded: isFromMyApp,
              isLiked: false,
            );
          })
          .toList();

      await _restoreLikes();
    } catch (e) {
      debugPrint("Error loading songs: $e");
    } finally {
      _isFetching = false;
    }
  }

  Uri _buildUri(String uri) {
    if (uri.startsWith("content://")) {
      return Uri.parse(uri);
    }
    if (uri.startsWith("/storage") || uri.startsWith("/sdcard")) {
      return Uri.file(uri);
    }
    return Uri.parse(uri);
  }

  Future<void> toggleLike(int songId) async {
    final currentList = songs.value;
    final index = currentList.indexWhere((s) => s.id == songId);
    if (index != -1) {
      final newList = List<LocalSongModel>.from(currentList);
      final newStatus = !newList[index].isLiked;
      newList[index] = newList[index].copyWith(isLiked: newStatus);
      songs.value = newList;
      await _saveLikesToPrefs();
    }
  }

  Future<void> _saveLikesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final likedIds = songs.value
        .where((s) => s.isLiked)
        .map((s) => s.id.toString())
        .toList();
    await prefs.setStringList('liked_songs', likedIds);
  }

  Future<void> _restoreLikes() async {
    final prefs = await SharedPreferences.getInstance();
    final likedIds = prefs.getStringList('liked_songs') ?? [];
    if (likedIds.isNotEmpty && songs.value.isNotEmpty) {
      final newList = List<LocalSongModel>.from(songs.value);
      for (int i = 0; i < newList.length; i++) {
        if (likedIds.contains(newList[i].id.toString())) {
          newList[i] = newList[i].copyWith(isLiked: true);
        }
      }
      songs.value = newList;
    }
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.value.length) return;
    _isPlayingFromQueue = false;
    playbackQueue.value = [];
    queueIndex.value = -1;

    try {
      currentIndex.value = index;
      final song = songs.value[index];
      _fetchLyrics(song.uri);
      final uri = _buildUri(song.uri);
      await audioPlayer.setAudioSource(AudioSource.uri(uri), preload: true);
      await audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      print("Error Playing: $e");
    }
  }

  Future<void> playFromPlaylist(
    List<LocalSongModel> playlistSongs,
    int index,
  ) async {
    if (index < 0 || index >= playlistSongs.length) return;
    _isPlayingFromQueue = true;
    playbackQueue.value = playlistSongs;
    queueIndex.value = index;
    currentIndex.value = index;
    await _playCurrentQueueSong();
  }

  Future<void> _playFromQueue(int index) async {
    if (index < 0 || index >= playbackQueue.value.length) return;
    queueIndex.value = index;
    currentIndex.value = index;
    await _playCurrentQueueSong();
  }

  Future<void> _playCurrentQueueSong() async {
    if (queueIndex.value < 0 || queueIndex.value >= playbackQueue.value.length)
      return;
    try {
      final song = playbackQueue.value[queueIndex.value];
      _fetchLyrics(song.uri);
      final uri = _buildUri(song.uri);
      await audioPlayer.setAudioSource(AudioSource.uri(uri), preload: true);
      await audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      print("Error Playing Queue: $e");
    }
  }

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
    if (_isPlayingFromQueue) {
      if (queueIndex.value < playbackQueue.value.length - 1) {
        await _playFromQueue(queueIndex.value + 1);
      } else {
        await audioPlayer.stop();
        currentIndex.value = -1;
        queueIndex.value = -1;
        isPlaying.value = false;
      }
    } else {
      if (currentIndex.value < songs.value.length - 1) {
        await playSong(currentIndex.value + 1);
      } else {
        await audioPlayer.stop();
        currentIndex.value = -1;
        isPlaying.value = false;
      }
    }
  }

  Future<void> previousSong() async {
    if (_isPlayingFromQueue) {
      if (queueIndex.value <= 0) {
        await audioPlayer.stop();
        currentIndex.value = -1;
        queueIndex.value = -1;
        isPlaying.value = false;
        return;
      }
      await _playFromQueue(queueIndex.value - 1);
    } else {
      if (currentIndex.value <= 0) {
        await audioPlayer.stop();
        currentIndex.value = -1;
        isPlaying.value = false;
        return;
      }
      await playSong(currentIndex.value - 1);
    }
  }

  void clearQueue() {
    _isPlayingFromQueue = false;
    playbackQueue.value = [];
    queueIndex.value = -1;
  }

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
      currentLyrics.value = "No Lyrics Available";
    }
  }

  // **********************************************************************
  // DELETE SONG (Updated: Adds to Blacklist)
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
      // Even if file deletion fails (common on Android 11+ for non-owned files),
      // we mark it as deleted so we can hide it from the UI.
      deleted = true;
    }

    if (deleted) {
      // ✅ 1. Add ID to Blacklist in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> blockedIds = prefs.getStringList('blocked_song_ids') ?? [];

      if (!blockedIds.contains(songId.toString())) {
        blockedIds.add(songId.toString());
        await prefs.setStringList('blocked_song_ids', blockedIds);
      }

      // ✅ 2. Remove from Memory List (UI Update)
      songs.value = songs.value.where((song) => song.id != songId).toList();

      // ✅ 3. Stop player if that specific song was playing
      if (currentsong?.id == songId) {
        audioPlayer.stop();
        currentIndex.value = -1;
        isPlaying.value = false;
        clearQueue();
      }

      _saveLikesToPrefs();
    }
  }

  void dispose() {
    audioPlayer.dispose();
  }
}
