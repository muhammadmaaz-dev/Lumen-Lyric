import 'dart:typed_data';

/// ═══════════════════════════════════════════════════════════════════════════
/// SONG ENTITY - THE CANONICAL MODEL FOR ALL SCREENS
/// ═══════════════════════════════════════════════════════════════════════════
///
/// INVARIANTS:
/// 1. All fields are populated ONLY from ID3 tag reads
/// 2. Every screen uses this SAME model - no screen-specific parsing
/// 3. If ID3 tags are missing, fields are null - UI displays defaults
/// 4. No MediaStore metadata, no filename parsing, no sidecar JSON
/// 5. This is the SINGLE source of truth for song metadata
///
/// IDENTITY:
/// - Runtime key: filePath (absolute path to the file)
/// - Logical identity: youtubeVideoId (from ID3 TXXX or composer field)
/// ═══════════════════════════════════════════════════════════════════════════
class SongEntity {
  /// Absolute file path - RUNTIME KEY (used for playback and lookups)
  final String path;

  /// Song title from ID3 TIT2 frame
  final String? title;

  /// Artist name from ID3 TPE1 frame
  final String? artist;

  /// Album name from ID3 TALB frame
  final String? album;

  /// Duration in milliseconds (from file analysis, not ID3)
  final int duration;

  /// Embedded artwork bytes from ID3 APIC frame (null if not embedded)
  final Uint8List? artworkBytes;

  /// Local artwork file path (alternative to embedded artwork)
  final String? artworkPath;

  /// YouTube video ID - LOGICAL IDENTITY (from ID3 composer field)
  final String? youtubeVideoId;

  /// MediaStore ID (used only for QueryArtworkWidget fallback - NOT for identity)
  final int? mediaStoreId;

  /// Whether this song is from our app's download folder
  final bool isFromLumenLyric;

  /// Whether the user has liked this song
  final bool isLiked;

  const SongEntity({
    required this.path,
    this.title,
    this.artist,
    this.album,
    this.duration = 0,
    this.artworkBytes,
    this.artworkPath,
    this.youtubeVideoId,
    this.mediaStoreId,
    this.isFromLumenLyric = false,
    this.isLiked = false,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY VALUES - Use these in UI to get proper defaults
  // ═══════════════════════════════════════════════════════════════════════════

  /// Display title: ID3 title or "Unknown Title"
  String get displayTitle => title ?? 'Unknown Title';

  /// Display artist: ID3 artist or "Unknown Artist"
  String get displayArtist => artist ?? 'Unknown Artist';

  /// Display album: ID3 album or "Unknown Album"
  String get displayAlbum => album ?? 'Unknown Album';

  /// Formatted duration string (MM:SS)
  String get formattedDuration {
    final d = Duration(milliseconds: duration);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if this song has valid ID3 metadata
  bool get hasValidMetadata => title != null || artist != null;

  /// Check if this song has artwork (either embedded or external file)
  bool get hasArtwork =>
      (artworkBytes != null && artworkBytes!.isNotEmpty) ||
      (artworkPath != null && artworkPath!.isNotEmpty);

  // ═══════════════════════════════════════════════════════════════════════════
  // COPY WITH - For updating individual fields (like isLiked)
  // ═══════════════════════════════════════════════════════════════════════════

  SongEntity copyWith({
    String? path,
    String? title,
    String? artist,
    String? album,
    int? duration,
    Uint8List? artworkBytes,
    String? artworkPath,
    String? youtubeVideoId,
    int? mediaStoreId,
    bool? isFromLumenLyric,
    bool? isLiked,
  }) {
    return SongEntity(
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkBytes: artworkBytes ?? this.artworkBytes,
      artworkPath: artworkPath ?? this.artworkPath,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      isFromLumenLyric: isFromLumenLyric ?? this.isFromLumenLyric,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongEntity && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'SongEntity(path: $path, title: $displayTitle, artist: $displayArtist)';
  }
}
