class PlaylistModel {
  final String id;
  final String name;
  final List<int> songIds; // Store song IDs, not full objects
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get song count
  int get songCount => songIds.length;

  // Create a copy with modified fields
  PlaylistModel copyWith({
    String? id,
    String? name,
    List<int>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? List<int>.from(this.songIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: List<int>.from(json['songIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Create a new empty playlist
  factory PlaylistModel.create({required String name}) {
    final now = DateTime.now();
    return PlaylistModel(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
