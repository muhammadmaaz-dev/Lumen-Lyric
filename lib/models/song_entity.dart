import 'dart:typed_data';

class SongEntity {
  final String path;
  final String? title;
  final String? artist;
  final String? album;
  final int duration;
  final Uint8List? artworkBytes;
  final String? artworkPath;
  final String? youtubeVideoId;
  final int? mediaStoreId;
  final bool isFromLumenLyric;
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

  String get displayTitle => title ?? 'Unknown Title';
  String get displayArtist => artist ?? 'Unknown Artist';
  String get displayAlbum => album ?? 'Unknown Album';

  /// Formatted duration string (MM:SS)
  String get formattedDuration {
    final d = Duration(milliseconds: duration);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get hasValidMetadata => title != null || artist != null;
  bool get hasArtwork =>
      (artworkBytes != null && artworkBytes!.isNotEmpty) ||
      (artworkPath != null && artworkPath!.isNotEmpty);

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
