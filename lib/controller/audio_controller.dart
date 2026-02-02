import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/services/metadata_database_service.dart'; // ✅ Permanent Metadata Storage
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:musicapp/models/song_model.dart' as Online;
import 'package:path/path.dart' as path; // ✅ For file path operations

class AudioController {
  static final AudioController instance = AudioController._instance();
  factory AudioController() => instance;
  AudioController._instance() {
    _setupAudioPlayer();
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();
  final FlutterAudioTagger _tagger = FlutterAudioTagger();
  final MetadataDatabaseService _metadataDb =
      MetadataDatabaseService.instance; // ✅ Permanent Storage

  final ValueNotifier<List<LocalSongModel>> songs =
      ValueNotifier<List<LocalSongModel>>([]);

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

  // ✅ 1. Ghosting Fix Flag
  bool _isPlayerDismissed = false;

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
    // 1. Sync Playing State
    audioPlayer.playerStateStream.listen((playerState) {
      isPlaying.value = playerState.playing;

      // ✅ NOTE: Removed Manual "Auto-Play Next" logic here.
      // just_audio's ConcatenatingAudioSource handles this automatically now.
      // If we keep it, it might cause double-skips.
      if (playerState.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        // Optionally reset UI when playlist ends
      }
    });

    // 2. Sync Current Song Index (Handles Background Next/Prev updates)
    audioPlayer.currentIndexStream.listen((index) {
      // ✅ FIX: Only update index if Player is NOT dismissed
      if (index != null && !_isPlayerDismissed) {
        currentIndex.value = index;

        if (_isPlayingFromQueue) {
          queueIndex.value = index;
        }

        final song = currentsong;
        if (song != null) {
          _fetchLyrics(song.uri);
        }
      }
    });
  }

  Future<void> scanMedia(String path) async {
    try {
      debugPrint("Scanning file: $path");
      await audioQuery.scanMedia(path);
    } catch (e) {
      debugPrint("Error scanning media: $e");
    }
  }

  Future<void> scanNewMedia(String path) async {
    try {
      debugPrint("🔍 Scanning file: $path");
      await audioQuery.scanMedia(path);
      await Future.delayed(const Duration(seconds: 1));
      await loadSongs();
    } catch (e) {
      debugPrint("❌ Error scanning media: $e");
    }
  }

  Future<void> loadSongs() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      bool hasPermission = false;
      if (await Permission.audio.isGranted ||
          await Permission.storage.isGranted) {
        hasPermission = true;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.audio,
          Permission.storage,
        ].request();
        if (statuses[Permission.audio] == PermissionStatus.granted ||
            statuses[Permission.storage] == PermissionStatus.granted) {
          hasPermission = true;
        }
      }

      if (!hasPermission) {
        debugPrint("❌ Permission Denied. Skipping song load.");
        _isFetching = false;
        return;
      }

      final fetchSongs = await audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final prefs = await SharedPreferences.getInstance();
      final blockedIds = prefs.getStringList('blocked_song_ids') ?? [];

      // ✅ Load metadata from PERMANENT SQLite database (survives reinstall & offline)
      await _metadataDb.initialize();
      final permanentMetadataMap = await _metadataDb.getMetadataMap();
      debugPrint(
        '📦 Loaded ${permanentMetadataMap.length ~/ 2} permanent metadata records',
      );

      // Fallback: Also load from SharedPreferences (legacy support)
      Map<String, String> artistMap = {};
      Map<String, String> artworkMap = {};
      final recentData = prefs.getString('recent_downloads');

      if (recentData != null) {
        try {
          final List<dynamic> decoded = jsonDecode(recentData);
          for (var item in decoded) {
            final filePath = item['filePath'];
            final meta = item['metadata'];
            if (filePath != null && meta != null) {
              if (meta['artist'] != null) artistMap[filePath] = meta['artist'];
              if (meta['thumbnail'] != null)
                artworkMap[filePath] = meta['thumbnail'];
            }
          }
        } catch (e) {
          debugPrint("Error parsing recent metadata: $e");
        }
      }

      songs
          .value = fetchSongs.where((s) => !blockedIds.contains(s.id.toString())).map((
        s,
      ) {
        bool isFromMyApp =
            s.data.contains("LumenLyric") || s.data.contains("MyMusicApp");
        String songUri = s.uri ?? s.data;
        String displayTitle = s.title;
        String displayArtist = s.artist ?? "Unknown Artist";
        String? customArt;

        // ✅ PRIORITY 1: Check permanent SQLite database (ONLY for downloaded songs)
        // Only apply downloaded metadata to songs from our app's folder
        final fileName = path.basename(s.data);
        PersistentSongMetadata? permMeta;

        if (isFromMyApp) {
          // First try exact file path match
          permMeta = permanentMetadataMap[s.data];

          // Only try fileName match if it's a unique match and song is from our app
          if (permMeta == null) {
            final fileNameMeta = permanentMetadataMap[fileName];
            // Verify the matched metadata is actually for this song's location
            if (fileNameMeta != null &&
                fileNameMeta.filePath.contains('LumenLyric')) {
              permMeta = fileNameMeta;
            }
          }
        }

        if (permMeta != null) {
          // Use permanent metadata (works offline and after reinstall)
          displayTitle = permMeta.title;
          displayArtist = permMeta.artist;
          // Prefer local artwork path (offline-first)
          if (permMeta.artworkPath != null &&
              File(permMeta.artworkPath!).existsSync()) {
            customArt = permMeta.artworkPath;
          } else if (permMeta.artworkUrl != null &&
              permMeta.artworkUrl!.isNotEmpty) {
            customArt = permMeta.artworkUrl;
          }
          debugPrint('✅ Using permanent metadata for: $displayTitle');
        } else if (isFromMyApp) {
          // ✅ PRIORITY 2: Check SharedPreferences (legacy fallback) - ONLY for our app's songs
          String customTitleKey = 'custom_title_${s.id}';
          if (prefs.containsKey(customTitleKey)) {
            displayTitle = prefs.getString(customTitleKey) ?? s.title;
          }

          if (artistMap.containsKey(s.data)) {
            displayArtist = artistMap[s.data]!;
          }

          if (artworkMap.containsKey(s.data)) {
            customArt = artworkMap[s.data];
          }
        }

        if (displayArtist == "<unknown>") displayArtist = "Unknown Artist";

        return LocalSongModel(
          id: s.id,
          artist: displayArtist,
          title: displayTitle,
          uri: songUri,
          albumArt: s.album ?? "",
          duration: s.duration ?? 0,
          isDownloaded: isFromMyApp,
          isLiked: false,
          artworkUrl: customArt,
        );
      }).toList();

      await _restoreLikes();
    } catch (e) {
      debugPrint("Error loading songs: $e");
    } finally {
      _isFetching = false;
    }
  }

  Uri _buildUri(String uri) {
    if (uri.startsWith("content://")) return Uri.parse(uri);
    if (uri.startsWith("/storage") || uri.startsWith("/sdcard"))
      return Uri.file(uri);
    return Uri.parse(uri);
  }

  // ✅ Helper to create AudioSource with Notification Data
  AudioSource _createAudioSource(LocalSongModel song) {
    Uri audioUri = _buildUri(song.uri);
    Uri? artworkUri;
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      if (song.artworkUrl!.startsWith('http')) {
        artworkUri = Uri.parse(song.artworkUrl!);
      } else {
        artworkUri = Uri.file(song.artworkUrl!);
      }
    }

    return AudioSource.uri(
      audioUri,
      tag: MediaItem(
        id: song.id.toString(),
        album: "LumenLyric",
        title: song.title,
        artist: song.artist,
        artUri: artworkUri,
      ),
    );
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

  // ✅ Play a song from the main list (Resets Ghosting Flag)
  Future<void> playSong(int index) async {
    _isPlayerDismissed = false; // Reset
    if (index < 0 || index >= songs.value.length) return;

    _isPlayingFromQueue = false;
    playbackQueue.value = [];
    queueIndex.value = -1;
    currentIndex.value = index;

    try {
      final playlist = ConcatenatingAudioSource(
        children: songs.value.map((s) => _createAudioSource(s)).toList(),
      );
      await audioPlayer.setAudioSource(playlist, initialIndex: index);
      await audioPlayer.play();
    } catch (e) {
      print("Error Playing: $e");
    }
  }

  // ✅ Play from a specific playlist (Resets Ghosting Flag)
  Future<void> playFromPlaylist(
    List<LocalSongModel> playlistSongs,
    int index,
  ) async {
    _isPlayerDismissed = false; // Reset
    if (index < 0 || index >= playlistSongs.length) return;

    _isPlayingFromQueue = true;
    playbackQueue.value = playlistSongs;
    queueIndex.value = index;
    currentIndex.value = index;

    try {
      final playlist = ConcatenatingAudioSource(
        children: playlistSongs.map((s) => _createAudioSource(s)).toList(),
      );
      await audioPlayer.setAudioSource(playlist, initialIndex: index);
      await audioPlayer.play();
    } catch (e) {
      print("Error Playing Playlist: $e");
    }
  }

  // ✅ NEW: Call this to close player and prevent ghosting
  Future<void> closePlayer() async {
    _isPlayerDismissed = true; // Block stream updates
    await audioPlayer.stop();

    // Clear State
    currentIndex.value = -1;
    queueIndex.value = -1;
    isPlaying.value = false;
    currentLyrics.value = "No Lyrics";
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
    if (isPlaying.value) {
      await pauseSong();
    } else {
      await resumeSong();
    }
  }

  // ✅ Uses player's built-in seekToNext (Works in Background)
  Future<void> nextSong() async {
    if (audioPlayer.hasNext) {
      await audioPlayer.seekToNext();
    } else {
      await audioPlayer.stop();
    }
  }

  // ✅ Uses player's built-in seekToPrevious (Works in Background)
  Future<void> previousSong() async {
    if (audioPlayer.hasPrevious) {
      await audioPlayer.seekToPrevious();
    } else {
      await audioPlayer.seek(Duration.zero); // Restart song if no prev
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

  Future<void> deleteSong(int songId, String filePath) async {
    bool deleted = false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        deleted = true;
      } else {
        deleted = true;
      }
    } catch (e) {
      print("Error deleting song: $e");
      deleted = true;
    }

    if (deleted) {
      final prefs = await SharedPreferences.getInstance();
      List<String> blockedIds = prefs.getStringList('blocked_song_ids') ?? [];

      if (!blockedIds.contains(songId.toString())) {
        blockedIds.add(songId.toString());
        await prefs.setStringList('blocked_song_ids', blockedIds);
      }

      songs.value = songs.value.where((song) => song.id != songId).toList();

      if (currentsong?.id == songId) {
        // ✅ Use closePlayer safely
        await closePlayer();
      }
      _saveLikesToPrefs();
    }
  }

  Future<void> renameSong(int songId, String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_title_$songId', newTitle);
    final index = songs.value.indexWhere((s) => s.id == songId);
    if (index != -1) {
      final updatedList = List<LocalSongModel>.from(songs.value);
      updatedList[index] = updatedList[index].copyWith(title: newTitle);
      songs.value = updatedList;
    }
  }
  // lib/controller/audio_controller.dart ke andar

  Future<void> playNetworkAudio(String url, Online.SongModel songMeta) async {
    // Player reset logic (Ghosting prevent karne ke liye)
    _isPlayerDismissed = false;
    _isPlayingFromQueue = false;
    playbackQueue.value = [];
    queueIndex.value = -1;
    currentIndex.value =
        -1; // Online song ka koi index nahi hota local list mein

    try {
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
        'Referer': 'https://www.youtube.com/',
      };
      // 1. Create Audio Source with Metadata
      final audioSource = AudioSource.uri(
        Uri.parse(url),
        headers: headers,
        tag: MediaItem(
          // Online.SongModel ki ID String hai, isliye toString() ki zaroorat nahi
          id: songMeta.id,
          album: "Online Stream",
          title: songMeta.title,
          artist: songMeta.genre, // Artist name humne genre mein store kiya tha
          artUri: Uri.parse(songMeta.imageUrl), // Ab ye error nahi dega
        ),
      );

      // 2. Load and Play
      // Loading state show karne ke liye
      currentLyrics.value = "Fetching Audio...";

      await audioPlayer.setAudioSource(audioSource);
      await audioPlayer.play();

      // Update UI Flags
      isPlaying.value = true;
      currentLyrics.value = "Playing Online";
    } catch (e) {
      debugPrint("❌ Error Playing Network Audio: $e");
      isPlaying.value = false;
    }
  }

  void dispose() {
    audioPlayer.dispose();
  }
}
