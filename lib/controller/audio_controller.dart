import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/services/id3_tag_service.dart'; // ✅ ID3 Tag Reading - SINGLE SOURCE OF TRUTH
import 'package:musicapp/services/metadata_database_service.dart'; // ✅ Database fallback for display
import 'package:musicapp/services/storage_path_service.dart'; // ✅ Centralized Storage Paths
import 'package:musicapp/services/storage_permission_service.dart'; // ✅ Version-aware permissions
import 'package:musicapp/services/song_cache_service.dart'; // ✅ Fast startup cache
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
  final SongCacheService _cacheService =
      SongCacheService.instance; // Fast startup cache

  final ValueNotifier<List<LocalSongModel>> songs =
      ValueNotifier<List<LocalSongModel>>([]);

  // ✅ Loading state for UI feedback
  final ValueNotifier<bool> isLoadingSongs = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isBackgroundScanRunning = ValueNotifier<bool>(
    false,
  );

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

  Future<void> scanMedia(String filePath) async {
    try {
      debugPrint("🔍 [SCAN] Scanning file: $filePath");

      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("⚠️ [SCAN] File does not exist: $filePath");
        return;
      }

      final fileSize = await file.length();
      debugPrint("📁 [SCAN] File size: $fileSize bytes");

      // Try to scan via MediaStore
      try {
        await audioQuery.scanMedia(filePath);
        debugPrint("✅ [SCAN] MediaStore scan requested");
      } catch (e) {
        debugPrint("⚠️ [SCAN] MediaStore scan failed: $e");
        // Continue anyway - file system will pick it up
      }

      // Wait a bit for MediaStore to index
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate cache and reload
      _cacheService.invalidateCache();
      await loadSongsFull();
    } catch (e) {
      debugPrint("❌ [SCAN] Error scanning media: $e");
    }
  }

  Future<void> scanNewMedia(String filePath) async {
    try {
      debugPrint("🎵 [SCAN] New media downloaded: $filePath");

      // Verify file exists and is valid
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("⚠️ [SCAN] Downloaded file not found: $filePath");
        return;
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        debugPrint(
          "⚠️ [SCAN] File too small, might be corrupted: $fileSize bytes",
        );
        return;
      }

      debugPrint("✅ [SCAN] File verified: $fileSize bytes");

      // Request MediaStore to scan the file
      try {
        await audioQuery.scanMedia(filePath);
        debugPrint("✅ [SCAN] MediaStore notified");
      } catch (e) {
        debugPrint("⚠️ [SCAN] MediaStore notification failed: $e");
        // This is okay on Android 10 - file system discovery will work
      }

      // Give system time to process
      await Future.delayed(const Duration(milliseconds: 300));

      // Invalidate cache since we have a new song
      _cacheService.invalidateCache();

      // Reload songs (file system discovery will find it even if MediaStore doesn't)
      await loadSongsFull();

      debugPrint("✅ [SCAN] Song list refreshed");
    } catch (e) {
      debugPrint("❌ [SCAN] Error scanning new media: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAST STARTUP - LOAD FROM CACHE INSTANTLY
  // ═══════════════════════════════════════════════════════════════════════════
  /// Load songs from cache for instant UI display.
  /// Returns true if cache was available, false if full scan needed.
  Future<bool> loadSongsFromCache() async {
    try {
      isLoadingSongs.value = true;

      final cachedSongs = await _cacheService.loadFromCache();
      if (cachedSongs != null && cachedSongs.isNotEmpty) {
        songs.value = cachedSongs;
        await _restoreLikes();
        debugPrint('⚡ [FAST] Loaded ${cachedSongs.length} songs from cache');
        isLoadingSongs.value = false;
        return true;
      }

      isLoadingSongs.value = false;
      return false;
    } catch (e) {
      debugPrint('⚠️ [CACHE] Error loading from cache: $e');
      isLoadingSongs.value = false;
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND SCAN - FULL MEDIASTORE + METADATA RESOLUTION
  // ═══════════════════════════════════════════════════════════════════════════
  /// Run full MediaStore scan in background without blocking UI.
  /// Updates song list when complete and saves to cache.
  Future<void> loadSongsInBackground() async {
    if (_isFetching) return;

    isBackgroundScanRunning.value = true;
    debugPrint('🔄 [BACKGROUND] Starting MediaStore scan...');

    // Run the full scan
    await loadSongsFull();

    // Save to cache for next startup
    if (songs.value.isNotEmpty) {
      await _cacheService.saveToCache(songs.value);
    }

    isBackgroundScanRunning.value = false;
    debugPrint('✅ [BACKGROUND] Scan complete, cache updated');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAZY METADATA RESOLUTION - ON-DEMAND FOR VISIBLE SONGS
  // ═══════════════════════════════════════════════════════════════════════════
  /// Resolve metadata for a specific song (called when song becomes visible).
  /// Returns updated song model with resolved metadata and artwork.
  Future<LocalSongModel> resolveMetadataForSong(LocalSongModel song) async {
    // Skip if not a LumenLyric file or already has good metadata
    if (!song.isDownloaded) return song;
    if (song.title != 'Unknown Title' && song.artworkUrl != null) return song;

    try {
      final id3Metadata = await _id3Service.readMetadataFromFile(song.uri);

      if (id3Metadata != null && id3Metadata.hasValidMetadata) {
        return song.copyWith(
          title: id3Metadata.displayTitle,
          artist: id3Metadata.displayArtist,
          artworkUrl: id3Metadata.artworkPath,
        );
      }

      // Try database fallback
      final dbMetadata = await _metadataDb.getMetadataByPath(song.uri);
      if (dbMetadata != null) {
        return song.copyWith(
          title: dbMetadata.title,
          artist: dbMetadata.artist,
          artworkUrl: dbMetadata.artworkPath,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [LAZY] Error resolving metadata: $e');
    }

    return song;
  }

  /// Resolve artwork only for a song (lighter than full metadata)
  Future<String?> resolveArtworkForSong(LocalSongModel song) async {
    if (song.artworkUrl != null) return song.artworkUrl;
    if (!song.isDownloaded) return null;

    try {
      return await _id3Service.findArtworkPath(song.uri);
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY SUPPORT - FULL LOAD (for refresh, new downloads, etc.)
  // ═══════════════════════════════════════════════════════════════════════════
  /// Full song loading with MediaStore scan and metadata resolution.
  /// Use loadSongsFromCache() + loadSongsInBackground() for fast startup.
  Future<void> loadSongsFull() async {
    if (_isFetching) return;
    _isFetching = true;
    isLoadingSongs.value = true; // Loading start

    try {
      if (!await _checkPermission()) {
        debugPrint('❌ [LOAD] Permission denied');
        _isFetching = false;
        isLoadingSongs.value = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final blockedIds = prefs.getStringList('blocked_song_ids') ?? [];

      List<LocalSongModel> initialSongs = [];
      Set<String> loadedPaths = {};

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 1: LOAD FROM FILE SYSTEM FIRST (MOST RELIABLE ON ALL ANDROID VERSIONS)
      // ═══════════════════════════════════════════════════════════════════════
      // This is critical for Android 10-12 where MediaStore may not index files
      debugPrint('🔍 [LOAD] Step 1: Scanning file system...');
      final directFiles = await _fetchFileSystemSongs();

      for (final file in directFiles) {
        if (!loadedPaths.contains(file.path)) {
          int tempId = file.path.hashCode;
          if (tempId > 0)
            tempId = -tempId; // Use negative IDs for file system songs

          initialSongs.add(
            LocalSongModel(
              id: tempId,
              title: path.basenameWithoutExtension(file.path),
              artist: "LumenLyric",
              uri: file.path,
              duration: 0,
              albumArt: "",
              isDownloaded: true,
              isLiked: false,
            ),
          );
          loadedPaths.add(file.path);
        }
      }

      debugPrint(
        '✅ [LOAD] Found ${initialSongs.length} songs from file system',
      );

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 2: ALSO CHECK MEDIASTORE (FOR OTHER MUSIC ON DEVICE)
      // ═══════════════════════════════════════════════════════════════════════
      debugPrint('🔍 [LOAD] Step 2: Querying MediaStore...');
      try {
        final systemSongs = await audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );

        for (final s in systemSongs) {
          if (blockedIds.contains(s.id.toString())) continue;
          if (loadedPaths.contains(s.data)) continue; // Skip duplicates

          initialSongs.add(
            LocalSongModel(
              id: s.id,
              title: s.title,
              artist: s.artist ?? "Unknown Artist",
              uri: s.data,
              duration: s.duration ?? 0,
              albumArt: s.album ?? "",
              isDownloaded: _id3Service.isLumenLyricFile(s.data),
              isLiked: false,
            ),
          );
          loadedPaths.add(s.data);
        }

        debugPrint(
          '✅ [LOAD] Total songs after MediaStore: ${initialSongs.length}',
        );
      } catch (e) {
        debugPrint('⚠️ [LOAD] MediaStore query failed: $e');
        // Continue with file system results only
      }

      // ✅ UI UPDATE: List FORAN show kar dein (0 Delay)
      songs.value = initialSongs;
      await _restoreLikes();
      isLoadingSongs.value = false; // Loading khatam! User khush.
      _isFetching = false;

      // 4. Ab Background mein Metadata Load karein (Images/Tags)
      _updateMetadataInBackground(songs.value);
    } catch (e) {
      debugPrint("❌ [LOAD] Error loading songs: $e");
      _isFetching = false;
      isLoadingSongs.value = false;
    }
  }

  Future<void> _updateMetadataInBackground(
    List<LocalSongModel> currentSongs,
  ) async {
    List<LocalSongModel> updatedList = List.from(currentSongs);
    bool listChanged = false;
    int processedCount = 0;

    debugPrint(
      '🔄 [METADATA] Starting background metadata update for ${currentSongs.length} songs',
    );
    final startTime = DateTime.now();

    // Process songs in parallel batches for faster loading
    const batchSize = 5; // Process 5 songs at a time

    for (int i = 0; i < updatedList.length; i += batchSize) {
      final batchEnd = (i + batchSize).clamp(0, updatedList.length);
      final batch = <Future<MapEntry<int, LocalSongModel>>>[];

      for (int j = i; j < batchEnd; j++) {
        final song = updatedList[j];

        // Only process downloaded songs (LumenLyric files)
        if (song.isDownloaded) {
          batch.add(
            _processSongModelFast(
              id: song.id,
              title: song.title,
              artist: song.artist,
              data: song.uri,
              duration: song.duration,
              album: song.albumArt,
              isLiked: song.isLiked,
            ).then((processed) => MapEntry(j, processed)),
          );
        }
      }

      if (batch.isNotEmpty) {
        // Wait for batch to complete
        final results = await Future.wait(batch);

        for (final entry in results) {
          final j = entry.key;
          final processed = entry.value;
          final song = updatedList[j];

          // Check if metadata actually changed
          if (processed.title != song.title ||
              processed.artworkUrl != song.artworkUrl ||
              processed.artist != song.artist) {
            updatedList[j] = processed;
            listChanged = true;
            processedCount++;
          }
        }

        // Update UI every batch
        if (listChanged) {
          songs.value = List.from(updatedList);
          listChanged = false;
        }

        // Small break to keep UI responsive (reduced from 50ms)
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    // Final update
    if (listChanged) {
      songs.value = updatedList;
    }

    final duration = DateTime.now().difference(startTime);
    debugPrint(
      '✅ [METADATA] Completed in ${duration.inMilliseconds}ms, updated $processedCount songs',
    );

    // Mark initial scan complete for ID3 service
    _id3Service.markInitialScanComplete();
  }

  /// Fast version of _processSongModel that uses database first
  Future<LocalSongModel> _processSongModelFast({
    required int id,
    required String title,
    String? artist,
    required String data,
    int? duration,
    String? album,
    required bool isLiked,
  }) async {
    final bool isFromMyApp = _id3Service.isLumenLyricFile(data);
    String displayTitle = title;
    String displayArtist = artist ?? 'Unknown Artist';
    if (displayArtist == '<unknown>') displayArtist = 'Unknown Artist';
    String? customArt;
    int? resolvedDuration = duration;

    if (isFromMyApp) {
      // Priority 1: Database Metadata (FASTEST - no file I/O)
      final dbMetadata = await _metadataDb.getMetadataByPath(data);
      if (dbMetadata != null) {
        displayTitle = dbMetadata.title;
        displayArtist = dbMetadata.artist;
        customArt = dbMetadata.artworkPath;

        // ✅ Use duration from database if available (fixes Android <13 issue)
        if (dbMetadata.duration != null && dbMetadata.duration! > 0) {
          resolvedDuration = dbMetadata.duration;
        }

        // If artwork path exists, verify file still exists
        if (customArt != null && !await File(customArt).exists()) {
          customArt = null;
        }
      }
      // Priority 2: Sidecar JSON (fast file read)
      else {
        final sidecarMeta = await _id3Service.readMetadataFromSidecar(data);
        if (sidecarMeta != null && sidecarMeta.hasValidMetadata) {
          displayTitle = sidecarMeta.displayTitle;
          displayArtist = sidecarMeta.displayArtist;
          customArt = sidecarMeta.artworkPath;
        }
        // Priority 3: ID3 Tags (slower - reads from MP3 file)
        else {
          final id3Metadata = await _id3Service.readMetadataFromFile(data);
          if (id3Metadata != null && id3Metadata.hasValidMetadata) {
            displayTitle = id3Metadata.displayTitle;
            displayArtist = id3Metadata.displayArtist;
            customArt = id3Metadata.artworkPath;
          }
        }
      }

      // If no artwork found in metadata, check artwork folder directly
      if (customArt == null) {
        customArt = await _id3Service.findArtworkPath(data);
      }
    }

    return LocalSongModel(
      id: id,
      artist: displayArtist,
      title: displayTitle,
      uri: data,
      albumArt: album ?? "",
      duration: resolvedDuration ?? 0,
      isDownloaded: isFromMyApp,
      isLiked: isLiked,
      artworkUrl: customArt,
    );
  }

  Future<List<File>> _fetchFileSystemSongs() async {
    List<File> audioFiles = [];
    try {
      final songsPath = await StoragePathService.instance.songsPath;
      final dir = Directory(songsPath);

      debugPrint('🔍 [FILESYSTEM] Scanning directory: $songsPath');

      if (await dir.exists()) {
        final files = dir.listSync();
        for (var file in files) {
          if (file is File && file.path.toLowerCase().endsWith('.mp3')) {
            // Verify file is readable and has content
            try {
              final fileLength = await file.length();
              if (fileLength > 0) {
                audioFiles.add(file);
                debugPrint(
                  '🎵 [FILESYSTEM] Found: ${path.basename(file.path)} (${fileLength} bytes)',
                );
              }
            } catch (e) {
              debugPrint('⚠️ [FILESYSTEM] Cannot read file: ${file.path}');
            }
          }
        }
      } else {
        debugPrint(
          '⚠️ [FILESYSTEM] Songs directory does not exist: $songsPath',
        );
        // Try to create it
        await dir.create(recursive: true);
      }

      // Also check legacy location (root LumenLyric folder)
      final basePath = await StoragePathService.instance.basePath;
      final baseDir = Directory(basePath);
      if (await baseDir.exists()) {
        final baseFiles = baseDir.listSync();
        for (var file in baseFiles) {
          if (file is File && file.path.toLowerCase().endsWith('.mp3')) {
            // Don't add duplicates
            if (!audioFiles.any((f) => f.path == file.path)) {
              try {
                final fileLength = await file.length();
                if (fileLength > 0) {
                  audioFiles.add(file);
                  debugPrint(
                    '🎵 [FILESYSTEM] Found (legacy): ${path.basename(file.path)}',
                  );
                }
              } catch (e) {
                // Ignore unreadable files
              }
            }
          }
        }
      }

      debugPrint('✅ [FILESYSTEM] Found ${audioFiles.length} audio files');
    } catch (e) {
      debugPrint("❌ [FILESYSTEM] Error: $e");
    }
    return audioFiles;
  }

  // Helper: Process Metadata for both System and File songs
  Future<LocalSongModel> _processSongModel({
    required int id,
    required String title,
    String? artist,
    required String data,
    int? duration,
    String? album,
  }) async {
    final bool isFromMyApp = _id3Service.isLumenLyricFile(data);
    String displayTitle = title;
    String displayArtist = artist ?? 'Unknown Artist';
    if (displayArtist == '<unknown>') displayArtist = 'Unknown Artist';
    String? customArt;

    if (isFromMyApp) {
      // Priority 1: Sidecar/DB Metadata (Fastest)
      final dbMetadata = await _metadataDb.getMetadataByPath(data);
      if (dbMetadata != null) {
        displayTitle = dbMetadata.title;
        displayArtist = dbMetadata.artist;
        customArt = dbMetadata.artworkPath;
      }
      // Priority 2: ID3 Tags (If DB missing)
      else {
        final id3Metadata = await _id3Service.readMetadataFromFile(data);
        if (id3Metadata != null && id3Metadata.hasValidMetadata) {
          displayTitle = id3Metadata.displayTitle;
          displayArtist = id3Metadata.displayArtist;
          customArt = id3Metadata.artworkPath;
        }
      }
    }

    return LocalSongModel(
      id: id,
      artist: displayArtist,
      title: displayTitle,
      uri: data,
      albumArt: album ?? "",
      duration: duration ?? 0,
      isDownloaded: isFromMyApp,
      isLiked: false,
      artworkUrl: customArt,
    );
  }

  Future<bool> _checkPermission() async {
    // Check Android version to determine which permissions to request
    final sdk = await StoragePermissionService.instance.androidSdkVersion;

    if (sdk >= 33) {
      // Android 13+ - Need audio permission
      if (await Permission.audio.isGranted) {
        return true;
      }
      final status = await Permission.audio.request();
      return status.isGranted;
    } else {
      // Android 12 and below - Need storage permission
      if (await Permission.storage.isGranted) {
        return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Alias for backward compatibility
  Future<void> loadSongs() async {
    await loadSongsFull();
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
    debugPrint('🎵 [AUDIO] Creating source for: ${song.title}');
    debugPrint('🎵 [AUDIO] URI: ${song.uri} -> $audioUri');

    Uri? artworkUri;
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      if (song.artworkUrl!.startsWith('http')) {
        artworkUri = Uri.parse(song.artworkUrl!);
      } else {
        artworkUri = Uri.file(song.artworkUrl!);
      }
      debugPrint('🎨 [AUDIO] Artwork: $artworkUri');
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
      final newStatus = !newList[index].isLiked; // Toggle status

      newList[index] = newList[index].copyWith(isLiked: newStatus);
      songs.value = newList;

      await _saveLikesToPrefs();
    }
  }

  Future<void> _saveLikesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final likedPaths = songs.value
        .where((s) => s.isLiked)
        .map((s) => s.uri)
        .toList();

    await prefs.setStringList('liked_song_paths', likedPaths);
  }

  Future<void> _restoreLikes() async {
    final prefs = await SharedPreferences.getInstance();

    // Nayi key 'liked_song_paths' se load karo
    final likedPaths = prefs.getStringList('liked_song_paths') ?? [];

    // Purani key 'liked_songs' ka backup check (Migration ke liye)
    final legacyIds = prefs.getStringList('liked_songs') ?? [];

    if (songs.value.isNotEmpty) {
      final newList = List<LocalSongModel>.from(songs.value);
      bool changed = false;

      for (int i = 0; i < newList.length; i++) {
        final song = newList[i];

        // Check 1: Agar Path match ho jaye (New Logic)
        if (likedPaths.contains(song.uri)) {
          newList[i] = song.copyWith(isLiked: true);
          changed = true;
        }
        // Check 2: Agar purana ID match ho jaye (Legacy Logic - sirf System songs ke liye)
        else if (legacyIds.contains(song.id.toString())) {
          newList[i] = song.copyWith(isLiked: true);
          changed = true;
          // Purane like ko naye system mein convert karne ke liye save trigger karein
          Future.delayed(Duration(seconds: 1), _saveLikesToPrefs);
        }
      }

      if (changed) {
        songs.value = newList;
      }
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
