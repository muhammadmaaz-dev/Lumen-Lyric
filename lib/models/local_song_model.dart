class LocalSongModel {
  final int id;
  final String artist;
  final String title;
  final String uri;
  final String albumArt;
  final int duration;
  final bool isDownloaded;
  final bool isLiked;

  LocalSongModel({
    required this.id,
    required this.artist,
    required this.title,
    required this.uri,
    required this.albumArt,
    required this.duration,
    required this.isDownloaded,
    required this.isLiked,
  });
}
