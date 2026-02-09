import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/services/id3_tag_service.dart';
import 'package:musicapp/services/metadata_database_service.dart';
import 'package:musicapp/services/storage_path_service.dart';
import 'package:musicapp/services/storage_permission_service.dart';
import 'package:musicapp/services/song_cache_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:musicapp/models/song_model.dart' as online;
import 'package:path/path.dart' as path;

class AudioController {
  static final AudioController instance = AudioController._instance();
  factory AudioController() => instance;
  AudioController._instance() {
    _setupAudioPlayer();
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();
  final FlutterAudioTagger _tagger = FlutterAudioTagger();
  final Id3TagService _id3Service = Id3TagService.instance;
  final MetadataDatabaseService _metadataDb = MetadataDatabaseService.instance;
  final SongCacheService _cacheService = SongCacheService.instance;

  final ValueNotifier<List<LocalSongModel>> songs =
      ValueNotifier<List<LocalSongModel>>([]);

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
  final ValueNotifier<String?> currentLrcContent = ValueNotifier<String?>(null);
  final ValueNotifier<String> currentLyrics = ValueNotifier<String>(
    "No Lyrics",
  );

  bool _isFetching = false;

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
    audioPlayer.playerStateStream.listen((playerState) {
      isPlaying.value = playerState.playing;

      if (playerState.processingState == ProcessingState.completed) {
        isPlaying.value = false;
      }
    });

    audioPlayer.currentIndexStream.listen((index) {
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
      final file = File(filePath);
      if (!await file.exists()) {
        return;
      }

      try {
        await audioQuery.scanMedia(filePath);
      } catch (e) {
        // Continue anyway - file system will pick it up
      }

      await Future.delayed(const Duration(milliseconds: 500));

      _cacheService.invalidateCache();
      await loadSongsFull();
    } catch (e) {
      // Error scanning media
    }
  }

  Future<void> scanNewMedia(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return;
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        return;
      }

      try {
        await audioQuery.scanMedia(filePath);
      } catch (e) {
        // File system discovery will work
      }

      await Future.delayed(const Duration(milliseconds: 300));

      _cacheService.invalidateCache();
      await loadSongsFull();
    } catch (e) {
      // Error scanning new media
    }
  }

  Future<bool> loadSongsFromCache() async {
    try {
      isLoadingSongs.value = true;

      final cachedSongs = await _cacheService.loadFromCache();
      if (cachedSongs != null && cachedSongs.isNotEmpty) {
        songs.value = cachedSongs;
        await _restoreLikes();
        isLoadingSongs.value = false;
        return true;
      }

      isLoadingSongs.value = false;
      return false;
    } catch (e) {
      isLoadingSongs.value = false;
      return false;
    }
  }

  Future<void> loadSongsInBackground() async {
    if (_isFetching) return;

    isBackgroundScanRunning.value = true;

    await loadSongsFull();

    if (songs.value.isNotEmpty) {
      await _cacheService.saveToCache(songs.value);
    }

    isBackgroundScanRunning.value = false;
  }

  Future<LocalSongModel> resolveMetadataForSong(LocalSongModel song) async {
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

      final dbMetadata = await _metadataDb.getMetadataByPath(song.uri);
      if (dbMetadata != null) {
        return song.copyWith(
          title: dbMetadata.title,
          artist: dbMetadata.artist,
          artworkUrl: dbMetadata.artworkPath,
        );
      }
    } catch (e) {
      // Error resolving metadata
    }

    return song;
  }

  Future<String?> resolveArtworkForSong(LocalSongModel song) async {
    if (song.artworkUrl != null) return song.artworkUrl;
    if (!song.isDownloaded) return null;

    try {
      return await _id3Service.findArtworkPath(song.uri);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadSongsFull() async {
    if (_isFetching) return;
    _isFetching = true;
    isLoadingSongs.value = true;

    try {
      if (!await _checkPermission()) {
        _isFetching = false;
        isLoadingSongs.value = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final blockedIds = prefs.getStringList('blocked_song_ids') ?? [];

      List<LocalSongModel> initialSongs = [];
      Set<String> loadedPaths = {};

      final directFiles = await _fetchFileSystemSongs();

      for (final file in directFiles) {
        if (!loadedPaths.contains(file.path)) {
          int tempId = file.path.hashCode;
          if (tempId > 0) tempId = -tempId;

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
      } catch (e) {
        // Continue with file system results only
      }

      songs.value = initialSongs;
      await _restoreLikes();
      isLoadingSongs.value = false;
      _isFetching = false;

      _updateMetadataInBackground(songs.value);
    } catch (e) {
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

    const batchSize = 5;

    for (int i = 0; i < updatedList.length; i += batchSize) {
      final batchEnd = (i + batchSize).clamp(0, updatedList.length);
      final batch = <Future<MapEntry<int, LocalSongModel>>>[];

      for (int j = i; j < batchEnd; j++) {
        final song = updatedList[j];

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
        final results = await Future.wait(batch);

        for (final entry in results) {
          final j = entry.key;
          final processed = entry.value;
          final song = updatedList[j];

          if (processed.title != song.title ||
              processed.artworkUrl != song.artworkUrl ||
              processed.artist != song.artist) {
            updatedList[j] = processed;
            listChanged = true;
            processedCount++;
          }
        }

        if (listChanged) {
          songs.value = List.from(updatedList);
          listChanged = false;
        }

        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    if (listChanged) {
      songs.value = updatedList;
    }

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
      final dbMetadata = await _metadataDb.getMetadataByPath(data);
      if (dbMetadata != null) {
        displayTitle = dbMetadata.title;
        displayArtist = dbMetadata.artist;
        customArt = dbMetadata.artworkPath;

        if (dbMetadata.duration != null && dbMetadata.duration! > 0) {
          resolvedDuration = dbMetadata.duration;
        }

        if (customArt != null && !await File(customArt).exists()) {
          customArt = null;
        }
      } else {
        final sidecarMeta = await _id3Service.readMetadataFromSidecar(data);
        if (sidecarMeta != null && sidecarMeta.hasValidMetadata) {
          displayTitle = sidecarMeta.displayTitle;
          displayArtist = sidecarMeta.displayArtist;
          customArt = sidecarMeta.artworkPath;
        } else {
          final id3Metadata = await _id3Service.readMetadataFromFile(data);
          if (id3Metadata != null && id3Metadata.hasValidMetadata) {
            displayTitle = id3Metadata.displayTitle;
            displayArtist = id3Metadata.displayArtist;
            customArt = id3Metadata.artworkPath;
          }
        }
      }

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

      if (await dir.exists()) {
        final files = dir.listSync();
        for (var file in files) {
          if (file is File && file.path.toLowerCase().endsWith('.mp3')) {
            try {
              final fileLength = await file.length();
              if (fileLength > 0) {
                audioFiles.add(file);
              }
            } catch (e) {
              // Cannot read file
            }
          }
        }
      } else {
        await dir.create(recursive: true);
      }

      final basePath = await StoragePathService.instance.basePath;
      final baseDir = Directory(basePath);
      if (await baseDir.exists()) {
        final baseFiles = baseDir.listSync();
        for (var file in baseFiles) {
          if (file is File && file.path.toLowerCase().endsWith('.mp3')) {
            if (!audioFiles.any((f) => f.path == file.path)) {
              try {
                final fileLength = await file.length();
                if (fileLength > 0) {
                  audioFiles.add(file);
                }
              } catch (e) {
                // Ignore unreadable files
              }
            }
          }
        }
      }
    } catch (e) {
      // Error scanning filesystem
    }
    return audioFiles;
  }

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
      final dbMetadata = await _metadataDb.getMetadataByPath(data);
      if (dbMetadata != null) {
        displayTitle = dbMetadata.title;
        displayArtist = dbMetadata.artist;
        customArt = dbMetadata.artworkPath;
      } else {
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
    final sdk = await StoragePermissionService.instance.androidSdkVersion;

    if (sdk >= 33) {
      if (await Permission.audio.isGranted) {
        return true;
      }
      final status = await Permission.audio.request();
      return status.isGranted;
    } else {
      if (await Permission.storage.isGranted) {
        return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> loadSongs() async {
    await loadSongsFull();
  }

  Uri _buildUri(String uri) {
    if (uri.startsWith("content://")) return Uri.parse(uri);
    if (uri.startsWith("/storage") || uri.startsWith("/sdcard"))
      return Uri.file(uri);
    return Uri.parse(uri);
  }

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

    final likedPaths = prefs.getStringList('liked_song_paths') ?? [];
    final legacyIds = prefs.getStringList('liked_songs') ?? [];

    if (songs.value.isNotEmpty) {
      final newList = List<LocalSongModel>.from(songs.value);
      bool changed = false;

      for (int i = 0; i < newList.length; i++) {
        final song = newList[i];

        if (likedPaths.contains(song.uri)) {
          newList[i] = song.copyWith(isLiked: true);
          changed = true;
        } else if (legacyIds.contains(song.id.toString())) {
          newList[i] = song.copyWith(isLiked: true);
          changed = true;
          Future.delayed(const Duration(seconds: 1), _saveLikesToPrefs);
        }
      }

      if (changed) {
        songs.value = newList;
      }
    }
  }

  Future<void> playSong(int index) async {
    _isPlayerDismissed = false;
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
      // Error playing
    }
  }

  Future<void> playFromPlaylist(
    List<LocalSongModel> playlistSongs,
    int index,
  ) async {
    _isPlayerDismissed = false;
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
      // Error playing playlist
    }
  }

  Future<void> closePlayer() async {
    _isPlayerDismissed = true;
    await audioPlayer.stop();

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

  Future<void> nextSong() async {
    if (audioPlayer.hasNext) {
      await audioPlayer.seekToNext();
    } else {
      await audioPlayer.stop();
    }
  }

  Future<void> previousSong() async {
    if (audioPlayer.hasPrevious) {
      await audioPlayer.seekToPrevious();
    } else {
      await audioPlayer.seek(Duration.zero);
    }
  }

  void clearQueue() {
    _isPlayingFromQueue = false;
    playbackQueue.value = [];
    queueIndex.value = -1;
  }

  Future<void> _fetchLyrics(String path) async {
    currentLyrics.value = "Loading...";
    currentLrcContent.value = null;

    if (path.startsWith("content://")) {
      currentLyrics.value = "Cannot read lyrics from Content URI";
      return;
    }

    try {
      final lrcFile = File(
        path.replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '.lrc'),
      );

      if (await lrcFile.exists()) {
        final content = await lrcFile.readAsString();
        currentLrcContent.value = content;
        currentLyrics.value = "Synced Lyrics Available";
        return;
      }

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

  Future<void> playNetworkAudio(String url, online.SongModel songMeta) async {
    _isPlayerDismissed = false;
    _isPlayingFromQueue = false;
    playbackQueue.value = [];
    queueIndex.value = -1;
    currentIndex.value = -1;

    try {
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
        'Referer': 'https://www.youtube.com/',
      };

      final audioSource = AudioSource.uri(
        Uri.parse(url),
        headers: headers,
        tag: MediaItem(
          id: songMeta.id,
          album: "Online Stream",
          title: songMeta.title,
          artist: songMeta.genre,
          artUri: Uri.parse(songMeta.imageUrl),
        ),
      );

      currentLyrics.value = "Fetching Audio...";

      await audioPlayer.setAudioSource(audioSource);
      await audioPlayer.play();

      isPlaying.value = true;
      currentLyrics.value = "Playing Online";
    } catch (e) {
      isPlaying.value = false;
    }
  }

  void dispose() {
    audioPlayer.dispose();
  }
}
