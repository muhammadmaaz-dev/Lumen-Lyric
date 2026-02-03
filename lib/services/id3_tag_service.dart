import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:path/path.dart' as path;

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

  /// ─────────────────────────────────────────────────────────────────────────
  /// READ METADATA FROM MP3 FILE - THE ONLY AUTHORITATIVE SOURCE
  /// ─────────────────────────────────────────────────────────────────────────
  ///
  /// This method reads ID3 tags directly from the MP3 file.
  /// If tags are missing or corrupt, returns null (caller uses neutral defaults).
  /// NEVER attempts cross-file recovery or silent repair.
  Future<Id3Metadata?> readMetadataFromFile(String filePath) async {
    try {
      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('⚠️ [ID3] File does not exist: $filePath');
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

      // Read ID3 tags from the file
      final tags = await _tagger.getAllTags(filePath);

      if (tags == null) {
        debugPrint('ℹ️ [ID3] No tags found in: ${path.basename(filePath)}');
        return null;
      }

      // ═══════════════════════════════════════════════════════════════════════
      // READ EMBEDDED ARTWORK FROM ID3 APIC FRAME
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

      // Extract and clean metadata
      // NOTE: We store YouTube URL in the 'composer' field as logical identity
      final metadata = Id3Metadata(
        title: _cleanTagValue(tags.title),
        artist: _cleanTagValue(tags.artist),
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
        '✅ [ID3] Read: "${metadata.displayTitle}" by "${metadata.displayArtist}"',
      );
      return metadata;
    } catch (e) {
      debugPrint('❌ [ID3] Error reading $filePath: $e');
      return null;
    }
  }

  /// Check if a file is from our app's download folder
  bool isLumenLyricFile(String filePath) {
    return filePath.contains('LumenLyric') || filePath.contains('MyMusicApp');
  }

  /// Get the expected artwork path for a song file
  /// (artwork is stored as same-name .jpg file next to the .mp3)
  String? getArtworkPath(String mp3FilePath) {
    if (!mp3FilePath.toLowerCase().endsWith('.mp3')) {
      return null;
    }
    return mp3FilePath.replaceAll(
      RegExp(r'\.mp3$', caseSensitive: false),
      '.jpg',
    );
  }

  /// Check if artwork file exists for this song
  Future<bool> hasLocalArtwork(String mp3FilePath) async {
    final artworkPath = getArtworkPath(mp3FilePath);
    if (artworkPath == null) return false;
    return await File(artworkPath).exists();
  }

  /// Clean tag value: trim, handle null/empty, remove placeholder values
  String? _cleanTagValue(String? value) {
    if (value == null) return null;
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    // Ignore placeholder values that indicate missing data
    if (cleaned == '<unknown>' ||
        cleaned == 'Unknown' ||
        cleaned == 'unknown' ||
        cleaned == 'Unknown Artist' ||
        cleaned == 'Unknown Album') {
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
