class SongModel {
  final String id;
  final String title;
  final String genre;
  final String imageUrl;

  SongModel({
    required this.id,
    required this.title,
    required this.genre,
    required this.imageUrl,
  });

  // Factory constructor for JSON parsing (backend ready)
  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      genre: json['genre'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
