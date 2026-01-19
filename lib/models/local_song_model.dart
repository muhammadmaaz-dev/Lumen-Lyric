class LocalSongModel {
  final int id;
  final String title;
  final String artist;
  final String uri;
  final String albumArt;
  final int duration;
  final bool isLiked; // <-- Zaroori field
  final bool isDownloaded; // <-- Zaroori field

  LocalSongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.albumArt,
    required this.duration,
    this.isLiked = false, // Default false
    this.isDownloaded = false, // Default false
  });

  LocalSongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? uri,
    String? albumArt,
    int? duration,
    bool? isLiked,
    bool? isDownloaded,
  }) {
    return LocalSongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      uri: uri ?? this.uri,
      albumArt: albumArt ?? this.albumArt,
      duration: duration ?? this.duration,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
