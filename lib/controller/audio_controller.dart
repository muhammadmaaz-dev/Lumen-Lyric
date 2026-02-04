import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/services/id3_tag_service.dart'; // ✅ ID3 Tag Reading - SINGLE SOURCE OF TRUTH
import 'package:musicapp/services/metadata_database_service.dart'; // ✅ Database fallback for display
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:musicapp/models/song_model.dart' as online;
import 'package:path/path.dart' as path;

/// ═══════════════════════════════════════════════════════════════════════════
/// AUDIO CONTROLLER
/// ═══════════════════════════════════════════════════════════════════════════
///
/// METADATA INVARIANT: ID3 tags embedded in MP3 files are the SINGLE source
/// of truth. This controller NEVER rewrites metadata - it only READS from
/// the files themselves.
/// ═══════════════════════════════════════════════════════════════════════════
class AudioController {
  static final AudioController instance = AudioController._instance();
  factory AudioController() => instance;
  AudioController._instance() {
    _setupAudioPlayer();
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery(); // ONLY for file discovery
  final FlutterAudioTagger _tagger = FlutterAudioTagger();
  final Id3TagService _id3Service =
      Id3TagService.instance; // SINGLE SOURCE OF TRUTH
  final MetadataDatabaseService _metadataDb =
      MetadataDatabaseService.instance; // Fallback for display only

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

      // ═══════════════════════════════════════════════════════════════════════
      // COLD START STABILIZATION - CRITICAL FOR REINSTALL METADATA RECOVERY
      // ═══════════════════════════════════════════════════════════════════════
      // After reinstall, MediaStore may report files before the filesystem
      // is fully stable. The ID3 tag library may fail to read tags if we
      // query too early. This delay allows Android's filesystem to stabilize.
      if (!_id3Service.isInitialScanComplete) {
        debugPrint(
          '🔄 [STARTUP] Cold start detected, waiting for filesystem to stabilize...',
        );
        // Longer delay on cold start to ensure files are fully accessible
        await Future.delayed(const Duration(milliseconds: 800));
        debugPrint(
          '🔄 [STARTUP] Filesystem stabilization complete, beginning ID3 scan...',
        );
      }

      // ═══════════════════════════════════════════════════════════════════════
      // MEDIASTORE: USED ONLY FOR FILE DISCOVERY - NEVER FOR METADATA
      // ═══════════════════════════════════════════════════════════════════════
      final fetchSongs = await audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final prefs = await SharedPreferences.getInstance();
      final blockedIds = prefs.getStringList('blocked_song_ids') ?? [];

      final loadedSongs = <LocalSongModel>[];

      for (final s in fetchSongs) {
        if (blockedIds.contains(s.id.toString())) continue;

        final bool isFromMyApp = _id3Service.isLumenLyricFile(s.data);
        final String songUri = s.uri ?? s.data;

        // ═══════════════════════════════════════════════════════════════════════
        // METADATA RESOLUTION - ID3 TAGS ARE THE SINGLE SOURCE OF TRUTH
        // ═══════════════════════════════════════════════════════════════════════
        //
        // INVARIANTS:
        // 1. Every MP3 is an independent, self-describing object
        // 2. ID3 tags embedded in MP3 are the ONLY source of truth
        // 3. This code NEVER rewrites metadata - it only READS
        // 4. No filename, MediaStore ID, list index, or download order is identity
        // 5. If ID3 tags are missing, check database fallback for display only
        // ═══════════════════════════════════════════════════════════════════════

        String displayTitle;
        String displayArtist;
        String? customArt;

        if (isFromMyApp) {
          // READ ID3 TAGS (or sidecar .meta.json) - THE ONLY AUTHORITATIVE SOURCE
          var id3Metadata = await _id3Service.readMetadataFromFile(s.data);

          // ═══════════════════════════════════════════════════════════════════════
          // MIGRATION: If no metadata found, try to create sidecar from filename
          // ═══════════════════════════════════════════════════════════════════════
          // This handles existing songs that were downloaded before sidecar support
          if (id3Metadata == null || !id3Metadata.hasValidMetadata) {
            final created = await _id3Service.createSidecarFromFilename(s.data);
            if (created) {
              // Re-read after creating sidecar
              id3Metadata = await _id3Service.readMetadataFromFile(s.data);
            }
          }

          if (id3Metadata != null && id3Metadata.hasValidMetadata) {
            // ✅ Metadata found - use it as the source of truth
            displayTitle = id3Metadata.displayTitle;
            displayArtist = id3Metadata.displayArtist;

            // ✅ Use artwork from ID3 metadata (includes sidecar check)
            customArt = id3Metadata.artworkPath;

            debugPrint(
              '🎵 [META] $displayTitle by $displayArtist${customArt != null ? " (artwork)" : ""}',
            );
          } else {
            // ⚠️ All metadata sources failed - try database as DISPLAY fallback
            final dbMetadata = await _metadataDb.getMetadataByPath(s.data);

            if (dbMetadata != null) {
              // Use database metadata for display
              displayTitle = dbMetadata.title;
              displayArtist = dbMetadata.artist;
              customArt = dbMetadata.artworkPath;
              debugPrint('📦 [DB] Fallback: $displayTitle by $displayArtist');
            } else {
              // No metadata anywhere - use neutral defaults
              displayTitle = 'Unknown Title';
              displayArtist = 'Unknown Artist';
              debugPrint('⚠️ [META] No metadata for: ${path.basename(s.data)}');
            }

            // Still check for sidecar artwork even if metadata is missing
            if (customArt == null) {
              final artworkPath = _id3Service.getArtworkPath(s.data);
              if (artworkPath != null && File(artworkPath).existsSync()) {
                customArt = artworkPath;
              }
            }
          }
        } else {
          // Non-LumenLyric files: use MediaStore data (system manages these)
          displayTitle = s.title;
          displayArtist = s.artist ?? 'Unknown Artist';
          if (displayArtist == '<unknown>') displayArtist = 'Unknown Artist';
        }

        loadedSongs.add(
          LocalSongModel(
            id: s.id,
            artist: displayArtist,
            title: displayTitle,
            uri: songUri,
            albumArt: s.album ?? "",
            duration: s.duration ?? 0,
            isDownloaded: isFromMyApp,
            isLiked: false,
            artworkUrl: customArt,
          ),
        );
      }

      songs.value = loadedSongs;
      await _restoreLikes();

      // ═══════════════════════════════════════════════════════════════════════
      // MARK INITIAL SCAN COMPLETE
      // ═══════════════════════════════════════════════════════════════════════
      // After first successful scan, mark as complete so future reads
      // don't use cold start retry logic unnecessarily.
      if (!_id3Service.isInitialScanComplete) {
        _id3Service.markInitialScanComplete();
      }

      debugPrint('✅ Loaded ${loadedSongs.length} songs');
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

  Future<void> playNetworkAudio(String url, online.SongModel songMeta) async {
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
