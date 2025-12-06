class ArtistModel {
  final String id;
  final String name;
  final String songTitle;
  final String imageUrl;

  ArtistModel({
    required this.id,
    required this.name,
    required this.songTitle,
    required this.imageUrl,
  });

  // Factory constructor for JSON parsing (backend ready)
  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      songTitle: json['songTitle'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
