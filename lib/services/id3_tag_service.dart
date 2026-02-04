import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:path/path.dart' as path;
import 'package:musicapp/services/storage_path_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ID3 TAG SERVICE - THE SINGLE SOURCE OF TRUTH FOR METADATA
/// ═══════════════════════════════════════════════════════════════════════════
///
/// INVARIANT: Every MP3 file is an independent, self-describing object.
///
/// NON-NEGOTIABLE RULES:
/// 1. ID3 tags embedded inside the MP3 are the ONLY source of truth
/// 2. App startup, reinstall, reboot, or rescan NEVER rewrites metadata
/// 3. No filename, MediaStore ID, list index, or download order is used as identity
/// 4. MediaStore is used ONLY for file discovery, never for metadata authority
/// 5. If ID3 tags are missing/corrupt, display neutral defaults - never repair
///
/// This permanently solves the "metadata collapse" bug where all songs
/// showed the same metadata after app reinstall.
/// ═══════════════════════════════════════════════════════════════════════════
class Id3TagService {
  static final Id3TagService instance = Id3TagService._internal();
  factory Id3TagService() => instance;
  Id3TagService._internal();

  final FlutterAudioTagger _tagger = FlutterAudioTagger();

  /// Track if initial scan has completed (for cold start detection)
  bool _initialScanComplete = false;

  /// Number of retries attempted during current scan
  int _coldStartRetryCount = 0;
  static const int _maxColdStartRetries = 3;

  /// Mark initial scan as complete - called after first loadSongs() finishes
  void markInitialScanComplete() {
    _initialScanComplete = true;
    _coldStartRetryCount = 0;
    debugPrint('✅ [ID3] Initial scan marked complete');
  }

  /// Check if initial scan is complete
  bool get isInitialScanComplete => _initialScanComplete;

  /// ─────────────────────────────────────────────────────────────────────────
  /// READ METADATA FROM MP3 FILE - THE ONLY AUTHORITATIVE SOURCE
  /// ─────────────────────────────────────────────────────────────────────────
  ///
  /// This method reads ID3 tags directly from the MP3 file.
  /// If tags are missing or corrupt, falls back to sidecar .meta.json file.
  /// NEVER attempts cross-file recovery or silent repair.
  ///
  /// COLD START HANDLING:
  /// On reinstall/cold start, file system may not be immediately stable.
  /// This method includes validation and multiple retries to ensure reliable reads.
  ///
  /// FALLBACK CHAIN:
  /// 1. Try reading ID3 tags from MP3 file (with retries)
  /// 2. If ID3 fails, try reading from .meta.json sidecar file
  /// 3. If both fail, return null (caller uses neutral defaults)
  Future<Id3Metadata?> readMetadataFromFile(String filePath) async {
    // First attempt: Read ID3 tags from the MP3 file
    final id3Metadata = await _readMetadataWithRetry(filePath, retryCount: 0);

    if (id3Metadata != null && id3Metadata.hasValidMetadata) {
      return id3Metadata;
    }

    // Fallback: Try reading from sidecar .meta.json file
    // This is critical for reinstall recovery since ID3 writing may have failed
    final sidecarMetadata = await readMetadataFromSidecar(filePath);
    if (sidecarMetadata != null && sidecarMetadata.hasValidMetadata) {
      debugPrint(
        '📦 [FALLBACK] Using sidecar metadata for: ${path.basename(filePath)}',
      );
      return sidecarMetadata;
    }

    // Both failed - return null
    return null;
  }

  /// Internal method that performs actual ID3 read with retries on cold start
  Future<Id3Metadata?> _readMetadataWithRetry(
    String filePath, {
    required int retryCount,
  }) async {
    try {
      // ═══════════════════════════════════════════════════════════════════════
      // STEP 1: VALIDATE FILE EXISTENCE AND READABILITY
      // ═══════════════════════════════════════════════════════════════════════
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('⚠️ [ID3] File does not exist: $filePath');
        return null;
      }

      // Verify file is readable and has content
      final fileLength = await file.length();
      if (fileLength < 128) {
        // MP3 files must have at least 128 bytes (ID3v1 minimum)
        debugPrint('⚠️ [ID3] File too small to contain ID3 tags: $filePath');
        return null;
      }

      // Only process MP3 files
      if (!filePath.toLowerCase().endsWith('.mp3')) {
        return null;
      }

      // Cannot read from content:// URIs
      if (filePath.startsWith('content://')) {
        return null;
      }

      // ═══════════════════════════════════════════════════════════════════════
      // COLD START: Force a file read to ensure filesystem is ready
      // ═══════════════════════════════════════════════════════════════════════
      if (!_initialScanComplete && retryCount == 0) {
        // Read first few bytes to "warm up" the file handle
        try {
          final raf = await file.open(mode: FileMode.read);
          await raf.read(10);
          await raf.close();
        } catch (e) {
          debugPrint('⚠️ [ID3] File warmup failed: $e');
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 2: READ ID3 TAGS WITH EXPLICIT FRAME VALIDATION
      // ═══════════════════════════════════════════════════════════════════════
      final tags = await _tagger.getAllTags(filePath);

      if (tags == null) {
        // On cold start, retry after increasing delays
        if (!_initialScanComplete && retryCount < _maxColdStartRetries) {
          final delay = Duration(milliseconds: 200 * (retryCount + 1));
          debugPrint(
            '⚠️ [ID3] Read returned null (attempt ${retryCount + 1}), retrying in ${delay.inMilliseconds}ms: ${path.basename(filePath)}',
          );
          await Future.delayed(delay);
          return _readMetadataWithRetry(filePath, retryCount: retryCount + 1);
        }
        debugPrint(
          'ℹ️ [ID3] No tags found after ${retryCount + 1} attempts: ${path.basename(filePath)}',
        );
        return null;
      }

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 3: EXTRACT AND VALIDATE ID3 FRAMES (TIT2, TPE1, etc.)
      // ═══════════════════════════════════════════════════════════════════════
      final cleanedTitle = _cleanTagValue(tags.title);
      final cleanedArtist = _cleanTagValue(tags.artist);

      // If we got empty/null values on cold start, retry with increasing delays
      if (!_initialScanComplete &&
          retryCount < _maxColdStartRetries &&
          cleanedTitle == null &&
          cleanedArtist == null) {
        final delay = Duration(milliseconds: 250 * (retryCount + 1));
        debugPrint(
          '⚠️ [ID3] Empty metadata (attempt ${retryCount + 1}), retrying in ${delay.inMilliseconds}ms: ${path.basename(filePath)}',
        );
        await Future.delayed(delay);
        return _readMetadataWithRetry(filePath, retryCount: retryCount + 1);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 4: READ EMBEDDED ARTWORK FROM ID3 APIC FRAME
      // ═══════════════════════════════════════════════════════════════════════
      Uint8List? embeddedArtwork;
      if (tags.artwork != null && tags.artwork!.isNotEmpty) {
        embeddedArtwork = Uint8List.fromList(tags.artwork!);
        debugPrint(
          '✅ [ID3] Embedded artwork found: ${embeddedArtwork.length} bytes',
        );
      }

      // Also check for sidecar .jpg file as fallback
      String? sidecarArtworkPath;
      final artworkPath = getArtworkPath(filePath);
      if (artworkPath != null && await File(artworkPath).exists()) {
        sidecarArtworkPath = artworkPath;
        debugPrint('✅ [ID3] Sidecar artwork found: $artworkPath');
      }

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 5: BUILD METADATA OBJECT WITH VALIDATED VALUES
      // ═══════════════════════════════════════════════════════════════════════
      // NOTE: We store YouTube URL in the 'composer' field as logical identity
      final metadata = Id3Metadata(
        title: cleanedTitle,
        artist: cleanedArtist,
        album: _cleanTagValue(tags.album),
        year: _cleanTagValue(tags.year),
        youtubeUrl: _cleanTagValue(
          tags.composer,
        ), // YouTube URL stored in composer field
        artworkBytes: embeddedArtwork,
        artworkPath: sidecarArtworkPath,
        hasEmbeddedArtwork:
            embeddedArtwork != null && embeddedArtwork.isNotEmpty,
        filePath: filePath,
        fileName: path.basename(filePath),
      );

      debugPrint(
        '✅ [ID3] Read: "${metadata.displayTitle}" by "${metadata.displayArtist}"${retryCount > 0 ? " (attempt ${retryCount + 1})" : ""}',
      );
      return metadata;
    } catch (e) {
      // On exception during cold start, retry with increasing delays
      if (!_initialScanComplete && retryCount < _maxColdStartRetries) {
        final delay = Duration(milliseconds: 200 * (retryCount + 1));
        debugPrint(
          '⚠️ [ID3] Read failed (attempt ${retryCount + 1}), retrying in ${delay.inMilliseconds}ms: ${path.basename(filePath)} - $e',
        );
        await Future.delayed(delay);
        return _readMetadataWithRetry(filePath, retryCount: retryCount + 1);
      }
      debugPrint(
        '❌ [ID3] Error reading $filePath after ${retryCount + 1} attempts: $e',
      );
      return null;
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// READ METADATA FROM SIDECAR JSON FILE (FALLBACK FOR ID3 FAILURES)
  /// ─────────────────────────────────────────────────────────────────────────
  /// If ID3 tags cannot be read, check for a .meta.json sidecar file
  /// that was written during download. This survives app reinstall.
  ///
  /// STORAGE STRUCTURE: Checks both new (.meta/ folder) and legacy locations
  Future<Id3Metadata?> readMetadataFromSidecar(String filePath) async {
    try {
      // Use StoragePathService to find metadata file (checks new and legacy locations)
      final storagePaths = StoragePathService.instance;
      final metaJsonPath = await storagePaths.findMetaForMp3(filePath);

      if (metaJsonPath == null) {
        return null;
      }

      final metaFile = File(metaJsonPath);
      if (!await metaFile.exists()) {
        return null;
      }

      final jsonStr = await metaFile.readAsString();
      final Map<String, dynamic> metaJson = jsonDecode(jsonStr);

      final title = _cleanTagValue(metaJson['title'] as String?);
      final artist = _cleanTagValue(metaJson['artist'] as String?);

      if (title == null && artist == null) {
        return null;
      }

      // Check for sidecar artwork
      String? sidecarArtworkPath;
      final artworkPath = getArtworkPath(filePath);
      if (artworkPath != null && await File(artworkPath).exists()) {
        sidecarArtworkPath = artworkPath;
      }

      debugPrint('✅ [META] Read from sidecar: "$title" by "$artist"');

      return Id3Metadata(
        title: title,
        artist: artist,
        album: _cleanTagValue(metaJson['album'] as String?),
        year: null,
        youtubeUrl: metaJson['youtubeUrl'] as String?,
        artworkBytes: null,
        artworkPath: sidecarArtworkPath,
        hasEmbeddedArtwork: false,
        filePath: filePath,
        fileName: path.basename(filePath),
      );
    } catch (e) {
      debugPrint('⚠️ [META] Error reading sidecar for $filePath: $e');
      return null;
    }
  }

  /// Check if a file is from our app's download folder
  bool isLumenLyricFile(String filePath) {
    return filePath.contains('LumenLyric') || filePath.contains('MyMusicApp');
  }

  /// Get the expected artwork path for a song file
  /// Uses new storage structure: /.artwork/ folder
  /// Also checks legacy location (same folder as MP3)
  String? getArtworkPath(String mp3FilePath) {
    if (!mp3FilePath.toLowerCase().endsWith('.mp3')) {
      return null;
    }
    // Return the new .artwork/ folder path
    return StoragePathService.instance.getArtworkPathForMp3(mp3FilePath);
  }

  /// Get legacy artwork path (same folder as MP3) for migration
  String? getLegacyArtworkPath(String mp3FilePath) {
    if (!mp3FilePath.toLowerCase().endsWith('.mp3')) {
      return null;
    }
    return mp3FilePath.replaceAll(
      RegExp(r'\.mp3$', caseSensitive: false),
      '.jpg',
    );
  }

  /// Get the expected metadata JSON path for a song file
  /// Uses new storage structure: /.meta/ folder
  String? getMetadataJsonPath(String mp3FilePath) {
    if (!mp3FilePath.toLowerCase().endsWith('.mp3')) {
      return null;
    }
    // Return the new .meta/ folder path
    return StoragePathService.instance.getMetaPathForMp3(mp3FilePath);
  }

  /// Get legacy metadata path (same folder as MP3) for migration
  String? getLegacyMetadataJsonPath(String mp3FilePath) {
    if (!mp3FilePath.toLowerCase().endsWith('.mp3')) {
      return null;
    }
    return mp3FilePath.replaceAll(
      RegExp(r'\.mp3$', caseSensitive: false),
      '.meta.json',
    );
  }

  /// Check if artwork file exists for this song (new or legacy location)
  Future<bool> hasLocalArtwork(String mp3FilePath) async {
    final storagePaths = StoragePathService.instance;
    final artworkPath = await storagePaths.findArtworkForMp3(mp3FilePath);
    return artworkPath != null;
  }

  /// Find artwork path (checks new .artwork/ folder first, then legacy)
  Future<String?> findArtworkPath(String mp3FilePath) async {
    final storagePaths = StoragePathService.instance;
    return await storagePaths.findArtworkForMp3(mp3FilePath);
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// CREATE SIDECAR METADATA FROM FILENAME (MIGRATION FOR EXISTING FILES)
  /// ─────────────────────────────────────────────────────────────────────────
  /// For existing files that don't have .meta.json, parse the filename
  /// to extract title and artist information.
  ///
  /// Common YouTube title patterns:
  /// - "Artist - Song Title (Official Video).mp3"
  /// - "Song Title by Artist.mp3"
  /// - "Artist Name - Song Name.mp3"
  Future<bool> createSidecarFromFilename(String filePath) async {
    try {
      final metaJsonPath = getMetadataJsonPath(filePath);
      if (metaJsonPath == null) return false;

      // Don't overwrite existing metadata
      if (await File(metaJsonPath).exists()) {
        return false;
      }

      final filename = path.basenameWithoutExtension(filePath);
      String title = filename;
      String artist = 'Unknown Artist';

      // Try to parse "Artist - Title" format (most common)
      if (filename.contains(' - ')) {
        final parts = filename.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }
      // Try "Title by Artist" format
      else if (filename.toLowerCase().contains(' by ')) {
        final regex = RegExp(r'(.+?)\s+by\s+(.+)', caseSensitive: false);
        final match = regex.firstMatch(filename);
        if (match != null) {
          title = match.group(1)?.trim() ?? filename;
          artist = match.group(2)?.trim() ?? 'Unknown Artist';
        }
      }

      // Clean up common YouTube suffixes
      title = title
          .replaceAll(RegExp(r'\s*\(Official.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\[Official.*?\]', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\(Lyrics.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\[Lyrics.*?\]', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\(Audio.*?\)', caseSensitive: false), '')
          .replaceAll(
            RegExp(r'\s*\(Music Video.*?\)', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'\s*\(Visualizer.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\(Prod\..*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*Prod\..*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*｜.*$'), '') // Remove Japanese pipe suffix
          .trim();

      // Clean artist too
      artist = artist
          .replaceAll(RegExp(r'\s*\(Official.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '')
          .trim();

      if (title.isEmpty) title = filename;

      final metaJson = {
        'title': title,
        'artist': artist,
        'album': 'LumenLyric',
        'migratedFromFilename': true,
        'originalFilename': filename,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await File(metaJsonPath).writeAsString(jsonEncode(metaJson));
      debugPrint('✅ [MIGRATE] Created sidecar for: $title by $artist');
      return true;
    } catch (e) {
      debugPrint('⚠️ [MIGRATE] Failed to create sidecar for $filePath: $e');
      return false;
    }
  }

  /// Clean tag value: trim, handle null/empty, remove placeholder values
  /// CRITICAL: Empty strings are treated as invalid metadata
  String? _cleanTagValue(String? value) {
    if (value == null) return null;
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;

    // ═══════════════════════════════════════════════════════════════════════
    // REJECT PLACEHOLDER VALUES THAT INDICATE MISSING DATA
    // ═══════════════════════════════════════════════════════════════════════
    // These values should NEVER be treated as valid metadata.
    // If ID3 tags contain these, treat as if tags are missing.
    final lowerCleaned = cleaned.toLowerCase();
    if (lowerCleaned == '<unknown>' ||
        lowerCleaned == 'unknown' ||
        lowerCleaned == 'unknown artist' ||
        lowerCleaned == 'unknown title' ||
        lowerCleaned == 'unknown album' ||
        lowerCleaned == 'various artists' ||
        lowerCleaned == 'untitled' ||
        cleaned == 'null' ||
        cleaned == 'undefined') {
      return null;
    }
    return cleaned;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ID3 METADATA - IMMUTABLE DATA READ FROM MP3 FILE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This class represents metadata read directly from an MP3 file's ID3 tags.
/// It is immutable and represents the authoritative state of the file.
///
/// IDENTITY:
/// - Runtime key: filePath (absolute path to the file)
/// - Logical identity: youtubeUrl stored in ID3 composer field
/// ═══════════════════════════════════════════════════════════════════════════
class Id3Metadata {
  /// Song title from ID3 TIT2 frame (null if missing)
  final String? title;

  /// Artist name from ID3 TPE1 frame (null if missing)
  final String? artist;

  /// Album name from ID3 TALB frame (null if missing)
  final String? album;

  /// Year from ID3 TYER/TDRC frame (null if missing)
  final String? year;

  /// YouTube URL stored in ID3 composer field - LOGICAL IDENTITY (null if missing)
  final String? youtubeUrl;

  /// Embedded artwork bytes from ID3 APIC frame (null if not embedded)
  final Uint8List? artworkBytes;

  /// Path to sidecar .jpg artwork file (backup for embedded artwork)
  final String? artworkPath;

  /// Whether the file has embedded artwork in APIC frame
  final bool hasEmbeddedArtwork;

  /// Absolute path to the MP3 file (RUNTIME KEY - used for lookups)
  final String filePath;

  /// Filename only (for display purposes, NOT for identity)
  final String fileName;

  const Id3Metadata({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.youtubeUrl,
    this.artworkBytes,
    this.artworkPath,
    this.hasEmbeddedArtwork = false,
    required this.filePath,
    required this.fileName,
  });

  /// Check if this file has artwork (either embedded or sidecar file)
  bool get hasArtwork =>
      hasEmbeddedArtwork || (artworkPath != null && artworkPath!.isNotEmpty);

  /// ─────────────────────────────────────────────────────────────────────────
  /// DISPLAY VALUES WITH NEUTRAL DEFAULTS
  /// ─────────────────────────────────────────────────────────────────────────
  /// If ID3 tags are missing, return neutral defaults.
  /// NEVER attempt to derive from filename, index, or cross-file data.

  /// Display title: ID3 title or neutral "Unknown Title"
  String get displayTitle => title ?? 'Unknown Title';

  /// Display artist: ID3 artist or neutral "Unknown Artist"
  String get displayArtist => artist ?? 'Unknown Artist';

  /// Display album: ID3 album or neutral "Unknown Album"
  String get displayAlbum => album ?? 'Unknown Album';

  /// ─────────────────────────────────────────────────────────────────────────
  /// YOUTUBE VIDEO ID EXTRACTION (LOGICAL IDENTITY)
  /// ─────────────────────────────────────────────────────────────────────────
  /// The YouTube URL is stored in the composer field during download.
  /// This provides a stable logical identity that survives any file operation.

  /// Extract YouTube video ID from youtubeUrl if present
  String? get youtubeVideoId {
    if (youtubeUrl == null) return null;
    // Look for YouTube video ID pattern (11 characters, alphanumeric with - and _)
    final regex = RegExp(
      r'(?:youtube\.com/watch\?v=|youtu\.be/|^)([a-zA-Z0-9_-]{11})',
    );
    final match = regex.firstMatch(youtubeUrl!);
    return match?.group(1);
  }

  /// Check if this file has valid metadata
  bool get hasValidMetadata => title != null || artist != null;

  @override
  String toString() {
    return 'Id3Metadata(title: $title, artist: $artist, filePath: $filePath)';
  }
}
